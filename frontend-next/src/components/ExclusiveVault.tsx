"use client";

// Supporter-only media hub. Fans unlock with the email they tipped or
// subscribed with; the creators+tips services verify server-side. Renders
// posts, videos (YouTube/Vimeo/direct), audio players and image galleries.

import { useState } from "react";
import Link from "next/link";
import { api } from "@/lib/api";
import type { ExclusivePost, SupportTier } from "@/types";

// Turn a YouTube / Vimeo / direct URL into an embed source.
function toEmbed(url: string): { kind: "iframe" | "video" | "audio" | "none"; src: string } {
  const u = url.trim();
  if (!u) return { kind: "none", src: "" };
  const yt = u.match(/(?:youtube\.com\/(?:watch\?v=|embed\/)|youtu\.be\/)([\w-]{6,})/);
  if (yt) return { kind: "iframe", src: `https://www.youtube.com/embed/${yt[1]}` };
  const vm = u.match(/vimeo\.com\/(?:video\/)?(\d+)/);
  if (vm) return { kind: "iframe", src: `https://player.vimeo.com/video/${vm[1]}` };
  if (/\.(mp4|webm|mov)($|\?)/i.test(u)) return { kind: "video", src: u };
  if (/\.(mp3|wav|ogg|m4a)($|\?)/i.test(u)) return { kind: "audio", src: u };
  return { kind: "none", src: u };
}

function PostBody({ post }: { post: ExclusivePost }) {
  if (post.kind === "video" && post.media_url) {
    const e = toEmbed(post.media_url);
    if (e.kind === "iframe")
      return (
        <div className="mt-3 aspect-video overflow-hidden rounded-xl bg-black">
          <iframe src={e.src} className="h-full w-full" allow="autoplay; encrypted-media; picture-in-picture" allowFullScreen title={post.title} />
        </div>
      );
    if (e.kind === "video")
      return <video src={e.src} controls className="mt-3 w-full rounded-xl bg-black" />;
    return <a className="mt-3 inline-block text-sm text-teal underline" href={e.src} target="_blank" rel="noreferrer">Watch video →</a>;
  }
  if (post.kind === "audio" && post.media_url) {
    return <audio src={post.media_url} controls className="mt-3 w-full" />;
  }
  return (
    <>
      {post.image_url && (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={post.image_url} alt="" className="mt-3 max-h-96 w-full rounded-xl object-cover" />
      )}
      {post.body && <p className="body-muted mt-3 whitespace-pre-wrap">{post.body}</p>}
    </>
  );
}

const KIND_LABEL: Record<string, { emoji: string; label: string }> = {
  post:    { emoji: "📝", label: "Post" },
  video:   { emoji: "🎥", label: "Video" },
  audio:   { emoji: "🎧", label: "Audio" },
  gallery: { emoji: "🖼", label: "Gallery" },
};

