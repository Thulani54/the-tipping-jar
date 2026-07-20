import Link from "next/link";
import sanitizeHtml from "sanitize-html";
import { api } from "@/lib/api";
import type { BlogPost } from "@/types";

// Blog content is HTML authored in a rich-text editor. It is rendered via
// dangerouslySetInnerHTML, so it MUST be sanitized against XSS first — an
// allowlist of formatting tags/attributes only, no scripts, no event handlers,
// and only http/https/mailto URLs.
const SANITIZE_OPTS: sanitizeHtml.IOptions = {
  allowedTags: [
    "h1", "h2", "h3", "h4", "p", "br", "hr", "strong", "b", "em", "i", "u",
    "a", "ul", "ol", "li", "blockquote", "code", "pre", "img", "span",
  ],
  allowedAttributes: {
    a: ["href", "title", "target", "rel"],
    img: ["src", "alt", "title"],
    span: [],
  },
  allowedSchemes: ["http", "https", "mailto"],
  allowedSchemesByTag: { img: ["http", "https"] },
  transformTags: {
    // Force safe, no-referrer external links.
    a: sanitizeHtml.simpleTransform("a", { rel: "noopener noreferrer nofollow" }),
  },
  disallowedTagsMode: "discard",
};

function cleanHtml(html: string): string {
  return sanitizeHtml(html ?? "", SANITIZE_OPTS);
}

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

export default async function BlogDetailPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;

  let post: BlogPost | null = null;
  try {
    post = await api.getPost(slug);
  } catch {
    post = null;
  }

  if (!post) {
    return (
      <section className="container-content py-32">
        <div className="mx-auto max-w-md text-center">
          <h1 className="text-2xl font-bold text-white">Post not found</h1>
          <p className="body-muted mt-3">
            The post you&apos;re looking for doesn&apos;t exist or has been removed.
          </p>
          <Link href="/blog" className="btn-primary mt-8">
            Back to Blog
          </Link>
        </div>
      </section>
    );
  }

  const color = catColor(post.category);

  return (
    <article>
      {/* Hero banner */}
      <header className="border-b border-border bg-darker">
        <div className="container-content py-16">
          <div className="mx-auto max-w-3xl">
            <Link href="/blog" className="text-sm text-muted transition hover:text-white">
              ← All posts
            </Link>
            <div className="mt-7">
              <span
                className="inline-block rounded-full border px-3 py-1.5 text-xs font-semibold"
                style={{ color, borderColor: `${color}4D`, backgroundColor: `${color}1F` }}
              >
                {catLabel(post.category)}
              </span>
            </div>
            <h1 className="mt-5 text-3xl font-extrabold leading-tight tracking-tight text-white md:text-5xl">
              {post.title}
            </h1>
            {post.excerpt && (
              <p className="body-muted mt-4 text-lg leading-relaxed">{post.excerpt}</p>
            )}
            <div className="mt-6 flex flex-wrap items-center gap-x-3 gap-y-2 text-xs text-muted">
              <span
                className="grid h-8 w-8 place-items-center rounded-full text-[13px] font-extrabold"
                style={{ color, backgroundColor: `${color}26` }}
              >
                {post.author_name ? post.author_name.charAt(0).toUpperCase() : "T"}
              </span>
              <span className="text-sm font-semibold text-white">{post.author_name}</span>
              <span>{formatDate(post.created_at)}</span>
              <span>·</span>
              <span>{post.read_time}</span>
            </div>
          </div>
        </div>
      </header>

      {/* Content */}
      <div className="bg-dark">
        <div className="container-content py-14">
          <div
            className="prose-blog mx-auto max-w-3xl"
            dangerouslySetInnerHTML={{ __html: cleanHtml(post.content) }}
          />
        </div>
      </div>

      {/* Local content styles */}
      <style>{`
        .prose-blog { color: #D1D5DB; font-size: 16px; line-height: 1.75; }
        .prose-blog h1 { color: #fff; font-size: 30px; font-weight: 800; margin: 36px 0 16px; letter-spacing: -0.5px; }
        .prose-blog h2 { color: #fff; font-size: 24px; font-weight: 700; margin: 32px 0 12px; letter-spacing: -0.3px; }
        .prose-blog h3 { color: #fff; font-size: 19px; font-weight: 700; margin: 24px 0 8px; }
        .prose-blog p { margin-bottom: 20px; }
        .prose-blog strong, .prose-blog b { color: #fff; font-weight: 700; }
        .prose-blog em, .prose-blog i { font-style: italic; }
        .prose-blog u { text-decoration: underline; }
        .prose-blog a { color: #0097B2; text-decoration: underline; }
        .prose-blog ul, .prose-blog ol { margin: 0 0 20px 24px; }
        .prose-blog ul { list-style: disc; }
        .prose-blog ol { list-style: decimal; }
        .prose-blog li { margin-bottom: 6px; }
        .prose-blog blockquote { color: #7A9088; font-style: italic; border-left: 3px solid #0097B2; padding-left: 16px; margin: 0 0 20px; }
        .prose-blog code { background: #111A16; color: #86EFAC; font-family: monospace; font-size: 13px; padding: 2px 4px; border-radius: 4px; }
        .prose-blog pre { background: #111A16; color: #86EFAC; font-family: monospace; font-size: 13px; padding: 16px; border-radius: 8px; margin-bottom: 20px; overflow-x: auto; }
        .prose-blog pre code { background: transparent; padding: 0; }
        .prose-blog hr { border: none; border-top: 1px solid #1E2E26; margin: 32px 0; }
        .prose-blog img { max-width: 100%; border-radius: 12px; margin-bottom: 20px; }
      `}</style>
    </article>
  );
}
