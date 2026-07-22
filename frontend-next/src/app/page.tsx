import Link from "next/link";
import { api } from "@/lib/api";
import { CreatorCard } from "@/components/CreatorCard";
import { HeroDemo } from "@/components/HeroDemo";
import { LiveTicker, type TickerItem } from "@/components/LiveTicker";
import { Reveal } from "@/components/Reveal";
import type { Creator } from "@/types";

const FLOW = [
  { n: "01", title: "A fan taps your link", body: "Your page opens — they pick an amount, add a note, and pay by card in seconds." },
  { n: "02", title: "The jar fills", body: "Every tip drops in and nudges the bar toward your goal, live, for everyone to see." },
  { n: "03", title: "You get paid out", body: "Support lands in your balance and pays out to your bank. You keep the majority, always." },
];

const FEATURES = [
  { icon: "🫙", tint: "bg-mint/15", title: "Goals that fill up", body: "Set a monthly goal and watch the jar rise as fans chip in." },
  { icon: "🪙", tint: "bg-gold/15", title: "Keep the majority", body: "Low, transparent fees — the bulk of every rand is yours." },
  { icon: "⚡", tint: "bg-mint/15", title: "Live in minutes", body: "Make a page, share the link, start receiving support today." },
  { icon: "🔒", tint: "bg-primary/10", title: "Real payouts", body: "Verified, bank-grade payouts straight to your account." },
  { icon: "🧾", tint: "bg-gold/15", title: "Every tip, tracked", body: "A clean receipt for each supporter, with names and messages." },
  { icon: "🌍", tint: "bg-primary/10", title: "Made for Africa", body: "Local cards, local currency, local support. Built in South Africa." },
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

export default async function LandingPage() {
  const [creators, ticker] = await Promise.all([getCreators(), getTicker()]);
  const categories = Array.from(
    new Set(creators.map((c) => c.category).filter(Boolean)),
  ).slice(0, 6);
  const chips = categories.length
    ? categories
    : ["Music", "Art", "Writing", "Streaming", "Podcasts", "Photography"];

  return (
    <>
      {/* Hero */}
      <section className="overflow-hidden border-b border-border">
        <div className="container-content grid items-center gap-14 py-16 lg:grid-cols-[1.05fr_0.95fr] lg:py-24">
          <div>
            <p className="eyebrow rise-in">Fan tipping · South Africa</p>
            <h1 className="heading-xl mt-5 max-w-xl rise-in" style={{ animationDelay: "0.05s" }}>
              Support that{" "}
              <span className="relative whitespace-nowrap text-green">
                adds up
                <svg aria-hidden viewBox="0 0 200 12" className="absolute -bottom-1.5 left-0 h-2.5 w-full" preserveAspectRatio="none">
                  <path d="M2 8 Q 60 2 100 6 T 198 5" fill="none" stroke="var(--gold)" strokeWidth="3.5" strokeLinecap="round" />
                </svg>
              </span>
              .
            </h1>
            <p className="body-muted mt-6 max-w-lg text-lg rise-in" style={{ animationDelay: "0.1s" }}>
              Fans drop a tip, your jar fills, and appreciation becomes steady
              income. Set up in minutes and keep the majority of every rand.
            </p>
            <div className="mt-9 flex flex-wrap items-center gap-4 rise-in" style={{ animationDelay: "0.15s" }}>
              <Link href="/register" className="btn-primary text-base">Start your jar →</Link>
              <Link href="/creators" className="btn-ghost text-base">Explore creators</Link>
            </div>
            <div className="mt-9 flex flex-wrap gap-x-6 gap-y-2 font-mono text-xs uppercase tracking-[0.14em] text-muted rise-in" style={{ animationDelay: "0.2s" }}>
              <span className="inline-flex items-center gap-1.5"><span className="text-green">◆</span> low fees</span>
              <span className="inline-flex items-center gap-1.5"><span className="text-green">◆</span> fast payouts</span>
              <span className="inline-flex items-center gap-1.5"><span className="text-green">◆</span> pay by card</span>
            </div>
          </div>

          <div className="rise-in" style={{ animationDelay: "0.25s" }}>
            <HeroDemo />
          </div>
        </div>
      </section>

      {/* Live activity */}
      <section className="border-b border-border bg-white py-4">
        <div className="container-content flex items-center gap-4">
          <span className="hidden shrink-0 font-mono text-[11px] uppercase tracking-[0.18em] text-green sm:inline">
            ● live tips
          </span>
          <div className="min-w-0 flex-1">
            <LiveTicker items={ticker} />
          </div>
        </div>
      </section>

      {/* Categories band */}
      <section className="border-b border-border bg-white">
        <div className="container-content flex flex-wrap items-center justify-center gap-x-8 gap-y-3 py-8 font-mono text-xs uppercase tracking-[0.2em] text-muted">
          <span className="text-ink/40">Creators of every kind —</span>
          {chips.map((c) => (
            <span key={c}>{c}</span>
          ))}
        </div>
      </section>

      {/* How a tip flows */}
      <section className="border-b border-border bg-white">
        <div className="container-content py-20">
          <Reveal className="flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
            <div>
              <p className="eyebrow">The flow</p>
              <h2 className="heading-xl mt-3 text-4xl md:text-5xl">From tap to payout</h2>
            </div>
            <p className="body-muted max-w-sm">
              Three steps, no faff. Here&apos;s exactly what happens when someone
              wants to back you.
            </p>
          </Reveal>
          <ol className="mt-14 grid gap-8 md:grid-cols-3">
            {FLOW.map((s, i) => (
              <Reveal as="li" key={s.n} delay={i * 90} className="relative">
                {i < FLOW.length - 1 && (
                  <span aria-hidden className="absolute left-12 top-5 hidden h-px w-[calc(100%-2rem)] border-t border-dashed border-border md:block" />
                )}
                <span className="grid h-11 w-11 shrink-0 place-items-center rounded-full bg-primary font-mono text-sm font-bold text-white">
                  {s.n}
                </span>
                <h3 className="mt-5 font-display text-xl font-bold text-ink">{s.title}</h3>
                <p className="body-muted mt-2">{s.body}</p>
              </Reveal>
            ))}
          </ol>
        </div>
      </section>

      {/* Features */}
      <section className="container-content py-20">
        <Reveal className="max-w-2xl">
          <p className="eyebrow">Why Tipping Jar</p>
          <h2 className="heading-xl mt-3 text-4xl md:text-5xl">
            Built for the moment someone says thanks
          </h2>
        </Reveal>
        <div className="mt-12 grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {FEATURES.map((f, i) => (
            <Reveal key={f.title} delay={(i % 3) * 80}>
              <div className="card h-full transition duration-200 hover:-translate-y-1 hover:shadow-lift">
                <div className={`grid h-12 w-12 place-items-center rounded-2xl text-2xl ${f.tint}`}>
                  {f.icon}
                </div>
                <h3 className="mt-5 font-display text-lg font-bold text-ink">{f.title}</h3>
                <p className="body-muted mt-2">{f.body}</p>
              </div>
            </Reveal>
          ))}
        </div>
      </section>

      {/* Featured creators */}
      {creators.length > 0 && (
        <section className="border-t border-border bg-white">
          <div className="container-content py-20">
            <Reveal className="flex items-end justify-between">
              <div>
                <p className="eyebrow">On the platform</p>
                <h2 className="heading-xl mt-3 text-4xl md:text-5xl">Creators filling their jars</h2>
              </div>
              <Link href="/creators" className="hidden text-sm font-semibold text-green hover:underline sm:block">
                View all →
              </Link>
            </Reveal>
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

      {/* CTA */}
      <section className="container-content py-20">
        <Reveal>
          <div className="relative overflow-hidden rounded-[28px] bg-navy px-8 py-16 text-center md:px-16">
            <span aria-hidden className="pointer-events-none absolute left-8 top-8 h-8 w-8 rounded-full bg-gold/50" />
            <span aria-hidden className="pointer-events-none absolute right-12 top-12 h-14 w-14 rounded-full bg-mint/20" />
            <span aria-hidden className="pointer-events-none absolute bottom-10 right-24 h-6 w-6 rounded-full bg-gold/60" />
            <p className="eyebrow !text-mint">Your jar is waiting</p>
            <h2 className="heading-xl mt-4 text-white">Start collecting support today</h2>
            <p className="mx-auto mt-4 max-w-lg text-white/75">
              Set up your page, share one link, and let the tips add up.
            </p>
            <Link
              href="/register"
              className="mt-9 inline-flex rounded-full bg-white px-8 py-3.5 font-semibold !text-primary shadow-lift transition hover:-translate-y-0.5 hover:bg-white/90"
            >
              Create your jar
            </Link>
          </div>
        </Reveal>
      </section>
    </>
  );
}
