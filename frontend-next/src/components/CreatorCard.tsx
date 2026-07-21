import Link from "next/link";
import type { Creator } from "@/types";

export function CreatorCard({ creator }: { creator: Creator }) {
  return (
    <Link
      href={`/creator/${creator.slug}`}
      className="group card overflow-hidden !p-0 transition duration-200 hover:-translate-y-1 hover:shadow-lift"
    >
      <div className="relative h-24 bg-navy">
        <span aria-hidden className="absolute right-4 top-4 h-9 w-9 rounded-full bg-mint/25" />
        <span aria-hidden className="absolute right-10 top-10 h-4 w-4 rounded-full bg-gold/70" />
      </div>
      <div className="-mt-8 p-6">
        <div className="grid h-14 w-14 place-items-center rounded-2xl border-4 border-white bg-primary text-lg font-bold text-white">
          {creator.display_name.charAt(0).toUpperCase()}
        </div>
        <h3 className="mt-3 font-display text-lg font-bold text-ink group-hover:text-green">
          {creator.display_name}
        </h3>
        <p className="text-sm text-muted">{creator.category || "Creator"}</p>
        {creator.tagline && (
          <p className="body-muted mt-3 line-clamp-2">{creator.tagline}</p>
        )}
        <div className="mt-5 flex items-center justify-between border-t border-border pt-4">
          <span className="font-mono text-xs text-muted">@{creator.slug}</span>
          <span className="rounded-full bg-mint/15 px-3 py-1 text-xs font-semibold text-green">
            Tip →
          </span>
        </div>
      </div>
    </Link>
  );
}
