"use client";

import Link from "next/link";
import { useState } from "react";

interface Tier {
  name: string;
  price: string;
  period: string;
  desc: string;
  features: string[];
  cta: string;
  href: string;
  isPro: boolean;
}

const TIERS: Tier[] = [
  {
    name: "Free",
    price: "$0",
    period: "/month",
    desc: "Perfect for getting started",
    features: [
      "Unlimited tips received",
      "5% platform fee per tip",
      "Public tip page",
      "Basic analytics",
      "Email notifications",
      "Stripe payouts (T+2)",
    ],
    cta: "Get started free",
    href: "/register",
    isPro: false,
  },
  {
    name: "Pro",
    price: "$12",
    period: "/month",
    desc: "For creators serious about growth",
    features: [
      "Everything in Free",
      "2.5% platform fee per tip",
      "Custom domain",
      "Advanced analytics & exports",
      "Priority payouts (T+1)",
      "Custom tip amounts & goals",
      "Remove The Tipping Jar branding",
      "Priority email support",
    ],
    cta: "Start Pro — 14 days free",
    href: "/register",
    isPro: true,
  },
  {
    name: "Enterprise",
    price: "Custom",
    period: "",
    desc: "For platforms & large communities",
    features: [
      "Everything in Pro",
      "Custom platform fee",
      "White-label branding",
      "SSO & SCIM provisioning",
      "Dedicated account manager",
      "SLA guarantee",
      "Custom payout schedules",
      "Data processing agreement",
    ],
    cta: "Contact sales",
    href: "/contact",
    isPro: false,
  },
];

const COMPARE_ROWS: [string, string, string, string][] = [
  ["Platform fee", "5%", "2.5%", "Custom"],
  ["Payouts", "T+2", "T+1", "Custom"],
  ["Custom domain", "no", "yes", "yes"],
  ["Remove branding", "no", "yes", "yes"],
  ["Advanced analytics", "no", "yes", "yes"],
  ["Priority support", "no", "yes", "yes"],
  ["White-label", "no", "no", "yes"],
  ["SSO & SCIM", "no", "no", "yes"],
  ["SLA", "no", "no", "yes"],
];

const FAQS: [string, string][] = [
  [
    "Is the Free plan really free?",
    "Yes. You keep your page, receive unlimited tips, and pay zero monthly fee. We only take a 5% cut of each tip received.",
  ],
  [
    "When do I get paid?",
    "Free creators receive payouts 2 business days after a tip is processed. Pro creators get next-day payouts.",
  ],
  [
    "Can I cancel anytime?",
    "Absolutely. Cancel your Pro subscription any time from your dashboard — no lock-in, no questions asked.",
  ],
  [
    "What payment methods do fans use?",
    "Fans can tip via any major credit or debit card, Apple Pay, and Google Pay. Stripe handles all processing.",
  ],
  [
    "Do you offer refunds?",
    "Tips are non-refundable by default. If you believe a fraudulent tip occurred, contact our support team within 7 days.",
  ],
];

function cellClass(value: string): string {
  if (value === "yes") return "text-teal font-semibold";
  if (value === "no") return "text-muted/40 font-semibold";
  return "text-muted font-semibold";
}

// Render yes/no sentinels as crisp Bootstrap icons; pass other text through.
function cellContent(value: string) {
  if (value === "yes") return <i className="bi bi-check-lg" />;
  if (value === "no") return <i className="bi bi-x-lg" />;
  return value;
}

