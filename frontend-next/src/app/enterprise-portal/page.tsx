"use client";

// Enterprise portal — ported from frontend/lib/screens/enterprise_portal_screen.dart
// Flutter tabs: Overview · Creators · Distributions · Settings · Disputes.
// We resolve the current user's enterprise from listEnterprises() (no "my
// enterprise" endpoint yet). Managed-creator and distribution data have no
// endpoints, so they render as placeholders with TODO(api) markers.

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import type { Enterprise } from "@/types";

type Tab = "overview" | "creators" | "distributions" | "settings";

const TABS: { id: Tab; label: string; icon: string }[] = [
  { id: "overview", label: "Overview", icon: "bi-bar-chart-fill" },
  { id: "creators", label: "Creators", icon: "bi-people-fill" },
  { id: "distributions", label: "Distributions", icon: "bi-cash-coin" },
  { id: "settings", label: "Settings", icon: "bi-gear-fill" },
];

export default function EnterprisePortalPage() {
  const { user, isAuthenticated, initialized } = useAuth();
  const router = useRouter();
  const [tab, setTab] = useState<Tab>("overview");
  const [enterprise, setEnterprise] = useState<Enterprise | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (initialized && !isAuthenticated) router.push("/login");
  }, [initialized, isAuthenticated, router]);

  useEffect(() => {
    if (!isAuthenticated || !user) return;
    let alive = true;
    // TODO(api): a "my enterprise" endpoint; we filter the public list by admin_user_id.
    api
      .listEnterprises()
      .then((list) => {
        if (!alive) return;
        setEnterprise(list.find((e) => e.admin_user_id === user.id) ?? null);
        setLoading(false);
      })
      .catch(() => {
        if (!alive) return;
        setEnterprise(null);
        setLoading(false);
      });
    return () => {
      alive = false;
    };
  }, [isAuthenticated, user]);

  if (!initialized || !isAuthenticated) {
    return (
      <div className="container-content grid min-h-[60vh] place-items-center">
        <p className="body-muted">Loading portal…</p>
      </div>
    );
  }

  return (
    <div className="app-shell container-content py-10">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <p className="text-sm text-muted">Enterprise Portal</p>
          <h1 className="text-2xl font-extrabold tracking-tight text-ink">
            {enterprise?.name || "Your organisation"}
          </h1>
        </div>
        {enterprise && (
          <span
            className={`rounded-full px-3 py-1 text-xs font-semibold ${
              enterprise.approval_status === "approved"
                ? "bg-teal/10 text-teal"
                : "bg-yellow-400/10 text-yellow-400"
            }`}
          >
            {(enterprise.approval_status || "pending").toUpperCase()}
          </span>
        )}
      </div>

      {loading ? (
        <p className="body-muted mt-10">Loading…</p>
      ) : !enterprise ? (
        <NoEnterprise />
      ) : (
        <>
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
            {tab === "overview" && <OverviewTab enterprise={enterprise} />}
            {tab === "creators" && <CreatorsTab />}
            {tab === "distributions" && <DistributionsTab />}
            {tab === "settings" && <SettingsTab enterprise={enterprise} />}
          </div>
        </>
      )}
    </div>
  );
}

function StatCard({
  label,
  value,
  icon,
  highlight,
}: {
  label: string;
  value: string;
  icon: string;
  highlight?: boolean;
}) {
  return (
    <div className={`card !p-5 ${highlight ? "!border-teal/40" : ""}`}>
      <div className="text-lg text-teal"><i className={`bi ${icon}`} /></div>
      <p className="mt-3 text-2xl font-extrabold tracking-tight text-ink">{value}</p>
      <p className="mt-1 text-xs text-muted">{label}</p>
    </div>
  );
}

function NoEnterprise() {
  return (
    <div className="mt-10 card grid place-items-center py-16 text-center">
      <div className="text-4xl text-teal"><i className="bi bi-building" /></div>
      <p className="mt-4 text-lg font-semibold text-ink">No enterprise linked to your account</p>
      <p className="body-muted mt-2 max-w-md">
        Apply to run tipping at scale for your platform. Your account will be reviewed before
        portal access is granted.
      </p>
      {/* TODO(api): enterprise self-setup / apply endpoint */}
      <Link href="/partner-apply" className="btn-primary mt-6 !px-6 !py-2.5 text-sm">
        Apply for access
      </Link>
    </div>
  );
}

