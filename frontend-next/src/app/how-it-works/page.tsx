"use client";

import Link from "next/link";
import { useState } from "react";
import { PageHero, PageCta } from "@/components/PageHero";
import { Aurora } from "@/components/Aurora";

interface Step {
  icon: string;
  title: string;
  body: string;
}

const FAN_STEPS: Step[] = [
  {
    icon: "bi-search",
    title: "Discover creators",
    body: "Browse the creator directory — search by name or category. Every creator has a public page showing their work, goals, and live tip feed.",
  },
  {
    icon: "bi-cash-coin",
    title: "Choose your amount",
    body: "Pick a quick amount (R20 · R50 · R100) or enter a custom value from R10. No account needed — tip anonymously or leave your name and a message.",
  },
  {
    icon: "bi-credit-card-fill",
    title: "Pay securely",
    body: "Card details go straight to a PCI-DSS compliant checkout over an encrypted connection. Nothing is ever stored on Tipping Jar servers.",
  },
  {
    icon: "bi-check-circle-fill",
    title: "Tip confirmed!",
    body: "Your tip lands on the creator's page instantly. They see your name and message in real time; a receipt lands in your inbox automatically.",
  },
];

const CREATOR_STEPS: Step[] = [
  {
    icon: "bi-person-badge-fill",
    title: "Sign up as a creator",
    body: "Register, pick a name, and answer a few quick setup questions. Your slug becomes your unique link: tippingjar.co.za/creator/you.",
  },
  {
    icon: "bi-palette-fill",
    title: "Complete your page",
    body: "Cover photo, avatar, tagline, goal, preset amounts. Your tip page opens for fans the moment your profile hits 100% complete.",
  },
  {
    icon: "bi-bank",
    title: "Add your bank account",
    body: "Link your South African bank account in under two minutes — that's where your payouts land when you request them.",
  },
  {
    icon: "bi-link-45deg",
    title: "Share your link",
    body: "Post your link anywhere — bio, videos, newsletter, WhatsApp status. Every visit is a potential tip. Watch your jar fill in real time.",
  },
];

const TIMELINE: string[] = [
  "Fan opens the creator's page",
  "Picks an amount & adds a message",
  "Pays securely — fully encrypted",
  "The tip lands in the creator's balance",
  "Creator requests a payout to their bank",
];

const SECURITY_BADGES: [string, string][] = [
  ["bi-shield-lock-fill", "PCI-DSS compliant gateway"],
  ["bi-check-circle-fill", "Bank-grade encryption"],
  ["bi-shield-check", "TLS in transit"],
  ["bi-slash-circle", "Zero card data stored"],
];

const FAQS: [string, string][] = [
  [
    "How much does Tipping Jar take?",
    "6% flat when a tip lands — 3% platform fee and 3% card & service fee. No subscriptions, no hidden charges. You only pay when you get paid.",
  ],
  [
    "When do I get paid?",
    "Tips land in your balance as they're paid. Request a payout from your dashboard and it's transferred to your South African bank account — typically within 1–2 business days.",
  ],
  [
    "Do fans need an account to tip?",
    "No. Fans can tip completely anonymously without registering. They just need a card. If they want to track their tips, they can create a free account.",
  ],
  [
    "Which countries are supported?",
    "Tipping Jar is currently available in South Africa — creators must be based in South Africa to receive payouts. Fans can tip from anywhere. More countries soon.",
  ],
  [
    "Is my payment information safe?",
    "Yes. Tipping Jar never stores card details. All payment data is handled by a PCI-DSS compliant payment gateway — card numbers never touch our servers.",
  ],
  [
    "Can I set a monthly tip goal?",
    "Absolutely. Add a goal on your profile and a live progress bar appears on your tip page — a tangible target for fans to rally around. You can run separate campaign jars too.",
  ],
  [
    "What if a tip is refunded?",
    "Fans can request a refund within 7 days of tipping. Refunds are deducted from your balance and you're notified by email.",
  ],
];