export default function PricingPage() {
  const [openFaq, setOpenFaq] = useState(-1);

  return (
    <>
      {/* Hero */}
      <section className="border-b border-border bg-darker">
        <div className="container-content py-20 text-center md:py-24">
          <span className="inline-block rounded-full border border-teal/30 bg-teal/10 px-4 py-1.5 text-sm font-semibold text-teal">
            Pricing
          </span>
          <h1 className="heading-xl mt-6">Simple, transparent pricing</h1>
          <p className="body-muted mx-auto mt-4 max-w-lg text-lg">
            Start free. Upgrade when you&apos;re ready. No hidden fees.
          </p>
        </div>
      </section>

      {/* Tiers */}
      <section className="container-content py-16 md:py-20">
        <div className="grid gap-6 md:grid-cols-3">
          {TIERS.map((t) => (
            <div
              key={t.name}
              className={`card flex flex-col ${
                t.isPro ? "border-teal/50 ring-1 ring-teal/20" : ""
              }`}
            >
              {t.isPro && (
                <span className="mb-3 inline-flex w-fit rounded-full bg-teal px-3 py-1 text-xs font-bold text-ink">
                  Most popular
                </span>
              )}
              <h2 className="text-xl font-extrabold text-ink">{t.name}</h2>
              <p className="mt-1 text-sm text-muted">{t.desc}</p>
              <div className="mt-4 flex items-end gap-1">
                <span
                  className={`font-extrabold tracking-tight ${
                    t.isPro ? "text-teal" : "text-ink"
                  } ${t.price.length > 4 ? "text-3xl" : "text-4xl"}`}
                >
                  {t.price}
                </span>
                {t.period && <span className="pb-1 text-sm text-muted">{t.period}</span>}
              </div>
              <ul className="mt-6 space-y-2.5">
                {t.features.map((f) => (
                  <li key={f} className="flex items-start gap-2 text-sm text-ink">
                    <span className="mt-0.5 text-teal"><i className="bi bi-check-lg" /></span>
                    <span>{f}</span>
                  </li>
                ))}
              </ul>
              <Link
                href={t.href}
                className={`mt-6 w-full text-center text-sm ${
                  t.isPro ? "btn-primary" : "btn-ghost"
                }`}
              >
                {t.cta}
              </Link>
            </div>
          ))}
        </div>
      </section>

      {/* Compare */}
      <section className="border-y border-border bg-darker">
        <div className="container-content py-16 md:py-20">
          <h2 className="text-center text-3xl font-extrabold tracking-tight">
            Compare plans
          </h2>
          <div className="mx-auto mt-10 max-w-3xl overflow-x-auto">
            <table className="w-full text-left">
              <thead>
                <tr className="border-b border-border/80">
                  {["Feature", "Free", "Pro", "Enterprise"].map((h) => (
                    <th
                      key={h}
                      className={`px-3 py-3 text-sm font-bold ${
                        h === "Pro" ? "text-teal" : "text-ink"
                      }`}
                    >
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {COMPARE_ROWS.map((row, i) => (
                  <tr key={row[0]} className={i % 2 === 0 ? "bg-card/40" : ""}>
                    <td className="px-3 py-3 text-sm font-medium text-muted">{row[0]}</td>
                    <td className={`px-3 py-3 text-sm ${cellClass(row[1])}`}>{cellContent(row[1])}</td>
                    <td className={`px-3 py-3 text-sm ${cellClass(row[2])}`}>{cellContent(row[2])}</td>
                    <td className={`px-3 py-3 text-sm ${cellClass(row[3])}`}>{cellContent(row[3])}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section className="container-content py-16 md:py-20">
        <h2 className="text-center text-3xl font-extrabold tracking-tight">
          Frequently asked
        </h2>
        <div className="mx-auto mt-10 max-w-2xl space-y-2.5">
          {FAQS.map(([q, a], i) => {
            const open = openFaq === i;
            return (
              <div
                key={q}
                className={`rounded-2xl border bg-card ${
                  open ? "border-teal/40" : "border-border"
                }`}
              >
                <button
                  onClick={() => setOpenFaq(open ? -1 : i)}
                  className="flex w-full items-center justify-between gap-4 p-4 text-left"
                >
                  <span className="font-semibold text-ink">{q}</span>
                  <span
                    className={`flex text-muted transition-transform ${open ? "rotate-90" : ""}`}
                  >
                    <i className="bi bi-chevron-right" />
                  </span>
                </button>
                {open && <p className="body-muted px-4 pb-4 text-sm">{a}</p>}
              </div>
            );
          })}
        </div>
      </section>

      {/* CTA */}
      <section className="container-content pb-20">
        <div className="card mx-auto max-w-3xl p-10 text-center md:p-14">
          <h2 className="text-3xl font-extrabold tracking-tight">Start for free today</h2>
          <p className="body-muted mx-auto mt-3 max-w-md">
            No credit card required. Upgrade whenever you want.
          </p>
          <Link href="/register" className="btn-primary mt-8 text-base">
            Create your free page →
          </Link>
        </div>
      </section>
    </>
  );
}
