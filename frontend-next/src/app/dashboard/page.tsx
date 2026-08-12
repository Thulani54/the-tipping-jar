"use client";

// Creator dashboard — a full-bleed app shell with its own collapsible sidebar.
// The marketing top-nav + footer are hidden for /dashboard (see SiteFrame), so
// this owns the whole viewport. Tabs render in the content area on the right.

import React, { useCallback, useEffect, useState, useRef } from "react";
import { useRouter, useSearchParams, usePathname } from "next/navigation";
import { Suspense } from "react";
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
  MapPin,
  Building2,
  ShieldCheck,
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
  Subscriber,
  Supporter,
  SupportTier,
  Tip,
  ReferralCode,
  Creator,
  CreatorStats,
  Transaction,
  Payout,
  Balance,
  StudioDesign,
} from "@/types";

type Tab = "overview" | "tips" | "supporters" | "subscribers" | "analytics" | "exclusive" | "jars" | "transactions" | "referrals" | "studio" | "profile";

const TABS: { id: Tab; label: string; icon: LucideIcon }[] = [
  { id: "overview", label: "Overview", icon: LayoutDashboard },
  { id: "tips", label: "Tips", icon: HandCoins },
  { id: "supporters", label: "Supporters", icon: Trophy },
  { id: "subscribers", label: "Subscribers", icon: Users },
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
  // Suspense boundary is required because DashboardInner uses useSearchParams
  // to sync the active tab with the URL (?tab=…).
  return (
    <Suspense fallback={<div className="grid min-h-screen place-items-center bg-darker text-muted">Loading…</div>}>
      <DashboardInner />
    </Suspense>
  );
}

