"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { api } from "@/lib/api";
import { PageHero, PageCta } from "@/components/PageHero";
import { Aurora } from "@/components/Aurora";
import { Reveal } from "@/components/Reveal";
import type { FeeQuote } from "@/types";

// Everything is included for every creator — pricing is one flat cut per
// tip, so this page shows the split honestly instead of inventing tiers.
const INCLUDED: [string, string][] = [
  ["bi-infinity", "Unlimited tips received"],
  ["bi-link-45deg", "Your public tip page & link"],
  ["bi-bullseye", "Goals & campaign jars"],
  ["bi-lock-fill", "Exclusive content & subscriptions"],
  ["bi-bar-chart-fill", "Full analytics & CSV exports"],
  ["bi-palette-fill", "Creator Studio graphics"],
  ["bi-people-fill", "Referral commissions"],
  ["bi-bank", "Payouts to your SA bank"],
  ["bi-bell-fill", "Instant notifications"],
];

const FAQS: [string, string][] = [
  [
    "Is it really free to start?",
    "Yes. There's no monthly fee, no setup cost, and no card required to create your page. We only earn when you do — 6% flat when a tip lands.",
  ],
  [
    "What exactly is the 6%?",
    "Two flat fees taken from each tip: 3% platform fee and 3% card & service fee. A R100 tip puts R94 in your balance. That's the whole model.",
  ],
  [
    "When do I get paid?",
    "Tips land in your balance the moment they're paid. Request a payout from your dashboard and it's transferred to your South African bank account, typically within 1–2 business days.",
  ],
  [
    "Is there a minimum tip?",
    "R10 — card processing makes anything smaller uneconomical for the creator, so we keep every tip worth receiving.",
  ],
  [
    "What payment methods can fans use?",
    "Any major credit or debit card, through a PCI-DSS compliant hosted checkout. Fans never need an account.",
  ],
  [
    "What about NGOs, churches and schools?",
    "Organisations register the same way — pick 'organisation' at signup. Same flat pricing; a registration number adds a trust badge to your public page.",
  ],
];

