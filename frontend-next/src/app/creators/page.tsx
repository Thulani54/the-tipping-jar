"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { PageHero, PageCta } from "@/components/PageHero";
import { Aurora } from "@/components/Aurora";
import { Reveal } from "@/components/Reveal";
import { api } from "@/lib/api";

// The public creator directory is intentionally hidden while we're in
// private beta — creators still receive tips through their direct link
// (tippingjar.co.za/creator/<slug>) but there's no browse-index yet.
// This page replaces the old grid with a warm 'coming soon' + waitlist,
// so link-shares from Nav / marketing pages still land somewhere useful.

const WHY = [
  {
    icon: "bi-shield-check",
    title: "Every creator vetted",
    body: "When the directory opens, every listed creator will be a verified account — ID + proof of bank on file. Fans won't see half-built pages here.",
  },
  {
    icon: "bi-sliders",
    title: "Filter by what matters",
    body: "Search by category, city, and audience size. Pin the ones you follow. See who's climbing.",
  },
  {
    icon: "bi-lightning-charge-fill",
    title: "Discover live campaigns",
    body: "See the jars filling right now — new mic, tour fund, event weekend — and back the goal that speaks to you.",
  },
];

export default function CreatorsComingSoonPage() {
  const [email, setEmail] = useState("");
  const [role, setRole] = useState<"fan" | "creator">("fan");
  const [status, setStatus] = useState<"idle" | "sending" | "sent" | "error">("idle");
  const [note, setNote] = useState<string | null>(null);
  const [live, setLive] = useState<{ creators: number; tipsCount: number } | null>(null);

  // Honest "coming soon" numbers — pulled from the same public endpoints
  // the landing page uses, so this page grows on its own as the platform
  // grows. Falls back to '—' cleanly when the API's unreachable.
  useEffect(() => {
    let alive = true;
    Promise.all([
      api.listCreators().catch(() => []),
      api.listTips().catch(() => []),
    ]).then(([cs, ts]) => {
      if (!alive) return;
      setLive({
        creators: cs.length,
        tipsCount: ts.filter((t) => t.status === "completed").length,
      });
    });
    return () => { alive = false; };
  }, []);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!email.includes("@")) {
      setNote("Please enter a valid email address.");
      return;
    }
    setStatus("sending");
    setNote(null);
    try {
      // Route through the existing contact endpoint — same inbox, tagged
      // 'waitlist' so we can filter later.
      await api.contact({
        name: role === "creator" ? "Creator waitlist" : "Fan waitlist",
        email: email.trim(),
        subject: `Creator directory waitlist (${role})`,
        message: `Sign me up for the creator-directory waitlist. Role: ${role}. Email: ${email.trim()}.`,
      });
      setStatus("sent");
    } catch (err) {
      setStatus("error");
      setNote(err instanceof Error ? err.message : "Could not save your address. Try again in a moment.");
    }
  }

  return (
    <>
      <PageHero
        eyebrow="Private beta"
        title={
          <>
            The creator directory is{" "}
            <span className="relative whitespace-nowrap !text-mint">coming soon</span>.
          </>
        }
        sub="We're keeping browse in private beta while the first cohort of vetted creators comes online. In the meantime, tips are already flowing — creators share their link directly, fans tap and support."
      />

      {/* Waitlist card */}
      <section className="relative overflow-hidden bg-white">
        <Aurora />
        <div className="container-content relative py-14 md:py-20">
          <Reveal className="mx-auto max-w-2xl">
            <div className="glass-card p-6 md:p-8">
              <div className="flex items-center gap-2">
                <span className="grid h-9 w-9 place-items-center rounded-full bg-mint text-navy">
                  <i className="bi bi-envelope-heart-fill" />
                </span>
                <h2 className="font-display text-xl font-extrabold text-ink">
                  Get an email when the directory opens
                </h2>
              </div>
              <p className="body-muted mt-2 text-sm">
                No newsletter, no spam. One email when browsing goes live — then we stop.
              </p>

              {status === "sent" ? (
                <div className="mt-6 rounded-2xl border border-mint/40 bg-mint/10 p-5">
                  <p className="flex items-center gap-2 font-display text-lg font-bold text-ink">
                    <i className="bi bi-check-circle-fill text-green" /> You&apos;re on the list.
                  </p>
                  <p className="body-muted mt-2 text-sm">
                    We&apos;ll email <span className="font-mono text-ink">{email}</span> the moment the directory opens. Meanwhile, start your own jar or share your favourite creator&apos;s link.
                  </p>
                </div>
              ) : (
                <form onSubmit={submit} className="mt-6 space-y-4">
                  <div className="inline-flex rounded-full border border-border bg-white p-1.5 shadow-soft">
                    {(["fan", "creator"] as const).map((r) => (
                      <button
                        key={r}
                        type="button"
                        onClick={() => setRole(r)}
                        className={`rounded-full px-5 py-1.5 text-xs font-semibold uppercase tracking-wide transition ${
                          role === r ? "bg-primary text-white shadow-soft" : "text-muted hover:text-ink"
                        }`}
                      >
                        {r === "fan" ? "I'm a fan" : "I'm a creator"}
                      </button>
                    ))}
                  </div>
                  <div className="flex flex-col gap-3 sm:flex-row">
                    <input
                      type="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="you@example.com"
                      className="w-full rounded-full border border-border bg-white px-5 py-3 text-sm text-ink placeholder:text-muted focus:border-teal focus:outline-none focus:ring-2 focus:ring-teal/30"
                      required
                    />
                    <button
                      type="submit"
                      disabled={status === "sending"}
                      className="btn-primary shrink-0 !px-6 disabled:opacity-50"
                    >
                      {status === "sending" ? "Adding you…" : "Notify me →"}
                    </button>
                  </div>
                  {note && (
                    <p className={`text-xs ${status === "error" ? "text-red-500" : "text-muted"}`}>
                      {note}
                    </p>
                  )}
                </form>
              )}
            </div>
          </Reveal>

          {/* Meanwhile — real next steps so the page isn't a dead-end */}
          <div className="stagger mt-10 grid gap-4 sm:grid-cols-2">
            <div className="glass-card group flex items-start gap-4 p-5">
              <span className="glass-tile h-11 w-11 text-lg"><i className="bi bi-rocket-takeoff-fill" /></span>
              <div className="min-w-0 flex-1">
                <p className="font-display font-bold text-ink">In the meantime — start your own jar</p>
                <p className="body-muted mt-1 text-sm">Fans still find you through your direct link. Your page opens for tips the moment your profile is complete.</p>
                <Link href="/register" className="mt-3 inline-flex items-center gap-1 text-sm font-semibold text-green hover:underline">
                  Create your page <i className="bi bi-arrow-right" />
                </Link>
              </div>
            </div>
            <div className="glass-card group flex items-start gap-4 p-5">
              <span className="glass-tile h-11 w-11 text-lg"><i className="bi bi-heart-fill" /></span>
              <div className="min-w-0 flex-1">
                <p className="font-display font-bold text-ink">Have a creator in mind?</p>
                <p className="body-muted mt-1 text-sm">Their tip link works today. Ask them for it, or check their bio: tippingjar.co.za/creator/&lt;name&gt;.</p>
                <Link href="/how-it-works" className="mt-3 inline-flex items-center gap-1 text-sm font-semibold text-green hover:underline">
                  See how a tip flows <i className="bi bi-arrow-right" />
                </Link>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* What the directory will feel like */}
      <section className="relative overflow-hidden border-y border-border bg-[#f3f9f5]">
        <Aurora />
        <div className="container-content relative py-16 md:py-20">
          <Reveal className="mx-auto max-w-xl text-center">
            <p className="eyebrow">What&apos;s coming</p>
            <h2 className="heading-xl mt-3 text-3xl md:text-4xl">A directory worth browsing</h2>
            <p className="body-muted mx-auto mt-3 max-w-md">
              Not a list of anyone who signed up — a curated, filterable view of verified South African creators.
            </p>
          </Reveal>
          <div className="stagger mt-12 grid gap-6 md:grid-cols-3">
            {WHY.map((w) => (
              <div key={w.title} className="glass-card group pop-in h-full p-6">
                <span className="glass-tile h-12 w-12 text-xl"><i className={`bi ${w.icon}`} /></span>
                <h3 className="mt-5 font-display text-lg font-bold text-ink">{w.title}</h3>
                <p className="body-muted mt-2 text-sm leading-relaxed">{w.body}</p>
              </div>
            ))}
          </div>

          {/* Live counts — honest social proof */}
          {live && live.creators > 0 && (
            <p className="mt-10 text-center font-mono text-xs uppercase tracking-[0.16em] text-muted">
              <span className="font-semibold text-ink">{live.creators}</span> creators onboarding
              <span className="mx-2">·</span>
              <span className="font-semibold text-ink">{live.tipsCount}</span> tips in the current feed
            </p>
          )}
        </div>
      </section>

      <PageCta title="Don't wait for browse — start now." sub="Your tip page and direct link are live from day one. Share it anywhere your audience already is.">
        <Link
          href="/register"
          className="inline-flex rounded-full bg-white px-8 py-3.5 font-semibold !text-primary shadow-lift transition hover:-translate-y-0.5"
        >
          Create your jar →
        </Link>
        <Link
          href="/how-it-works"
          className="inline-flex rounded-full border border-white/25 px-8 py-3.5 font-semibold transition hover:border-white/60 hover:bg-white/10"
        >
          How it works
        </Link>
      </PageCta>
    </>
  );
}
