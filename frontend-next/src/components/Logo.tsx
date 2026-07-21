import Link from "next/link";

export function Logo({ size = 32 }: { size?: number }) {
  return (
    <Link href="/" className="flex items-center gap-2.5">
      <svg width={size} height={size} viewBox="0 0 32 32" aria-hidden>
        {/* jar mark: navy vessel, mint fill, a gold coin dropping in */}
        <rect x="6.5" y="10" width="19" height="18" rx="6" fill="var(--navy)" />
        <path d="M6.5 20 h19 v2 a6 6 0 0 1-6 6 H12.5 a6 6 0 0 1-6-6 z" fill="var(--mint)" />
        <rect x="10.5" y="5.5" width="11" height="5" rx="2.5" fill="var(--navy)" />
        <circle cx="16" cy="15.5" r="3.2" fill="var(--gold)" />
      </svg>
      <span className="font-display text-lg font-extrabold tracking-tight text-ink">
        Tipping<span className="text-green">Jar</span>
      </span>
    </Link>
  );
}
