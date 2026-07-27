"use client";

// Creator dashboard — ported from frontend/lib/screens/dashboard_screen.dart
// The Flutter screen has a full sidebar (Overview, Tips, Jars, Analytics, Content,
// Monetize, Profile, Notifications, Disputes, Studio, Referrals). Here we surface
// the core Overview + Tips, plus the Referral and Studio tabs (referral_tab.dart /
// studio_tab.dart). Many creator-scoped stats have no API endpoint yet, so they
// render as placeholders with TODO(api) markers.

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import type {
  Tip,
  ReferralCode,
  Creator,
  CreatorStats,
  Transaction,
  Payout,
  Balance,
} from "@/types";

type Tab = "overview" | "tips" | "transactions" | "referrals" | "studio";

const TABS: { id: Tab; label: string; icon: string }[] = [
  { id: "overview", label: "Overview", icon: "bi-house-door-fill" },
  { id: "tips", label: "Tips", icon: "bi-cash-stack" },
  { id: "transactions", label: "Transactions", icon: "bi-receipt" },
  { id: "referrals", label: "Referrals", icon: "bi-people-fill" },
  { id: "studio", label: "Studio", icon: "bi-palette-fill" },
];

const money = (n: number) =>
  n.toLocaleString("en-ZA", { minimumFractionDigits: 2, maximumFractionDigits: 2 });

function greeting(): string {
  const h = new Date().getHours();
  if (h < 12) return "Good morning";
  if (h < 17) return "Good afternoon";
  return "Good evening";
}

export default function DashboardPage() {
  const { user, token, isAuthenticated, initialized } = useAuth();
  const router = useRouter();
  const [tab, setTab] = useState<Tab>("overview");

  const [tips, setTips] = useState<Tip[]>([]);
  const [referral, setReferral] = useState<ReferralCode | null>(null);
  const [myCreator, setMyCreator] = useState<Creator | null>(null);
  const [stats, setStats] = useState<CreatorStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (initialized && !isAuthenticated) router.push("/login");
  }, [initialized, isAuthenticated, router]);

  useEffect(() => {
    if (!isAuthenticated) return;
    let alive = true;
    (async () => {
      setLoading(true);
      // Resolve the caller's creator profile, then its real stats + tips.
      const mine = token ? await api.myCreatorProfile(token).catch(() => null) : null;
      const [t, r, s] = await Promise.all([
        mine
          ? api.tipsForCreator(mine.id).catch(() => [] as Tip[])
          : api.listTips().catch(() => [] as Tip[]),
        token ? api.myReferralCode(token).catch(() => null) : Promise.resolve(null),
        mine ? api.creatorStats(mine.id).catch(() => null) : Promise.resolve(null),
      ]);
      if (!alive) return;
      setMyCreator(mine);
      setTips(t.slice(0, 50));
      setReferral(r);
      setStats(s);
      setLoading(false);
    })();
    return () => {
      alive = false;
    };
  }, [isAuthenticated, token]);

  if (!initialized || !isAuthenticated) {
    return (
      <div className="container-content grid min-h-[60vh] place-items-center">
        <p className="body-muted">Loading your dashboard…</p>
      </div>
    );
  }

  const name = user?.username || "there";

  return (
    <div className="container-content py-10">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <p className="text-sm text-muted">{greeting()}</p>
          <h1 className="text-2xl font-extrabold tracking-tight text-ink">{name}</h1>
        </div>
        <Link href="/creators" className="btn-ghost !px-4 !py-2 text-sm">
          Explore creators
        </Link>
      </div>

      {/* Tab bar */}
      <div className="mt-8 flex gap-2 overflow-x-auto border-b border-border pb-px">
        {TABS.map((t) => (
          <button
            key={t.id}
            onClick={() => setTab(t.id)}
            className={`flex items-center gap-2 whitespace-nowrap rounded-t-lg px-4 py-2.5 text-sm font-semibold transition ${
              tab === t.id
                ? "border-b-2 border-teal text-ink"
                : "text-muted hover:text-ink"
            }`}
          >
            <span className="flex"><i className={`bi ${t.icon}`} /></span>
            {t.label}
          </button>
        ))}
      </div>

      <div className="mt-8">
        {tab === "overview" && (
          <OverviewTab
            tips={tips}
            loading={loading}
            stats={stats}
            slug={myCreator?.slug ?? null}
          />
        )}
        {tab === "tips" && <TipsTab tips={tips} loading={loading} />}
        {tab === "transactions" && (
          <TransactionsTab token={token} creatorId={myCreator?.id ?? null} />
        )}
        {tab === "referrals" && <ReferralsTab referral={referral} />}
        {tab === "studio" && <StudioTab />}
      </div>
    </div>
  );
}

