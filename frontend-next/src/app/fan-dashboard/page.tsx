"use client";

// Fan dashboard — ported from frontend/lib/screens/fan_dashboard_screen.dart
// Flutter tabs: Home · Live · Content · Activity · Settings. Here we surface
// Home (welcome + stats + discover), Activity (tips-sent history + pledges) and
// Settings. Fan-scoped data (sent tips, pledges, streaks) has no API endpoint
// yet, so those render as placeholders with TODO(api) markers.

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { CreatorCard } from "@/components/CreatorCard";
import type { Creator, Tip } from "@/types";

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
  const { user, token, isAuthenticated, initialized, logout } = useAuth();
  const router = useRouter();
  const [tab, setTab] = useState<Tab>("home");
  const [creators, setCreators] = useState<Creator[]>([]);
  const [myTips, setMyTips] = useState<Tip[]>([]);

  useEffect(() => {
    if (initialized && !isAuthenticated) router.push("/login");
  }, [initialized, isAuthenticated, router]);

  useEffect(() => {
    if (!isAuthenticated) return;
    api
      .listCreators()
      .then((c) => setCreators(c.slice(0, 8)))
      .catch(() => setCreators([]));
    if (user?.email) {
      api
        .tipsForFan(user.email)
        .then(setMyTips)
        .catch(() => setMyTips([]));
    }
  }, [isAuthenticated, user?.email]);

  if (!initialized || !isAuthenticated) {
    return (
      <div className="container-content grid min-h-[60vh] place-items-center">
        <p className="body-muted">Loading…</p>
      </div>
    );
  }

  const name = user?.username || "there";
  const totalGiven = myTips.reduce((s, t) => s + parseFloat(t.amount || "0"), 0);
  const creatorsSupported = new Set(myTips.map((t) => t.creator_id)).size;

  return (
    <div className="app-shell container-content py-10">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <p className="text-sm text-muted">{greeting()}</p>
          <h1 className="text-2xl font-extrabold tracking-tight text-ink">{name}</h1>
        </div>
        <Link href="/creators" className="btn-ghost !px-4 !py-2 text-sm">
          Discover creators
        </Link>
      </div>

      <div className="mt-8 flex gap-2 overflow-x-auto border-b border-border pb-px">
        {TABS.map((t) => (
          <button
            key={t.id}
            onClick={() => setTab(t.id)}
            className={`flex items-center gap-2 whitespace-nowrap rounded-t-lg px-4 py-2.5 text-sm font-semibold transition ${
              tab === t.id ? "border-b-2 border-teal text-ink" : "text-muted hover:text-ink"
            }`}
          >
            <span className="flex"><i className={`bi ${t.icon}`} /></span>
            {t.label}
          </button>
        ))}
      </div>

      <div className="mt-8">
        {tab === "home" && (
          <HomeTab
            name={name}
            creators={creators}
            tipsCount={myTips.length}
            totalGiven={totalGiven}
            creatorsSupported={creatorsSupported}
          />
        )}
        {tab === "activity" && <ActivityTab tips={myTips} />}
        {tab === "settings" && (
          <SettingsTab twoFa={user?.two_fa_enabled ?? false} token={token} onLogout={logout} />
        )}
      </div>
    </div>
  );
}

function StatCard({ label, value, icon }: { label: string; value: string; icon: string }) {
  return (
    <div className="card !p-5">
      <div className="text-lg text-teal"><i className={`bi ${icon}`} /></div>
      <p className="mt-3 text-2xl font-extrabold tracking-tight text-ink">{value}</p>
      <p className="mt-1 text-xs text-muted">{label}</p>
    </div>
  );
}

// ─── Home ──────────────────────────────────────────────────────────────────────
function HomeTab({
  name,
  creators,
  tipsCount,
  totalGiven,
  creatorsSupported,
}: {
  name: string;
  creators: Creator[];
  tipsCount: number;
  totalGiven: number;
  creatorsSupported: number;
}) {
  return (
    <div className="space-y-10">
      <div className="card bg-brand-gradient !border-transparent">
        <h2 className="text-2xl font-extrabold tracking-tight text-ink">
          {greeting()}, {name}
        </h2>
        <p className="mt-2 text-sm text-white/85">Ready to support your favourite creators?</p>
        <Link
          href="/creators"
          className="mt-5 inline-flex rounded-full bg-white px-5 py-2.5 text-sm font-semibold text-primary transition hover:opacity-90"
        >
          Discover creators →
        </Link>
      </div>

      <div className="grid gap-4 sm:grid-cols-3">
        <StatCard label="Tips sent" value={String(tipsCount)} icon="bi-heart-fill" />
        <StatCard label="Total given" value={`R${totalGiven.toFixed(2)}`} icon="bi-cash-stack" />
        <StatCard label="Creators supported" value={String(creatorsSupported)} icon="bi-people-fill" />
      </div>

      <div>
        <div className="mb-5 flex items-end justify-between">
          <h3 className="text-base font-bold text-ink">Discover creators</h3>
          <Link href="/creators" className="text-sm text-teal hover:underline">
            See all →
          </Link>
        </div>
        {creators.length === 0 ? (
          <p className="body-muted">No creators to show yet.</p>
        ) : (
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {creators.map((c) => (
              <CreatorCard key={c.id} creator={c} />
            ))}
          </div>
        )}
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
            <div className="text-3xl text-teal"><i className="bi bi-heart-fill" /></div>
            <p className="mt-3 font-semibold text-ink">No tips sent yet</p>
            <p className="body-muted mt-1 max-w-sm">
              Find a creator you love and send your first tip!
            </p>
            <Link href="/creators" className="btn-primary mt-5 !px-5 !py-2.5 text-sm">
              Browse creators
            </Link>
          </div>
        ) : (
          <div className="space-y-3">
            {tips.map((t) => (
              <div key={t.id} className="card flex items-center justify-between !py-4">
                <div className="min-w-0">
                  <p className="font-semibold text-ink">{t.creator_name}</p>
                  {t.message && <p className="body-muted truncate text-sm">{t.message}</p>}
                  <p className="mt-1 text-xs text-muted">
                    {new Date(t.created_at).toLocaleDateString()}
                  </p>
                </div>
                <span className="whitespace-nowrap font-bold text-teal">R{t.amount}</span>
              </div>
            ))}
          </div>
        )}
      </div>

      <div>
        <h3 className="mb-4 text-base font-bold text-ink">My pledges</h3>
        {/* TODO(api): fan pledges (recurring monthly support) endpoint */}
        <div className="card grid place-items-center py-12 text-center">
          <div className="text-3xl text-teal"><i className="bi bi-arrow-repeat" /></div>
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
              {enabled ? "Verification code sent on each login." : "2FA is off."}
            </p>
          </div>
          <button
            onClick={toggle}
            disabled={saving}
            className={`rounded-full px-4 py-1.5 text-xs font-semibold transition disabled:opacity-50 ${
              enabled ? "bg-teal/10 text-teal hover:bg-teal/20" : "bg-border text-muted hover:text-ink"
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
            <span>Browse all creators</span>
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
