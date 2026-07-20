"use client";

import { use, useEffect, useState } from "react";
import Link from "next/link";
import { api } from "@/lib/api";
import type { Creator } from "@/types";

// TODO(api): tiers/subscribe endpoint not yet in /api/v2 — tiers below are
// placeholder data. Wire to a real getPublicTiers / createPledge once shipped.
interface Tier {
  id: string;
  name: string;
  price: number;
  description: string;
  perks: string[];
  featured?: boolean;
}

const PLACEHOLDER_TIERS: Tier[] = [
  {
    id: "supporter",
    name: "Supporter",
    price: 30,
    description: "A little love that keeps the lights on.",
    perks: ["Supporter badge on your profile", "Monthly thank-you note"],
  },
  {
    id: "insider",
    name: "Insider",
    price: 75,
    description: "Get closer to the work as it happens.",
    perks: [
      "Everything in Supporter",
      "Behind-the-scenes posts",
      "Early access to new drops",
    ],
    featured: true,
  },
  {
    id: "patron",
    name: "Patron",
    price: 150,
    description: "For the true believers.",
    perks: [
      "Everything in Insider",
      "Monthly group hangout",
      "Name in the credits",
      "Priority DMs",
    ],
  },
];

function initials(name: string): string {
  return (
    name
      .split(" ")
      .map((w) => w.charAt(0))
      .join("")
      .slice(0, 2)
      .toUpperCase() || "T"
  );
}

export default function SubscribePage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = use(params);

  const [creator, setCreator] = useState<Creator | null>(null);
  const [loading, setLoading] = useState(true);
  const [notFound, setNotFound] = useState(false);
  const [active, setActive] = useState<Tier | null>(null);

  useEffect(() => {
    let alive = true;
    api
      .getCreator(slug)
      .then((c) => alive && setCreator(c))
      .catch(() => alive && setNotFound(true))
      .finally(() => alive && setLoading(false));
    return () => {
      alive = false;
    };
  }, [slug]);

  if (loading) {
    return (
      <section className="container-content grid min-h-[60vh] place-items-center py-24">
        <div className="h-10 w-10 animate-spin rounded-full border-2 border-border border-t-teal" />
      </section>
    );
  }

  if (notFound || !creator) {
    return (
      <section className="container-content py-32 text-center">
        <div className="mx-auto grid h-16 w-16 place-items-center rounded-full bg-card text-3xl">
          ⭐
        </div>
        <h1 className="heading-xl mt-6">Creator not found</h1>
        <p className="body-muted mx-auto mt-4 max-w-md">
          This subscribe page may have moved or the link is invalid.
        </p>
        <Link href="/" className="btn-primary mt-8">
          Go home
        </Link>
      </section>
    );
  }

  return (
    <section className="container-content py-16">
      {/* Breadcrumb */}
      <nav className="flex flex-wrap items-center gap-2 text-sm text-muted">
        <Link href="/" className="hover:text-white">
          TippingJar
        </Link>
        <span>›</span>
        <Link href={`/creator/${creator.slug}`} className="hover:text-white">
          {creator.slug}
        </Link>
        <span>›</span>
        <span className="text-white">Subscribe</span>
      </nav>

      {/* Header */}
      <div className="mt-10 flex flex-col items-center text-center">
        <div className="grid h-20 w-20 place-items-center rounded-full bg-primary text-3xl font-extrabold text-white">
          {initials(creator.display_name)}
        </div>
        <h1 className="mt-4 text-3xl font-extrabold tracking-tight">
          {creator.display_name}
        </h1>
        <p className="mt-1 text-muted">@{creator.slug}</p>
        <div className="mt-6 max-w-md rounded-2xl border border-border bg-card px-8 py-5">
          <p className="text-lg font-bold text-white">
            Choose a monthly support level
          </p>
          <p className="body-muted mt-1">
            Your pledge supports {creator.display_name} every month and unlocks
            exclusive perks.
          </p>
        </div>
      </div>

      {/* Tiers */}
      <div className="mx-auto mt-12 grid max-w-4xl gap-6 md:grid-cols-3">
        {PLACEHOLDER_TIERS.map((tier) => (
          <div
            key={tier.id}
            className={`card flex flex-col ${
              tier.featured ? "border-teal shadow-[0_0_0_1px_rgba(0,151,178,0.4)]" : ""
            }`}
          >
            <div className="flex items-center gap-2">
              <span className="rounded-full bg-teal/10 px-3 py-1 text-xs font-semibold text-teal">
                Monthly
              </span>
              {tier.featured && (
                <span className="rounded-full bg-brand-gradient px-3 py-1 text-xs font-semibold text-white">
                  Popular
                </span>
              )}
            </div>
            <h3 className="mt-4 text-xl font-extrabold text-white">
              {tier.name}
            </h3>
            <div className="mt-2 flex items-end gap-1">
              <span className="text-3xl font-extrabold text-teal">
                R{tier.price}
              </span>
              <span className="pb-1 text-sm text-muted">/month</span>
            </div>
            <p className="body-muted mt-3">{tier.description}</p>
            <ul className="mt-5 space-y-2 border-t border-border pt-5">
              {tier.perks.map((perk) => (
                <li key={perk} className="flex items-start gap-2 text-sm text-white/80">
                  <span className="text-teal">✓</span>
                  <span>{perk}</span>
                </li>
              ))}
            </ul>
            <button
              type="button"
              onClick={() => setActive(tier)}
              className="btn-primary mt-6 w-full"
            >
              Subscribe · R{tier.price}/mo
            </button>
          </div>
        ))}
      </div>

      {/* Back link */}
      <div className="mt-12 text-center">
        <Link
          href={`/creator/${creator.slug}`}
          className="text-sm text-muted underline hover:text-white"
        >
          ← Back to {creator.display_name}&apos;s page
        </Link>
      </div>

      {/* Pledge modal (placeholder) */}
      {active && (
        <PledgeModal
          tier={active}
          creatorName={creator.display_name}
          onClose={() => setActive(null)}
        />
      )}
    </section>
  );
}