// ─── Overview ────────────────────────────────────────────────────────────────
function StatCard({
  label,
  value,
  icon,
  accent,
}: {
  label: string;
  value: string;
  icon: string;
  accent?: string;
}) {
  return (
    <div className="card !p-5">
      <div
        className="grid h-10 w-10 place-items-center rounded-xl text-lg"
        style={{ backgroundColor: (accent ?? "#004423") + "22" }}
      >
        <i className={`bi ${icon}`} style={{ color: accent ?? "#004423" }} />
      </div>
      <p className="mt-4 text-2xl font-extrabold tracking-tight text-ink">{value}</p>
      <p className="mt-1 text-xs text-muted">{label}</p>
    </div>
  );
}

function OverviewTab({
  tips,
  loading,
  stats,
  slug,
}: {
  tips: Tip[];
  loading: boolean;
  stats: CreatorStats | null;
  slug: string | null;
}) {
  const netEarned = stats ? Number(stats.creator_net_total) || 0 : 0;
  const thisMonth = stats ? Number(stats.this_month_amount) || 0 : 0;
  const shareUrl = slug ? `https://tippingjar.co.za/creator/${slug}` : null;
  return (
    <div className="space-y-8">
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Net earned" value={`R${money(netEarned)}`} icon="bi-cash-coin" accent="#004423" />
        <StatCard label="This month" value={`R${money(thisMonth)}`} icon="bi-calendar3" accent="#2563EB" />
        <StatCard label="Supporters" value={String(stats?.supporter_count ?? 0)} icon="bi-people-fill" accent="#FBBF24" />
        <StatCard label="Total tips" value={String(stats?.tip_count ?? 0)} icon="bi-heart-fill" accent="#F472B6" />
      </div>

      {/* Share tip link */}
      <div className="card bg-brand-gradient !border-transparent">
        <h3 className="text-lg font-semibold text-ink">Share your tip link</h3>
        <p className="mt-1 text-sm text-white/80">
          Drop your link in your bio, streams and posts so fans can support you.
        </p>
        {shareUrl && slug ? (
          <>
            <p className="mt-3 break-all font-mono text-sm text-white/90">{shareUrl}</p>
            <Link
              href={`/creator/${slug}`}
              className="mt-4 inline-flex rounded-full bg-white px-5 py-2.5 text-sm font-semibold text-primary transition hover:opacity-90"
            >
              View your page →
            </Link>
          </>
        ) : (
          <Link
            href="/onboarding"
            className="mt-5 inline-flex rounded-full bg-white px-5 py-2.5 text-sm font-semibold text-primary transition hover:opacity-90"
          >
            Set up your creator page →
          </Link>
        )}
      </div>

      {/* Recent tips */}
      <RecentTips tips={tips} loading={loading} />
    </div>
  );
}

