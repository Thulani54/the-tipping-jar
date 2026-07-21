"use client";

import { use, useEffect, useState } from "react";
import Link from "next/link";
import { api } from "@/lib/api";
import type { Creator, FeeQuote, Tip } from "@/types";

const PRESETS = [5, 10, 20, 50, 100, 200];

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

export default function TipPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = use(params);

  const [creator, setCreator] = useState<Creator | null>(null);
  const [loadingCreator, setLoadingCreator] = useState(true);
  const [notFound, setNotFound] = useState(false);

  const [amount, setAmount] = useState<number>(20);
  const [custom, setCustom] = useState<string>("");

  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [message, setMessage] = useState("");

  const [quote, setQuote] = useState<FeeQuote | null>(null);
  const [quoting, setQuoting] = useState(false);

  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<Tip | null>(null);

  // Load creator on mount
  useEffect(() => {
    let alive = true;
    setLoadingCreator(true);
    api
      .getCreator(slug)
      .then((c) => {
        if (alive) setCreator(c);
      })
      .catch(() => {
        if (alive) setNotFound(true);
      })
      .finally(() => {
        if (alive) setLoadingCreator(false);
      });
    return () => {
      alive = false;
    };
  }, [slug]);

  // Live fee quote whenever the amount changes (debounced)
  useEffect(() => {
    if (amount < 1) {
      setQuote(null);
      return;
    }
    let alive = true;
    setQuoting(true);
    const t = setTimeout(() => {
      api
        .quote(amount)
        .then((q) => {
          if (alive) setQuote(q);
        })
        .catch(() => {
          if (alive) setQuote(null);
        })
        .finally(() => {
          if (alive) setQuoting(false);
        });
    }, 300);
    return () => {
      alive = false;
      clearTimeout(t);
    };
  }, [amount]);

  function selectPreset(v: number) {
    setAmount(v);
    setCustom("");
  }

  function onCustom(v: string) {
    // allow digits + up to 2 decimals
    const cleaned = v.replace(/[^0-9.]/g, "");
    setCustom(cleaned);
    const parsed = parseFloat(cleaned);
    setAmount(Number.isNaN(parsed) ? 0 : parsed);
  }

  async function submit() {
    if (amount < 1) {
      setError("Enter an amount (R1 minimum).");
      return;
    }
    if (name.trim() && /[0-9]/.test(name)) {
      setError("Name cannot contain numbers.");
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      const tip = await api.createTip({
        creator_slug: slug,
        amount,
        tipper_name: name.trim() || "Anonymous",
        tipper_email: email.trim() || undefined,
        message: message.trim() || undefined,
      });
      setSuccess(tip);
    } catch {
      setError("Something went wrong. Please try again.");
    } finally {
      setSubmitting(false);
    }
  }

  // Real PayCloud hosted checkout — redirects the payer to PayCloud's page.
  async function payWithCard() {
    if (amount < 1 || !creator) {
      setError("Enter an amount (R1 minimum).");
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      const res = await api.checkout({
        creator_id: creator.id,
        amount,
        description: `Tip for ${creator.display_name}`,
        return_url: `${window.location.origin}/payment/callback`,
      });
      window.location.href = res.pay_url;
    } catch (e) {
      setError(
        e instanceof Error
          ? `Card payment unavailable: ${e.message}`
          : "Card payment is not available right now.",
      );
      setSubmitting(false);
    }
  }

  function reset() {
    setSuccess(null);
    setAmount(20);
    setCustom("");
    setName("");
    setEmail("");
    setMessage("");
    setError(null);
  }

  // ── States ──────────────────────────────────────────────────────────
  if (loadingCreator) {
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
          🫙
        </div>
        <h1 className="heading-xl mt-6">Creator not found</h1>
        <p className="body-muted mx-auto mt-4 max-w-md">
          We couldn&apos;t find who you&apos;re trying to tip.
        </p>
        <Link href="/creators" className="btn-primary mt-8">
          Explore creators
        </Link>
      </section>
    );
  }

  if (success) {
    return (
      <section className="container-content grid min-h-[60vh] place-items-center py-24">
        <div className="card w-full max-w-md text-center">
          <div className="mx-auto grid h-20 w-20 place-items-center rounded-full bg-teal/12 text-4xl">
            💚
          </div>
          <h1 className="mt-6 text-3xl font-extrabold tracking-tight">
            Tip sent! 🎉
          </h1>
          <p className="body-muted mx-auto mt-3 max-w-sm">
            You sent R{amount.toFixed(2)} to {creator.display_name}.{" "}
            {name.trim() || "You"} just made someone&apos;s day.
          </p>
          {success.reference && (
            <div className="mt-6 rounded-2xl border border-border bg-darker px-4 py-3">
              <p className="text-xs uppercase tracking-wide text-muted">
                Reference
              </p>
              <p className="mt-1 font-mono text-sm text-white">
                {success.reference}
              </p>
            </div>
          )}
          <button onClick={reset} className="btn-primary mt-8 w-full">
            Send another tip
          </button>
          <Link
            href={`/creator/${creator.slug}`}
            className="mt-3 inline-block text-sm text-muted hover:text-white"
          >
            Back to {creator.display_name}&apos;s page
          </Link>
        </div>
      </section>
    );
  }

  const fee = (v: string | undefined) => {
    const n = parseFloat(v ?? "0");
    return Number.isNaN(n) ? "0.00" : n.toFixed(2);
  };

  // ── Form ────────────────────────────────────────────────────────────
  return (
    <section className="container-content max-w-xl py-16">
      <div className="card">
        {/* Header row */}
        <div className="flex items-center gap-3 border-b border-border pb-5">
          <div className="grid h-12 w-12 place-items-center rounded-full bg-primary text-lg font-bold text-white">
            {initials(creator.display_name)}
          </div>
          <div className="min-w-0 flex-1">
            <p className="text-xs text-muted">Supporting</p>
            <p className="truncate text-lg font-bold text-white">
              {creator.display_name}
            </p>
          </div>
          <span className="rounded-full bg-brand-gradient px-4 py-2 text-lg font-extrabold text-white">
            R{Math.round(amount) || 0}
          </span>
        </div>

        {/* Amount presets */}
        <div className="mt-6">
          <p className="text-sm font-semibold text-white">Choose amount</p>
          <div className="mt-3 grid grid-cols-3 gap-3">
            {PRESETS.map((v) => {
              const active = custom === "" && amount === v;
              return (
                <button
                  key={v}
                  type="button"
                  onClick={() => selectPreset(v)}
                  className={`rounded-full border px-4 py-3 text-sm font-bold transition ${
                    active
                      ? "border-teal bg-teal/10 text-teal"
                      : "border-border bg-darker text-white hover:border-teal/50"
                  }`}
                >
                  R{v}
                </button>
              );
            })}
          </div>

          {/* Custom */}
          <div className="mt-4">
            <div className="flex items-center rounded-2xl border border-border bg-darker px-4 focus-within:border-teal">
              <span className="text-muted">R</span>
              <input
                inputMode="decimal"
                value={custom}
                onChange={(e) => onCustom(e.target.value)}
                placeholder="Or enter a custom amount"
                className="w-full bg-transparent py-3 pl-2 text-white placeholder:text-muted focus:outline-none"
              />
            </div>
          </div>
        </div>

        {/* Fee breakdown */}
        {amount >= 1 && (
          <div className="mt-6 rounded-2xl border border-teal/20 bg-teal/[0.06] p-4">
            <div className="flex items-center justify-between text-sm font-semibold text-teal">
              <span>Sending to {creator.display_name}</span>
              <span>R{amount.toFixed(2)}</span>
            </div>
            <div className="mt-3 space-y-1.5 text-xs">
              <div className="flex justify-between text-muted">
                <span>
                  Platform fee
                  {quote ? ` (${fee(quote.platform_pct)}%)` : ""}
                </span>
                <span>- R{quote ? fee(quote.platform_fee) : "…"}</span>
              </div>
              <div className="flex justify-between text-muted">
                <span>
                  Service fee
                  {quote ? ` (${fee(quote.service_pct)}%)` : ""}
                </span>
                <span>- R{quote ? fee(quote.service_fee) : "…"}</span>
              </div>
              <div className="mt-2 flex justify-between border-t border-border pt-2 font-bold text-white">
                <span>Creator receives</span>
                <span>
                  {quoting && !quote
                    ? "…"
                    : `R${quote ? fee(quote.creator_net) : amount.toFixed(2)}`}
                </span>
              </div>
            </div>
          </div>
        )}

        {/* Name */}
        <div className="mt-6">
          <label className="text-sm font-semibold text-white">
            Your name (optional)
          </label>
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Anonymous"
            className="mt-2 w-full rounded-2xl border border-border bg-darker px-4 py-3 text-white placeholder:text-muted focus:border-teal focus:outline-none"
          />
        </div>

        {/* Email */}
        <div className="mt-4">
          <label className="text-sm font-semibold text-white">
            Email (for receipt)
          </label>
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="you@example.com (optional)"
            className="mt-2 w-full rounded-2xl border border-border bg-darker px-4 py-3 text-white placeholder:text-muted focus:border-teal focus:outline-none"
          />
        </div>

        {/* Message */}
        <div className="mt-4">
          <label className="text-sm font-semibold text-white">
            Message (optional)
          </label>
          <textarea
            value={message}
            onChange={(e) => setMessage(e.target.value.slice(0, 280))}
            rows={3}
            placeholder="Say something nice… 👋"
            className="mt-2 w-full resize-none rounded-2xl border border-border bg-darker px-4 py-3 text-white placeholder:text-muted focus:border-teal focus:outline-none"
          />
          <p className="mt-1 text-right text-xs text-muted">
            {message.length}/280
          </p>
        </div>

        {error && (
          <div className="mt-4 flex items-center gap-2 rounded-xl border border-red-500/20 bg-red-500/10 px-4 py-3 text-sm text-red-400">
            <span>⚠️</span>
            <span>{error}</span>
          </div>
        )}

        {/* Submit */}
        <button
          type="button"
          onClick={submit}
          disabled={submitting || amount < 1}
          className="btn-primary mt-6 w-full text-base disabled:cursor-not-allowed disabled:opacity-50"
        >
          {submitting
            ? "Sending…"
            : amount < 1
              ? "Enter an amount (R1 minimum)"
              : `Send R${amount.toFixed(2)} tip →`}
        </button>

        {/* Real card payment via PayCloud hosted checkout */}
        <button
          type="button"
          onClick={payWithCard}
          disabled={submitting || amount < 1}
          className="btn-ghost mt-3 w-full text-base disabled:cursor-not-allowed disabled:opacity-50"
        >
          💳 Pay R{amount.toFixed(2)} with card
        </button>

        <p className="mt-4 flex items-center justify-center gap-1.5 text-xs text-muted">
          🔒 Secure card payments via PayCloud
        </p>
      </div>
    </section>
  );
}
