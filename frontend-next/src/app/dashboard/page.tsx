"use client";

// Creator dashboard — a full-bleed app shell with its own collapsible sidebar.
// The marketing top-nav + footer are hidden for /dashboard (see SiteFrame), so
// this owns the whole viewport. Tabs render in the content area on the right.

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import {
  LayoutDashboard,
  HandCoins,
  Receipt,
  Users,
  Palette,
  PanelLeftClose,
  PanelLeftOpen,
  ExternalLink,
  LogOut,
  Menu,
  X,
  Banknote,
  Wallet,
  Calendar,
  Heart,
  CircleCheck,
  Percent,
  Zap,
  Gift,
  Link2,
  ArrowUpRight,
  type LucideIcon,
} from "lucide-react";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { StudioEditor } from "@/components/StudioEditor";
import { LiveClock } from "@/components/Clock";
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

const TABS: { id: Tab; label: string; icon: LucideIcon }[] = [
  { id: "overview", label: "Overview", icon: LayoutDashboard },
  { id: "tips", label: "Tips", icon: HandCoins },
  { id: "transactions", label: "Transactions", icon: Receipt },
  { id: "referrals", label: "Referrals", icon: Users },
  { id: "studio", label: "Studio", icon: Palette },
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
  const { user, token, isAuthenticated, initialized, logout } = useAuth();
  const router = useRouter();
  const [tab, setTab] = useState<Tab>("overview");
  const [collapsed, setCollapsed] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);

  const [tips, setTips] = useState<Tip[]>([]);
  const [referral, setReferral] = useState<ReferralCode | null>(null);
  const [myCreator, setMyCreator] = useState<Creator | null>(null);
  const [stats, setStats] = useState<CreatorStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setCollapsed(localStorage.getItem("tj_dash_collapsed") === "1");
  }, []);
  const toggleCollapsed = () =>
    setCollapsed((c) => {
      const next = !c;
      localStorage.setItem("tj_dash_collapsed", next ? "1" : "0");
      return next;
    });

  useEffect(() => {
    if (initialized && !isAuthenticated) router.push("/login");
  }, [initialized, isAuthenticated, router]);

  useEffect(() => {
    if (!isAuthenticated) return;
    let alive = true;
    (async () => {
      setLoading(true);
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
      <div className="grid min-h-screen place-items-center bg-darker">
        <p className="body-muted animate-pulse">Loading your dashboard…</p>
      </div>
    );
  }

  const name = user?.username || "there";
  const active = TABS.find((t) => t.id === tab)!;

  return (
    <div className="app-shell flex min-h-screen bg-darker">
      <DashboardSidebar
        tab={tab}
        onTab={(t) => {
          setTab(t);
          setMobileOpen(false);
        }}
        collapsed={collapsed}
        onToggleCollapsed={toggleCollapsed}
        mobileOpen={mobileOpen}
        onCloseMobile={() => setMobileOpen(false)}
        creator={myCreator}
        onLogout={logout}
      />

      {/* Content */}
      <div className="flex min-w-0 flex-1 flex-col">
        <header className="sticky top-0 z-20 flex h-16 items-center gap-3 border-b border-border bg-white/85 px-4 backdrop-blur-xl md:px-7">
          <button
            onClick={() => setMobileOpen(true)}
            className="grid h-10 w-10 place-items-center rounded-xl text-ink transition-colors hover:bg-ink/5 lg:hidden"
            aria-label="Open menu"
          >
            <Menu className="h-5 w-5" />
          </button>
          <div className="min-w-0">
            <p className="text-[11px] font-medium text-muted">{greeting()},</p>
            <h1 className="truncate text-base font-medium leading-tight tracking-tight text-ink">
              {name}
            </h1>
          </div>
          <div className="ml-auto flex items-center gap-2.5">
            <LiveClock />
            <span className="hidden items-center gap-1.5 rounded-full border border-border bg-white px-3 py-1.5 text-xs font-medium text-muted lg:inline-flex">
              <active.icon className="h-3.5 w-3.5 text-teal" strokeWidth={2.4} />
              {active.label}
            </span>
            <Link
              href="/"
              className="hidden items-center gap-1.5 rounded-full border border-border bg-white px-3.5 py-1.5 text-xs font-medium text-ink transition-colors hover:border-teal hover:text-teal sm:inline-flex"
            >
              View site <ArrowUpRight className="h-3.5 w-3.5" strokeWidth={2.4} />
            </Link>
            <span
              title={name}
              className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-gradient-to-br from-primary to-green text-sm font-medium text-white shadow-soft ring-2 ring-white"
            >
              {name.charAt(0).toUpperCase()}
            </span>
          </div>
        </header>

        <main className="flex-1 px-4 py-7 md:px-8">
          <div key={tab} className="pop-in mx-auto max-w-[1180px]">
            {tab === "overview" && (
              <OverviewTab tips={tips} loading={loading} stats={stats} slug={myCreator?.slug ?? null} />
            )}
            {tab === "tips" && <TipsTab tips={tips} loading={loading} />}
            {tab === "transactions" && (
              <TransactionsTab token={token} creatorId={myCreator?.id ?? null} />
            )}
            {tab === "referrals" && <ReferralsTab referral={referral} />}
            {tab === "studio" && <StudioTab token={token} />}
          </div>
        </main>
      </div>
    </div>
  );
}

// ─── Sidebar ─────────────────────────────────────────────────────────────────
function NavRow({
  icon: Icon,
  label,
  active,
  collapsed,
  onClick,
  href,
}: {
  icon: LucideIcon;
  label: string;
  active?: boolean;
  collapsed: boolean;
  onClick?: () => void;
  href?: string;
}) {
  const cls = `group relative flex w-full items-center gap-3 rounded-xl p-1.5 transition-all duration-200 ${
    collapsed ? "lg:justify-center" : ""
  } ${active ? "nav-glass" : "hover:bg-white/[0.06]"}`;
  const inner = (
    <>
      <span
        className={`grid h-9 w-9 shrink-0 place-items-center rounded-lg transition-all duration-200 ${
          active
            ? "bg-mint/25 text-mint ring-1 ring-mint/30"
            : "text-white/70 group-hover:bg-white/10 group-hover:text-white"
        }`}
      >
        <Icon className="h-[18px] w-[18px]" strokeWidth={2} />
      </span>
      <span
        className={`text-sm font-medium ${active ? "text-white" : "text-white/65 group-hover:text-white"} ${
          collapsed ? "lg:hidden" : ""
        }`}
      >
        {label}
      </span>
      {collapsed && (
        <span className="nav-tip hidden rounded-lg border border-white/10 bg-navy px-2.5 py-1.5 text-xs font-medium text-white shadow-lift lg:block">
          {label}
        </span>
      )}
    </>
  );
  return href ? (
    <Link href={href} onClick={onClick} className={cls}>
      {inner}
    </Link>
  ) : (
    <button onClick={onClick} className={cls}>
      {inner}
    </button>
  );
}

function DashboardSidebar({
  tab,
  onTab,
  collapsed,
  onToggleCollapsed,
  mobileOpen,
  onCloseMobile,
  creator,
  onLogout,
}: {
  tab: Tab;
  onTab: (t: Tab) => void;
  collapsed: boolean;
  onToggleCollapsed: () => void;
  mobileOpen: boolean;
  onCloseMobile: () => void;
  creator: Creator | null;
  onLogout: () => void;
}) {
  return (
    <>
      {/* Mobile backdrop */}
      <div
        onClick={onCloseMobile}
        className={`fixed inset-0 z-40 bg-navy/50 backdrop-blur-sm transition-opacity duration-300 lg:hidden ${
          mobileOpen ? "opacity-100" : "pointer-events-none opacity-0"
        }`}
      />

      <aside
        className={`glass-sidebar fixed inset-y-0 left-0 z-50 flex w-[248px] flex-col text-white shadow-2xl transition-all duration-300 lg:sticky lg:top-0 lg:z-30 lg:h-screen lg:translate-x-0 lg:shadow-none ${
          mobileOpen ? "translate-x-0" : "-translate-x-full"
        } ${collapsed ? "lg:w-[74px]" : "lg:w-[248px]"}`}
      >
        {/* Brand + collapse toggle */}
        <div
          className={`flex h-16 shrink-0 items-center gap-2.5 border-b border-white/10 px-4 ${
            collapsed ? "lg:justify-center lg:px-0" : ""
          }`}
        >
          <Link href="/" className={`flex items-center gap-2.5 ${collapsed ? "lg:hidden" : ""}`}>
            <span className="grid h-9 w-9 shrink-0 place-items-center rounded-xl bg-gradient-to-br from-mint to-green text-navy">
              <Palette className="h-[18px] w-[18px]" strokeWidth={2.4} />
            </span>
            <span className="font-display text-lg font-medium tracking-tight">
              Creator<span className="text-mint">Hub</span>
            </span>
          </Link>

          {/* Desktop collapse toggle */}
          <button
            onClick={onToggleCollapsed}
            className={`hidden h-9 w-9 place-items-center rounded-lg text-white/60 transition-colors hover:bg-white/10 hover:text-white lg:grid ${
              collapsed ? "" : "ml-auto"
            }`}
            aria-label={collapsed ? "Expand sidebar" : "Collapse sidebar"}
            title={collapsed ? "Expand" : "Collapse"}
          >
            {collapsed ? (
              <PanelLeftOpen className="h-[18px] w-[18px]" />
            ) : (
              <PanelLeftClose className="h-[18px] w-[18px]" />
            )}
          </button>

          {/* Mobile close */}
          <button
            onClick={onCloseMobile}
            className="ml-auto grid h-9 w-9 place-items-center rounded-lg text-white/60 hover:bg-white/10 hover:text-white lg:hidden"
            aria-label="Close menu"
          >
            <X className="h-[18px] w-[18px]" />
          </button>
        </div>

        {/* Nav */}
        <nav className="thin-scroll flex-1 space-y-1 overflow-y-auto p-3">
          {!collapsed && (
            <p className="px-3 pb-1.5 pt-2 text-[10px] font-medium uppercase tracking-[0.18em] text-white/35">
              Menu
            </p>
          )}
          {TABS.map((t) => (
            <NavRow
              key={t.id}
              icon={t.icon}
              label={t.label}
              active={tab === t.id}
              collapsed={collapsed}
              onClick={() => onTab(t.id)}
            />
          ))}
        </nav>

        {/* Footer actions */}
        <div className="space-y-1 border-t border-white/10 p-3">
          {creator?.slug && (
            <NavRow icon={ExternalLink} label="My page" collapsed={collapsed} href={`/creator/${creator.slug}`} />
          )}
          <NavRow icon={LogOut} label="Log out" collapsed={collapsed} onClick={onLogout} />
        </div>
      </aside>
    </>
  );
}

// ─── Overview ────────────────────────────────────────────────────────────────
function StatCard({
  label,
  value,
  icon: Icon,
  accent,
}: {
  label: string;
  value: string;
  icon: LucideIcon;
  accent?: string;
}) {
  const c = accent ?? "#12A25C";
  return (
    <div className="card group !p-5 transition-all duration-300 hover:-translate-y-1 hover:shadow-lift">
      <div
        className="grid h-11 w-11 place-items-center rounded-xl transition-transform duration-300 group-hover:scale-110"
        style={{ backgroundColor: c + "1f" }}
      >
        <Icon className="h-5 w-5" style={{ color: c }} strokeWidth={2.2} />
      </div>
      <p
        className={`mt-4 text-2xl tracking-tight text-ink ${
          value.trim().startsWith("R") ? "font-bold" : "font-medium"
        }`}
      >
        {value}
      </p>
      <p className="mt-1 text-xs font-medium text-muted">{label}</p>
    </div>
  );
}

function EmptyState({ icon: Icon, title, body }: { icon: LucideIcon; title: string; body: string }) {
  return (
    <div className="card grid place-items-center py-12 text-center">
      <span className="grid h-14 w-14 place-items-center rounded-2xl bg-teal/10 text-teal">
        <Icon className="h-7 w-7" strokeWidth={2} />
      </span>
      <p className="mt-4 font-medium text-ink">{title}</p>
      <p className="body-muted mt-1 max-w-sm">{body}</p>
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
      <div className="stagger grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Net earned" value={`R${money(netEarned)}`} icon={Banknote} accent="#12A25C" />
        <StatCard label="This month" value={`R${money(thisMonth)}`} icon={Calendar} accent="#2563EB" />
        <StatCard label="Supporters" value={String(stats?.supporter_count ?? 0)} icon={Users} accent="#E0A536" />
        <StatCard label="Total tips" value={String(stats?.tip_count ?? 0)} icon={Heart} accent="#EC4899" />
      </div>

      {/* Share tip link */}
      <div className="card relative overflow-hidden bg-brand-gradient !border-transparent">
        <span aria-hidden className="dot-grid pointer-events-none absolute inset-0 opacity-[0.12]" />
        <h3 className="relative text-lg font-medium text-ink">Share your tip link</h3>
        <p className="relative mt-1 text-sm text-white/80">
          Drop your link in your bio, streams and posts so fans can support you.
        </p>
        {shareUrl && slug ? (
          <>
            <p className="relative mt-3 break-all font-mono text-sm text-white/90">{shareUrl}</p>
            <Link
              href={`/creator/${slug}`}
              className="relative mt-4 inline-flex items-center gap-1.5 rounded-full bg-white px-5 py-2.5 text-sm font-medium text-primary transition hover:opacity-90"
            >
              View your page <ArrowUpRight className="h-4 w-4" strokeWidth={2.4} />
            </Link>
          </>
        ) : (
          <Link
            href="/onboarding"
            className="relative mt-5 inline-flex items-center gap-1.5 rounded-full bg-white px-5 py-2.5 text-sm font-medium text-primary transition hover:opacity-90"
          >
            Set up your creator page <ArrowUpRight className="h-4 w-4" strokeWidth={2.4} />
          </Link>
        )}
      </div>

      <RecentTips tips={tips} loading={loading} />
    </div>
  );
}

function RecentTips({ tips, loading }: { tips: Tip[]; loading: boolean }) {
  return (
    <div>
      <h3 className="mb-4 text-base font-medium text-ink">Recent tips</h3>
      {loading ? (
        <p className="body-muted">Loading…</p>
      ) : tips.length === 0 ? (
        <EmptyState icon={HandCoins} title="No tips yet" body="Share your tip link to start receiving support from your fans." />
      ) : (
        <div className="card overflow-hidden !p-0">
          <div className="overflow-x-auto">
            <table className="w-full min-w-[560px] text-left text-sm">
              <thead className="border-b border-border text-xs uppercase tracking-wide text-muted">
                <tr>
                  <th className="px-5 py-3 font-medium">From</th>
                  <th className="px-5 py-3 font-medium">Message</th>
                  <th className="px-5 py-3 font-medium">Status</th>
                  <th className="px-5 py-3 text-right font-medium">Amount</th>
                </tr>
              </thead>
              <tbody>
                {tips.map((t) => (
                  <tr key={t.id} className="border-b border-border/60 transition-colors last:border-0 hover:bg-ink/[0.02]">
                    <td className="px-5 py-3 font-medium text-ink">{t.tipper_name || "Anonymous"}</td>
                    <td className="max-w-[220px] truncate px-5 py-3 text-muted">{t.message || "—"}</td>
                    <td className="px-5 py-3">
                      <span className="rounded-full bg-teal/10 px-2.5 py-1 text-xs font-medium text-teal">
                        {t.status || "—"}
                      </span>
                    </td>
                    <td className="px-5 py-3 text-right font-bold text-ink">R{money(Number(t.amount) || 0)}</td>
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
type TipPeriod = "all" | "today" | "week" | "month";
const TIP_PERIODS: { id: TipPeriod; label: string }[] = [
  { id: "all", label: "All" },
  { id: "today", label: "Today" },
  { id: "week", label: "7 days" },
  { id: "month", label: "This month" },
];

function TipsTab({ tips, loading }: { tips: Tip[]; loading: boolean }) {
  const [period, setPeriod] = useState<TipPeriod>("all");
  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const cutoff =
    period === "today"
      ? startOfToday
      : period === "week"
        ? new Date(now.getTime() - 7 * 24 * 3600 * 1000)
        : period === "month"
          ? new Date(now.getFullYear(), now.getMonth(), 1)
          : null;
  const filtered = cutoff ? tips.filter((t) => new Date(t.created_at) >= cutoff) : tips;
  const total = filtered.reduce((s, t) => s + (Number(t.amount) || 0), 0);

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h3 className="text-base font-medium text-ink">All tips</h3>
        <span className="text-sm text-muted">
          {filtered.length} tip{filtered.length === 1 ? "" : "s"} · Total: R{money(total)}
        </span>
      </div>
      <div className="flex flex-wrap gap-2">
        {TIP_PERIODS.map((p) => (
          <button
            key={p.id}
            onClick={() => setPeriod(p.id)}
            className={`rounded-full px-3.5 py-1.5 text-xs font-medium transition ${
              period === p.id ? "bg-primary text-white" : "border border-border text-muted hover:text-ink"
            }`}
          >
            {p.label}
          </button>
        ))}
      </div>
      <RecentTips tips={filtered} loading={loading} />
    </div>
  );
}

// ─── Referrals ───────────────────────────────────────────────────────────────
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
        <h2 className="text-xl font-medium tracking-tight text-ink">Referrals</h2>
        <p className="body-muted mt-1">
          Earn {(rate * 100).toFixed(1)}% of tips from every creator you refer — for 6 months.
        </p>
      </div>

      <div className="card relative overflow-hidden bg-brand-gradient !border-transparent">
        <span aria-hidden className="dot-grid pointer-events-none absolute inset-0 opacity-[0.12]" />
        <p className="relative inline-flex items-center gap-1.5 text-xs font-medium uppercase tracking-wide text-white/70">
          <Gift className="h-4 w-4" strokeWidth={2.2} /> Your referral code
        </p>
        <div className="relative mt-3 flex items-center gap-3">
          <span className="font-mono text-3xl font-medium tracking-[0.3em] text-ink">{code || "—"}</span>
          {code && (
            <button
              onClick={() => copy(code, "code")}
              className="rounded-lg bg-white/15 px-3 py-1.5 text-xs font-medium text-ink hover:bg-white/25"
            >
              {copied === "code" ? "Copied!" : "Copy"}
            </button>
          )}
        </div>
        {shareUrl && <p className="relative mt-3 break-all text-xs text-white/60">{shareUrl}</p>}
        {shareUrl && (
          <div className="relative mt-4 flex flex-wrap gap-2">
            <button
              onClick={() => copy(shareUrl, "link")}
              className="inline-flex items-center gap-1.5 rounded-lg bg-white/15 px-3 py-2 text-xs font-medium text-ink hover:bg-white/25"
            >
              <Link2 className="h-3.5 w-3.5" strokeWidth={2.2} />
              {copied === "link" ? "Link copied!" : "Copy link"}
            </button>
            <a
              href={`https://wa.me/?text=${encodeURIComponent(`Sign up on TippingJar with my code ${code}: ${shareUrl}`)}`}
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center gap-1.5 rounded-lg bg-white/15 px-3 py-2 text-xs font-medium text-ink hover:bg-white/25"
            >
              <i className="bi bi-whatsapp" /> WhatsApp
            </a>
            <a
              href={`https://twitter.com/intent/tweet?text=${encodeURIComponent(`I'm earning on @TippingJar — join with my code ${code}! ${shareUrl}`)}`}
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center gap-1.5 rounded-lg bg-white/15 px-3 py-2 text-xs font-medium text-ink hover:bg-white/25"
            >
              <i className="bi bi-twitter-x" /> Twitter / X
            </a>
          </div>
        )}
      </div>

      {/* "Your commission" is live from the referrals service; counts have no
          endpoint yet (the service stores codes, not signups per code). */}
      <div className="stagger grid gap-4 sm:grid-cols-3">
        <StatCard label="Total referrals" value="0" icon={Users} accent="#12A25C" />
        <StatCard label="Active (earning)" value="0" icon={Zap} accent="#E0A536" />
        <StatCard label="Your commission" value={`${(rate * 100).toFixed(1)}%`} icon={Percent} accent="#2563EB" />
      </div>

      <div>
        <h3 className="mb-3 text-base font-medium text-ink">Your referrals</h3>
        <EmptyState icon={Users} title="No referrals yet" body="Share your code above to start earning commission." />
      </div>

      <div>
        <h3 className="mb-4 text-base font-medium text-ink">How it works</h3>
        <div className="space-y-4">
          {steps.map(([title, body], i) => (
            <div key={title} className="flex gap-4">
              <div className="grid h-9 w-9 shrink-0 place-items-center rounded-xl bg-primary/15 text-sm font-medium text-teal">
                {i + 1}
              </div>
              <div>
                <p className="font-medium text-ink">{title}</p>
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
function TransactionsTab({ token, creatorId }: { token: string | null; creatorId: string | null }) {
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
        <span className="grid h-14 w-14 place-items-center rounded-2xl bg-teal/10 text-teal">
          <Receipt className="h-7 w-7" strokeWidth={2} />
        </span>
        <p className="mt-4 font-medium text-ink">Create a creator profile</p>
        <p className="body-muted mt-1">Set up your page to start receiving tips and see transactions.</p>
        <Link href="/onboarding" className="btn-primary mt-5 !px-5 !py-2.5 !font-medium text-sm">
          Set up profile
        </Link>
      </div>
    );
  }
  if (loading) return <p className="body-muted">Loading…</p>;

  const available = Number(balance?.available ?? "0");

  return (
    <div className="space-y-8">
      <div className="stagger grid gap-4 sm:grid-cols-3">
        <StatCard label="Net earned" value={`R${balance?.net_balance ?? "0.00"}`} icon={Banknote} accent="#12A25C" />
        <StatCard label="Withdrawn" value={`R${balance?.withdrawn ?? "0.00"}`} icon={Wallet} accent="#2563EB" />
        <StatCard label="Available" value={`R${balance?.available ?? "0.00"}`} icon={CircleCheck} accent="#0097B2" />
      </div>

      <div className="card flex flex-wrap items-center justify-between gap-4">
        <div>
          <p className="font-medium text-ink">Payouts</p>
          <p className="body-muted">Withdraw your available balance to your bank account.</p>
        </div>
        <button
          onClick={payout}
          disabled={busy || available <= 0}
          className="btn-primary !font-medium disabled:cursor-not-allowed disabled:opacity-50"
        >
          {busy ? "Requesting…" : `Request payout · R${available.toFixed(2)}`}
        </button>
      </div>
      {msg && <p className="text-sm text-teal">{msg}</p>}

      <div>
        <h3 className="mb-4 text-base font-medium text-ink">Transactions</h3>
        {txns.length === 0 ? (
          <EmptyState icon={Receipt} title="No transactions yet" body="Tips and card payments will show up here." />
        ) : (
          <div className="card overflow-hidden !p-0">
            <div className="overflow-x-auto">
              <table className="w-full min-w-[640px] text-left text-sm">
                <thead className="border-b border-border text-xs uppercase tracking-wide text-muted">
                  <tr>
                    <th className="px-5 py-3 font-medium">Reference</th>
                    <th className="px-5 py-3 font-medium">Date</th>
                    <th className="px-5 py-3 font-medium">Status</th>
                    <th className="px-5 py-3 text-right font-medium">Amount</th>
                    <th className="px-5 py-3 text-right font-medium">You get</th>
                  </tr>
                </thead>
                <tbody>
                  {txns.map((t) => (
                    <tr key={t.id} className="border-b border-border/60 transition-colors last:border-0 hover:bg-ink/[0.02]">
                      <td className="px-5 py-3 font-mono text-xs text-muted">{t.reference.slice(0, 18)}…</td>
                      <td className="px-5 py-3 text-muted">{new Date(t.created_at).toLocaleDateString()}</td>
                      <td className="px-5 py-3">
                        <span
                          className={`rounded-full px-2.5 py-1 text-xs font-medium ${
                            t.status === "completed"
                              ? "bg-teal/10 text-teal"
                              : t.status === "pending"
                                ? "bg-yellow-500/10 text-yellow-500"
                                : "bg-red-500/10 text-red-500"
                          }`}
                        >
                          {t.status}
                        </span>
                      </td>
                      <td className="px-5 py-3 text-right text-ink">{t.currency} {t.amount}</td>
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
          <h3 className="mb-4 text-base font-medium text-ink">Payout history</h3>
          <div className="space-y-2">
            {payouts.map((p) => (
              <div key={p.id} className="card flex flex-wrap items-center justify-between gap-3 !py-3">
                <span className="font-mono text-xs text-muted">{p.reference}</span>
                <span className="text-sm text-muted">{new Date(p.created_at).toLocaleDateString()}</span>
                <span className="rounded-full bg-border px-2.5 py-1 text-xs text-muted">{p.status}</span>
                <span className="font-bold text-ink">R{p.amount}</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

// ─── Studio ──────────────────────────────────────────────────────────────────
function StudioTab({ token }: { token: string | null }) {
  return <StudioEditor token={token} />;
}