export default function HowItWorksPage() {
  const [tab, setTab] = useState(0);
  const [openFaq, setOpenFaq] = useState(-1);
  const steps = tab === 0 ? FAN_STEPS : CREATOR_STEPS;

  return (
    <>
      <PageHero
        eyebrow="How it works"
        title="Simple for fans. Powerful for creators."
        sub="Tipping Jar removes every barrier between appreciation and action. No complicated setup, no waiting periods — just simple, transparent fees."
      />

      {/* Steps with tabs */}
      <section className="relative overflow-hidden bg-white">
        <Aurora />
        <div className="container-content relative py-16 md:py-20">
          <div className="flex justify-center">
            <div className="inline-flex rounded-full border border-border bg-white p-1.5 shadow-soft">
              {["I'm a fan", "I'm a creator"].map((t, i) => (
                <button
                  key={t}
                  onClick={() => setTab(i)}
                  className={`rounded-full px-6 py-2 text-sm font-semibold transition ${
                    tab === i ? "bg-primary text-white shadow-soft" : "text-muted hover:text-ink"
                  }`}
                >
                  {t}
                </button>
              ))}
            </div>
          </div>

          <div key={tab} className="relative mt-12 grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
            <span
              aria-hidden
              className="pointer-events-none absolute left-[6%] right-[6%] top-[54px] hidden border-t-2 border-dashed border-green/30 lg:block"
            />
            {steps.map((s, i) => (
              <div key={s.title} className="glass-card group h-full p-6">
                <div className="flex items-center justify-between">
                  <span className="glass-tile h-12 w-12 text-xl">
                    <i className={`bi ${s.icon}`} />
                  </span>
                  <span className="font-display text-4xl font-extrabold text-green/15 transition group-hover:text-green/30">
                    0{i + 1}
                  </span>
                </div>
                <h3 className="mt-5 font-display text-lg font-bold text-ink">{s.title}</h3>
                <p className="body-muted mt-2 text-sm leading-relaxed">{s.body}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Timeline */}
      <section className="relative overflow-hidden border-y border-border bg-[#f3f9f5]">
        <Aurora />
        <div className="container-content relative py-16 md:py-20">
          <div className="text-center">
            <p className="eyebrow">The full journey</p>
            <h2 className="heading-xl mt-3 text-3xl md:text-4xl">From tap to payout</h2>
            <p className="body-muted mt-3">Every step, clear and fast.</p>
          </div>
          <div className="mx-auto mt-12 max-w-xl">
            {TIMELINE.map((label, i) => (
              <div key={label} className="flex gap-4">
                <div className="flex flex-col items-center">
                  <span className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-mint text-sm text-navy shadow-soft">
                    <i className="bi bi-check-lg" />
                  </span>
                  {i < TIMELINE.length - 1 && (
                    <span className="w-0.5 flex-1 bg-gradient-to-b from-mint to-green/30" />
                  )}
                </div>
                <div className="w-full pb-6 pt-0.5">
                  <div className="rounded-2xl border border-border bg-white px-4 py-3 font-medium text-ink shadow-soft">
                    {label}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Security strip */}
      <section className="container-content py-16 text-center md:py-20">
        <p className="eyebrow">Security</p>
        <h2 className="heading-xl mt-3 text-3xl md:text-4xl">Your money is safe.</h2>
        <p className="body-muted mx-auto mt-3 max-w-md">
          All payments are secured end-to-end. We never see your card number.
        </p>
        <div className="mt-10 flex flex-wrap justify-center gap-3">
          {SECURITY_BADGES.map(([icon, label]) => (
            <div
              key={label}
              className="flex items-center gap-3 rounded-2xl border border-border bg-white px-5 py-3.5 shadow-soft transition hover:-translate-y-0.5 hover:shadow-lift"
            >
              <span className="grid h-8 w-8 place-items-center rounded-lg bg-mint/15 text-base text-green">
                <i className={`bi ${icon}`} />
              </span>
              <span className="text-sm font-semibold text-ink">{label}</span>
            </div>
          ))}
        </div>
      </section>

      {/* FAQ */}
      <section className="relative overflow-hidden border-y border-border bg-[#f3f9f5]">
        <Aurora />
        <div className="container-content relative py-16 md:py-20">
          <div className="text-center">
            <p className="eyebrow">FAQ</p>
            <h2 className="heading-xl mt-3 text-3xl md:text-4xl">Common questions</h2>
          </div>
          <div className="mx-auto mt-10 max-w-2xl space-y-2.5">
            {FAQS.map(([q, a], i) => {
              const open = openFaq === i;
              return (
                <div
                  key={q}
                  className={`rounded-2xl border bg-white shadow-soft transition ${
                    open ? "border-green/40" : "border-border"
                  }`}
                >
                  <button
                    onClick={() => setOpenFaq(open ? -1 : i)}
                    className="flex w-full items-center justify-between gap-4 p-4 text-left"
                  >
                    <span className="font-display font-bold text-ink">{q}</span>
                    <span
                      aria-hidden
                      className={`grid h-8 w-8 shrink-0 place-items-center rounded-full border font-mono text-base transition ${
                        open ? "rotate-45 border-green text-green" : "border-border text-muted"
                      }`}
                    >
                      +
                    </span>
                  </button>
                  {open && <p className="body-muted px-4 pb-4 text-sm leading-relaxed">{a}</p>}
                </div>
              );
            })}
          </div>
        </div>
      </section>

      <PageCta title="Ready to start?" sub="Set up your jar in minutes — free to start, no credit card needed.">
        <Link
          href="/register"
          className="inline-flex rounded-full bg-white px-8 py-3.5 font-semibold !text-primary shadow-lift transition hover:-translate-y-0.5"
        >
          Create your page →
        </Link>
        <Link
          href="/creators"
          className="inline-flex rounded-full border border-white/25 px-8 py-3.5 font-semibold transition hover:border-white/60 hover:bg-white/10"
        >
          Browse creators
        </Link>
      </PageCta>
    </>
  );
}
