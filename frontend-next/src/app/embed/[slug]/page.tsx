import { api } from "@/lib/api";
import { JarMeter } from "@/components/JarMeter";
import type { Creator, Tip } from "@/types";

// Embeddable jar widget — creators drop this in an <iframe> on their own site:
//   <iframe src="https://www.tippingjar.co.za/embed/<slug>" width="320" height="440" />
// Rendered bare (SiteFrame skips nav/footer for /embed).

export const revalidate = 60;

async function load(slug: string): Promise<{ creator: Creator | null; raised: number }> {
  try {
    const creator = await api.getCreator(slug);
    let raised = 0;
    try {
      const tips: Tip[] = await api.tipsForCreator(creator.id);
      raised = tips
        .filter((t) => t.status === "completed")
        .reduce((s, t) => s + (parseFloat(t.amount) || 0), 0);
    } catch {
      /* jar shows zero */
    }
    return { creator, raised };
  } catch {
    return { creator: null, raised: 0 };
  }
}

export default async function EmbedPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const { creator, raised } = await load(slug);

  if (!creator) {
    return (
      <div className="grid min-h-screen place-items-center bg-white p-6 text-center">
        <p className="text-sm text-muted">Creator not found.</p>
      </div>
    );
  }

  const goal = creator.tip_goal ? parseFloat(creator.tip_goal) : 0;
  const pct = goal > 0 ? Math.min(100, Math.round((raised / goal) * 100)) : 0;
  const jarPct = goal > 0 ? Math.max(pct, 4) : raised > 0 ? 62 : 8;
  const rand = (n: number) => `R${Math.round(n).toLocaleString("en-ZA")}`;

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-white p-4">
      <p className="font-mono text-[10px] uppercase tracking-[0.2em] text-green">
        Tipping Jar
      </p>
      <p className="mt-1 text-center text-base font-bold text-ink">
        {creator.display_name}
      </p>
      <div className="mt-2 scale-90">
        <JarMeter
          raised={rand(raised)}
          goal={goal > 0 ? rand(goal) : ""}
          pct={jarPct}
          label={goal > 0 ? "of goal" : "raised so far"}
        />
      </div>
      <a
        href={`https://www.tippingjar.co.za/tip/${creator.slug}`}
        target="_blank"
        rel="noreferrer"
        className="btn-primary mt-3 w-full max-w-[240px] !py-2.5 text-sm"
      >
        💚 Tip {creator.display_name.split(" ")[0]}
      </a>
      <a
        href={`https://www.tippingjar.co.za/creator/${creator.slug}`}
        target="_blank"
        rel="noreferrer"
        className="mt-2 text-[11px] text-muted hover:text-ink"
      >
        tippingjar.co.za
      </a>
    </div>
  );
}
