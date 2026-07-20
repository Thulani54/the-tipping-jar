import Link from "next/link";

export const metadata = {
  title: "About — The Tipping Jar",
  description: "We believe creators deserve to be paid. Built by creators, for creators.",
};

const VALUES = [
  {
    icon: "⚡",
    title: "Speed",
    body: "Payouts in 1-2 business days. No waiting weeks to access your own money.",
  },
  {
    icon: "👁️",
    title: "Transparency",
    body: "A single, honest platform fee. No hidden cuts, no confusing tier gates.",
  },
  {
    icon: "💚",
    title: "Creator-first",
    body: "Every product decision starts with: does this help creators earn more?",
  },
  {
    icon: "🔒",
    title: "Trust",
    body: "Bank-grade security, Stripe processing, and a team you can actually reach.",
  },
];

export default function AboutPage() {
  return (
    <>
      {/* Hero */}
      <section className="border-b border-border bg-dark">
        <div className="container-content py-24 text-center md:py-28">
          <span className="inline-block rounded-full border border-border bg-card px-4 py-1.5 text-sm text-teal">
            Our story
          </span>
          <h1 className="heading-xl mx-auto mt-6 max-w-3xl">
            We believe creators deserve to be paid.
          </h1>
          <p className="body-muted mx-auto mt-6 max-w-xl text-lg">
            The Tipping Jar was built by creators, for creators. We got tired of platforms
            taking 30% cuts, delaying payouts, and hiding creators behind algorithms. So we
            built something better.
          </p>
        </div>
      </section>

      {/* Mission */}
      <section className="container-content py-20 md:py-24">
        <div className="grid gap-10 md:grid-cols-2">
          <div>
            <p className="text-sm font-semibold text-teal">Our mission</p>
            <h2 className="heading-xl mt-4 max-w-sm text-3xl md:text-4xl">
              Put money directly in creators&apos; hands.
            </h2>
          </div>
          <div className="space-y-4">
            <p className="body-muted">
              We started The Tipping Jar in 2025 after watching talented friends struggle to
              monetise their work on platforms that took most of the revenue and paid out
              monthly — if at all.
            </p>
            <p className="body-muted">
              We built a platform where creators receive tips directly, payouts hit their bank
              in 1-2 days, and the platform fee is tiny and transparent. No subscriptions. No
              algorithms. Just fans who want to say thank you.
            </p>
          </div>
        </div>
      </section>

      {/* Values */}
      <section className="border-y border-border bg-dark">
        <div className="container-content py-20">
          <h2 className="text-center text-3xl font-extrabold tracking-tight">
            What we stand for
          </h2>
          <div className="mt-12 grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
            {VALUES.map((v) => (
              <div key={v.title} className="card">
                <div className="grid h-11 w-11 place-items-center rounded-xl bg-teal/10 text-xl">
                  {v.icon}
                </div>
                <h3 className="mt-4 font-semibold text-white">{v.title}</h3>
                <p className="body-muted mt-2 text-sm">{v.body}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="container-content py-20">
        <div className="rounded-3xl bg-brand-gradient p-12 text-center md:p-16">
          <h2 className="text-3xl font-extrabold tracking-tight text-white">
            Join us on the mission
          </h2>
          <p className="mx-auto mt-3 max-w-md text-white/85">
            Start your tip page today — it takes under a minute.
          </p>
          <div className="mt-8 flex flex-wrap items-center justify-center gap-4">
            <Link
              href="/register"
              className="inline-flex rounded-full bg-white px-8 py-3 font-semibold text-primary transition hover:opacity-90"
            >
              Create your page
            </Link>
            <Link
              href="/careers"
              className="inline-flex rounded-full border border-white/40 px-8 py-3 font-semibold text-white transition hover:border-white"
            >
              View open roles
            </Link>
          </div>
        </div>
      </section>
    </>
  );
}
