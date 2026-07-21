import { api } from "@/lib/api";
import type { Job } from "@/types";

export const metadata = {
  title: "Careers — Tipping Jar",
  description: "Build the future of the creator economy with the Tipping Jar team.",
};

const PERKS = [
  { icon: "🌍", title: "Fully remote", body: "Work from anywhere. We care about results, not where you sit." },
  { icon: "🏖️", title: "Unlimited PTO", body: "Take the time you need. We trust you." },
  { icon: "📈", title: "Equity", body: "Every full-time hire gets meaningful equity in TippingJar." },
  { icon: "🩺", title: "Health cover", body: "Full medical, dental, and vision for you and your family." },
  { icon: "💻", title: "Hardware stipend", body: "R35,000 to set up your ideal workspace." },
  { icon: "🎓", title: "Learning budget", body: "R18,000/year for courses, books, and conferences." },
];

const DEPT_COLORS: Record<string, string> = {
  engineering: "#818CF8",
  design: "#004423",
  growth: "#FBBF24",
  marketing: "#FBBF24",
  operations: "#F87171",
  finance: "#F87171",
  product: "#0097B2",
};

function deptColor(dept: string): string {
  return DEPT_COLORS[dept.toLowerCase()] ?? "#34D399";
}

async function getJobs(): Promise<Job[]> {
  try {
    return await api.listJobs();
  } catch {
    return [];
  }
}

export default async function CareersPage() {
  const jobs = await getJobs();

  // Group jobs by department, preserving encounter order.
  const byDept = new Map<string, Job[]>();
  for (const job of jobs) {
    const list = byDept.get(job.department) ?? [];
    list.push(job);
    byDept.set(job.department, list);
  }

  return (
    <>
      {/* Hero */}
      <section className="border-b border-border bg-darker">
        <div className="container-content py-24 text-center md:py-32">
          <span className="inline-block rounded-full border border-teal/30 bg-teal/10 px-4 py-1.5 text-xs font-semibold text-teal">
            We&apos;re hiring
          </span>
          <h1 className="heading-xl mx-auto mt-6 max-w-3xl">
            Build the future of the creator economy
          </h1>
          <p className="body-muted mx-auto mt-6 max-w-xl text-lg">
            We&apos;re a small, fully remote team with a big mission. If you care deeply about
            creators and love building great products, we&apos;d love to hear from you.
          </p>
        </div>
      </section>

      {/* Perks */}
      <section className="container-content py-20">
        <h2 className="heading-xl text-center text-3xl md:text-4xl">Why TippingJar</h2>
        <div className="mt-12 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {PERKS.map((p) => (
            <div key={p.title} className="card">
              <div className="grid h-10 w-10 place-items-center rounded-xl bg-teal/10 text-lg">
                {p.icon}
              </div>
              <h3 className="mt-3 text-sm font-bold text-ink">{p.title}</h3>
              <p className="body-muted mt-1.5 text-[13px]">{p.body}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Open roles */}
      <section className="border-t border-border bg-darker">
        <div className="container-content py-20">
          <h2 className="heading-xl text-center text-3xl md:text-4xl">Open roles</h2>
          <div className="mx-auto mt-10 max-w-3xl">
            {jobs.length === 0 ? (
              <div className="card text-center">
                <div className="text-3xl">💼</div>
                <h3 className="mt-3 text-base font-bold text-ink">No open roles right now</h3>
                <p className="body-muted mt-2 text-[13px]">
                  Check back soon — we&apos;re always growing.
                </p>
              </div>
            ) : (
              <div className="space-y-8">
                {[...byDept.entries()].map(([dept, deptJobs]) => (
                  <div key={dept}>
                    <p className="text-[11px] font-semibold uppercase tracking-wider text-muted">
                      {dept}
                    </p>
                    <div className="mt-3 space-y-2">
                      {deptJobs.map((job) => {
                        const color = deptColor(job.department);
                        return (
                          <div
                            key={job.id}
                            className="flex items-center gap-4 rounded-xl border border-border bg-card p-4"
                          >
                            <span
                              className="h-2 w-2 shrink-0 rounded-full"
                              style={{ backgroundColor: color }}
                            />
                            <span className="flex-1 text-sm font-semibold text-ink">
                              {job.title}
                            </span>
                            <span className="hidden text-xs text-muted sm:inline">
                              {job.location}
                            </span>
                            <span className="rounded-full border border-primary/25 bg-primary/10 px-2.5 py-1 text-[11px] font-semibold text-teal">
                              {job.employment_type}
                            </span>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </section>
    </>
  );
}
