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

function SocialLinks({ raw }: { raw: string }) {
  let links: Record<string, string> = {};
  try { links = raw ? JSON.parse(raw) : {}; } catch { return null; }
  const items = [
    { key: "instagram", icon: "bi-instagram", prefix: "https://instagram.com/" },
    { key: "twitter", icon: "bi-twitter-x", prefix: "https://x.com/" },
    { key: "youtube", icon: "bi-youtube", prefix: "https://youtube.com/@" },
    { key: "website", icon: "bi-globe2", prefix: "" },
  ].filter((i) => links[i.key]);
  if (items.length === 0) return null;
  return (
    <div className="mt-4 flex items-center gap-3">
      {items.map((i) => {
        const v = links[i.key].trim();
        const href = v.startsWith("http") ? v : `${i.prefix}${v.replace(/^@/, "")}`;
        return (
          <a key={i.key} href={href} target="_blank" rel="noreferrer"
             className="grid h-10 w-10 place-items-center rounded-full border border-border bg-white text-muted transition hover:border-green hover:text-green"
             aria-label={i.key}>
            <i className={`bi ${i.icon}`} />
          </a>
        );
      })}
    </div>
  );
}

function topSupporter(tips: Tip[]): { name: string; total: number } | null {
  const sums = new Map<string, number>();
  for (const t of tips) {
    const key = (t.tipper_email || t.tipper_name || "anon").toLowerCase();
    sums.set(key, (sums.get(key) ?? 0) + (parseFloat(t.amount) || 0));
  }
  let best: { name: string; total: number } | null = null;
  for (const t of tips) {
    const key = (t.tipper_email || t.tipper_name || "anon").toLowerCase();
    const total = sums.get(key) ?? 0;
    if (!best || total > best.total) best = { name: t.tipper_name, total };
  }
  return best && best.total > 0 ? best : null;
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
        <div className="mx-auto grid h-16 w-16 place-items-center rounded-full bg-white text-3xl text-teal shadow-soft">
          <i className="bi bi-piggy-bank-fill" />
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
      {/* Cover — the creator's cover image, or solid navy with a coin motif */}
      <div className="relative h-44 w-full overflow-hidden bg-navy md:h-56">
        {creator.cover_url ? (
          <>
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={creator.cover_url} alt="" className="h-full w-full object-cover" />
            <span aria-hidden className="absolute inset-0 bg-navy/30" />
          </>
        ) : (
          <>
            <span aria-hidden className="absolute left-[10%] top-8 h-10 w-10 rounded-full bg-gold/50" />
            <span aria-hidden className="absolute right-[10%] top-10 h-16 w-16 rounded-full bg-mint/20" />
            <span aria-hidden className="absolute right-[18%] top-20 h-7 w-7 rounded-full bg-gold/60" />
          </>
        )}
      </div>

      <div className="container-content">
        {/* Header — white avatar centred ON the navy header, info stacked below.
            relative z-10 so the avatar paints ABOVE the (positioned) cover. */}
        <div className="relative z-10 -mt-24 flex flex-col items-center text-center md:-mt-28">
          {creator.avatar_url ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={creator.avatar_url}
              alt={creator.display_name}
              className="h-32 w-32 shrink-0 rounded-[36px] object-cover shadow-lift ring-4 ring-white"
            />
          ) : (
            <div className="grid h-32 w-32 shrink-0 place-items-center rounded-[36px] bg-white text-4xl font-extrabold text-primary shadow-lift ring-1 ring-border">
              {initials(creator.display_name)}
            </div>
          )}
          <h1 className="mt-5 font-display text-3xl font-extrabold tracking-tight text-ink md:text-4xl">
            {creator.display_name}
          </h1>
          <p className="mt-1 font-mono text-sm text-muted">@{creator.slug}</p>
          {creator.category && (
            <span className="mt-3 inline-block rounded-full bg-mint/15 px-3 py-1 text-xs font-semibold text-green">
              {creator.category}
            </span>
          )}
          {creator.tagline && (
            <p className="body-muted mx-auto mt-5 max-w-2xl text-lg">{creator.tagline}</p>
          )}
          <SocialLinks raw={creator.links} />
        </div>

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
                <i className="bi bi-heart-fill" /> Tip {creator.display_name.split(" ")[0]}
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

            {(() => {
              const top = topSupporter(completed);
              return top ? (
                <div className="mt-4 flex items-center gap-3 rounded-2xl border border-gold/30 bg-gold/10 px-5 py-3.5">
                  <span className="text-2xl">🥇</span>
                  <div>
                    <p className="text-sm font-semibold text-ink">
                      Top supporter: {maskName(top.name)} · {rand(top.total)}
                    </p>
                    <p className="text-xs text-muted">Legend status. Thank you!</p>
                  </div>
                </div>
              ) : null;
            })()}

            <div className="mt-8 card !p-0 overflow-hidden">
              <div className="flex items-center justify-between border-b border-border px-5 py-3.5 font-mono text-[11px] uppercase tracking-[0.18em] text-muted">
                <span>Recent supporters</span>
                <span>{completed.length} tips</span>
              </div>
              {recent.length === 0 ? (
                <div className="px-6 py-14 text-center">
                  <div className="text-3xl text-teal"><i className="bi bi-emoji-smile-fill" /></div>
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
