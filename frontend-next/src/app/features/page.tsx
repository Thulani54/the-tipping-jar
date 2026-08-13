"use client";

import Link from "next/link";
import { useState } from "react";
import { PageHero, PageCta } from "@/components/PageHero";
import { Aurora } from "@/components/Aurora";

interface Feature {
  icon: string;
  title: string;
  body: string;
  big?: boolean;
}

const CREATOR_FEATURES: Feature[] = [
  {
    icon: "bi-link-45deg",
    title: "One shareable tip link",
    body: "Your personal URL works everywhere — bio, YouTube, Twitch, WhatsApp, email. Zero setup beyond copy & paste. Every visit is a potential tip.",
    big: true,
  },
  {
    icon: "bi-bar-chart-fill",
    title: "Live dashboard & analytics",
    body: "Every tip the instant it arrives — charts, heatmaps, supporter segments, CSV exports.",
  },
  {
    icon: "bi-bullseye",
    title: "Goals & campaign jars",
    body: "A public monthly goal plus separate jars for specific things — new mic, studio day, tour fund — each with its own QR poster.",
  },
  {
    icon: "bi-lock-fill",
    title: "Exclusive content",
    body: "Posts, video, audio and galleries behind a monthly tip or a subscription tier. Your supporters get more.",
  },
  {
    icon: "bi-palette-fill",
    title: "Creator Studio",
    body: "Design share-ready promo graphics in the browser — templates, brand fonts, stickers, your tip-link QR baked in.",
  },
  {
    icon: "bi-people-fill",
    title: "Referrals that pay",
    body: "Refer another creator and earn a commission on their tips — paid straight into your balance.",
  },
];

const FAN_FEATURES: Feature[] = [
  {
    icon: "bi-rocket-takeoff-fill",
    title: "No account required",
    body: "Send a tip in under 30 seconds without registering. Pick an amount, pay by card, done — no app, no signup, no password.",
    big: true,
  },
  {
    icon: "bi-chat-heart-fill",
    title: "Personal messages",
    body: "Every tip can carry a message. Say the thing you've been meaning to tell that creator.",
  },
  {
    icon: "bi-unlock-fill",
    title: "Unlock exclusive content",
    body: "Tip monthly or subscribe to a tier and their vault opens — early drops, unreleased tracks, behind the scenes.",
  },
  {
    icon: "bi-piggy-bank-fill",
    title: "Back a specific goal",
    body: "Tip into a campaign jar — the new laptop, the music video — and watch the bar move because of you.",
  },
  {
    icon: "bi-receipt",
    title: "Instant receipts",
    body: "An email receipt lands in your inbox seconds after every tip.",
  },
  {
    icon: "bi-globe-americas",
    title: "Built for South Africa",
    body: "Rand in, rand out. Tips from home or abroad reach South African creators.",
  },
];

const PLATFORM_FEATURES: Feature[] = [
  {
    icon: "bi-shield-lock-fill",
    title: "Card-safe by design",
    body: "Payments run through PayCloud's PCI-DSS compliant gateway. Card details never touch our servers — tokenised and encrypted end to end.",
    big: true,
  },
  {
    icon: "bi-lightning-charge-fill",
    title: "Fast under pressure",
    body: "Load-tested to 1,000 simultaneous tippers with zero failures. Viral moments welcome.",
  },
  {
    icon: "bi-phone-fill",
    title: "Responsive everywhere",
    body: "Desktop, tablet, mobile — the whole experience adapts to any screen.",
  },
  {
    icon: "bi-puzzle-fill",
    title: "REST API",
    body: "A documented REST API for embedding tips into your own apps and sites.",
  },
  {
    icon: "bi-geo-alt-fill",
    title: "Proudly South African",
    body: "Built and hosted in South Africa, for South African creators. Local support, local understanding.",
  },
  {
    icon: "bi-headset",
    title: "Real support",
    body: "Reach a human within 4 hours by email. We're here to help you grow.",
  },
];

const TABS = ["For creators", "For fans", "Platform"];
const TAB_FEATURES = [CREATOR_FEATURES, FAN_FEATURES, PLATFORM_FEATURES];

const INTEGRATIONS: [string, string, string][] = [
  ["bi-youtube", "YouTube", "Link in description"],
  ["bi-instagram", "Instagram", "Bio link"],
  ["bi-twitter-x", "Twitter / X", "Pinned tweet"],
  ["bi-twitch", "Twitch", "Panel link"],
  ["bi-whatsapp", "WhatsApp", "Status & groups"],
  ["bi-envelope-fill", "Newsletter", "Footer CTA"],
];

export default function FeaturesPage() {
  const [tab, setTab] = useState(0);
  const features = TAB_FEATURES[tab];

  return (
    <>
      <PageHero
        eyebrow="Features"
        title="Built for creators who mean business."
        sub="Every feature exists for one reason: to get more money into creators' hands with less friction."
      />

      {/* Feature tabs */}
      <section className="relative overflow-hidden bg-white">
        <Aurora />
        <div className="container-content relative py-16 md:py-20">
          <div className="flex justify-center">
            <div className="inline-flex rounded-full border border-border bg-white p-1.5 shadow-soft">
              {TABS.map((t, i) => (
                <button
                  key={t}
                  onClick={() => setTab(i)}
                  className={`rounded-full px-5 py-2 text-sm font-semibold transition ${
                    tab === i ? "bg-primary text-white shadow-soft" : "text-muted hover:text-ink"
                  }`}
                >
                  {t}
                </button>
              ))}
            </div>
          </div>

          <div key={tab} className="mt-12 grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {features.map((f, i) => (
              <div key={f.title} className={f.big ? "md:col-span-2 lg:col-span-2" : ""}>
                <div className="glass-card group h-full p-6" style={{ animationDelay: `${i * 60}ms` }}>
                  <span className="glass-tile h-12 w-12 text-xl">
                    <i className={`bi ${f.icon}`} />
                  </span>
                  <h3 className="mt-5 font-display text-lg font-bold text-ink">{f.title}</h3>
                  <p className="body-muted mt-2 max-w-lg text-sm leading-relaxed">{f.body}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Integrations */}
      <section className="relative overflow-hidden border-y border-border bg-[#f3f9f5]">
        <Aurora />
        <div className="container-content relative py-16 text-center md:py-20">
          <p className="eyebrow">Works with everything</p>
          <h2 className="heading-xl mt-3 text-3xl md:text-4xl">Paste your link. Done.</h2>
          <p className="body-muted mx-auto mt-3 max-w-md">
            No integrations to configure. One link works everywhere your audience already is.
          </p>
          <div className="mt-10 flex flex-wrap justify-center gap-3">
            {INTEGRATIONS.map(([icon, name, sub]) => (
              <div
                key={name}
                className="flex items-center gap-3 rounded-2xl border border-border bg-white px-4 py-3 shadow-soft transition hover:-translate-y-0.5 hover:shadow-lift"
              >
                <span className="grid h-9 w-9 place-items-center rounded-lg bg-mint/15 text-base text-green">
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

      <PageCta title="Ready to start earning?" sub="Create your page in under a minute — free to start, 6% flat when a tip lands.">
        <Link
          href="/register"
          className="inline-flex rounded-full bg-white px-8 py-3.5 font-semibold !text-primary shadow-lift transition hover:-translate-y-0.5"
        >
          Create your jar →
        </Link>
        <Link
          href="/how-it-works"
          className="inline-flex rounded-full border border-white/25 px-8 py-3.5 font-semibold transition hover:border-white/60 hover:bg-white/10"
        >
          How it works
        </Link>
      </PageCta>
    </>
  );
}
