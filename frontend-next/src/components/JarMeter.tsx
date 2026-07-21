// The signature: a glass jar that fills with "support" toward a goal.
// Pure SVG + CSS animation (fills on load; static under prefers-reduced-motion).

export function JarMeter({
  raised = "R2,340",
  goal = "R3,000",
  pct = 78,
  label = "of this month's goal",
}: {
  raised?: string;
  goal?: string;
  pct?: number;
  label?: string;
}) {
  const empty = Math.max(0, Math.min(100, 100 - pct));
  return (
    <div className="mx-auto w-[240px] select-none">
      <svg
        viewBox="0 0 220 300"
        className="w-full"
        role="img"
        aria-label={`${raised} raised, ${pct}% of ${goal} goal`}
      >
        <defs>
          <clipPath id="jarBody">
            <rect x="28" y="74" width="164" height="200" rx="32" />
          </clipPath>
        </defs>

        {/* liquid + coins, clipped to the jar body */}
        <g clipPath="url(#jarBody)">
          <g
            className="jar-liquid"
            style={{ ["--empty"]: `${empty}%` } as React.CSSProperties}
          >
            <rect x="28" y="74" width="164" height="200" fill="var(--mint)" />
            <rect x="28" y="74" width="164" height="5" fill="#3ab877" />
          </g>
          <ellipse className="jar-coin" style={{ animationDelay: "0.95s" }} cx="82" cy="256" rx="23" ry="8.5" fill="var(--gold)" />
          <ellipse className="jar-coin" style={{ animationDelay: "1.1s" }} cx="130" cy="262" rx="25" ry="9" fill="#eebe5c" />
          <ellipse className="jar-coin" style={{ animationDelay: "1.25s" }} cx="106" cy="249" rx="21" ry="8" fill="var(--gold)" />
        </g>

        {/* glass */}
        <rect x="28" y="74" width="164" height="200" rx="32" fill="none" stroke="var(--navy)" strokeOpacity="0.15" strokeWidth="2.5" />
        <rect x="41" y="96" width="9" height="140" rx="4.5" fill="#ffffff" opacity="0.55" />
        {/* neck + lid */}
        <rect x="54" y="56" width="112" height="26" rx="9" fill="#ffffff" stroke="var(--navy)" strokeOpacity="0.15" strokeWidth="2.5" />
        <rect x="62" y="45" width="96" height="16" rx="7" fill="var(--navy)" />
      </svg>

      <div className="mt-5 text-center">
        <p className="font-display text-3xl font-extrabold tracking-tight text-ink">
          {raised}
          <span className="ml-1 text-lg font-semibold text-muted">/ {goal}</span>
        </p>
        <p className="mt-1 font-mono text-[11px] uppercase tracking-[0.18em] text-muted">
          {pct}% {label}
        </p>
      </div>
    </div>
  );
}
