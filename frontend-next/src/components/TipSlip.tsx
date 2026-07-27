// A tip "slip" — the receipt motif. Mono voice, perforated top edge.

export function TipSlip({
  name,
  amount,
  message,
  className = "",
  style,
}: {
  name: string;
  amount: string;
  message?: string;
  className?: string;
  style?: React.CSSProperties;
}) {
  return (
    <div className={`slip ${className}`} style={style}>
      <div className="flex items-center justify-between font-mono text-[10px] uppercase tracking-[0.18em] text-muted">
        <span>Tip received</span>
        <span className="inline-flex items-center gap-1 text-green">
          <i className="bi bi-check-circle-fill" /> paid
        </span>
      </div>
      <div className="mt-2.5 flex items-center gap-3">
        <span className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-navy text-sm font-bold text-white">
          {name.charAt(0).toUpperCase()}
        </span>
        <div className="min-w-0">
          <p className="font-display text-[15px] font-bold text-ink">
            {name} <span className="text-muted">→</span> {amount}
          </p>
          {message && (
            <p className="truncate text-xs text-muted">&ldquo;{message}&rdquo;</p>
          )}
        </div>
      </div>
    </div>
  );
}
