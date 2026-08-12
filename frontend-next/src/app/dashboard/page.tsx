"use client";

// Creator dashboard — a full-bleed app shell with its own collapsible sidebar.
// The marketing top-nav + footer are hidden for /dashboard (see SiteFrame), so
// this owns the whole viewport. Tabs render in the content area on the right.

import { useCallback, useEffect, useState, useRef } from "react";
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
  Trophy,
  Download,
  UserRound,
  Megaphone,
  Copy,
  Check,
  BarChart3,
  Lock,
  Milk,
  Tv,
  QrCode,
  Code2,
  Send,
  type LucideIcon,
} from "lucide-react";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { StudioEditor } from "@/components/StudioEditor";
import { LiveClock } from "@/components/Clock";
import type {
  ExclusivePost,
  Jar,
  Supporter,
  Tip,
  ReferralCode,
  Creator,
  CreatorStats,
  Transaction,
  Payout,
  Balance,
} from "@/types";

type Tab = "overview" | "tips" | "supporters" | "analytics" | "exclusive" | "jars" | "transactions" | "referrals" | "studio" | "profile";

const TABS: { id: Tab; label: string; icon: LucideIcon }[] = [
  { id: "overview", label: "Overview", icon: LayoutDashboard },
  { id: "tips", label: "Tips", icon: HandCoins },
  { id: "supporters", label: "Supporters", icon: Trophy },
  { id: "analytics", label: "Analytics", icon: BarChart3 },
  { id: "exclusive", label: "Exclusive", icon: Lock },
  { id: "jars", label: "Jars", icon: Milk },
  { id: "transactions", label: "Transactions", icon: Receipt },
  { id: "referrals", label: "Referrals", icon: Users },
  { id: "studio", label: "Studio", icon: Palette },
  { id: "profile", label: "Profile", icon: UserRound },
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
        <DashboardHeader
          name={name}
          creator={myCreator}
          netEarned={stats ? Number(stats.creator_net_total) || 0 : 0}
          active={active}
          onOpenMobile={() => setMobileOpen(true)}
        />

        <main className="flex-1 px-4 py-7 md:px-8">
          <div key={tab} className="pop-in mx-auto max-w-[1180px]">
            {tab === "overview" && (
              <OverviewTab
                tips={tips}
                loading={loading}
                stats={stats}
                slug={myCreator?.slug ?? null}
                creator={myCreator}
                onTab={setTab}
              />
            )}
            {tab === "tips" && <TipsTab tips={tips} loading={loading} token={token} />}
            {tab === "supporters" && (
              <SupportersTab token={token} creatorId={myCreator?.id ?? null} />
            )}
            {tab === "analytics" && (
              <AnalyticsTab token={token} creatorId={myCreator?.id ?? null} tips={tips} />
            )}
            {tab === "exclusive" && <ExclusiveTab token={token} hasProfile={!!myCreator} />}
            {tab === "jars" && <JarsTab token={token} creator={myCreator} />}
            {tab === "transactions" && (
              <TransactionsTab token={token} creatorId={myCreator?.id ?? null} />
            )}
            {tab === "referrals" && <ReferralsTab referral={referral} />}
            {tab === "studio" && <StudioTab token={token} slug={myCreator?.slug ?? null} />}
            {tab === "profile" && (
              <ProfileTab token={token} creator={myCreator} onSaved={setMyCreator} />
            )}
          </div>
        </main>
      </div>
    </div>
  );
}

