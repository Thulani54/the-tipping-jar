"use client";

import { use, useEffect, useState } from "react";
import Link from "next/link";
import { api } from "@/lib/api";
import type { Creator, FeeQuote, Tip } from "@/types";

const PRESETS = [10, 20, 50, 100, 200, 500];

const initials = (name: string) =>
  name.split(" ").map((w) => w.charAt(0)).join("").slice(0, 2).toUpperCase() || "T";

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
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<Tip | null>(null);

  useEffect(() => {
    let alive = true;
    setLoadingCreator(true);
    api
      .getCreator(slug)
      .then((c) => alive && setCreator(c))
      .catch(() => alive && setNotFound(true))
      .finally(() => alive && setLoadingCreator(false));
    return () => {
      alive = false;
    };
  }, [slug]);

  useEffect(() => {
    if (amount < 1) {
      setQuote(null);
      return;
    }
    let alive = true;
    const t = setTimeout(() => {
      api
        .quote(amount)
        .then((q) => alive && setQuote(q))
        .catch(() => alive && setQuote(null));
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
    const cleaned = v.replace(/[^0-9.]/g, "");
    setCustom(cleaned);
    const parsed = parseFloat(cleaned);
    setAmount(Number.isNaN(parsed) ? 0 : parsed);
  }

  async function submit() {
    if (amount < 1) return setError("Enter an amount (R1 minimum).");
    if (name.trim() && /[0-9]/.test(name)) return setError("Name can't contain numbers.");
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

  async function payWithCard() {
    if (amount < 1 || !creator) return setError("Enter an amount (R1 minimum).");
    setSubmitting(true);
    setError(null);
    try {
      const res = await api.checkout({
        creator_id: creator.id,
        amount,
        description: `Tip for ${creator.display_name}`,
        return_url: `${window.location.origin}/payment/callback?creator_slug=${creator.slug}`,
        tipper_name: name.trim() || undefined,
        tipper_email: email.trim() || undefined,
        message: message.trim() || undefined,
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

  const fee = (v: string | undefined) => {
    const n = parseFloat(v ?? "0");
    return Number.isNaN(n) ? "0.00" : n.toFixed(2);
  };

  // ── Loading / not-found ─────────────────────────────────────────────
  if (loadingCreator) {
    return (
      <section className="container-content grid min-h-[60vh] place-items-center py-24">
        <div className="h-10 w-10 animate-spin rounded-full border-2 border-border border-t-green" />
      </section>
    );
  }
  if (notFound || !creator) {
    return (
      <section className="container-content py-32 text-center">
        <div className="mx-auto grid h-16 w-16 place-items-center rounded-full bg-white text-3xl shadow-soft">🫙</div>
        <h1 className="heading-xl mt-6 text-4xl">Creator not found</h1>
        <p className="body-muted mx-auto mt-4 max-w-md">We couldn&apos;t find who you&apos;re trying to tip.</p>
        <Link href="/creators" className="btn-primary mt-8">Explore creators</Link>
      </section>
    );
  }

  // ── Success ─────────────────────────────────────────────────────────
  if (success) {
    return (
      <section className="container-content grid min-h-[70vh] place-items-center py-16">
        <div className="slip w-full max-w-md !p-8 text-center shadow-lift">
          <div className="mx-auto grid h-16 w-16 place-items-center rounded-full bg-mint/15 text-3xl">💚</div>
          <p className="mt-4 font-mono text-[11px] uppercase tracking-[0.2em] text-green">✓ Tip received</p>
          <h1 className="mt-2 font-display text-3xl font-extrabold text-ink">Thank you!</h1>
          <p className="body-muted mx-auto mt-2 max-w-xs">
            You sent R{amount.toFixed(2)} to {creator.display_name}. You just made someone&apos;s day.
          </p>
          {success.reference && (
            <p className="mt-5 border-t border-dashed border-border pt-4 font-mono text-xs text-muted">
              ref {success.reference}
            </p>
          )}
          <button onClick={reset} className="btn-primary mt-6 w-full">Send another tip</button>
          <Link href={`/creator/${creator.slug}`} className="mt-3 inline-block text-sm text-muted hover:text-ink">
            Back to {creator.display_name}
          </Link>
        </div>
      </section>
    );
  }

  const inputCls =
    "w-full rounded-2xl border border-border bg-white px-4 py-3.5 text-ink placeholder:text-muted focus:border-primary/40 focus:outline-none";

  // ── Form ────────────────────────────────────────────────────────────
  return (
    <section className="container-content py-12 md:py-16">
      {/* Who you're supporting */}
      <div className="flex items-center gap-4">
        <div className="grid h-14 w-14 shrink-0 place-items-center rounded-2xl bg-primary text-lg font-extrabold text-white shadow-soft">
          {initials(creator.display_name)}
        </div>
        <div>
          <p className="eyebrow">You&apos;re supporting</p>
          <p className="font-display text-xl font-bold text-ink">{creator.display_name}</p>
        </div>
      </div>

      <div className="mt-8 grid gap-8 lg:grid-cols-[1fr_390px]">
        {/* Left — amount + note */}
        <div>
          <div className="card">
            <p className="eyebrow">Choose an amount</p>
            <div className="mt-4 grid grid-cols-3 gap-3">
              {PRESETS.map((v) => {
                const active = custom === "" && amount === v;
                return (
                  <button
                    key={v}
                    type="button"
                    onClick={() => selectPreset(v)}
                    className={`rounded-2xl border py-4 font-display text-lg font-bold transition ${
                      active
                        ? "border-primary bg-primary text-white"
                        : "border-border bg-white text-ink hover:border-primary/40"
                    }`}
                  >
                    R{v}
                  </button>
                );
              })}
            </div>
            <div className="mt-4 flex items-center rounded-2xl border border-border bg-white px-4 focus-within:border-primary/40">
              <span className="font-display text-lg text-muted">R</span>
              <input
                inputMode="decimal"
                value={custom}
                onChange={(e) => onCustom(e.target.value)}
                placeholder="Custom amount"
                className="w-full bg-transparent py-3.5 pl-2 font-display text-lg text-ink placeholder:font-sans placeholder:text-base placeholder:font-normal placeholder:text-muted focus:outline-none"
              />
            </div>
          </div>

          <div className="card mt-6">
            <p className="eyebrow">Add a note</p>
            <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Your name (optional)" className={`${inputCls} mt-4`} />
            <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="Email for a receipt (optional)" className={`${inputCls} mt-3`} />
            <textarea
              value={message}
              onChange={(e) => setMessage(e.target.value.slice(0, 280))}
              rows={3}
              placeholder="Say something nice… 👋"
              className={`${inputCls} mt-3 resize-none`}
            />
            <p className="mt-1 text-right font-mono text-[11px] text-muted">{message.length}/280</p>
          </div>
        </div>

        {/* Right — the live receipt */}
        <aside className="lg:sticky lg:top-24 lg:self-start">
          <div className="slip !p-6 shadow-lift">
            <div className="flex items-center justify-between font-mono text-[11px] uppercase tracking-[0.18em] text-muted">
              <span>Tip slip</span>
              <span className="text-green">● live</span>
            </div>

            <div className="mt-5 flex items-end justify-between">
              <div>
                <p className="font-mono text-xs text-muted">You&apos;re sending</p>
                <p className="font-display text-[2.75rem] font-extrabold leading-none tracking-tight text-ink">
                  R{amount.toFixed(2)}
                </p>
              </div>
              <span className="grid h-12 w-12 place-items-center rounded-2xl bg-mint/15 text-2xl">🫙</span>
            </div>
            <p className="mt-1.5 text-sm text-muted">to {creator.display_name}</p>

            {amount >= 1 && (
              <>
                <div className="mt-5 space-y-2 border-t border-dashed border-border pt-4 font-mono text-[13px]">
                  <div className="flex justify-between text-muted">
                    <span>platform fee{quote ? ` (${fee(quote.platform_pct)}%)` : ""}</span>
                    <span>− R{quote ? fee(quote.platform_fee) : "…"}</span>
                  </div>
                  <div className="flex justify-between text-muted">
                    <span>service fee{quote ? ` (${fee(quote.service_pct)}%)` : ""}</span>
                    <span>− R{quote ? fee(quote.service_fee) : "…"}</span>
                  </div>
                </div>
                <div className="mt-3 flex items-center justify-between border-t border-dashed border-border pt-3">
                  <span className="text-sm font-semibold text-ink">Creator receives</span>
                  <span className="font-display text-2xl font-bold text-green">
                    R{quote ? fee(quote.creator_net) : amount.toFixed(2)}
                  </span>
                </div>
              </>
            )}

            {error && (
              <p className="mt-4 rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-500">
                {error}
              </p>
            )}

            <button
              type="button"
              onClick={payWithCard}
              disabled={submitting || amount < 1}
              className="btn-primary mt-6 w-full text-base disabled:cursor-not-allowed disabled:opacity-50"
            >
              {submitting ? "Processing…" : amount < 1 ? "Enter an amount" : `💳 Pay R${amount.toFixed(2)}`}
            </button>
            <button
              type="button"
              onClick={submit}
              disabled={submitting || amount < 1}
              className="btn-ghost mt-3 w-full text-sm disabled:cursor-not-allowed disabled:opacity-50"
            >
              Send instantly
            </button>
            <p className="mt-4 text-center font-mono text-[10px] uppercase tracking-[0.16em] text-muted">
              🔒 Secured by PayCloud
            </p>
          </div>
        </aside>
      </div>
    </section>
  );
}
