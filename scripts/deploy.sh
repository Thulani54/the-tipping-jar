#!/usr/bin/env bash
#
# Tipping Jar deployment script.
#
#   ./scripts/deploy.sh                 build + deploy the web frontend
#   ./scripts/deploy.sh --backend       also rebuild ALL rust services
#   ./scripts/deploy.sh --backend creators payments
#                                       rebuild only those rust services
#   ./scripts/deploy.sh --no-commit     deploy without committing/pushing
#   ./scripts/deploy.sh -m "message"    use a specific commit message
#   ./scripts/deploy.sh --backend-only  skip the frontend entirely
#
# The build gate is strict: if `next build` fails, NOTHING is pushed and
# NOTHING is deployed. (A previous manual deploy piped the build into
# `tail`, which hid npm's exit code and let a failing build get pushed.)
#
# Credentials are read from scripts/.deploy.env (gitignored), never from
# this file. That file needs:
#     SSHPASS='...'          # root password for the VPS
# Optional overrides: DEPLOY_HOST, WEB_DIR, RUST_DIR, API_BASE

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEB_SRC="$REPO_ROOT/frontend-next"
RUST_SRC="$REPO_ROOT/backend-rust"
ENV_FILE="$REPO_ROOT/scripts/.deploy.env"

# ── pretty output ───────────────────────────────────────────────────────
bold=$'\033[1m'; red=$'\033[31m'; grn=$'\033[32m'; ylw=$'\033[33m'; rst=$'\033[0m'
step() { printf '\n%s▸ %s%s\n' "$bold" "$1" "$rst"; }
ok()   { printf '%s  ✓ %s%s\n' "$grn" "$1" "$rst"; }
warn() { printf '%s  ! %s%s\n' "$ylw" "$1" "$rst"; }
die()  { printf '\n%s  ✗ %s%s\n\n' "$red" "$1" "$rst" >&2; exit 1; }

# ── args ────────────────────────────────────────────────────────────────
DO_WEB=1; DO_BACKEND=0; DO_COMMIT=1; COMMIT_MSG=""; RUST_SERVICES=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --backend)      DO_BACKEND=1; shift
                    while [[ $# -gt 0 && "$1" != --* ]]; do RUST_SERVICES+=("$1"); shift; done ;;
    --backend-only) DO_BACKEND=1; DO_WEB=0; shift
                    while [[ $# -gt 0 && "$1" != --* ]]; do RUST_SERVICES+=("$1"); shift; done ;;
    --no-commit)    DO_COMMIT=0; shift ;;
    -m|--message)   COMMIT_MSG="${2:-}"; shift 2 ;;
    -h|--help)      sed -n '2,25p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)              die "unknown option: $1  (try --help)" ;;
  esac
done

# ── credentials ─────────────────────────────────────────────────────────
[[ -f "$ENV_FILE" ]] || die "missing $ENV_FILE — create it with: SSHPASS='<vps root password>'"
# shellcheck disable=SC1090
source "$ENV_FILE"
: "${SSHPASS:?SSHPASS not set in $ENV_FILE}"
export SSHPASS

DEPLOY_HOST="${DEPLOY_HOST:-root@154.66.199.174}"
WEB_DIR="${WEB_DIR:-/opt/tipping-jar-web}"
RUST_DIR="${RUST_DIR:-/opt/tipping-jar-rust}"
API_BASE="${API_BASE:-https://api.tippingjar.co.za/api/v2}"

SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
          -o ConnectTimeout=40 -o PreferredAuthentications=password
          -o PubkeyAuthentication=no)
remote() { sshpass -e ssh "${SSH_OPTS[@]}" "$DEPLOY_HOST" "$@"; }

command -v sshpass >/dev/null || die "sshpass not installed (brew install hudochenkov/sshpass/sshpass)"

# ── 1. build gate ───────────────────────────────────────────────────────
if [[ $DO_WEB -eq 1 ]]; then
  step "Building frontend (strict — a failure stops the deploy)"
  BUILD_LOG="$(mktemp -t tj-build)"
  build_ok=0
  # Clean first. The container build always starts fresh (.dockerignore
  # excludes .next), so an incremental local build proves nothing about
  # whether the deploy will succeed — and stale .next/types artifacts
  # produce phantom "file not found" type errors of their own.
  rm -rf "$WEB_SRC/.next"
  for attempt in 1 2; do
    # No pipe here: we need npm's own exit status, not a pipeline's.
    if ( cd "$WEB_SRC" && npm run build ) >"$BUILD_LOG" 2>&1 \
       && ! grep -qE 'Failed to compile|Build failed because of webpack errors' "$BUILD_LOG"; then
      build_ok=1; break
    fi
    # next/font fetches Google Fonts at BUILD time; that call is flaky and
    # throws "Cannot read properties of null" when the fetch fails. It is
    # not a code error, so retry once before giving up.
    if grep -q 'An error occurred in `next/font`' "$BUILD_LOG" && [[ $attempt -eq 1 ]]; then
      warn "next/font fetch failed (transient) — retrying build"
      continue
    fi
    break
  done
  if [[ $build_ok -ne 1 ]]; then
    echo; tail -40 "$BUILD_LOG"
    die "frontend build FAILED — nothing pushed, nothing deployed. Log: $BUILD_LOG"
  fi
  ok "frontend build passed"
  rm -f "$BUILD_LOG"
