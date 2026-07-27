"use client";

import Link from "next/link";
import { useState } from "react";

interface Feature {
  icon: string;
  title: string;
  body: string;
  accent: string; // tailwind text color class
}

const CREATOR_FEATURES: Feature[] = [
  {
    icon: "bi-link-45deg",
    title: "Shareable tip link",
    body: "Your personal URL works everywhere — bio, YouTube, Twitch, email. Zero setup beyond copy & paste.",
    accent: "text-teal",
  },
  {
    icon: "bi-bar-chart-fill",
    title: "Live dashboard",
    body: "See every tip the instant it arrives. Filter by date, amount, or tipper. Export your history as CSV.",
    accent: "text-teal",
  },
  {
    icon: "bi-bullseye",
    title: "Monthly goal",
    body: "Set a public tip goal and watch a live progress bar motivate your fans to push you over the line.",
    accent: "text-blue",
  },
  {
    icon: "bi-palette-fill",
    title: "Page customisation",
    body: "Cover image, avatar, tagline, bio — make your page unmistakably yours. Changes go live in seconds.",
    accent: "text-teal",
  },
  {
    icon: "bi-bank",
    title: "Fast payouts",
    body: "Your money arrives in your bank account quickly after each tip. No holding periods — straight to your bank.",
    accent: "text-teal",
  },
  {
    icon: "bi-bell-fill",
    title: "Instant notifications",
    body: "Get an email the moment a fan tips you. Never miss a kind word.",
    accent: "text-blue",
  },
];

const FAN_FEATURES: Feature[] = [
  {
    icon: "bi-rocket-takeoff-fill",
    title: "No account required",
    body: "Send a tip in under 30 seconds without registering. We only ask for a card — nothing else.",
    accent: "text-teal",
  },
  {
    icon: "bi-chat-heart-fill",
    title: "Personal messages",
    body: "Every tip can include a message up to 500 characters. Say what you've been meaning to tell that creator.",
    accent: "text-teal",
  },
  {
    icon: "bi-clock-history",
    title: "Tip history",
    body: "Create a free fan account to see every tip you've sent and follow your favourite creators.",
    accent: "text-blue",
  },
  {
    icon: "bi-emoji-smile-fill",
    title: "Reaction emojis",
    body: "Add a reaction alongside your tip — flames for fire content, a heart for love, confetti for milestones.",
    accent: "text-teal",
  },
  {
    icon: "bi-receipt",
    title: "Instant receipts",
    body: "An email receipt lands in your inbox within seconds of every tip.",
    accent: "text-teal",
  },
  {
    icon: "bi-globe-americas",
    title: "South Africa focused",
    body: "Built specifically for South African creators. Accept tips from fans locally and abroad.",
    accent: "text-blue",
  },
];

const PLATFORM_FEATURES: Feature[] = [
  {
    icon: "bi-shield-lock-fill",
    title: "PCI-DSS Level 1",
    body: "All card data is tokenised and encrypted before it leaves your browser. We never touch raw card numbers.",
    accent: "text-teal",
  },
  {
    icon: "bi-lightning-charge-fill",
    title: "Sub-second payments",
    body: "Our payment integration processes tips in under 800 ms on average. No spinners, no waiting.",
    accent: "text-teal",
  },
  {
    icon: "bi-phone-fill",
    title: "Responsive everywhere",
    body: "The Tipping Jar works perfectly on desktop, tablet, and mobile. Adapts to any screen size.",
    accent: "text-blue",
  },
  {
    icon: "bi-puzzle-fill",
    title: "REST API",
    body: "Our documented REST API lets you embed tips in your own apps and websites.",
    accent: "text-teal",
  },
  {
    icon: "bi-geo-alt-fill",
    title: "Proudly South African",
    body: "Built and hosted in South Africa, for South African creators. Local support, local understanding.",
    accent: "text-teal",
  },
  {
    icon: "bi-headset",
    title: "Real support",
    body: "Reach a human within 4 hours via email. We are here to help you grow.",
    accent: "text-blue",
  },
];

