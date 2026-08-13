import Link from "next/link";
import { api } from "@/lib/api";
import { PageHero } from "@/components/PageHero";
import { Aurora } from "@/components/Aurora";
import { Reveal } from "@/components/Reveal";
import type { BlogPost } from "@/types";

export const metadata = {
  title: "Blog — Tipping Jar",
  description: "Creator guides, product news, and the economics of tipping.",
};

const CAT_COLORS: Record<string, string> = {
  product: "#818CF8",
  industry: "#0097B2",
  company: "#FBBF24",
  "tips-tricks": "#F87171",
};

function catColor(category: string): string {
  return CAT_COLORS[category] ?? "#0097B2";
}

function catLabel(category: string): string {
  if (!category) return "General";
  return category
    .split("-")
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(" & ");
}

function formatDate(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  return d.toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}

async function getPosts(): Promise<BlogPost[]> {
  try {
    return await api.listPosts();
  } catch {
    return [];
  }
}

function Tag({ label, color }: { label: string; color: string }) {
  return (
    <span
      className="inline-block rounded-full border px-2.5 py-1 text-[11px] font-semibold"
      style={{
        color,
        borderColor: `${color}44`,
        backgroundColor: `${color}18`,
      }}
    >
      {label}
    </span>
  );
}

function Avatar({ name, color, size = 30 }: { name: string; color: string; size?: number }) {
  return (
    <span
      className="grid shrink-0 place-items-center rounded-full font-extrabold"
      style={{
        width: size,
        height: size,
        color,
        backgroundColor: `${color}22`,
        fontSize: size * 0.4,
      }}
    >
      {name ? name.charAt(0).toUpperCase() : "T"}
    </span>
  );
}

export default async function BlogPage() {
  const posts = await getPosts();
  const featured = posts[0];
  const rest = posts.slice(1);

  return (
    <>
      <PageHero
        eyebrow="Blog"
        title="Stories, tips & insights"
        sub="Creator guides, product news, and the economics of tipping."
      />

      {/* Body */}
      <section className="relative overflow-hidden bg-white">
        <Aurora />
        <div className="container-content relative py-16">
        {posts.length === 0 ? (
          <div className="mx-auto max-w-lg py-24 text-center">
            <p className="body-muted text-base">No blog posts yet. Check back soon!</p>
          </div>
        ) : (
          <div className="mx-auto max-w-5xl">
            <p className="text-xs font-bold uppercase tracking-wider text-muted">Latest</p>

            {/* Featured */}
            {featured && (
              <Reveal>
              <Link
                href={`/blog/${featured.slug}`}
                className="glass-card group mt-5 block p-8"
              >
                <div className="flex items-center justify-between">
                  <Tag label={catLabel(featured.category)} color={catColor(featured.category)} />
                  <span className="rounded-full bg-gold/15 px-3 py-1 text-[11px] font-semibold text-gold">
                    ★ Featured
                  </span>
                </div>
                <h2 className="mt-5 text-2xl font-extrabold tracking-tight text-ink md:text-3xl">
                  {featured.title}
                </h2>
                <p className="body-muted mt-3 text-[15px] leading-relaxed">{featured.excerpt}</p>
                <div className="mt-6 border-t border-border pt-4">
                  <div className="flex flex-wrap items-center gap-x-3 gap-y-2 text-xs text-muted">
                    <Avatar name={featured.author_name} color={catColor(featured.category)} />
                    <span className="font-semibold text-ink">{featured.author_name}</span>
                    <span>{formatDate(featured.created_at)}</span>
                    <span>·</span>
                    <span>{featured.read_time}</span>
                    <span className="ml-auto font-semibold text-teal group-hover:underline">
                      Read more →
                    </span>
                  </div>
                </div>
              </Link>
              </Reveal>
            )}

            {/* More articles */}
            {rest.length > 0 && (
              <>
                <div className="my-12 h-px bg-border" />
                <p className="text-xs font-bold uppercase tracking-wider text-muted">
                  More articles
                </p>
                <div className="mt-5 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
                  {rest.map((post, i) => {
                    const color = catColor(post.category);
                    return (
                      <Reveal key={post.id} delay={(i % 3) * 80}>
                      <Link
                        href={`/blog/${post.slug}`}
                        className="glass-card flex h-full flex-col p-6"
                      >
                        <div className="flex items-center justify-between">
                          <Tag label={catLabel(post.category)} color={color} />
                          <span className="text-[11px] text-muted">{post.read_time}</span>
                        </div>
                        <h3 className="mt-4 text-[15px] font-bold leading-snug text-ink">
                          {post.title}
                        </h3>
                        <p className="body-muted mt-2 line-clamp-3 text-[13px]">{post.excerpt}</p>
                        <div className="mt-5 flex items-center gap-2 text-[11px] text-muted">
                          <Avatar name={post.author_name} color={color} size={26} />
                          <span className="truncate font-medium">{post.author_name}</span>
                          <span className="ml-auto shrink-0">{formatDate(post.created_at)}</span>
                        </div>
                      </Link>
                      </Reveal>
                    );
                  })}
                </div>
              </>
            )}
          </div>
        )}
        </div>
      </section>
    </>
  );
}
