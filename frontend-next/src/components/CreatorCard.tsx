import Link from "next/link";
import type { Creator } from "@/types";

export function CreatorCard({ creator }: { creator: Creator }) {
  return (
    <Link
      href={`/creator/${creator.slug}`}
      className="card group transition hover:border-teal"
    >
      <div className="mb-4 h-24 rounded-2xl bg-brand-gradient opacity-90" />
      <div className="flex items-center gap-3">
        <div className="grid h-12 w-12 place-items-center rounded-full bg-primary text-lg font-bold text-ink">
          {creator.display_name.charAt(0).toUpperCase()}
        </div>
        <div className="min-w-0">
          <h3 className="truncate font-semibold text-ink group-hover:text-teal">
            {creator.display_name}
          </h3>
          <p className="truncate text-sm text-muted">
            {creator.category || "Creator"}
          </p>
        </div>
      </div>
      {creator.tagline && (
        <p className="body-muted mt-4 line-clamp-2">{creator.tagline}</p>
      )}
      <div className="mt-5 flex items-center justify-between">
        <span className="text-xs text-muted">@{creator.slug}</span>
        <span className="rounded-full bg-teal/10 px-3 py-1 text-xs font-semibold text-teal">
          Tip →
        </span>
      </div>
    </Link>
  );
}
