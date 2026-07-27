"use client";

// A live wall clock for the dashboard top bar. Owns its own state + interval so
// only this component re-renders every second — the dashboard tree does not.
// Renders a placeholder on the server/first paint to avoid a hydration mismatch.

import { useEffect, useState } from "react";
import { Clock as ClockIcon } from "lucide-react";

export function LiveClock() {
  const [now, setNow] = useState<Date | null>(null);

  useEffect(() => {
    setNow(new Date());
    const id = setInterval(() => setNow(new Date()), 1000);
    return () => clearInterval(id);
  }, []);

  const date = now
    ? now.toLocaleDateString(undefined, { weekday: "short", day: "numeric", month: "short" })
    : "——";
  const pad = (n: number) => String(n).padStart(2, "0");
  const time = now ? `${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}` : "--:--:--";

  return (
    <span className="inline-flex items-center gap-2 rounded-full border border-border bg-white px-3 py-1.5 shadow-soft">
      <ClockIcon className="h-3.5 w-3.5 text-teal" strokeWidth={2.4} />
      <span className="hidden text-xs font-medium text-muted sm:inline">{date}</span>
      <span aria-hidden className="hidden h-3 w-px bg-border sm:inline-block" />
      <span
        suppressHydrationWarning
        className="font-mono text-xs font-medium tabular-nums tracking-tight text-ink"
      >
        {time}
      </span>
    </span>
  );
}
