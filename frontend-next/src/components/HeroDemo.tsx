"use client";

import { useEffect, useMemo, useState } from "react";
import { api } from "@/lib/api";
import { JarMeter } from "./JarMeter";
import type { FeeQuote } from "@/types";

const CHIPS = [20, 50, 100, 200, 500];

// The signature: an interactive tip. Drag the amount and the jar fills while a
// live receipt shows exactly what the creator keeps — the fee split comes from
// the real payments API, so the transparency claim is demonstrated, not asserted.
export function HeroDemo() {
  const [amount, setAmount] = useState(120);
  const [quote, setQuote] = useState<FeeQuote | null>(null);

  useEffect(() => {
    let alive = true;
    const t = setTimeout(() => {
      api
        .quote(amount)
        .then((q) => alive && setQuote(q))
        .catch(() => alive && setQuote(null));
    }, 220);
    return () => {
      alive = false;
      clearTimeout(t);
    };
  }, [amount]);

  // Illustrative fill — a bigger tip drops the level higher (8%–100%).
  const pct = useMemo(() => {
    const c = Math.max(10, Math.min(1000, amount));
    return Math.round(8 + ((c - 10) / 990) * 92);
  }, [amount]);

  const fee = (v?: string) => (v ? parseFloat(v).toFixed(2) : "0.00");
  const net = quote ? parseFloat(quote.creator_net) : amount;

  return (
    <div className="relative mx-auto w-full max-w-sm lg:mx-0 lg:ml-auto">
      {/* Soft navy radial glow behind the jar — keeps text legible on top
          of the hero photo without reintroducing a visible card. */}
      <span
        aria-hidden
        className="pointer-events-none absolute inset-0 -z-10"
        style={{
          background:
            "radial-gradient(60% 55% at 50% 50%, rgba(15,36,57,0.55) 0%, rgba(15,36,57,0.28) 55%, transparent 82%)",
        }}
      />
      <div className="!bg-transparent p-2">
        <div className="flex items-center justify-between font-mono text-[11px] uppercase tracking-[0.18em] text-white/60">
          <span>Try a tip</span>
          <span className="inline-flex items-center gap-1 text-mint">
            <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-mint" /> live
          </span>
        </div>

        <div className="mt-1">
          <JarMeter raised={`R${amount}`} goal="" pct={pct} label="a tip of" dark />
        </div>

        <input
          type="range"
          min={10}
          max={1000}
          step={5}
          value={amount}
          onChange={(e) => setAmount(parseInt(e.target.value, 10))}
          className="tip-range mt-1"
          aria-label="Tip amount in rands"
        />
        <div className="mt-3 flex flex-wrap justify-center gap-2">
          {CHIPS.map((v) => (
            <button
              key={v}
              type="button"
              onClick={() => setAmount(v)}
              className={`rounded-full px-3 py-1.5 font-mono text-xs transition ${
                amount === v
                  ? "bg-mint text-navy"
                  : "border border-white/20 text-white/80 hover:border-mint/60 hover:text-mint"
              }`}
            >
              R{v}
            </button>
          ))}
        </div>

        <div className="mt-5 space-y-1.5 border-t border-dashed border-white/20 pt-4 font-mono text-[12px] text-white/70">
          <div className="flex justify-between">
            <span>platform fee{quote ? ` (${fee(quote.platform_pct)}%)` : ""}</span>
            <span>− R{fee(quote?.platform_fee)}</span>
          </div>
          <div className="flex justify-between">
            <span>service fee{quote ? ` (${fee(quote.service_pct)}%)` : ""}</span>
            <span>− R{fee(quote?.service_fee)}</span>
          </div>
        </div>
        <div className="mt-3 flex items-center justify-between rounded-2xl border border-mint/25 bg-mint/10 px-4 py-3">
          <span className="text-sm font-semibold text-white">Creator keeps</span>
          <span className="font-display text-2xl font-extrabold text-mint">
            R{net.toFixed(2)}
          </span>
        </div>
      </div>
      <p className="mt-3 text-center font-mono text-[11px] text-white/60">
        drag the amount — see what a creator takes home
      </p>
    </div>
  );
}
