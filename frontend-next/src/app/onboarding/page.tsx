"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

const TOTAL_STEPS = 6;

const PLATFORMS = [
  "YouTube",
  "Twitch",
  "Instagram",
  "Twitter / X",
  "TikTok",
  "Podcast",
  "Blog / Newsletter",
  "Other",
];

const NICHES = [
  { label: "Gaming", icon: "🎮" },
  { label: "Music", icon: "🎵" },
  { label: "Art & Design", icon: "🎨" },
  { label: "Tech", icon: "💻" },
  { label: "Education", icon: "🎓" },
  { label: "Fitness", icon: "🏋️" },
  { label: "Food", icon: "🍽️" },
  { label: "Photography", icon: "📷" },
  { label: "Comedy", icon: "😂" },
  { label: "Travel", icon: "✈️" },
  { label: "Writing", icon: "📖" },
  { label: "Other", icon: "•••" },
];

const AUDIENCE_SIZES = [
  { title: "Just starting out", sub: "Under 1,000 followers", icon: "🌱" },
  { title: "Growing", sub: "1K – 10K followers", icon: "📈" },
  { title: "Established", sub: "10K – 100K followers", icon: "⭐" },
  { title: "Large audience", sub: "100K+ followers", icon: "🚀" },
];

const AGE_GROUPS = [
  { title: "Under 13", sub: "Kids — safe, family-friendly content", icon: "🧸" },
  { title: "13 – 17", sub: "Teens — school-age to late adolescence", icon: "🎒" },
  { title: "18 – 24", sub: "Young adults — Gen Z", icon: "🎮" },
  { title: "25 – 34", sub: "Millennials — early career adults", icon: "💼" },
  { title: "35 – 44", sub: "Mid-life adults", icon: "🏠" },
  { title: "45+", sub: "Mature audiences", icon: "✨" },
  { title: "All ages", sub: "My content is for everyone", icon: "🌍" },
];

const AUDIENCE_GENDERS = [
  { label: "Mostly female", icon: "♀" },
  { label: "Mostly male", icon: "♂" },
  { label: "Both equally", icon: "⚥" },
  { label: "Prefer not to say", icon: "•••" },
];

const GOALS = ["R500", "R2,000", "R5,000", "R10,000"];

const inputClass =
  "w-full rounded-xl border border-border bg-card px-4 py-3 text-sm text-ink placeholder:text-muted focus:border-teal focus:outline-none focus:ring-2 focus:ring-teal/30";