// ─── Top app bar ─────────────────────────────────────────────────────────────
function DashboardHeader({
  name,
  creator,
  netEarned,
  active,
  onOpenMobile,
}: {
  name: string;
  creator: Creator | null;
  netEarned: number;
  active: { id: string; label: string; icon: LucideIcon };
  onOpenMobile: () => void;
}) {
  const [copied, setCopied] = useState(false);
  const tipUrl = creator?.slug ? `https://www.tippingjar.co.za/creator/${creator.slug}` : "";
  const money = (n: number) =>
    n.toLocaleString("en-ZA", { minimumFractionDigits: 0, maximumFractionDigits: 0 });

  return (
    <header className="sticky top-0 z-20 flex h-16 items-center gap-3 border-b border-border bg-white/90 px-4 backdrop-blur-xl md:px-7">
      <button
        onClick={onOpenMobile}
        className="grid h-10 w-10 place-items-center rounded-xl text-ink transition-colors hover:bg-ink/5 lg:hidden"
        aria-label="Open menu"
      >
        <Menu className="h-5 w-5" />
      </button>

      {/* Section indicator — big, visible, no wasted space */}
      <div className="min-w-0 hidden sm:flex sm:items-center sm:gap-2.5">
        <span className="grid h-9 w-9 place-items-center rounded-full bg-mint/20 text-teal">
          <active.icon className="h-[18px] w-[18px]" strokeWidth={2.2} />
        </span>
        <div className="min-w-0">
          <p className="text-[10px] font-medium uppercase tracking-[0.14em] text-muted">
            Dashboard
          </p>
          <p className="truncate text-sm font-bold leading-tight text-ink">{active.label}</p>
        </div>
      </div>
      <p className="min-w-0 truncate text-sm font-medium text-ink sm:hidden">{name}</p>

      <div className="ml-auto flex items-center gap-2">
        {/* Net earned pill — always-on money snapshot */}
        <span
          className="hidden items-center gap-1.5 rounded-full border border-teal/30 bg-teal/8 px-3 py-1.5 text-xs font-semibold text-teal md:inline-flex"
          title="Lifetime net earnings"
        >
          <Banknote className="h-3.5 w-3.5" strokeWidth={2.4} />
          R{money(netEarned)}
        </span>

        {/* Live clock */}
        <span className="hidden lg:inline-flex">
          <LiveClock />
        </span>

        {/* One-click tip-link copy — the single most-used action */}
        {tipUrl && (
          <button
            onClick={() => {
              navigator.clipboard?.writeText(tipUrl);
              setCopied(true);
              window.setTimeout(() => setCopied(false), 1800);
            }}
            className={`hidden items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-medium transition-colors sm:inline-flex ${
              copied
                ? "border-teal bg-teal text-white"
                : "border-border bg-white text-ink hover:border-teal hover:text-teal"
            }`}
            title={tipUrl}
          >
            {copied ? (
              <><Check className="h-3.5 w-3.5" strokeWidth={2.6} /> Copied!</>
            ) : (
              <><Copy className="h-3.5 w-3.5" strokeWidth={2.4} /> Copy tip link</>
            )}
          </button>
        )}

        {/* Public page shortcut */}
        <Link
          href={creator?.slug ? `/creator/${creator.slug}` : "/"}
          target={creator?.slug ? "_blank" : undefined}
          className="hidden items-center gap-1.5 rounded-full bg-primary px-3.5 py-1.5 text-xs font-medium text-white transition-colors hover:bg-navy sm:inline-flex"
        >
          View page <ArrowUpRight className="h-3.5 w-3.5" strokeWidth={2.4} />
        </Link>

        {/* Avatar chip (uses uploaded avatar if the creator has one) */}
        {creator?.avatar_url ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={creator.avatar_url}
            alt={name}
            title={name}
            className="h-9 w-9 shrink-0 rounded-full object-cover shadow-soft ring-2 ring-white"
          />
        ) : (
          <span
            title={name}
            className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-primary text-sm font-medium text-white shadow-soft ring-2 ring-white"
          >
            {name.charAt(0).toUpperCase()}
          </span>
        )}
      </div>
    </header>
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
  danger,
}: {
  icon: LucideIcon;
  label: string;
  active?: boolean;
  collapsed: boolean;
  onClick?: () => void;
  href?: string;
  danger?: boolean;
}) {
  // Danger variant (used by Log out) mirrors the active pill's shape/size but
  // in red-on-red-tint with white text, so it reads as a destructive action.
  const cls = `group relative flex w-full items-center gap-3 rounded-[32px] p-1.5 transition-colors duration-200 ${
    collapsed ? "lg:justify-center" : ""
  } ${danger ? "bg-red-500/20 hover:bg-red-500/30" : active ? "nav-glass" : "hover:bg-white/[0.06]"}`;
  const inner = (
    <>
      <span
        className={`grid h-9 w-9 shrink-0 place-items-center rounded-full transition-colors duration-200 ${
          danger
            ? "ml-[2px] bg-red-500/30 text-white ring-1 ring-red-400/40"
            : active
              ? "ml-[2px] bg-mint/25 text-mint ring-1 ring-mint/30"
              : "text-white/70 group-hover:bg-white/10 group-hover:text-white"
        }`}
      >
        <Icon className="h-[18px] w-[18px]" strokeWidth={2} />
      </span>
      <span
        className={`text-sm font-medium ${danger ? "text-white" : active ? "text-white" : "text-white/65 group-hover:text-white"} ${
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
            <span className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-mint text-navy shadow-lift">
              <span aria-hidden className="text-lg leading-none">🫙</span>
            </span>
            <span className="font-display text-lg font-medium tracking-tight">
              Tipping<span className="text-mint">Jar</span>
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
          <NavRow
            icon={LogOut}
            label="Log out"
            collapsed={collapsed}
            danger
            onClick={() => {
              if (window.confirm("Log out of your Tipping Jar dashboard?")) onLogout();
            }}
          />
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
    <div className="card !p-5">
      <div
        className="grid h-10 w-10 place-items-center rounded-xl"
        style={{ backgroundColor: c + "22" }}
      >
        <Icon className="h-5 w-5" style={{ color: c }} strokeWidth={2.2} />
      </div>
      <p className="mt-4 text-2xl font-extrabold tracking-tight text-ink">
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

async function downloadQrPoster(slug: string) {
  const QRCode = (await import("qrcode")).default;
  const url = `https://www.tippingjar.co.za/creator/${slug}`;
  const qr = await QRCode.toDataURL(url, { width: 560, margin: 1, color: { dark: "#0F2439", light: "#FFFFFF" } });
  const W = 1080, H = 1350;
  const c = document.createElement("canvas");
  c.width = W; c.height = H;
  const ctx = c.getContext("2d")!;
  const g = ctx.createLinearGradient(0, 0, W, H);
  g.addColorStop(0, "#0F2439"); g.addColorStop(1, "#12A25C");
  ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  ctx.fillStyle = "#FFFFFF"; ctx.textAlign = "center";
  ctx.font = "800 92px Manrope, system-ui, sans-serif";
  ctx.fillText("Enjoying my work?", W / 2, 200);
  ctx.fillStyle = "#57CE8B";
  ctx.font = "500 48px Manrope, system-ui, sans-serif";
  ctx.fillText("Scan to drop a tip in my jar", W / 2, 290);
  // QR card
  const qs = 620, qx = (W - qs) / 2, qy = 400;
  ctx.fillStyle = "#FFFFFF";
  ctx.beginPath();
  ctx.roundRect(qx - 30, qy - 30, qs + 60, qs + 60, 40);
  ctx.fill();
  const img = new Image();
  await new Promise<void>((res) => { img.onload = () => res(); img.src = qr; });
  ctx.drawImage(img, qx, qy, qs, qs);
  ctx.fillStyle = "#FFFFFF";
  ctx.font = "500 40px 'Space Mono', monospace";
  ctx.fillText(`tippingjar.co.za/creator/${slug}`, W / 2, qy + qs + 140);
  const a = document.createElement("a");
  a.href = c.toDataURL("image/png");
  a.download = `tip-qr-${slug}.png`;
  a.click();
}

function OverviewTab({
  tips,
  loading,
  stats,
  slug,
  creator,
  onTab,
}: {
  tips: Tip[];
  loading: boolean;
  stats: CreatorStats | null;
  slug: string | null;
  creator: Creator | null;
  onTab: (t: Tab) => void;
}) {
  const netEarned = stats ? Number(stats.creator_net_total) || 0 : 0;
  const thisMonth = stats ? Number(stats.this_month_amount) || 0 : 0;
  const shareUrl = slug ? `https://tippingjar.co.za/creator/${slug}` : null;

  // Monthly goal push
  const goal = creator?.tip_goal ? Number(creator.tip_goal) : 0;
  const goalPct = goal > 0 ? Math.min(100, Math.round((thisMonth / goal) * 100)) : 0;
  const goalGap = Math.max(0, goal - thisMonth);

  // 7-day tip volume sparkline (from the tips prop)
  const completed = tips.filter((t) => t.status === "completed");
  const startOfToday = new Date();
  startOfToday.setHours(0, 0, 0, 0);
  const week: { day: string; amount: number }[] = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date(startOfToday.getTime() - i * 86400000);
    const next = new Date(d.getTime() + 86400000);
    const amount = completed
      .filter((t) => {
        const td = new Date(t.created_at);
        return td >= d && td < next;
      })
      .reduce((s, t) => s + (Number(t.amount) || 0), 0);
    week.push({ day: d.toLocaleDateString("en-ZA", { weekday: "short" }).charAt(0), amount });
  }
  const weekMax = Math.max(...week.map((w) => w.amount), 1);
  const weekTotal = week.reduce((s, w) => s + w.amount, 0);

  return (
    <div className="space-y-8">
      <div className="stagger grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Net earned" value={`R${money(netEarned)}`} icon={Banknote} accent="#12A25C" />
        <StatCard label="This month" value={`R${money(thisMonth)}`} icon={Calendar} accent="#2563EB" />
        <StatCard label="Supporters" value={String(stats?.supporter_count ?? 0)} icon={Users} accent="#E0A536" />
        <StatCard label="Total tips" value={String(stats?.tip_count ?? 0)} icon={Heart} accent="#EC4899" />
      </div>

      {/* Quick actions — the four things a creator does most, one click away */}
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        {[
          { icon: Megaphone,  label: "Message supporters", tab: "supporters" as Tab, accent: "#12A25C" },
          { icon: Lock,       label: "Publish exclusive",  tab: "exclusive"  as Tab, accent: "#7C3AED" },
          { icon: Milk,       label: "Create a jar",        tab: "jars"       as Tab, accent: "#E0A536" },
          { icon: Palette,    label: "Design a promo",      tab: "studio"     as Tab, accent: "#EC4899" },
        ].map((a) => (
          <button
            key={a.label}
            onClick={() => onTab(a.tab)}
            className="card group flex items-center gap-3 !p-4 text-left transition hover:border-teal/40"
          >
            <span
              className="grid h-10 w-10 shrink-0 place-items-center rounded-full transition group-hover:scale-105"
              style={{ backgroundColor: a.accent + "22" }}
            >
              <a.icon className="h-[18px] w-[18px]" style={{ color: a.accent }} strokeWidth={2.2} />
            </span>
            <span className="min-w-0 flex-1">
              <p className="text-sm font-semibold text-ink">{a.label}</p>
              <p className="mt-0.5 text-[11px] text-muted">Jump to the {a.tab} tab</p>
            </span>
            <ArrowUpRight className="h-4 w-4 shrink-0 text-muted transition group-hover:text-teal" strokeWidth={2.4} />
          </button>
        ))}
      </div>

      {/* Monthly goal + 7-day momentum, side by side */}
      <div className="grid gap-6 lg:grid-cols-[1.15fr_1fr]">
        <div className="card !p-5">
          <div className="flex items-center justify-between">
            <p className="text-xs font-semibold uppercase tracking-wide text-muted">This month vs your goal</p>
            {goal > 0 && (
              <span className="text-xs font-semibold text-teal">
                {goalPct}%
              </span>
            )}
          </div>
          {goal > 0 ? (
            <>
              <p className="mt-3 font-display text-3xl font-extrabold tracking-tight text-ink">
                R{money(thisMonth)}
                <span className="ml-2 text-base font-medium text-muted">of R{money(goal)}</span>
              </p>
              <div className="mt-4 h-3 overflow-hidden rounded-full bg-border/60">
                <div
                  className="h-full rounded-full bg-teal transition-all duration-700"
                  style={{ width: `${Math.max(3, goalPct)}%` }}
                />
              </div>
              <p className="mt-3 text-xs text-muted">
                {goalPct >= 100 ? (
                  <span className="font-semibold text-teal">🎉 You smashed it. Push the next stretch goal!</span>
                ) : (
                  <>Need <span className="font-semibold text-ink">R{money(goalGap)}</span> more to hit your monthly goal.</>
                )}
              </p>
            </>
          ) : (
            <>
              <p className="body-muted mt-3">
                Set a monthly tip goal to unlock a live progress bar on your page and here.
              </p>
              <button
                onClick={() => onTab("profile")}
                className="btn-primary mt-4 !px-5 !py-2 text-sm"
              >
                Set a goal
              </button>
            </>
          )}
        </div>

        <div className="card !p-5">
          <div className="flex items-baseline justify-between">
            <p className="text-xs font-semibold uppercase tracking-wide text-muted">Last 7 days</p>
            <p className="text-sm font-bold text-ink">R{money(weekTotal)}</p>
          </div>
          <div className="mt-4 flex h-24 items-end gap-2">
            {week.map((w, i) => (
              <div key={i} className="flex flex-1 flex-col items-center gap-1.5">
                <div
                  className="w-full rounded-t bg-teal/70 transition hover:bg-teal"
                  style={{ height: `${Math.max(4, (w.amount / weekMax) * 80)}px` }}
                  title={`R${money(w.amount)}`}
                />
                <span className="font-mono text-[10px] uppercase text-muted">{w.day}</span>
              </div>
            ))}
          </div>
          <button
            onClick={() => onTab("analytics")}
            className="mt-3 text-xs font-medium text-teal hover:underline"
          >
            See full analytics →
          </button>
        </div>
      </div>

      {/* Achievements */}
      {stats && (
        <div className="flex flex-wrap gap-2">
          {[
            { earned: (stats.tip_count ?? 0) >= 1, icon: "🫙", label: "First tip" },
            { earned: Number(stats.total_amount) >= 100, icon: "🪙", label: "R100 club" },
            { earned: Number(stats.total_amount) >= 1000, icon: "💰", label: "R1k club" },
            { earned: (stats.supporter_count ?? 0) >= 5, icon: "🙌", label: "5 supporters" },
            { earned: (stats.supporter_count ?? 0) >= 25, icon: "🔥", label: "25 supporters" },
            { earned: (stats.tip_count ?? 0) >= 50, icon: "⭐", label: "50 tips" },
          ].map((a) => (
            <span
              key={a.label}
              title={a.earned ? "Earned!" : "Locked — keep going"}
              className={`inline-flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-medium transition ${
                a.earned ? "border-gold/40 bg-gold/10 text-ink" : "border-border text-muted/50 grayscale"
              }`}
            >
              {a.icon} {a.label}
            </span>
          ))}
        </div>
      )}

      {/* Share tip link */}
      <div className="card">
        <h3 className="text-lg font-semibold text-ink">Share your tip link</h3>
        <p className="mt-1 text-sm text-muted">
          Drop your link in your bio, streams and posts so fans can support you.
        </p>
        {shareUrl && slug ? (
          <>
            <p className="mt-3 break-all rounded-lg bg-darker px-3 py-2 font-mono text-sm text-ink">{shareUrl}</p>
            <div className="mt-4 flex flex-wrap gap-2">
              <Link
                href={`/creator/${slug}`}
                target="_blank"
                className="inline-flex items-center gap-1.5 rounded-full bg-primary px-5 py-2.5 text-sm font-medium text-white transition hover:bg-navy"
              >
                View your page <ArrowUpRight className="h-4 w-4" strokeWidth={2.4} />
              </Link>
              <button
                onClick={() => downloadQrPoster(slug)}
                className="inline-flex items-center gap-1.5 rounded-full border border-border px-5 py-2.5 text-sm font-medium text-muted transition hover:border-teal hover:text-teal"
              >
                <QrCode className="h-4 w-4" strokeWidth={2.2} /> QR poster
              </button>
              <button
                onClick={() => {
                  navigator.clipboard?.writeText(`https://www.tippingjar.co.za/overlay/${slug}`);
                  window.alert("Overlay URL copied — add it as a Browser Source in OBS/Streamlabs (transparent, shows live tip alerts + your goal bar).");
                }}
                className="inline-flex items-center gap-1.5 rounded-full border border-border px-5 py-2.5 text-sm font-medium text-muted transition hover:border-teal hover:text-teal"
              >
                <Tv className="h-4 w-4" strokeWidth={2.2} /> OBS overlay
              </button>
              <button
                onClick={() => {
                  navigator.clipboard?.writeText(
                    `<iframe src="https://www.tippingjar.co.za/embed/${slug}" width="320" height="440" style="border:0;border-radius:16px" title="Tip me on Tipping Jar"></iframe>`,
                  );
                  window.alert("Embed code copied — paste it into your website.");
                }}
                className="inline-flex items-center gap-1.5 rounded-full border border-border px-5 py-2.5 text-sm font-medium text-muted transition hover:border-teal hover:text-teal"
              >
                <Code2 className="h-4 w-4" strokeWidth={2.2} /> Embed widget
              </button>
            </div>
          </>
        ) : (
          <Link
            href="/onboarding"
            className="mt-5 inline-flex items-center gap-1.5 rounded-full bg-primary px-5 py-2.5 text-sm font-medium text-white transition hover:bg-navy"
          >
            Set up your creator page <ArrowUpRight className="h-4 w-4" strokeWidth={2.4} />
          </Link>
        )}
      </div>

      <RecentTips tips={tips} loading={loading} />
    </div>
  );
}

function RecentTips({ tips, loading, token }: { tips: Tip[]; loading: boolean; token?: string | null }) {
  const [thanked, setThanked] = useState<Set<string>>(new Set());
  const [busy, setBusy] = useState<string | null>(null);

  async function thank(t: Tip) {
    if (!token) return;
    const message = window.prompt(`Send a thank-you note to ${t.tipper_name || "this supporter"}:`, "Thank you so much for the support! 💚");
    if (!message?.trim()) return;
    setBusy(t.id);
    try {
      await api.thankTip(token, t.id, message.trim());
      setThanked((prev) => new Set(prev).add(t.id));
    } catch (e) {
      window.alert(e instanceof Error ? e.message : "Could not send the thank-you.");
    } finally {
      setBusy(null);
    }
  }

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
                  {token && <th className="px-5 py-3 text-right font-medium">Thanks</th>}
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
                    {token && (
                      <td className="px-5 py-3 text-right">
                        {t.thanked_at || thanked.has(t.id) ? (
                          <span className="text-xs text-teal">Sent ✓</span>
                        ) : t.tipper_email ? (
                          <button
                            onClick={() => thank(t)}
                            disabled={busy === t.id}
                            className="inline-flex items-center gap-1 rounded-full border border-border px-3 py-1 text-xs font-medium text-muted transition hover:border-teal hover:text-teal disabled:opacity-50"
                          >
                            <Send className="h-3 w-3" strokeWidth={2.2} /> Thank
                          </button>
                        ) : (
                          <span className="text-xs text-muted/60">no email</span>
                        )}
                      </td>
                    )}
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

function exportTipsCsv(tips: Tip[]) {
  const esc = (v: string) => `"${(v || "").replace(/"/g, '""')}"`;
  const rows = [
    "date,tipper,email,message,amount,platform_fee,service_fee,net,status,reference",
    ...tips.map((t) =>
      [
        new Date(t.created_at).toISOString(), esc(t.tipper_name), esc(t.tipper_email),
        esc(t.message), t.amount, t.platform_fee, t.service_fee, t.creator_net, t.status, t.reference,
      ].join(","),
    ),
  ];
  const blob = new Blob([rows.join("\n")], { type: "text/csv" });
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = `tipping-jar-tips-${new Date().toISOString().slice(0, 10)}.csv`;
  a.click();
  URL.revokeObjectURL(a.href);
}

function TipsTab({ tips, loading, token }: { tips: Tip[]; loading: boolean; token?: string | null }) {
  const [period, setPeriod] = useState<TipPeriod>("all");
  const [status, setStatus] = useState<"all" | "completed" | "pending" | "failed">("all");
  const [minAmount, setMinAmount] = useState(""); // empty = any
  const [q, setQ] = useState("");

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

  const minA = parseFloat(minAmount);
  const filtered = tips.filter((t) => {
    if (cutoff && new Date(t.created_at) < cutoff) return false;
    if (status !== "all" && t.status !== status) return false;
    if (!Number.isNaN(minA) && Number(t.amount) < minA) return false;
    if (q) {
      const needle = q.toLowerCase();
      if (
        !(t.tipper_name || "").toLowerCase().includes(needle) &&
        !(t.message || "").toLowerCase().includes(needle) &&
        !(t.tipper_email || "").toLowerCase().includes(needle) &&
        !(t.reference || "").toLowerCase().includes(needle)
      ) return false;
    }
    return true;
  });

  const completed = filtered.filter((t) => t.status === "completed");
  const total = completed.reduce((s, t) => s + (Number(t.amount) || 0), 0);
  const avg = completed.length ? total / completed.length : 0;
  const biggest = completed.reduce((m, t) => Math.max(m, Number(t.amount) || 0), 0);
  const withMessages = filtered.filter((t) => t.message).length;
  const unthanked = filtered.filter((t) => t.status === "completed" && t.tipper_email && !t.thanked_at).length;

  // Daily activity strip — 14 days of completed-tip counts
  const days: { day: string; count: number; amount: number }[] = [];
  for (let i = 13; i >= 0; i--) {
    const d = new Date(startOfToday.getTime() - i * 86400000);
    const next = new Date(d.getTime() + 86400000);
    const rows = completed.filter((t) => {
      const td = new Date(t.created_at);
      return td >= d && td < next;
    });
    days.push({
      day: d.toLocaleDateString("en-ZA", { weekday: "short" }).charAt(0),
      count: rows.length,
      amount: rows.reduce((s, t) => s + (Number(t.amount) || 0), 0),
    });
  }
  const maxCount = Math.max(...days.map((d) => d.count), 1);

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h2 className="text-xl font-medium tracking-tight text-ink">Tips</h2>
          <p className="body-muted mt-1 text-sm">Everything you&apos;ve been sent — search, filter, thank, export.</p>
        </div>
        <button
          onClick={() => exportTipsCsv(filtered)}
          disabled={filtered.length === 0}
          className="inline-flex items-center gap-1.5 rounded-full border border-border bg-white px-4 py-2 text-xs font-medium text-muted transition hover:border-teal hover:text-teal disabled:opacity-40"
        >
          <Download className="h-3.5 w-3.5" strokeWidth={2.2} /> Export CSV
        </button>
      </div>

      {/* KPI header — the numbers for the current filter, not lifetime */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Tips shown" value={String(filtered.length)} icon={HandCoins} accent="#12A25C" />
        <StatCard label="Completed volume" value={`R${money(total)}`} icon={Banknote} accent="#2563EB" />
        <StatCard label="Average tip" value={`R${money(avg)}`} icon={Percent} accent="#E0A536" />
        <StatCard label="Biggest tip" value={`R${money(biggest)}`} icon={Trophy} accent="#EC4899" />
      </div>

      {/* Callouts row: unthanked + messages */}
      {filtered.length > 0 && (
        <div className="grid gap-3 sm:grid-cols-2">
          <div className={`card flex items-center gap-3 !p-4 ${unthanked > 0 ? "!border-teal/40" : ""}`}>
            <span className="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-teal/15 text-teal">
              <Send className="h-4 w-4" strokeWidth={2.4} />
            </span>
            <div className="min-w-0 flex-1">
              <p className="text-sm font-semibold text-ink">
                {unthanked > 0
                  ? `${unthanked} supporter${unthanked === 1 ? "" : "s"} not yet thanked`
                  : "All supporters thanked ✨"}
              </p>
              <p className="text-xs text-muted">Reply personally under any tip below.</p>
            </div>
          </div>
          <div className="card flex items-center gap-3 !p-4">
            <span className="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-mint/20 text-green">
              <Heart className="h-4 w-4" strokeWidth={2.4} />
            </span>
            <div className="min-w-0 flex-1">
              <p className="text-sm font-semibold text-ink">
                {withMessages} tip{withMessages === 1 ? "" : "s"} with a message
              </p>
              <p className="text-xs text-muted">
                {filtered.length ? Math.round((withMessages / filtered.length) * 100) : 0}% of the current filter left a note.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* 14-day activity strip */}
      <div className="card !p-5">
        <div className="flex items-baseline justify-between">
          <p className="text-xs font-semibold uppercase tracking-wide text-muted">Activity · last 14 days</p>
          <p className="text-sm font-bold text-ink">{days.reduce((s, d) => s + d.count, 0)} completed</p>
        </div>
        <div className="mt-4 flex h-20 items-end gap-1.5">
          {days.map((d, i) => (
            <div key={i} className="flex flex-1 flex-col items-center gap-1">
              <div
                className="w-full rounded-t bg-teal/70 transition hover:bg-teal"
                style={{ height: `${Math.max(4, (d.count / maxCount) * 68)}px` }}
                title={`${d.count} tip${d.count === 1 ? "" : "s"} · R${money(d.amount)}`}
              />
              <span className="font-mono text-[10px] uppercase text-muted">{d.day}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Filter toolbar */}
      <div className="card flex flex-wrap items-center gap-3 !p-4">
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Search name, email, message or reference…"
          className="w-full max-w-xs rounded-full border border-border bg-white px-4 py-2 text-sm text-ink focus:border-primary/40 focus:outline-none"
        />
        <input
          value={minAmount}
          onChange={(e) => setMinAmount(e.target.value.replace(/[^0-9.]/g, ""))}
          inputMode="decimal"
          placeholder="Min R"
          className="w-24 rounded-full border border-border bg-white px-4 py-2 text-sm text-ink focus:border-primary/40 focus:outline-none"
        />
        <div className="flex flex-wrap gap-1.5">
          {(["all", "completed", "pending", "failed"] as const).map((s) => (
            <button
              key={s}
              onClick={() => setStatus(s)}
              className={`rounded-full px-3 py-1.5 text-xs font-medium transition ${
                status === s ? "bg-primary text-white" : "border border-border text-muted hover:text-ink"
              }`}
            >
              {s}
            </button>
          ))}
        </div>
        <span className="mx-1 h-5 w-px bg-border" />
        <div className="flex flex-wrap gap-1.5">
          {TIP_PERIODS.map((p) => (
            <button
              key={p.id}
              onClick={() => setPeriod(p.id)}
              className={`rounded-full px-3 py-1.5 text-xs font-medium transition ${
                period === p.id ? "bg-primary text-white" : "border border-border text-muted hover:text-ink"
              }`}
            >
              {p.label}
            </button>
          ))}
        </div>
        {(q || status !== "all" || minAmount || period !== "all") && (
          <button
            onClick={() => { setQ(""); setStatus("all"); setMinAmount(""); setPeriod("all"); }}
            className="ml-auto text-xs font-medium text-muted hover:text-ink"
          >
            Clear filters
          </button>
        )}
      </div>

      {filtered.length === 0 && !loading ? (
        <EmptyState icon={HandCoins} title="No tips match those filters" body="Try widening the period, dropping the min amount, or clearing your search." />
      ) : (
        <RecentTips tips={filtered} loading={loading} token={token} />
      )}
    </div>
  );
}

// ─── Supporters ──────────────────────────────────────────────────────────────
function exportTipsCsvSupporters(rows: Supporter[]) {
  const esc = (v: string) => `"${(v || "").replace(/"/g, '""')}"`;
  const lines = [
    "name,email,tips,total,last_tip",
    ...rows.map((r) => [esc(r.name), esc(r.email), r.tip_count, r.total, r.last_tip_at].join(",")),
  ];
  const blob = new Blob([lines.join("\n")], { type: "text/csv" });
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = `supporters-${new Date().toISOString().slice(0, 10)}.csv`;
  a.click();
  URL.revokeObjectURL(a.href);
}

function SupportersTab({ token, creatorId }: { token: string | null; creatorId: string | null }) {
  const [rows, setRows] = useState<Supporter[] | null>(null);
  const [err, setErr] = useState(false);
  const [composing, setComposing] = useState(false);
  const [subject, setSubject] = useState("");
  const [body, setBody] = useState("");
  const [sending, setSending] = useState(false);
  const [sendNote, setSendNote] = useState<string | null>(null);
  useEffect(() => {
    if (!token || !creatorId) { setRows([]); return; }
    api.creatorSupporters(token, creatorId).then(setRows).catch(() => setErr(true));
  }, [token, creatorId]);

  if (err) return <EmptyState icon={Trophy} title="Couldn't load supporters" body="Try refreshing the page." />;
  if (!rows) return <p className="body-muted">Loading…</p>;
  if (rows.length === 0)
    return <EmptyState icon={Trophy} title="No supporters yet" body="When fans tip you, your biggest supporters appear here." />;

  const medals = ["🥇", "🥈", "🥉"];
  const total = rows.reduce((s, r) => s + Number(r.total || 0), 0);
  const withEmail = rows.filter((r) => r.email).length;
  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h2 className="text-xl font-medium tracking-tight text-ink">Your supporters</h2>
          <p className="body-muted mt-1">{rows.length} supporter{rows.length === 1 ? "" : "s"} · R{money(total)} lifetime</p>
        </div>
        <button
          onClick={() =>
            exportTipsCsvSupporters(rows)
          }
          className="btn-ghost !px-4 !py-2.5 text-xs"
        >
          <Download className="h-3.5 w-3.5" strokeWidth={2.2} /> CSV
        </button>
        <button
          onClick={() => setComposing((v) => !v)}
          disabled={withEmail === 0}
          className="btn-primary !px-5 !py-2.5 text-sm disabled:opacity-50"
          title={withEmail === 0 ? "No supporters left an email yet" : `Email your ${withEmail} reachable supporter(s)`}
        >
          <Megaphone className="h-4 w-4" strokeWidth={2.2} /> Message supporters
        </button>
      </div>

      {composing && (
        <div className="card space-y-3 !p-5">
          <p className="text-sm font-medium text-ink">
            Send an update to {withEmail} supporter{withEmail === 1 ? "" : "s"} who left an email
          </p>
          <input
            value={subject}
            onChange={(e) => setSubject(e.target.value)}
            placeholder="Subject — e.g. New album out Friday!"
            className="w-full rounded-xl border border-border bg-white px-4 py-2.5 text-sm text-ink focus:border-primary/40 focus:outline-none"
          />
          <textarea
            value={body}
            onChange={(e) => setBody(e.target.value)}
            rows={5}
            placeholder="Your update… fans love hearing what their support made possible."
            className="w-full rounded-xl border border-border bg-white px-4 py-2.5 text-sm text-ink focus:border-primary/40 focus:outline-none"
          />
          <div className="flex items-center gap-3">
            <button
              onClick={async () => {
                if (!token || !creatorId || !subject.trim() || !body.trim()) return;
                setSending(true);
                setSendNote(null);
                try {
                  const r = await api.messageSupporters(token, creatorId, { subject: subject.trim(), message: body.trim() });
                  setSendNote(`Sent to ${r.sent}/${r.recipients} supporter(s).`);
                  setSubject("");
                  setBody("");
                } catch (e) {
                  setSendNote(e instanceof Error ? e.message : "Send failed.");
                } finally {
                  setSending(false);
                }
              }}
              disabled={sending || !subject.trim() || !body.trim()}
              className="btn-primary !px-5 !py-2 text-sm disabled:opacity-50"
            >
              {sending ? "Sending…" : "Send update"}
            </button>
            {sendNote && <p className="text-sm text-teal">{sendNote}</p>}
          </div>
        </div>
      )}
      <div className="card overflow-hidden !p-0">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[560px] text-left text-sm">
            <thead className="border-b border-border text-xs uppercase tracking-wide text-muted">
              <tr>
                <th className="px-5 py-3 font-medium">#</th>
                <th className="px-5 py-3 font-medium">Supporter</th>
                <th className="px-5 py-3 font-medium">Tips</th>
                <th className="px-5 py-3 font-medium">Last tip</th>
                <th className="px-5 py-3 text-right font-medium">Lifetime</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r, i) => (
                <tr key={`${r.name}-${i}`} className="border-b border-border/60 last:border-0 hover:bg-ink/[0.02]">
                  <td className="px-5 py-3 text-lg">{medals[i] ?? <span className="text-xs text-muted">{i + 1}</span>}</td>
                  <td className="px-5 py-3">
                    <span className="font-medium text-ink">{r.name || "Anonymous"}</span>
                    {r.email && <span className="ml-2 text-xs text-muted">{r.email}</span>}
                  </td>
                  <td className="px-5 py-3 text-muted">{r.tip_count}</td>
                  <td className="px-5 py-3 text-muted">{new Date(r.last_tip_at).toLocaleDateString("en-ZA", { day: "numeric", month: "short" })}</td>
                  <td className="px-5 py-3 text-right font-bold text-teal">R{money(Number(r.total) || 0)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
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

      <div className="card">
        <p className="inline-flex items-center gap-1.5 text-xs font-medium uppercase tracking-wide text-muted">
          <Gift className="h-4 w-4" strokeWidth={2.2} /> Your referral code
        </p>
        <div className="mt-3 flex items-center gap-3">
          <span className="font-mono text-3xl font-medium tracking-[0.3em] text-ink">{code || "—"}</span>
          {code && (
            <button
              onClick={() => copy(code, "code")}
              className="rounded-lg border border-border px-3 py-1.5 text-xs font-medium text-muted hover:border-teal hover:text-teal"
            >
              {copied === "code" ? "Copied!" : "Copy"}
            </button>
          )}
        </div>
        {shareUrl && <p className="mt-3 break-all text-xs text-muted">{shareUrl}</p>}
        {shareUrl && (
          <div className="mt-4 flex flex-wrap gap-2">
            <button
              onClick={() => copy(shareUrl, "link")}
              className="inline-flex items-center gap-1.5 rounded-lg border border-border px-3 py-2 text-xs font-medium text-muted hover:border-teal hover:text-teal"
            >
              <Link2 className="h-3.5 w-3.5" strokeWidth={2.2} />
              {copied === "link" ? "Link copied!" : "Copy link"}
            </button>
            <a
              href={`https://wa.me/?text=${encodeURIComponent(`Sign up on TippingJar with my code ${code}: ${shareUrl}`)}`}
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center gap-1.5 rounded-lg border border-border px-3 py-2 text-xs font-medium text-muted hover:border-teal hover:text-teal"
            >
              <i className="bi bi-whatsapp" /> WhatsApp
            </a>
            <a
              href={`https://twitter.com/intent/tweet?text=${encodeURIComponent(`I'm earning on @TippingJar — join with my code ${code}! ${shareUrl}`)}`}
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center gap-1.5 rounded-lg border border-border px-3 py-2 text-xs font-medium text-muted hover:border-teal hover:text-teal"
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
function StudioTab({ token, slug }: { token: string | null; slug: string | null }) {
  return <StudioEditor token={token} slug={slug} />;
}


// ─── Analytics ───────────────────────────────────────────────────────────────
function LineChart({ points, color = "#12A25C", height = 130 }: { points: number[]; color?: string; height?: number }) {
  const W = 600;
  const max = Math.max(...points, 1);
  const step = W / Math.max(points.length - 1, 1);
  const coords = points.map((v, i) => [i * step, height - 8 - (v / max) * (height - 20)]);
  const path = coords.map(([x, y], i) => `${i === 0 ? "M" : "L"}${x.toFixed(1)},${y.toFixed(1)}`).join(" ");
  const area = `${path} L${W},${height} L0,${height} Z`;
  return (
    <svg viewBox={`0 0 ${W} ${height}`} className="w-full" preserveAspectRatio="none" role="img" aria-label="line chart">
      <path d={area} fill={color} opacity="0.12" />
      <path d={path} fill="none" stroke={color} strokeWidth="2.5" strokeLinejoin="round" strokeLinecap="round" />
      {coords.length > 0 && (
        <circle cx={coords[coords.length - 1][0]} cy={coords[coords.length - 1][1]} r="4" fill={color} />
      )}
    </svg>
  );
}

function Donut({ slices }: { slices: { label: string; value: number; color: string }[] }) {
  const total = slices.reduce((s, x) => s + x.value, 0) || 1;
  let acc = 0;
  const R = 15.9155; // circumference 100
  return (
    <div className="flex items-center gap-5">
      <svg viewBox="0 0 42 42" className="h-28 w-28 -rotate-90">
        <circle cx="21" cy="21" r={R} fill="none" stroke="#EFF2F0" strokeWidth="6" />
        {slices.map((sl) => {
          const frac = (sl.value / total) * 100;
          const el = (
            <circle
              key={sl.label}
              cx="21" cy="21" r={R} fill="none"
              stroke={sl.color} strokeWidth="6"
              strokeDasharray={`${frac} ${100 - frac}`}
              strokeDashoffset={-acc}
              strokeLinecap="butt"
            />
          );
          acc += frac;
          return el;
        })}
      </svg>
      <div className="space-y-1.5">
        {slices.map((sl) => (
          <p key={sl.label} className="flex items-center gap-2 text-xs text-muted">
            <span className="h-2.5 w-2.5 rounded-full" style={{ background: sl.color }} />
            {sl.label} · <span className="font-semibold text-ink">{sl.value}</span>
          </p>
        ))}
      </div>
    </div>
  );
}

function AnalyticsTab({ token, creatorId, tips }: { token: string | null; creatorId: string | null; tips: Tip[] }) {
  const [days, setDays] = useState<{ day: string; count: number; gross: string; net: string }[] | null>(null);
  useEffect(() => {
    if (!token || !creatorId) { setDays([]); return; }
    api.creatorDailyStats(token, creatorId).then(setDays).catch(() => setDays([]));
  }, [token, creatorId]);

  const completed = tips.filter((t) => t.status === "completed");
  const now = new Date();
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
  const lastMonthStart = new Date(now.getFullYear(), now.getMonth() - 1, 1);
  const thisMonth = completed.filter((t) => new Date(t.created_at) >= monthStart).reduce((s, t) => s + Number(t.amount || 0), 0);
  const lastMonth = completed
    .filter((t) => { const d = new Date(t.created_at); return d >= lastMonthStart && d < monthStart; })
    .reduce((s, t) => s + Number(t.amount || 0), 0);
  const avg = completed.length ? completed.reduce((s, t) => s + Number(t.amount || 0), 0) / completed.length : 0;
  const biggest = completed.reduce((m, t) => Math.max(m, Number(t.amount || 0)), 0);
  const delta = lastMonth > 0 ? Math.round(((thisMonth - lastMonth) / lastMonth) * 100) : null;

  // 30-day series (gaps filled)
  const map = new Map((days ?? []).map((d) => [d.day, d]));
  const series: { day: string; gross: number; net: number; count: number }[] = [];
  for (let i = 29; i >= 0; i--) {
    const key = new Date(Date.now() - i * 86400000).toISOString().slice(0, 10);
    const row = map.get(key);
    series.push({ day: key, gross: Number(row?.gross ?? 0), net: Number(row?.net ?? 0), count: row?.count ?? 0 });
  }
  const max = Math.max(...series.map((x) => x.gross), 1);
  const total30 = series.reduce((s, x) => s + x.gross, 0);
  // cumulative net earnings line
  let running = 0;
  const cumulative = series.map((x) => (running += x.net));
  // weekday performance (from full tips history)
  const weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  const byDay = new Array(7).fill(0);
  completed.forEach((t) => { byDay[(new Date(t.created_at).getDay() + 6) % 7] += Number(t.amount || 0); });
  const maxDay = Math.max(...byDay, 1);
  // tip-size distribution
  const buckets = [
    { label: "R10–24", value: 0, color: "#57CE8B" },
    { label: "R25–49", value: 0, color: "#12A25C" },
    { label: "R50–99", value: 0, color: "#0F2439" },
    { label: "R100+", value: 0, color: "#E0A536" },
  ];
  completed.forEach((t) => {
    const a = Number(t.amount || 0);
    if (a < 25) buckets[0].value++;
    else if (a < 50) buckets[1].value++;
    else if (a < 100) buckets[2].value++;
    else buckets[3].value++;
  });

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-xl font-medium tracking-tight text-ink">Analytics</h2>
        <p className="body-muted mt-1">How your jar is filling.</p>
      </div>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label={delta === null ? "This month" : `This month (${delta >= 0 ? "+" : ""}${delta}% vs last)`} value={`R${money(thisMonth)}`} icon={Calendar} accent="#12A25C" />
        <StatCard label="Last month" value={`R${money(lastMonth)}`} icon={Calendar} accent="#2563EB" />
        <StatCard label="Average tip" value={`R${money(avg)}`} icon={HandCoins} accent="#E0A536" />
        <StatCard label="Biggest tip" value={`R${money(biggest)}`} icon={Trophy} accent="#EC4899" />
      </div>

      {/* Cumulative earnings line */}
      <div className="card !p-5">
        <div className="flex items-baseline justify-between">
          <p className="text-xs font-semibold uppercase tracking-wide text-muted">Cumulative earnings · last 30 days (net)</p>
          <p className="text-sm font-bold text-teal">R{money(cumulative[cumulative.length - 1] ?? 0)}</p>
        </div>
        <div className="mt-4">
          {!days ? <p className="body-muted">Loading…</p> : <LineChart points={cumulative} color="#12A25C" />}
        </div>
        <div className="mt-1 flex justify-between font-mono text-[10px] text-muted">
          <span>{series[0].day.slice(5)}</span>
          <span>today</span>
        </div>
      </div>

      {/* Daily volume bars */}
      <div className="card !p-5">
        <div className="flex items-baseline justify-between">
          <p className="text-xs font-semibold uppercase tracking-wide text-muted">Daily tip volume · last 30 days</p>
          <p className="text-sm font-bold text-ink">R{money(total30)}</p>
        </div>
        {!days ? (
          <p className="body-muted mt-4">Loading…</p>
        ) : (
          <>
            <div className="mt-4 flex h-28 items-end gap-[3px]">
              {series.map((x) => (
                <div
                  key={x.day}
                  className="flex-1 rounded-t bg-teal/70 transition hover:bg-teal"
                  style={{ height: `${Math.max(3, (x.gross / max) * 100)}%` }}
                  title={`${x.day}: R${money(x.gross)} (${x.count} tip${x.count === 1 ? "" : "s"})`}
                />
              ))}
            </div>
            <div className="mt-2 flex justify-between font-mono text-[10px] text-muted">
              <span>{series[0].day.slice(5)}</span>
              <span>{series[series.length - 1].day.slice(5)}</span>
            </div>
          </>
        )}
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* Weekday performance */}
        <div className="card !p-5">
          <p className="text-xs font-semibold uppercase tracking-wide text-muted">Best days of the week (all time)</p>
          <div className="mt-4 flex h-28 items-end gap-2">
            {byDay.map((v, i) => (
              <div key={weekdays[i]} className="flex flex-1 flex-col items-center gap-1.5">
                <div
                  className="w-full rounded-t bg-primary/80 transition hover:bg-primary"
                  style={{ height: `${Math.max(4, (v / maxDay) * 88)}px` }}
                  title={`${weekdays[i]}: R${money(v)}`}
                />
                <span className="font-mono text-[10px] text-muted">{weekdays[i]}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Tip size distribution */}
        <div className="card !p-5">
          <p className="text-xs font-semibold uppercase tracking-wide text-muted">Tip size mix (count, all time)</p>
          <div className="mt-4">
            {completed.length === 0 ? (
              <p className="body-muted">No completed tips yet.</p>
            ) : (
              <Donut slices={buckets} />
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── Profile ─────────────────────────────────────────────────────────────────
async function compressImage(file: File, maxSide: number, quality = 0.82): Promise<string> {
  return new Promise((res, rej) => {
    const img = new Image();
    const fr = new FileReader();
    fr.onload = () => {
      img.onload = () => {
        const k = Math.min(1, maxSide / Math.max(img.width, img.height));
        const c = document.createElement("canvas");
        c.width = Math.round(img.width * k);
        c.height = Math.round(img.height * k);
        c.getContext("2d")!.drawImage(img, 0, 0, c.width, c.height);
        res(c.toDataURL("image/jpeg", quality));
      };
      img.onerror = rej;
      img.src = fr.result as string;
    };
    fr.onerror = rej;
    fr.readAsDataURL(file);
  });
}

function ProfileTab({
  token,
  creator,
  onSaved,
}: {
  token: string | null;
  creator: Creator | null;
  onSaved: (c: Creator) => void;
}) {
  const [displayName, setDisplayName] = useState(creator?.display_name ?? "");
  const [tagline, setTagline] = useState(creator?.tagline ?? "");
  const [category, setCategory] = useState(creator?.category ?? "");
  const [goal, setGoal] = useState(creator?.tip_goal ? String(Number(creator.tip_goal)) : "");
  const [avatar, setAvatar] = useState<string | null>(null); // pending data URL
  const [cover, setCover] = useState<string | null>(null);
  const [presets, setPresets] = useState<string>(() => {
    try {
      const p = creator?.tip_presets ? JSON.parse(creator.tip_presets) : null;
      return Array.isArray(p) ? p.join(", ") : "";
    } catch { return ""; }
  });
  const [thanksNote, setThanksNote] = useState(creator?.thanks_note ?? "");
  const [links, setLinks] = useState<Record<string, string>>(() => {
    try { return creator?.links ? JSON.parse(creator.links) : {}; } catch { return {}; }
  });
  const [bank, setBank] = useState<Record<string, string>>({});
  const [theme, setTheme] = useState(creator?.theme ?? "");
  useEffect(() => {
    if (token) api.myBankDetails(token).then((b) => setBank(b as Record<string, string>)).catch(() => null);
  }, [token]);
  const [busy, setBusy] = useState(false);
  const [note, setNote] = useState<string | null>(null);
  const avatarRef = useRef<HTMLInputElement>(null);
  const coverRef = useRef<HTMLInputElement>(null);

  if (!creator) {
    return (
      <EmptyState icon={UserRound} title="No creator page yet" body="Set up your creator page first — then manage it here." />
    );
  }

  const avatarPreview = avatar ?? creator.avatar_url;
  const coverPreview = cover ?? creator.cover_url;

  async function save() {
    if (!token) return;
    setBusy(true);
    setNote(null);
    try {
      const presetNums = presets
        .split(/[\s,;]+/)
        .map((v) => Number(v))
        .filter((n) => n >= 10 && n <= 100000)
        .slice(0, 6);
      const updated = await api.updateMyCreatorProfile(token, {
        display_name: displayName.trim() || undefined,
        tagline,
        category,
        tip_goal: goal.trim() ? Number(goal) : undefined,
        avatar_url: avatar ?? undefined,
        cover_url: cover ?? undefined,
        tip_presets: presetNums.length >= 2 ? presetNums : [],
        thanks_note: thanksNote,
        links,
        bank_details: bank,
        theme,
      });
      onSaved(updated);
      setAvatar(null);
      setCover(null);
      setNote("Profile saved — your public page is updated.");
    } catch (e) {
      setNote(e instanceof Error ? e.message : "Could not save your profile.");
    } finally {
      setBusy(false);
    }
  }

  const inputCls =
    "w-full rounded-xl border border-border bg-white px-4 py-2.5 text-sm text-ink focus:border-primary/40 focus:outline-none";

  return (
    <div className="max-w-2xl space-y-6">
      <div>
        <h2 className="text-xl font-medium tracking-tight text-ink">Your public profile</h2>
        <p className="body-muted mt-1">What fans see on tippingjar.co.za/creator/{creator.slug}</p>
      </div>

      {/* Cover + avatar */}
      <div className="card overflow-hidden !p-0">
        <button
          onClick={() => coverRef.current?.click()}
          className="relative block h-36 w-full bg-navy transition hover:opacity-90"
          title="Change cover photo"
        >
          {coverPreview ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={coverPreview} alt="" className="h-full w-full object-cover" />
          ) : (
            <span className="absolute inset-0 grid place-items-center text-sm text-white/70">
              Click to add a cover photo
            </span>
          )}
        </button>
        <div className="flex items-end gap-4 px-6 pb-5">
          <button
            onClick={() => avatarRef.current?.click()}
            className="-mt-10 h-20 w-20 shrink-0 overflow-hidden rounded-3xl bg-white ring-4 ring-white transition hover:opacity-90"
            title="Change avatar"
          >
            {avatarPreview ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={avatarPreview} alt="" className="h-full w-full object-cover" />
            ) : (
              <span className="grid h-full w-full place-items-center bg-primary text-xl font-bold text-white">
                {(creator.display_name || "T").charAt(0)}
              </span>
            )}
          </button>
          <p className="pb-1 text-xs text-muted">Click the cover or avatar to change it. Images are compressed automatically.</p>
        </div>
        <input ref={avatarRef} type="file" accept="image/*" className="hidden"
          onChange={async (e) => { const fl = e.target.files?.[0]; if (fl) setAvatar(await compressImage(fl, 500)); e.target.value = ""; }} />
        <input ref={coverRef} type="file" accept="image/*" className="hidden"
          onChange={async (e) => { const fl = e.target.files?.[0]; if (fl) setCover(await compressImage(fl, 1400)); e.target.value = ""; }} />
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <label className="block text-xs font-medium text-muted">
          Display name
          <input value={displayName} onChange={(e) => setDisplayName(e.target.value)} className={`${inputCls} mt-1.5`} />
        </label>
        <label className="block text-xs font-medium text-muted">
          Category
          <select value={category} onChange={(e) => setCategory(e.target.value)} className={`${inputCls} mt-1.5`}>
            {["", "Music", "Art", "Writing", "Streaming", "Podcasts", "Photography", "Comedy", "Food", "Fitness", "Education"].map((c) => (
              <option key={c} value={c}>{c || "— none —"}</option>
            ))}
          </select>
        </label>
      </div>
      <label className="block text-xs font-medium text-muted">
        Tagline
        <input value={tagline} onChange={(e) => setTagline(e.target.value)} maxLength={140} placeholder="One line about what you make" className={`${inputCls} mt-1.5`} />
      </label>
      <label className="block text-xs font-medium text-muted">
        Monthly tip goal (R) — powers the jar on your page
        <input value={goal} onChange={(e) => setGoal(e.target.value.replace(/[^0-9.]/g, ""))} inputMode="decimal" placeholder="e.g. 3000" className={`${inputCls} mt-1.5 max-w-[200px]`} />
      </label>

      <div className="space-y-4">
        <div>
          <p className="text-sm font-medium text-ink">Tip page</p>
          <div className="mt-2 grid gap-4 sm:grid-cols-2">
            <label className="block text-xs font-medium text-muted">
              Preset amounts (2–6, comma separated)
              <input value={presets} onChange={(e) => setPresets(e.target.value.replace(/[^0-9,.\s]/g, ""))} placeholder="20, 50, 100, 250 (min R10 each)" className={`${inputCls} mt-1.5`} />
            </label>
            <label className="block text-xs font-medium text-muted">
              Thank-you note (shown after a fan pays)
              <input value={thanksNote} onChange={(e) => setThanksNote(e.target.value.slice(0, 300))} placeholder="You're amazing — this keeps the lights on! 💚" className={`${inputCls} mt-1.5`} />
            </label>
          </div>
        </div>

        <div>
          <p className="text-sm font-medium text-ink">Social links</p>
          <div className="mt-2 grid gap-4 sm:grid-cols-2">
            {(["instagram", "twitter", "youtube", "website"] as const).map((k) => (
              <label key={k} className="block text-xs font-medium capitalize text-muted">
                {k === "twitter" ? "X / Twitter" : k}
                <input
                  value={links[k] ?? ""}
                  onChange={(e) => setLinks((l) => ({ ...l, [k]: e.target.value }))}
                  placeholder={k === "website" ? "https://…" : "@handle"}
                  className={`${inputCls} mt-1.5`}
                />
              </label>
            ))}
          </div>
        </div>

        <div>
          <p className="text-sm font-medium text-ink">Page accent colour</p>
          <div className="mt-2 flex flex-wrap items-center gap-2">
            {["", "#12A25C", "#7C3AED", "#E0A536", "#EC4899", "#2563EB", "#DC2626", "#0F766E"].map((c) => (
              <button
                key={c || "default"}
                onClick={() => setTheme(c)}
                className={`h-8 w-8 rounded-full border-2 transition ${theme === c ? "border-ink scale-110" : "border-border"}`}
                style={{ background: c || "#0F2439" }}
                title={c || "Default"}
              />
            ))}
          </div>
        </div>

        <div>
          <p className="text-sm font-medium text-ink">Payout bank account</p>
          <p className="text-xs text-muted">Used by the team when settling your payout requests. Never shown publicly.</p>
          <div className="mt-2 grid gap-4 sm:grid-cols-3">
            {([["bank", "Bank"], ["account_name", "Account holder"], ["account_no", "Account number"]] as const).map(([k, label]) => (
              <label key={k} className="block text-xs font-medium text-muted">
                {label}
                <input
                  value={bank[k] ?? ""}
                  onChange={(e) => setBank((b) => ({ ...b, [k]: e.target.value }))}
                  className={`${inputCls} mt-1.5`}
                />
              </label>
            ))}
          </div>
        </div>
      </div>

      <div className="flex items-center gap-3">
        <button onClick={save} disabled={busy} className="btn-primary !px-6 !py-2.5 text-sm disabled:opacity-50">
          {busy ? "Saving…" : "Save profile"}
        </button>
        <Link href={`/creator/${creator.slug}`} className="text-sm text-muted hover:text-ink">
          View public page <ArrowUpRight className="inline h-3.5 w-3.5" strokeWidth={2.4} />
        </Link>
        {note && <p className="text-sm text-teal">{note}</p>}
      </div>
    </div>
  );
}


// ─── Exclusive posts ─────────────────────────────────────────────────────────
function ExclusiveTab({ token, hasProfile }: { token: string | null; hasProfile: boolean }) {
  const [posts, setPosts] = useState<ExclusivePost[] | null>(null);
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [image, setImage] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [note, setNote] = useState<string | null>(null);
  const imgRef = useRef<HTMLInputElement>(null);

  const load = useCallback(() => {
    if (!token) return;
    api.myPosts(token).then(setPosts).catch(() => setPosts([]));
  }, [token]);
  useEffect(load, [load]);

  if (!hasProfile) {
    return <EmptyState icon={Lock} title="No creator page yet" body="Set up your creator page first — then post exclusive content." />;
  }

  async function publish() {
    if (!token || !title.trim()) return;
    setBusy(true);
    setNote(null);
    try {
      await api.createPost(token, { title: title.trim(), body: body.trim() || undefined, image_url: image ?? undefined });
      setTitle("");
      setBody("");
      setImage(null);
      setNote("Published — supporters who tipped this month can see it now.");
      load();
    } catch (e) {
      setNote(e instanceof Error ? e.message : "Could not publish.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="max-w-3xl space-y-6">
      <div>
        <h2 className="text-xl font-medium tracking-tight text-ink">Exclusive content</h2>
        <p className="body-muted mt-1">
          Only fans who tipped you <span className="font-medium text-ink">this month</span> (R10+, with their email)
          can unlock these on your page. A fresh reason to tip, every month.
        </p>
      </div>

      <div className="card space-y-3 !p-5">
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Post title — e.g. Unreleased demo: 'Midnight'"
          className="w-full rounded-xl border border-border bg-white px-4 py-2.5 text-sm text-ink focus:border-primary/40 focus:outline-none"
        />
        <textarea
          value={body}
          onChange={(e) => setBody(e.target.value)}
          rows={5}
          placeholder="The content — behind-the-scenes notes, download links, early access codes…"
          className="w-full rounded-xl border border-border bg-white px-4 py-2.5 text-sm text-ink focus:border-primary/40 focus:outline-none"
        />
        <div className="flex flex-wrap items-center gap-3">
          <button onClick={() => imgRef.current?.click()} className="btn-ghost !px-4 !py-2 text-xs">
            {image ? "Change image" : "Add image"}
          </button>
          {image && (
            <>
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={image} alt="" className="h-10 w-10 rounded-lg object-cover" />
              <button onClick={() => setImage(null)} className="text-xs text-muted hover:text-red-500">remove</button>
            </>
          )}
          <button onClick={publish} disabled={busy || !title.trim()} className="btn-primary ml-auto !px-6 !py-2.5 text-sm disabled:opacity-50">
            {busy ? "Publishing…" : "Publish"}
          </button>
        </div>
        {note && <p className="text-sm text-teal">{note}</p>}
        <input ref={imgRef} type="file" accept="image/*" className="hidden"
          onChange={async (e) => { const fl = e.target.files?.[0]; if (fl) setImage(await compressImage(fl, 1200)); e.target.value = ""; }} />
      </div>

      {!posts ? (
        <p className="body-muted">Loading…</p>
      ) : posts.length === 0 ? (
        <EmptyState icon={Lock} title="Nothing in the vault yet" body="Publish your first exclusive post above." />
      ) : (
        <div className="space-y-3">
          {posts.map((p) => (
            <div key={p.id} className="card flex items-start gap-4 !p-5">
              {p.image_url && (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={p.image_url} alt="" className="h-16 w-16 shrink-0 rounded-xl object-cover" />
              )}
              <div className="min-w-0 flex-1">
                <p className="font-medium text-ink">{p.title}</p>
                {p.body && <p className="body-muted mt-1 line-clamp-2 text-sm">{p.body}</p>}
                <p className="mt-1.5 font-mono text-[11px] text-muted">
                  {new Date(p.created_at).toLocaleDateString("en-ZA", { day: "numeric", month: "short" })}
                </p>
              </div>
              <button
                onClick={async () => {
                  if (!token || !window.confirm(`Delete "${p.title}"?`)) return;
                  await api.deletePost(token, p.id).catch(() => null);
                  load();
                }}
                className="shrink-0 text-muted transition hover:text-red-500"
                title="Delete post"
              >
                <X className="h-4 w-4" strokeWidth={2.2} />
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}


// ─── Jars (campaign funds) ───────────────────────────────────────────────────
function JarsTab({ token, creator }: { token: string | null; creator: Creator | null }) {
  const [jars, setJars] = useState<Jar[] | null>(null);
  const [stats, setStats] = useState<Map<string, number>>(new Map());
  const [name, setName] = useState("");
  const [goal, setGoal] = useState("");
  const [desc, setDesc] = useState("");
  const [busy, setBusy] = useState(false);
  const [note, setNote] = useState<string | null>(null);

  const load = useCallback(() => {
    if (!creator) return;
    api.getJars(creator.slug).then(async (js) => {
      setJars(js);
      const m = new Map<string, number>();
      await Promise.all(
        js.map(async (j) => {
          try { m.set(j.id, Number((await api.jarStats(j.id)).raised) || 0); } catch { m.set(j.id, 0); }
        }),
      );
      setStats(new Map(m));
    }).catch(() => setJars([]));
  }, [creator]);
  useEffect(load, [load]);

  if (!creator) {
    return <EmptyState icon={Milk} title="No creator page yet" body="Set up your creator page first — then create campaign jars." />;
  }

  async function create() {
    if (!token || !name.trim()) return;
    setBusy(true);
    setNote(null);
    try {
      await api.createJar(token, creator!.slug, {
        name: name.trim(),
        description: desc.trim() || undefined,
        goal: goal.trim() ? Number(goal) : undefined,
      });
      setName(""); setGoal(""); setDesc("");
      setNote("Jar created — share its link below.");
      load();
    } catch (e) {
      setNote(e instanceof Error ? e.message : "Could not create the jar.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="max-w-3xl space-y-6">
      <div>
        <h2 className="text-xl font-medium tracking-tight text-ink">Campaign jars</h2>
        <p className="body-muted mt-1">
          Fund something specific — &ldquo;New microphone&rdquo;, &ldquo;Studio day&rdquo; — each jar has its own
          goal, progress bar and shareable tip link.
        </p>
      </div>

      <div className="card space-y-3 !p-5">
        <div className="grid gap-3 sm:grid-cols-[1fr_140px]">
          <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Jar name — e.g. New microphone"
            className="w-full rounded-xl border border-border bg-white px-4 py-2.5 text-sm text-ink focus:border-primary/40 focus:outline-none" />
          <input value={goal} onChange={(e) => setGoal(e.target.value.replace(/[^0-9.]/g, ""))} inputMode="decimal" placeholder="Goal (R)"
            className="w-full rounded-xl border border-border bg-white px-4 py-2.5 text-sm text-ink focus:border-primary/40 focus:outline-none" />
        </div>
        <input value={desc} onChange={(e) => setDesc(e.target.value)} placeholder="What's it for? (optional)"
          className="w-full rounded-xl border border-border bg-white px-4 py-2.5 text-sm text-ink focus:border-primary/40 focus:outline-none" />
        <div className="flex items-center gap-3">
          <button onClick={create} disabled={busy || !name.trim()} className="btn-primary !px-6 !py-2.5 text-sm disabled:opacity-50">
            {busy ? "Creating…" : "Create jar"}
          </button>
          {note && <p className="text-sm text-teal">{note}</p>}
        </div>
      </div>

      {!jars ? (
        <p className="body-muted">Loading…</p>
      ) : jars.length === 0 ? (
        <EmptyState icon={Milk} title="No jars yet" body="Create your first campaign jar above." />
      ) : (
        <div className="space-y-3">
          {jars.map((j) => {
            const raised = stats.get(j.id) ?? 0;
            const g = j.goal ? Number(j.goal) : 0;
            const link = `https://www.tippingjar.co.za/tip/${creator.slug}?jar=${j.slug}`;
            return (
              <div key={j.id} className="card !p-5">
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div className="min-w-0">
                    <p className="font-medium text-ink">🫙 {j.name}</p>
                    {j.description && <p className="body-muted mt-0.5 text-sm">{j.description}</p>}
                  </div>
                  <div className="flex shrink-0 items-center gap-2">
                    <button
                      onClick={() => { navigator.clipboard?.writeText(link); }}
                      className="rounded-full border border-border px-3 py-1.5 text-xs font-medium text-muted hover:border-teal hover:text-teal"
                      title={link}
                    >
                      Copy tip link
                    </button>
                    <button
                      onClick={async () => {
                        if (!token || !window.confirm(`Delete jar "${j.name}"?`)) return;
                        await api.deleteJar(token, j.id).catch(() => null);
                        load();
                      }}
                      className="rounded-full border border-red-200 px-3 py-1.5 text-xs font-medium text-red-500 hover:bg-red-50"
                    >
                      Delete
                    </button>
                  </div>
                </div>
                <div className="mt-3 flex items-center justify-between font-mono text-xs text-muted">
                  <span>R{raised.toLocaleString("en-ZA")} raised</span>
                  {g > 0 && <span>goal R{g.toLocaleString("en-ZA")} · {Math.min(100, Math.round((raised / g) * 100))}%</span>}
                </div>
                {g > 0 && (
                  <div className="mt-1.5 h-2 overflow-hidden rounded-full bg-border">
                    <div className="h-full rounded-full bg-teal" style={{ width: `${Math.min(100, (raised / g) * 100)}%` }} />
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
