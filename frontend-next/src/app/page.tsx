import Link from "next/link";
import { api } from "@/lib/api";
import { CreatorCard } from "@/components/CreatorCard";
import type { Creator } from "@/types";

const FEATURES = [
  { icon: "💚", tint: "bg-mint/15", title: "Keep more of every tip", body: "Low, transparent fees — creators receive the majority of every rand tipped." },
  { icon: "⚡", tint: "bg-gold/15", title: "Instant setup", body: "Create your page in minutes and start receiving support the same day." },
  { icon: "🔒", tint: "bg-primary/10", title: "Secure payouts", body: "Bank-grade security and verified payouts straight to your account." },
  { icon: "🎯", tint: "bg-mint/15", title: "Goals & milestones", body: "Set tip goals and celebrate milestones with your community." },
  { icon: "🌍", tint: "bg-gold/15", title: "Built for Africa", body: "Local payments, local currency, local support — made in South Africa." },
  { icon: "🧩", tint: "bg-primary/10", title: "Developer API", body: "Embed tipping anywhere with the Tipping Jar platform API." },
];

const STEPS = [
  { n: "1", title: "Create your page", body: "Sign up and set up your creator profile in minutes." },
  { n: "2", title: "Share your link", body: "Drop your tipping link in your bio, streams and posts." },
  { n: "3", title: "Get supported", body: "Fans tip you directly — you keep the majority, always." },
];

