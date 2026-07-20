import Link from "next/link";
import { api } from "@/lib/api";
import { CreatorCard } from "@/components/CreatorCard";
import type { Creator } from "@/types";

export const metadata = {
  title: "Discover creators — Tipping Jar",
  description:
    "Browse creators across art, music, code, writing and more. Drop a tip — it takes 30 seconds and means the world to them.",
};

async function getCreators(): Promise<Creator[]> {
  try {
    return await api.listCreators();
  } catch {
    return [];
  }
}

export default async function CreatorsPage() {
  const creators = await getCreators();

  return (
    <>
      {/* Hero */}
      <section className="relative overflow-hidden border-b border-border">
        <div className="absolute inset-0 -z-10 bg-brand-gradient opacity-[0.10]" />
        <div className="container-content py-20 text-center md:py-28">
          <span className="inline-block rounded-full border border-border bg-card px-4 py-1.5 text-sm text-teal">
            Discover creators
          </span>
          <h1 className="heading-xl mx-auto mt-6 max-w-2xl">
            Support the people{" "}
            <span className="bg-brand-gradient bg-clip-text text-transparent">
              who make your day
            </span>
          </h1>
          <p className="body-muted mx-auto mt-6 max-w-xl text-lg">
            Browse creators across art, music, code, writing, and more. Drop a
            tip — it takes 30 seconds and means the world to them.
          </p>
        </div>
      </section>

      {/* Stats bar */}
      <section className="border-b border-border">
        <div className="container-content flex flex-wrap items-center justify-center gap-x-16 gap-y-6 py-10 text-center">
          <div>
            <div className="text-3xl font-extrabold tracking-tight text-teal">
              {creators.length}+
            </div>
            <div className="mt-1 text-sm text-muted">Active creators</div>
          </div>
          <div>
            <div className="text-3xl font-extrabold tracking-tight text-teal">
              R3.6M+
            </div>
            <div className="mt-1 text-sm text-muted">Tips sent</div>
          </div>
          <div>
            <div className="text-3xl font-extrabold tracking-tight">🇿🇦</div>
            <div className="mt-1 text-sm text-muted">South Africa</div>
          </div>
        </div>
      </section>

      {/* Grid */}
      <section className="container-content py-16">
        <div className="flex flex-wrap items-end justify-between gap-4">
          <h2 className="text-2xl font-bold tracking-tight">All creators</h2>
          <span className="rounded-full border border-border bg-card px-3 py-1 text-xs font-semibold text-muted">
            {creators.length} creators
          </span>
        </div>

        {creators.length === 0 ? (
          <div className="card mt-10 py-16 text-center">
            <div className="text-4xl">🔍</div>
            <h3 className="mt-4 text-lg font-semibold text-white">
              No creators yet
            </h3>
            <p className="body-muted mx-auto mt-2 max-w-sm">
              Check back soon — creators are joining every day. Want to be the
              first?
            </p>
            <Link href="/register" className="btn-primary mt-6">
              Create your page →
            </Link>
          </div>
        ) : (
          <div className="mt-10 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {creators.map((c) => (
              <CreatorCard key={c.id} creator={c} />
            ))}
          </div>
        )}
      </section>

      {/* CTA */}
      <section className="container-content pb-24">
        <div className="rounded-3xl bg-brand-gradient p-12 text-center md:p-16">
          <h2 className="heading-xl">Are you a creator?</h2>
          <p className="mx-auto mt-4 max-w-lg text-white/85">
            Set up your tip page in 60 seconds. Completely free.
          </p>
          <Link
            href="/register"
            className="mt-8 inline-flex rounded-full bg-white px-8 py-3 font-semibold text-primary transition hover:opacity-90"
          >
            Create your page →
          </Link>
          <p className="mt-4 text-xs text-white/50">
            No credit card · Free forever
          </p>
        </div>
      </section>
    </>
  );
}