function PledgeModal({
  tier,
  creatorName,
  onClose,
}: {
  tier: Tier;
  creatorName: string;
  onClose: () => void;
}) {
  const [email, setEmail] = useState("");
  const [name, setName] = useState("");
  const [done, setDone] = useState(false);
  const [error, setError] = useState<string | null>(null);

  function submit() {
    if (!email.trim()) {
      setError("Email is required to set up your pledge.");
      return;
    }
    // TODO(api): tiers/subscribe endpoint not yet in /api/v2 — this only
    // simulates a successful pledge. Replace with api.createPledge(...).
    setError(null);
    setDone(true);
  }

  return (
    <div
      className="fixed inset-0 z-50 grid place-items-center bg-black/70 p-4"
      onClick={onClose}
    >
      <div
        className="card w-full max-w-md"
        onClick={(e) => e.stopPropagation()}
      >
        {done ? (
          <div className="text-center">
            <div className="mx-auto grid h-16 w-16 place-items-center rounded-full bg-teal/12 text-3xl">
              ✓
            </div>
            <h3 className="mt-4 text-xl font-extrabold text-white">
              You&apos;re in!
            </h3>
            <p className="body-muted mx-auto mt-2 max-w-xs">
              You&apos;re now supporting {creatorName} with R{tier.price}/month.
              Thank you!
            </p>
            <button onClick={onClose} className="btn-primary mt-6 w-full">
              Done
            </button>
          </div>
        ) : (
          <>
            <h3 className="text-xl font-extrabold text-white">
              Subscribe to {tier.name}
            </h3>
            <div className="mt-4 flex items-center gap-3 rounded-2xl border border-border bg-darker p-3">
              <span className="text-2xl">⭐</span>
              <div>
                <p className="font-semibold text-white">{tier.name}</p>
                <p className="text-sm text-teal">R{tier.price}/month</p>
              </div>
            </div>
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Your name (optional)"
              className="mt-4 w-full rounded-2xl border border-border bg-darker px-4 py-3 text-white placeholder:text-muted focus:border-teal focus:outline-none"
            />
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="your@email.com *"
              className="mt-3 w-full rounded-2xl border border-border bg-darker px-4 py-3 text-white placeholder:text-muted focus:border-teal focus:outline-none"
            />
            {error && (
              <p className="mt-3 text-sm text-red-400">{error}</p>
            )}
            <p className="mt-2 text-xs text-muted">
              Your card will be charged monthly until you cancel.
            </p>
            <div className="mt-6 flex gap-3">
              <button onClick={onClose} className="btn-ghost flex-1">
                Cancel
              </button>
              <button onClick={submit} className="btn-primary flex-1">
                Subscribe
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
