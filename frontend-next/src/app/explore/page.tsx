import Link from "next/link";
import { api } from "@/lib/api";
import { CreatorCard } from "@/components/CreatorCard";
import type { Creator } from "@/types";

export const metadata = {
  title: "Explore creators — The Tipping Jar",
  description: "Support creators you love. Drop a tip — it makes their day.",
};

async function getCreators(): Promise<Creator[]> {
  try {
    return await api.listCreators();
  } catch {
    return [];
  }
}

export default async function ExplorePage() {
  const creators = await getCreators();

  return (
    <>
      {/* Hero */}
      <section className="relative overflow-hidden border-b border-border">
        <div className="absolute inset-0 -z-10 bg-brand-gradient opacity-[0.12]" />
        <div className="container-content py-20 text-center md:py-24">
          <h1 className="heading-xl mx-auto max-w-2xl">Support creators you love</h1>
          <p className="body-muted mx-auto mt-5 max-w-lg text-lg">
            Drop a tip — it makes their day.
          </p>
          <div className="mt-8 flex justify-center">
            <Link href="/register" className="btn-primary text-base">
              Become a creator
            </Link>
          </div>
        </div>
      </section>

      {/* Creators grid */}
      <section className="container-content py-16 md:py-20">
        {creators.length === 0 ? (
          <p className="py-16 text-center text-muted">
            No creators yet — be the first!
          </p>
        ) : (
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {creators.map((c) => (
              <CreatorCard key={c.id} creator={c} />
            ))}
          </div>
        )}
      </section>
    </>
  );
}
