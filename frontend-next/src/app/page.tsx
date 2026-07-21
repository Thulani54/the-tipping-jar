import Link from "next/link";
import { api } from "@/lib/api";
import { CreatorCard } from "@/components/CreatorCard";
import type { Creator } from "@/types";

const FEATURES = [
  { icon: "💚", title: "Keep more of every tip", body: "Low, transparent fees. Creators receive the majority of every rand tipped." },
  { icon: "⚡", title: "Instant setup", body: "Create your page in minutes and start receiving support the same day." },
  { icon: "🔒", title: "Secure payouts", body: "Bank-grade security and verified payouts straight to your account." },
  { icon: "🎯", title: "Goals & milestones", body: "Set tip goals and celebrate milestones with your community." },
  { icon: "🌍", title: "Built for Africa", body: "Local payments, local currency, local support — made in South Africa." },
  { icon: "🧩", title: "Developer API", body: "Embed tipping anywhere with the Tipping Jar platform API." },
];

const STEPS = [
  { n: "1", title: "Create your page", body: "Sign up and set up your creator profile in minutes." },
  { n: "2", title: "Share your link", body: "Drop your tipping link in your bio, streams and posts." },
  { n: "3", title: "Get supported", body: "Fans tip you directly — you keep the majority, always." },
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
        <div className="absolute inset-0 -z-10 bg-brand-gradient opacity-[0.12]" />
        <div className="container-content py-24 text-center md:py-32">
          <span className="inline-block rounded-full border border-border bg-card px-4 py-1.5 text-sm text-teal">
            💚 The fan-tipping platform for creators
          </span>
          <h1 className="heading-xl mx-auto mt-6 max-w-3xl">
            Turn your audience into a{" "}
            <span className="bg-brand-gradient bg-clip-text text-transparent">
              community of supporters
            </span>
          </h1>
          <p className="body-muted mx-auto mt-6 max-w-xl text-lg">
            Get tipped by the fans who love what you do. Set up in minutes, keep
            the majority of every tip, and grow your support — all in one place.
          </p>
          <div className="mt-9 flex flex-wrap items-center justify-center gap-4">
            <Link href="/register" className="btn-primary text-base">
              Start earning →
            </Link>
            <Link href="/creators" className="btn-ghost text-base">
              Explore creators
            </Link>
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="container-content py-20">
        <h2 className="heading-xl text-center">Everything you need to get supported</h2>
        <div className="mt-12 grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {FEATURES.map((f) => (
            <div key={f.title} className="card">
              <div className="text-3xl">{f.icon}</div>
              <h3 className="mt-4 text-lg font-semibold text-ink">{f.title}</h3>
              <p className="body-muted mt-2">{f.body}</p>
            </div>
          ))}
        </div>
      </section>

      {/* How it works */}
      <section className="border-y border-border bg-dark">
        <div className="container-content py-20">
          <h2 className="heading-xl text-center">How it works</h2>
          <div className="mt-12 grid gap-6 md:grid-cols-3">
            {STEPS.map((s) => (
              <div key={s.n} className="card text-center">
                <div className="mx-auto grid h-12 w-12 place-items-center rounded-full bg-brand-gradient text-lg font-bold">
                  {s.n}
                </div>
                <h3 className="mt-4 text-lg font-semibold">{s.title}</h3>
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
            <Link href="/creators" className="text-sm text-teal hover:underline">
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

      {/* CTA */}
      <section className="container-content pb-24">
        <div className="rounded-3xl bg-brand-gradient p-12 text-center md:p-16">
          <h2 className="heading-xl">Ready to start?</h2>
          <p className="mx-auto mt-4 max-w-lg text-white/85">
            Join creators across Africa turning their passion into support.
          </p>
          <Link
            href="/register"
            className="mt-8 inline-flex rounded-full bg-white px-8 py-3 font-semibold text-primary transition hover:opacity-90"
          >
            Create your page
          </Link>
        </div>
      </section>
    </>
  );
}