function RecentTips({ tips, loading }: { tips: Tip[]; loading: boolean }) {
  return (
    <div>
      <h3 className="mb-4 text-base font-bold text-ink">Recent tips</h3>
      {loading ? (
        <p className="body-muted">Loading…</p>
      ) : tips.length === 0 ? (
        <div className="card grid place-items-center py-12 text-center">
          <div className="text-3xl text-teal"><i className="bi bi-cash-stack" /></div>
          <p className="mt-3 font-semibold text-ink">No tips yet</p>
          <p className="body-muted mt-1 max-w-sm">
            Share your tip link to start receiving support from your fans.
          </p>
        </div>
      ) : (
        <div className="card overflow-hidden !p-0">
          <div className="overflow-x-auto">
            <table className="w-full min-w-[560px] text-left text-sm">
              <thead className="border-b border-border text-xs uppercase tracking-wide text-muted">
                <tr>
                  <th className="px-5 py-3 font-semibold">From</th>
                  <th className="px-5 py-3 font-semibold">Message</th>
                  <th className="px-5 py-3 font-semibold">Status</th>
                  <th className="px-5 py-3 text-right font-semibold">Amount</th>
                </tr>
              </thead>
              <tbody>
                {tips.map((t) => (
                  <tr key={t.id} className="border-b border-border/60 last:border-0">
                    <td className="px-5 py-3 font-medium text-ink">
                      {t.tipper_name || "Anonymous"}
                    </td>
                    <td className="max-w-[220px] truncate px-5 py-3 text-muted">
                      {t.message || "—"}
                    </td>
                    <td className="px-5 py-3">
                      <span className="rounded-full bg-teal/10 px-2.5 py-1 text-xs font-semibold text-teal">
                        {t.status || "—"}
                      </span>
                    </td>
                    <td className="px-5 py-3 text-right font-bold text-ink">
                      R{money(Number(t.amount) || 0)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}

// ─── Tips ────────────────────────────────────────────────────────────────────
function TipsTab({ tips, loading }: { tips: Tip[]; loading: boolean }) {
  const total = tips.reduce((s, t) => s + (Number(t.amount) || 0), 0);
  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h3 className="text-base font-bold text-ink">All tips</h3>
        <span className="text-sm text-muted">Total: R{money(total)}</span>
      </div>
      {/* TODO(api): creator-scoped tips endpoint + date filters (Today / This week / This month) */}
      <RecentTips tips={tips} loading={loading} />
    </div>
  );
}

// ─── Referrals (referral_tab.dart) ─────────────────────────────────────────────
function ReferralsTab({ referral }: { referral: ReferralCode | null }) {
  const [copied, setCopied] = useState<string | null>(null);
  const code = referral?.code ?? "";
  const rate = referral ? Number(referral.commission_rate) || 0.01 : 0.01;
  const shareUrl = code ? `https://tippingjar.co.za/register?ref=${code}` : "";

  const copy = (text: string, key: string) => {
    navigator.clipboard?.writeText(text);
    setCopied(key);
    setTimeout(() => setCopied(null), 2000);
  };

  const steps = [
    ["Share your code", "Send your referral link to creators you know. They enter your code at signup."],
    ["They sign up", "When a creator registers with your code, a 6-month commission window starts."],
    ["Submit bank details", "You'll get an email — submit your bank account so we can pay your commission."],
    [`Earn ${(rate * 100).toFixed(1)}% of their tips`, "For every tip they receive in 6 months, you earn commission paid directly to your account."],
  ];

  return (
    <div className="max-w-3xl space-y-8">
      <div>
        <h2 className="text-xl font-extrabold tracking-tight text-ink">Referrals</h2>
        <p className="body-muted mt-1">
          Earn {(rate * 100).toFixed(1)}% of tips from every creator you refer — for 6 months.
        </p>
      </div>

      {/* Referral code card */}
      <div className="card bg-brand-gradient !border-transparent">
        <p className="inline-flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wide text-white/70">
          <i className="bi bi-gift-fill" /> Your referral code
        </p>
        <div className="mt-3 flex items-center gap-3">
          <span className="font-mono text-3xl font-bold tracking-[0.3em] text-ink">
            {code || "—"}
          </span>
          {code && (
            <button
              onClick={() => copy(code, "code")}
              className="rounded-lg bg-white/15 px-3 py-1.5 text-xs font-semibold text-ink hover:bg-white/25"
            >
              {copied === "code" ? "Copied!" : "Copy"}
            </button>
          )}
        </div>
        {shareUrl && <p className="mt-3 break-all text-xs text-white/60">{shareUrl}</p>}
        {shareUrl && (
          <div className="mt-4 flex flex-wrap gap-2">
            <button
              onClick={() => copy(shareUrl, "link")}
              className="rounded-lg bg-white/15 px-3 py-2 text-xs font-semibold text-ink hover:bg-white/25"
            >
              {copied === "link" ? "Link copied!" : <><i className="bi bi-link-45deg" /> Copy link</>}
            </button>
            <a
              href={`https://wa.me/?text=${encodeURIComponent(
                `Sign up on TippingJar with my code ${code}: ${shareUrl}`,
              )}`}
              target="_blank"
              rel="noreferrer"
              className="rounded-lg bg-white/15 px-3 py-2 text-xs font-semibold text-ink hover:bg-white/25"
            >
              <i className="bi bi-whatsapp" /> WhatsApp
            </a>
            <a
              href={`https://twitter.com/intent/tweet?text=${encodeURIComponent(
                `I'm earning on @TippingJar — join with my code ${code}! ${shareUrl}`,
              )}`}
              target="_blank"
              rel="noreferrer"
              className="rounded-lg bg-white/15 px-3 py-2 text-xs font-semibold text-ink hover:bg-white/25"
            >
              𝕏 Twitter / X
            </a>
          </div>
        )}
      </div>

      {/* "Your commission" is the live rate from the referrals service. The
          referral counts have no endpoint yet — the service stores codes but
          does not track which signups used them. */}
      {/* TODO(api): referral counts (total/active) + referred-users list — needs
          the referrals service to record signups per code. */}
      <div className="grid gap-4 sm:grid-cols-3">
        <StatCard label="Total referrals" value="0" icon="bi-people-fill" />
        <StatCard label="Active (earning)" value="0" icon="bi-lightning-charge-fill" />
        <StatCard label="Your commission" value={`${(rate * 100).toFixed(1)}%`} icon="bi-percent" />
      </div>

      <div>
        <h3 className="mb-3 text-base font-bold text-ink">Your referrals</h3>
        <div className="card grid place-items-center py-12 text-center">
          <div className="text-3xl text-teal"><i className="bi bi-people-fill" /></div>
          <p className="mt-3 font-semibold text-ink">No referrals yet</p>
          <p className="body-muted mt-1">Share your code above to start earning commission.</p>
        </div>
      </div>

      <div>
        <h3 className="mb-4 text-base font-bold text-ink">How it works</h3>
        <div className="space-y-4">
          {steps.map(([title, body], i) => (
            <div key={title} className="flex gap-4">
              <div className="grid h-9 w-9 shrink-0 place-items-center rounded-xl bg-primary/15 text-sm font-bold text-teal">
                {i + 1}
              </div>
              <div>
                <p className="font-semibold text-ink">{title}</p>
                <p className="body-muted">{body}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// ─── Transactions & payouts ─────────────────────────────────────────────────
function TransactionsTab({
  token,
  creatorId,
}: {
  token: string | null;
  creatorId: string | null;
}) {
  const [txns, setTxns] = useState<Transaction[]>([]);
  const [balance, setBalance] = useState<Balance | null>(null);
  const [payouts, setPayouts] = useState<Payout[]>([]);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState<string | null>(null);

  const load = useCallback(() => {
    if (!token || !creatorId) {
      setLoading(false);
      return;
    }
    setLoading(true);
    Promise.all([
      api.creatorTransactions(token, creatorId).catch(() => [] as Transaction[]),
      api.creatorBalance(token, creatorId).catch(() => null),
      api.creatorPayouts(token, creatorId).catch(() => [] as Payout[]),
    ])
      .then(([t, b, p]) => {
        setTxns(t);
        setBalance(b);
        setPayouts(p);
      })
      .finally(() => setLoading(false));
  }, [token, creatorId]);

  useEffect(() => {
    load();
  }, [load]);

  async function payout() {
    if (!token || busy) return;
    setBusy(true);
    setMsg(null);
    try {
      const po = await api.requestPayout(token, {});
      setMsg(`Payout requested: R${po.amount} (${po.status}).`);
      load();
    } catch (e) {
      setMsg(e instanceof Error ? e.message : "Payout failed.");
    } finally {
      setBusy(false);
    }
  }

  if (!creatorId) {
    return (
      <div className="card grid place-items-center py-12 text-center">
        <div className="text-3xl text-teal"><i className="bi bi-receipt" /></div>
        <p className="mt-3 font-semibold text-ink">Create a creator profile</p>
        <p className="body-muted mt-1">Set up your page to start receiving tips and see transactions.</p>
        <Link href="/onboarding" className="btn-primary mt-5 !px-5 !py-2.5 text-sm">
          Set up profile
        </Link>
      </div>
    );
  }
  if (loading) return <p className="body-muted">Loading…</p>;

  const available = Number(balance?.available ?? "0");

  return (
    <div className="space-y-8">
      <div className="grid gap-4 sm:grid-cols-3">
        <StatCard label="Net earned" value={`R${balance?.net_balance ?? "0.00"}`} icon="bi-cash-coin" accent="#004423" />
        <StatCard label="Withdrawn" value={`R${balance?.withdrawn ?? "0.00"}`} icon="bi-bank" accent="#2563EB" />
        <StatCard label="Available" value={`R${balance?.available ?? "0.00"}`} icon="bi-check-circle-fill" accent="#0097B2" />
      </div>

      <div className="card flex flex-wrap items-center justify-between gap-4">
        <div>
          <p className="font-semibold text-ink">Payouts</p>
          <p className="body-muted">Withdraw your available balance to your bank account.</p>
        </div>
        <button
          onClick={payout}
          disabled={busy || available <= 0}
          className="btn-primary disabled:cursor-not-allowed disabled:opacity-50"
        >
          {busy ? "Requesting…" : `Request payout · R${available.toFixed(2)}`}
        </button>
      </div>
      {msg && <p className="text-sm text-teal">{msg}</p>}

      <div>
        <h3 className="mb-4 text-base font-bold text-ink">Transactions</h3>
        {txns.length === 0 ? (
          <div className="card grid place-items-center py-12 text-center">
            <div className="text-3xl text-teal"><i className="bi bi-receipt" /></div>
            <p className="mt-3 font-semibold text-ink">No transactions yet</p>
            <p className="body-muted mt-1">Tips and card payments will show up here.</p>
          </div>
        ) : (
          <div className="card overflow-hidden !p-0">
            <div className="overflow-x-auto">
              <table className="w-full min-w-[640px] text-left text-sm">
                <thead className="border-b border-border text-xs uppercase tracking-wide text-muted">
                  <tr>
                    <th className="px-5 py-3 font-semibold">Reference</th>
                    <th className="px-5 py-3 font-semibold">Date</th>
                    <th className="px-5 py-3 font-semibold">Status</th>
                    <th className="px-5 py-3 text-right font-semibold">Amount</th>
                    <th className="px-5 py-3 text-right font-semibold">You get</th>
                  </tr>
                </thead>
                <tbody>
                  {txns.map((t) => (
                    <tr key={t.id} className="border-b border-border/60 last:border-0">
                      <td className="px-5 py-3 font-mono text-xs text-muted">
                        {t.reference.slice(0, 18)}…
                      </td>
                      <td className="px-5 py-3 text-muted">
                        {new Date(t.created_at).toLocaleDateString()}
                      </td>
                      <td className="px-5 py-3">
                        <span
                          className={`rounded-full px-2.5 py-1 text-xs font-semibold ${
                            t.status === "completed"
                              ? "bg-teal/10 text-teal"
                              : t.status === "pending"
                                ? "bg-yellow-500/10 text-yellow-300"
                                : "bg-red-500/10 text-red-400"
                          }`}
                        >
                          {t.status}
                        </span>
                      </td>
                      <td className="px-5 py-3 text-right text-ink">
                        {t.currency} {t.amount}
                      </td>
                      <td className="px-5 py-3 text-right font-bold text-ink">R{t.creator_net}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>

      {payouts.length > 0 && (
        <div>
          <h3 className="mb-4 text-base font-bold text-ink">Payout history</h3>
          <div className="space-y-2">
            {payouts.map((p) => (
              <div key={p.id} className="card flex flex-wrap items-center justify-between gap-3 !py-3">
                <span className="font-mono text-xs text-muted">{p.reference}</span>
                <span className="text-sm text-muted">
                  {new Date(p.created_at).toLocaleDateString()}
                </span>
                <span className="rounded-full bg-border px-2.5 py-1 text-xs text-muted">
                  {p.status}
                </span>
                <span className="font-bold text-ink">R{p.amount}</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

// ─── Studio (studio_tab.dart) ──────────────────────────────────────────────────
function StudioTab() {
  return (
    <div className="max-w-3xl space-y-6">
      <div>
        <h2 className="text-xl font-extrabold tracking-tight text-ink">Creator Studio</h2>
        <p className="body-muted mt-1">
          Design share-ready promo graphics for your tip page — square, portrait, story and
          landscape sizes, with text, shapes, colours and gradients.
        </p>
      </div>

      {/* The full canvas editor (drag/resize elements, export PNG, saved gallery)
          is a rich client-only tool. Rendered here as a feature placeholder. */}
      {/* TODO(api): none required — studio is client-side; port the canvas editor from studio_tab.dart */}
      <div className="card grid place-items-center py-16 text-center">
        <div className="text-4xl text-teal"><i className="bi bi-palette-fill" /></div>
        <p className="mt-4 text-lg font-semibold text-ink">Design studio coming to the web</p>
        <p className="body-muted mt-2 max-w-md">
          Create branded assets with text, shapes and gradients, then export and save them to
          your gallery. The full editor is being ported.
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {["Square", "Portrait", "Story", "Landscape"].map((s) => (
          <div key={s} className="card !p-4 text-center">
            <div className="mx-auto mb-3 h-16 w-16 rounded-lg bg-brand-gradient opacity-80" />
            <p className="text-sm font-semibold text-ink">{s}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