export default function OnboardingPage() {
  const router = useRouter();

  const [step, setStep] = useState(0);
  const [saving, setSaving] = useState(false);

  const [platforms, setPlatforms] = useState<string[]>([]);
  const [niche, setNiche] = useState<string | null>(null);
  const [audienceSize, setAudienceSize] = useState<string | null>(null);
  const [ageGroup, setAgeGroup] = useState<string | null>(null);
  const [audienceGender, setAudienceGender] = useState<string | null>(null);
  const [tagline, setTagline] = useState("");
  const [bio, setBio] = useState("");
  const [goal, setGoal] = useState("");

  const canProceed = (() => {
    switch (step) {
      case 0:
        return platforms.length > 0;
      case 1:
        return niche !== null;
      case 2:
        return audienceSize !== null;
      case 3:
        return ageGroup !== null;
      case 4:
        return audienceGender !== null;
      case 5:
        return tagline.trim().length > 0;
      default:
        return false;
    }
  })();

  function togglePlatform(p: string) {
    setPlatforms((prev) =>
      prev.includes(p) ? prev.filter((x) => x !== p) : [...prev, p],
    );
  }

  async function next() {
    if (step < TOTAL_STEPS - 1) {
      setStep((s) => s + 1);
      return;
    }
    // Final step — persist onboarding data, then head to the dashboard.
    setSaving(true);
    // TODO(api): no creator-profile / avatar / user-profile update endpoints are
    // exposed in the current /api/v2 client, so the collected onboarding data
    // (platforms, niche, audience_size, age_group, audience_gender, tagline, bio,
    // goal) cannot be persisted yet. Wire these up when the endpoints land.
    setTimeout(() => {
      router.push("/dashboard");
    }, 400);
  }

  function back() {
    if (step > 0) setStep((s) => s - 1);
  }

  return (
    <section className="container-content flex min-h-[70vh] flex-col items-center py-12">
      <div className="w-full max-w-2xl">
        {/* Progress */}
        <div className="flex gap-1.5">
          {Array.from({ length: TOTAL_STEPS }).map((_, i) => (
            <span
              key={i}
              className={`h-1 flex-1 rounded-full ${i <= step ? "bg-teal" : "bg-border"}`}
            />
          ))}
        </div>
        <p className="mt-3 text-center text-xs text-muted">
          Step {step + 1} of {TOTAL_STEPS}
        </p>

        <div className="mt-10">
          {step === 0 && (
            <StepShell
              title="Where do you create?"
              subtitle="Select all that apply."
            >
              <div className="grid gap-3 sm:grid-cols-2">
                {PLATFORMS.map((p) => {
                  const active = platforms.includes(p);
                  return (
                    <OptionButton key={p} active={active} onClick={() => togglePlatform(p)}>
                      <span className="text-sm font-semibold">{p}</span>
                      {active && <span className="ml-auto text-teal">✓</span>}
                    </OptionButton>
                  );
                })}
              </div>
            </StepShell>
          )}

          {step === 1 && (
            <StepShell
              title="What's your content niche?"
              subtitle="Pick the one that best describes your content."
            >
              <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
                {NICHES.map((n) => {
                  const active = niche === n.label;
                  return (
                    <button
                      key={n.label}
                      type="button"
                      onClick={() => setNiche(n.label)}
                      className={`flex flex-col items-center justify-center gap-2 rounded-xl border px-3 py-5 text-center transition ${
                        active
                          ? "border-teal bg-primary/15 text-teal"
                          : "border-border bg-card text-muted hover:border-teal/50"
                      }`}
                    >
                      <span className="text-2xl" aria-hidden>
                        {n.icon}
                      </span>
                      <span className="text-xs font-semibold">{n.label}</span>
                    </button>
                  );
                })}
              </div>
            </StepShell>
          )}

          {step === 2 && (
            <StepShell
              title="How big is your audience?"
              subtitle="This helps us tailor your experience."
            >
              <div className="space-y-3">
                {AUDIENCE_SIZES.map((s) => (
                  <RowOption
                    key={s.title}
                    active={audienceSize === s.title}
                    icon={s.icon}
                    title={s.title}
                    sub={s.sub}
                    onClick={() => setAudienceSize(s.title)}
                  />
                ))}
              </div>
            </StepShell>
          )}

          {step === 3 && (
            <StepShell
              title="Who is your content for?"
              subtitle="Select the primary age group you create for."
            >
              <div className="space-y-3">
                {AGE_GROUPS.map((g) => (
                  <RowOption
                    key={g.title}
                    active={ageGroup === g.title}
                    icon={g.icon}
                    title={g.title}
                    sub={g.sub}
                    onClick={() => setAgeGroup(g.title)}
                  />
                ))}
              </div>
            </StepShell>
          )}

          {step === 4 && (
            <StepShell
              title="Who watches your content?"
              subtitle="Helps match you with the right opportunities."
            >
              <div className="grid grid-cols-2 gap-4">
                {AUDIENCE_GENDERS.map((g) => {
                  const active = audienceGender === g.label;
                  return (
                    <button
                      key={g.label}
                      type="button"
                      onClick={() => setAudienceGender(g.label)}
                      className={`flex flex-col items-center justify-center gap-3 rounded-2xl border px-4 py-8 text-center transition ${
                        active
                          ? "border-teal bg-primary/15 text-teal"
                          : "border-border bg-card text-ink hover:border-teal/50"
                      }`}
                    >
                      <span className="text-3xl" aria-hidden>
                        {g.icon}
                      </span>
                      <span className="text-sm font-bold">{g.label}</span>
                    </button>
                  );
                })}
              </div>
            </StepShell>
          )}

          {step === 5 && (
            <StepShell
              title="Set up your creator profile"
              subtitle="You can always change these later."
            >
              <div className="space-y-6">
                <div>
                  <label className="mb-2 block text-sm font-semibold text-ink">
                    Your tagline
                  </label>
                  <input
                    value={tagline}
                    maxLength={80}
                    onChange={(e) => setTagline(e.target.value)}
                    placeholder={'e.g. "Indie game dev sharing my journey 🎮"'}
                    className={inputClass}
                  />
                </div>

                <div>
                  <label className="mb-1 block text-sm font-semibold text-ink">
                    Short bio (optional)
                  </label>
                  <p className="mb-2 text-xs text-muted">Visible on your public tip page.</p>
                  <textarea
                    value={bio}
                    maxLength={200}
                    rows={3}
                    onChange={(e) => setBio(e.target.value)}
                    placeholder="Tell your fans a bit about you…"
                    className={inputClass}
                  />
                </div>

                <div>
                  <label className="mb-1 block text-sm font-semibold text-ink">
                    Monthly tip goal (optional)
                  </label>
                  <p className="mb-3 text-xs text-muted">
                    Sets a visible goal bar on your tip page.
                  </p>
                  <div className="flex flex-wrap gap-2.5">
                    {GOALS.map((g) => {
                      const active = goal === g;
                      return (
                        <button
                          key={g}
                          type="button"
                          onClick={() => setGoal(g)}
                          className={`rounded-full border px-5 py-2 text-sm font-semibold transition ${
                            active
                              ? "border-teal bg-primary/15 text-teal"
                              : "border-border bg-card text-muted hover:border-teal/50"
                          }`}
                        >
                          {g}
                        </button>
                      );
                    })}
                  </div>
                </div>

                {/* Preview */}
                <div className="rounded-2xl border border-teal/30 bg-card p-5">
                  <div className="flex items-center gap-3.5">
                    <span className="grid h-11 w-11 place-items-center rounded-full bg-brand-gradient text-lg">
                      💚
                    </span>
                    <div>
                      <p className="text-xs text-muted">Your tip page preview</p>
                      <p
                        className={`text-sm font-semibold ${tagline ? "text-ink" : "text-muted"}`}
                      >
                        {tagline || "Your tagline will appear here…"}
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </StepShell>
          )}
        </div>

        {/* Footer nav */}
        <div className="mt-10 flex items-center">
          {step > 0 && (
            <button
              type="button"
              onClick={back}
              disabled={saving}
              className="text-sm font-medium text-muted hover:text-ink disabled:opacity-50"
            >
              Back
            </button>
          )}
          <div className="ml-auto">
            <button
              type="button"
              onClick={next}
              disabled={!canProceed || saving}
              className="btn-primary disabled:opacity-40"
            >
              {saving
                ? "Saving…"
                : step === TOTAL_STEPS - 1
                  ? "Go to dashboard →"
                  : "Continue"}
            </button>
          </div>
        </div>
      </div>
    </section>
  );
}

