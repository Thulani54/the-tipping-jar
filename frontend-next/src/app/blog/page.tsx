import Link from "next/link";
import { api } from "@/lib/api";
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
      {/* Hero */}
      <section className="border-b border-border bg-dark">
        <div className="container-content py-20 text-center md:py-28">
          <span className="inline-block rounded-full border border-teal/30 bg-teal/10 px-4 py-1.5 text-xs font-semibold text-teal">
            Blog
          </span>
          <h1 className="heading-xl mx-auto mt-6 max-w-3xl">Stories, tips &amp; insights</h1>
          <p className="body-muted mx-auto mt-4 max-w-xl text-lg">
            Creator guides, product news, and the economics of tipping.
          </p>
        </div>
      </section>

      {/* Body */}
      <section className="container-content py-16">
        {posts.length === 0 ? (
          <div className="mx-auto max-w-lg py-24 text-center">
            <p className="body-muted text-base">No blog posts yet. Check back soon!</p>
          </div>
        ) : (
          <div className="mx-auto max-w-5xl">
            <p className="text-xs font-bold uppercase tracking-wider text-muted">Latest</p>

            {/* Featured */}
            {featured && (
              <Link
                href={`/blog/${featured.slug}`}
                className="group mt-5 block rounded-3xl border border-border bg-card p-8 transition hover:border-teal/40"
              >
                <div className="flex items-center justify-between">
                  <Tag label={catLabel(featured.category)} color={catColor(featured.category)} />
                  <span className="rounded-full bg-dark px-3 py-1 text-[11px] text-muted">
                    Featured
                  </span>
                </div>
                <h2 className="mt-5 text-2xl font-extrabold tracking-tight text-white md:text-3xl">
                  {featured.title}
                </h2>
                <p className="body-muted mt-3 text-[15px] leading-relaxed">{featured.excerpt}</p>
                <div className="mt-6 border-t border-border pt-4">
                  <div className="flex flex-wrap items-center gap-x-3 gap-y-2 text-xs text-muted">
                    <Avatar name={featured.author_name} color={catColor(featured.category)} />
                    <span className="font-semibold text-white">{featured.author_name}</span>
                    <span>{formatDate(featured.created_at)}</span>
                    <span>·</span>
                    <span>{featured.read_time}</span>
                    <span className="ml-auto font-semibold text-teal group-hover:underline">
                      Read more →
                    </span>
                  </div>
                </div>
              </Link>
            )}

            {/* More articles */}
            {rest.length > 0 && (
              <>
                <div className="my-12 h-px bg-border" />
                <p className="text-xs font-bold uppercase tracking-wider text-muted">
                  More articles
                </p>
                <div className="mt-5 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
                  {rest.map((post) => {
                    const color = catColor(post.category);
                    return (
                      <Link
                        key={post.id}
                        href={`/blog/${post.slug}`}
                        className="flex flex-col rounded-2xl border border-border bg-card p-6 transition hover:border-teal/40"
                      >
                        <div className="flex items-center justify-between">
                          <Tag label={catLabel(post.category)} color={color} />
                          <span className="text-[11px] text-muted">{post.read_time}</span>
                        </div>
                        <h3 className="mt-4 text-[15px] font-bold leading-snug text-white">
                          {post.title}
                        </h3>
                        <p className="body-muted mt-2 line-clamp-3 text-[13px]">{post.excerpt}</p>
                        <div className="mt-5 flex items-center gap-2 text-[11px] text-muted">
                          <Avatar name={post.author_name} color={color} size={26} />
                          <span className="truncate font-medium">{post.author_name}</span>
                          <span className="ml-auto shrink-0">{formatDate(post.created_at)}</span>
                        </div>
                      </Link>
                    );
                  })}
                </div>
              </>
            )}
          </div>
        )}
      </section>
    </>
  );
}
