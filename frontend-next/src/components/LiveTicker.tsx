"use client";

export type TickerItem = { name: string; amount: string; creator: string };

// A continuously scrolling strip of recent support — makes the platform feel
// alive. Pauses on hover; static under reduced motion.
export function LiveTicker({ items }: { items: TickerItem[] }) {
  if (!items.length) return null;
  const row = [...items, ...items];
  return (
    <div className="ticker-mask overflow-hidden">
      <div className="ticker-track py-1">
        {row.map((t, i) => (
          <span
            key={i}
            className="mx-1.5 inline-flex shrink-0 items-center gap-2 rounded-full border border-border bg-white px-4 py-2 text-sm shadow-soft"
          >
            <span className="grid h-6 w-6 place-items-center rounded-full bg-mint/15 text-[11px] font-bold text-green">
              {t.name.charAt(0).toUpperCase()}
            </span>
            <span className="font-semibold text-ink">{t.name}</span>
            <span className="text-muted">tipped</span>
            <span className="font-display font-bold text-green">{t.amount}</span>
            {t.creator && <span className="whitespace-nowrap text-muted">→ {t.creator}</span>}
          </span>
        ))}
      </div>
    </div>
  );
}
