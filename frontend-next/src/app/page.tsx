import Link from "next/link";
import { api } from "@/lib/api";
import { CreatorCard } from "@/components/CreatorCard";
import { HeroDemo } from "@/components/HeroDemo";
import { LiveTicker, type TickerItem } from "@/components/LiveTicker";
import { Reveal } from "@/components/Reveal";
import { Aurora } from "@/components/Aurora";
import {
  IconBank,
  IconBolt,
  IconCoin,
  IconGlobe,
  IconJar,
  IconLink,
  IconReceipt,
  IconShield,
} from "@/components/Icons";
import type { Creator } from "@/types";

const FLOW = [
  { n: "01", icon: IconLink, title: "A fan taps your link", body: "Your page opens — they pick an amount, add a note, and pay by card in seconds. No account needed." },
  { n: "02", icon: IconJar, title: "The jar fills", body: "Every tip drops in and nudges the bar toward your goal, live, for everyone to see." },
  { n: "03", icon: IconBank, title: "You get paid out", body: "Support lands in your balance and pays out to your South African bank account." },
];

const FEATURES: {
  icon: typeof IconJar;
  title: string;
  body: string;
  big?: boolean;
}[] = [
  { icon: IconJar, big: true, title: "Goals that fill up", body: "Set a monthly goal and let fans watch the jar rise as they chip in. A visible goal turns one-off thanks into momentum — supporters love pushing it over the line." },
  { icon: IconCoin, title: "Keep the majority", body: "6% flat when a tip lands. No subscriptions, no hidden charges." },
  { icon: IconBank, title: "Real payouts", body: "Balance to bank account, on request. ZAR in, ZAR out." },
  { icon: IconReceipt, title: "Every tip, tracked", body: "A clean receipt per supporter — names, messages, amounts — plus a nightly PDF statement by email." },
  { icon: IconBolt, title: "Live in minutes", body: "Name your page, share one link, start receiving support today." },
  { icon: IconShield, title: "Card-safe by design", body: "Payments run through PayCloud's PCI-compliant gateway. Card details never touch our servers." },
];

const FAQ = [
  { q: "What does it cost?", a: "6% flat per tip — 3% platform and 3% card & service. There are no monthly fees and no setup cost; you only pay when you get paid." },
  { q: "How do payouts work?", a: "Tips land in your balance as they're paid. Request a payout from your dashboard and it's transferred to your South African bank account." },
  { q: "Do fans need an account?", a: "No. Fans open your link, pick an amount and pay by card in under a minute — no signup, no app to install." },
  { q: "Is it secure?", a: "Payments are processed by PayCloud's PCI-compliant gateway over an encrypted connection. Your fans' card details never touch our servers." },
  { q: "Who can start a jar?", a: "Any South African creator — musicians, writers, streamers, artists, podcasters. Sign up, name your page and share the link." },
];

const SAMPLE_TICKER: TickerItem[] = [
  { name: "Sam", amount: "R50", creator: "Pay Flow" },
  { name: "Thandi", amount: "R120", creator: "Lehani" },
  { name: "Anon", amount: "R20", creator: "The Studio" },
  { name: "Lerato", amount: "R250", creator: "Night Set" },
  { name: "Kabelo", amount: "R80", creator: "Inkwell" },
  { name: "Zinhle", amount: "R30", creator: "Pay Flow" },
];

function maskName(name: string): string {
  const n = (name || "").trim();
  if (!n || n.toLowerCase() === "anonymous") return "Anon";
  const first = n.split(" ")[0];
  return first.length <= 2 ? first : `${first.charAt(0)}${"•".repeat(Math.min(first.length - 1, 3))}`;
}

async function getCreators(): Promise<Creator[]> {
  try {
    return (await api.listCreators()).slice(0, 6);
  } catch {
    return [];
  }
}

// Roll platform-wide numbers for the hero social-proof ribbon. The backend
// caps listCreators + listTips at ~200 rows each, so these are 'recent
// activity' numbers rather than lifetime totals — which stays honest and
// updates automatically as the platform grows.
async function getHeroStats(): Promise<{ creators: number; tipsCount: number; totalRaised: number }> {
  try {
    const [creators, tips] = await Promise.all([api.listCreators(), api.listTips()]);
    const completed = tips.filter((t) => t.status === "completed");
    const totalRaised = completed.reduce((s, t) => s + (parseFloat(t.amount) || 0), 0);
    return { creators: creators.length, tipsCount: completed.length, totalRaised };
  } catch {
    return { creators: 0, tipsCount: 0, totalRaised: 0 };
  }
}

