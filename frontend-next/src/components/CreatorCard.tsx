import Link from "next/link";
import { IconJar } from "./Icons";
import type { Creator } from "@/types";

const initial = (name: string) => (name.trim()[0] || "T").toUpperCase();

export function CreatorCard({ creator }: { creator: Creator }) {
  return (
    <Link
      href={`/creator/${creator.slug}`}
      className="group card flex flex-col transition duration-200 hover:-translate-y-1 hover:shadow-lift"
    >
      <div className="flex items-start gap-3.5">
        <div className="grid h-14 w-14 shrink-0 place-items-center rounded-2xl bg-primary text-lg font-extrabold text-white">
          {initial(creator.display_name)}
        </div>
        <div className="min-w-0 flex-1">
          <h3 className="truncate font-display text-lg font-bold text-ink group-hover:text-green">
            {creator.display_name}
          </h3>
          <p className="truncate font-mono text-xs text-muted">@{creator.slug}</p>
        </div>
        {creator.category && (
          <span className="shrink-0 rounded-full bg-mint/15 px-2.5 py-1 text-[11px] font-semibold text-green">
            {creator.category}
          </span>
        )}
      </div>

      <p className="body-muted mt-4 line-clamp-2 min-h-[2.6em]">
        {creator.tagline || `Support ${creator.display_name} on Tipping Jar.`}
      </p>

      <div className="mt-5 flex items-center justify-between border-t border-border pt-4">
        <span className="inline-flex items-center gap-1.5 font-mono text-xs text-muted">
          <IconJar className="h-4 w-4" /> tip jar
        </span>
        <span className="rounded-full bg-primary px-4 py-1.5 text-xs font-semibold text-white transition group-hover:bg-navy">
          Tip →
        </span>
      </div>
    </Link>
  );
}