export default function PricingPage() {
  const [openFaq, setOpenFaq] = useState(-1);
  const [amount, setAmount] = useState(100);
  const [quote, setQuote] = useState<FeeQuote | null>(null);

  // Live quote from the real payments API — the same endpoint the tip page
  // uses, so the number here can never drift from what fans actually pay.
  useEffect(() => {
    let alive = true;
    const t = setTimeout(() => {
      api
        .quote(amount)
        .then((q) => alive && setQuote(q))
        .catch(() => alive && setQuote(null));
    }, 200);
    return () => {
      alive = false;
      clearTimeout(t);
    };
  }, [amount]);

  const fee = (v?: string) => (v ? parseFloat(v) : 0);
  const net = quote ? fee(quote.creator_net) : amount * 0.94;
  const platformFee = quote ? fee(quote.platform_fee) : amount * 0.03;
  const serviceFee = quote ? fee(quote.service_fee) : amount * 0.03;

  return (
    <>
      <PageHero
        eyebrow="Pricing"
        title={
          <>
            You only pay when{" "}
            <span className="relative whitespace-nowrap !text-mint">you get paid</span>.
          </>
        }
        sub="No monthly fees. No setup costs. No tiers to compare. 6% flat when a tip lands — that's the whole page."
      />

      {/* The flat fee, shown to scale */}
      <section className="relative overflow-hidden bg-white">
        <Aurora />
        <div className="container-content relative py-16 md:py-20">
          <div className="grid items-center gap-12 lg:grid-cols-[0.95fr_1.05fr]">
            <Reveal>
              <p className="eyebrow">The whole model</p>
              <h2 className="heading-xl mt-3 text-4xl md:text-5xl">6% flat. Nothing else.</h2>
              <p className="body-muted mt-5 max-w-md">
                Two flat fees, taken only when a tip actually lands. Everything on the platform
                is included for every creator — there is no Pro plan to unlock.
              </p>
              <ul className="mt-7 space-y-2.5 font-mono text-sm">
                <li className="flex items-center gap-3 rounded-2xl border border-mint/40 bg-mint/10 px-4 py-3">
                  <span className="h-3 w-3 shrink-0 rounded-full bg-mint" />
                  <span className="font-semibold text-ink">94%</span>
                  <span className="text-muted">— yours, paid to your bank</span>
                </li>
                <li className="flex items-center gap-3 rounded-2xl border border-border bg-white px-4 py-3">
                  <span className="h-3 w-3 shrink-0 rounded-full bg-primary" />
                  <span className="font-semibold text-ink">3%</span>
                  <span className="text-muted">— platform fee</span>
                </li>
                <li className="flex items-center gap-3 rounded-2xl border border-border bg-white px-4 py-3">
                  <span className="h-3 w-3 shrink-0 rounded-full bg-gold" />
                  <span className="font-semibold text-ink">3%</span>
                  <span className="text-muted">— card &amp; service</span>
                </li>
              </ul>
            </Reveal>

            {/* Live calculator — drag a tip, see the real split */}
            <Reveal delay={100} className="glass-card p-6 md:p-8">
              <div className="flex items-center justify-between font-mono text-[11px] uppercase tracking-[0.18em] text-muted">
                <span>Fee calculator</span>
                <span className="inline-flex items-center gap-1 text-green">
                  <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-green" /> live rates
                </span>
              </div>
              <p className="mt-5 text-center font-display text-5xl font-extrabold tracking-tight text-ink">
                R{amount}
              </p>
              <p className="mt-1 text-center font-mono text-[11px] uppercase tracking-[0.18em] text-muted">
                a fan tips you
              </p>
              <input
                type="range"
                min={10}
                max={2000}
                step={10}
                value={amount}
                onChange={(e) => setAmount(parseInt(e.target.value, 10))}
                className="tip-range mt-5"
                aria-label="Tip amount in rands"
              />
              <div className="mt-3 flex flex-wrap justify-center gap-2">
                {[50, 100, 250, 500, 1000].map((v) => (
                  <button
                    key={v}
                    type="button"
                    onClick={() => setAmount(v)}
                    className={`rounded-full px-3 py-1.5 font-mono text-xs transition ${
                      amount === v
                        ? "bg-primary text-white"
                        : "border border-border text-muted hover:border-primary/40"
                    }`}
                  >
                    R{v}
                  </button>
                ))}
              </div>
              <div className="mt-6 space-y-1.5 border-t border-dashed border-border pt-4 font-mono text-[12px] text-muted">
                <div className="flex justify-between">
                  <span>platform fee (3%)</span>
                  <span>− R{platformFee.toFixed(2)}</span>
                </div>
                <div className="flex justify-between">
                  <span>card &amp; service (3%)</span>
                  <span>− R{serviceFee.toFixed(2)}</span>
                </div>
              </div>
              <div className="mt-3 flex items-center justify-between rounded-2xl bg-mint/10 px-4 py-3 ring-1 ring-mint/30">
                <span className="text-sm font-semibold text-ink">You keep</span>
                <span className="font-display text-2xl font-extrabold text-green">
                  R{net.toFixed(2)}
                </span>
              </div>
            </Reveal>
          </div>
        </div>
      </section>

      {/* Everything included */}
      <section className="relative overflow-hidden border-y border-border bg-[#f3f9f5]">
        <Aurora />
        <div className="container-content relative py-16 md:py-20">
          <div className="text-center">
            <p className="eyebrow">No tiers, no upsells</p>
            <h2 className="heading-xl mt-3 text-3xl md:text-4xl">Everything is included</h2>
            <p className="body-muted mx-auto mt-3 max-w-md">
              Every creator gets the full platform from day one.
            </p>
          </div>
          <div className="mx-auto mt-10 grid max-w-3xl gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {INCLUDED.map(([icon, label], i) => (
              <Reveal
                key={label}
                delay={(i % 3) * 70}
                className="flex items-center gap-3 rounded-2xl border border-border bg-white px-4 py-3.5 shadow-soft"
              >
                <span className="grid h-9 w-9 shrink-0 place-items-center rounded-lg bg-mint/15 text-base text-green">
                  <i className={`bi ${icon}`} />
                </span>
                <span className="text-sm font-semibold text-ink">{label}</span>
              </Reveal>
            ))}
          </div>

          {/* Organisations */}
          <Reveal className="mx-auto mt-10 max-w-3xl">
            <div className="flex flex-wrap items-center gap-4 rounded-3xl border border-border bg-white p-6 shadow-soft">
              <span className="grid h-12 w-12 shrink-0 place-items-center rounded-2xl bg-primary/10 text-xl text-primary">
                <i className="bi bi-building-fill-check" />
              </span>
              <div className="min-w-0 flex-1">
                <p className="font-display font-bold text-ink">NGOs, churches &amp; schools</p>
                <p className="body-muted mt-0.5 text-sm">
                  Same flat pricing. Register as an organisation and your registration number
                  becomes a trust badge on your public page.
                </p>
              </div>
              <Link href="/contact" className="btn-ghost shrink-0 !px-5 !py-2.5 text-sm">
                Talk to us
              </Link>
            </div>
          </Reveal>
        </div>
      </section>

      {/* FAQ */}
      <section className="container-content py-16 md:py-20">
        <div className="text-center">
          <p className="eyebrow">Questions</p>
          <h2 className="heading-xl mt-3 text-3xl md:text-4xl">Fair to ask</h2>
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
      </section>

      <PageCta title="Start for free today" sub="No credit card required. 6% flat when a tip lands — nothing before, nothing after.">
        <Link
          href="/register"
          className="inline-flex rounded-full bg-white px-8 py-3.5 font-semibold !text-primary shadow-lift transition hover:-translate-y-0.5"
        >
          Create your free page →
        </Link>
        <Link
          href="/features"
          className="inline-flex rounded-full border border-white/25 px-8 py-3.5 font-semibold transition hover:border-white/60 hover:bg-white/10"
        >
          See what&apos;s included
        </Link>
      </PageCta>
    </>
  );
}
