import Link from "next/link";
import type { Creator } from "@/types";
import { tipReadinessChecklist, tipReadinessPct } from "@/lib/creator-complete";

// Public placeholder shown in place of the tip page while a creator's
// profile is still being set up. It's intentionally warm rather than
// error-toned — "come back soon" not "something's broken" — because
// this is a fan seeing an under-construction creator page, not a
// system failure.
export function UnavailableTips({ creator }: { creator: Creator }) {
  const pct = tipReadinessPct(creator);
  const items = tipReadinessChecklist(creator);
  const missing = items.filter((i) => !i.done).length;
  const inactive = creator.is_active === false;

  return (
    <section className="min-h-[70vh] bg-gradient-to-b from-[#f3f9f5] to-white">
      <div className="container-content pt-16 pb-24 sm:pt-24">
        <div className="mx-auto max-w-xl text-center">
          {/* Avatar puck so the fan still sees who they were coming to
              support — feels personal, not like a 404. */}
          <div className="relative mx-auto h-24 w-24">
            <div className="grid h-full w-full place-items-center overflow-hidden rounded-3xl bg-navy shadow-lift ring-4 ring-white">
              {creator.avatar_url ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={creator.avatar_url} alt="" className="h-full w-full object-cover" />
              ) : (
                <span className="text-3xl font-extrabold text-white">
                  {(creator.display_name || "T").charAt(0).toUpperCase()}
                </span>
              )}
            </div>
            <span
              aria-hidden
              className="absolute -bottom-2 -right-2 grid h-9 w-9 place-items-center rounded-full bg-amber-500 text-white shadow-lift ring-4 ring-white"
            >
              <i className="bi bi-tools text-sm" />
            </span>
          </div>

          <p className="mt-6 inline-flex items-center gap-1.5 rounded-full border border-amber-500/30 bg-amber-500/10 px-3 py-1 text-xs font-semibold text-amber-700">
            <span className="relative flex h-1.5 w-1.5">
              <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-amber-500/60" />
              <span className="relative inline-flex h-1.5 w-1.5 rounded-full bg-amber-500" />
            </span>
            {inactive ? "Currently paused" : "Setting up their page"}
          </p>

          <h1 className="mt-4 font-display text-3xl font-extrabold tracking-tight text-ink sm:text-4xl">
            {creator.display_name || "This creator"} can&apos;t receive tips just yet.
          </h1>
          <p className="body-muted mx-auto mt-4 max-w-lg text-base">
            {inactive
              ? "Their page is paused for now. Save the link and check back in a little while — they'll be back soon."
              : "They're finishing up their public page. Save the link and check back in a bit — it'll only be a moment."}
          </p>

          {/* Live readiness meter — reassures the fan that this really is
              temporary. Only shown when the profile isn't paused. */}
          {!inactive && (
            <div className="mx-auto mt-8 max-w-sm">
              <div className="flex items-baseline justify-between text-xs text-muted">
                <span className="font-mono uppercase tracking-wide">Page readiness</span>
                <span className="font-semibold text-ink">{pct}%</span>
              </div>
              <div className="mt-2 h-2 w-full overflow-hidden rounded-full bg-border/60">
                <div
                  className="h-full rounded-full bg-teal transition-all duration-700"
                  style={{ width: `${Math.max(6, pct)}%` }}
                />
              </div>
              <p className="mt-2 text-xs text-muted">
                {missing === 1
                  ? "One last thing to finish."
                  : `${missing} things left before their jar opens.`}
              </p>
            </div>
          )}

          <div className="mt-10 flex flex-wrap items-center justify-center gap-3">
            <Link href="/creators" className="btn-primary !px-6 !py-3 text-sm">
              Explore other creators
            </Link>
            <Link href="/" className="btn-ghost !px-6 !py-3 text-sm">
              Back home
            </Link>
          </div>

          <p className="mt-8 text-[11px] text-muted">
            If this is your page, finish setup in your dashboard.
          </p>
        </div>
      </div>
    </section>
  );
}
