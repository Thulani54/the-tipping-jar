"use client";

import { use, useEffect, useState } from "react";
import Link from "next/link";
import { api } from "@/lib/api";
import type { FeeQuote, Tip } from "@/types";

// TODO(api): jars endpoint not yet in /api/v2 — jar details below are
// placeholder data derived from the URL slug. Wire to a real getPublicJar()
// once the campaign-jars API ships.
interface Jar {
  name: string;
  description: string;
  goal: number | null;
  totalRaised: number;
  tipCount: number;
}

function makePlaceholderJar(jarSlug: string): Jar {
  const name = jarSlug
    .split("-")
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(" ");
  return {
    name: name || "Campaign Jar",
    description:
      "Help this campaign reach its goal. Every tip drops straight into the jar and moves the bar.",
    goal: 5000,
    totalRaised: 1840,
    tipCount: 42,
  };
}

const PRESETS = [5, 10, 20, 50, 100, 200];

export default function JarPage({
  params,
}: {
  params: Promise<{ slug: string; jarSlug: string }>;
}) {
  const { slug, jarSlug } = use(params);
  const [jar, setJar] = useState<Jar>(() => makePlaceholderJar(jarSlug));

  useEffect(() => {
    let alive = true;
    api
      .getJar(slug, jarSlug)
      .then((j) => {
        if (!alive) return;
        setJar({
          name: j.name,
          description:
            j.description ||
            "Help this campaign reach its goal. Every tip supports the creator.",
          goal: j.goal ? parseFloat(j.goal) : null,
          totalRaised: 0,
          tipCount: 0,
        });
      })
      .catch(() => {});
    return () => {
      alive = false;
    };
  }, [slug, jarSlug]);

  const progress =
    jar.goal && jar.goal > 0
      ? Math.min((jar.totalRaised / jar.goal) * 100, 100)
      : null;

  return (
    <section className="container-content py-12">
      {/* Breadcrumb */}
      <nav className="flex flex-wrap items-center gap-2 text-sm text-muted">
        <Link href="/" className="hover:text-white">
          TippingJar
        </Link>
        <span>›</span>
        <Link href={`/creator/${slug}`} className="hover:text-white">
          {slug}
        </Link>
        <span>›</span>
        <span className="text-white">{jar.name}</span>
      </nav>

      <div className="mt-8 grid gap-10 lg:grid-cols-[4fr_5fr]">
        {/* Left — jar info */}
        <div>
          <div className="grid h-16 w-16 place-items-center rounded-2xl border border-teal/30 bg-teal/12 text-3xl">
            🫙
          </div>
          <h1 className="mt-5 text-3xl font-extrabold tracking-tight md:text-4xl">
            {jar.name}
          </h1>
          <p className="body-muted mt-3 text-lg">{jar.description}</p>

          {/* Stats */}
          <div className="mt-7 flex flex-wrap gap-3">
            <StatPill label="Raised" value={`R${jar.totalRaised.toFixed(0)}`} />
            <StatPill label="Tips" value={`${jar.tipCount}`} />
            {jar.goal != null && (
              <StatPill label="Goal" value={`R${jar.goal.toFixed(0)}`} />
            )}
          </div>

          {/* Progress */}
          {progress != null && (
            <div className="mt-7">
              <div className="flex items-center justify-between text-sm">
                <span className="text-muted">Progress</span>
                <span className="font-bold text-teal">
                  {progress.toFixed(1)}%
                </span>
              </div>
              <div className="mt-2 h-2.5 overflow-hidden rounded-full bg-border">
                <div
                  className="h-full rounded-full bg-brand-gradient"
                  style={{ width: `${progress}%` }}
                />
              </div>
            </div>
          )}

          <Link
            href={`/creator/${slug}`}
            className="mt-7 inline-block text-sm text-muted underline hover:text-white"
          >
            ← Back to creator page
          </Link>
        </div>

        {/* Right — tip form */}
        <JarTipForm creatorSlug={slug} jarName={jar.name} />
      </div>
    </section>
  );
}

function StatPill({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-2xl border border-border bg-card px-4 py-3">
      <div className="text-lg font-extrabold text-white">{value}</div>
      <div className="text-xs text-muted">{label}</div>
    </div>
  );
}

