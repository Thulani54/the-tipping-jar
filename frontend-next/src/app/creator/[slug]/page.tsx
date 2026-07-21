import Link from "next/link";
import { api } from "@/lib/api";
import { JarMeter } from "@/components/JarMeter";
import type { Creator, Tip } from "@/types";

async function load(slug: string): Promise<{ creator: Creator | null; tips: Tip[] }> {
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

const initials = (name: string) =>
  name.split(" ").map((w) => w.charAt(0)).join("").slice(0, 2).toUpperCase() || "T";

function maskName(name: string): string {
  const n = (name || "").trim();
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
  return days === 1 ? "yesterday" : `${days}d ago`;
}

const rand = (n: number) => `R${Math.round(n).toLocaleString("en-ZA")}`;

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
        <div className="mx-auto grid h-16 w-16 place-items-center rounded-full bg-white text-3xl shadow-soft">
          🫙
        </div>
        <h1 className="heading-xl mt-6 text-4xl">Creator not found</h1>
        <p className="body-muted mx-auto mt-4 max-w-md">
          This page may have moved or the link is invalid.
        </p>
        <div className="mt-8 flex justify-center gap-4">
          <Link href="/creators" className="btn-primary">Explore creators</Link>
          <Link href="/" className="btn-ghost">Go home</Link>
        </div>
      </section>
    );
  }

  const completed = tips.filter((t) => t.status === "completed");
  const raised = completed.reduce((s, t) => s + (parseFloat(t.amount) || 0), 0);
  const supporters = new Set(
    completed.map((t) => (t.tipper_email || t.tipper_name || t.id).toLowerCase()),
  ).size;
  const now = new Date();
  const thisMonth = completed
    .filter((t) => {
      const d = new Date(t.created_at);
      return d.getMonth() === now.getMonth() && d.getFullYear() === now.getFullYear();
    })
    .reduce((s, t) => s + (parseFloat(t.amount) || 0), 0);

  const goal = creator.tip_goal ? parseFloat(creator.tip_goal) : 0;
  const pct = goal > 0 ? Math.min(100, Math.round((raised / goal) * 100)) : 0;
  const jarPct = goal > 0 ? Math.max(pct, 4) : raised > 0 ? 62 : 8;

  const recent = completed.slice(0, 8);

  return (
    <section className="pb-24">
      {/* Cover — solid navy with a coin motif */}
      <div className="relative h-36 w-full overflow-hidden bg-navy md:h-48">
        <span aria-hidden className="absolute right-[8%] top-6 h-16 w-16 rounded-full bg-mint/20" />
        <span aria-hidden className="absolute right-[16%] top-16 h-8 w-8 rounded-full bg-gold/60" />
        <span aria-hidden className="absolute right-[3%] bottom-[-20px] h-24 w-24 rounded-full border border-white/10" />
      </div>

      <div className="container-content">
        {/* Header */}
        <div className="-mt-14 flex flex-col gap-6 md:-mt-16 lg:flex-row lg:items-end lg:justify-between">
          <div className="flex items-end gap-5">
            <div className="grid h-28 w-28 shrink-0 place-items-center rounded-[26px] bg-white text-3xl font-extrabold text-primary shadow-lift ring-1 ring-border">
              {initials(creator.display_name)}
            </div>
            <div className="pb-1">
              <h1 className="font-display text-3xl font-extrabold tracking-tight text-ink md:text-4xl">
                {creator.display_name}
              </h1>
              <p className="mt-1 font-mono text-sm text-muted">@{creator.slug}</p>
              {creator.category && (
                <span className="mt-3 inline-block rounded-full bg-mint/15 px-3 py-1 text-xs font-semibold text-green">
                  {creator.category}
                </span>
              )}
            </div>
          </div>
        </div>

        {creator.tagline && (
          <p className="body-muted mt-6 max-w-2xl text-lg">{creator.tagline}</p>
        )}

        {/* Two columns: supporters ledger + the jar */}
        <div className="mt-10 grid gap-8 lg:grid-cols-[1fr_360px]">
          {/* Jar + tip CTA — first on mobile, right on desktop */}
          <aside className="lg:order-2 lg:sticky lg:top-24 lg:self-start">
            <div className="card">
              <p className="eyebrow text-center">Support {creator.display_name.split(" ")[0]}</p>
              <div className="mt-6">
                <JarMeter
                  raised={rand(raised)}
                  goal={goal > 0 ? rand(goal) : ""}
                  pct={jarPct}
                  label={goal > 0 ? "of monthly goal" : "raised so far"}
                />
              </div>
              <Link href={`/tip/${creator.slug}`} className="btn-primary mt-8 w-full text-base">
                💚 Tip {creator.display_name.split(" ")[0]}
              </Link>
              <Link
                href={`/creator/${creator.slug}/subscribe`}
                className="btn-ghost mt-3 w-full"
              >
                Subscribe monthly
              </Link>
            </div>
          </aside>

          {/* Main: stats + ledger */}
          <div className="lg:order-1">
            <div className="grid grid-cols-3 gap-4">
              {[
                [rand(raised), "raised"],
                [String(supporters), supporters === 1 ? "supporter" : "supporters"],
                [rand(thisMonth), "this month"],
              ].map(([big, small]) => (
                <div key={small} className="card !p-5">
                  <p className="font-display text-2xl font-extrabold text-ink">{big}</p>
                  <p className="mt-1 font-mono text-[11px] uppercase tracking-[0.16em] text-muted">
                    {small}
                  </p>
                </div>
              ))}
            </div>

            <div className="mt-8 card !p-0 overflow-hidden">
              <div className="flex items-center justify-between border-b border-border px-5 py-3.5 font-mono text-[11px] uppercase tracking-[0.18em] text-muted">
                <span>Recent supporters</span>
                <span>{completed.length} tips</span>
              </div>
              {recent.length === 0 ? (
                <div className="px-6 py-14 text-center">
                  <div className="text-3xl">🙌</div>
                  <p className="body-muted mx-auto mt-3 max-w-sm">
                    No tips yet — be the first to fill {creator.display_name}&apos;s jar.
                  </p>
                  <Link href={`/tip/${creator.slug}`} className="btn-primary mt-6">
                    Send the first tip →
                  </Link>
                </div>
              ) : (
                recent.map((tip) => (
                  <div
                    key={tip.id}
                    className="flex items-start gap-3.5 border-b border-border/60 px-5 py-4 last:border-0"
                  >
                    <div className="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-mint/15 text-sm font-bold text-green">
                      {(tip.tipper_name || "A").charAt(0).toUpperCase()}
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-2">
                        <span className="truncate font-semibold text-ink">
                          {maskName(tip.tipper_name)}
                        </span>
                        <span className="font-mono text-[11px] text-muted">
                          {relative(tip.created_at)}
                        </span>
                        <span className="ml-auto font-display text-base font-bold text-green">
                          {rand(parseFloat(tip.amount) || 0)}
                        </span>
                      </div>
                      {tip.message && (
                        <p className="body-muted mt-1 line-clamp-3 text-sm">
                          &ldquo;{tip.message}&rdquo;
                        </p>
                      )}
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