function StepShell({
  title,
  subtitle,
  children,
}: {
  title: string;
  subtitle: string;
  children: React.ReactNode;
}) {
  return (
    <div>
      <h1 className="text-2xl font-extrabold tracking-tight text-ink md:text-3xl">
        {title}
      </h1>
      <p className="body-muted mt-2">{subtitle}</p>
      <div className="mt-8">{children}</div>
    </div>
  );
}

function OptionButton({
  active,
  onClick,
  children,
}: {
  active: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`flex items-center gap-3 rounded-xl border px-4 py-3.5 text-left transition ${
        active
          ? "border-teal bg-primary/15 text-teal"
          : "border-border bg-card text-ink hover:border-teal/50"
      }`}
    >
      {children}
    </button>
  );
}

function RowOption({
  active,
  icon,
  title,
  sub,
  onClick,
}: {
  active: boolean;
  icon: string;
  title: string;
  sub: string;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`flex w-full items-center gap-4 rounded-2xl border px-4 py-4 text-left transition ${
        active ? "border-teal bg-primary/10" : "border-border bg-card hover:border-teal/50"
      }`}
    >
      <span
        className={`grid h-10 w-10 shrink-0 place-items-center rounded-full text-lg ${
          active ? "bg-primary/20" : "bg-border/40"
        }`}
        aria-hidden
      >
        {icon}
      </span>
      <span className="flex-1">
        <span className="block text-sm font-bold text-ink">{title}</span>
        <span className="block text-xs text-muted">{sub}</span>
      </span>
      {active && <span className="text-teal">✓</span>}
    </button>
  );
}
