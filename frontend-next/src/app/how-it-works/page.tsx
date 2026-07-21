"use client";

import Link from "next/link";
import { useState } from "react";

interface Step {
  icon: string;
  title: string;
  body: string;
}

const FAN_STEPS: Step[] = [
  {
    icon: "🔍",
    title: "Discover creators",
    body: "Browse The Tipping Jar's creator directory. Search by name, category, or trending. Every creator has a public page showing their work, bio, and tip feed.",
  },
  {
    icon: "🙌",
    title: "Choose your amount",
    body: "Pick a quick amount (R5 · R10 · R20 · R50) or enter a custom value. No account needed — tip anonymously or leave your name and a message.",
  },
  {
    icon: "💳",
    title: "Pay securely",
    body: "Enter your card details on our fully encrypted, PCI-DSS compliant checkout. Your payment info is never stored on The Tipping Jar servers.",
  },
  {
    icon: "✅",
    title: "Tip confirmed!",
    body: "Your tip lands on the creator's page instantly. They'll see your name and message in real time. You'll receive an email receipt automatically.",
  },
];

const CREATOR_STEPS: Step[] = [
  {
    icon: "🧑‍🎤",
    title: "Sign up as a creator",
    body: "Register with your email, pick a username, and select the \"Creator\" role. Your profile slug becomes your unique tip link: tippingjar.com/you.",
  },
  {
    icon: "🎨",
    title: "Customise your page",
    body: "Upload a cover photo and avatar, write a tagline, and set a monthly tip goal. Your page goes live the moment you save — no approval required.",
  },
  {
    icon: "🏦",
    title: "Connect your bank",
    body: "Link your South African bank account in under 2 minutes. The Tipping Jar never holds your money — funds go straight to your bank account.",
  },
  {
    icon: "🔗",
    title: "Share your link",
    body: "Post tippingjar.com/you anywhere — your bio, videos, newsletter, or Linktree. Every visit is a potential tip. Watch your jar fill up in real time.",
  },
];

const TIMELINE: string[] = [
  "Fan visits creator's page",
  "Picks an amount & adds a message",
  "Pays securely — fully encrypted",
  "Creator receives funds in their bank account",
  "Creator sees tip on their dashboard",
];

const SECURITY_BADGES: [string, string][] = [
  ["🔒", "PCI-DSS Level 1"],
  ["✅", "Bank-grade Encryption"],
  ["🛡️", "TLS in transit"],
  ["🚫", "Zero card data stored"],
];

const FAQS: [string, string][] = [
  [
    "How much does The Tipping Jar take?",
    "The Tipping Jar charges a 3% platform fee per tip. A 3% payment processing fee (excl. VAT) also applies. No subscriptions, no hidden charges — just transparent, simple pricing.",
  ],
  [
    "When do I get paid?",
    "Funds are settled to your linked bank account on a rolling basis after each successful tip. Payout timing depends on your bank but is typically within 1–2 business days.",
  ],
  [
    "Do fans need an account to tip?",
    "No. Fans can tip completely anonymously without registering. They just need a card. If they want to track their tips, they can create a free account.",
  ],
  [
    "Which countries are supported?",
    "The Tipping Jar is currently available in South Africa only. Creators must be based in South Africa to receive payouts. We plan to expand to more countries soon.",
  ],
  [
    "Is my payment information safe?",
    "Yes. The Tipping Jar never stores card details. All payment data is handled through a PCI-DSS Level 1 certified payment processor — the highest level of payment security available.",
  ],
  [
    "Can I set a monthly tip goal?",
    "Absolutely. Add a goal amount on your creator profile. A progress bar appears on your tip page, giving fans a tangible target to rally around.",
  ],
  [
    "What if a tip is refunded?",
    "Fans can request a refund within 7 days of tipping. Refunds are processed and deducted from your next payout. The Tipping Jar will notify you by email.",
  ],
];