const BARS = [38, 52, 44, 66, 58, 80, 72];

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
      <section className="container-content grid items-center gap-14 py-16 lg:grid-cols-2 lg:py-24">
        <div>
          <span className="inline-flex items-center gap-2 rounded-full border border-border bg-white px-4 py-1.5 text-sm font-medium text-primary shadow-sm">
            <span className="h-2 w-2 rounded-full bg-mint" />
            Fan tipping for African creators
          </span>
          <h1 className="heading-xl mt-6 max-w-xl">
            Turn your audience into a{" "}
            <span className="text-primary underline decoration-mint decoration-4 underline-offset-4">
              community of supporters
            </span>
          </h1>
          <p className="body-muted mt-6 max-w-lg text-lg">
            Get tipped by the fans who love what you do. Set up in minutes, keep
            the majority of every tip, and grow your support — all in one place.
          </p>
          <div className="mt-9 flex flex-wrap items-center gap-4">
            <Link href="/register" className="btn-primary text-base">
              Start earning →
            </Link>
            <Link href="/creators" className="btn-ghost text-base">
              Explore creators
            </Link>
          </div>
          <div className="mt-8 flex flex-wrap gap-x-6 gap-y-2 text-sm text-muted">
            <span className="inline-flex items-center gap-1.5"><span className="text-teal">✓</span> Low, transparent fees</span>
            <span className="inline-flex items-center gap-1.5"><span className="text-teal">✓</span> Fast payouts</span>
            <span className="inline-flex items-center gap-1.5">🇿🇦 Made in South Africa</span>
          </div>
        </div>

        {/* Visual — mock earnings + tip cards (no images, all flat) */}
        <div className="relative mx-auto w-full max-w-md lg:mx-0 lg:ml-auto">
          <div className="card">
            <div className="flex items-start justify-between">
              <div>
                <p className="text-xs font-medium uppercase tracking-wide text-muted">This month</p>
                <p className="mt-1 text-3xl font-extrabold text-ink">R2,340</p>
              </div>
              <span className="rounded-full bg-mint/15 px-3 py-1 text-xs font-semibold text-teal">↑ 18%</span>
            </div>
            <div className="mt-6 flex h-28 items-end gap-2">
              {BARS.map((h, i) => (
                <div
                  key={i}
                  className={`flex-1 rounded-t-md ${i === BARS.length - 1 ? "bg-primary" : "bg-primary/25"}`}
                  style={{ height: `${h}%` }}
                />
              ))}
            </div>
            <div className="mt-4 flex justify-between text-[11px] text-muted">
              <span>Mon</span><span>Tue</span><span>Wed</span><span>Thu</span><span>Fri</span><span>Sat</span><span>Sun</span>
            </div>
          </div>

          <div className="card absolute -bottom-6 -left-4 flex w-64 items-center gap-3 !p-4 sm:-left-8">
            <div className="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-primary text-sm font-bold">S</div>
            <div className="min-w-0">
              <p className="truncate text-sm font-semibold text-ink">Sam tipped R50 💚</p>
              <p className="truncate text-xs text-muted">&ldquo;Love your work!&rdquo;</p>
            </div>
          </div>

          <div className="card absolute -right-3 -top-5 flex items-center gap-2 !p-3">
            <span className="text-lg">🎯</span>
            <div>
              <p className="text-xs font-semibold text-ink">Goal 78%</p>
              <div className="mt-1 h-1.5 w-20 overflow-hidden rounded-full bg-border">
                <div className="h-full w-[78%] rounded-full bg-gold" />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Value band */}
      <section className="border-y border-border bg-white">
        <div className="container-content grid gap-8 py-10 text-center sm:grid-cols-3">
          {[
            ["Minutes", "to set up your page"],
            ["Majority", "of every tip kept by creators"],
            ["Local", "ZAR payments & payouts"],
          ].map(([big, small]) => (
            <div key={big}>
              <p className="text-2xl font-extrabold text-primary">{big}</p>
              <p className="body-muted mt-1">{small}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Features */}
      <section className="container-content py-20">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="heading-xl">Everything you need to get supported</h2>
          <p className="body-muted mt-4">
            A complete toolkit to turn appreciation into sustainable income.
          </p>
        </div>
        <div className="mt-12 grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {FEATURES.map((f) => (
            <div key={f.title} className="card transition hover:-translate-y-1">
              <div className={`grid h-12 w-12 place-items-center rounded-2xl text-2xl ${f.tint}`}>
                {f.icon}
              </div>
              <h3 className="mt-5 text-lg font-semibold text-ink">{f.title}</h3>
              <p className="body-muted mt-2">{f.body}</p>
            </div>
          ))}
        </div>
      </section>

      {/* How it works */}
      <section className="border-y border-border bg-white">
        <div className="container-content py-20">
          <h2 className="heading-xl text-center">How it works</h2>
          <div className="mt-12 grid gap-6 md:grid-cols-3">
            {STEPS.map((s) => (
              <div key={s.n} className="card text-center">
                <div className="mx-auto grid h-12 w-12 place-items-center rounded-full bg-primary text-lg font-bold">
                  {s.n}
                </div>
                <h3 className="mt-5 text-lg font-semibold text-ink">{s.title}</h3>
                <p className="body-muted mt-2">{s.body}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Featured creators */}
      {creators.length > 0 && (
        <section className="container-content py-20">
          <div className="flex items-end justify-between">
            <h2 className="heading-xl">Featured creators</h2>
            <Link href="/creators" className="text-sm font-semibold text-teal hover:underline">
              View all →
            </Link>
          </div>
          <div className="mt-10 grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {creators.map((c) => (
              <CreatorCard key={c.id} creator={c} />
            ))}
          </div>
        </section>
      )}

      {/* CTA — solid navy */}
      <section className="container-content pb-24">
        <div className="rounded-3xl bg-primary p-12 text-center md:p-16">
          <h2 className="heading-xl">Ready to start?</h2>
          <p className="mx-auto mt-4 max-w-lg text-white/80">
            Join creators across Africa turning their passion into support.
          </p>
          <Link
            href="/register"
            className="mt-8 inline-flex rounded-full bg-white px-8 py-3 font-semibold !text-primary transition hover:bg-white/90"
          >
            Create your page
          </Link>
        </div>
      </section>
    </>
  );
}
