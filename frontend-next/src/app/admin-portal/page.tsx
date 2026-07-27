"use client";

// Admin portal — ported from frontend/lib/screens/admin_portal_screen.dart
// Flutter tabs: Overview · Users · Tips · Creators · Enterprises · Blog · Careers.
// Overview is powered by api.dashboard() (aggregate JSON). Management tabs have
// no read/write endpoints wired here yet, so they render as placeholders.

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";

type Tab = "overview" | "users" | "tips" | "creators" | "enterprises" | "blog" | "careers";

const TABS: { id: Tab; label: string; icon: string }[] = [
  { id: "overview", label: "Overview", icon: "bi-bar-chart-fill" },
  { id: "users", label: "Users", icon: "bi-person-fill" },
  { id: "tips", label: "Tips", icon: "bi-receipt" },
  { id: "creators", label: "Creators", icon: "bi-patch-check-fill" },
  { id: "enterprises", label: "Enterprises", icon: "bi-building" },
  { id: "blog", label: "Blog", icon: "bi-pencil-square" },
  { id: "careers", label: "Careers", icon: "bi-briefcase-fill" },
];

const money = (n: number) =>
  n.toLocaleString("en-ZA", { minimumFractionDigits: 2, maximumFractionDigits: 2 });

export default function AdminPortalPage() {
  const { isAuthenticated, isAdmin, initialized } = useAuth();
  const router = useRouter();
  const [tab, setTab] = useState<Tab>("overview");
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  useEffect(() => {
    if (initialized && !isAuthenticated) router.push("/login");
  }, [initialized, isAuthenticated, router]);

  useEffect(() => {
    if (!isAuthenticated || !isAdmin) return;
    let alive = true;
    api
      .dashboard()
      .then((d) => {
        if (!alive) return;
        setData(d);
        setLoading(false);
      })
      .catch(() => {
        if (!alive) return;
        setError(true);
        setLoading(false);
      });
    return () => {
      alive = false;
    };
  }, [isAuthenticated, isAdmin]);

  if (!initialized || !isAuthenticated) {
    return (
      <div className="container-content grid min-h-[60vh] place-items-center">
        <p className="body-muted">Loading…</p>
      </div>
    );
  }

  if (!isAdmin) {
    return (
      <div className="container-content grid min-h-[60vh] place-items-center text-center">
        <div>
          <div className="text-4xl text-teal"><i className="bi bi-lock-fill" /></div>
          <h1 className="mt-4 text-xl font-bold text-ink">Admins only</h1>
          <p className="body-muted mt-2">You don&apos;t have permission to view this page.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="app-shell container-content py-10">
      <div>
        <p className="text-sm text-muted">TippingJar</p>
        <h1 className="text-2xl font-extrabold tracking-tight text-ink">Admin Portal</h1>
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
        {tab === "overview" ? (
          <OverviewTab data={data} loading={loading} error={error} />
        ) : (
          <PlaceholderTab tab={tab} />
        )}
      </div>
    </div>
  );
}

function StatCard({
  label,
  value,
  icon,
  accent,
}: {
  label: string;
  value: string;
  icon: string;
  accent: string;
}) {
  return (
    <div className="card !p-5">
      <div
        className="grid h-10 w-10 place-items-center rounded-xl text-lg"
        style={{ backgroundColor: accent + "22" }}
      >
        <i className={`bi ${icon}`} style={{ color: accent }} />
      </div>
      <p className="mt-4 text-2xl font-extrabold tracking-tight text-ink">{value}</p>
      <p className="mt-1 text-xs text-muted">{label}</p>
    </div>
  );
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function OverviewTab({ data, loading, error }: { data: any; loading: boolean; error: boolean }) {
  if (loading) return <p className="body-muted">Loading dashboard…</p>;
  if (error || !data)
    return (
      <div className="card grid place-items-center py-12 text-center">
        <div className="text-3xl text-teal"><i className="bi bi-graph-down-arrow" /></div>
        <p className="mt-3 font-semibold text-ink">Could not load dashboard</p>
        <p className="body-muted mt-1">The admin dashboard service is unavailable.</p>
      </div>
    );

  const s = data.sources ?? {};
  const creators = s.creators?.count ?? 0;
  const tipsCount = s.tips?.count ?? 0;
  const tipsVolume = Number(s.tips?.total_amount ?? 0);
  const contacts = s.contacts?.count ?? 0;
  const disputes = s.disputes?.count ?? 0;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const recentTips: any[] = Array.isArray(data.recent_tips) ? data.recent_tips : [];

  return (
    <div className="space-y-8">
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5">
        <StatCard label="Creators" value={`${creators}`} icon="bi-patch-check-fill" accent="#004423" />
        <StatCard label="Total tips" value={`${tipsCount}`} icon="bi-receipt" accent="#FBBF24" />
        <StatCard label="Volume (R)" value={`R ${money(tipsVolume)}`} icon="bi-cash-coin" accent="#34D399" />
        <StatCard label="Contact messages" value={`${contacts}`} icon="bi-envelope-fill" accent="#0097B2" />
        <StatCard label="Disputes" value={`${disputes}`} icon="bi-shield-fill-exclamation" accent="#F87171" />
      </div>

      <div>
        <h3 className="mb-4 text-base font-bold text-ink">Recent tips</h3>
        {recentTips.length === 0 ? (
          <div className="card grid place-items-center py-12 text-center">
            <div className="text-3xl text-teal"><i className="bi bi-receipt" /></div>
            <p className="mt-3 font-semibold text-ink">No recent tips</p>
          </div>
        ) : (
          <div className="card overflow-hidden !p-0">
            <div className="overflow-x-auto">
              <table className="w-full min-w-[640px] text-left text-sm">
                <thead className="border-b border-border text-xs uppercase tracking-wide text-muted">
                  <tr>
                    <th className="px-5 py-3 font-semibold">From</th>
                    <th className="px-5 py-3 font-semibold">To</th>
                    <th className="px-5 py-3 font-semibold">Status</th>
                    <th className="px-5 py-3 text-right font-semibold">Amount</th>
                  </tr>
                </thead>
                <tbody>
                  {recentTips.map((t, i) => (
                    <tr key={t.id ?? i} className="border-b border-border/60 last:border-0">
                      <td className="px-5 py-3 font-medium text-ink">
                        {t.tipper_name || "Anonymous"}
                      </td>
                      <td className="px-5 py-3 text-muted">
                        {t.creator_name || t.creator_slug || "—"}
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
    </div>
  );
}

function PlaceholderTab({ tab }: { tab: Tab }) {
  const copy: Record<string, string> = {
    users: "User management — list, filter by role, activate/deactivate, promote to admin.",
    tips: "Full tips ledger with status filters and totals.",
    creators: "KYC review — approve or decline creator verification and documents.",
    enterprises: "Enterprise approvals — review applications and supporting documents.",
    blog: "Blog editor — create, publish and delete posts.",
    careers: "Job listings management.",
  };
  return (
    <div className="card grid place-items-center py-16 text-center">
      <div className="text-3xl text-teal"><i className="bi bi-tools" /></div>
      <p className="mt-3 font-semibold capitalize text-ink">{tab}</p>
      <p className="body-muted mt-1 max-w-md">{copy[tab]}</p>
      {/* TODO(api): admin management endpoints for the "{tab}" tab (list + mutations) */}
      <p className="mt-3 text-xs text-muted">Management actions coming soon.</p>
    </div>
  );
}
