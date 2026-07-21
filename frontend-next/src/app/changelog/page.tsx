export const metadata = {
  title: "Changelog — The Tipping Jar",
  description: "Every update, improvement, and fix — documented.",
};

type Badge = "New" | "Fix" | "Launch";

interface Release {
  version: string;
  date: string;
  badge: Badge;
  title: string;
  summary: string;
  items: string[];
}

const BADGE_CLASSES: Record<Badge, { text: string; dot: string; chip: string }> = {
  New: {
    text: "text-teal",
    dot: "bg-teal",
    chip: "border-teal/30 bg-teal/10 text-teal",
  },
  Fix: {
    text: "text-[#FBBF24]",
    dot: "bg-[#FBBF24]",
    chip: "border-[#FBBF24]/30 bg-[#FBBF24]/10 text-[#FBBF24]",
  },
  Launch: {
    text: "text-[#818CF8]",
    dot: "bg-[#818CF8]",
    chip: "border-[#818CF8]/30 bg-[#818CF8]/10 text-[#818CF8]",
  },
};

const RELEASES: Release[] = [
  {
    version: "v1.4.0",
    date: "Feb 14, 2026",
    badge: "New",
    title: "Developer API + Webhooks",
    summary:
      "The Tipping Jar REST API is now publicly available. Developers can create tip flows, manage creators, and react to events in real time with signed webhooks.",
    items: [
      "Public REST API with JWT auth",
      "Webhook events: tip.completed, tip.failed, payout.initiated, payout.completed",
      "Official SDKs for Python, Node.js, Dart, and Go",
      "Interactive API playground in dashboard",
    ],
  },
  {
    version: "v1.3.2",
    date: "Jan 28, 2026",
    badge: "Fix",
    title: "Payout reliability improvements",
    summary:
      "Several edge cases in the Stripe payout flow have been resolved. Payouts now retry automatically on transient failures.",
    items: [
      "Auto-retry on Stripe timeout (up to 3 attempts)",
      "Fixed duplicate payout bug for creators with multiple bank accounts",
      "Improved payout failure email notifications",
    ],
  },
  {
    version: "v1.3.0",
    date: "Jan 10, 2026",
    badge: "New",
    title: "Pro plan & advanced analytics",
    summary:
      "Introducing the Pro plan with lower fees, priority payouts, and a brand-new analytics dashboard with cohort analysis.",
    items: [
      "Pro plan — $12/month, 2.5% fee, T+1 payouts",
      "Revenue chart, tip heatmap, fan retention cohort",
      "CSV data export",
      "Custom tip amount goals with progress bar",
      "Remove The Tipping Jar branding from tip pages",
    ],
  },
  {
    version: "v1.2.0",
    date: "Dec 19, 2025",
    badge: "New",
    title: "Creator discovery & categories",
    summary:
      "Fans can now browse and search all creators by category. Creators can tag their content type for better discoverability.",
    items: [
      "Creator search by name and tagline",
      "Category filter (Music, Art, Gaming, Podcasts, Writing, Tech)",
      "Featured creators strip on Creators page",
      "Monthly tip goal progress bar on creator profiles",
    ],
  },
  {
    version: "v1.1.0",
    date: "Dec 1, 2025",
    badge: "New",
    title: "Apple Pay & Google Pay",
    summary:
      "Fans can now tip using Apple Pay and Google Pay in addition to cards, making the tip flow one tap on mobile.",
    items: [
      "Apple Pay on Safari (iOS & macOS)",
      "Google Pay on Chrome (Android & desktop)",
      "Payment method icons on tip pages",
    ],
  },
  {
    version: "v1.0.0",
    date: "Nov 15, 2025",
    badge: "Launch",
    title: "The Tipping Jar is live 🎉",
    summary:
      "The first public release of The Tipping Jar. Creators can set up a tip page in 60 seconds and start receiving fan support powered by Stripe.",
    items: [
      "Creator profiles with custom slug and tagline",
      "Tip pages with custom messages",
      "Stripe payment processing",
      "T+2 bank payouts",
      "Basic tip feed and notifications",
    ],
  },
];

export default function ChangelogPage() {
  return (
    <>
      {/* Hero */}
      <section className="border-b border-border bg-darker">
        <div className="container-content py-20 text-center md:py-24">
          <span className="inline-block rounded-full border border-teal/30 bg-teal/10 px-4 py-1.5 text-sm font-semibold text-teal">
            Changelog
          </span>
          <h1 className="heading-xl mt-6">What&apos;s new</h1>
          <p className="body-muted mx-auto mt-4 max-w-lg text-lg">
            Every update, improvement, and fix — documented.
          </p>
        </div>
      </section>

      {/* Entries */}
      <section className="container-content py-16 md:py-20">
        <div className="mx-auto max-w-3xl">
          {RELEASES.map((r) => {
            const c = BADGE_CLASSES[r.badge];
            return (
              <div key={r.version} className="flex gap-6">
                {/* Timeline */}
                <div className="flex flex-col items-center">
                  <span className={`mt-2 h-3 w-3 shrink-0 rounded-full ${c.dot}`} />
                  <span className="w-px flex-1 bg-border" />
                </div>

                {/* Card */}
                <div className="card mb-8 flex-1">
                  <div className="flex flex-wrap items-center gap-3">
                    <span
                      className={`rounded-full border px-2.5 py-1 text-xs font-bold ${c.chip}`}
                    >
                      {r.badge}
                    </span>
                    <span className="font-mono text-xs text-muted">{r.version}</span>
                    <span className="ml-auto text-xs text-muted">{r.date}</span>
                  </div>
                  <h2 className="mt-3 text-lg font-bold text-ink">{r.title}</h2>
                  <p className="body-muted mt-2 text-sm">{r.summary}</p>
                  <ul className="mt-4 space-y-1.5">
                    {r.items.map((item) => (
                      <li key={item} className="flex items-start gap-2 text-sm text-ink">
                        <span className={`mt-0.5 ${c.text}`}>›</span>
                        <span>{item}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            );
          })}
        </div>
      </section>
    </>
  );
}
