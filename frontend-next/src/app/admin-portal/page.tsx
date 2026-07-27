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

const money = (v: string | number) => {
  const n = Number(v) || 0; // -0 and NaN both normalise to 0
  return `R${n.toLocaleString("en-ZA", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
};
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

function RevenueChart({ token }: { token: string }) {
  const [days, setDays] = useState<{ day: string; count: number; gross: string }[] | null>(null);
  useEffect(() => {
    api.adminDailyStats(token).then(setDays).catch(() => setDays([]));
  }, [token]);
  if (!days) return null;
  // Fill the last 30 days so quiet days render as empty slots.
  const map = new Map(days.map((d) => [d.day, d]));
  const series: { day: string; gross: number; count: number }[] = [];
  for (let i = 29; i >= 0; i--) {
    const d = new Date(Date.now() - i * 86400000);
    const key = d.toISOString().slice(0, 10);
    const row = map.get(key);
    series.push({ day: key, gross: Number(row?.gross ?? 0), count: row?.count ?? 0 });
  }
  const max = Math.max(...series.map((s) => s.gross), 1);
  const total = series.reduce((s, d) => s + d.gross, 0);
  return (
    <div className="card !p-5">
      <div className="flex items-baseline justify-between">
        <p className="text-xs font-semibold uppercase tracking-wide text-muted">Tip volume · last 30 days</p>
        <p className="text-sm font-bold text-ink">{money(total)}</p>
      </div>
      <div className="mt-4 flex h-28 items-end gap-[3px]">
        {series.map((s) => (
          <div
            key={s.day}
            className="group relative flex-1 rounded-t bg-teal/70 transition hover:bg-teal"
            style={{ height: `${Math.max(3, (s.gross / max) * 100)}%` }}
            title={`${s.day}: ${money(s.gross)} (${s.count} tip${s.count === 1 ? "" : "s"})`}
          />
        ))}
      </div>
      <div className="mt-2 flex justify-between font-mono text-[10px] text-muted">
        <span>{series[0].day.slice(5)}</span>
        <span>{series[series.length - 1].day.slice(5)}</span>
      </div>
    </div>
  );
}

function OpsPanel({ token }: { token: string }) {
  const [busy, setBusy] = useState<string | null>(null);
  const [note, setNote] = useState<string | null>(null);
  async function run(kind: "report" | "reminders") {
    setBusy(kind);
    setNote(null);
    try {
      if (kind === "report") {
        const r = await api.adminRunDailyReport(token);
        setNote(`Daily report (${r.date}): ${r.rendered} PDF(s) rendered, ${r.emailed} emailed.`);
      } else {
        const r = await api.adminRunReminders(token);
        setNote(`Signup reminders: ${r.sent}/${r.candidates} sent.`);
      }
    } catch (e) {
      setNote(e instanceof Error ? e.message : "Operation failed.");
    } finally {
      setBusy(null);
    }
  }
  return (
    <div className="card !p-5">
      <p className="text-xs font-semibold uppercase tracking-wide text-muted">Operations</p>
      <div className="mt-3 flex flex-wrap gap-2">
        <button onClick={() => run("report")} disabled={!!busy} className="btn-primary !px-4 !py-2 text-xs disabled:opacity-50">
          {busy === "report" ? "Running…" : <><i className="bi bi-file-earmark-pdf" /> Run daily report</>}
        </button>
        <button onClick={() => run("reminders")} disabled={!!busy} className="btn-ghost !px-4 !py-2 text-xs disabled:opacity-50">
          {busy === "reminders" ? "Running…" : <><i className="bi bi-envelope" /> Run signup reminders</>}
        </button>
      </div>
      {note && <p className="mt-3 text-xs text-teal">{note}</p>}
      <p className="mt-3 text-[11px] text-muted">
        The report renders yesterday&apos;s PDFs (and emails them when delivery is enabled). Reminders nudge
        creator signups older than 12h without a page — once per user, ever.
      </p>
    </div>
  );
}

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

      <div className="grid gap-6 lg:grid-cols-[1.4fr_1fr]">
        <RevenueChart token={token} />
        <OpsPanel token={token} />
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
  async function setKyc(c: AdminCreator, status: string) {
    setBusy(c.id);
    try {
      await api.adminSetCreatorKyc(token, c.id, status);
      load();
    } finally {
      setBusy(null);
    }
  }
  async function remove(c: AdminCreator) {
    if (!window.confirm(`Delete creator “${c.display_name}” (@${c.slug})? This removes their page, jars, tiers and designs. This cannot be undone.`)) return;
    setBusy(c.id);
    try {
      await api.adminDeleteCreator(token, c.id);
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
          <td className="px-5 py-3">
            <select
              value={c.kyc_status}
              disabled={busy === c.id}
              onChange={(e) => setKyc(c, e.target.value)}
              className="rounded-lg border border-border bg-white px-2 py-1 text-xs text-ink focus:outline-none"
            >
              {["not_started", "pending", "verified", "rejected"].map((s) => (
                <option key={s} value={s}>{s}</option>
              ))}
            </select>
          </td>
          <td className="px-5 py-3 text-muted">
            {c.has_avatar && <i className="bi bi-person-circle text-teal" title="Has avatar" />}{" "}
            {c.has_cover && <i className="bi bi-image text-teal" title="Has cover" />}
            {!c.has_avatar && !c.has_cover && "—"}
          </td>
          <td className="px-5 py-3 text-muted">{when(c.created_at)}</td>
          <td className="px-5 py-3"><StatusPill status={c.is_active ? "active" : "inactive"} /></td>
          <td className="px-5 py-3 text-right">
            <span className="inline-flex items-center gap-2">
              <button
                onClick={() => toggle(c)}
                disabled={busy === c.id}
                className={`rounded-full px-3.5 py-1.5 text-xs font-semibold transition disabled:opacity-50 ${
                  c.is_active
                    ? "border border-yellow-500/40 text-yellow-600 hover:bg-yellow-50"
                    : "bg-primary text-white"
                }`}
              >
                {busy === c.id ? "…" : c.is_active ? "Deactivate" : "Activate"}
              </button>
              <button
                onClick={() => remove(c)}
                disabled={busy === c.id}
                className="rounded-full border border-red-200 px-3 py-1.5 text-xs font-semibold text-red-500 hover:bg-red-50 disabled:opacity-50"
                title="Delete creator"
              >
                <i className="bi bi-trash" />
              </button>
            </span>
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
  const [q, setQ] = useState("");
  const [busy, setBusy] = useState<string | null>(null);
  const load = useCallback(() => {
    api.adminUsers(token).then(setRows).catch(() => setErr(true));
  }, [token]);
  useEffect(load, [load]);
  if (err) return <LoadError />;
  if (!rows) return <Loading />;

  const filtered = rows.filter(
    (u) =>
      !q ||
      u.email.toLowerCase().includes(q.toLowerCase()) ||
      u.username.toLowerCase().includes(q.toLowerCase()),
  );

  async function setRole(u: AdminUser, role: string) {
    if (role === "admin" && !window.confirm(`Grant ADMIN to ${u.email}? They get full platform control.`)) { load(); return; }
    setBusy(u.id);
    try {
      await api.adminSetUserRole(token, u.id, role);
      load();
    } finally {
      setBusy(null);
    }
  }
  async function remove(u: AdminUser) {
    if (!window.confirm(`Delete account ${u.email}? This cannot be undone.`)) return;
    setBusy(u.id);
    try {
      await api.adminDeleteUser(token, u.id);
      load();
    } catch (e) {
      window.alert(e instanceof Error ? e.message : "Delete failed.");
    } finally {
      setBusy(null);
    }
  }

  return (
    <div className="space-y-4">
      <input
        value={q}
        onChange={(e) => setQ(e.target.value)}
        placeholder="Search email or username…"
        className="w-full max-w-sm rounded-full border border-border bg-white px-4 py-2 text-sm text-ink focus:border-primary/40 focus:outline-none"
      />
      <Table head={["Email", "Username", "Role", "2FA", "Joined", ""]}>
        {filtered.map((u) => (
          <tr key={u.id} className="border-b border-border/60 last:border-0">
            <td className="px-5 py-3 font-medium text-ink">{u.email}</td>
            <td className="px-5 py-3 text-muted">{u.username}</td>
            <td className="px-5 py-3">
              <select
                value={u.role}
                disabled={busy === u.id}
                onChange={(e) => setRole(u, e.target.value)}
                className="rounded-lg border border-border bg-white px-2 py-1 text-xs text-ink focus:outline-none"
              >
                {["fan", "creator", "enterprise", "admin"].map((r) => (
                  <option key={r} value={r}>{r}</option>
                ))}
              </select>
            </td>
            <td className="px-5 py-3 text-muted">{u.two_fa_enabled ? "on" : "off"}</td>
            <td className="px-5 py-3 text-muted">{when(u.created_at)}</td>
            <td className="px-5 py-3 text-right">
              <button
                onClick={() => remove(u)}
                disabled={busy === u.id}
                className="rounded-full border border-red-200 px-3 py-1.5 text-xs font-semibold text-red-500 hover:bg-red-50 disabled:opacity-50"
                title="Delete account"
              >
                <i className="bi bi-trash" />
              </button>
            </td>
          </tr>
        ))}
      </Table>
    </div>
  );
}

// ── Tips ─────────────────────────────────────────────────────────────────────

function TipsTab({ token }: { token: string }) {
  const [rows, setRows] = useState<Tip[] | null>(null);
  const [err, setErr] = useState(false);
  const [status, setStatus] = useState("all");
  useEffect(() => {
    api.adminTips(token).then(setRows).catch(() => setErr(true));
  }, [token]);
  if (err) return <LoadError />;
  if (!rows) return <Loading />;
  const shown = rows.filter((t) => status === "all" || t.status === status);
  const total = shown.filter((t) => t.status === "completed").reduce((s, t) => s + Number(t.amount || 0), 0);
  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <FilterChips options={["all", "completed", "pending", "failed"]} value={status} onChange={setStatus} />
        <p className="text-sm text-muted">{shown.length} tip(s) · completed volume {money(total)}</p>
      </div>
      <Table head={["From", "Creator", "Message", "Status", "Date", "Amount", "Net"]}>
        {shown.map((t) => (
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

function FilterChips({ options, value, onChange }: { options: string[]; value: string; onChange: (v: string) => void }) {
  return (
    <div className="flex flex-wrap gap-2">
      {options.map((o) => (
        <button
          key={o}
          onClick={() => onChange(o)}
          className={`rounded-full px-3.5 py-1.5 text-xs font-semibold transition ${
            value === o ? "bg-primary text-white" : "border border-border text-muted hover:text-ink"
          }`}
        >
          {o}
        </button>
      ))}
    </div>
  );
}

function TransactionsTab({ token }: { token: string }) {
  const [rows, setRows] = useState<Transaction[] | null>(null);
  const [err, setErr] = useState(false);
  const [q, setQ] = useState("");
  const [status, setStatus] = useState("all");
  const [busy, setBusy] = useState<string | null>(null);
  const [note, setNote] = useState<string | null>(null);
  const load = useCallback(() => {
    api.adminTransactions(token).then(setRows).catch(() => setErr(true));
  }, [token]);
  useEffect(load, [load]);
  if (err) return <LoadError />;
  if (!rows) return <Loading />;

  const filtered = rows.filter(
    (t) =>
      (status === "all" || t.status === status) &&
      (!q ||
        t.reference?.toLowerCase().includes(q.toLowerCase()) ||
        t.creator_name?.toLowerCase().includes(q.toLowerCase()) ||
        t.tipper_name?.toLowerCase().includes(q.toLowerCase())),
  );

  async function refund(t: Transaction) {
    if (!window.confirm(`Refund ${t.currency} ${t.amount} to ${t.tipper_name || "the payer"}? This submits a real PayCloud refund.`)) return;
    setBusy(t.id);
    setNote(null);
    try {
      await api.adminRefund(token, t.merchant_order_no, `Refund ${t.reference}`);
      setNote(`Refund submitted for ${t.reference.slice(0, 14)}…`);
      load();
    } catch (e) {
      setNote(e instanceof Error ? e.message : "Refund failed.");
    } finally {
      setBusy(null);
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center gap-3">
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Search reference, creator, tipper…"
          className="w-full max-w-sm rounded-full border border-border bg-white px-4 py-2 text-sm text-ink focus:border-primary/40 focus:outline-none"
        />
        <FilterChips options={["all", "completed", "pending", "failed"]} value={status} onChange={setStatus} />
      </div>
      {note && <p className="text-sm text-teal">{note}</p>}
      <Table head={["Reference", "Creator", "Tipper", "Status", "Date", "Amount", "Net", ""]}>
        {filtered.map((t) => (
          <tr key={t.id} className="border-b border-border/60 last:border-0">
            <td className="px-5 py-3 font-mono text-xs text-muted">{t.reference?.slice(0, 18)}…</td>
            <td className="px-5 py-3 text-muted">{t.creator_name || "—"}</td>
            <td className="px-5 py-3 text-muted">{t.tipper_name || "—"}</td>
            <td className="px-5 py-3"><StatusPill status={t.status} /></td>
            <td className="px-5 py-3 text-muted">{when(t.created_at)}</td>
            <td className="px-5 py-3 text-ink">{t.currency} {t.amount}</td>
            <td className="px-5 py-3 text-right font-bold text-teal">{money(t.creator_net)}</td>
            <td className="px-5 py-3 text-right">
              {t.status === "completed" && (
                <button
                  onClick={() => refund(t)}
                  disabled={busy === t.id}
                  className="rounded-full border border-red-200 px-3 py-1.5 text-xs font-semibold text-red-500 hover:bg-red-50 disabled:opacity-50"
                >
                  {busy === t.id ? "…" : "Refund"}
                </button>
              )}
            </td>
          </tr>
        ))}
      </Table>
    </div>
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
  const [busy, setBusy] = useState<string | null>(null);
  const load = useCallback(() => {
    api.adminTickets(token).then(setData).catch(() => setErr(true));
  }, [token]);
  useEffect(load, [load]);
  if (err) return <LoadError />;
  if (!data) return <Loading />;

  async function setDispute(id: string, status: string) {
    setBusy(id);
    try {
      await api.adminSetDisputeStatus(token, id, status);
      load();
    } finally {
      setBusy(null);
    }
  }
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
          <Table head={["Email", "Reason", "Status", "Date", "Actions"]}>
            {data.disputes.map((d) => (
              <tr key={d.id} className="border-b border-border/60 last:border-0">
                <td className="px-5 py-3 font-medium text-ink">{d.email || "—"}</td>
                <td className="max-w-[240px] truncate px-5 py-3 text-muted">{d.reason || "—"}</td>
                <td className="px-5 py-3"><StatusPill status={d.status} /></td>
                <td className="px-5 py-3 text-muted">{when(d.created_at)}</td>
                <td className="px-5 py-3 text-right">
                  {d.status !== "resolved" && d.status !== "rejected" ? (
                    <span className="inline-flex gap-2">
                      <button
                        onClick={() => setDispute(d.id, "resolved")}
                        disabled={busy === d.id}
                        className="rounded-full bg-primary px-3 py-1.5 text-xs font-semibold text-white disabled:opacity-50"
                      >
                        Resolve
                      </button>
                      <button
                        onClick={() => setDispute(d.id, "rejected")}
                        disabled={busy === d.id}
                        className="rounded-full border border-red-200 px-3 py-1.5 text-xs font-semibold text-red-500 hover:bg-red-50 disabled:opacity-50"
                      >
                        Reject
                      </button>
                    </span>
                  ) : (
                    <span className="text-xs text-muted">closed</span>
                  )}
                </td>
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
