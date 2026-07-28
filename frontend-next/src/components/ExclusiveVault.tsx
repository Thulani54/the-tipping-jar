"use client";

// Supporter-only content vault on the public creator page. Fans unlock it with
// the email they tipped with this month; the tips service verifies server-side.

import { useState } from "react";
import Link from "next/link";
import { api } from "@/lib/api";
import type { ExclusivePost } from "@/types";

export function ExclusiveVault({ slug, count, creatorName }: { slug: string; count: number; creatorName: string }) {
  const [email, setEmail] = useState("");
  const [posts, setPosts] = useState<ExclusivePost[] | null>(null);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  if (count === 0) return null;

  async function unlock() {
    if (!email.includes("@")) { setErr("Enter the email you tipped with."); return; }
    setBusy(true);
    setErr(null);
    try {
      setPosts(await api.unlockExclusive(slug, email.trim()));
    } catch (e) {
      setErr(e instanceof Error ? e.message : "Could not unlock.");
    } finally {
      setBusy(false);
    }
  }

  if (posts) {
    return (
      <div className="mt-8 card !p-0 overflow-hidden">
        <div className="flex items-center justify-between border-b border-border bg-gold/10 px-5 py-3.5">
          <span className="font-mono text-[11px] uppercase tracking-[0.18em] text-ink">
            🔓 Exclusive · unlocked
          </span>
          <span className="font-mono text-[11px] text-muted">{posts.length} post{posts.length === 1 ? "" : "s"}</span>
        </div>
        {posts.map((p) => (
          <article key={p.id} className="border-b border-border/60 px-5 py-5 last:border-0">
            <h3 className="font-display text-lg font-bold text-ink">{p.title}</h3>
            {p.image_url && (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={p.image_url} alt="" className="mt-3 max-h-96 w-full rounded-xl object-cover" />
            )}
            {p.body && <p className="body-muted mt-3 whitespace-pre-wrap">{p.body}</p>}
            <p className="mt-3 font-mono text-[11px] text-muted">
              {new Date(p.created_at).toLocaleDateString("en-ZA", { day: "numeric", month: "short", year: "numeric" })}
            </p>
          </article>
        ))}
      </div>
    );
  }

  return (
    <div className="mt-8 card relative overflow-hidden !border-gold/40">
      <span aria-hidden className="pointer-events-none absolute -right-6 -top-6 text-8xl opacity-10">🔒</span>
      <p className="font-mono text-[11px] uppercase tracking-[0.18em] text-gold">Supporters only</p>
      <h3 className="mt-2 font-display text-xl font-bold text-ink">
        {count} exclusive post{count === 1 ? "" : "s"} from {creatorName}
      </h3>
      <p className="body-muted mt-1.5">
        Tip R10 or more this month (with your email) and the vault opens for you.
      </p>
      <div className="mt-4 flex flex-col gap-2 sm:flex-row">
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && unlock()}
          placeholder="Email you tipped with"
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
    </div>
  );
}