function JarTipForm({
  creatorSlug,
  jarName,
}: {
  creatorSlug: string;
  jarName: string;
}) {
  const [amount, setAmount] = useState(20);
  const [custom, setCustom] = useState("");
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [message, setMessage] = useState("");
  const [quote, setQuote] = useState<FeeQuote | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<Tip | null>(null);

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

  function onCustom(v: string) {
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
    setSubmitting(true);
    setError(null);
    try {
      // NOTE: createTip has no jar_id param in /api/v2 yet — the tip is sent to
      // the creator. TODO(api): attach jar_id once the jars endpoint ships.
      const tip = await api.createTip({
        creator_slug: creatorSlug,
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

  const fee = (v: string | undefined) => {
    const n = parseFloat(v ?? "0");
    return Number.isNaN(n) ? "0.00" : n.toFixed(2);
  };

  if (success) {
    return (
      <div className="card text-center">
        <div className="mx-auto grid h-16 w-16 place-items-center rounded-full bg-teal/12 text-3xl">
          💚
        </div>
        <h2 className="mt-4 text-2xl font-extrabold">Thank you! 🎉</h2>
        <p className="body-muted mx-auto mt-2 max-w-xs">
          Your tip was sent to the &ldquo;{jarName}&rdquo; jar.
        </p>
        {success.reference && (
          <p className="mt-4 font-mono text-sm text-muted">
            Ref: {success.reference}
          </p>
        )}
        <button
          onClick={() => {
            setSuccess(null);
            setAmount(20);
            setCustom("");
            setName("");
            setEmail("");
            setMessage("");
          }}
          className="btn-primary mt-6"
        >
          Send another tip
        </button>
      </div>
    );
  }

  return (
    <div className="card">
      <h2 className="text-2xl font-extrabold tracking-tight">
        Drop a tip into this jar
      </h2>
      <p className="mt-1 text-sm font-semibold text-teal">
        Supporting: {jarName}
      </p>

      {/* Presets */}
      <p className="mt-6 text-sm font-semibold text-white">Choose amount</p>
      <div className="mt-3 grid grid-cols-3 gap-3">
        {PRESETS.map((v) => {
          const active = custom === "" && amount === v;
          return (
            <button
              key={v}
              type="button"
              onClick={() => {
                setAmount(v);
                setCustom("");
              }}
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
      <div className="mt-4 flex items-center rounded-2xl border border-border bg-darker px-4 focus-within:border-teal">
        <span className="text-muted">R</span>
        <input
          inputMode="decimal"
          value={custom}
          onChange={(e) => onCustom(e.target.value)}
          placeholder="Or enter a custom amount"
          className="w-full bg-transparent py-3 pl-2 text-white placeholder:text-muted focus:outline-none"
        />
      </div>

      {/* Fee breakdown */}
      {amount >= 1 && (
        <div className="mt-5 rounded-2xl border border-teal/20 bg-teal/[0.06] p-4 text-xs">
          <div className="flex items-center justify-between text-sm font-semibold text-teal">
            <span>Sending to {jarName}</span>
            <span>R{amount.toFixed(2)}</span>
          </div>
          <div className="mt-3 space-y-1.5">
            <div className="flex justify-between text-muted">
              <span>
                Platform fee{quote ? ` (${fee(quote.platform_pct)}%)` : ""}
              </span>
              <span>- R{quote ? fee(quote.platform_fee) : "…"}</span>
            </div>
            <div className="flex justify-between text-muted">
              <span>
                Service fee{quote ? ` (${fee(quote.service_pct)}%)` : ""}
              </span>
              <span>- R{quote ? fee(quote.service_fee) : "…"}</span>
            </div>
            <div className="mt-2 flex justify-between border-t border-border pt-2 font-bold text-white">
              <span>Creator receives</span>
              <span>R{quote ? fee(quote.creator_net) : amount.toFixed(2)}</span>
            </div>
          </div>
        </div>
      )}

      {/* Fields */}
      <input
        value={name}
        onChange={(e) => setName(e.target.value)}
        placeholder="Your name (optional)"
        className="mt-5 w-full rounded-2xl border border-border bg-darker px-4 py-3 text-white placeholder:text-muted focus:border-teal focus:outline-none"
      />
      <input
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder="Email (for receipt, optional)"
        className="mt-3 w-full rounded-2xl border border-border bg-darker px-4 py-3 text-white placeholder:text-muted focus:border-teal focus:outline-none"
      />
      <textarea
        value={message}
        onChange={(e) => setMessage(e.target.value.slice(0, 280))}
        rows={3}
        placeholder="Say something nice…"
        className="mt-3 w-full resize-none rounded-2xl border border-border bg-darker px-4 py-3 text-white placeholder:text-muted focus:border-teal focus:outline-none"
      />

      {error && (
        <p className="mt-3 text-sm text-red-400">{error}</p>
      )}

      <button
        type="button"
        onClick={submit}
        disabled={submitting || amount < 1}
        className="btn-primary mt-5 w-full text-base disabled:cursor-not-allowed disabled:opacity-50"
      >
        {submitting
          ? "Sending…"
          : amount < 1
            ? "Enter an amount"
            : `Tip R${amount.toFixed(2)}`}
      </button>
    </div>
  );
}
