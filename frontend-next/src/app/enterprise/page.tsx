// Enterprise marketing page — ported from frontend/lib/screens/enterprise_screen.dart
// Static server component, rendered in the dark brand theme to match the site.

import Link from "next/link";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Enterprise — Tipping Jar",
  description:
    "Tipping at scale for your platform. White-label, custom contracts, dedicated infrastructure, and a 99.99% SLA.",
};

const LOGOS = ["Streamio", "CreatorHub", "FanBridge", "PodPay", "LiveLink", "ArtPass"];

const FEATURES = [
  { icon: "🛡️", title: "SOC 2 Type II", body: "Fully audited security controls with annual third-party pen testing." },
  { icon: "🏢", title: "White-label", body: "Your brand, your domain — TippingJar is invisible to your users." },
  { icon: "🔌", title: "Enterprise API", body: "High-throughput REST + webhooks with dedicated rate limits." },
  { icon: "🎧", title: "Dedicated support", body: "24/7 Slack channel with a named account manager and 1-hour SLA." },
  { icon: "🏦", title: "Custom payouts", body: "Bespoke settlement schedules, multi-currency, and T+1 options." },
  { icon: "📊", title: "Advanced analytics", body: "Real-time dashboards, cohort analysis, and raw data exports." },
  { icon: "🔐", title: "SSO & SCIM", body: "SAML 2.0, OIDC, Okta, and Azure AD provisioning out of the box." },
  { icon: "🎛️", title: "Custom contracts", body: "Volume pricing, MSA, BAA, and data processing agreements." },
];

export default function EnterprisePage() {
  return (
    <>
      {/* Hero */}
      <section className="relative overflow-hidden">
        <div className="absolute inset-0 -z-10 bg-brand-gradient opacity-[0.12]" />
        <div className="container-content py-24 text-center md:py-32">
          <span className="inline-block rounded-full border border-border bg-card px-4 py-1.5 text-sm text-teal">
            Enterprise
          </span>
          <h1 className="heading-xl mx-auto mt-6 max-w-3xl">
            Tipping at scale{" "}
            <span className="bg-brand-gradient bg-clip-text text-transparent">
              for your platform
            </span>
          </h1>
          <p className="body-muted mx-auto mt-6 max-w-xl text-lg">
            Power fan monetisation for communities of any size. White-label, custom contracts,
            dedicated infrastructure, and a 99.99% SLA.
          </p>
          <div className="mt-9 flex flex-wrap items-center justify-center gap-4">
            <Link href="/contact" className="btn-primary text-base">
              Contact sales
            </Link>
            <Link href="/enterprise-portal" className="btn-ghost text-base">
              Go to portal
            </Link>
          </div>
        </div>
      </section>

      {/* Trusted by */}
      <section className="border-y border-border bg-dark">
        <div className="container-content py-14">
          <p className="text-center text-xs font-semibold uppercase tracking-widest text-muted">
            Trusted by leading platforms
          </p>
          <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
            {LOGOS.map((name) => (
              <span
                key={name}
                className="rounded-lg border border-border bg-card px-4 py-2 text-sm font-bold text-muted"
              >
                {name}
              </span>
            ))}
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="container-content py-20">
        <h2 className="heading-xl text-center">Built for the enterprise</h2>
        <p className="body-muted mx-auto mt-3 max-w-xl text-center">
          Everything you need to run tipping at scale.
        </p>
        <div className="mt-12 grid gap-6 md:grid-cols-2 lg:grid-cols-4">
          {FEATURES.map((f) => (
            <div key={f.title} className="card">
              <div className="grid h-10 w-10 place-items-center rounded-xl bg-primary/15 text-lg">
                {f.icon}
              </div>
              <h3 className="mt-4 font-semibold text-white">{f.title}</h3>
              <p className="body-muted mt-2 text-sm">{f.body}</p>
            </div>
          ))}
        </div>
      </section>

      {/* CTA */}
      <section className="container-content pb-24">
        <div className="rounded-3xl bg-brand-gradient p-12 text-center md:p-16">
          <div className="mx-auto grid h-14 w-14 place-items-center rounded-full bg-white/15 text-2xl">
            🏢
          </div>
          <h2 className="heading-xl mt-6">Ready to talk?</h2>
          <p className="mx-auto mt-4 max-w-lg text-white/85">
            Our sales team will respond within one business day.
          </p>
          <Link
            href="/contact"
            className="mt-8 inline-flex rounded-full bg-white px-8 py-3 font-semibold text-primary transition hover:opacity-90"
          >
            Schedule a demo
          </Link>
        </div>
      </section>
    </>
  );
}