fi

if [[ $DO_BACKEND -eq 1 ]]; then
  step "Checking rust workspace"
  ( cd "$RUST_SRC" && cargo check --all ) || die "cargo check FAILED — nothing pushed, nothing deployed."
  ok "cargo check passed"
fi

# ── 2. commit + push ────────────────────────────────────────────────────
if [[ $DO_COMMIT -eq 1 ]]; then
  cd "$REPO_ROOT"
  if [[ -n "$(git status --porcelain)" ]]; then
    step "Committing + pushing"
    git add -A
    git commit -q -m "${COMMIT_MSG:-chore: deploy $(date '+%Y-%m-%d %H:%M')}"
    ok "committed $(git rev-parse --short HEAD)"
    git push -q origin HEAD:dev  && ok "pushed dev"
    git push -q origin HEAD:main && ok "pushed main"
  else
    warn "working tree clean — nothing to commit"
  fi
fi

# ── 3. deploy ───────────────────────────────────────────────────────────
if [[ $DO_WEB -eq 1 ]]; then
  step "Deploying frontend → $DEPLOY_HOST:$WEB_DIR"
  WEB_LOG="$(mktemp -t tj-web-deploy)"
  # NOTE: no `| grep || true` around this — swallowing the pipeline's exit
  # status is how a failing remote docker build once got reported as success.
  set +e
  for attempt in 1 2; do
    tar -C "$WEB_SRC" -czf - \
        --exclude='./node_modules' --exclude='./.next' --exclude='._*' . \
      | remote "set -e; tar xzf - -C $WEB_DIR 2>/dev/null; \
                find $WEB_DIR -name '._*' -delete; \
                cd $WEB_DIR && NEXT_PUBLIC_API_BASE=$API_BASE PREVIEW_HTTP=0 \
                docker compose up --build -d" >"$WEB_LOG" 2>&1
    rc=$?
    # Same transient next/font failure can hit the container build, where
    # .dockerignore excludes .next so fonts are always fetched fresh.
    if [[ $rc -ne 0 ]] && grep -q 'next/font' "$WEB_LOG" && [[ $attempt -eq 1 ]]; then
      printf '%s  ! next/font fetch failed remotely (transient) — retrying%s\n' "$ylw" "$rst"
      continue
    fi
    break
  done
  set -e
  grep -vE 'Warning: Permanently added|LIBARCHIVE' "$WEB_LOG" | tail -5 || true
  if [[ $rc -ne 0 ]] || grep -qE 'failed to solve|did not complete successfully|ERROR \[' "$WEB_LOG"; then
    echo; tail -60 "$WEB_LOG"
    die "remote frontend build/deploy FAILED (rc=$rc). Previous container left running. Log: $WEB_LOG"
  fi
  ok "frontend container restarted"
  rm -f "$WEB_LOG"
fi

if [[ $DO_BACKEND -eq 1 ]]; then
  svc="${RUST_SERVICES[*]:-}"
  step "Deploying backend → $DEPLOY_HOST:$RUST_DIR ${svc:+($svc)}"
  BE_LOG="$(mktemp -t tj-be-deploy)"
  set +e
  tar -C "$RUST_SRC" -czf - --exclude='./target' --exclude='._*' . \
    | remote "set -e; tar xzf - -C $RUST_DIR 2>/dev/null; \
              find $RUST_DIR -name '._*' -delete; \
              cd $RUST_DIR && docker compose up --build -d $svc" >"$BE_LOG" 2>&1
  rc=$?
  set -e
  grep -vE 'Warning: Permanently added|LIBARCHIVE' "$BE_LOG" | tail -5 || true
  if [[ $rc -ne 0 ]] || grep -qE 'failed to solve|did not complete successfully|ERROR \[' "$BE_LOG"; then
    echo; tail -60 "$BE_LOG"
    die "remote backend build/deploy FAILED (rc=$rc). Previous container(s) left running. Log: $BE_LOG"
  fi
  ok "backend container(s) restarted"
  rm -f "$BE_LOG"
fi

# ── 4. verify ───────────────────────────────────────────────────────────
step "Verifying"
for url in https://www.tippingjar.co.za/ https://api.tippingjar.co.za/api/v2/creators/creators; do
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$url" || echo 000)"
  if [[ "$code" == 2* ]]; then ok "$code  $url"; else warn "$code  $url"; fi
done

printf '\n%s✓ Deploy complete.%s\n\n' "$grn" "$rst"