const TABS = ["For creators", "For fans", "Platform"];
const TAB_FEATURES = [CREATOR_FEATURES, FAN_FEATURES, PLATFORM_FEATURES];

const INTEGRATIONS: [string, string, string][] = [
  ["bi-youtube", "YouTube", "Link in description"],
  ["bi-instagram", "Instagram", "Bio link"],
  ["bi-twitter-x", "Twitter / X", "Pinned tweet"],
  ["bi-twitch", "Twitch", "Panel link"],
  ["bi-envelope-fill", "Newsletter", "Footer CTA"],
];

export default function FeaturesPage() {
  const [tab, setTab] = useState(0);
  const features = TAB_FEATURES[tab];

  return (
    <>
      {/* Hero */}
      <section className="border-b border-border bg-darker">
        <div className="container-content py-20 text-center md:py-24">
          <span className="inline-block rounded-full border border-teal/30 bg-teal/10 px-4 py-1.5 text-sm font-semibold text-teal">
            Features
          </span>
          <h1 className="heading-xl mx-auto mt-6 max-w-2xl">
            Built for creators who mean business.
          </h1>
          <p className="body-muted mx-auto mt-5 max-w-xl text-lg">
            Every feature exists for one reason: to get more money into creators&apos; hands
            with less friction.
          </p>
        </div>
      </section>

      {/* Feature tabs */}
      <section className="container-content py-16 md:py-20">
        <div className="flex justify-center">
          <div className="inline-flex rounded-full border border-border bg-card p-1.5">
            {TABS.map((t, i) => (
              <button
                key={t}
                onClick={() => setTab(i)}
                className={`rounded-full px-5 py-2 text-sm font-semibold transition ${
                  tab === i ? "bg-brand-gradient text-ink" : "text-muted hover:text-ink"
                }`}
              >
                {t}
              </button>
            ))}
          </div>
        </div>

        <div className="mt-12 grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {features.map((f) => (
            <div key={f.title} className="card transition hover:border-teal">
              <div className={`grid h-11 w-11 place-items-center rounded-xl bg-teal/10 text-xl ${f.accent}`}>
                <i className={`bi ${f.icon}`} />
              </div>
              <h3 className="mt-4 font-semibold text-ink">{f.title}</h3>
              <p className="body-muted mt-2 text-sm">{f.body}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Integrations */}
      <section className="border-y border-border bg-dark">
        <div className="container-content py-16 md:py-20 text-center">
          <span className="inline-block rounded-full border border-teal/30 bg-teal/10 px-4 py-1.5 text-sm font-semibold text-teal">
            Works with everything
          </span>
          <h2 className="mt-4 text-3xl font-extrabold tracking-tight">Paste your link. Done.</h2>
          <p className="body-muted mt-3">
            No integrations to configure. One link works everywhere.
          </p>
          <div className="mt-10 flex flex-wrap justify-center gap-3">
            {INTEGRATIONS.map(([icon, name, sub]) => (
              <div
                key={name}
                className="flex items-center gap-3 rounded-2xl border border-border bg-card px-4 py-3"
              >
                <span className="grid h-9 w-9 place-items-center rounded-lg bg-teal/10 text-base text-teal">
                  <i className={`bi ${icon}`} />
                </span>
                <div className="text-left">
                  <p className="text-sm font-semibold text-ink">{name}</p>
                  <p className="text-xs text-muted">{sub}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="container-content py-20">
        <div className="rounded-3xl bg-brand-gradient p-12 text-center md:p-16">
          <h2 className="heading-xl text-ink">Ready to start earning?</h2>
          <p className="mx-auto mt-4 max-w-md text-white/85">
            Create your free page in under a minute.
          </p>
          <Link
            href="/register"
            className="mt-8 inline-flex rounded-full bg-white px-8 py-3 font-semibold text-primary transition hover:opacity-90"
          >
            Create your free page →
          </Link>
          <p className="mt-4 text-xs text-white/60">
            No credit card · Free forever · Cancel anytime
          </p>
        </div>
      </section>
    </>
  );
}
