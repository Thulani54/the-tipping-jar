"use client";

// Fan dashboard — ported from frontend/lib/screens/fan_dashboard_screen.dart
// Flutter tabs: Home · Live · Content · Activity · Settings. Here we surface
// Home (welcome + stats + discover), Activity (tips-sent history + pledges) and
// Settings. Fan-scoped data (sent tips, pledges, streaks) has no API endpoint
// yet, so those render as placeholders with TODO(api) markers.

import { Suspense, useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import type { Tip } from "@/types";
import { Logo } from "@/components/Logo";
import {
  ArrowUpRight,
  Home,
  History,
  Settings,
  LogOut,
  Menu,
  X,
  Heart,
} from "lucide-react";

type Tab = "home" | "activity" | "settings";

const TABS: { id: Tab; label: string; icon: string }[] = [
  { id: "home", label: "Home", icon: "bi-house-door-fill" },
  { id: "activity", label: "Activity", icon: "bi-clock-history" },
  { id: "settings", label: "Settings", icon: "bi-gear-fill" },
];

function greeting(): string {
  const h = new Date().getHours();
  if (h < 12) return "Good morning";
  if (h < 17) return "Good afternoon";
  return "Good evening";
}

export default function FanDashboardPage() {
  return (
    <Suspense fallback={<div className="p-10">Loading your workspace…</div>}>
      <FanDashboardInner />
    </Suspense>
  );
}

function FanDashboardInner() {
  const { user, token, isAuthenticated, initialized, logout } = useAuth();
  const router = useRouter();
  const search = useSearchParams();
  const requestedTab = search.get("tab");
  const tab: Tab =
    requestedTab === "activity" || requestedTab === "settings"
      ? requestedTab
      : "home";
  const [mobileOpen, setMobileOpen] = useState(false);
  const [loadError, setLoadError] = useState(false);
  const [loading, setLoading] = useState(true);
  const [retry, setRetry] = useState(0);
  const signOut = () => {
    if (window.confirm("Log out of your Tipping Jar account?")) logout();
  };
  const [myTips, setMyTips] = useState<Tip[]>([]);

  useEffect(() => {
    if (initialized && !isAuthenticated) router.push("/login");
  }, [initialized, isAuthenticated, router]);

  useEffect(() => {
    if (!isAuthenticated) return;
    // Creator directory is hidden during private beta — no listCreators
    // fetch here; the HomeTab shows a waitlist pointer instead.
    if (user?.email) {
      setLoading(true);
      setLoadError(false);
      api
        .tipsForFan(user.email)
        .then(setMyTips)
        .catch(() => setLoadError(true))
        .finally(() => setLoading(false));
    }
  }, [isAuthenticated, user?.email, retry]);

  if (!initialized || !isAuthenticated) {
    return (
      <div className="container-content grid min-h-[60vh] place-items-center">
        <p className="body-muted">Loading…</p>
      </div>
    );
  }

  const name = user?.username || "there";
  const totalGiven = myTips.reduce(
    (s, t) => s + parseFloat(t.amount || "0"),
    0,
  );
  const creatorsSupported = new Set(myTips.map((t) => t.creator_id)).size;

  return (
    <div className="app-shell tj-workspace tj-supporter-shell">
      {mobileOpen && (
        <button
          className="tj-supporter-backdrop"
          aria-label="Close menu"
          onClick={() => setMobileOpen(false)}
        />
      )}
      <aside className={`tj-supporter-sidebar ${mobileOpen ? "is-open" : ""}`}>
        <div className="tj-supporter-brand">
          <Logo size={36} />
          <button
            className="lg:hidden"
            onClick={() => setMobileOpen(false)}
            aria-label="Close menu"
          >
            <X size={20} />
          </button>
        </div>
        <p className="tj-sidebar-label">Your supporter space</p>
        <nav aria-label="Supporter navigation">
          {TABS.map((t, i) => {
            const Icon = [Home, History, Settings][i];
            return (
              <Link
                key={t.id}
                href={
                  t.id === "home"
                    ? "/fan-dashboard"
                    : `/fan-dashboard?tab=${t.id}`
                }
                onClick={() => setMobileOpen(false)}
                aria-current={tab === t.id ? "page" : undefined}
                className={`tj-workspace-nav-row ${tab === t.id ? "is-active" : ""}`}
              >
                <span>
                  <Icon size={19} />
                </span>
                <span>{t.id === "home" ? "Overview" : t.label}</span>
              </Link>
            );
          })}
        </nav>
        <div className="tj-supporter-sidebar-note">
          <Heart size={24} />
          <p>
            Small gestures.
            <br />
            Lasting impact.
          </p>
          <span>Thanks for showing up for the people who inspire you.</span>
        </div>
        <button className="tj-workspace-nav-row is-danger" onClick={signOut}>
          <span>
            <LogOut size={19} />
          </span>
          <span>Log out</span>
        </button>
      </aside>
      <div className="tj-supporter-content">
        <header className="tj-supporter-header">
          <button
            className="lg:hidden"
            onClick={() => setMobileOpen(true)}
            aria-label="Open menu"
          >
            <Menu size={21} />
          </button>
          <span>
            My account <span className="mx-2 text-muted">/</span>{" "}
            {tab === "home"
              ? "Overview"
              : TABS.find((t) => t.id === tab)?.label}
          </span>
          <Link href="/" className="ml-auto">
            Visit website <ArrowUpRight size={16} />
          </Link>
          <span className="tj-account-avatar">
            {name.charAt(0).toUpperCase()}
          </span>
        </header>
        <main className="tj-workspace-main">
          <div className="tj-workspace-intro">
            <div>
              <p className="tj-workspace-eyebrow">Your supporter workspace</p>
              <h1>
                {tab === "home"
                  ? `${greeting()}, ${name}.`
                  : tab === "activity"
                    ? "Your activity"
                    : "Account settings"}
              </h1>
              <p>
                {tab === "home"
                  ? "The little things you give make a big difference."
                  : tab === "activity"
                    ? "A record of the support you’ve shared."
                    : "Manage your security and account preferences."}
              </p>
            </div>
          </div>
          {loadError && (
            <div role="alert" className="tj-data-error">
              We couldn’t load your tips.{" "}
              <button onClick={() => setRetry((n) => n + 1)}>Try again</button>
            </div>
          )}
          {loading && tab !== "settings" ? (
            <div className="card py-12 text-muted" role="status">
              Loading your support history…
            </div>
          ) : !loadError ? (
            <>
              {tab === "home" && (
                <HomeTab
                  name={name}
                  tipsCount={myTips.length}
                  totalGiven={totalGiven}
                  creatorsSupported={creatorsSupported}
                />
              )}
              {tab === "activity" && <ActivityTab tips={myTips} />}
            </>
          ) : null}
          {tab === "settings" && (
            <SettingsTab
              twoFa={user?.two_fa_enabled ?? false}
              token={token}
              onLogout={signOut}
            />
          )}
        </main>
      </div>
    </div>
  );
}

function StatCard({
  label,
  value,
  icon,
}: {
  label: string;
  value: string;
  icon: string;
}) {
  return (
    <div className="card !p-5">
      <div className="text-lg text-teal">
        <i className={`bi ${icon}`} />
      </div>
      <p className="mt-3 text-2xl font-extrabold tracking-tight text-ink">
        {value}
      </p>
      <p className="mt-1 text-xs text-muted">{label}</p>
    </div>
  );
}

// ─── Home ──────────────────────────────────────────────────────────────────────
function HomeTab({
  name,
  tipsCount,
  totalGiven,
  creatorsSupported,
}: {
  name: string;
  tipsCount: number;
  totalGiven: number;
  creatorsSupported: number;
}) {
  return (
    <div className="space-y-10">
      <div className="tj-supporter-welcome">
        <h2 className="text-2xl font-extrabold tracking-tight text-ink">
          Your support means something.
        </h2>
        <p className="mt-2 text-sm text-white/85">
          Every tip is a little encouragement to keep going. Open a creator’s
          personal link to send your next thank you.
        </p>
        <Link
          href="/how-it-works"
          className="mt-5 inline-flex rounded-full bg-white px-5 py-2.5 text-sm font-semibold text-primary transition hover:opacity-90"
        >
          How tipping works →
        </Link>
      </div>

      <div className="grid gap-4 sm:grid-cols-3">
        <StatCard
          label="Tips sent"
          value={String(tipsCount)}
          icon="bi-heart-fill"
        />
        <StatCard
          label="Total given"
          value={`R${totalGiven.toFixed(2)}`}
          icon="bi-cash-stack"
        />
        <StatCard
          label="Creators supported"
          value={String(creatorsSupported)}
          icon="bi-people-fill"
        />
      </div>

      {/* Discover-creators grid hidden during private beta — the public
          directory is behind a waitlist and unvetted profiles shouldn't
          be surfaced here either. Replaced with a small pointer card
          so the section slot still guides the fan forward. */}
      <div className="card flex flex-col items-start gap-3 !p-5 sm:flex-row sm:items-center">
        <span className="grid h-11 w-11 shrink-0 place-items-center rounded-full bg-mint/20 text-teal">
          <i className="bi bi-envelope-heart-fill text-lg" />
        </span>
        <div className="min-w-0 flex-1">
          <p className="font-semibold text-ink">
            Creator directory — opening soon
          </p>
          <p className="body-muted mt-0.5 text-sm">
            Every listed creator will be vetted. Join the waitlist to get an
            email the moment browsing opens.
          </p>
        </div>
        <Link
          href="/creators"
          className="btn-primary shrink-0 !px-5 !py-2.5 text-sm"
        >
          Join waitlist →
        </Link>
      </div>
    </div>
  );
}

// ─── Activity ───────────────────────────────────────────────────────────────────
function ActivityTab({ tips }: { tips: Tip[] }) {
  return (
    <div className="max-w-3xl space-y-10">
      <div>
        <h3 className="mb-4 text-base font-bold text-ink">Your tips</h3>
        {tips.length === 0 ? (
          <div className="card grid place-items-center py-12 text-center">
            <div className="text-3xl text-teal">
              <i className="bi bi-heart-fill" />
            </div>
            <p className="mt-3 font-semibold text-ink">No tips sent yet</p>
            <p className="body-muted mt-1 max-w-sm">
              Open a creator’s personal tip link to send your first thank you.
            </p>
            <Link
              href="/creators"
              className="btn-primary mt-5 !px-5 !py-2.5 text-sm"
            >
              Directory waitlist
            </Link>
          </div>
        ) : (
          <div className="space-y-3">
            {tips.map((t) => (
              <div
                key={t.id}
                className="card flex items-center justify-between !py-4"
              >
                <div className="min-w-0">
                  <p className="font-semibold text-ink">{t.creator_name}</p>
                  {t.message && (
                    <p className="body-muted truncate text-sm">{t.message}</p>
                  )}
                  <p className="mt-1 text-xs text-muted">
                    {new Date(t.created_at).toLocaleDateString()}
                  </p>
                </div>
                <span className="whitespace-nowrap font-bold text-teal">
                  R{t.amount}
                </span>
              </div>
            ))}
          </div>
        )}
      </div>

      <div>
        <h3 className="mb-4 text-base font-bold text-ink">My pledges</h3>
        {/* TODO(api): fan pledges (recurring monthly support) endpoint */}
        <div className="card grid place-items-center py-12 text-center">
          <div className="text-3xl text-teal">
            <i className="bi bi-arrow-repeat" />
          </div>
          <p className="mt-3 font-semibold text-ink">No active pledges</p>
          <p className="body-muted mt-1 max-w-sm">
            Set up recurring monthly support for the creators you follow.
          </p>
        </div>
      </div>
    </div>
  );
}

// ─── Settings ───────────────────────────────────────────────────────────────────
function SettingsTab({
  twoFa,
  token,
  onLogout,
}: {
  twoFa: boolean;
  token: string | null;
  onLogout: () => void;
}) {
  const [enabled, setEnabled] = useState(twoFa);
  const [saving, setSaving] = useState(false);

  async function toggle() {
    if (!token || saving) return;
    setSaving(true);
    try {
      await api.set2fa(token, !enabled);
      setEnabled(!enabled);
    } catch {
      // keep previous state on failure
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="max-w-2xl space-y-6">
      <div className="card">
        <div className="flex items-center justify-between gap-4">
          <div>
            <p className="font-semibold text-ink">Two-factor authentication</p>
            <p className="body-muted mt-1">
              {enabled
                ? "Verification code sent on each login."
                : "2FA is off."}
            </p>
          </div>
          <button
            onClick={toggle}
            disabled={saving}
            className={`rounded-full px-4 py-1.5 text-xs font-semibold transition disabled:opacity-50 ${
              enabled
                ? "bg-teal/10 text-teal hover:bg-teal/20"
                : "bg-border text-muted hover:text-ink"
            }`}
          >
            {saving ? "…" : enabled ? "On · turn off" : "Off · turn on"}
          </button>
        </div>
      </div>

      <div className="card">
        <p className="font-semibold text-ink">Account</p>
        <div className="mt-3 divide-y divide-border/60">
          <Link
            href="/creators"
            className="flex items-center justify-between py-3 text-sm text-ink hover:text-teal"
          >
            <span>Creator directory waitlist</span>
            <span className="text-muted">›</span>
          </Link>
          <button
            onClick={onLogout}
            className="flex w-full items-center justify-between py-3 text-left text-sm text-red-400 hover:text-red-300"
          >
            <span>Sign out</span>
            <span>›</span>
          </button>
        </div>
      </div>
    </div>
  );
}
