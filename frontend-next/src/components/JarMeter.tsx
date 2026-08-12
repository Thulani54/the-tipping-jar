// The signature: a glass jar that fills with "support" toward a goal.
// Pure SVG + CSS animation (fills on load; static under prefers-reduced-motion).

export function JarMeter({
  raised = "R2,340",
  goal = "R3,000",
  pct = 78,
  label,
  dark = false,
}: {
  raised?: string;
  goal?: string; // empty string → no goal (show "raised so far")
  pct?: number;
  label?: string;
  /** Invert the text + glass stroke for use on a dark hero background. */
  dark?: boolean;
}) {
  const empty = Math.max(0, Math.min(100, 100 - pct));
  const stroke = dark ? "#ffffff" : "var(--navy)";
  const strokeOpacity = dark ? 0.35 : 0.15;
  const lidFill = dark ? "#ffffff" : "var(--navy)";
  const neckFill = dark ? "rgba(255,255,255,0.08)" : "#ffffff";
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
        <rect x="28" y="74" width="164" height="200" rx="32" fill="none" stroke={stroke} strokeOpacity={strokeOpacity} strokeWidth="2.5" />
        <rect x="41" y="96" width="9" height="140" rx="4.5" fill="#ffffff" opacity="0.55" />
        {/* neck + lid */}
        <rect x="54" y="56" width="112" height="26" rx="9" fill={neckFill} stroke={stroke} strokeOpacity={strokeOpacity} strokeWidth="2.5" />
        <rect x="62" y="45" width="96" height="16" rx="7" fill={lidFill} />
      </svg>

      <div className="mt-5 text-center">
        <p className={`font-display text-3xl font-extrabold tracking-tight ${dark ? "text-white" : "text-ink"}`}>
          {raised}
          {goal && (
            <span className={`ml-1 text-lg font-semibold ${dark ? "text-white/60" : "text-muted"}`}>/ {goal}</span>
          )}
        </p>
        <p className={`mt-1 font-mono text-[11px] uppercase tracking-[0.18em] ${dark ? "text-white/60" : "text-muted"}`}>
          {goal ? `${pct}% ${label ?? "of goal"}` : (label ?? "raised so far")}
        </p>
      </div>
    </div>
  );
}
