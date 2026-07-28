"use client";

import { use, useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import Link from "next/link";
import { api } from "@/lib/api";
import type { Creator, FeeQuote, Jar } from "@/types";

const DEFAULT_PRESETS = [10, 20, 50, 100, 200, 500];

function presetsFor(creator: Creator | null): number[] {
  if (creator?.tip_presets) {
    try {
      const p = JSON.parse(creator.tip_presets);
      if (Array.isArray(p)) {
        const nums = p.map(Number).filter((n) => n >= 10 && n <= 100000).slice(0, 6);
        if (nums.length >= 2) return nums;
      }
    } catch { /* fall back */ }
  }
  return DEFAULT_PRESETS;
}

const initials = (name: string) =>
  name.split(" ").map((w) => w.charAt(0)).join("").slice(0, 2).toUpperCase() || "T";

export default function TipPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = use(params);
  const jarSlug = useSearchParams().get("jar");

  const [creator, setCreator] = useState<Creator | null>(null);
  const [loadingCreator, setLoadingCreator] = useState(true);
  const [notFound, setNotFound] = useState(false);

  const [amount, setAmount] = useState<number>(20);
  const [custom, setCustom] = useState<string>("");
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [message, setMessage] = useState("");

  const [quote, setQuote] = useState<FeeQuote | null>(null);
  const [exclusiveN, setExclusiveN] = useState(0);
  const [jar, setJar] = useState<Jar | null>(null);
  const [jarRaised, setJarRaised] = useState(0);

  useEffect(() => {
    if (!jarSlug) return;
    let alive = true;
    api.getJar(slug, jarSlug).then(async (j) => {
      if (!alive) return;
      setJar(j);
      try {
        const st = await api.jarStats(j.id);
        if (alive) setJarRaised(Number(st.raised) || 0);
      } catch { /* progress stays 0 */ }
    }).catch(() => null);
    return () => { alive = false; };
  }, [slug, jarSlug]);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let alive = true;
    setLoadingCreator(true);
    api.exclusiveCount(slug).then((r) => alive && setExclusiveN(r.count)).catch(() => null);
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
    if (amount < 10) {
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

  async function payWithCard() {
    if (amount < 10 || !creator) return setError("Minimum tip is R10 (card processing costs).");
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
        jar_id: jar?.id,
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
        <div className="mx-auto grid h-16 w-16 place-items-center rounded-full bg-white text-3xl text-green shadow-soft"><i className="bi bi-piggy-bank-fill" /></div>
        <h1 className="heading-xl mt-6 text-4xl">Creator not found</h1>
        <p className="body-muted mx-auto mt-4 max-w-md">We couldn&apos;t find who you&apos;re trying to tip.</p>
        <Link href="/creators" className="btn-primary mt-8">Explore creators</Link>
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

      {jar && (
        <div className="mt-5 rounded-2xl border border-mint/50 bg-mint/10 px-5 py-4">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <p className="text-sm text-ink">
              <span className="font-mono text-[11px] uppercase tracking-[0.16em] text-green">Tipping into</span>
              <span className="ml-2 font-display text-base font-bold">🫙 {jar.name}</span>
            </p>
            {jar.goal && (
              <p className="font-mono text-xs text-muted">
                R{Math.round(jarRaised).toLocaleString("en-ZA")} / R{Math.round(Number(jar.goal)).toLocaleString("en-ZA")}
              </p>
            )}
          </div>
          {jar.goal && Number(jar.goal) > 0 && (
            <div className="mt-2 h-2 overflow-hidden rounded-full bg-border">
              <div className="h-full rounded-full bg-green" style={{ width: `${Math.min(100, (jarRaised / Number(jar.goal)) * 100)}%` }} />
            </div>
          )}
          {jar.description && <p className="body-muted mt-2 text-sm">{jar.description}</p>}
        </div>
      )}

      {exclusiveN > 0 && (
        <div className="mt-5 flex items-center gap-3 rounded-2xl border border-gold/40 bg-gold/10 px-5 py-3.5">
          <span className="text-2xl">🔓</span>
          <p className="text-sm text-ink">
            <span className="font-semibold">Supporter perk:</span> tipping R10+ this month unlocks{" "}
            <span className="font-semibold">{exclusiveN} exclusive post{exclusiveN === 1 ? "" : "s"}</span> from{" "}
            {creator.display_name}. Leave your email below so we can recognise you.
          </p>
        </div>
      )}

      <div className="mt-8 grid gap-8 lg:grid-cols-[1fr_390px]">
        {/* Left — amount + note */}
        <div>
          <div className="card">
            <p className="eyebrow">Choose an amount</p>
            <div className="mt-4 grid grid-cols-3 gap-3">
              {presetsFor(creator).map((v) => {
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
                placeholder="Custom amount (min R10)"
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
              placeholder="Say something nice…"
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
              <span className="inline-flex items-center gap-1 text-green"><i className="bi bi-broadcast" /> live</span>
            </div>

            <div className="mt-5 flex items-end justify-between">
              <div>
                <p className="font-mono text-xs text-muted">You&apos;re sending</p>
                <p className="font-display text-[2.75rem] font-extrabold leading-none tracking-tight text-ink">
                  R{amount.toFixed(2)}
                </p>
              </div>
              <span className="grid h-12 w-12 place-items-center rounded-2xl bg-mint/15 text-2xl text-green"><i className="bi bi-piggy-bank-fill" /></span>
            </div>
            <p className="mt-1.5 text-sm text-muted">to {creator.display_name}</p>

            {amount >= 10 && (
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
              disabled={submitting || amount < 10}
              className="btn-primary mt-6 w-full text-base disabled:cursor-not-allowed disabled:opacity-50"
            >
              {submitting ? "Processing…" : amount < 10 ? "Minimum R10" : <><i className="bi bi-credit-card-fill" /> Pay R{amount.toFixed(2)}</>}
            </button>
            <p className="mt-4 inline-flex w-full items-center justify-center gap-1 text-center font-mono text-[10px] uppercase tracking-[0.16em] text-muted">
              <i className="bi bi-lock-fill" /> Secured by PayCloud
            </p>
          </div>
        </aside>
      </div>
    </section>
  );
}