function DashboardInner() {
  const { user, token, isAuthenticated, initialized, logout } = useAuth();
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const TAB_IDS: Tab[] = ["overview", "tips", "supporters", "subscribers", "analytics", "exclusive", "jars", "transactions", "referrals", "studio", "profile"];
  const urlTab = searchParams.get("tab");
  const initialTab: Tab = TAB_IDS.includes(urlTab as Tab) ? (urlTab as Tab) : "overview";
  const [tab, setTabState] = useState<Tab>(initialTab);

  // Two-way sync: when the URL param changes (browser back/forward, external
  // link, etc.) we follow it; when the user clicks a nav row we push the URL
  // via setTab below.
  useEffect(() => {
    const t = searchParams.get("tab");
    if (t && TAB_IDS.includes(t as Tab) && t !== tab) {
      setTabState(t as Tab);
    } else if (!t && tab !== "overview") {
      setTabState("overview");
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchParams]);

  const setTab = (next: Tab) => {
    setTabState(next);
    const params = new URLSearchParams(searchParams.toString());
    if (next === "overview") params.delete("tab");
    else params.set("tab", next);
    const qs = params.toString();
    router.replace(qs ? `${pathname}?${qs}` : pathname, { scroll: false });
  };
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
            {tab === "subscribers" && <SubscribersTab token={token} slug={myCreator?.slug ?? null} />}
            {tab === "analytics" && (
              <AnalyticsTab token={token} creatorId={myCreator?.id ?? null} tips={tips} />
            )}
            {tab === "exclusive" && (
              <ExclusiveTab token={token} hasProfile={!!myCreator} slug={myCreator?.slug ?? null} />
            )}
            {tab === "jars" && <JarsTab token={token} creator={myCreator} />}
            {tab === "transactions" && (
              <TransactionsTab token={token} creatorId={myCreator?.id ?? null} />
            )}
            {tab === "referrals" && (
              <ReferralsTab referral={referral} token={token} creatorId={myCreator?.id ?? null} />
            )}
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
  downloadCsv(
    `tipping-jar-tips-${new Date().toISOString().slice(0, 10)}.csv`,
    ["date", "tipper", "email", "message", "amount", "platform_fee", "service_fee", "net", "status", "reference"],
    tips.map((t) => [
      new Date(t.created_at).toISOString(), t.tipper_name, t.tipper_email, t.message,
      t.amount, t.platform_fee, t.service_fee, t.creator_net, t.status, t.reference,
    ]),
  );
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
  downloadCsv(
    `supporters-${new Date().toISOString().slice(0, 10)}.csv`,
    ["name", "email", "tips", "total", "last_tip"],
    rows.map((r) => [r.name, r.email, r.tip_count, r.total, r.last_tip_at]),
  );
}

// Classify a supporter into a segment for at-a-glance CRM.
function segmentOf(r: Supporter): "champion" | "recurring" | "new" | "dormant" | "one-off" {
  const daysSince = Math.floor((Date.now() - new Date(r.last_tip_at).getTime()) / 86400000);
  const total = Number(r.total) || 0;
  if (total >= 500 || r.tip_count >= 5) return "champion";
  if (r.tip_count >= 2 && daysSince <= 60) return "recurring";
  if (daysSince <= 14) return "new";
  if (daysSince > 90) return "dormant";
  return "one-off";
}
const SEGMENT_META: Record<string, { label: string; cls: string; emoji: string }> = {
  champion: { label: "Champion",  cls: "bg-gold/15 text-ink border-gold/40",     emoji: "🏆" },
  recurring:{ label: "Recurring", cls: "bg-teal/15 text-teal border-teal/40",    emoji: "💚" },
  new:      { label: "New",       cls: "bg-mint/15 text-green border-mint/40",   emoji: "✨" },
  dormant:  { label: "Dormant",   cls: "bg-border/50 text-muted border-border",  emoji: "😴" },
  "one-off":{ label: "One-off",   cls: "bg-white text-muted border-border",      emoji: "•"  },
};

function SupportersTab({ token, creatorId }: { token: string | null; creatorId: string | null }) {
  const [rows, setRows] = useState<Supporter[] | null>(null);
  const [err, setErr] = useState(false);
  const [composing, setComposing] = useState(false);
  const [subject, setSubject] = useState("");
  const [body, setBody] = useState("");
  const [sending, setSending] = useState(false);
  const [sendNote, setSendNote] = useState<string | null>(null);
  const [q, setQ] = useState("");
  const [sort, setSort] = useState<"lifetime" | "recent" | "count">("lifetime");
  const [segment, setSegment] = useState<"all" | "champion" | "recurring" | "new" | "dormant">("all");

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

  // Segment counts (before filtering, so the chips always show real numbers)
  const counts: Record<string, number> = { all: rows.length, champion: 0, recurring: 0, new: 0, dormant: 0 };
  const bySegment = new Map<string, string>();
  rows.forEach((r) => {
    const s = segmentOf(r);
    bySegment.set(r.name + "|" + r.email, s);
    if (counts[s] !== undefined) counts[s]++;
  });

  // Filter + sort
  const filtered = rows.filter((r) => {
    if (segment !== "all" && segmentOf(r) !== segment) return false;
    if (q) {
      const needle = q.toLowerCase();
      if (!r.name.toLowerCase().includes(needle) && !(r.email || "").toLowerCase().includes(needle)) return false;
    }
    return true;
  });
  const sorted = [...filtered].sort((a, b) => {
    if (sort === "recent") return +new Date(b.last_tip_at) - +new Date(a.last_tip_at);
    if (sort === "count") return b.tip_count - a.tip_count;
    return Number(b.total) - Number(a.total);
  });

  const now = Date.now();
  const first = new Date(rows[rows.length - 1].last_tip_at).getTime();
  const daysSinceOldest = Math.max(1, Math.floor((now - first) / 86400000));
  const avgSupport = total / rows.length;
  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h2 className="text-xl font-medium tracking-tight text-ink">Your supporters</h2>
          <p className="body-muted mt-1">
            {rows.length} people · R{money(total)} lifetime · {withEmail} reachable by email
          </p>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => exportTipsCsvSupporters(rows)}
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
      </div>

      {/* KPI cards */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Supporters" value={String(rows.length)} icon={Users} accent="#12A25C" />
        <StatCard label="Lifetime volume" value={`R${money(total)}`} icon={Banknote} accent="#2563EB" />
        <StatCard label="Average per supporter" value={`R${money(avgSupport)}`} icon={Percent} accent="#E0A536" />
        <StatCard label="Reachable by email" value={`${withEmail} · ${Math.round((withEmail / rows.length) * 100)}%`} icon={Send} accent="#EC4899" />
      </div>

      {/* Segment chips (labels + counts) */}
      <div className="flex flex-wrap gap-2">
        {(["all", "champion", "recurring", "new", "dormant"] as const).map((s) => (
          <button
            key={s}
            onClick={() => setSegment(s)}
            className={`rounded-full px-3.5 py-1.5 text-xs font-medium transition ${
              segment === s ? "bg-primary text-white" : "border border-border text-muted hover:text-ink"
            }`}
          >
            {s === "all" ? "All" : SEGMENT_META[s].label} · {counts[s]}
          </button>
        ))}
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
      {/* Filter toolbar */}
      <div className="card flex flex-wrap items-center gap-3 !p-4">
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Search name or email…"
          className="w-full max-w-xs rounded-full border border-border bg-white px-4 py-2 text-sm text-ink focus:border-primary/40 focus:outline-none"
        />
        <span className="text-xs font-medium text-muted">Sort by</span>
        <div className="flex gap-1.5">
          {([
            ["lifetime", "Lifetime"],
            ["recent", "Recent"],
            ["count", "Tips"],
          ] as const).map(([id, label]) => (
            <button
              key={id}
              onClick={() => setSort(id)}
              className={`rounded-full px-3 py-1.5 text-xs font-medium transition ${
                sort === id ? "bg-primary text-white" : "border border-border text-muted hover:text-ink"
              }`}
            >
              {label}
            </button>
          ))}
        </div>
        <span className="ml-auto text-xs text-muted">
          Showing {sorted.length} of {rows.length}
          {" · "}avg supporter has been giving for ~{Math.round(daysSinceOldest / Math.max(1, rows.length))}d
        </span>
      </div>

      {sorted.length === 0 ? (
        <EmptyState icon={Trophy} title="No supporters match those filters" body="Try widening the segment or clearing the search." />
      ) : (
      <div className="card overflow-hidden !p-0">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[720px] text-left text-sm">
            <thead className="border-b border-border text-xs uppercase tracking-wide text-muted">
              <tr>
                <th className="px-5 py-3 font-medium">#</th>
                <th className="px-5 py-3 font-medium">Supporter</th>
                <th className="px-5 py-3 font-medium">Segment</th>
                <th className="px-5 py-3 font-medium">Tips</th>
                <th className="px-5 py-3 font-medium">Last tip</th>
                <th className="px-5 py-3 text-right font-medium">Lifetime</th>
                <th className="px-5 py-3 text-right font-medium">Act</th>
              </tr>
            </thead>
            <tbody>
              {sorted.map((r, i) => {
                const seg = bySegment.get(r.name + "|" + r.email) ?? "one-off";
                const meta = SEGMENT_META[seg];
                const days = Math.floor((now - new Date(r.last_tip_at).getTime()) / 86400000);
                const initial = (r.name || "?").charAt(0).toUpperCase();
                return (
                <tr key={`${r.name}-${i}`} className="border-b border-border/60 last:border-0 hover:bg-ink/[0.02]">
                  <td className="px-5 py-3 text-lg">
                    {sort === "lifetime" && i < 3 ? medals[i] : <span className="text-xs text-muted">{i + 1}</span>}
                  </td>
                  <td className="px-5 py-3">
                    <div className="flex items-center gap-3">
                      <span
                        className="grid h-9 w-9 shrink-0 place-items-center rounded-full text-xs font-bold text-white"
                        style={{ background: seg === "champion" ? "#E0A536" : seg === "recurring" ? "#12A25C" : "#0F2439" }}
                      >
                        {initial}
                      </span>
                      <div className="min-w-0">
                        <p className="truncate font-medium text-ink">{r.name || "Anonymous"}</p>
                        {r.email && <p className="truncate text-[11px] text-muted">{r.email}</p>}
                      </div>
                    </div>
                  </td>
                  <td className="px-5 py-3">
                    <span className={`inline-flex items-center gap-1 rounded-full border px-2.5 py-0.5 text-[11px] font-medium ${meta.cls}`}>
                      <span>{meta.emoji}</span> {meta.label}
                    </span>
                  </td>
                  <td className="px-5 py-3 text-muted">{r.tip_count}</td>
                  <td className="px-5 py-3 text-muted">
                    {new Date(r.last_tip_at).toLocaleDateString("en-ZA", { day: "numeric", month: "short" })}
                    <span className="ml-1 text-[11px] text-muted/70">
                      · {days === 0 ? "today" : `${days}d ago`}
                    </span>
                  </td>
                  <td className="px-5 py-3 text-right font-bold text-teal">R{money(Number(r.total) || 0)}</td>
                  <td className="px-5 py-3 text-right">
                    {r.email ? (
                      <a
                        href={`mailto:${r.email}?subject=${encodeURIComponent("A quick thanks from your Tipping Jar creator")}&body=${encodeURIComponent(`Hi ${r.name?.split(" ")[0] || "there"},\n\nJust wanted to say thank you for supporting my work — it means the world.\n\n`)}`}
                        className="inline-flex items-center gap-1 rounded-full border border-border px-3 py-1 text-xs font-medium text-muted transition hover:border-teal hover:text-teal"
                        title="Compose an email"
                      >
                        <Send className="h-3 w-3" strokeWidth={2.4} /> Email
                      </a>
                    ) : (
                      <span className="text-[11px] text-muted/60">no email</span>
                    )}
                  </td>
                </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
      )}
    </div>
  );
}

// ─── Referrals ───────────────────────────────────────────────────────────────
async function downloadReferralPoster(code: string, link: string) {
  const QRCode = (await import("qrcode")).default;
  const qr = await QRCode.toDataURL(link, { width: 480, margin: 1, color: { dark: "#0F2439", light: "#FFFFFF" } });
  const W = 720, H = 960;
  const c = document.createElement("canvas");
  c.width = W; c.height = H;
  const ctx = c.getContext("2d")!;
  const g = ctx.createLinearGradient(0, 0, W, H);
  g.addColorStop(0, "#0F2439"); g.addColorStop(1, "#12A25C");
  ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  ctx.fillStyle = "#FFFFFF";
  ctx.textAlign = "center";
  ctx.font = "500 22px Manrope, system-ui, sans-serif";
  ctx.fillText("Join me on", W / 2, 90);
  ctx.font = "bold 56px Manrope, system-ui, sans-serif";
  ctx.fillStyle = "#57CE8B";
  ctx.fillText("🫙 Tipping Jar", W / 2, 156);
  ctx.font = "500 22px 'Space Mono', monospace";
  ctx.fillStyle = "#FFFFFF";
  ctx.fillText(`Code: ${code}`, W / 2, 210);
  const qs = 460, qx = (W - qs) / 2, qy = 260;
  ctx.fillStyle = "#FFFFFF";
  ctx.beginPath();
  ctx.roundRect(qx - 24, qy - 24, qs + 48, qs + 48, 32);
  ctx.fill();
  const img = new Image();
  await new Promise<void>((res) => { img.onload = () => res(); img.src = qr; });
  ctx.drawImage(img, qx, qy, qs, qs);
  ctx.fillStyle = "#FFFFFF";
  ctx.font = "500 20px 'Space Mono', monospace";
  ctx.fillText(link.replace(/^https?:\/\//, ""), W / 2, qy + qs + 90);
  ctx.font = "400 18px Manrope, system-ui, sans-serif";
  ctx.fillStyle = "#DFF5E9";
  ctx.fillText("Scan or use my code at sign-up", W / 2, qy + qs + 130);
  const a = document.createElement("a");
  a.href = c.toDataURL("image/png");
  a.download = `tipping-jar-referral-${code}.png`;
  a.click();
}

function ReferralsTab({
  referral,
  token,
  creatorId,
}: {
  referral: ReferralCode | null;
  token: string | null;
  creatorId: string | null;
}) {
  const [copied, setCopied] = useState<string | null>(null);
  const [simAmount, setSimAmount] = useState(3000);
  const [simCreators, setSimCreators] = useState(3);
  const [commissionRows, setCommissionRows] = useState<Transaction[]>([]);
  const code = referral?.code ?? "";
  const rate = referral ? Number(referral.commission_rate) || 0.01 : 0.01;
  const shareUrl = code ? `https://tippingjar.co.za/register?ref=${code}` : "";

  // Pull the caller's own transactions ledger and pick out referral-commission
  // rows. Backend keys those with reference = `rc_<original_tip_ref>`, so a
  // prefix filter is enough. Errors here just leave the KPIs at zero.
  useEffect(() => {
    if (!token || !creatorId) return;
    api
      .creatorTransactions(token, creatorId)
      .then((rows) =>
        setCommissionRows(rows.filter((r) => (r.reference || "").startsWith("rc_"))),
      )
      .catch(() => setCommissionRows([]));
  }, [token, creatorId]);

  const totalEarned = commissionRows.reduce((s, r) => s + Number(r.amount || 0), 0);
  const monthAgo = Date.now() - 30 * 86400000;
  const earned30d = commissionRows
    .filter((r) => +new Date(r.created_at) >= monthAgo)
    .reduce((s, r) => s + Number(r.amount || 0), 0);
  const referralsCount = commissionRows.length;

  // Countdown from the code's creation. Codes earn commission on signups
  // within a 6-month rolling window from when THEY sign up, but the code
  // itself has no expiry — this timer shows time since it was minted.
  const codeAge = referral ? Math.floor((Date.now() - +new Date(referral.created_at)) / 86400000) : 0;

  const copy = (text: string, key: string) => {
    navigator.clipboard?.writeText(text);
    setCopied(key);
    setTimeout(() => setCopied(null), 2000);
  };

  // Channel-tagged share URL — helps you see where signups came from later.
  const channelUrl = (channel: string) => (shareUrl ? `${shareUrl}&s=${channel}` : "");

  // 6-month commission simulator
  const monthlyPerCreator = simAmount;
  const totalMonthlyGross = monthlyPerCreator * simCreators;
  const monthlyComm = totalMonthlyGross * rate;
  const sixMonthComm = monthlyComm * 6;

  const steps = [
    { icon: Link2,    title: "Share your code",  body: "Send your referral link to creators you know. They enter your code at signup." },
    { icon: Users,    title: "They sign up",     body: "When a creator registers with your code, a 6-month commission window starts." },
    { icon: Banknote, title: "Submit bank details", body: "You'll get an email — submit your bank account so we can pay your commission." },
    { icon: Gift,     title: `Earn ${(rate * 100).toFixed(1)}% of their tips`, body: "For every tip they receive in 6 months, you earn commission paid directly to your account." },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-xl font-medium tracking-tight text-ink">Referrals</h2>
        <p className="body-muted mt-1">
          Earn <span className="font-semibold text-ink">{(rate * 100).toFixed(1)}%</span> of every tip your referred creators receive — for 6 months.
        </p>
      </div>

      {/* KPI row */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Commission earned" value={`R${money(totalEarned)}`} icon={Banknote} accent="#12A25C" />
        <StatCard label="Last 30 days" value={`R${money(earned30d)}`} icon={Zap} accent="#E0A536" />
        <StatCard label="Commission events" value={String(referralsCount)} icon={Users} accent="#2563EB" />
        <StatCard label={code ? `Rate · ${(rate * 100).toFixed(1)}%` : "Rate"} value={code ? `${codeAge}d code` : "—"} icon={Percent} accent="#7C3AED" />
      </div>

      {/* Recent commissions — the real ledger, filtered from Transactions.
          This makes the money movement visible without leaving the tab. */}
      {commissionRows.length > 0 && (
        <div className="card !p-4">
          <div className="mb-3 flex items-center justify-between">
            <p className="text-xs font-semibold uppercase tracking-wide text-muted">Recent commissions</p>
            <Link href="/dashboard?tab=transactions" className="text-xs font-medium text-teal hover:underline">
              See all in Transactions →
            </Link>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="text-left text-[11px] font-mono uppercase tracking-wide text-muted">
                  <th className="pb-2">Date</th>
                  <th className="pb-2">Source</th>
                  <th className="pb-2 text-right">Earned</th>
                </tr>
              </thead>
              <tbody>
                {commissionRows.slice(0, 8).map((r) => (
                  <tr key={r.id} className="border-t border-border/60">
                    <td className="py-2 font-mono text-xs text-muted">{new Date(r.created_at).toLocaleDateString()}</td>
                    <td className="py-2 truncate text-ink">{r.tipper_name || r.description || "Referral commission"}</td>
                    <td className="py-2 text-right font-semibold text-green">+R{money(Number(r.amount || 0))}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Referral card + poster preview */}
      <div className="grid gap-6 lg:grid-cols-[1.4fr_1fr]">
        <div className="card !p-5">
          <p className="inline-flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wide text-muted">
            <Gift className="h-4 w-4" strokeWidth={2.2} /> Your referral code
          </p>
          {code ? (
            <>
              <div className="mt-3 flex items-center gap-3">
                <span className="rounded-xl border border-border bg-darker/40 px-4 py-3 font-mono text-2xl font-medium tracking-[0.3em] text-ink">{code}</span>
                <button
                  onClick={() => copy(code, "code")}
                  className={`rounded-full border px-3 py-1.5 text-xs font-medium transition ${copied === "code" ? "border-teal bg-teal text-white" : "border-border text-muted hover:border-teal hover:text-teal"}`}
                >
                  {copied === "code" ? <><Check className="inline h-3 w-3" strokeWidth={2.6} /> Copied</> : <><Copy className="inline h-3 w-3" strokeWidth={2.4} /> Copy</>}
                </button>
              </div>
              <p className="mt-3 break-all rounded-lg bg-darker/40 px-3 py-2 font-mono text-xs text-ink">{shareUrl}</p>
              <div className="mt-4 flex flex-wrap gap-2">
                <button
                  onClick={() => copy(shareUrl, "link")}
                  className={`inline-flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-medium transition ${copied === "link" ? "border-teal bg-teal text-white" : "border-border text-muted hover:border-teal hover:text-teal"}`}
                >
                  <Link2 className="h-3.5 w-3.5" strokeWidth={2.2} /> {copied === "link" ? "Link copied!" : "Copy link"}
                </button>
                <button
                  onClick={() => downloadReferralPoster(code, shareUrl)}
                  className="inline-flex items-center gap-1.5 rounded-full border border-border px-3 py-1.5 text-xs font-medium text-muted hover:border-teal hover:text-teal"
                >
                  <QrCode className="h-3.5 w-3.5" strokeWidth={2.2} /> QR poster
                </button>
                <button
                  onClick={async () => {
                    if (navigator.share) {
                      try {
                        await navigator.share({ title: "Tipping Jar", text: `Join TippingJar with my code ${code}`, url: shareUrl });
                      } catch { /* user cancelled */ }
                    } else {
                      copy(shareUrl, "share");
                    }
                  }}
                  className="inline-flex items-center gap-1.5 rounded-full border border-border px-3 py-1.5 text-xs font-medium text-muted hover:border-teal hover:text-teal"
                >
                  <Send className="h-3.5 w-3.5" strokeWidth={2.4} /> Share…
                </button>
                <a
                  href={`https://wa.me/?text=${encodeURIComponent(`Sign up on TippingJar with my code ${code}: ${channelUrl("wa")}`)}`}
                  target="_blank" rel="noreferrer"
                  className="inline-flex items-center gap-1.5 rounded-full border border-border px-3 py-1.5 text-xs font-medium text-muted hover:border-teal hover:text-teal"
                >
                  <i className="bi bi-whatsapp" /> WhatsApp
                </a>
                <a
                  href={`https://twitter.com/intent/tweet?text=${encodeURIComponent(`I'm earning on @TippingJar — join with my code ${code}! ${channelUrl("x")}`)}`}
                  target="_blank" rel="noreferrer"
                  className="inline-flex items-center gap-1.5 rounded-full border border-border px-3 py-1.5 text-xs font-medium text-muted hover:border-teal hover:text-teal"
                >
                  <i className="bi bi-twitter-x" /> X / Twitter
                </a>
                <a
                  href={`mailto:?subject=${encodeURIComponent("Join me on Tipping Jar")}&body=${encodeURIComponent(`Hey — thought you'd like this. It's a tipping platform for South African creators.\n\nSign up with my code ${code}: ${channelUrl("email")}`)}`}
                  className="inline-flex items-center gap-1.5 rounded-full border border-border px-3 py-1.5 text-xs font-medium text-muted hover:border-teal hover:text-teal"
                >
                  <i className="bi bi-envelope" /> Email
                </a>
              </div>
            </>
          ) : (
            <p className="body-muted mt-3">Loading your referral code…</p>
          )}
        </div>

        {/* Earnings simulator */}
        <div className="card !p-5">
          <p className="text-xs font-semibold uppercase tracking-wide text-muted">Commission simulator</p>
          <p className="body-muted mt-1 text-sm">See what your referrals could earn you over 6 months.</p>
          <div className="mt-4 space-y-4">
            <div>
              <label className="flex items-center justify-between text-xs text-muted">
                Creators you refer
                <span className="font-mono font-semibold text-ink">{simCreators}</span>
              </label>
              <input
                type="range" min={1} max={20} value={simCreators}
                onChange={(e) => setSimCreators(Number(e.target.value))}
                className="tip-range mt-2"
              />
            </div>
            <div>
              <label className="flex items-center justify-between text-xs text-muted">
                Their monthly tip volume
                <span className="font-mono font-semibold text-ink">R{money(simAmount)}</span>
              </label>
              <input
                type="range" min={100} max={20000} step={100} value={simAmount}
                onChange={(e) => setSimAmount(Number(e.target.value))}
                className="tip-range mt-2"
              />
            </div>
            <div className="rounded-xl border border-teal/30 bg-teal/5 p-4">
              <p className="text-[11px] uppercase tracking-wide text-muted">Estimated over 6 months</p>
              <p className="mt-1 font-display text-3xl font-extrabold tracking-tight text-teal">
                R{money(sixMonthComm)}
              </p>
              <p className="mt-1 text-[11px] text-muted">
                ≈ R{money(monthlyComm)}/month · {(rate * 100).toFixed(1)}% of R{money(totalMonthlyGross)} tipped monthly
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Referrals table (empty state until the referrals service tracks signups per code) */}
      <div>
        <h3 className="mb-3 text-base font-medium text-ink">Your referrals</h3>
        <EmptyState
          icon={Users}
          title="No signups yet"
          body="Share your code above to start earning commission. Signups linked to your code will appear here as they happen."
        />
      </div>

      {/* How it works — richer with icons */}
      <div>
        <h3 className="mb-4 text-base font-medium text-ink">How it works</h3>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {steps.map((s, i) => (
            <div key={s.title} className="card !p-5">
              <div className="flex items-center gap-2">
                <span className="grid h-8 w-8 place-items-center rounded-full bg-primary text-xs font-bold text-white">{i + 1}</span>
                <s.icon className="h-4 w-4 text-teal" strokeWidth={2.2} />
              </div>
              <p className="mt-3 font-medium text-ink">{s.title}</p>
              <p className="body-muted mt-1 text-sm">{s.body}</p>
            </div>
          ))}
        </div>
      </div>

      {/* Copy-paste pitch templates */}
      {code && (
        <div className="card !p-5">
          <p className="text-xs font-semibold uppercase tracking-wide text-muted">Message templates</p>
          <p className="body-muted mt-1 text-sm">Ready-to-send messages — click Copy to grab one.</p>
          <div className="mt-4 space-y-3">
            {[
              { label: "For a friend creator", text: `Hey! You should try Tipping Jar — SA-first, fans tip you by card and you keep most of it. If you sign up with my code ${code}, I get a small kickback and you get on a legit platform. Link: ${shareUrl}` },
              { label: "For a stream chat", text: `Support my friends too — sign up on Tipping Jar with code ${code}: ${channelUrl("stream")}` },
              { label: "For an email intro", text: `Sharing this: Tipping Jar. It's a South African tipping platform — fans pay by card, creators get paid out to bank. If you're on the fence about monetising, this is the easiest way in. Use my code ${code} at signup — ${channelUrl("email")}` },
            ].map((t) => (
              <div key={t.label} className="rounded-xl border border-border bg-white p-3">
                <div className="flex items-start justify-between gap-2">
                  <p className="text-xs font-semibold text-ink">{t.label}</p>
                  <button
                    onClick={() => copy(t.text, `tpl-${t.label}`)}
                    className={`shrink-0 rounded-full border px-2.5 py-1 text-[11px] font-medium transition ${copied === `tpl-${t.label}` ? "border-teal bg-teal text-white" : "border-border text-muted hover:border-teal hover:text-teal"}`}
                  >
                    {copied === `tpl-${t.label}` ? "Copied!" : <><Copy className="inline h-2.5 w-2.5" strokeWidth={2.4} /> Copy</>}
                  </button>
                </div>
                <p className="mt-1.5 whitespace-pre-wrap text-xs text-muted">{t.text}</p>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

// ─── Transactions & payouts ─────────────────────────────────────────────────
// Escape a CSV cell, defusing spreadsheet formula-injection attacks. Any cell
// whose first character is a formula trigger (= + - @ \t \r) gets a leading
// single-quote so Excel/Sheets renders it as literal text.
function csvCell(v: string | number | null | undefined): string {
  let s = String(v ?? "");
  if (/^[=+\-@\t\r]/.test(s)) s = "'" + s;
  return `"${s.replace(/"/g, '""')}"`;
}
function downloadCsv(name: string, header: string[], rows: (string | number | null | undefined)[][]) {
  const lines = [header.map(csvCell).join(","), ...rows.map((r) => r.map(csvCell).join(","))];
  // Prepend a UTF-8 BOM so Excel opens non-ASCII content correctly.
  const blob = new Blob(["﻿" + lines.join("\n")], { type: "text/csv;charset=utf-8" });
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = name;
  a.click();
  URL.revokeObjectURL(a.href);
}

function exportTxnCsv(rows: Transaction[]) {
  downloadCsv(
    `transactions-${new Date().toISOString().slice(0, 10)}.csv`,
    ["date", "reference", "tipper", "email", "message", "status", "currency", "amount", "platform_fee", "service_fee", "you_get", "jar_id"],
    rows.map((t) => [
      t.created_at, t.reference, t.tipper_name || "Anonymous", t.tipper_email || "",
      t.message || "", t.status, t.currency, t.amount, t.platform_fee, t.service_fee, t.creator_net, t.jar_id || "",
    ]),
  );
}

function TransactionsTab({ token, creatorId }: { token: string | null; creatorId: string | null }) {
  const [txns, setTxns] = useState<Transaction[]>([]);
  const [balance, setBalance] = useState<Balance | null>(null);
  const [payouts, setPayouts] = useState<Payout[]>([]);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState<string | null>(null);
  const [q, setQ] = useState("");
  const [status, setStatus] = useState<"all" | "completed" | "pending" | "failed">("all");
  const [range, setRange] = useState<"all" | "7d" | "30d" | "month">("all");
  const [minAmount, setMinAmount] = useState("");
  const [selected, setSelected] = useState<Transaction | null>(null);

  const load = useCallback(() => {
    if (!token || !creatorId) { setLoading(false); return; }
    setLoading(true);
    Promise.all([
      api.creatorTransactions(token, creatorId).catch(() => [] as Transaction[]),
      api.creatorBalance(token, creatorId).catch(() => null),
      api.creatorPayouts(token, creatorId).catch(() => [] as Payout[]),
    ])
      .then(([t, b, p]) => { setTxns(t); setBalance(b); setPayouts(p); })
      .finally(() => setLoading(false));
  }, [token, creatorId]);
  useEffect(load, [load]);

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

  // Filtering
  const now = Date.now();
  const startOfToday = new Date(); startOfToday.setHours(0, 0, 0, 0);
  const startOfMonth = new Date(); startOfMonth.setDate(1); startOfMonth.setHours(0, 0, 0, 0);
  const cutoff =
    range === "7d"    ? new Date(now - 7 * 86400000)
    : range === "30d" ? new Date(now - 30 * 86400000)
    : range === "month" ? startOfMonth
    : null;
  const minA = parseFloat(minAmount);
  const filtered = txns.filter((t) => {
    if (cutoff && new Date(t.created_at) < cutoff) return false;
    if (status !== "all" && t.status !== status) return false;
    if (!Number.isNaN(minA) && Number(t.amount) < minA) return false;
    if (q) {
      const n = q.toLowerCase();
      if (
        !(t.reference || "").toLowerCase().includes(n) &&
        !(t.tipper_name || "").toLowerCase().includes(n) &&
        !(t.tipper_email || "").toLowerCase().includes(n) &&
        !(t.message || "").toLowerCase().includes(n)
      ) return false;
    }
    return true;
  });

  // KPI derivations
  const completed = txns.filter((t) => t.status === "completed");
  const pending = txns.filter((t) => t.status === "pending");
  const totalGross = completed.reduce((s, t) => s + Number(t.amount || 0), 0);
  const totalNet = completed.reduce((s, t) => s + Number(t.creator_net || 0), 0);
  const totalFees = completed.reduce((s, t) => s + Number(t.platform_fee || 0) + Number(t.service_fee || 0), 0);
  const pendingAmt = pending.reduce((s, t) => s + Number(t.amount || 0), 0);
  const available = Number(balance?.available ?? "0");
  const withdrawn = Number(balance?.withdrawn ?? "0");

  // 14-day mini sparkline
  const bins: number[] = Array(14).fill(0);
  completed.forEach((t) => {
    const d = new Date(t.created_at);
    const day = Math.floor((now - +d) / 86400000);
    if (day >= 0 && day < 14) bins[13 - day] += Number(t.amount || 0);
  });
  const maxBin = Math.max(...bins, 1);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-xl font-medium tracking-tight text-ink">Transactions & payouts</h2>
        <p className="body-muted mt-1">Every card payment, its fee split, and your withdrawals — one screen.</p>
      </div>

      {/* KPI row */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6">
        <StatCard label="Gross received" value={`R${money(totalGross)}`} icon={Banknote} accent="#2563EB" />
        <StatCard label="Net after fees" value={`R${money(totalNet)}`} icon={Wallet} accent="#12A25C" />
        <StatCard label="Available now" value={`R${money(available)}`} icon={CircleCheck} accent="#0097B2" />
        <StatCard label="Withdrawn" value={`R${money(withdrawn)}`} icon={Percent} accent="#7C3AED" />
        <StatCard label="Fees paid" value={`R${money(totalFees)}`} icon={Percent} accent="#DC2626" />
        <StatCard label={`Pending (${pending.length})`} value={`R${money(pendingAmt)}`} icon={Calendar} accent="#E0A536" />
      </div>

      {/* Payout card + sparkline */}
      <div className="grid gap-4 lg:grid-cols-[1.4fr_1fr]">
        <div className="card !p-5">
          <div className="flex flex-wrap items-start justify-between gap-3">
            <div>
              <p className="font-medium text-ink">Request a payout</p>
              <p className="body-muted mt-1 text-sm">
                Withdraw your available balance to your bank account. Set up your bank details on the Profile tab first.
              </p>
              <p className="mt-3 font-display text-3xl font-extrabold tracking-tight text-teal">
                R{money(available)}
                <span className="ml-2 text-sm font-medium text-muted">available</span>
              </p>
            </div>
            <button
              onClick={payout}
              disabled={busy || available <= 0}
              className="btn-primary !font-medium disabled:cursor-not-allowed disabled:opacity-50"
            >
              {busy ? "Requesting…" : "Request payout"}
            </button>
          </div>
          {msg && <p className="mt-3 text-sm text-teal">{msg}</p>}
        </div>
        <div className="card !p-5">
          <div className="flex items-baseline justify-between">
            <p className="text-xs font-semibold uppercase tracking-wide text-muted">Volume · last 14 days</p>
            <p className="text-sm font-bold text-ink">R{money(bins.reduce((s, x) => s + x, 0))}</p>
          </div>
          <div className="mt-4 flex h-20 items-end gap-1.5">
            {bins.map((v, i) => (
              <div key={i} className="flex-1 rounded-t bg-teal/70 transition hover:bg-teal"
                style={{ height: `${Math.max(3, (v / maxBin) * 68)}px` }}
                title={`R${money(v)}`} />
            ))}
          </div>
        </div>
      </div>

      {/* Filter toolbar */}
      <div className="card flex flex-wrap items-center gap-3 !p-4">
        <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search reference, name, email, message…"
          className="w-full max-w-xs rounded-full border border-border bg-white px-4 py-2 text-sm text-ink focus:border-primary/40 focus:outline-none" />
        <input value={minAmount} onChange={(e) => setMinAmount(e.target.value.replace(/[^0-9.]/g, ""))} inputMode="decimal"
          placeholder="Min R" className="w-24 rounded-full border border-border bg-white px-4 py-2 text-sm text-ink focus:border-primary/40 focus:outline-none" />
        <div className="flex flex-wrap gap-1.5">
          {(["all", "completed", "pending", "failed"] as const).map((s) => (
            <button key={s} onClick={() => setStatus(s)} className={`rounded-full px-3 py-1.5 text-xs font-medium transition ${status === s ? "bg-primary text-white" : "border border-border text-muted hover:text-ink"}`}>
              {s}
            </button>
          ))}
        </div>
        <span className="mx-1 h-5 w-px bg-border" />
        <div className="flex flex-wrap gap-1.5">
          {(["all", "7d", "30d", "month"] as const).map((r) => (
            <button key={r} onClick={() => setRange(r)} className={`rounded-full px-3 py-1.5 text-xs font-medium transition ${range === r ? "bg-primary text-white" : "border border-border text-muted hover:text-ink"}`}>
              {r === "all" ? "All time" : r === "month" ? "This month" : `Last ${r}`}
            </button>
          ))}
        </div>
        <button onClick={() => exportTxnCsv(filtered)} disabled={filtered.length === 0}
          className="ml-auto inline-flex items-center gap-1.5 rounded-full border border-border px-3.5 py-1.5 text-xs font-medium text-muted transition hover:border-teal hover:text-teal disabled:opacity-40">
          <Download className="h-3.5 w-3.5" strokeWidth={2.2} /> CSV
        </button>
      </div>

      {/* Transactions */}
      {filtered.length === 0 ? (
        txns.length === 0
          ? <EmptyState icon={Receipt} title="No transactions yet" body="Tips and card payments will show up here." />
          : <EmptyState icon={Receipt} title="No transactions match those filters" body="Widen the range, drop the min amount, or clear the search." />
      ) : (
        <div className="card overflow-hidden !p-0">
          <div className="border-b border-border bg-darker/40 px-5 py-2 text-xs text-muted">
            {filtered.length} of {txns.length} · R{money(filtered.reduce((s, t) => s + Number(t.amount || 0), 0))} gross · click any row for full details
          </div>
          <div className="overflow-x-auto">
            <table className="w-full min-w-[820px] text-left text-sm">
              <thead className="border-b border-border text-xs uppercase tracking-wide text-muted">
                <tr>
                  <th className="px-5 py-3 font-medium">Reference</th>
                  <th className="px-5 py-3 font-medium">Tipper</th>
                  <th className="px-5 py-3 font-medium">Date</th>
                  <th className="px-5 py-3 font-medium">Status</th>
                  <th className="px-5 py-3 text-right font-medium">Amount</th>
                  <th className="px-5 py-3 text-right font-medium">Fees</th>
                  <th className="px-5 py-3 text-right font-medium">You get</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((t) => {
                  const fees = Number(t.platform_fee || 0) + Number(t.service_fee || 0);
                  return (
                  <tr key={t.id} onClick={() => setSelected(t)} className="cursor-pointer border-b border-border/60 transition-colors last:border-0 hover:bg-ink/[0.02]">
                    <td className="px-5 py-3">
                      <p className="font-mono text-xs text-ink">{t.reference.slice(0, 22)}…</p>
                      {t.jar_id && <p className="mt-0.5 inline-flex items-center gap-1 rounded-full bg-mint/15 px-2 py-0.5 text-[10px] font-medium text-green">🫙 jar</p>}
                    </td>
                    <td className="px-5 py-3">
                      <p className="text-ink">{t.tipper_name || "Anonymous"}</p>
                      {t.tipper_email && <p className="text-[11px] text-muted">{t.tipper_email}</p>}
                    </td>
                    <td className="px-5 py-3 text-muted whitespace-nowrap">
                      {new Date(t.created_at).toLocaleDateString("en-ZA", { day: "numeric", month: "short" })}
                      <span className="ml-1 text-[11px] text-muted/60">{new Date(t.created_at).toLocaleTimeString("en-ZA", { hour: "2-digit", minute: "2-digit" })}</span>
                    </td>
                    <td className="px-5 py-3">
                      <span className={`rounded-full px-2.5 py-1 text-xs font-medium ${
                        t.status === "completed" ? "bg-teal/10 text-teal"
                        : t.status === "pending" ? "bg-yellow-500/10 text-yellow-500"
                        : "bg-red-500/10 text-red-500"
                      }`}>{t.status}</span>
                    </td>
                    <td className="px-5 py-3 text-right text-ink">{t.currency} {t.amount}</td>
                    <td className="px-5 py-3 text-right text-muted">R{fees.toFixed(2)}</td>
                    <td className="px-5 py-3 text-right font-bold text-teal">R{t.creator_net}</td>
                  </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Details modal */}
      {selected && (
        <div className="fixed inset-0 z-50 grid place-items-center bg-navy/60 p-4 backdrop-blur-sm" onClick={() => setSelected(null)}>
          <div className="card w-full max-w-xl !p-6" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-start justify-between gap-3">
              <div>
                <p className="text-xs font-semibold uppercase tracking-wide text-muted">Transaction</p>
                <h3 className="mt-1 font-display text-2xl font-extrabold tracking-tight text-ink">
                  R{selected.amount} <span className="text-sm font-medium text-muted">gross</span>
                </h3>
              </div>
              <button onClick={() => setSelected(null)} className="text-muted hover:text-ink" aria-label="Close">
                <X className="h-5 w-5" strokeWidth={2.2} />
              </button>
            </div>
            <dl className="mt-5 grid gap-y-3 text-sm sm:grid-cols-2">
              <div><dt className="text-xs text-muted">Reference</dt><dd className="mt-0.5 break-all font-mono text-xs text-ink">{selected.reference}</dd></div>
              <div><dt className="text-xs text-muted">PayCloud trans_no</dt><dd className="mt-0.5 break-all font-mono text-xs text-ink">{selected.trans_no || "—"}</dd></div>
              <div><dt className="text-xs text-muted">Tipper</dt><dd className="mt-0.5 text-ink">{selected.tipper_name || "Anonymous"}</dd></div>
              <div><dt className="text-xs text-muted">Email</dt><dd className="mt-0.5 text-ink">{selected.tipper_email || "—"}</dd></div>
              <div><dt className="text-xs text-muted">Status</dt><dd className="mt-0.5"><span className={`rounded-full px-2.5 py-1 text-xs font-medium ${selected.status === "completed" ? "bg-teal/10 text-teal" : selected.status === "pending" ? "bg-yellow-500/10 text-yellow-500" : "bg-red-500/10 text-red-500"}`}>{selected.status}</span></dd></div>
              <div><dt className="text-xs text-muted">When</dt><dd className="mt-0.5 text-ink">{new Date(selected.created_at).toLocaleString("en-ZA", { dateStyle: "medium", timeStyle: "short" })}</dd></div>
              <div className="sm:col-span-2"><dt className="text-xs text-muted">Message</dt><dd className="mt-0.5 whitespace-pre-wrap text-ink">{selected.message || <span className="text-muted">—</span>}</dd></div>
            </dl>
            <div className="mt-5 rounded-xl bg-darker/40 p-4">
              <p className="text-xs font-semibold uppercase tracking-wide text-muted">Fee breakdown</p>
              <div className="mt-2 space-y-1.5 text-sm">
                <div className="flex justify-between"><span className="text-muted">Gross</span><span className="font-mono text-ink">R{selected.amount}</span></div>
                <div className="flex justify-between"><span className="text-muted">Platform fee</span><span className="font-mono text-red-500">−R{selected.platform_fee}</span></div>
                <div className="flex justify-between"><span className="text-muted">Card & service</span><span className="font-mono text-red-500">−R{selected.service_fee}</span></div>
                <div className="flex justify-between border-t border-border pt-1.5"><span className="font-semibold text-ink">You get</span><span className="font-mono font-bold text-teal">R{selected.creator_net}</span></div>
              </div>
            </div>
            <div className="mt-4 flex flex-wrap gap-2">
              <button
                onClick={() => { navigator.clipboard?.writeText(selected.reference); setMsg("Reference copied"); window.setTimeout(() => setMsg(null), 1500); }}
                className="inline-flex items-center gap-1.5 rounded-full border border-border px-3 py-1.5 text-xs font-medium text-muted hover:border-teal hover:text-teal"
              >
                <Copy className="h-3 w-3" strokeWidth={2.4} /> Copy reference
              </button>
              <Link href={`/dashboard?tab=tips`} className="inline-flex items-center gap-1.5 rounded-full border border-border px-3 py-1.5 text-xs font-medium text-muted hover:border-teal hover:text-teal">
                Open in Tips <ArrowUpRight className="h-3 w-3" strokeWidth={2.4} />
              </Link>
            </div>
          </div>
        </div>
      )}

      {/* Payout history */}
      {payouts.length > 0 && (
        <div>
          <div className="mb-4 flex items-baseline justify-between">
            <h3 className="text-base font-medium text-ink">Payout history</h3>
            <p className="text-xs text-muted">{payouts.length} withdrawal{payouts.length === 1 ? "" : "s"}</p>
          </div>
          <div className="card overflow-hidden !p-0">
            <div className="overflow-x-auto">
              <table className="w-full min-w-[560px] text-left text-sm">
                <thead className="border-b border-border text-xs uppercase tracking-wide text-muted">
                  <tr>
                    <th className="px-5 py-3 font-medium">Reference</th>
                    <th className="px-5 py-3 font-medium">When</th>
                    <th className="px-5 py-3 font-medium">Status</th>
                    <th className="px-5 py-3 text-right font-medium">Amount</th>
                  </tr>
                </thead>
                <tbody>
                  {payouts.map((p) => (
                    <tr key={p.id} className="border-b border-border/60 last:border-0">
                      <td className="px-5 py-3 font-mono text-xs text-muted">{p.reference}</td>
                      <td className="px-5 py-3 text-muted">{new Date(p.created_at).toLocaleString("en-ZA", { dateStyle: "medium", timeStyle: "short" })}</td>
                      <td className="px-5 py-3">
                        <span className={`rounded-full px-2.5 py-1 text-xs font-medium ${p.status === "completed" ? "bg-teal/10 text-teal" : p.status === "pending" ? "bg-yellow-500/10 text-yellow-500" : "bg-red-500/10 text-red-500"}`}>
                          {p.status}
                        </span>
                      </td>
                      <td className="px-5 py-3 text-right font-bold text-teal">R{p.amount}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ─── Studio ──────────────────────────────────────────────────────────────────

function GalleryPreview({ token }: { token: string | null }) {
  const [designs, setDesigns] = useState<StudioDesign[] | null>(null);
  const [q, setQ] = useState("");
  const [kindFilter, setKindFilter] = useState<
    "all" | "square" | "portrait" | "story" | "landscape" | "banner" | "thumb" | "poster" | "card"
  >("all");
  const [note, setNote] = useState<string | null>(null);

  const load = useCallback(() => {
    if (!token) return;
    api.myDesigns(token).then(setDesigns).catch(() => setDesigns([]));
  }, [token]);
  useEffect(load, [load]);

  if (!designs) return null;
  const filtered = designs.filter((d) => {
    if (kindFilter !== "all" && d.kind !== kindFilter) return false;
    if (q && !d.title.toLowerCase().includes(q.toLowerCase())) return false;
    return true;
  });

  const total = designs.length;
  const monthAgo = Date.now() - 30 * 86400000;
  const thisMonth = designs.filter((d) => +new Date(d.created_at) >= monthAgo).length;
  const byKind: Record<string, number> = {};
  designs.forEach((d) => { byKind[d.kind] = (byKind[d.kind] || 0) + 1; });
  const latest = designs[0]?.created_at;
  const daysSince = latest ? Math.floor((Date.now() - +new Date(latest)) / 86400000) : null;

  async function download(d: StudioDesign) {
    if (!d.thumb) return;
    const a = document.createElement("a");
    a.href = d.thumb;
    a.download = `${d.title.replace(/\W+/g, "-").toLowerCase() || d.kind}.png`;
    a.click();
  }
  async function copyImage(d: StudioDesign) {
    try {
      const res = await fetch(d.thumb);
      const blob = await res.blob();
      await navigator.clipboard.write([new ClipboardItem({ [blob.type]: blob })]);
      setNote("Design copied — paste into a chat or post.");
    } catch {
      setNote("Clipboard image not supported here — use Download instead.");
    }
    window.setTimeout(() => setNote(null), 2000);
  }

  async function remove(d: StudioDesign) {
    if (!token || !window.confirm(`Delete "${d.title || d.kind}"?`)) return;
    await api.deleteDesign(token, d.id).catch(() => null);
    load();
  }

  return (
    <div className="space-y-6">
      {/* KPIs */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Designs saved" value={String(total)} icon={Palette} accent="#EC4899" />
        <StatCard label="This month" value={String(thisMonth)} icon={Calendar} accent="#12A25C" />
        <StatCard label="Days since last save" value={daysSince === null ? "—" : String(daysSince)} icon={Zap} accent={daysSince !== null && daysSince > 30 ? "#DC2626" : "#2563EB"} />
        <StatCard label="Sizes used" value={String(Object.keys(byKind).length)} icon={QrCode} accent="#E0A536" />
      </div>

      {designs.length > 0 && (
        <div className="card flex flex-wrap items-center gap-3 !p-4">
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Search designs…"
            className="w-full max-w-xs rounded-full border border-border bg-white px-4 py-2 text-sm text-ink focus:border-primary/40 focus:outline-none"
          />
          <div className="flex flex-wrap gap-1.5">
            {(["all", "square", "portrait", "story", "landscape", "banner", "thumb", "poster", "card"] as const).map((k) => (
              <button
                key={k}
                onClick={() => setKindFilter(k)}
                className={`rounded-full px-3 py-1.5 text-xs font-medium transition ${
                  kindFilter === k ? "bg-primary text-white" : "border border-border text-muted hover:text-ink"
                }`}
              >
                {k === "all" ? "All" : k}
              </button>
            ))}
          </div>
          <span className="ml-auto text-xs text-muted">{filtered.length} of {designs.length}</span>
        </div>
      )}

      {note && <p className="text-sm text-teal">{note}</p>}

      {designs.length > 0 && (
        <div>
          <h3 className="mb-3 text-base font-medium text-ink">Your gallery</h3>
          {filtered.length === 0 ? (
            <EmptyState icon={Palette} title="No designs match" body="Try clearing your search or widening the size filter." />
          ) : (
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
              {filtered.map((d) => (
                <div key={d.id} className="card overflow-hidden !p-0">
                  <div className="grid place-items-center bg-darker/40 p-2">
                    {d.thumb ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img src={d.thumb} alt="" className="w-full rounded-lg object-contain" />
                    ) : (
                      <div className="grid aspect-square w-full place-items-center text-4xl text-muted">🎨</div>
                    )}
                  </div>
                  <div className="p-3">
                    <div className="flex items-start justify-between gap-2">
                      <p className="min-w-0 truncate text-sm font-medium text-ink">{d.title || "Untitled"}</p>
                      <span className="shrink-0 rounded-full bg-primary/10 px-2 py-0.5 text-[10px] font-medium text-primary">
                        {d.kind}
                      </span>
                    </div>
                    <p className="mt-1 font-mono text-[10px] text-muted">
                      {new Date(d.created_at).toLocaleDateString("en-ZA", { day: "numeric", month: "short" })}
                    </p>
                    <div className="mt-2 flex items-center gap-1">
                      <button
                        onClick={() => download(d)}
                        className="rounded-full border border-border px-2.5 py-1 text-[11px] font-medium text-muted hover:border-teal hover:text-teal"
                        title="Download PNG"
                      >
                        <Download className="inline h-3 w-3" strokeWidth={2.4} />
                      </button>
                      <button
                        onClick={() => copyImage(d)}
                        className="rounded-full border border-border px-2.5 py-1 text-[11px] font-medium text-muted hover:border-teal hover:text-teal"
                        title="Copy image to clipboard"
                      >
                        <Copy className="inline h-3 w-3" strokeWidth={2.4} />
                      </button>
                      <button
                        onClick={() => remove(d)}
                        className="ml-auto rounded-full border border-red-200 px-2.5 py-1 text-[11px] font-medium text-red-500 hover:bg-red-50"
                        title="Delete"
                      >
                        <X className="inline h-3 w-3" strokeWidth={2.4} />
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function StudioTab({ token, slug }: { token: string | null; slug: string | null }) {
  return (
    <div className="space-y-8">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h2 className="text-xl font-medium tracking-tight text-ink">Creator Studio</h2>
          <p className="body-muted mt-1">
            Design share-ready graphics for your posts, stories, and streams — with your tip link built in.
          </p>
        </div>
      </div>

      {/* Ideas strip — what to make */}
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        {[
          { emoji: "📱", title: "Instagram post", body: "1080×1080 square with your tip link + tagline." },
          { emoji: "📸", title: "Story / Reel cover", body: "1080×1920 portrait — sticker on your story." },
          { emoji: "🎥", title: "OBS overlay card", body: "Landscape banner that reads on stream." },
          { emoji: "🎯", title: "QR tip poster", body: "Print-ready QR + your slug for events/gigs." },
        ].map((i) => (
          <div key={i.title} className="card !p-4">
            <span className="text-2xl">{i.emoji}</span>
            <p className="mt-2 font-medium text-ink">{i.title}</p>
            <p className="body-muted mt-1 text-xs">{i.body}</p>
          </div>
        ))}
      </div>

      {/* Gallery + KPIs */}
      <GalleryPreview token={token} />

      {/* Editor */}
      <div className="pt-2">
        <h3 className="mb-3 text-base font-medium text-ink">The editor</h3>
        <StudioEditor token={token} slug={slug} />
      </div>
    </div>
  );
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

function DualLineChart({
  gross,
  net,
  height = 180,
}: {
  gross: number[];
  net: number[];
  height?: number;
}) {
  const W = 600;
  const max = Math.max(...gross, ...net, 1);
  const step = W / Math.max(gross.length - 1, 1);
  const path = (arr: number[]) =>
    arr.map((v, i) => `${i === 0 ? "M" : "L"}${(i * step).toFixed(1)},${(height - 12 - (v / max) * (height - 30)).toFixed(1)}`).join(" ");
  const area = (arr: number[]) => `${path(arr)} L${W},${height} L0,${height} Z`;
  return (
    <svg viewBox={`0 0 ${W} ${height}`} className="w-full" preserveAspectRatio="none" role="img" aria-label="dual line chart">
      {/* horizontal grid ticks */}
      {[0.25, 0.5, 0.75].map((f) => (
        <line key={f} x1="0" x2={W} y1={height - 12 - f * (height - 30)} y2={height - 12 - f * (height - 30)} stroke="#EFF2F0" strokeWidth="1" />
      ))}
      <path d={area(gross)} fill="#2563EB" opacity="0.10" />
      <path d={path(gross)} fill="none" stroke="#2563EB" strokeWidth="2.4" strokeLinejoin="round" strokeLinecap="round" />
      <path d={area(net)} fill="#12A25C" opacity="0.14" />
      <path d={path(net)} fill="none" stroke="#12A25C" strokeWidth="2.4" strokeLinejoin="round" strokeLinecap="round" />
    </svg>
  );
}

function HourHeatmap({ tips }: { tips: Tip[] }) {
  // 7 weekdays × 24 hours (Mon-first)
  const grid: number[][] = Array.from({ length: 7 }, () => new Array(24).fill(0));
  tips.forEach((t) => {
    const d = new Date(t.created_at);
    const wd = (d.getDay() + 6) % 7;
    grid[wd][d.getHours()] += Number(t.amount || 0);
  });
  const max = Math.max(1, ...grid.flat());
  const weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  return (
    <div>
      <div className="grid gap-[3px]" style={{ gridTemplateColumns: "36px repeat(24, minmax(0, 1fr))" }}>
        <span />
        {Array.from({ length: 24 }, (_, h) => (
          <span key={h} className="text-center font-mono text-[9px] text-muted">
            {h % 3 === 0 ? h : ""}
          </span>
        ))}
        {grid.map((row, i) => (
          <React.Fragment key={i}>
            <span className="pr-1 text-right font-mono text-[10px] text-muted">{weekdays[i]}</span>
            {row.map((v, h) => {
              const t = v / max;
              const bg = v === 0
                ? "rgba(15,36,57,0.04)"
                : `rgba(18,162,92,${0.2 + 0.75 * t})`;
              return (
                <span
                  key={h}
                  className="aspect-square rounded-sm"
                  style={{ background: bg }}
                  title={`${weekdays[i]} ${h.toString().padStart(2, "0")}:00 · R${Math.round(v)}`}
                />
              );
            })}
          </React.Fragment>
        ))}
      </div>
    </div>
  );
}

type Range = "7d" | "30d" | "90d" | "all";
const RANGES: { id: Range; label: string; days: number | null }[] = [
  { id: "7d", label: "7d", days: 7 },
  { id: "30d", label: "30d", days: 30 },
  { id: "90d", label: "90d", days: 90 },
  { id: "all", label: "All", days: null },
];

function AnalyticsTab({ token, creatorId, tips }: { token: string | null; creatorId: string | null; tips: Tip[] }) {
  const [days, setDays] = useState<{ day: string; count: number; gross: string; net: string }[] | null>(null);
  const [range, setRange] = useState<Range>("30d");
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
  const withMessage = completed.filter((t) => t.message).length;
  const messagePct = completed.length ? Math.round((withMessage / completed.length) * 100) : 0;

  // Repeat vs one-off supporters (uses email or name as key)
  const seenBy = new Map<string, number>();
  completed.forEach((t) => {
    const key = (t.tipper_email || t.tipper_name || "anon").toLowerCase();
    seenBy.set(key, (seenBy.get(key) ?? 0) + 1);
  });
  const supporters = seenBy.size;
  const repeat = [...seenBy.values()].filter((c) => c >= 2).length;
  const oneOff = supporters - repeat;
  const repeatRate = supporters ? Math.round((repeat / supporters) * 100) : 0;

  // Top supporters (top 5 by lifetime completed)
  const totalsByKey = new Map<string, { name: string; total: number; count: number }>();
  completed.forEach((t) => {
    const key = (t.tipper_email || t.tipper_name || "anon").toLowerCase();
    const cur = totalsByKey.get(key) ?? { name: t.tipper_name || "Anonymous", total: 0, count: 0 };
    cur.total += Number(t.amount || 0);
    cur.count += 1;
    totalsByKey.set(key, cur);
  });
  const topSupporters = [...totalsByKey.values()].sort((a, b) => b.total - a.total).slice(0, 5);

  // Time series driven by the range switcher (server data is 30 days,
  // longer ranges fall back to the tips array).
  const rangeDays = RANGES.find((r) => r.id === range)!.days;
  const cutoff = rangeDays ? new Date(Date.now() - rangeDays * 86400000) : new Date(0);
  const inRange = completed.filter((t) => new Date(t.created_at) >= cutoff);

  const map = new Map((days ?? []).map((d) => [d.day, d]));
  const nDays = rangeDays ?? Math.max(30, Math.ceil((Date.now() - +cutoff) / 86400000));
  const series: { day: string; gross: number; net: number; count: number }[] = [];
  for (let i = nDays - 1; i >= 0; i--) {
    const d = new Date(Date.now() - i * 86400000);
    const key = d.toISOString().slice(0, 10);
    const row = map.get(key);
    if (row) {
      series.push({ day: key, gross: Number(row.gross ?? 0), net: Number(row.net ?? 0), count: row.count ?? 0 });
    } else {
      const next = new Date(d.getTime() + 86400000); next.setHours(0,0,0,0); d.setHours(0,0,0,0);
      const rows = completed.filter((t) => { const td = new Date(t.created_at); return td >= d && td < next; });
      series.push({
        day: key,
        gross: rows.reduce((s, t) => s + (Number(t.amount) || 0), 0),
        net: rows.reduce((s, t) => s + (Number(t.creator_net) || 0), 0),
        count: rows.length,
      });
    }
  }
  const max = Math.max(...series.map((x) => x.gross), 1);
  const totalRange = series.reduce((s, x) => s + x.gross, 0);
  const netRange = series.reduce((s, x) => s + x.net, 0);
  const countRange = series.reduce((s, x) => s + x.count, 0);
  let running = 0;
  const cumulative = series.map((x) => (running += x.net));

  // weekday performance (from range)
  const weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  const byDay = new Array(7).fill(0);
  inRange.forEach((t) => { byDay[(new Date(t.created_at).getDay() + 6) % 7] += Number(t.amount || 0); });
  const maxDay = Math.max(...byDay, 1);
  const bestDay = weekdays[byDay.indexOf(Math.max(...byDay))];

  // tip-size distribution (from range)
  const buckets = [
    { label: "R10–24", value: 0, color: "#57CE8B" },
    { label: "R25–49", value: 0, color: "#12A25C" },
    { label: "R50–99", value: 0, color: "#0F2439" },
    { label: "R100+", value: 0, color: "#E0A536" },
  ];
  inRange.forEach((t) => {
    const a = Number(t.amount || 0);
    if (a < 25) buckets[0].value++;
    else if (a < 50) buckets[1].value++;
    else if (a < 100) buckets[2].value++;
    else buckets[3].value++;
  });

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h2 className="text-xl font-medium tracking-tight text-ink">Analytics</h2>
          <p className="body-muted mt-1">How your jar is filling.</p>
        </div>
        <div className="flex gap-1.5">
          {RANGES.map((r) => (
            <button
              key={r.id}
              onClick={() => setRange(r.id)}
              className={`rounded-full px-3.5 py-1.5 text-xs font-medium transition ${
                range === r.id ? "bg-primary text-white" : "border border-border text-muted hover:text-ink"
              }`}
            >
              {r.label}
            </button>
          ))}
        </div>
      </div>

      {/* 6-tile KPI header */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6">
        <StatCard label="Gross (range)" value={`R${money(totalRange)}`} icon={Banknote} accent="#2563EB" />
        <StatCard label="Net (range)" value={`R${money(netRange)}`} icon={Wallet} accent="#12A25C" />
        <StatCard label="Tips (range)" value={String(countRange)} icon={HandCoins} accent="#E0A536" />
        <StatCard label={delta === null ? "This month" : `Month (${delta >= 0 ? "+" : ""}${delta}%)`} value={`R${money(thisMonth)}`} icon={Calendar} accent="#7C3AED" />
        <StatCard label="Average tip" value={`R${money(avg)}`} icon={Percent} accent="#EC4899" />
        <StatCard label="Biggest tip" value={`R${money(biggest)}`} icon={Trophy} accent="#DC2626" />
      </div>

      {/* Insights strip */}
      <div className="card flex flex-wrap items-center gap-x-6 gap-y-2 !p-4 text-xs text-muted">
        <span><span className="font-semibold text-ink">{repeatRate}%</span> of supporters give more than once</span>
        <span className="h-3 w-px bg-border" />
        <span><span className="font-semibold text-ink">{messagePct}%</span> of tips came with a message</span>
        <span className="h-3 w-px bg-border" />
        <span>Best day: <span className="font-semibold text-ink">{bestDay || "—"}</span></span>
        <span className="h-3 w-px bg-border" />
        <span>Range gross: <span className="font-semibold text-ink">R{money(totalRange)}</span></span>
      </div>

      {/* Dual-line: gross vs net */}
      <div className="card !p-5">
        <div className="flex items-baseline justify-between">
          <p className="text-xs font-semibold uppercase tracking-wide text-muted">Gross vs net · {range === "all" ? "all time" : `last ${rangeDays} days`}</p>
          <div className="flex items-center gap-3 text-[11px]">
            <span className="inline-flex items-center gap-1.5 text-muted"><span className="h-2 w-3 rounded-sm bg-[#2563EB]" /> gross</span>
            <span className="inline-flex items-center gap-1.5 text-muted"><span className="h-2 w-3 rounded-sm bg-[#12A25C]" /> net</span>
          </div>
        </div>
        <div className="mt-4">
          {!days ? <p className="body-muted">Loading…</p> : <DualLineChart gross={series.map((x) => x.gross)} net={series.map((x) => x.net)} />}
        </div>
        <div className="mt-1 flex justify-between font-mono text-[10px] text-muted">
          <span>{series[0]?.day.slice(5)}</span>
          <span>today</span>
        </div>
      </div>

      {/* Daily volume bars + cumulative earnings */}
      <div className="grid gap-6 lg:grid-cols-2">
        <div className="card !p-5">
          <div className="flex items-baseline justify-between">
            <p className="text-xs font-semibold uppercase tracking-wide text-muted">Daily tip volume</p>
            <p className="text-sm font-bold text-ink">R{money(totalRange)}</p>
          </div>
          <div className="mt-4 flex h-28 items-end gap-[3px]">
            {series.map((x) => (
              <div
                key={x.day}
                className="flex-1 rounded-t bg-teal/70 transition hover:bg-teal"
                style={{ height: `${Math.max(3, (x.gross / max) * 100)}%` }}
                title={`${x.day}: R${money(x.gross)} (${x.count})`}
              />
            ))}
          </div>
        </div>
        <div className="card !p-5">
          <div className="flex items-baseline justify-between">
            <p className="text-xs font-semibold uppercase tracking-wide text-muted">Cumulative net earnings</p>
            <p className="text-sm font-bold text-teal">R{money(cumulative[cumulative.length - 1] ?? 0)}</p>
          </div>
          <div className="mt-4"><LineChart points={cumulative} color="#12A25C" height={112} /></div>
        </div>
      </div>

      {/* Hour-of-day heatmap */}
      <div className="card !p-5">
        <p className="text-xs font-semibold uppercase tracking-wide text-muted">When your fans tip (weekday × hour)</p>
        <p className="mt-1 text-[11px] text-muted">Darker green = more money that hour, from every completed tip.</p>
        <div className="mt-4 overflow-x-auto">
          {completed.length === 0 ? <p className="body-muted">No completed tips yet.</p> : <HourHeatmap tips={completed} />}
        </div>
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        {/* Weekday performance */}
        <div className="card !p-5">
          <p className="text-xs font-semibold uppercase tracking-wide text-muted">Best days of the week</p>
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
          <p className="text-xs font-semibold uppercase tracking-wide text-muted">Tip size mix</p>
          <div className="mt-4">
            {inRange.length === 0 ? <p className="body-muted">No completed tips yet.</p> : <Donut slices={buckets} />}
          </div>
        </div>

        {/* Repeat vs one-off */}
        <div className="card !p-5">
          <p className="text-xs font-semibold uppercase tracking-wide text-muted">Repeat vs one-off supporters</p>
          <div className="mt-4">
            {supporters === 0 ? (
              <p className="body-muted">No supporters yet.</p>
            ) : (
              <Donut
                slices={[
                  { label: `Repeat · ${repeat}`, value: repeat, color: "#12A25C" },
                  { label: `One-off · ${oneOff}`, value: oneOff, color: "#E0A536" },
                ]}
              />
            )}
          </div>
        </div>
      </div>

      {/* Top supporters micro-list */}
      <div className="card !p-5">
        <p className="text-xs font-semibold uppercase tracking-wide text-muted">Top supporters (all time)</p>
        {topSupporters.length === 0 ? (
          <p className="body-muted mt-3">No completed tips yet.</p>
        ) : (
          <div className="mt-4 space-y-2">
            {topSupporters.map((s, i) => (
              <div key={s.name + i} className="flex items-center gap-3">
                <span className="w-6 text-center text-lg">{["🥇", "🥈", "🥉"][i] ?? <span className="text-xs text-muted">{i + 1}</span>}</span>
                <span className="min-w-0 flex-1 truncate text-sm text-ink">{s.name}</span>
                <div className="h-1.5 w-40 max-w-[45%] overflow-hidden rounded-full bg-border/60">
                  <div className="h-full rounded-full bg-teal" style={{ width: `${(s.total / (topSupporters[0].total || 1)) * 100}%` }} />
                </div>
                <span className="w-24 text-right font-bold text-teal">R{money(s.total)}</span>
                <span className="w-14 text-right text-xs text-muted">{s.count} tip{s.count === 1 ? "" : "s"}</span>
              </div>
            ))}
          </div>
        )}
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

// SA banks with universal branch codes — mirrors onboarding so users
// see the same list when editing here.
const PROFILE_SA_BANKS: { name: string; code: string }[] = [
  { name: "Absa", code: "632005" },
  { name: "African Bank", code: "430000" },
  { name: "Bank Zero", code: "888000" },
  { name: "Capitec Bank", code: "470010" },
  { name: "Discovery Bank", code: "679000" },
  { name: "First National Bank (FNB)", code: "250655" },
  { name: "Investec", code: "580105" },
  { name: "Nedbank", code: "198765" },
  { name: "Standard Bank", code: "051001" },
  { name: "TymeBank", code: "678910" },
  { name: "Other", code: "" },
];
const PROFILE_ACCOUNT_TYPES = [
  { id: "cheque", label: "Cheque / Current" },
  { id: "savings", label: "Savings" },
  { id: "transmission", label: "Transmission" },
];
const PROFILE_COUNTRIES: { code: string; name: string }[] = [
  { code: "ZA", name: "South Africa" },
  { code: "NA", name: "Namibia" },
  { code: "BW", name: "Botswana" },
  { code: "ZW", name: "Zimbabwe" },
  { code: "MZ", name: "Mozambique" },
  { code: "LS", name: "Lesotho" },
  { code: "SZ", name: "Eswatini" },
  { code: "KE", name: "Kenya" },
  { code: "NG", name: "Nigeria" },
  { code: "GH", name: "Ghana" },
  { code: "UK", name: "United Kingdom" },
  { code: "US", name: "United States" },
  { code: "OT", name: "Elsewhere" },
];
const PROFILE_ORG_TYPES = [
  { id: "", label: "— pick one —" },
  { id: "ngo", label: "NGO / non-profit" },
  { id: "church", label: "Church / faith community" },
  { id: "school", label: "School / educator" },
  { id: "business", label: "Social enterprise" },
  { id: "other", label: "Something else" },
];

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
  const [country, setCountry] = useState(creator?.country ?? "ZA");
  const [city, setCity] = useState(creator?.city ?? "");
  const [orgType, setOrgType] = useState(creator?.org_type ?? "");
  const [regNumber, setRegNumber] = useState(creator?.registration_number ?? "");
  useEffect(() => {
    if (token) api.myBankDetails(token).then((b) => setBank(b as Record<string, string>)).catch(() => null);
  }, [token]);
  const [busy, setBusy] = useState(false);
  const [note, setNote] = useState<string | null>(null);
  const [linkCopied, setLinkCopied] = useState(false);
  const avatarRef = useRef<HTMLInputElement>(null);
  const coverRef = useRef<HTMLInputElement>(null);

  if (!creator) {
    return (
      <EmptyState icon={UserRound} title="No creator page yet" body="Set up your creator page first — then manage it here." />
    );
  }

  const isOrg = (creator.profile_type || "individual") === "organisation";
  const avatarPreview = avatar ?? creator.avatar_url;
  const coverPreview = cover ?? creator.cover_url;
  const publicUrl = `https://tippingjar.co.za/creator/${creator.slug}`;

  // Bank verification status derived from the presence of the essential
  // fields (holder + bank + account no). We treat all-3 as "verified" for
  // the badge — the actual bank-verification happens against the payout
  // gateway before the first cash-out.
  const bankReady =
    !!(bank.account_name?.trim() && bank.bank?.trim() && bank.account_no?.trim());

  // Profile completion — 10 items, all things fans (or the ops team) can
  // see or act on. The strip surfaces what's left.
  const checklist: { key: string; label: string; done: boolean; href?: string }[] = [
    { key: "name", label: "Display name", done: displayName.trim().length > 0 },
    { key: "tagline", label: "Tagline", done: tagline.trim().length > 0 },
    { key: "avatar", label: "Avatar photo", done: !!avatarPreview },
    { key: "cover", label: "Cover photo", done: !!coverPreview },
    { key: "category", label: "Category", done: category.trim().length > 0 },
    { key: "goal", label: "Monthly goal", done: goal.trim().length > 0 && Number(goal) > 0 },
    { key: "presets", label: "Tip preset amounts", done: presets.trim().length > 0 },
    { key: "thanks", label: "Thank-you note", done: thanksNote.trim().length > 0 },
    { key: "social", label: "At least one social link", done: Object.values(links).some((v) => (v || "").trim().length > 0) },
    { key: "location", label: "Country + city", done: country.length > 0 && city.trim().length > 0 },
    { key: "bank", label: "Payout bank details", done: bankReady },
  ];
  if (isOrg) {
    checklist.push({ key: "reg", label: "Registration number", done: regNumber.trim().length > 0 });
  }
  const doneCount = checklist.filter((c) => c.done).length;
  const pct = Math.round((doneCount / checklist.length) * 100);

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
        country,
        city: city.trim() || undefined,
        org_type: isOrg ? (orgType as "ngo" | "church" | "school" | "business" | "other" | "" | undefined) : undefined,
        registration_number: isOrg ? regNumber.trim() || undefined : undefined,
      });
      onSaved(updated);
      setAvatar(null);
      setCover(null);
      setNote("Profile saved — your public page is updated.");
      window.setTimeout(() => setNote(null), 4000);
    } catch (e) {
      setNote(e instanceof Error ? e.message : "Could not save your profile.");
    } finally {
      setBusy(false);
    }
  }

  const inputCls =
    "w-full rounded-xl border border-border bg-white px-4 py-2.5 text-sm text-ink focus:border-primary/40 focus:outline-none";
  const sectionCls = "card space-y-4 !p-5";

  const kyc = (creator.kyc_status || "").toLowerCase();
  const verifiedBadge = kyc === "verified" || (bankReady && pct >= 70);

  return (
    <div className="space-y-6">
      {/* ── Header — verification + public URL ─────────────────────── */}
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <h2 className="text-xl font-medium tracking-tight text-ink">Your public profile</h2>
          <p className="body-muted mt-1">This is what fans see on your Tipping Jar page.</p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <span
            className={`inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-semibold ${
              verifiedBadge
                ? "bg-green/10 text-green"
                : "bg-amber-500/15 text-amber-700"
            }`}
          >
            {verifiedBadge ? <ShieldCheck className="h-3.5 w-3.5" strokeWidth={2.6} /> : <Lock className="h-3.5 w-3.5" strokeWidth={2.6} />}
            {verifiedBadge ? "Verified" : "Complete your profile"}
          </span>
          {isOrg && (
            <span className="inline-flex items-center gap-1.5 rounded-full bg-primary/10 px-3 py-1 text-xs font-semibold text-primary">
              <Building2 className="h-3.5 w-3.5" strokeWidth={2.4} /> Organisation
            </span>
          )}
        </div>
      </div>

      {/* Public URL card — always visible, one-click copy + view. */}
      <div className="card flex flex-wrap items-center gap-3 !p-4">
        <span className="inline-flex items-center gap-1.5 text-xs font-mono uppercase tracking-wide text-muted">
          <Link2 className="h-3.5 w-3.5" strokeWidth={2.2} /> Your page
        </span>
        <span className="min-w-0 flex-1 truncate rounded-lg bg-darker/40 px-3 py-1.5 font-mono text-xs text-ink">
          tippingjar.co.za/creator/{creator.slug}
        </span>
        <button
          onClick={() => {
            navigator.clipboard?.writeText(publicUrl);
            setLinkCopied(true);
            window.setTimeout(() => setLinkCopied(false), 2000);
          }}
          className={`inline-flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-medium transition ${
            linkCopied ? "border-teal bg-teal text-white" : "border-border text-muted hover:border-teal hover:text-teal"
          }`}
        >
          {linkCopied ? <><Check className="h-3.5 w-3.5" strokeWidth={2.6} /> Copied</> : <><Copy className="h-3.5 w-3.5" strokeWidth={2.4} /> Copy link</>}
        </button>
        <Link
          href={`/creator/${creator.slug}`}
          target="_blank"
          className="inline-flex items-center gap-1.5 rounded-full bg-primary px-3 py-1.5 text-xs font-semibold text-white hover:opacity-90"
        >
          <ExternalLink className="h-3.5 w-3.5" strokeWidth={2.4} /> View page
        </Link>
      </div>

      <div className="grid gap-6 lg:grid-cols-[1fr_320px]">
        {/* ── Left column — form ───────────────────────────────────── */}
        <div className="space-y-6">
          {/* Cover + avatar */}
          <div className="card overflow-hidden !p-0">
            <button
              onClick={() => coverRef.current?.click()}
              className="relative block h-40 w-full bg-navy transition hover:opacity-90"
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
              {cover && (
                <span className="absolute right-3 top-3 rounded-full bg-amber-500 px-2.5 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-white">
                  Unsaved
                </span>
              )}
            </button>
            <div className="flex items-end gap-4 px-6 pb-5">
              <button
                onClick={() => avatarRef.current?.click()}
                className="relative -mt-10 h-20 w-20 shrink-0 overflow-hidden rounded-3xl bg-white ring-4 ring-white transition hover:opacity-90"
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
                {avatar && (
                  <span className="absolute -right-1 -top-1 h-3.5 w-3.5 rounded-full border-2 border-white bg-amber-500" title="Unsaved" />
                )}
              </button>
              <p className="pb-1 text-xs text-muted">
                Click the cover or avatar to change it. JPEG / PNG / WebP — images are compressed on upload.
              </p>
            </div>
            <input ref={avatarRef} type="file" accept="image/*" className="hidden"
              onChange={async (e) => { const fl = e.target.files?.[0]; if (fl) setAvatar(await compressImage(fl, 500)); e.target.value = ""; }} />
            <input ref={coverRef} type="file" accept="image/*" className="hidden"
              onChange={async (e) => { const fl = e.target.files?.[0]; if (fl) setCover(await compressImage(fl, 1400)); e.target.value = ""; }} />
          </div>

          {/* Identity */}
          <div className={sectionCls}>
            <div className="flex items-center gap-2">
              <UserRound className="h-4 w-4 text-primary" strokeWidth={2.4} />
              <p className="text-sm font-semibold text-ink">Identity</p>
            </div>
            <div className="grid gap-4 sm:grid-cols-2">
              <label className="block text-xs font-medium text-muted">
                {isOrg ? "Organisation name" : "Display name"}
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
              <input value={tagline} onChange={(e) => setTagline(e.target.value)} maxLength={140}
                placeholder={isOrg ? "One line about your mission" : "One line about what you make"} className={`${inputCls} mt-1.5`} />
              <span className="mt-1 block text-[10px] text-muted/70">{tagline.length}/140</span>
            </label>
            <label className="block text-xs font-medium text-muted">
              Monthly {isOrg ? "fundraising" : "tip"} goal (R) — powers the jar on your page
              <input value={goal} onChange={(e) => setGoal(e.target.value.replace(/[^0-9.]/g, ""))} inputMode="decimal" placeholder="e.g. 3000" className={`${inputCls} mt-1.5 max-w-[200px]`} />
            </label>
          </div>

          {/* Location */}
          <div className={sectionCls}>
            <div className="flex items-center gap-2">
              <MapPin className="h-4 w-4 text-primary" strokeWidth={2.4} />
              <p className="text-sm font-semibold text-ink">Location</p>
              <span className="text-xs text-muted">— shown on your public page, helps local fans find you</span>
            </div>
            <div className="grid gap-4 sm:grid-cols-2">
              <label className="block text-xs font-medium text-muted">
                Country
                <select value={country} onChange={(e) => setCountry(e.target.value)} className={`${inputCls} mt-1.5`}>
                  {PROFILE_COUNTRIES.map((c) => (
                    <option key={c.code} value={c.code}>{c.name}</option>
                  ))}
                </select>
              </label>
              <label className="block text-xs font-medium text-muted">
                City / town
                <input value={city} maxLength={80} onChange={(e) => setCity(e.target.value)} placeholder="e.g. Cape Town" className={`${inputCls} mt-1.5`} />
              </label>
            </div>
          </div>

          {/* Organisation details — only for org accounts */}
          {isOrg && (
            <div className={sectionCls}>
              <div className="flex items-center gap-2">
                <Building2 className="h-4 w-4 text-primary" strokeWidth={2.4} />
                <p className="text-sm font-semibold text-ink">Organisation details</p>
              </div>
              <div className="grid gap-4 sm:grid-cols-2">
                <label className="block text-xs font-medium text-muted">
                  Organisation type
                  <select value={orgType} onChange={(e) => setOrgType(e.target.value)} className={`${inputCls} mt-1.5`}>
                    {PROFILE_ORG_TYPES.map((t) => (
                      <option key={t.id} value={t.id}>{t.label}</option>
                    ))}
                  </select>
                </label>
                <label className="block text-xs font-medium text-muted">
                  Registration number
                  <input value={regNumber} maxLength={60} onChange={(e) => setRegNumber(e.target.value)}
                    placeholder="e.g. NPO 123-456 or 2024/012345/08" className={`${inputCls} mt-1.5`} />
                  <span className="mt-1 block text-[10px] text-muted/70">
                    Displayed as a small trust badge on your public page.
                  </span>
                </label>
              </div>
            </div>
          )}

          {/* Tip page */}
          <div className={sectionCls}>
            <div className="flex items-center gap-2">
              <HandCoins className="h-4 w-4 text-primary" strokeWidth={2.4} />
              <p className="text-sm font-semibold text-ink">Tip page</p>
            </div>
            <div className="grid gap-4 sm:grid-cols-2">
              <label className="block text-xs font-medium text-muted">
                Preset amounts (2–6, comma separated)
                <input value={presets} onChange={(e) => setPresets(e.target.value.replace(/[^0-9,.\s]/g, ""))} placeholder="20, 50, 100, 250" className={`${inputCls} mt-1.5`} />
                <span className="mt-1 block text-[10px] text-muted/70">Min R10 each · fans see these as quick-tip buttons.</span>
              </label>
              <label className="block text-xs font-medium text-muted">
                Thank-you note (shown after a fan pays)
                <input value={thanksNote} onChange={(e) => setThanksNote(e.target.value.slice(0, 300))}
                  placeholder="You're amazing — this keeps the lights on! 💚" className={`${inputCls} mt-1.5`} />
                <span className="mt-1 block text-[10px] text-muted/70">{thanksNote.length}/300</span>
              </label>
            </div>
          </div>

          {/* Social links */}
          <div className={sectionCls}>
            <div className="flex items-center gap-2">
              <Send className="h-4 w-4 text-primary" strokeWidth={2.4} />
              <p className="text-sm font-semibold text-ink">Social links</p>
            </div>
            <div className="grid gap-4 sm:grid-cols-2">
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

          {/* Theme */}
          <div className={sectionCls}>
            <div className="flex items-center gap-2">
              <Palette className="h-4 w-4 text-primary" strokeWidth={2.4} />
              <p className="text-sm font-semibold text-ink">Page accent colour</p>
              <span className="text-xs text-muted">— tints buttons + highlights on your public page</span>
            </div>
            <div className="flex flex-wrap items-center gap-2">
              {["", "#12A25C", "#7C3AED", "#E0A536", "#EC4899", "#2563EB", "#DC2626", "#0F766E"].map((c) => (
                <button
                  key={c || "default"}
                  onClick={() => setTheme(c)}
                  className={`h-9 w-9 rounded-full border-2 transition ${theme === c ? "border-ink scale-110" : "border-border"}`}
                  style={{ background: c || "#0F2439" }}
                  title={c || "Default"}
                />
              ))}
              <span className="ml-2 text-[11px] font-mono text-muted">{theme || "default"}</span>
            </div>
          </div>

          {/* Payout bank — the extended 5-field form we now capture at signup */}
          <div className={sectionCls}>
            <div className="flex items-center justify-between gap-2">
              <div className="flex items-center gap-2">
                <Wallet className="h-4 w-4 text-primary" strokeWidth={2.4} />
                <p className="text-sm font-semibold text-ink">Payout bank account</p>
              </div>
              <span
                className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-[11px] font-semibold ${
                  bankReady ? "bg-green/10 text-green" : "bg-amber-500/15 text-amber-700"
                }`}
              >
                <ShieldCheck className="h-3 w-3" strokeWidth={2.6} /> {bankReady ? "Ready for payout" : "Incomplete"}
              </span>
            </div>
            <p className="text-xs text-muted">
              Where we send your tips. Encrypted &amp; only shown to the payout team — never on your public page.
            </p>

            <div>
              <label className="block text-xs font-medium text-muted">
                Account holder
                <input
                  value={bank.account_name ?? ""}
                  onChange={(e) => setBank((b) => ({ ...b, account_name: e.target.value }))}
                  placeholder="Exactly as it appears on the account"
                  className={`${inputCls} mt-1.5`}
                />
              </label>
              <p className="mt-1 text-[10px] text-muted/70">Must match the name on the account or payouts may be rejected.</p>
            </div>

            <div className="grid gap-4 sm:grid-cols-2">
              <label className="block text-xs font-medium text-muted">
                Bank
                <select
                  value={bank.bank ?? ""}
                  onChange={(e) => {
                    const v = e.target.value;
                    setBank((b) => {
                      const next: Record<string, string> = { ...b, bank: v };
                      const found = PROFILE_SA_BANKS.find((x) => x.name === v);
                      if (found && found.code && !(b.branch_code || "").trim()) next.branch_code = found.code;
                      return next;
                    });
                  }}
                  className={`${inputCls} mt-1.5`}
                >
                  <option value="">Select your bank…</option>
                  {PROFILE_SA_BANKS.map((b) => (
                    <option key={b.name} value={b.name}>{b.name}</option>
                  ))}
                </select>
              </label>
              <label className="block text-xs font-medium text-muted">
                Account type
                <select
                  value={bank.account_type ?? "cheque"}
                  onChange={(e) => setBank((b) => ({ ...b, account_type: e.target.value }))}
                  className={`${inputCls} mt-1.5`}
                >
                  {PROFILE_ACCOUNT_TYPES.map((t) => (
                    <option key={t.id} value={t.id}>{t.label}</option>
                  ))}
                </select>
              </label>
            </div>

            <div className="grid gap-4 sm:grid-cols-[1fr_180px]">
              <label className="block text-xs font-medium text-muted">
                Account number
                <input
                  value={bank.account_no ?? ""}
                  inputMode="numeric"
                  maxLength={20}
                  onChange={(e) => setBank((b) => ({ ...b, account_no: e.target.value.replace(/[^\d\s]/g, "") }))}
                  placeholder="e.g. 12345678901"
                  className={`${inputCls} mt-1.5`}
                />
              </label>
              <label className="block text-xs font-medium text-muted">
                Branch code
                <input
                  value={bank.branch_code ?? ""}
                  inputMode="numeric"
                  maxLength={10}
                  onChange={(e) => setBank((b) => ({ ...b, branch_code: e.target.value.replace(/[^\d\s]/g, "") }))}
                  placeholder="Universal"
                  className={`${inputCls} mt-1.5`}
                />
              </label>
            </div>
          </div>
        </div>

        {/* ── Right column — completion + live preview ─────────────── */}
        <div className="space-y-4 lg:sticky lg:top-24 lg:self-start">
          {/* Completion meter */}
          <div className="card !p-4">
            <div className="flex items-baseline justify-between">
              <p className="text-xs font-semibold uppercase tracking-wide text-muted">Profile complete</p>
              <span className={`text-lg font-extrabold ${pct >= 80 ? "text-green" : pct >= 40 ? "text-amber-600" : "text-muted"}`}>
                {pct}%
              </span>
            </div>
            <div className="mt-2 h-2 w-full overflow-hidden rounded-full bg-darker/40">
              <div
                className="h-full rounded-full bg-green transition-all"
                style={{ width: `${pct}%` }}
              />
            </div>
            <ul className="mt-4 space-y-1.5 text-xs">
              {checklist.map((c) => (
                <li key={c.key} className="flex items-center gap-2">
                  {c.done ? (
                    <CircleCheck className="h-3.5 w-3.5 shrink-0 text-green" strokeWidth={2.6} />
                  ) : (
                    <span className="h-3.5 w-3.5 shrink-0 rounded-full border-2 border-border" />
                  )}
                  <span className={c.done ? "text-ink" : "text-muted"}>{c.label}</span>
                </li>
              ))}
            </ul>
          </div>

          {/* Live preview */}
          <div className="card overflow-hidden !p-0">
            <p className="border-b border-border px-4 py-2 text-[10px] font-mono uppercase tracking-wide text-muted">
              Live preview
            </p>
            <div className="relative h-16" style={{ background: theme || "#0F2439" }}>
              {coverPreview && (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={coverPreview} alt="" className="absolute inset-0 h-full w-full object-cover" />
              )}
            </div>
            <div className="flex items-start gap-3 px-4 pb-4">
              <div className="-mt-6 h-12 w-12 shrink-0 overflow-hidden rounded-2xl ring-2 ring-white">
                {avatarPreview ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={avatarPreview} alt="" className="h-full w-full object-cover" />
                ) : (
                  <span className="grid h-full w-full place-items-center bg-primary text-sm font-bold text-white">
                    {(displayName || creator.display_name || "T").charAt(0)}
                  </span>
                )}
              </div>
              <div className="min-w-0 pt-1">
                <p className="truncate text-sm font-bold text-ink">{displayName || "Your name"}</p>
                {(category || city) && (
                  <p className="mt-0.5 truncate text-[11px] text-muted">
                    {[category, city].filter(Boolean).join(" · ")}
                  </p>
                )}
                <p className="mt-1.5 line-clamp-2 text-xs text-muted">{tagline || "Your tagline will appear here."}</p>
              </div>
            </div>
            {Object.values(links).some((v) => (v || "").trim().length > 0) && (
              <div className="flex flex-wrap gap-1 border-t border-border px-4 py-2">
                {(Object.entries(links) as [string, string][])
                  .filter(([, v]) => (v || "").trim().length > 0)
                  .slice(0, 4)
                  .map(([k]) => (
                    <span key={k} className="rounded-full bg-darker/40 px-2 py-0.5 text-[10px] font-medium capitalize text-muted">
                      {k === "twitter" ? "X" : k}
                    </span>
                  ))}
              </div>
            )}
          </div>

          {/* Danger-ish hints */}
          <div className="rounded-2xl border border-border/60 bg-primary/5 p-3 text-[11px] text-muted">
            <p className="font-semibold text-ink">Tip</p>
            <p className="mt-1">
              A complete profile with cover, avatar, tagline and preset amounts earns 2–3× more per visit than a barebones one.
            </p>
          </div>
        </div>
      </div>

      {/* ── Sticky save bar ──────────────────────────────────────────── */}
      <div className="sticky bottom-4 z-30 flex flex-wrap items-center gap-3 rounded-2xl border border-border bg-white/95 p-3 shadow-lift backdrop-blur">
        <button onClick={save} disabled={busy} className="btn-primary !px-6 !py-2.5 text-sm disabled:opacity-50">
          {busy ? "Saving…" : "Save profile"}
        </button>
        <Link href={`/creator/${creator.slug}`} target="_blank" className="text-sm text-muted hover:text-ink">
          View public page <ArrowUpRight className="inline h-3.5 w-3.5" strokeWidth={2.4} />
        </Link>
        {(avatar || cover) && (
          <span className="rounded-full bg-amber-500/15 px-2.5 py-0.5 text-xs font-semibold text-amber-700">
            Unsaved image changes
          </span>
        )}
        {note && <p className="ml-auto text-sm text-teal">{note}</p>}
      </div>
    </div>
  );
}


// ─── Exclusive posts ─────────────────────────────────────────────────────────
// Ready-to-remix post ideas so creators aren't staring at a blank field.
const POST_TEMPLATES: { label: string; title: string; body: string }[] = [
  {
    label: "🎁 Behind the scenes",
    title: "Behind the scenes: what I've been working on",
    body: "A quick peek at what's been happening this month — the wins, the mess, the surprises. Thanks for making it possible 💚",
  },
  {
    label: "🎵 Unreleased track",
    title: "Unreleased track — supporter preview",
    body: "This one's been on my mind for weeks. Not out yet, but you get to hear it first.\n\nDownload link: [paste here]\nPassword: [optional]",
  },
  {
    label: "📸 Photo dump",
    title: "Photo dump — this month's outtakes",
    body: "The photos that didn't make the grid — but I love them all. Enjoy!",
  },
  {
    label: "🎟️ Early access",
    title: "Early access: [event / product / drop]",
    body: "You're on the list. Redemption code: [XXXX-XXXX]\nExpires: [date]\n\nThanks for backing me — this is the smallest way I can say it.",
  },
  {
    label: "📝 Long form",
    title: "A note from me…",
    body: "I wanted to write this properly, just for you. Here's what's been on my mind…",
  },
];

// Extract a YouTube video id from a URL, then build the thumbnail URL.
function youtubeThumb(url: string): string | null {
  const m = url.match(/(?:youtube\.com\/(?:watch\?v=|embed\/)|youtu\.be\/)([\w-]{6,})/);
  return m ? `https://img.youtube.com/vi/${m[1]}/hqdefault.jpg` : null;
}

const KIND_META: Record<string, { emoji: string; label: string; color: string }> = {
  post:    { emoji: "📝", label: "Post",    color: "#2563EB" },
  video:   { emoji: "🎥", label: "Video",   color: "#DC2626" },
  audio:   { emoji: "🎧", label: "Audio",   color: "#7C3AED" },
  gallery: { emoji: "🖼", label: "Gallery", color: "#E0A536" },
};

function ExclusiveTab({ token, hasProfile, slug }: { token: string | null; hasProfile: boolean; slug: string | null }) {
  const [posts, setPosts] = useState<ExclusivePost[] | null>(null);
  const [tiers, setTiers] = useState<SupportTier[]>([]);
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [image, setImage] = useState<string | null>(null);
  const [kind, setKind] = useState<"post" | "video" | "audio" | "gallery">("post");
  const [mediaUrl, setMediaUrl] = useState("");
  const [access, setAccess] = useState<"monthly_tip" | "subscription" | "public">("monthly_tip");
  const [minTip, setMinTip] = useState("10");
  const [tierId, setTierId] = useState<string | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [note, setNote] = useState<string | null>(null);
  const [q, setQ] = useState("");
  const [scope, setScope] = useState<"all" | "month">("all");
  const [kindFilter, setKindFilter] = useState<"all" | "post" | "video" | "audio" | "gallery">("all");
  const [accessFilter, setAccessFilter] = useState<"all" | "monthly_tip" | "subscription" | "public">("all");
  const [sortNewest, setSortNewest] = useState(true);
  const [dragOver, setDragOver] = useState(false);
  const [linkCopied, setLinkCopied] = useState(false);
  const [expanded, setExpanded] = useState<string | null>(null);
  const imgRef = useRef<HTMLInputElement>(null);

  function resetDraft() {
    setTitle(""); setBody(""); setImage(null); setMediaUrl("");
    setKind("post"); setAccess("monthly_tip"); setMinTip("10"); setTierId(null);
    setEditingId(null);
  }
  function startEdit(p: ExclusivePost) {
    setEditingId(p.id);
    setTitle(p.title);
    setBody(p.body);
    setImage(p.image_url || null);
    setKind((p.kind as typeof kind) || "post");
    setMediaUrl(p.media_url || "");
    setAccess((p.access === "one_tip" ? "monthly_tip" : (p.access as typeof access)) || "monthly_tip");
    setMinTip(String(Number(p.min_tip) || 10));
    setTierId(p.tier_id ?? null);
    document.getElementById("exclusive-title")?.focus();
    document.getElementById("exclusive-title")?.scrollIntoView({ behavior: "smooth", block: "center" });
  }
  async function duplicate(p: ExclusivePost) {
    if (!token) return;
    try {
      await api.createPost(token, {
        title: `${p.title} (copy)`,
        body: p.body,
        image_url: p.image_url || undefined,
        kind: p.kind as "post" | "video" | "audio" | "gallery",
        media_url: p.media_url || undefined,
        access: p.access as "monthly_tip" | "subscription" | "one_tip" | "public",
        min_tip: Number(p.min_tip) || 10,
        tier_id: p.tier_id ?? undefined,
      });
      load();
      setNote(`Duplicated "${p.title}".`);
    } catch (e) {
      setNote(e instanceof Error ? e.message : "Could not duplicate.");
    }
  }

  const load = useCallback(() => {
    if (!token) return;
    api.myPosts(token).then(setPosts).catch(() => setPosts([]));
    api.myTiers(token).then(setTiers).catch(() => setTiers([]));
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
      const body_data = {
        title: title.trim(),
        body: body.trim(),
        image_url: image ?? "",
        kind,
        media_url: mediaUrl.trim(),
        access,
        min_tip: access === "monthly_tip" ? Math.max(10, Number(minTip) || 10) : 10,
        tier_id: access === "subscription" ? (tierId ?? undefined) : undefined,
      };
      if (editingId) {
        await api.updatePost(token, editingId, body_data);
        setNote("Updated — supporters see the new version now.");
      } else {
        await api.createPost(token, body_data);
        setNote("Published — supporters with matching access can see it now.");
      }
      resetDraft();
      load();
    } catch (e) {
      setNote(e instanceof Error ? e.message : "Could not save.");
    } finally {
      setBusy(false);
    }
  }

  async function onDropFile(e: React.DragEvent<HTMLDivElement>) {
    e.preventDefault();
    setDragOver(false);
    const fl = e.dataTransfer.files?.[0];
    if (fl && fl.type.startsWith("image/")) setImage(await compressImage(fl, 1200));
  }

  const now = Date.now();
  const monthAgo = now - 30 * 86400000;
  const filtered = (posts ?? [])
    .filter((p) => {
      if (scope === "month" && +new Date(p.created_at) < monthAgo) return false;
      if (kindFilter !== "all" && p.kind !== kindFilter) return false;
      if (accessFilter !== "all" && p.access !== accessFilter) return false;
      if (q) {
        const needle = q.toLowerCase();
        if (!p.title.toLowerCase().includes(needle) && !(p.body || "").toLowerCase().includes(needle)) return false;
      }
      return true;
    })
    .sort((a, b) => (sortNewest ? +new Date(b.created_at) - +new Date(a.created_at) : +new Date(a.created_at) - +new Date(b.created_at)));

  const total = posts?.length ?? 0;
  const thisMonth = (posts ?? []).filter((p) => +new Date(p.created_at) >= monthAgo).length;
  const withImage = (posts ?? []).filter((p) => p.image_url).length;
  const latest = posts?.[0]?.created_at;
  const daysSinceLast = latest ? Math.floor((now - +new Date(latest)) / 86400000) : null;
  const vaultUrl = slug ? `https://www.tippingjar.co.za/creator/${slug}` : "";

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h2 className="text-xl font-medium tracking-tight text-ink">Exclusive content</h2>
          <p className="body-muted mt-1">
            Fans who tipped you <span className="font-medium text-ink">this month</span> (R10+, with their email) unlock these on your page.
            A fresh reason to tip, every month.
          </p>
        </div>
        {slug && (
          <button
            onClick={() => {
              navigator.clipboard?.writeText(vaultUrl);
              setLinkCopied(true);
              window.setTimeout(() => setLinkCopied(false), 1800);
            }}
            className={`inline-flex items-center gap-1.5 rounded-full border px-4 py-2 text-xs font-medium transition ${
              linkCopied ? "border-teal bg-teal text-white" : "border-border bg-white text-muted hover:border-teal hover:text-teal"
            }`}
          >
            {linkCopied ? <><Check className="h-3.5 w-3.5" strokeWidth={2.6} /> Vault link copied</> : <><Copy className="h-3.5 w-3.5" strokeWidth={2.2} /> Copy vault link</>}
          </button>
        )}
      </div>

      {/* KPIs */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Total posts" value={String(total)} icon={Lock} accent="#7C3AED" />
        <StatCard label="Published this month" value={String(thisMonth)} icon={Calendar} accent="#12A25C" />
        <StatCard label="With image" value={String(withImage)} icon={QrCode} accent="#E0A536" />
        <StatCard
          label="Days since last post"
          value={daysSinceLast === null ? "—" : String(daysSinceLast)}
          icon={Zap}
          accent={daysSinceLast !== null && daysSinceLast > 30 ? "#DC2626" : "#2563EB"}
        />
      </div>

      {/* Nudge if it's been a while */}
      {daysSinceLast !== null && daysSinceLast > 30 && (
        <div className="card flex items-center gap-3 !p-4 !border-amber-500/40 bg-amber-500/5">
          <span className="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-amber-500/15 text-amber-600">
            <Zap className="h-4 w-4" strokeWidth={2.4} />
          </span>
          <p className="text-sm text-ink">
            It&apos;s been <span className="font-semibold">{daysSinceLast} days</span> since your last post. Fresh drops keep supporters coming back —
            {" "}<button onClick={() => (document.getElementById("exclusive-title") as HTMLInputElement | null)?.focus()} className="font-semibold text-teal hover:underline">write a quick update</button>.
          </p>
        </div>
      )}

      {/* Composer + live preview side-by-side on xl+ */}
      <div className="grid gap-6 xl:grid-cols-[1fr_360px]">
      {/* Composer */}
      <div className="card space-y-4 !p-5">
        {editingId && (
          <div className="flex items-center gap-3 rounded-xl border border-teal/40 bg-teal/5 px-4 py-2 text-xs">
            <span className="font-semibold text-teal">Editing existing post</span>
            <button onClick={resetDraft} className="ml-auto text-muted hover:text-red-500">
              Cancel edit
            </button>
          </div>
        )}
        {/* Template chips */}
        <div className="flex flex-wrap gap-2">
          <span className="mr-1 text-xs font-semibold uppercase tracking-wide text-muted">Templates</span>
          {POST_TEMPLATES.map((t) => (
            <button
              key={t.label}
              onClick={() => { setTitle(t.title); setBody(t.body); }}
              className="rounded-full border border-border px-3 py-1 text-xs font-medium text-muted transition hover:border-teal hover:text-teal"
            >
              {t.label}
            </button>
          ))}
          {(title || body) && (
            <button
              onClick={() => { setTitle(""); setBody(""); setImage(null); }}
              className="ml-auto text-xs font-medium text-muted hover:text-red-500"
            >
              Clear
            </button>
          )}
        </div>

        {/* Kind switcher */}
        <div>
          <p className="mb-1.5 text-xs font-semibold uppercase tracking-wide text-muted">Content type</p>
          <div className="flex flex-wrap gap-1.5">
            {([
              ["post", "📝 Post"],
              ["video", "🎥 Video"],
              ["audio", "🎧 Audio"],
              ["gallery", "🖼 Gallery"],
            ] as const).map(([id, label]) => (
              <button
                key={id}
                onClick={() => setKind(id)}
                className={`rounded-full px-3.5 py-1.5 text-xs font-medium transition ${
                  kind === id ? "bg-primary text-white" : "border border-border text-muted hover:text-ink"
                }`}
              >
                {label}
              </button>
            ))}
          </div>
        </div>

        <div>
          <input
            id="exclusive-title"
            value={title}
            maxLength={120}
            onChange={(e) => setTitle(e.target.value)}
            placeholder={
              kind === "video" ? "Video title — e.g. Studio tour"
              : kind === "audio" ? "Audio title — e.g. Unreleased demo"
              : kind === "gallery" ? "Gallery title — e.g. This month's outtakes"
              : "Post title — e.g. Behind the scenes"
            }
            className="w-full rounded-xl border border-border bg-white px-4 py-2.5 text-sm text-ink focus:border-primary/40 focus:outline-none"
          />
          <p className="mt-1 text-right font-mono text-[10px] text-muted">{title.length}/120</p>
        </div>

        {(kind === "video" || kind === "audio") && (
          <div>
            <label className="text-xs font-semibold uppercase tracking-wide text-muted">
              {kind === "video" ? "Video URL" : "Audio URL"}
            </label>
            <input
              value={mediaUrl}
              onChange={(e) => setMediaUrl(e.target.value)}
              placeholder={
                kind === "video"
                  ? "YouTube, Vimeo, or a direct .mp4 URL"
                  : "Direct .mp3 / .wav URL"
              }
              className="mt-1.5 w-full rounded-xl border border-border bg-white px-4 py-2.5 text-sm text-ink focus:border-primary/40 focus:outline-none"
            />
            <p className="mt-1 text-[11px] text-muted">
              {kind === "video"
                ? "YouTube and Vimeo embed automatically. Upload to Vimeo/YouTube as Unlisted for privacy."
                : "Host on SoundCloud (direct link) or your own storage. The vault renders a native audio player."}
            </p>
          </div>
        )}

        <div>
          <textarea
            value={body}
            maxLength={5000}
            onChange={(e) => setBody(e.target.value)}
            rows={6}
            placeholder="The content — behind-the-scenes notes, download links, early-access codes…"
            className="w-full rounded-xl border border-border bg-white px-4 py-2.5 text-sm text-ink focus:border-primary/40 focus:outline-none"
          />
          <p className="mt-1 text-right font-mono text-[10px] text-muted">{body.length.toLocaleString()}/5,000</p>
        </div>

        {/* Drag-and-drop image */}
        <div
          onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
          onDragLeave={() => setDragOver(false)}
          onDrop={onDropFile}
          onClick={() => imgRef.current?.click()}
          className={`grid cursor-pointer place-items-center rounded-xl border-2 border-dashed p-4 text-center transition ${
            dragOver ? "border-teal bg-teal/5" : "border-border bg-darker/40 hover:border-teal/50"
          }`}
        >
          {image ? (
            <div className="flex w-full items-center gap-4">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={image} alt="" className="h-20 w-20 shrink-0 rounded-lg object-cover" />
              <div className="min-w-0 flex-1 text-left">
                <p className="text-sm font-medium text-ink">Image attached</p>
                <p className="text-xs text-muted">Click to swap · drop a new one to replace</p>
              </div>
              <button
                onClick={(e) => { e.stopPropagation(); setImage(null); }}
                className="text-xs font-medium text-muted hover:text-red-500"
              >
                Remove
              </button>
            </div>
          ) : (
            <>
              <QrCode className="h-6 w-6 text-muted" strokeWidth={2} />
              <p className="mt-2 text-sm font-medium text-ink">Drop an image, or click to choose one</p>
              <p className="text-xs text-muted">JPEG / PNG · auto-compressed to fit</p>
            </>
          )}
          <input
            ref={imgRef}
            type="file"
            accept="image/*"
            className="hidden"
            onChange={async (e) => { const fl = e.target.files?.[0]; if (fl) setImage(await compressImage(fl, 1200)); e.target.value = ""; }}
          />
        </div>

        {/* Access controls */}
        <div className="rounded-xl border border-border bg-darker/40 p-4">
          <p className="text-xs font-semibold uppercase tracking-wide text-muted">Who can see this?</p>
          <div className="mt-2 flex flex-wrap gap-1.5">
            {([
              ["monthly_tip", "💚 Monthly tippers"],
              ["subscription", "⭐ Subscribers only"],
              ["public", "🌍 Public"],
            ] as const).map(([id, label]) => (
              <button
                key={id}
                onClick={() => setAccess(id)}
                className={`rounded-full px-3.5 py-1.5 text-xs font-medium transition ${
                  access === id ? "bg-primary text-white" : "border border-border text-muted hover:text-ink"
                }`}
              >
                {label}
              </button>
            ))}
          </div>
          {access === "monthly_tip" && (
            <div className="mt-3 flex items-center gap-2 text-sm">
              <label className="text-xs text-muted">Minimum tip this month:</label>
              <span className="font-mono text-ink">R</span>
              <input
                value={minTip}
                onChange={(e) => setMinTip(e.target.value.replace(/[^0-9.]/g, ""))}
                inputMode="decimal"
                className="w-20 rounded border border-border bg-white px-2 py-1 text-sm text-ink focus:border-primary/40 focus:outline-none"
              />
            </div>
          )}
          {access === "subscription" && (
            <div className="mt-3">
              {tiers.length === 0 ? (
                <p className="text-xs text-red-500">
                  You don&apos;t have any support tiers yet — this post will be locked to nobody.
                  Create a tier first.
                </p>
              ) : (
                <div className="flex flex-wrap gap-2">
                  {tiers.map((t) => (
                    <button
                      key={t.id}
                      onClick={() => setTierId(t.id)}
                      className={`rounded-full px-3 py-1.5 text-xs font-medium transition ${
                        tierId === t.id ? "bg-primary text-white" : "border border-border text-muted hover:text-ink"
                      }`}
                    >
                      {t.name} · R{Number(t.price).toFixed(0)}
                    </button>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>

        <div className="flex flex-wrap items-center gap-3 border-t border-border pt-4">
          <p className="text-xs text-muted">
            <Lock className="mr-1 inline-block h-3 w-3" strokeWidth={2.4} />
            {access === "monthly_tip"
              ? `Locked to fans who tipped R${minTip || 10}+ this month`
              : access === "subscription"
                ? tierId
                  ? `Locked to subscribers of "${tiers.find((t) => t.id === tierId)?.name}"`
                  : "Pick a tier"
                : "Public — anyone with the vault link can view"}
          </p>
          <button
            onClick={publish}
            disabled={busy || !title.trim() || (access === "subscription" && !tierId)}
            className="btn-primary ml-auto !px-6 !py-2.5 text-sm disabled:opacity-50"
          >
            {busy ? "Saving…" : editingId ? "Update post" : "Publish to the vault"}
          </button>
        </div>
        {note && <p className="text-sm text-teal">{note}</p>}
      </div>

      {/* Live preview */}
      <div className="card !p-0 xl:sticky xl:top-24 xl:self-start">
        <div className="border-b border-border px-4 py-3">
          <p className="text-xs font-semibold uppercase tracking-wide text-muted">Vault preview</p>
        </div>
        <div className="p-4">
          {!title.trim() && !body.trim() && !mediaUrl && !image ? (
            <p className="body-muted text-sm">Fill in the composer to see how supporters will see this.</p>
          ) : (
            <article>
              <p className="text-[11px] font-mono uppercase tracking-[0.14em] text-muted">
                {KIND_META[kind].emoji} {KIND_META[kind].label}
                {access === "monthly_tip" && Number(minTip) > 10 && <> · min tip R{Math.max(10, Number(minTip) || 10)}</>}
                {access === "subscription" && tierId && <> · Subscribers of {tiers.find((t) => t.id === tierId)?.name}</>}
                {access === "public" && <> · Public</>}
              </p>
              <h3 className="mt-1 font-display text-lg font-bold text-ink">{title || "Post title"}</h3>
              {kind === "video" && (() => {
                const thumb = youtubeThumb(mediaUrl);
                return thumb ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={thumb} alt="" className="mt-3 aspect-video w-full rounded-lg object-cover" />
                ) : mediaUrl ? (
                  <div className="mt-3 grid aspect-video w-full place-items-center rounded-lg bg-black/90 text-4xl text-white">🎥</div>
                ) : (
                  <div className="mt-3 grid aspect-video w-full place-items-center rounded-lg border-2 border-dashed border-border text-xs text-muted">Paste a video URL</div>
                );
              })()}
              {kind === "audio" && (
                <div className="mt-3 flex items-center gap-3 rounded-lg bg-darker/50 px-4 py-3">
                  <span className="text-2xl">🎧</span>
                  <p className="min-w-0 flex-1 truncate text-xs text-muted">{mediaUrl || "Paste an audio URL"}</p>
                </div>
              )}
              {image && (kind === "post" || kind === "gallery") && (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={image} alt="" className="mt-3 max-h-64 w-full rounded-lg object-cover" />
              )}
              {body && <p className="mt-3 whitespace-pre-wrap text-xs text-muted line-clamp-6">{body}</p>}
            </article>
          )}
        </div>
      </div>
      </div>

      {/* Filter row */}
      {posts && posts.length > 0 && (
        <div className="card flex flex-wrap items-center gap-3 !p-4">
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Search posts…"
            className="w-full max-w-xs rounded-full border border-border bg-white px-4 py-2 text-sm text-ink focus:border-primary/40 focus:outline-none"
          />
          <div className="flex flex-wrap gap-1.5">
            {(["all", "month"] as const).map((s) => (
              <button
                key={s}
                onClick={() => setScope(s)}
                className={`rounded-full px-3 py-1.5 text-xs font-medium transition ${
                  scope === s ? "bg-primary text-white" : "border border-border text-muted hover:text-ink"
                }`}
              >
                {s === "all" ? "All time" : "This month"}
              </button>
            ))}
          </div>
          <span className="mx-1 h-5 w-px bg-border" />
          <div className="flex flex-wrap gap-1.5">
            {(["all", "post", "video", "audio", "gallery"] as const).map((k) => (
              <button
                key={k}
                onClick={() => setKindFilter(k)}
                className={`rounded-full px-3 py-1.5 text-xs font-medium transition ${
                  kindFilter === k ? "bg-primary text-white" : "border border-border text-muted hover:text-ink"
                }`}
              >
                {k === "all" ? "Any kind" : `${KIND_META[k].emoji} ${KIND_META[k].label}`}
              </button>
            ))}
          </div>
          <span className="mx-1 h-5 w-px bg-border" />
          <div className="flex flex-wrap gap-1.5">
            {(["all", "monthly_tip", "subscription", "public"] as const).map((a) => (
              <button
                key={a}
                onClick={() => setAccessFilter(a)}
                className={`rounded-full px-3 py-1.5 text-xs font-medium transition ${
                  accessFilter === a ? "bg-primary text-white" : "border border-border text-muted hover:text-ink"
                }`}
              >
                {a === "all" ? "Any access" : a === "monthly_tip" ? "💚 Tippers" : a === "subscription" ? "⭐ Subs" : "🌍 Public"}
              </button>
            ))}
          </div>
          <span className="mx-1 h-5 w-px bg-border" />
          <button
            onClick={() => setSortNewest((v) => !v)}
            className="rounded-full border border-border px-3 py-1.5 text-xs font-medium text-muted transition hover:text-ink"
          >
            Sort · {sortNewest ? "Newest" : "Oldest"}
          </button>
          <span className="ml-auto text-xs text-muted">Showing {filtered.length} of {posts.length}</span>
        </div>
      )}

      {/* Posts grid */}
      {!posts ? (
        <p className="body-muted">Loading…</p>
      ) : posts.length === 0 ? (
        <EmptyState icon={Lock} title="Nothing in the vault yet" body="Pick a template above and publish your first exclusive post." />
      ) : filtered.length === 0 ? (
        <EmptyState icon={Lock} title="No posts match" body="Try clearing your search or widening the scope." />
      ) : (
        <div className="grid gap-4 sm:grid-cols-2">
          {filtered.map((p) => {
            const isOpen = expanded === p.id;
            return (
            <div key={p.id} className={`card overflow-hidden !p-0 ${editingId === p.id ? "!border-teal ring-2 ring-teal/20" : ""}`}>
              {(() => {
                const cover = p.image_url || (p.kind === "video" ? youtubeThumb(p.media_url) : null);
                return cover ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <div className="relative">
                    <img src={cover} alt="" className="h-40 w-full object-cover" />
                    {p.kind === "video" && (
                      <span className="absolute inset-0 grid place-items-center bg-black/30 text-3xl text-white">▶</span>
                    )}
                  </div>
                ) : p.kind === "audio" ? (
                  <div className="flex h-24 items-center gap-3 bg-gradient-to-r from-purple-500/10 to-purple-500/5 px-5">
                    <span className="text-2xl">🎧</span>
                    <p className="min-w-0 flex-1 truncate text-xs text-muted">{p.media_url || "No source URL"}</p>
                  </div>
                ) : null;
              })()}
              <div className="space-y-2 p-5">
                <div className="flex items-start justify-between gap-2">
                  <p className="font-medium text-ink">{p.title}</p>
                  <div className="flex shrink-0 gap-1">
                    <span className="rounded-full bg-primary/10 px-2 py-0.5 text-[10px] font-medium text-primary">
                      {p.kind === "video" ? "🎥" : p.kind === "audio" ? "🎧" : p.kind === "gallery" ? "🖼" : "📝"} {p.kind}
                    </span>
                    <span className="rounded-full bg-mint/15 px-2 py-0.5 text-[10px] font-medium text-green">
                      <Lock className="mr-1 inline h-2.5 w-2.5" strokeWidth={2.6} />
                      {p.access === "subscription" ? "Subs" : p.access === "public" ? "Public" : `R${Number(p.min_tip) || 10}+`}
                    </span>
                  </div>
                </div>
                {p.body && (
                  <p className={`text-sm text-muted whitespace-pre-wrap ${isOpen ? "" : "line-clamp-3"}`}>{p.body}</p>
                )}
                {p.body && p.body.length > 160 && (
                  <button
                    onClick={() => setExpanded(isOpen ? null : p.id)}
                    className="text-[11px] font-medium text-teal hover:underline"
                  >
                    {isOpen ? "Show less" : "Read more"}
                  </button>
                )}
                <div className="flex items-center justify-between gap-2 pt-1">
                  <p className="font-mono text-[11px] text-muted">
                    {new Date(p.created_at).toLocaleDateString("en-ZA", { day: "numeric", month: "short", year: "numeric" })}
                  </p>
                  <div className="flex items-center gap-1">
                    <button
                      onClick={() => startEdit(p)}
                      className="rounded-full border border-border px-2.5 py-1 text-[11px] font-medium text-muted hover:border-teal hover:text-teal"
                      title="Edit post"
                    >
                      Edit
                    </button>
                    <button
                      onClick={() => duplicate(p)}
                      className="rounded-full border border-border px-2.5 py-1 text-[11px] font-medium text-muted hover:border-teal hover:text-teal"
                      title="Duplicate"
                    >
                      <Copy className="inline h-3 w-3" strokeWidth={2.4} />
                    </button>
                    {slug && (
                      <button
                        onClick={() => {
                          navigator.clipboard?.writeText(`${vaultUrl}?post=${p.id}`);
                          setNote("Post link copied — supporters see it after unlocking the vault.");
                          window.setTimeout(() => setNote(null), 2000);
                        }}
                        className="rounded-full border border-border px-2.5 py-1 text-[11px] font-medium text-muted hover:border-teal hover:text-teal"
                        title="Copy a link to this post"
                      >
                        Link
                      </button>
                    )}
                    <button
                      onClick={async () => {
                        if (!token || !window.confirm(`Delete "${p.title}"?`)) return;
                        await api.deletePost(token, p.id).catch(() => null);
                        load();
                      }}
                      className="rounded-full border border-red-200 px-2.5 py-1 text-[11px] font-medium text-red-500 hover:bg-red-50"
                      title="Delete post"
                    >
                      <X className="inline h-3 w-3" strokeWidth={2.4} />
                    </button>
                  </div>
                </div>
              </div>
            </div>
            );
          })}
        </div>
      )}
    </div>
  );
}


// ─── Jars (campaign funds) ───────────────────────────────────────────────────
// Popular jar patterns creators reach for.
const JAR_TEMPLATES = [
  { emoji: "🎙️", name: "New microphone",   goal: 2500, desc: "Upgrading my setup for cleaner recordings." },
  { emoji: "🎧", name: "Studio day",        goal: 1500, desc: "A full day in a proper studio." },
  { emoji: "💻", name: "New laptop",        goal: 15000, desc: "The old one's on its last legs." },
  { emoji: "🎨", name: "New art supplies",  goal: 800,  desc: "Paints, canvases, brushes for the next series." },
  { emoji: "✈️", name: "Tour fund",         goal: 8000, desc: "Getting on the road to meet you all." },
  { emoji: "📚", name: "Course/workshop",   goal: 3500, desc: "Levelling up my craft." },
];

function ProgressRing({ pct, size = 56 }: { pct: number; size?: number }) {
  const r = size / 2 - 6;
  const c = 2 * Math.PI * r;
  const off = c * (1 - Math.max(0, Math.min(1, pct / 100)));
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} className="-rotate-90">
      <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="#EFF2F0" strokeWidth="4" />
      <circle
        cx={size / 2} cy={size / 2} r={r} fill="none" stroke="#12A25C" strokeWidth="4"
        strokeLinecap="round" strokeDasharray={c} strokeDashoffset={off}
      />
    </svg>
  );
}

async function downloadJarQr(link: string, name: string) {
  const QRCode = (await import("qrcode")).default;
  const qr = await QRCode.toDataURL(link, { width: 480, margin: 1, color: { dark: "#0F2439", light: "#FFFFFF" } });
  const W = 720, H = 900;
  const c = document.createElement("canvas");
  c.width = W; c.height = H;
  const ctx = c.getContext("2d")!;
  const g = ctx.createLinearGradient(0, 0, W, H);
  g.addColorStop(0, "#0F2439"); g.addColorStop(1, "#12A25C");
  ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  ctx.fillStyle = "#FFFFFF";
  ctx.textAlign = "center";
  ctx.font = "bold 34px Manrope, system-ui, sans-serif";
  ctx.fillText("🫙 " + name, W / 2, 96);
  ctx.font = "500 22px Manrope, system-ui, sans-serif";
  ctx.fillStyle = "#57CE8B";
  ctx.fillText("Scan to tip into this jar", W / 2, 138);
  const qs = 420, qx = (W - qs) / 2, qy = 200;
  ctx.fillStyle = "#FFFFFF";
  ctx.beginPath();
  ctx.roundRect(qx - 24, qy - 24, qs + 48, qs + 48, 32);
  ctx.fill();
  const img = new Image();
  await new Promise<void>((res) => { img.onload = () => res(); img.src = qr; });
  ctx.drawImage(img, qx, qy, qs, qs);
  ctx.fillStyle = "#FFFFFF";
  ctx.font = "500 20px 'Space Mono', monospace";
  ctx.fillText(link.replace(/^https?:\/\//, ""), W / 2, qy + qs + 88);
  const a = document.createElement("a");
  a.href = c.toDataURL("image/png");
  a.download = `jar-${name.replace(/\W+/g, "-").toLowerCase()}.png`;
  a.click();
}

function JarsTab({ token, creator }: { token: string | null; creator: Creator | null }) {
  const [jars, setJars] = useState<Jar[] | null>(null);
  const [stats, setStats] = useState<Map<string, { raised: number; count: number }>>(new Map());
  const [name, setName] = useState("");
  const [goal, setGoal] = useState("");
  const [desc, setDesc] = useState("");
  const [busy, setBusy] = useState(false);
  const [note, setNote] = useState<string | null>(null);
  const [q, setQ] = useState("");
  const [showCompleted, setShowCompleted] = useState(false);
  const [copiedFor, setCopiedFor] = useState<string | null>(null);

  const load = useCallback(() => {
    if (!creator) return;
    api.getJars(creator.slug).then(async (js) => {
      setJars(js);
      const m = new Map<string, { raised: number; count: number }>();
      await Promise.all(
        js.map(async (j) => {
          try {
            const s = await api.jarStats(j.id);
            m.set(j.id, { raised: Number(s.raised) || 0, count: s.count });
          } catch { m.set(j.id, { raised: 0, count: 0 }); }
        }),
      );
      setStats(new Map(m));
    }).catch(() => setJars([]));
  }, [creator]);
  useEffect(load, [load]);

  if (!creator) {
    return <EmptyState icon={Milk} title="No creator page yet" body="Set up your creator page first — then create campaign jars." />;
  }

  function useTemplate(t: typeof JAR_TEMPLATES[number]) {
    setName(t.name); setGoal(String(t.goal)); setDesc(t.desc);
    document.getElementById("jar-name")?.focus();
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

  function copy(link: string, jarId: string) {
    navigator.clipboard?.writeText(link);
    setCopiedFor(jarId);
    window.setTimeout(() => setCopiedFor((c) => (c === jarId ? null : c)), 1800);
  }

  const rows = (jars ?? []).map((j) => {
    const s = stats.get(j.id) ?? { raised: 0, count: 0 };
    const g = j.goal ? Number(j.goal) : 0;
    const pct = g > 0 ? Math.min(100, Math.round((s.raised / g) * 100)) : 0;
    return { j, raised: s.raised, count: s.count, goal: g, pct, isDone: g > 0 && s.raised >= g };
  });
  const active = rows.filter((r) => !r.isDone);
  const completed = rows.filter((r) => r.isDone);
  const filteredActive = active.filter((r) => !q || r.j.name.toLowerCase().includes(q.toLowerCase()) || (r.j.description || "").toLowerCase().includes(q.toLowerCase()));
  filteredActive.sort((a, b) => b.raised - a.raised);

  const totalRaised = rows.reduce((s, r) => s + r.raised, 0);
  const totalCount  = rows.reduce((s, r) => s + r.count, 0);
  const totalGoal   = rows.reduce((s, r) => s + r.goal, 0);
  const totalPct    = totalGoal > 0 ? Math.round((totalRaised / totalGoal) * 100) : 0;

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-xl font-medium tracking-tight text-ink">Campaign jars</h2>
        <p className="body-muted mt-1">
          Fund something specific — each jar has its own goal, progress bar and shareable tip link.
        </p>
      </div>

      {/* KPIs */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Total jars" value={String(rows.length)} icon={Milk} accent="#12A25C" />
        <StatCard label="Raised across jars" value={`R${money(totalRaised)}`} icon={Banknote} accent="#2563EB" />
        <StatCard label="Tips into jars" value={String(totalCount)} icon={HandCoins} accent="#E0A536" />
        <StatCard label="Overall goal progress" value={totalGoal > 0 ? `${totalPct}%` : "—"} icon={Trophy} accent="#EC4899" />
      </div>

      {/* Composer with templates */}
      <div className="card space-y-4 !p-5">
        <div className="flex flex-wrap gap-2">
          <span className="mr-1 text-xs font-semibold uppercase tracking-wide text-muted">Templates</span>
          {JAR_TEMPLATES.map((t) => (
            <button
              key={t.name}
              onClick={() => useTemplate(t)}
              className="rounded-full border border-border px-3 py-1 text-xs font-medium text-muted transition hover:border-teal hover:text-teal"
            >
              {t.emoji} {t.name}
            </button>
          ))}
          {(name || goal || desc) && (
            <button onClick={() => { setName(""); setGoal(""); setDesc(""); }} className="ml-auto text-xs font-medium text-muted hover:text-red-500">
              Clear
            </button>
          )}
        </div>
        <div className="grid gap-3 sm:grid-cols-[1fr_160px]">
          <input
            id="jar-name"
            value={name}
            maxLength={80}
            onChange={(e) => setName(e.target.value)}
            placeholder="Jar name — e.g. New microphone"
            className="w-full rounded-xl border border-border bg-white px-4 py-2.5 text-sm text-ink focus:border-primary/40 focus:outline-none"
          />
          <input value={goal} onChange={(e) => setGoal(e.target.value.replace(/[^0-9.]/g, ""))} inputMode="decimal" placeholder="Goal (R)"
            className="w-full rounded-xl border border-border bg-white px-4 py-2.5 text-sm text-ink focus:border-primary/40 focus:outline-none" />
        </div>
        <input value={desc} onChange={(e) => setDesc(e.target.value)} maxLength={200} placeholder="What's it for? (optional)"
          className="w-full rounded-xl border border-border bg-white px-4 py-2.5 text-sm text-ink focus:border-primary/40 focus:outline-none" />
        <div className="flex items-center gap-3">
          <button onClick={create} disabled={busy || !name.trim()} className="btn-primary !px-6 !py-2.5 text-sm disabled:opacity-50">
            {busy ? "Creating…" : "Create jar"}
          </button>
          {note && <p className="text-sm text-teal">{note}</p>}
        </div>
      </div>

      {rows.length > 0 && (
        <div className="flex flex-wrap items-center gap-3">
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Search jars…"
            className="w-full max-w-xs rounded-full border border-border bg-white px-4 py-2 text-sm text-ink focus:border-primary/40 focus:outline-none"
          />
          <span className="text-xs text-muted">{filteredActive.length} active</span>
          {completed.length > 0 && (
            <button
              onClick={() => setShowCompleted((v) => !v)}
              className="ml-auto rounded-full border border-border px-3 py-1.5 text-xs font-medium text-muted transition hover:border-teal hover:text-teal"
            >
              {showCompleted ? "Hide" : "Show"} {completed.length} completed
            </button>
          )}
        </div>
      )}

      {!jars ? (
        <p className="body-muted">Loading…</p>
      ) : jars.length === 0 ? (
        <EmptyState icon={Milk} title="No jars yet" body="Pick a template above or write your own to start." />
      ) : filteredActive.length === 0 && !showCompleted ? (
        <EmptyState icon={Milk} title="No active jars match" body="Try clearing your search." />
      ) : (
        <div className="grid gap-4 lg:grid-cols-2">
          {filteredActive.map(({ j, raised, count, goal: g, pct }) => {
            const link = `https://www.tippingjar.co.za/tip/${creator.slug}?jar=${j.slug}`;
            const remaining = g > 0 ? Math.max(0, g - raised) : 0;
            return (
              <div key={j.id} className="card overflow-hidden !p-0">
                <div className="flex items-center gap-4 border-b border-border p-5">
                  {g > 0 ? (
                    <div className="relative shrink-0">
                      <ProgressRing pct={pct} size={56} />
                      <span className="absolute inset-0 grid place-items-center text-[10px] font-bold text-ink">{pct}%</span>
                    </div>
                  ) : (
                    <span className="grid h-14 w-14 shrink-0 place-items-center rounded-full bg-mint/20 text-2xl">🫙</span>
                  )}
                  <div className="min-w-0 flex-1">
                    <p className="truncate font-medium text-ink">{j.name}</p>
                    {j.description && <p className="body-muted line-clamp-1 text-xs">{j.description}</p>}
                  </div>
                </div>
                <div className="space-y-3 p-5">
                  <div className="flex items-baseline justify-between font-mono text-xs text-muted">
                    <span><span className="font-semibold text-ink">R{money(raised)}</span> raised · {count} tip{count === 1 ? "" : "s"}</span>
                    {g > 0 && <span>of R{money(g)}</span>}
                  </div>
                  {g > 0 && (
                    <>
                      <div className="h-2 overflow-hidden rounded-full bg-border">
                        <div className="h-full rounded-full bg-teal transition-all duration-700" style={{ width: `${Math.max(3, pct)}%` }} />
                      </div>
                      <p className="text-[11px] text-muted">
                        {remaining > 0 ? <>Need <span className="font-semibold text-ink">R{money(remaining)}</span> more to hit the goal.</> : "Goal reached! 🎉"}
                      </p>
                    </>
                  )}
                  <div className="flex flex-wrap gap-2 pt-1">
                    <button
                      onClick={() => copy(link, j.id)}
                      className={`inline-flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-medium transition ${
                        copiedFor === j.id ? "border-teal bg-teal text-white" : "border-border text-muted hover:border-teal hover:text-teal"
                      }`}
                      title={link}
                    >
                      {copiedFor === j.id ? <><Check className="h-3 w-3" strokeWidth={2.6} /> Copied!</> : <><Copy className="h-3 w-3" strokeWidth={2.4} /> Copy link</>}
                    </button>
                    <button
                      onClick={() => downloadJarQr(link, j.name)}
                      className="inline-flex items-center gap-1.5 rounded-full border border-border px-3 py-1.5 text-xs font-medium text-muted hover:border-teal hover:text-teal"
                    >
                      <QrCode className="h-3 w-3" strokeWidth={2.4} /> QR poster
                    </button>
                    <a
                      href={`https://wa.me/?text=${encodeURIComponent(`Help me fill this jar: ${j.name}\n${link}`)}`}
                      target="_blank"
                      rel="noreferrer"
                      className="inline-flex items-center gap-1.5 rounded-full border border-border px-3 py-1.5 text-xs font-medium text-muted hover:border-teal hover:text-teal"
                    >
                      <i className="bi bi-whatsapp" /> Share
                    </a>
                    <button
                      onClick={async () => {
                        if (!token || !window.confirm(`Delete jar "${j.name}"?`)) return;
                        await api.deleteJar(token, j.id).catch(() => null);
                        load();
                      }}
                      className="ml-auto rounded-full border border-red-200 px-3 py-1.5 text-xs font-medium text-red-500 hover:bg-red-50"
                    >
                      Delete
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {showCompleted && completed.length > 0 && (
        <div className="space-y-3">
          <div className="flex items-center gap-2 pt-4">
            <Trophy className="h-4 w-4 text-gold" strokeWidth={2.4} />
            <p className="text-sm font-semibold text-ink">Completed jars — legends</p>
          </div>
          <div className="grid gap-3 lg:grid-cols-2">
            {completed.map(({ j, raised, count, goal: g }) => (
              <div key={j.id} className="card flex items-center gap-4 !p-5 !border-gold/40 bg-gold/5">
                <span className="grid h-12 w-12 shrink-0 place-items-center rounded-full bg-gold/20 text-2xl">🏆</span>
                <div className="min-w-0 flex-1">
                  <p className="truncate font-medium text-ink">{j.name}</p>
                  <p className="mt-0.5 text-xs text-muted">
                    R{money(raised)} raised · {count} tip{count === 1 ? "" : "s"}
                    {g > 0 && <> · goal R{money(g)}</>}
                  </p>
                </div>
                <button
                  onClick={async () => {
                    if (!token || !window.confirm(`Delete completed jar "${j.name}"?`)) return;
                    await api.deleteJar(token, j.id).catch(() => null);
                    load();
                  }}
                  className="text-xs text-muted hover:text-red-500"
                >
                  Archive
                </button>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

// ─── Subscribers ─────────────────────────────────────────────────────────────
function SubscribersTab({ token, slug }: { token: string | null; slug: string | null }) {
  const [subs, setSubs] = useState<Subscriber[] | null>(null);
  const [tiers, setTiers] = useState<SupportTier[]>([]);
  const [tierFilter, setTierFilter] = useState<string>("all");
  const [q, setQ] = useState("");

  useEffect(() => {
    if (!token) return;
    api.mySubscribers(token).then(setSubs).catch(() => setSubs([]));
    api.myTiers(token).then(setTiers).catch(() => setTiers([]));
  }, [token]);

  if (!subs) return <p className="body-muted">Loading…</p>;

  const filtered = subs.filter((s) => {
    if (tierFilter !== "all" && s.tier_id !== tierFilter) return false;
    if (q) {
      const n = q.toLowerCase();
      if (!s.email.toLowerCase().includes(n) && !s.name.toLowerCase().includes(n)) return false;
    }
    return true;
  });

  const active = subs.filter((s) => s.status === "active").length;
  const monthlyRev = subs.filter((s) => s.status === "active").reduce((sum, s) => {
    const t = tiers.find((t) => t.id === s.tier_id);
    return sum + (t ? Number(t.price) || 0 : 0);
  }, 0);
  const byTier = new Map<string, number>();
  subs.forEach((s) => byTier.set(s.tier_id, (byTier.get(s.tier_id) ?? 0) + 1));

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h2 className="text-xl font-medium tracking-tight text-ink">Subscribers</h2>
          <p className="body-muted mt-1">Fans on your recurring support tiers. They unlock subscription-only content in your vault.</p>
        </div>
        <button
          onClick={() => {
            downloadCsv(
              `subscribers-${new Date().toISOString().slice(0, 10)}.csv`,
              ["email", "name", "tier", "status", "joined"],
              filtered.map((s) => [s.email, s.name, s.tier_name, s.status, s.created_at]),
            );
          }}
          disabled={filtered.length === 0}
          className="btn-ghost !px-4 !py-2.5 text-xs disabled:opacity-40"
        >
          <Download className="h-3.5 w-3.5" strokeWidth={2.2} /> CSV
        </button>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Total subscribers" value={String(subs.length)} icon={Users} accent="#7C3AED" />
        <StatCard label="Active" value={String(active)} icon={CircleCheck} accent="#12A25C" />
        <StatCard label="Estimated MRR" value={`R${money(monthlyRev)}`} icon={Banknote} accent="#E0A536" />
        <StatCard label="Support tiers" value={String(tiers.length)} icon={Trophy} accent="#EC4899" />
      </div>

      {tiers.length === 0 ? (
        <div className="card !p-5">
          <p className="text-sm font-semibold text-ink">No support tiers yet</p>
          <p className="body-muted mt-1 text-sm">
            Support tiers unlock subscription-only content. Set them up on your creator page — coming soon:
            in-dashboard tier editor. For now, tiers are managed via the API.
          </p>
        </div>
      ) : (
        <div className="card !p-5">
          <p className="text-xs font-semibold uppercase tracking-wide text-muted">Your tiers</p>
          <div className="mt-3 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {tiers.map((t) => (
              <div key={t.id} className="rounded-xl border border-border bg-white p-4">
                <div className="flex items-baseline justify-between">
                  <p className="font-medium text-ink">{t.name}</p>
                  <p className="font-mono text-sm font-bold text-teal">R{Number(t.price).toFixed(0)}/mo</p>
                </div>
                {t.description && <p className="mt-1 text-xs text-muted line-clamp-2">{t.description}</p>}
                <p className="mt-2 text-xs text-muted">{byTier.get(t.id) ?? 0} subscriber{(byTier.get(t.id) ?? 0) === 1 ? "" : "s"}</p>
              </div>
            ))}
          </div>
        </div>
      )}

      {subs.length > 0 && (
        <>
          <div className="card flex flex-wrap items-center gap-3 !p-4">
            <input
              value={q}
              onChange={(e) => setQ(e.target.value)}
              placeholder="Search email or name…"
              className="w-full max-w-xs rounded-full border border-border bg-white px-4 py-2 text-sm text-ink focus:border-primary/40 focus:outline-none"
            />
            <div className="flex flex-wrap gap-1.5">
              <button
                onClick={() => setTierFilter("all")}
                className={`rounded-full px-3 py-1.5 text-xs font-medium transition ${tierFilter === "all" ? "bg-primary text-white" : "border border-border text-muted hover:text-ink"}`}
              >
                All · {subs.length}
              </button>
              {tiers.map((t) => (
                <button
                  key={t.id}
                  onClick={() => setTierFilter(t.id)}
                  className={`rounded-full px-3 py-1.5 text-xs font-medium transition ${tierFilter === t.id ? "bg-primary text-white" : "border border-border text-muted hover:text-ink"}`}
                >
                  {t.name} · {byTier.get(t.id) ?? 0}
                </button>
              ))}
            </div>
          </div>

          <div className="card overflow-hidden !p-0">
            <div className="overflow-x-auto">
              <table className="w-full min-w-[640px] text-left text-sm">
                <thead className="border-b border-border text-xs uppercase tracking-wide text-muted">
                  <tr>
                    <th className="px-5 py-3 font-medium">Subscriber</th>
                    <th className="px-5 py-3 font-medium">Tier</th>
                    <th className="px-5 py-3 font-medium">Status</th>
                    <th className="px-5 py-3 font-medium">Joined</th>
                    <th className="px-5 py-3 text-right font-medium">Act</th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((s) => (
                    <tr key={s.id} className="border-b border-border/60 last:border-0 hover:bg-ink/[0.02]">
                      <td className="px-5 py-3">
                        <p className="font-medium text-ink">{s.name || s.email.split("@")[0]}</p>
                        <p className="text-[11px] text-muted">{s.email}</p>
                      </td>
                      <td className="px-5 py-3 text-muted">{s.tier_name || "—"}</td>
                      <td className="px-5 py-3">
                        <span className={`rounded-full px-2.5 py-0.5 text-[11px] font-medium ${s.status === "active" ? "bg-teal/10 text-teal" : "bg-border/60 text-muted"}`}>
                          {s.status}
                        </span>
                      </td>
                      <td className="px-5 py-3 text-muted">
                        {new Date(s.created_at).toLocaleDateString("en-ZA", { day: "numeric", month: "short", year: "numeric" })}
                      </td>
                      <td className="px-5 py-3 text-right">
                        <a
                          href={`mailto:${s.email}`}
                          className="inline-flex items-center gap-1 rounded-full border border-border px-3 py-1 text-xs font-medium text-muted hover:border-teal hover:text-teal"
                        >
                          <Send className="h-3 w-3" strokeWidth={2.4} /> Email
                        </a>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </>
      )}

      {slug && (
        <p className="text-xs text-muted">
          Share your public tier list at{" "}
          <a href={`/creator/${slug}`} target="_blank" className="text-teal hover:underline">
            tippingjar.co.za/creator/{slug}
          </a>{" "}
          — fans subscribe there.
        </p>
      )}
    </div>
  );
}
