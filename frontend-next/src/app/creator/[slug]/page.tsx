import Link from "next/link";
import { api } from "@/lib/api";
import type { Creator, Tip } from "@/types";

async function load(
  slug: string,
): Promise<{ creator: Creator | null; tips: Tip[] }> {
  let creator: Creator | null = null;
  try {
    creator = await api.getCreator(slug);
  } catch {
    return { creator: null, tips: [] };
  }
  let tips: Tip[] = [];
  try {
    tips = await api.tipsForCreator(creator.id);
  } catch {
    tips = [];
  }
  return { creator, tips };
}

function initials(name: string): string {
  return (
    name
      .split(" ")
      .map((w) => w.charAt(0))
      .join("")
      .slice(0, 2)
      .toUpperCase() || "T"
  );
}

function maskName(name: string): string {
  const n = name.trim();
  if (!n || n.toLowerCase() === "anonymous") return "Anonymous";
  const parts = n.split(" ");
  if (parts.length === 1) {
    return parts[0].length <= 2
      ? parts[0]
      : `${parts[0].charAt(0)}${"•".repeat(Math.min(parts[0].length - 1, 4))}`;
  }
  return `${parts[0]} ${parts[parts.length - 1].charAt(0)}.`;
}

function relative(iso: string): string {
  const then = new Date(iso).getTime();
  if (Number.isNaN(then)) return "";
  const mins = Math.floor((Date.now() - then) / 60000);
  if (mins < 1) return "just now";
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  if (days === 1) return "yesterday";
  return `${days}d ago`;
}

function money(v: string | null): string {
  const n = parseFloat(v ?? "0");
  return Number.isNaN(n) ? "0" : n.toFixed(2);
}

export default async function CreatorPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const { creator, tips } = await load(slug);

  if (!creator) {
    return (
      <section className="container-content py-32 text-center">
        <div className="mx-auto grid h-16 w-16 place-items-center rounded-full bg-card text-3xl">
          🫙
        </div>
        <h1 className="heading-xl mt-6">Creator not found</h1>
        <p className="body-muted mx-auto mt-4 max-w-md">
          This page may have moved or the link is invalid.
        </p>
        <div className="mt-8 flex justify-center gap-4">
          <Link href="/creators" className="btn-primary">
            Explore creators
          </Link>
          <Link href="/" className="btn-ghost">
            Go home
          </Link>
        </div>
      </section>
    );
  }

  const recent = tips.slice(0, 5);

  return (
    <section className="pb-24">
      {/* Cover */}
      <div className="h-40 w-full bg-brand-gradient opacity-90 md:h-56" />

      <div className="container-content">
        {/* Header */}
        <div className="-mt-14 flex flex-col items-start gap-5 sm:flex-row sm:items-end">
          <div className="grid h-28 w-28 place-items-center rounded-3xl border-4 border-darker bg-primary text-3xl font-extrabold text-white">
            {initials(creator.display_name)}
          </div>
          <div className="pb-1">
            <h1 className="text-3xl font-extrabold tracking-tight md:text-4xl">
              {creator.display_name}
            </h1>
            <p className="mt-1 text-muted">@{creator.slug}</p>
            {creator.category && (
              <span className="mt-3 inline-block rounded-full bg-teal/10 px-3 py-1 text-xs font-semibold text-teal">
                {creator.category}
              </span>
            )}
          </div>
        </div>

        {creator.tagline && (
          <p className="body-muted mt-6 max-w-2xl text-lg">{creator.tagline}</p>
        )}

        {/* Tip CTA */}
        <div className="mt-8 flex flex-wrap items-center gap-4">
          <Link href={`/tip/${creator.slug}`} className="btn-primary text-base">
            💚 Tip {creator.display_name}
          </Link>
          <Link
            href={`/creator/${creator.slug}/subscribe`}
            className="btn-ghost text-base"
          >
            Subscribe
          </Link>
          {creator.tip_goal && (
            <span className="text-sm text-muted">
              Goal: R{money(creator.tip_goal)}
            </span>
          )}
        </div>

        {/* Recent tips */}
        <div className="mt-14">
          <h2 className="text-xl font-bold tracking-tight">Recent supporters</h2>
          {recent.length === 0 ? (
            <div className="card mt-6 py-12 text-center">
              <div className="text-3xl">🙌</div>
              <p className="body-muted mx-auto mt-3 max-w-sm">
                No tips yet — be the first to support {creator.display_name}.
              </p>
              <Link
                href={`/tip/${creator.slug}`}
                className="btn-primary mt-6"
              >
                Send the first tip →
              </Link>
            </div>
          ) : (
            <div className="mt-6 space-y-3">
              {recent.map((tip) => (
                <div
                  key={tip.id}
                  className="flex items-start gap-3 rounded-2xl border border-border bg-card p-4"
                >
                  <div className="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-teal/10 text-sm font-bold text-teal">
                    {(tip.tipper_name || "A").charAt(0).toUpperCase()}
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2">
                      <span className="truncate font-semibold text-white">
                        {maskName(tip.tipper_name)}
                      </span>
                      <span className="text-xs text-muted">
                        {relative(tip.created_at)}
                      </span>
                      <span className="ml-auto font-bold text-teal">
                        R{money(tip.amount)}
                      </span>
                    </div>
                    {tip.message && (
                      <p className="body-muted mt-1 line-clamp-3 text-sm">
                        {tip.message}
                      </p>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </section>
  );
}
