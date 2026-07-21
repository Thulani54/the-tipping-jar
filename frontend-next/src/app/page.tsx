import Link from "next/link";
import { api } from "@/lib/api";
import { CreatorCard } from "@/components/CreatorCard";
import { JarMeter } from "@/components/JarMeter";
import { TipSlip } from "@/components/TipSlip";
import type { Creator } from "@/types";

const FLOW = [
  { n: "01", title: "A fan taps your link", body: "Your tipping page opens — pick an amount, add a note, pay by card in seconds." },
  { n: "02", title: "The jar fills", body: "Every tip drops in and moves the bar toward your goal, live, for everyone to see." },
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

async function getCreators(): Promise<Creator[]> {
  try {
    return (await api.listCreators()).slice(0, 6);
  } catch {
    return [];
  }
}

export default async function LandingPage() {
  const creators = await getCreators();

  return (
    <>
      {/* Hero */}
      <section className="relative overflow-hidden">
        <div
          aria-hidden
          className="pointer-events-none absolute right-[-6%] top-[8%] h-[420px] w-[420px] rounded-full bg-mint/25 blur-[110px]"
        />
        <div className="container-content grid items-center gap-14 py-16 lg:grid-cols-[1.05fr_0.95fr] lg:py-24">
          <div>
            <p className="eyebrow rise-in">Fan tipping · South Africa</p>
            <h1 className="heading-xl mt-5 rise-in max-w-xl" style={{ animationDelay: "0.05s" }}>
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
              <Link href="/register" className="btn-primary text-base">
                Start your jar →
              </Link>
              <Link href="/creators" className="btn-ghost text-base">
                Explore creators
              </Link>
            </div>
            <div className="mt-9 flex flex-wrap gap-x-6 gap-y-2 font-mono text-xs uppercase tracking-[0.14em] text-muted rise-in" style={{ animationDelay: "0.2s" }}>
              <span className="inline-flex items-center gap-1.5"><span className="text-green">◆</span> low fees</span>
              <span className="inline-flex items-center gap-1.5"><span className="text-green">◆</span> fast payouts</span>
              <span className="inline-flex items-center gap-1.5"><span className="text-green">◆</span> pay by card</span>
            </div>
          </div>

          {/* Signature: the filling jar. Slips stack below on mobile, float on sm+ */}
          <div className="relative mx-auto w-full max-w-sm py-4 lg:mx-0 lg:ml-auto">
            <JarMeter raised="R2,340" goal="R3,000" pct={78} />
            <TipSlip
              name="Sam"
              amount="R50"
              message="Love your work!"
              className="slip-in mx-auto mt-6 w-full max-w-xs sm:absolute sm:-left-10 sm:top-6 sm:mt-0 sm:w-56 sm:-rotate-3"
              style={{ animationDelay: "0.55s" }}
            />
            <TipSlip
              name="Thandi"
              amount="R120"
              message="Keep it coming 🙌"
              className="slip-in mx-auto mt-4 w-full max-w-xs sm:absolute sm:-right-8 sm:bottom-2 sm:mt-0 sm:w-56 sm:rotate-2"
              style={{ animationDelay: "0.75s" }}
            />
          </div>
        </div>
      </section>

      {/* How a tip flows — a real sequence, so numbered */}
      <section className="border-y border-border bg-white">
        <div className="container-content py-20">
          <div className="flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
            <div>
              <p className="eyebrow">The flow</p>
              <h2 className="heading-xl mt-3 text-4xl md:text-5xl">From tap to payout</h2>
            </div>
            <p className="body-muted max-w-sm">
              Three steps, no faff. Here&apos;s exactly what happens when someone
              wants to back you.
            </p>
          </div>
          <ol className="mt-14 grid gap-8 md:grid-cols-3">
            {FLOW.map((s, i) => (
              <li key={s.n} className="relative">
                {i < FLOW.length - 1 && (
                  <span
                    aria-hidden
                    className="absolute left-12 top-5 hidden h-px w-[calc(100%-2rem)] border-t border-dashed border-border md:block"
                  />
                )}
                <div className="flex items-center gap-4">
                  <span className="grid h-11 w-11 shrink-0 place-items-center rounded-full bg-primary font-mono text-sm font-bold text-white">
                    {s.n}
                  </span>
                </div>
                <h3 className="mt-5 font-display text-xl font-bold text-ink">{s.title}</h3>
                <p className="body-muted mt-2">{s.body}</p>
              </li>
            ))}
          </ol>
        </div>
      </section>

      {/* Features */}
      <section className="container-content py-20">
        <div className="max-w-2xl">
          <p className="eyebrow">Why Tipping Jar</p>
          <h2 className="heading-xl mt-3 text-4xl md:text-5xl">
            Built for the moment someone says thanks
          </h2>
        </div>
        <div className="mt-12 grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {FEATURES.map((f) => (
            <div key={f.title} className="card transition duration-200 hover:-translate-y-1 hover:shadow-lift">
              <div className={`grid h-12 w-12 place-items-center rounded-2xl text-2xl ${f.tint}`}>
                {f.icon}
              </div>
              <h3 className="mt-5 font-display text-lg font-bold text-ink">{f.title}</h3>
              <p className="body-muted mt-2">{f.body}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Featured creators */}
      {creators.length > 0 && (
        <section className="border-t border-border bg-white">
          <div className="container-content py-20">
            <div className="flex items-end justify-between">
              <div>
                <p className="eyebrow">On the platform</p>
                <h2 className="heading-xl mt-3 text-4xl md:text-5xl">Creators filling their jars</h2>
              </div>
              <Link href="/creators" className="hidden text-sm font-semibold text-green hover:underline sm:block">
                View all →
              </Link>
            </div>
            <div className="mt-10 grid gap-6 md:grid-cols-2 lg:grid-cols-3">
              {creators.map((c) => (
                <CreatorCard key={c.id} creator={c} />
              ))}
            </div>
          </div>
        </section>
      )}

      {/* CTA */}
      <section className="container-content py-20">
        <div className="relative overflow-hidden rounded-[28px] bg-navy px-8 py-16 text-center md:px-16">
          <span aria-hidden className="pointer-events-none absolute -right-10 -top-10 h-48 w-48 rounded-full bg-mint/20 blur-3xl" />
          <p className="eyebrow !text-mint">Your jar is waiting</p>
          <h2 className="heading-xl mt-4 text-white">Start collecting support today</h2>
          <p className="mx-auto mt-4 max-w-lg text-white/75">
            Set up your page, share one link, and let the tips add up.
          </p>
          <Link
            href="/register"
            className="mt-9 inline-flex rounded-full bg-white px-8 py-3.5 font-semibold !text-primary shadow-lift transition hover:bg-white/90"
          >
            Create your jar
          </Link>
        </div>
      </section>
    </>
  );
}