// ─── Overview ────────────────────────────────────────────────────────────────
function OverviewTab({ enterprise }: { enterprise: Enterprise }) {
  return (
    <div className="space-y-8">
      <div>
        <h2 className="text-xl font-extrabold tracking-tight text-ink">Overview</h2>
        <p className="body-muted mt-1">{enterprise.name}</p>
      </div>
      {/* TODO(api): enterprise stats (creator count, tips, earned, distributed) */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <StatCard label="Managed creators" value="0" icon="bi-people-fill" />
        <StatCard label="Total tips received" value="0" icon="bi-credit-card-fill" />
        <StatCard label="Total earned" value="R0.00" icon="bi-graph-up-arrow" highlight />
        <StatCard label="Total distributed" value="R0.00" icon="bi-cash-coin" />
        <StatCard label="Distributions" value="0" icon="bi-receipt" />
      </div>

      <div>
        <h3 className="mb-4 text-base font-bold text-ink">Earnings per creator</h3>
        <div className="card grid place-items-center py-12 text-center">
          <div className="text-3xl text-teal"><i className="bi bi-bar-chart-fill" /></div>
          <p className="mt-3 font-semibold text-ink">No earnings data yet</p>
          <p className="body-muted mt-1">Add creators to start tracking earnings.</p>
        </div>
      </div>
    </div>
  );
}

// ─── Creators ────────────────────────────────────────────────────────────────
function CreatorsTab() {
  return (
    <div className="max-w-3xl space-y-6">
      <h2 className="text-xl font-extrabold tracking-tight text-ink">Managed creators</h2>

      {/* TODO(api): enterprise members endpoints (list / add by slug / remove) */}
      <div className="card">
        <p className="font-semibold text-ink">Add a creator</p>
        <div className="mt-3 flex flex-wrap gap-3">
          <input
            type="text"
            placeholder="creator-slug"
            className="min-w-0 flex-1 rounded-lg border border-border bg-dark px-4 py-2.5 text-sm text-ink placeholder:text-muted focus:border-teal focus:outline-none"
          />
          <button
            type="button"
            disabled
            className="cursor-not-allowed rounded-lg bg-primary/40 px-5 py-2.5 text-sm font-semibold text-ink"
          >
            Add
          </button>
        </div>
      </div>

      <div className="card grid place-items-center py-12 text-center">
        <div className="text-3xl text-teal"><i className="bi bi-people-fill" /></div>
        <p className="mt-3 font-semibold text-ink">No creators yet</p>
        <p className="body-muted mt-1">Add a creator above to manage them under your enterprise.</p>
      </div>
    </div>
  );
}

// ─── Distributions ────────────────────────────────────────────────────────────
function DistributionsTab() {
  return (
    <div className="max-w-3xl space-y-6">
      <h2 className="text-xl font-extrabold tracking-tight text-ink">Distributions</h2>
      {/* TODO(api): distributions endpoints (list history / create payout run) */}
      <div className="card grid place-items-center py-16 text-center">
        <div className="text-3xl text-teal"><i className="bi bi-cash-coin" /></div>
        <p className="mt-3 font-semibold text-ink">No distributions yet</p>
        <p className="body-muted mt-1 max-w-sm">
          Distribute pooled tips to your managed creators. History will appear here.
        </p>
      </div>
    </div>
  );
}

// ─── Settings ────────────────────────────────────────────────────────────────
function SettingsTab({ enterprise }: { enterprise: Enterprise }) {
  const rows: [string, string][] = [
    ["Name", enterprise.name],
    ["Plan", enterprise.plan || "—"],
    ["Website", enterprise.website || "—"],
    ["Contact name", enterprise.contact_name || "—"],
    ["Contact email", enterprise.contact_email || "—"],
    ["Contact phone", enterprise.contact_phone || "—"],
    ["Status", (enterprise.approval_status || "pending").toUpperCase()],
  ];
  return (
    <div className="max-w-2xl space-y-6">
      <h2 className="text-xl font-extrabold tracking-tight text-ink">Settings</h2>
      <div className="card !p-0">
        <dl className="divide-y divide-border/60">
          {rows.map(([label, value]) => (
            <div key={label} className="flex items-start justify-between gap-4 px-5 py-3.5">
              <dt className="text-sm text-muted">{label}</dt>
              <dd className="text-right text-sm font-medium text-ink">{value}</dd>
            </div>
          ))}
        </dl>
      </div>
      {/* TODO(api): update enterprise settings endpoint */}
    </div>
  );
}
