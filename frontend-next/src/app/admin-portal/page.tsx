"use client";

// Admin portal — fully wired to the Rust admin_portal service (/api/v2/admin/*).
// Every tab reads live data; creators can be activated/deactivated and payouts
// settled from here. All requests carry the admin JWT.

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import type {
  AdminCreator,
  AdminDashboard,
  AdminTickets,
  AdminUser,
  Payout,
  Tip,
  Transaction,
} from "@/types";

type Tab = "overview" | "creators" | "users" | "tips" | "transactions" | "payouts" | "support";

const TABS: { id: Tab; label: string; icon: string }[] = [
  { id: "overview", label: "Overview", icon: "bi-bar-chart-fill" },
  { id: "creators", label: "Creators", icon: "bi-patch-check-fill" },
  { id: "users", label: "Users", icon: "bi-people-fill" },
  { id: "tips", label: "Tips", icon: "bi-cash-stack" },
  { id: "transactions", label: "Transactions", icon: "bi-receipt" },
  { id: "payouts", label: "Payouts", icon: "bi-bank" },
  { id: "support", label: "Support", icon: "bi-life-preserver" },
];

const money = (v: string | number) =>
  `R${Number(v || 0).toLocaleString("en-ZA", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
const when = (iso?: string) => (iso ? new Date(iso).toLocaleString("en-ZA", { dateStyle: "medium", timeStyle: "short" }) : "—");

function StatusPill({ status }: { status?: string }) {
  const s = status || "—";
  const cls =
    s === "completed" || s === "active"
      ? "bg-teal/10 text-teal"
      : s === "pending"
        ? "bg-yellow-500/15 text-yellow-600"
        : s === "failed" || s === "inactive"
          ? "bg-red-500/10 text-red-500"
          : "bg-border text-muted";
  return <span className={`rounded-full px-2.5 py-1 text-xs font-semibold ${cls}`}>{s}</span>;
}

export default function AdminPortalPage() {
  const { token, isAuthenticated, isAdmin, initialized } = useAuth();
  const router = useRouter();
  const [tab, setTab] = useState<Tab>("overview");

  useEffect(() => {
    if (initialized && (!isAuthenticated || !isAdmin)) router.push("/login");
  }, [initialized, isAuthenticated, isAdmin, router]);

  if (!initialized || !isAuthenticated || !isAdmin || !token) {
    return (
      <div className="container-content grid min-h-[60vh] place-items-center">
        <p className="body-muted">Checking admin access…</p>
      </div>
    );
  }

  return (
    <div className="container-content py-10">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <p className="eyebrow">Admin portal</p>
          <h1 className="mt-1 text-2xl font-extrabold tracking-tight text-ink">Platform control</h1>
        </div>
        <span className="font-mono text-xs text-muted">live · api.tippingjar.co.za</span>
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
            <i className={`bi ${t.icon}`} />
            {t.label}
          </button>
        ))}
      </div>

      <div className="mt-8">
        {tab === "overview" && <OverviewTab token={token} />}
        {tab === "creators" && <CreatorsTab token={token} />}
        {tab === "users" && <UsersTab token={token} />}
        {tab === "tips" && <TipsTab token={token} />}
        {tab === "transactions" && <TransactionsTab token={token} />}
        {tab === "payouts" && <PayoutsTab token={token} />}
        {tab === "support" && <SupportTab token={token} />}
      </div>
    </div>
  );
}

// ── Shared bits ──────────────────────────────────────────────────────────────

function StatCard({ label, value, icon, accent = "#004423" }: { label: string; value: string; icon: string; accent?: string }) {
  return (
    <div className="card !p-5">
      <div className="grid h-10 w-10 place-items-center rounded-xl text-lg" style={{ backgroundColor: accent + "22" }}>
        <i className={`bi ${icon}`} style={{ color: accent }} />
      </div>
      <p className="mt-4 text-2xl font-extrabold tracking-tight text-ink">{value}</p>
      <p className="mt-1 text-xs text-muted">{label}</p>
    </div>
  );
}

function Loading() {
  return <p className="body-muted">Loading…</p>;
}
function LoadError() {
  return (
    <div className="card grid place-items-center py-12 text-center">
      <div className="text-3xl text-red-400"><i className="bi bi-exclamation-triangle-fill" /></div>
      <p className="mt-3 font-semibold text-ink">Couldn&apos;t load data</p>
      <p className="body-muted mt-1">Check that you&apos;re signed in with an admin account.</p>
    </div>
  );
}

function Table({ head, children }: { head: string[]; children: React.ReactNode }) {
  return (
    <div className="card overflow-hidden !p-0">
      <div className="overflow-x-auto">
        <table className="w-full min-w-[720px] text-left text-sm">
          <thead className="border-b border-border text-xs uppercase tracking-wide text-muted">
            <tr>{head.map((h) => <th key={h} className="px-5 py-3 font-semibold">{h}</th>)}</tr>
          </thead>
          <tbody>{children}</tbody>
        </table>
      </div>
    </div>
  );
}

// ── Overview ─────────────────────────────────────────────────────────────────

function OverviewTab({ token }: { token: string }) {
  const [data, setData] = useState<AdminDashboard | null>(null);
  const [err, setErr] = useState(false);
  useEffect(() => {
    api.adminDashboard(token).then(setData).catch(() => setErr(true));
  }, [token]);
  if (err) return <LoadError />;
  if (!data) return <Loading />;
  const t = data.totals;
  return (
    <div className="space-y-8">
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Gross volume (recent)" value={money(t.gross_volume)} icon="bi-cash-coin" />
        <StatCard label="To creators" value={money(t.creator_net)} icon="bi-piggy-bank-fill" accent="#0097B2" />
        <StatCard label={`Tips (${t.tips_completed} completed)`} value={String(t.tips)} icon="bi-heart-fill" accent="#F472B6" />
        <StatCard label="Transactions" value={String(t.transactions)} icon="bi-receipt" accent="#2563EB" />
        <StatCard label="Users" value={String(t.users)} icon="bi-people-fill" accent="#7C3AED" />
        <StatCard label={`Creators (${t.creators_active} active)`} value={String(t.creators)} icon="bi-patch-check-fill" accent="#004423" />
        <StatCard label={`Payouts pending (${money(t.payouts_pending_amount)})`} value={String(t.payouts_pending)} icon="bi-bank" accent="#D97706" />
        <StatCard label={`Support (${t.disputes} disputes)`} value={String(t.contacts + t.disputes)} icon="bi-life-preserver" accent="#DC2626" />
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <div>
          <h3 className="mb-3 text-base font-bold text-ink">Recent tips</h3>
          <Table head={["From", "Creator", "Status", "Amount"]}>
            {data.recent_tips.map((tip: Tip) => (
              <tr key={tip.id} className="border-b border-border/60 last:border-0">
                <td className="px-5 py-3 font-medium text-ink">{tip.tipper_name || "Anonymous"}</td>
                <td className="px-5 py-3 text-muted">{tip.creator_name || "—"}</td>
                <td className="px-5 py-3"><StatusPill status={tip.status} /></td>
                <td className="px-5 py-3 text-right font-bold text-ink">{money(tip.amount)}</td>
              </tr>
            ))}
          </Table>
        </div>
        <div>
          <h3 className="mb-3 text-base font-bold text-ink">Recent transactions</h3>
          <Table head={["Reference", "Status", "Amount", "Net"]}>
            {data.recent_transactions.map((tx: Transaction) => (
              <tr key={tx.id} className="border-b border-border/60 last:border-0">
                <td className="px-5 py-3 font-mono text-xs text-muted">{tx.reference?.slice(0, 16)}…</td>
                <td className="px-5 py-3"><StatusPill status={tx.status} /></td>
                <td className="px-5 py-3 text-ink">{money(tx.amount)}</td>
                <td className="px-5 py-3 text-right font-bold text-teal">{money(tx.creator_net)}</td>
              </tr>
            ))}
          </Table>
        </div>
      </div>
    </div>
  );
}

// ── Creators ─────────────────────────────────────────────────────────────────

function CreatorsTab({ token }: { token: string }) {
  const [rows, setRows] = useState<AdminCreator[] | null>(null);
  const [err, setErr] = useState(false);
  const [busy, setBusy] = useState<string | null>(null);
  const load = useCallback(() => {
    api.adminCreators(token).then(setRows).catch(() => setErr(true));
  }, [token]);
  useEffect(load, [load]);
  if (err) return <LoadError />;
  if (!rows) return <Loading />;

  async function toggle(c: AdminCreator) {
    setBusy(c.id);
    try {
      await api.adminSetCreatorActive(token, c.id, !c.is_active);
      load();
    } finally {
      setBusy(null);
    }
  }

  return (
    <Table head={["Creator", "Category", "KYC", "Media", "Joined", "Status", ""]}>
      {rows.map((c) => (
        <tr key={c.id} className="border-b border-border/60 last:border-0">
          <td className="px-5 py-3">
            <Link href={`/creator/${c.slug}`} className="font-semibold text-ink hover:text-green">
              {c.display_name}
            </Link>
            <span className="ml-2 font-mono text-xs text-muted">@{c.slug}</span>
          </td>
          <td className="px-5 py-3 text-muted">{c.category || "—"}</td>
          <td className="px-5 py-3 text-muted">{c.kyc_status}</td>
          <td className="px-5 py-3 text-muted">
            {c.has_avatar && <i className="bi bi-person-circle text-teal" title="Has avatar" />}{" "}
            {c.has_cover && <i className="bi bi-image text-teal" title="Has cover" />}
            {!c.has_avatar && !c.has_cover && "—"}
          </td>
          <td className="px-5 py-3 text-muted">{when(c.created_at)}</td>
          <td className="px-5 py-3"><StatusPill status={c.is_active ? "active" : "inactive"} /></td>
          <td className="px-5 py-3 text-right">
            <button
              onClick={() => toggle(c)}
              disabled={busy === c.id}
              className={`rounded-full px-3.5 py-1.5 text-xs font-semibold transition disabled:opacity-50 ${
                c.is_active
                  ? "border border-red-200 text-red-500 hover:bg-red-50"
                  : "bg-primary text-white"
              }`}
            >
              {busy === c.id ? "…" : c.is_active ? "Deactivate" : "Activate"}
            </button>
          </td>
        </tr>
      ))}
    </Table>
  );
}

// ── Users ────────────────────────────────────────────────────────────────────

function UsersTab({ token }: { token: string }) {
  const [rows, setRows] = useState<AdminUser[] | null>(null);
  const [err, setErr] = useState(false);
  useEffect(() => {
    api.adminUsers(token).then(setRows).catch(() => setErr(true));
  }, [token]);
  if (err) return <LoadError />;
  if (!rows) return <Loading />;
  return (
    <Table head={["Email", "Username", "Role", "2FA", "Joined"]}>
      {rows.map((u) => (
        <tr key={u.id} className="border-b border-border/60 last:border-0">
          <td className="px-5 py-3 font-medium text-ink">{u.email}</td>
          <td className="px-5 py-3 text-muted">{u.username}</td>
          <td className="px-5 py-3"><StatusPill status={u.role} /></td>
          <td className="px-5 py-3 text-muted">{u.two_fa_enabled ? "on" : "off"}</td>
          <td className="px-5 py-3 text-muted">{when(u.created_at)}</td>
        </tr>
      ))}
    </Table>
  );
}

// ── Tips ─────────────────────────────────────────────────────────────────────

function TipsTab({ token }: { token: string }) {
  const [rows, setRows] = useState<Tip[] | null>(null);
  const [err, setErr] = useState(false);
  useEffect(() => {
    api.adminTips(token).then(setRows).catch(() => setErr(true));
  }, [token]);
  if (err) return <LoadError />;
  if (!rows) return <Loading />;
  const total = rows.filter((t) => t.status === "completed").reduce((s, t) => s + Number(t.amount || 0), 0);
  return (
    <div className="space-y-4">
      <p className="text-sm text-muted">{rows.length} tip(s) · completed volume {money(total)}</p>
      <Table head={["From", "Creator", "Message", "Status", "Date", "Amount", "Net"]}>
        {rows.map((t) => (
          <tr key={t.id} className="border-b border-border/60 last:border-0">
            <td className="px-5 py-3 font-medium text-ink">{t.tipper_name || "Anonymous"}</td>
            <td className="px-5 py-3 text-muted">{t.creator_name || "—"}</td>
            <td className="max-w-[200px] truncate px-5 py-3 text-muted">{t.message || "—"}</td>
            <td className="px-5 py-3"><StatusPill status={t.status} /></td>
            <td className="px-5 py-3 text-muted">{when(t.created_at)}</td>
            <td className="px-5 py-3 text-ink">{money(t.amount)}</td>
            <td className="px-5 py-3 text-right font-bold text-teal">{money(t.creator_net)}</td>
          </tr>
        ))}
      </Table>
    </div>
  );
}

// ── Transactions ─────────────────────────────────────────────────────────────

function TransactionsTab({ token }: { token: string }) {
  const [rows, setRows] = useState<Transaction[] | null>(null);
  const [err, setErr] = useState(false);
  useEffect(() => {
    api.adminTransactions(token).then(setRows).catch(() => setErr(true));
  }, [token]);
  if (err) return <LoadError />;
  if (!rows) return <Loading />;
  return (
    <Table head={["Reference", "Creator", "Tipper", "Status", "Date", "Amount", "Net"]}>
      {rows.map((t) => (
        <tr key={t.id} className="border-b border-border/60 last:border-0">
          <td className="px-5 py-3 font-mono text-xs text-muted">{t.reference?.slice(0, 18)}…</td>
          <td className="px-5 py-3 text-muted">{t.creator_name || "—"}</td>
          <td className="px-5 py-3 text-muted">{t.tipper_name || "—"}</td>
          <td className="px-5 py-3"><StatusPill status={t.status} /></td>
          <td className="px-5 py-3 text-muted">{when(t.created_at)}</td>
          <td className="px-5 py-3 text-ink">{t.currency} {t.amount}</td>
          <td className="px-5 py-3 text-right font-bold text-teal">{money(t.creator_net)}</td>
        </tr>
      ))}
    </Table>
  );
}

// ── Payouts ──────────────────────────────────────────────────────────────────

function PayoutsTab({ token }: { token: string }) {
  const [rows, setRows] = useState<Payout[] | null>(null);
  const [err, setErr] = useState(false);
  const [busy, setBusy] = useState<string | null>(null);
  const load = useCallback(() => {
    api.adminPayouts(token).then(setRows).catch(() => setErr(true));
  }, [token]);
  useEffect(load, [load]);
  if (err) return <LoadError />;
  if (!rows) return <Loading />;
  if (rows.length === 0) {
    return (
      <div className="card grid place-items-center py-12 text-center">
        <div className="text-3xl text-teal"><i className="bi bi-bank" /></div>
        <p className="mt-3 font-semibold text-ink">No payout requests</p>
        <p className="body-muted mt-1">Creator withdrawal requests will appear here for settlement.</p>
      </div>
    );
  }

  async function setStatus(p: Payout, status: string) {
    setBusy(p.id);
    try {
      await api.adminSetPayoutStatus(token, p.id, status);
      load();
    } finally {
      setBusy(null);
    }
  }

  return (
    <Table head={["Reference", "Date", "Status", "Amount", "Settle"]}>
      {rows.map((p) => (
        <tr key={p.id} className="border-b border-border/60 last:border-0">
          <td className="px-5 py-3 font-mono text-xs text-muted">{p.reference}</td>
          <td className="px-5 py-3 text-muted">{when(p.created_at)}</td>
          <td className="px-5 py-3"><StatusPill status={p.status} /></td>
          <td className="px-5 py-3 font-bold text-ink">{money(p.amount)}</td>
          <td className="px-5 py-3 text-right">
            {p.status === "pending" ? (
              <span className="inline-flex gap-2">
                <button
                  onClick={() => setStatus(p, "completed")}
                  disabled={busy === p.id}
                  className="rounded-full bg-primary px-3.5 py-1.5 text-xs font-semibold text-white disabled:opacity-50"
                >
                  Mark paid
                </button>
                <button
                  onClick={() => setStatus(p, "failed")}
                  disabled={busy === p.id}
                  className="rounded-full border border-red-200 px-3.5 py-1.5 text-xs font-semibold text-red-500 hover:bg-red-50 disabled:opacity-50"
                >
                  Fail
                </button>
              </span>
            ) : (
              <span className="text-xs text-muted">settled</span>
            )}
          </td>
        </tr>
      ))}
    </Table>
  );
}

// ── Support ──────────────────────────────────────────────────────────────────

function SupportTab({ token }: { token: string }) {
  const [data, setData] = useState<AdminTickets | null>(null);
  const [err, setErr] = useState(false);
  useEffect(() => {
    api.adminTickets(token).then(setData).catch(() => setErr(true));
  }, [token]);
  if (err) return <LoadError />;
  if (!data) return <Loading />;
  return (
    <div className="space-y-8">
      <div>
        <h3 className="mb-3 text-base font-bold text-ink">Contact messages ({data.contacts.length})</h3>
        {data.contacts.length === 0 ? (
          <p className="body-muted">Inbox zero 🎉</p>
        ) : (
          <Table head={["From", "Subject", "Message", "Date"]}>
            {data.contacts.map((c) => (
              <tr key={c.id} className="border-b border-border/60 last:border-0">
                <td className="px-5 py-3 font-medium text-ink">{c.name || c.email || "—"}</td>
                <td className="px-5 py-3 text-muted">{c.subject || "—"}</td>
                <td className="max-w-[280px] truncate px-5 py-3 text-muted">{c.message || "—"}</td>
                <td className="px-5 py-3 text-muted">{when(c.created_at)}</td>
              </tr>
            ))}
          </Table>
        )}
      </div>
      <div>
        <h3 className="mb-3 text-base font-bold text-ink">Disputes ({data.disputes.length})</h3>
        {data.disputes.length === 0 ? (
          <p className="body-muted">No open disputes.</p>
        ) : (
          <Table head={["Email", "Reason", "Status", "Tracking", "Date"]}>
            {data.disputes.map((d) => (
              <tr key={d.id} className="border-b border-border/60 last:border-0">
                <td className="px-5 py-3 font-medium text-ink">{d.email || "—"}</td>
                <td className="max-w-[240px] truncate px-5 py-3 text-muted">{d.reason || "—"}</td>
                <td className="px-5 py-3"><StatusPill status={d.status} /></td>
                <td className="px-5 py-3 font-mono text-xs text-muted">{d.tracking_token || "—"}</td>
                <td className="px-5 py-3 text-muted">{when(d.created_at)}</td>
              </tr>
            ))}
          </Table>
        )}
      </div>
      <div>
        <h3 className="mb-3 text-base font-bold text-ink">Partner applications ({data.partners.length})</h3>
        {data.partners.length === 0 ? (
          <p className="body-muted">No applications yet.</p>
        ) : (
          <Table head={["Company", "Email", "Date"]}>
            {data.partners.map((p) => (
              <tr key={p.id} className="border-b border-border/60 last:border-0">
                <td className="px-5 py-3 font-medium text-ink">{p.company || "—"}</td>
                <td className="px-5 py-3 text-muted">{p.email || "—"}</td>
                <td className="px-5 py-3 text-muted">{when(p.created_at)}</td>
              </tr>
            ))}
          </Table>
        )}
      </div>
    </div>
  );
}
