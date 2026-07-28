"use client";

// OBS tip overlay — streamers add this URL as a Browser Source. Transparent
// background, polls for new completed tips and toasts them; optional jar bar.
//   https://www.tippingjar.co.za/overlay/<slug>

import { use, useEffect, useRef, useState } from "react";
import { api } from "@/lib/api";
import type { Creator, Tip } from "@/types";

export default function OverlayPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = use(params);
  const [creator, setCreator] = useState<Creator | null>(null);
  const [toast, setToast] = useState<Tip | null>(null);
  const [raised, setRaised] = useState(0);
  const seen = useRef<Set<string>>(new Set());
  const queue = useRef<Tip[]>([]);
  const primed = useRef(false);

  // Transparent page for OBS.
  useEffect(() => {
    document.documentElement.style.background = "transparent";
    document.body.style.background = "transparent";
  }, []);

  useEffect(() => {
    let alive = true;
    api.getCreator(slug).then((c) => alive && setCreator(c)).catch(() => null);
    return () => { alive = false; };
  }, [slug]);

  useEffect(() => {
    if (!creator) return;
    let alive = true;
    async function poll() {
      try {
        const tips = (await api.tipsForCreator(creator!.id)).filter((t) => t.status === "completed");
        if (!alive) return;
        setRaised(tips.reduce((s, t) => s + (Number(t.amount) || 0), 0));
        if (!primed.current) {
          tips.forEach((t) => seen.current.add(t.id)); // don't replay history on load
          primed.current = true;
        } else {
          for (const t of tips) {
            if (!seen.current.has(t.id)) {
              seen.current.add(t.id);
              queue.current.push(t);
            }
          }
        }
      } catch { /* retry next poll */ }
      if (alive) window.setTimeout(poll, 8000);
    }
    poll();
    return () => { alive = false; };
  }, [creator]);

  // Drain the toast queue one at a time.
  useEffect(() => {
    const iv = window.setInterval(() => {
      setToast((cur) => {
        if (cur) return cur;
        return queue.current.shift() ?? null;
      });
    }, 500);
    return () => window.clearInterval(iv);
  }, []);
  useEffect(() => {
    if (!toast) return;
    const t = window.setTimeout(() => setToast(null), 7000);
    return () => window.clearTimeout(t);
  }, [toast]);

  const goal = creator?.tip_goal ? Number(creator.tip_goal) : 0;
  const accent = creator?.theme || "#12A25C";

  return (
    <div className="pointer-events-none fixed inset-0 flex flex-col justify-end p-6" style={{ background: "transparent" }}>
      {toast && (
        <div
          className="slip-in mb-4 w-fit max-w-md rounded-2xl border-2 bg-white px-6 py-4 shadow-lift"
          style={{ borderColor: accent }}
        >
          <p className="font-mono text-[11px] uppercase tracking-[0.2em]" style={{ color: accent }}>
            🫙 New tip!
          </p>
          <p className="mt-1 font-display text-2xl font-extrabold text-ink">
            {toast.tipper_name || "Anonymous"} tipped R{Math.round(Number(toast.amount))}
          </p>
          {toast.message && <p className="mt-1 text-sm text-muted">&ldquo;{toast.message}&rdquo;</p>}
        </div>
      )}
      {goal > 0 && creator && (
        <div className="w-full max-w-md rounded-full border border-white/40 bg-navy/85 px-5 py-3 backdrop-blur">
          <div className="flex items-center justify-between font-mono text-[11px] uppercase tracking-[0.16em] text-white">
            <span>{creator.display_name} · tip goal</span>
            <span>
              R{Math.round(raised).toLocaleString("en-ZA")} / R{Math.round(goal).toLocaleString("en-ZA")}
            </span>
          </div>
          <div className="mt-2 h-2.5 overflow-hidden rounded-full bg-white/20">
            <div
              className="h-full rounded-full transition-all duration-700"
              style={{ width: `${Math.min(100, (raised / goal) * 100)}%`, background: accent }}
            />
          </div>
        </div>
      )}
    </div>
  );
}