export default function HowItWorksPage() {
  const [tab, setTab] = useState(0);
  const [openFaq, setOpenFaq] = useState(-1);
  const steps = tab === 0 ? FAN_STEPS : CREATOR_STEPS;

  return (
    <>
      {/* Hero */}
      <section className="border-b border-border bg-darker">
        <div className="container-content py-20 text-center md:py-24">
          <span className="inline-block rounded-full border border-teal/30 bg-teal/10 px-4 py-1.5 text-sm font-semibold text-teal">
            How it works
          </span>
          <h1 className="heading-xl mx-auto mt-6 max-w-2xl">
            Simple for fans. Powerful for creators.
          </h1>
          <p className="body-muted mx-auto mt-5 max-w-xl text-lg">
            The Tipping Jar removes every barrier between appreciation and action. No
            complicated setup, no waiting periods — just simple, transparent fees.
          </p>
        </div>
      </section>

      {/* Steps with tabs */}
      <section className="container-content py-16 md:py-20">
        <div className="flex justify-center">
          <div className="inline-flex rounded-full border border-border bg-card p-1.5">
            {["I'm a fan", "I'm a creator"].map((t, i) => (
              <button
                key={t}
                onClick={() => setTab(i)}
                className={`rounded-full px-6 py-2 text-sm font-semibold transition ${
                  tab === i ? "bg-brand-gradient text-ink" : "text-muted hover:text-ink"
                }`}
              >
                {t}
              </button>
            ))}
          </div>
        </div>

        <div className="mt-12 grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {steps.map((s, i) => (
            <div key={s.title} className="card transition hover:border-teal">
              <div className="flex items-center justify-between">
                <span className="grid h-12 w-12 place-items-center rounded-xl bg-teal/10 text-2xl">
                  {s.icon}
                </span>
                <span className="text-3xl font-black text-border">
                  0{i + 1}
                </span>
              </div>
              <h3 className="mt-5 font-semibold text-ink">{s.title}</h3>
              <p className="body-muted mt-2 text-sm">{s.body}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Timeline */}
      <section className="border-y border-border bg-dark">
        <div className="container-content py-16 md:py-20">
          <div className="text-center">
            <span className="inline-block rounded-full border border-teal/30 bg-teal/10 px-4 py-1.5 text-sm font-semibold text-teal">
              The full journey
            </span>
            <h2 className="mt-4 text-3xl font-extrabold tracking-tight">From tap to payout</h2>
            <p className="body-muted mt-3">Every step, clear and fast.</p>
          </div>
          <div className="mx-auto mt-12 max-w-xl">
            {TIMELINE.map((label, i) => (
              <div key={label} className="flex gap-4">
                <div className="flex flex-col items-center">
                  <span className="grid h-9 w-9 shrink-0 place-items-center rounded-full border-2 border-teal/40 bg-teal/10 text-sm text-teal">
                    ✓
                  </span>
                  {i < TIMELINE.length - 1 && <span className="w-0.5 flex-1 bg-border" />}
                </div>
                <p className="pb-6 pt-1.5 font-medium text-ink">{label}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Security strip */}
      <section className="container-content py-16 md:py-20 text-center">
        <h2 className="text-3xl font-extrabold tracking-tight">Your money is safe.</h2>
        <p className="body-muted mt-3">
          All payments are secured end-to-end. We never see your card number.
        </p>
        <div className="mt-10 flex flex-wrap justify-center gap-3">
          {SECURITY_BADGES.map(([icon, label]) => (
            <div
              key={label}
              className="flex items-center gap-3 rounded-2xl border border-border bg-card px-5 py-3.5"
            >
              <span className="grid h-8 w-8 place-items-center rounded-lg bg-teal/10 text-base">
                {icon}
              </span>
              <span className="text-sm font-semibold text-ink">{label}</span>
            </div>
          ))}
        </div>
      </section>

      {/* FAQ */}
      <section className="border-y border-border bg-dark">
        <div className="container-content py-16 md:py-20">
          <div className="text-center">
            <span className="inline-block rounded-full border border-teal/30 bg-teal/10 px-4 py-1.5 text-sm font-semibold text-teal">
              FAQ
            </span>
            <h2 className="mt-4 text-3xl font-extrabold tracking-tight">Common questions</h2>
          </div>
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
                      className={`text-muted transition-transform ${open ? "rotate-180" : ""}`}
                    >
                      ⌄
                    </span>
                  </button>
                  {open && <p className="body-muted px-4 pb-4 text-sm">{a}</p>}
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="container-content py-20">
        <div className="rounded-3xl bg-brand-gradient p-12 text-center md:p-16">
          <h2 className="heading-xl text-ink">Ready to start?</h2>
          <p className="mx-auto mt-4 max-w-md text-white/85">
            Set up your jar in 60 seconds — no credit card needed.
          </p>
          <div className="mt-8 flex flex-wrap items-center justify-center gap-4">
            <Link
              href="/register"
              className="inline-flex rounded-full bg-white px-8 py-3 font-semibold text-primary transition hover:opacity-90"
            >
              Create your page →
            </Link>
            <Link
              href="/creators"
              className="inline-flex rounded-full border border-white/40 px-8 py-3 font-semibold text-ink transition hover:border-white"
            >
              Browse creators
            </Link>
          </div>
          <p className="mt-4 text-xs text-white/60">No credit card · Free forever</p>
        </div>
      </section>
    </>
  );
}