async function getTicker(): Promise<TickerItem[]> {
  try {
    const tips = await api.listTips();
    const items = tips
      .filter((t) => t.status === "completed")
      .slice(0, 12)
      .map((t) => ({
        name: maskName(t.tipper_name),
        amount: `R${Math.round(parseFloat(t.amount) || 0)}`,
        creator: t.creator_name || "",
      }));
    return items.length >= 4 ? items : SAMPLE_TICKER;
  } catch {
    return SAMPLE_TICKER;
  }
}

// Compact number formatter — 1230 → "1.2k", 15_000 → "15k", 1_500_000 → "1.5M".
function compact(n: number): string {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 10_000) return `${Math.round(n / 1_000)}k`;
  if (n >= 1_000) return `${(n / 1_000).toFixed(1)}k`;
  return String(Math.round(n));
}

export default async function LandingPage() {
  const [creators, ticker, stats] = await Promise.all([
    getCreators(),
    getTicker(),
    getHeroStats(),
  ]);
  const categories = Array.from(
    new Set(creators.map((c) => c.category).filter(Boolean)),
  ).slice(0, 6);
  const chips = categories.length
    ? categories
    : ["Music", "Art", "Writing", "Streaming", "Podcasts", "Photography"];
  // Latest tip for the hero's live-activity pill — pulled from the same
  // ticker feed we already fetched.
  const latestTip = ticker[0];

  return (
    <>
      {/* ── Hero — navy stage for the live demo ─────────────────────────── */}
      <section className="relative overflow-hidden bg-navy">
        {/* A creator at work, dimmed into the navy stage (CC0 photo) */}
        <img
          src="/hero-creator.jpg"
          alt=""
          aria-hidden
          className="pointer-events-none absolute inset-0 h-full w-full object-cover object-[70%_center] opacity-30"
        />
        <span aria-hidden className="pointer-events-none absolute inset-0 bg-navy/20" />
        <span aria-hidden className="blob pointer-events-none absolute -left-10 top-24 h-40 w-40 rounded-full bg-mint/20" />
        <span aria-hidden className="blob pointer-events-none absolute -bottom-16 right-[38%] h-48 w-48 rounded-full bg-green/20" style={{ animationDelay: "-8s" }} />
        {/* floating coins + sparkles */}
        <span aria-hidden className="float-y pointer-events-none absolute left-[46%] top-10 grid h-9 w-9 place-items-center rounded-full bg-gold text-navy shadow-lift">
          <i className="bi bi-coin text-sm" />
        </span>
        <span aria-hidden className="float-y pointer-events-none absolute right-[8%] top-1/3 grid h-7 w-7 place-items-center rounded-full bg-mint text-navy shadow-lift" style={{ animationDelay: "1.4s" }}>
          <i className="bi bi-suit-heart-fill text-xs" />
        </span>
        <span aria-hidden className="sparkle pointer-events-none absolute left-[18%] bottom-16 h-3 w-3 rounded-full bg-gold/80" />
        <span aria-hidden className="sparkle pointer-events-none absolute right-[30%] top-16 h-2.5 w-2.5 rounded-full bg-mint/80" style={{ animationDelay: "0.9s" }} />

        <div className="container-content relative grid items-center gap-14 py-16 lg:grid-cols-[1.05fr_0.95fr] lg:py-24">
          <div>
            {/* Live activity pill — a tiny bit of proof-of-life the moment
                the page loads. Falls back cleanly when there's no ticker. */}
            {latestTip && (
              <span className="mb-5 inline-flex items-center gap-2 rounded-full border border-mint/30 bg-mint/10 py-1.5 pl-2 pr-4 text-xs font-medium text-mint rise-in">
                <span className="relative flex h-2 w-2">
                  <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-mint/60" />
                  <span className="relative inline-flex h-2 w-2 rounded-full bg-mint" />
                </span>
                <span className="text-white/85">
                  <span className="text-mint">{latestTip.name}</span> just tipped{" "}
                  <span className="font-mono">{latestTip.amount}</span> to{" "}
                  <span className="text-mint">{latestTip.creator}</span>
                </span>
              </span>
            )}

            <p className="eyebrow !text-mint rise-in">Fan tipping · South Africa</p>
            <h1
              className="mt-5 max-w-xl font-display text-[2.9rem] font-extrabold leading-[1.02] tracking-[-0.02em] md:text-[4.2rem] rise-in"
              style={{ animationDelay: "0.05s" }}
            >
              Support that{" "}
              <span className="relative whitespace-nowrap !text-mint">
                adds up
                <svg aria-hidden viewBox="0 0 200 12" className="absolute -bottom-1.5 left-0 h-2.5 w-full" preserveAspectRatio="none">
                  <path d="M2 8 Q 60 2 100 6 T 198 5" fill="none" stroke="var(--gold)" strokeWidth="3.5" strokeLinecap="round" />
                </svg>
              </span>
              .
            </h1>
            <p className="mt-6 max-w-lg text-lg leading-relaxed opacity-80 rise-in" style={{ animationDelay: "0.1s" }}>
              Fans drop a tip, your jar fills, and appreciation becomes steady
              income. Set up in minutes and keep the majority of every rand.
            </p>
            <div className="mt-9 flex flex-wrap items-center gap-4 rise-in" style={{ animationDelay: "0.15s" }}>
              <Link
                href="/register"
                className="inline-flex items-center justify-center rounded-full bg-white px-7 py-3.5 text-base font-semibold !text-primary shadow-lift transition duration-200 hover:-translate-y-0.5"
              >
                Start your jar →
              </Link>
              <Link
                href="/creators"
                className="inline-flex items-center justify-center rounded-full border border-white/25 px-7 py-3.5 text-base font-semibold transition duration-200 hover:border-white/60 hover:bg-white/10"
              >
                Explore creators
              </Link>
            </div>
            <div className="mt-10 flex flex-wrap gap-x-3 gap-y-2 rise-in" style={{ animationDelay: "0.2s" }}>
              {["6% flat fees", "Payouts to your bank", "Fans pay by card — no signup"].map((f) => (
                <span
                  key={f}
                  className="rounded-full border border-white/15 px-3.5 py-1.5 font-mono text-[11px] uppercase tracking-[0.14em] opacity-80"
                >
                  {f}
                </span>
              ))}
            </div>

            {/* Social proof — real numbers from the platform + creator
                avatar stack. Replaces the previous single line of chips
                with something creators can actually see themselves in. */}
            <div className="mt-10 flex flex-wrap items-center gap-x-6 gap-y-4 rise-in" style={{ animationDelay: "0.25s" }}>
              {creators.length > 0 && (
                <div className="flex items-center gap-3">
                  <div className="flex -space-x-2.5">
                    {creators.slice(0, 5).map((c) => (
                      <span
                        key={c.id}
                        className="grid h-9 w-9 place-items-center overflow-hidden rounded-full border-2 border-navy bg-white text-sm font-bold text-navy"
                        title={c.display_name}
                      >
                        {c.avatar_url ? (
                          // eslint-disable-next-line @next/next/no-img-element
                          <img src={c.avatar_url} alt="" className="h-full w-full object-cover" />
                        ) : (
                          <span>{(c.display_name || "T").charAt(0)}</span>
                        )}
                      </span>
                    ))}
                    {stats.creators > 5 && (
                      <span className="grid h-9 w-9 place-items-center rounded-full border-2 border-navy bg-mint text-[10px] font-bold text-navy">
                        +{stats.creators - 5}
                      </span>
                    )}
                  </div>
                  <p className="text-xs leading-tight opacity-80">
                    <span className="font-semibold text-white">{compact(stats.creators)}+ creators</span>
                    <br />
                    trust Tipping Jar
                  </p>
                </div>
              )}
              {stats.totalRaised > 0 && (
                <div className="flex items-center gap-2">
                  <span className="grid h-9 w-9 place-items-center rounded-full bg-mint/15 text-mint">
                    <i className="bi bi-cash-coin text-base" aria-hidden />
                  </span>
                  <p className="text-xs leading-tight opacity-80">
                    <span className="font-semibold text-white">R{compact(stats.totalRaised)}</span>
                    <br />
                    tipped recently
                  </p>
                </div>
              )}
              {stats.tipsCount > 0 && (
                <div className="flex items-center gap-2">
                  <span className="grid h-9 w-9 place-items-center rounded-full bg-gold/15 text-gold">
                    <i className="bi bi-lightning-charge-fill text-base" aria-hidden />
                  </span>
                  <p className="text-xs leading-tight opacity-80">
                    <span className="font-semibold text-white">{stats.tipsCount}</span>
                    <br />
                    tips in the feed
                  </p>
                </div>
              )}
            </div>

            {/* Scroll cue — a small nudge that there's more below the fold. */}
            <p className="mt-12 hidden items-center gap-2 font-mono text-[11px] uppercase tracking-[0.16em] text-white/60 lg:flex rise-in" style={{ animationDelay: "0.3s" }}>
              <span className="h-px w-8 bg-white/40" />
              Scroll to see how a tip flows
            </p>
          </div>

          <div className="rise-in" style={{ animationDelay: "0.25s" }}>
            <HeroDemo />
          </div>
        </div>
      </section>

      {/* ── Live activity ───────────────────────────────────────────────── */}
      <section className="border-b border-border bg-white py-4">
        <div className="container-content flex items-center gap-4">
          <span className="hidden shrink-0 items-center gap-1.5 font-mono text-[11px] uppercase tracking-[0.18em] text-green sm:inline-flex">
            <i className="bi bi-broadcast" /> live tips
          </span>
          <div className="min-w-0 flex-1">
            <LiveTicker items={ticker} />
          </div>
        </div>
      </section>

      {/* ── Fee transparency — the split, shown not told ────────────────── */}
      <section className="border-b border-border bg-white">
        <div className="container-content py-24">
          <Reveal className="grid items-center gap-12 lg:grid-cols-[0.95fr_1.05fr]">
            <div>
              <p className="eyebrow">Transparent fees</p>
              <h2 className="heading-xl mt-3 text-4xl md:text-5xl">
                You keep R94 of every R100
              </h2>
              <p className="body-muted mt-5 max-w-md">
                Two flat fees, taken only when a tip actually lands. No
                subscriptions, no setup costs, nothing hidden in the fine
                print — you only ever pay when you get paid.
              </p>
              <ul className="mt-7 space-y-3 font-mono text-sm">
                <li className="flex items-center gap-3">
                  <span className="h-3 w-3 shrink-0 rounded-full bg-mint" />
                  <span className="font-semibold text-ink">R94.00</span>
                  <span className="text-muted">— yours, paid to your bank</span>
                </li>
                <li className="flex items-center gap-3">
                  <span className="h-3 w-3 shrink-0 rounded-full bg-primary" />
                  <span className="font-semibold text-ink">R3.00</span>
                  <span className="text-muted">— platform fee (3%)</span>
                </li>
                <li className="flex items-center gap-3">
                  <span className="h-3 w-3 shrink-0 rounded-full bg-gold" />
                  <span className="font-semibold text-ink">R3.00</span>
                  <span className="text-muted">— card &amp; service (3%)</span>
                </li>
              </ul>
            </div>
            <div>
              <div className="flex h-24 overflow-hidden rounded-[20px] ring-1 ring-border">
                <div className="grow-x grid place-items-center bg-mint" style={{ width: "94%" }}>
                  <div className="text-center">
                    <p className="font-display text-2xl font-extrabold text-navy">R94</p>
                    <p className="font-mono text-[10px] uppercase tracking-[0.16em] text-navy/70">creator keeps</p>
                  </div>
                </div>
                <div className="bg-primary" style={{ width: "3%" }} />
                <div className="bg-gold" style={{ width: "3%" }} />
              </div>
              <p className="mt-3 text-center font-mono text-[11px] uppercase tracking-[0.16em] text-muted">
                a R100 tip, split exactly to scale
              </p>
            </div>
          </Reveal>
        </div>
      </section>

      {/* ── How a tip flows ─────────────────────────────────────────────── */}
      <section className="relative overflow-hidden border-b border-border bg-[#f3f9f5]">
        <Aurora />
        <div className="container-content relative py-24">
          <Reveal className="flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
            <div>
              <p className="eyebrow">The flow</p>
              <h2 className="heading-xl mt-3 text-4xl md:text-5xl">From tap to payout</h2>
            </div>
            <p className="body-muted max-w-sm">
              Three steps, no faff. Here&apos;s exactly what happens when
              someone wants to back you.
            </p>
          </Reveal>
          <ol className="mt-14 grid gap-6 md:grid-cols-3">
            {FLOW.map((s, i) => {
              const Icon = s.icon;
              return (
                <Reveal as="li" key={s.n} delay={i * 90}>
                  <div className="glass-card group h-full p-7">
                    <span className="absolute right-6 top-6 font-mono text-xs font-bold text-green/50">{s.n}</span>
                    <span className="glass-tile h-12 w-12">
                      <Icon />
                    </span>
                    <h3 className="mt-6 font-display text-xl font-bold text-ink">{s.title}</h3>
                    <p className="body-muted mt-2">{s.body}</p>
                  </div>
                </Reveal>
              );
            })}
          </ol>
        </div>
      </section>

      {/* ── Features — bento grid, one hero card ────────────────────────── */}
      <section className="relative overflow-hidden border-b border-border bg-white">
        <Aurora />
        <div className="container-content relative py-24">
          <Reveal className="max-w-2xl">
            <p className="eyebrow">Why Tipping Jar</p>
            <h2 className="heading-xl mt-3 text-4xl md:text-5xl">
              Built for the moment someone says thanks
            </h2>
          </Reveal>
          <div className="mt-12 grid gap-6 md:grid-cols-3">
            {FEATURES.map((f, i) => {
              const Icon = f.icon;
              return (
                <Reveal key={f.title} delay={(i % 3) * 80} className={f.big ? "md:col-span-2" : ""}>
                  <div className="glass-card group h-full p-6">
                    <div className="flex h-full flex-col">
                      <span className="glass-tile h-12 w-12">
                        <Icon />
                      </span>
                      <h3 className="mt-5 font-display text-lg font-bold text-ink">{f.title}</h3>
                      <p className="body-muted mt-2 max-w-lg">{f.body}</p>
                      {f.big && (
                        <div className="mt-auto pt-6">
                          <div className="flex items-center justify-between font-mono text-[11px] uppercase tracking-[0.16em] text-muted">
                            <span>this month</span>
                            <span>R2,340 / R3,000</span>
                          </div>
                          <div className="mt-2 h-3 overflow-hidden rounded-full bg-white/70 ring-1 ring-border">
                            <div className="grow-x h-full rounded-full bg-gradient-to-r from-green to-mint" style={{ width: "78%" }} />
                          </div>
                        </div>
                      )}
                    </div>
                  </div>
                </Reveal>
              );
            })}
          </div>
        </div>
      </section>

      {/* ── Featured creators ───────────────────────────────────────────── */}
      {creators.length > 0 && (
        <section className="relative overflow-hidden border-b border-border bg-[#f3f9f5]">
          <Aurora />
          <div className="container-content relative py-24">
            <Reveal className="flex flex-col gap-6 md:flex-row md:items-end md:justify-between">
              <div>
                <p className="eyebrow">On the platform</p>
                <h2 className="heading-xl mt-3 text-4xl md:text-5xl">Creators filling their jars</h2>
              </div>
              <Link href="/creators" className="text-sm font-semibold text-green hover:underline">
                View all →
              </Link>
            </Reveal>
            <div className="mt-6 flex flex-wrap gap-2">
              {chips.map((c) => (
                <span key={c} className="rounded-full border border-border bg-white px-3.5 py-1.5 font-mono text-[11px] uppercase tracking-[0.14em] text-muted">
                  {c}
                </span>
              ))}
            </div>
            <div className="mt-10 grid gap-6 md:grid-cols-2 lg:grid-cols-3">
              {creators.map((c, i) => (
                <Reveal key={c.id} delay={(i % 3) * 80}>
                  <CreatorCard creator={c} />
                </Reveal>
              ))}
            </div>
          </div>
        </section>
      )}

      {/* ── FAQ ─────────────────────────────────────────────────────────── */}
      <section className="relative overflow-hidden border-b border-border bg-white">
        <Aurora />
        <div className="container-content relative grid gap-12 py-24 lg:grid-cols-[0.8fr_1.2fr]">
          <Reveal>
            <p className="eyebrow">Questions</p>
            <h2 className="heading-xl mt-3 text-4xl md:text-5xl">Fair to ask</h2>
            <p className="body-muted mt-5 max-w-sm">
              The short version of everything creators ask us before starting a
              jar. Anything else —{" "}
              <Link href="/contact" className="font-semibold text-green hover:underline">
                talk to us
              </Link>
              .
            </p>
          </Reveal>
          <Reveal delay={90}>
            <div className="glass-card p-2 md:p-4">
              {FAQ.map((f) => (
                <details key={f.q} className="faq-item group border-b border-border px-4 py-5 last:border-0">
                  <summary className="flex cursor-pointer items-center justify-between gap-4 font-display text-base font-bold text-ink md:text-lg">
                    {f.q}
                    <span aria-hidden className="grid h-8 w-8 shrink-0 place-items-center rounded-full border border-border font-mono text-base text-muted transition group-open:rotate-45 group-open:border-green group-open:text-green">
                      +
                    </span>
                  </summary>
                  <p className="body-muted mt-3 max-w-2xl">{f.a}</p>
                </details>
              ))}
            </div>
          </Reveal>
        </div>
      </section>

      {/* ── CTA ─────────────────────────────────────────────────────────── */}
      <section className="container-content py-24">
        <Reveal>
          <div className="relative overflow-hidden rounded-[28px] bg-navy px-8 py-14 md:px-16">
            <span aria-hidden className="float-y pointer-events-none absolute -right-8 -top-8 h-36 w-36 rounded-full bg-mint/10" />
            <span aria-hidden className="sparkle pointer-events-none absolute bottom-8 right-[30%] h-6 w-6 rounded-full bg-gold/60" />
            <span aria-hidden className="sparkle pointer-events-none absolute left-10 top-10 h-3 w-3 rounded-full bg-mint/70" style={{ animationDelay: "0.6s" }} />
            <span aria-hidden className="sparkle pointer-events-none absolute left-[42%] bottom-12 h-2.5 w-2.5 rounded-full bg-gold/70" style={{ animationDelay: "1.2s" }} />
            <div className="grid items-center gap-10 md:grid-cols-[1.2fr_0.8fr]">
              <div>
                <p className="eyebrow !text-mint">Your jar is waiting</p>
                <h2 className="mt-4 font-display text-4xl font-extrabold leading-[1.05] tracking-[-0.02em] md:text-5xl">
                  Start collecting support today
                </h2>
                <p className="mt-4 max-w-lg opacity-75">
                  Set up your page, share one link, and let the tips add up. Live
                  in minutes — free to start.
                </p>
                <div className="mt-8 flex flex-wrap gap-4">
                  <Link
                    href="/register"
                    className="inline-flex rounded-full bg-white px-8 py-3.5 font-semibold !text-primary shadow-lift transition hover:-translate-y-0.5"
                  >
                    Create your jar
                  </Link>
                  <Link
                    href="/how-it-works"
                    className="inline-flex rounded-full border border-white/25 px-8 py-3.5 font-semibold transition hover:border-white/60 hover:bg-white/10"
                  >
                    How it works
                  </Link>
                </div>
              </div>
              <svg viewBox="0 0 220 300" className="float-y mx-auto hidden h-56 w-auto md:block" aria-hidden>
                <defs>
                  <clipPath id="ctaJar">
                    <rect x="28" y="74" width="164" height="200" rx="32" />
                  </clipPath>
                </defs>
                <g clipPath="url(#ctaJar)">
                  <g className="jar-liquid" style={{ ["--empty"]: "18%" } as React.CSSProperties}>
                    <rect x="28" y="150" width="164" height="130" fill="var(--mint)" opacity="0.92" />
                    <rect x="28" y="150" width="164" height="5" fill="#3ab877" />
                  </g>
                  <ellipse className="jar-coin" style={{ animationDelay: "0.9s" }} cx="82" cy="256" rx="23" ry="8.5" fill="var(--gold)" />
                  <ellipse className="jar-coin" style={{ animationDelay: "1.1s" }} cx="130" cy="262" rx="25" ry="9" fill="#eebe5c" />
                  <ellipse className="jar-coin" style={{ animationDelay: "1.3s" }} cx="106" cy="249" rx="21" ry="8" fill="var(--gold)" />
                </g>
                <rect x="28" y="74" width="164" height="200" rx="32" fill="none" stroke="#ffffff" strokeOpacity="0.3" strokeWidth="2.5" />
                <rect x="41" y="96" width="9" height="140" rx="4.5" fill="#ffffff" opacity="0.25" />
                <rect x="54" y="56" width="112" height="26" rx="9" fill="none" stroke="#ffffff" strokeOpacity="0.3" strokeWidth="2.5" />
                <rect x="62" y="45" width="96" height="16" rx="7" fill="var(--gold)" />
              </svg>
            </div>
          </div>
        </Reveal>
      </section>
    </>
  );
}
