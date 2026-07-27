import Link from "next/link";
import { IconJar } from "./Icons";
import type { Creator } from "@/types";

const initial = (name: string) => (name.trim()[0] || "T").toUpperCase();

export function CreatorCard({ creator }: { creator: Creator }) {
  return (
    <Link
      href={`/creator/${creator.slug}`}
      className="group glass-card flex flex-col p-6"
    >
      <div className="flex items-start gap-3.5">
        <div className="grid h-14 w-14 shrink-0 place-items-center rounded-2xl bg-gradient-to-br from-primary to-green text-lg font-extrabold text-white shadow-lift transition-transform duration-300 group-hover:scale-105">
          {initial(creator.display_name)}
        </div>
        <div className="min-w-0 flex-1">
          <h3 className="truncate font-display text-lg font-bold text-ink group-hover:text-green">
            {creator.display_name}
          </h3>
          <p className="truncate font-mono text-xs text-muted">@{creator.slug}</p>
        </div>
        {creator.category && (
          <span className="shrink-0 rounded-full border border-green/20 bg-mint/20 px-2.5 py-1 text-[11px] font-semibold text-green">
            {creator.category}
          </span>
        )}
      </div>

      <p className="body-muted mt-4 line-clamp-2 min-h-[2.6em]">
        {creator.tagline || `Support ${creator.display_name} on Tipping Jar.`}
      </p>

      <div className="mt-5 flex items-center justify-between border-t border-green/15 pt-4">
        <span className="inline-flex items-center gap-1.5 font-mono text-xs text-muted">
          <IconJar className="h-4 w-4 text-green" /> tip jar
        </span>
        <span className="inline-flex items-center gap-1 rounded-full bg-primary px-4 py-1.5 text-xs font-semibold text-white transition-all duration-300 group-hover:gap-2 group-hover:bg-green">
          Tip <i className="bi bi-arrow-right" />
        </span>
      </div>
    </Link>
  );
}
