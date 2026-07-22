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
    const c = Math.max(5, Math.min(1000, amount));
    return Math.round(8 + ((c - 5) / 995) * 92);
  }, [amount]);

  const fee = (v?: string) => (v ? parseFloat(v).toFixed(2) : "0.00");
  const net = quote ? parseFloat(quote.creator_net) : amount;

  return (
    <div className="relative mx-auto w-full max-w-sm lg:mx-0 lg:ml-auto">
      <div className="card !rounded-[26px] !p-6 shadow-lift">
        <div className="flex items-center justify-between font-mono text-[11px] uppercase tracking-[0.18em] text-muted">
          <span>Try a tip</span>
          <span className="inline-flex items-center gap-1 text-green">
            <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-green" /> live
          </span>
        </div>

        <div className="mt-1">
          <JarMeter raised={`R${amount}`} goal="" pct={pct} label="a tip of" />
        </div>

        <input
          type="range"
          min={5}
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
                  ? "bg-primary text-white"
                  : "border border-border text-muted hover:border-primary/40"
              }`}
            >
              R{v}
            </button>
          ))}
        </div>

        <div className="mt-5 space-y-1.5 border-t border-dashed border-border pt-4 font-mono text-[12px] text-muted">
          <div className="flex justify-between">
            <span>platform fee{quote ? ` (${fee(quote.platform_pct)}%)` : ""}</span>
            <span>− R{fee(quote?.platform_fee)}</span>
          </div>
          <div className="flex justify-between">
            <span>service fee{quote ? ` (${fee(quote.service_pct)}%)` : ""}</span>
            <span>− R{fee(quote?.service_fee)}</span>
          </div>
        </div>
        <div className="mt-3 flex items-center justify-between rounded-2xl bg-mint/10 px-4 py-3">
          <span className="text-sm font-semibold text-ink">Creator keeps</span>
          <span className="font-display text-2xl font-extrabold text-green">
            R{net.toFixed(2)}
          </span>
        </div>
      </div>
      <p className="mt-3 text-center font-mono text-[11px] text-muted">
        drag the amount — see what a creator takes home
      </p>
    </div>
  );
}
