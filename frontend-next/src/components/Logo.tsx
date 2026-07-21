import Link from "next/link";

export function Logo({ size = 34 }: { size?: number }) {
  return (
    <Link href="/" className="flex items-center gap-2.5">
      <span
        className="grid place-items-center rounded-xl bg-brand-gradient font-black text-ink"
        style={{ width: size, height: size, fontSize: size * 0.5 }}
        aria-hidden
      >
        T
      </span>
      <span className="text-lg font-extrabold tracking-tight text-ink">
        Tipping<span className="text-teal">Jar</span>
      </span>
    </Link>
  );
}