export function ExclusiveVault({
  slug,
  count,
  creatorName,
  tiers,
}: {
  slug: string;
  count: number;
  creatorName: string;
  tiers?: SupportTier[];
}) {
  const [email, setEmail] = useState("");
  const [posts, setPosts] = useState<ExclusivePost[] | null>(null);
  const [tierIds, setTierIds] = useState<Set<string>>(new Set());
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const [subOpen, setSubOpen] = useState(false);
  const [subTier, setSubTier] = useState<string | null>(null);
  const [subName, setSubName] = useState("");
  const [subNote, setSubNote] = useState<string | null>(null);

  const hasVault = count > 0 || (tiers && tiers.length > 0);
  if (!hasVault) return null;

  async function unlock() {
    if (!email.includes("@")) { setErr("Enter the email you used."); return; }
    setBusy(true);
    setErr(null);
    try {
      const r = await api.unlockExclusive(slug, email.trim());
      setPosts(r.posts);
      setTierIds(new Set(r.grants.tier_ids));
    } catch (e) {
      setErr(e instanceof Error ? e.message : "Could not unlock.");
    } finally {
      setBusy(false);
    }
  }

  async function subscribe() {
    if (!subTier || !email.includes("@")) { setSubNote("Enter your email and pick a tier."); return; }
    setSubNote(null);
    try {
      await api.subscribeToTier(slug, { tier_id: subTier, email: email.trim(), name: subName || undefined });
      setSubNote("Subscribed! Now unlock with the same email.");
      setSubOpen(false);
      await unlock();
    } catch (e) {
      setSubNote(e instanceof Error ? e.message : "Could not subscribe.");
    }
  }

  if (posts) {
    return (
      <div className="mt-8 space-y-3">
        <div className="flex items-center justify-between rounded-2xl border border-gold/30 bg-gold/10 px-5 py-3">
          <p className="font-mono text-[11px] uppercase tracking-[0.18em] text-ink">
            🔓 Vault unlocked · {posts.length} post{posts.length === 1 ? "" : "s"}
          </p>
          <p className="font-mono text-[11px] text-muted">
            {tierIds.size > 0 && `subscriber · ${tierIds.size} tier${tierIds.size === 1 ? "" : "s"} · `}
            <span className="text-green">{email}</span>
          </p>
        </div>
        {posts.map((p) => {
          const meta = KIND_LABEL[p.kind] ?? KIND_LABEL.post;
          const locked = !p.body && !p.media_url && p.access !== "public";
          const tierName = tiers?.find((t) => t.id === p.tier_id)?.name;
          return (
            <article key={p.id} className={`card !p-5 ${locked ? "opacity-70" : ""}`}>
              <div className="flex items-start justify-between gap-3">
                <div className="min-w-0">
                  <p className="text-[11px] font-mono uppercase tracking-[0.14em] text-muted">
                    {meta.emoji} {meta.label}
                    {p.access === "subscription" && tierName && <> · Subscribers of {tierName}</>}
                    {p.access === "monthly_tip" && p.min_tip && Number(p.min_tip) > 10 && <> · min tip R{Number(p.min_tip)}</>}
                  </p>
                  <h3 className="mt-1 font-display text-lg font-bold text-ink">{p.title}</h3>
                </div>
                {locked && (
                  <span className="shrink-0 rounded-full bg-red-500/10 px-2.5 py-1 text-[11px] font-semibold text-red-500">
                    🔒 Locked
                  </span>
                )}
              </div>
              {locked ? (
                <p className="mt-2 text-sm text-muted">
                  {p.access === "subscription"
                    ? tierName
                      ? `Subscribe to "${tierName}" to unlock this.`
                      : "Subscribe to unlock this."
                    : `Tip R${p.min_tip || 10}+ this month to unlock this.`}
                </p>
              ) : (
                <PostBody post={p} />
              )}
              <p className="mt-3 font-mono text-[11px] text-muted">
                {new Date(p.created_at).toLocaleDateString("en-ZA", { day: "numeric", month: "short", year: "numeric" })}
              </p>
            </article>
          );
        })}
        {tiers && tiers.length > 0 && (
          <button onClick={() => setSubOpen((v) => !v)} className="text-xs text-muted underline hover:text-ink">
            View & manage subscriptions
          </button>
        )}
        {subOpen && (
          <SubscribeForm tiers={tiers ?? []} subTier={subTier} setSubTier={setSubTier} subName={subName} setSubName={setSubName} subscribe={subscribe} note={subNote} />
        )}
      </div>
    );
  }

  return (
    <div className="mt-8 card relative overflow-hidden !border-gold/40">
      <span aria-hidden className="pointer-events-none absolute -right-6 -top-6 text-8xl opacity-10">🔒</span>
      <p className="font-mono text-[11px] uppercase tracking-[0.18em] text-gold">Supporters only</p>
      <h3 className="mt-2 font-display text-xl font-bold text-ink">
        {count > 0
          ? `${count} exclusive post${count === 1 ? "" : "s"} from ${creatorName}`
          : `Support ${creatorName} for perks`}
      </h3>
      <p className="body-muted mt-1.5">
        Tip R10+ this month {tiers && tiers.length > 0 ? "or subscribe to a tier " : ""}
        to unlock videos, audio and behind-the-scenes posts.
      </p>
      <div className="mt-4 flex flex-col gap-2 sm:flex-row">
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && unlock()}
          placeholder="Email you tipped/subscribed with"
          className="w-full rounded-full border border-border bg-white px-4 py-2.5 text-sm text-ink focus:border-primary/40 focus:outline-none sm:max-w-xs"
        />
        <button onClick={unlock} disabled={busy} className="btn-primary !px-6 !py-2.5 text-sm disabled:opacity-50">
          {busy ? "Checking…" : "Unlock"}
        </button>
        <Link href={`/tip/${slug}`} className="btn-ghost !px-6 !py-2.5 text-sm">
          Tip to unlock
        </Link>
      </div>
      {err && <p className="mt-2 text-sm text-red-500">{err}</p>}

      {tiers && tiers.length > 0 && (
        <div className="mt-6 border-t border-border pt-5">
          <p className="text-xs font-semibold uppercase tracking-wide text-muted">Subscribe monthly</p>
          <div className="mt-3 grid gap-3 sm:grid-cols-2">
            {tiers.map((t) => (
              <button
                key={t.id}
                onClick={() => { setSubTier(t.id); setSubOpen(true); }}
                className={`card cursor-pointer !p-4 text-left transition hover:border-teal/60 ${subTier === t.id ? "!border-teal ring-2 ring-teal/20" : ""}`}
              >
                <div className="flex items-baseline justify-between">
                  <p className="font-medium text-ink">{t.name}</p>
                  <p className="font-mono text-sm font-bold text-teal">R{Number(t.price).toFixed(0)}/mo</p>
                </div>
                {t.description && <p className="mt-1 text-xs text-muted line-clamp-2">{t.description}</p>}
              </button>
            ))}
          </div>
          {subOpen && (
            <SubscribeForm tiers={tiers} subTier={subTier} setSubTier={setSubTier} subName={subName} setSubName={setSubName} subscribe={subscribe} note={subNote} />
          )}
        </div>
      )}
    </div>
  );
}

function SubscribeForm({
  tiers, subTier, setSubTier, subName, setSubName, subscribe, note,
}: {
  tiers: SupportTier[];
  subTier: string | null;
  setSubTier: (v: string) => void;
  subName: string;
  setSubName: (v: string) => void;
  subscribe: () => void;
  note: string | null;
}) {
  return (
    <div className="mt-4 rounded-xl border border-teal/40 bg-teal/5 p-4">
      <p className="text-sm font-semibold text-ink">Confirm your subscription</p>
      <div className="mt-2 flex flex-wrap gap-2">
        {tiers.map((t) => (
          <button
            key={t.id}
            onClick={() => setSubTier(t.id)}
            className={`rounded-full px-3 py-1.5 text-xs font-medium transition ${subTier === t.id ? "bg-primary text-white" : "border border-border text-muted hover:text-ink"}`}
          >
            {t.name} · R{Number(t.price).toFixed(0)}
          </button>
        ))}
      </div>
      <input
        value={subName}
        onChange={(e) => setSubName(e.target.value)}
        placeholder="Your name (optional)"
        className="mt-3 w-full rounded-full border border-border bg-white px-4 py-2 text-sm text-ink focus:border-primary/40 focus:outline-none"
      />
      <div className="mt-3 flex items-center gap-3">
        <button onClick={subscribe} className="btn-primary !px-5 !py-2 text-sm">Subscribe</button>
        {note && <p className="text-xs text-teal">{note}</p>}
      </div>
    </div>
  );
}
