"use client";

import { Suspense, useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";

type Role = "fan" | "creator" | "enterprise";

const ROLES: { value: Role; label: string; sub: string; icon: string }[] = [
  { value: "creator", label: "Creator", sub: "Receive tips for your work", icon: "bi-star-fill" },
  { value: "fan", label: "Tipper", sub: "Support creators you love", icon: "bi-emoji-smile-fill" },
  { value: "enterprise", label: "Enterprise", sub: "Tipping for your platform", icon: "bi-building" },
];

const PANEL: Record<Role, { heading: string; sub: string; perks: [string, string, string][] }> = {
  fan: {
    heading: "Support creators you love.",
    sub: "Tip your favourite creators instantly — pay by card in seconds.",
    perks: [
      ["bi-lightning-charge-fill", "Instant tips", "Support your favourite creators in seconds."],
      ["bi-chat-heart-fill", "Say it with a message", "Every tip can carry the words you've been meaning to send."],
      ["bi-unlock-fill", "Unlock exclusive content", "Tip monthly or subscribe and their vault opens for you."],
    ],
  },
  creator: {
    heading: "Start earning from day one.",
    sub: "Your tip page, goals, jars and exclusive content — live in minutes.",
    perks: [
      ["bi-rocket-takeoff-fill", "Live in minutes", "Finish your profile and your page opens for tips."],
      ["bi-bank", "Real payouts", "Balance to your South African bank account, on request."],
      ["bi-bar-chart-fill", "Real-time analytics", "Watch tips roll in on your dashboard as they happen."],
    ],
  },
  enterprise: {
    heading: "Scale tipping for your platform.",
    sub: "White-label tipping for teams, agencies and platforms.",
    perks: [
      ["bi-puzzle-fill", "White-label ready", "Embed tipping directly into your product."],
      ["bi-headset", "Dedicated support", "Priority onboarding and a dedicated manager."],
      ["bi-people-fill", "Custom contracts", "Revenue share and SLA terms available."],
    ],
  },
};

const GENDERS = [
  { value: "", label: "Prefer not to say" },
  { value: "male", label: "Male" },
  { value: "female", label: "Female" },
  { value: "non_binary", label: "Non-binary" },
];

// Mirror of the backend's slugify — lowercase, runs of non-alphanumerics
// become single hyphens — so the live URL preview matches the real slug.
function slugify(s: string): string {
  return s
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

const PW_RULES: { label: string; test: (pw: string) => boolean }[] = [
  { label: "At least 6 characters", test: (pw) => pw.length >= 6 },
  { label: "Contains a number", test: (pw) => /[0-9]/.test(pw) },
  { label: "Contains a special character", test: (pw) => /[^a-zA-Z0-9\s]/.test(pw) },
  { label: "Contains an uppercase letter", test: (pw) => /[A-Z]/.test(pw) },
];

const STRENGTH = [
  { label: "Weak", color: "#EF4444" },
  { label: "Fair", color: "#F97316" },
  { label: "Good", color: "#EAB308" },
  { label: "Strong", color: "#12A25C" },
];

function inputClass(extra = "") {
  return `w-full rounded-xl border border-border bg-white px-4 py-3 text-sm text-ink placeholder:text-muted focus:border-teal focus:outline-none focus:ring-2 focus:ring-teal/30 ${extra}`;
}

const STEPS = ["Account", "Security", "Finish"];

function RegisterInner() {
  const { register, loading } = useAuth();
  const router = useRouter();
  const search = useSearchParams();

  const [step, setStep] = useState(0);
  const [role, setRole] = useState<Role>("creator");
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [username, setUsername] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [phone, setPhone] = useState("");
  const [gender, setGender] = useState("");
  const [dob, setDob] = useState("");
  const [referral, setReferral] = useState("");
  const [refStatus, setRefStatus] = useState<"idle" | "checking" | "valid" | "invalid">("idle");
  const [isMinor, setIsMinor] = useState(false);
  const [guardianName, setGuardianName] = useState("");
  const [guardianEmail, setGuardianEmail] = useState("");
  const [acceptTerms, setAcceptTerms] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Referral links are shared as /register?ref=CODE — pick the code up
  // automatically so the referrer actually gets credited.
  useEffect(() => {
    const ref = search.get("ref");
    if (ref) setReferral(ref.toUpperCase());
  }, [search]);

  // Live-validate the referral code against the referrals service, debounced.
  useEffect(() => {
    const code = referral.trim();
    if (!code) {
      setRefStatus("idle");
      return;
    }
    let alive = true;
    setRefStatus("checking");
    const t = setTimeout(() => {
      api
        .lookupReferralCode(code)
        .then(() => alive && setRefStatus("valid"))
        .catch(() => alive && setRefStatus("invalid"));
    }, 400);
    return () => {
      alive = false;
      clearTimeout(t);
    };
  }, [referral]);

  const score = useMemo(() => PW_RULES.filter((r) => r.test(password)).length, [password]);
  const level = score > 0 ? STRENGTH[score - 1] : null;
  const slug = slugify(username || [firstName, lastName].filter(Boolean).join(" "));
  const panel = PANEL[role];

  function validateStep(s: number): string | null {
    if (s === 0) {
      if (username.trim().length < 3) return "Username must be at least 3 characters";
      if (!email.includes("@")) return "Enter a valid email";
      return null;
    }
    if (s === 1) {
      for (const rule of PW_RULES.slice(0, 3)) {
        if (!rule.test(password)) return `Password: ${rule.label.toLowerCase()}`;
      }
      if (password !== confirm) return "Passwords do not match";
      return null;
    }
    if (referral.trim() && refStatus === "invalid") {
      return "That referral code doesn't exist — fix it or clear the field.";
    }
    if (isMinor && (!guardianName.trim() || !guardianEmail.includes("@"))) {
      return "Add the parent/guardian's name and a valid email.";
    }
    if (!acceptTerms) return "Please accept the Terms of Service and Privacy Policy to continue.";
    return null;
  }

  function next() {
    setError(null);
    const problem = validateStep(step);
    if (problem) {
      setError(problem);
      return;
    }
    setStep((s) => s + 1);
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    const problem = validateStep(2);
    if (problem) {
      setError(problem);
      return;
    }
    try {
      await register({
        email: email.trim(),
        password,
        username: username.trim(),
        role,
        phone_number: phone.trim() || undefined,
        referral_code: referral.trim() || undefined,
      });
      // Creators go straight into the onboarding wizard (profile type,
      // location, identity, bank, verification). Everyone else lands on
      // the dashboard.
      router.push(role === "creator" ? "/onboarding" : "/dashboard");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Registration failed. Try again.");
    }
  }

  return (
    <section className="container-content grid items-start gap-16 py-16 lg:grid-cols-2 lg:py-24">
      {/* Branding panel */}
      <div className="hidden lg:sticky lg:top-24 lg:block">
        <p className="eyebrow">Create your account</p>
        <h1 className="heading-xl mt-4 max-w-md text-4xl md:text-5xl">{panel.heading}</h1>
        <p className="body-muted mt-5 max-w-md text-lg">{panel.sub}</p>
        <ul className="mt-10 space-y-5">
          {panel.perks.map(([icon, title, body]) => (
            <li key={title} className="flex items-start gap-4 rounded-2xl border border-border bg-white p-4 shadow-soft">
              <span className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-mint/15 text-lg text-green">
                <i className={`bi ${icon}`} />
              </span>
              <div>
                <p className="font-display font-bold text-ink">{title}</p>
                <p className="body-muted mt-0.5 text-sm">{body}</p>
              </div>
            </li>
          ))}
        </ul>
        {refStatus === "valid" && (
          <div className="mt-6 flex items-center gap-3 rounded-2xl border border-mint/40 bg-mint/10 p-4">
            <span className="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-mint text-navy">
              <i className="bi bi-gift-fill" />
            </span>
            <p className="text-sm text-ink">
              You&apos;re joining through a <span className="font-bold">referral</span> — your referrer
              earns a small commission on your tips, at no cost to you.
            </p>
          </div>
        )}
      </div>

      {/* Form card */}
      <div className="mx-auto w-full max-w-lg">
        <div className="card !p-6 md:!p-8">
          <div className="flex items-baseline justify-between">
            <h2 className="text-2xl font-extrabold tracking-tight text-ink">Create your account</h2>
            <span className="font-mono text-[11px] uppercase tracking-wide text-muted">
              {step + 1}/{STEPS.length}
            </span>
          </div>
          <p className="body-muted mt-2 text-sm">
            Already have an account?{" "}
            <Link href="/login" className="font-semibold text-teal hover:underline">
              Sign in
            </Link>
          </p>

          {/* Step rail */}
          <div className="mt-5 flex items-center gap-2">
            {STEPS.map((label, i) => (
              <div key={label} className="flex flex-1 flex-col gap-1.5">
                <span
                  className={`h-1.5 rounded-full transition ${
                    i < step ? "bg-green" : i === step ? "bg-mint" : "bg-border"
                  }`}
                />
                <span
                  className={`text-[10px] font-semibold uppercase tracking-wide ${
                    i <= step ? "text-green" : "text-muted"
                  }`}
                >
                  {label}
                </span>
              </div>
            ))}
          </div>

          <form onSubmit={handleSubmit} className="mt-6 space-y-4">
            {/* ── Step 1: Who you are ─────────────────────────────── */}
            {step === 0 && (
              <>
                <p className="text-sm font-semibold text-ink">I am a…</p>
                <div className="grid gap-2.5 sm:grid-cols-3">
                  {ROLES.map((r) => {
                    const active = role === r.value;
                    return (
                      <button
                        key={r.value}
                        type="button"
                        onClick={() => setRole(r.value)}
                        className={`flex flex-col items-start gap-1 rounded-xl border px-3 py-3 text-left transition ${
                          active
                            ? "border-teal bg-primary/10 shadow-soft"
                            : "border-border bg-white text-muted hover:border-teal/50"
                        }`}
                      >
                        <span className={`text-lg ${active ? "text-green" : "text-muted"}`} aria-hidden>
                          <i className={`bi ${r.icon}`} />
                        </span>
                        <span className={`text-sm font-bold ${active ? "text-ink" : "text-muted"}`}>{r.label}</span>
                        <span className="text-[11px] leading-tight text-muted">{r.sub}</span>
                      </button>
                    );
                  })}
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="mb-2 block text-sm font-semibold text-ink">First name</label>
                    <input value={firstName} onChange={(e) => setFirstName(e.target.value)} placeholder="Jane" className={inputClass()} />
                  </div>
                  <div>
                    <label className="mb-2 block text-sm font-semibold text-ink">Last name</label>
                    <input value={lastName} onChange={(e) => setLastName(e.target.value)} placeholder="Doe" className={inputClass()} />
                  </div>
                </div>

                <div>
                  <label className="mb-2 block text-sm font-semibold text-ink">Username</label>
                  <input
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    placeholder="yourname"
                    autoComplete="username"
                    className={inputClass()}
                  />
                  {role === "creator" && slug && (
                    <p className="mt-1.5 font-mono text-[11px] text-muted">
                      Your page: <span className="text-green">tippingjar.co.za/creator/{slug}</span>
                    </p>
                  )}
                </div>

                <div>
                  <label className="mb-2 block text-sm font-semibold text-ink">Email address</label>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="you@example.com"
                    autoComplete="email"
                    className={inputClass()}
                  />
                </div>
              </>
            )}

            {/* ── Step 2: Security ────────────────────────────────── */}
            {step === 1 && (
              <>
                <div>
                  <div className="mb-2 flex items-center justify-between">
                    <label className="block text-sm font-semibold text-ink">Password</label>
                    <button type="button" onClick={() => setShowPassword((s) => !s)} className="text-xs text-muted hover:text-ink">
                      {showPassword ? "Hide" : "Show"}
                    </button>
                  </div>
                  <input
                    type={showPassword ? "text" : "password"}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    autoComplete="new-password"
                    className={inputClass()}
                  />
                  {password && (
                    <div className="mt-2">
                      <div className="flex gap-1.5">
                        {[0, 1, 2, 3].map((i) => (
                          <span
                            key={i}
                            className="h-1 flex-1 rounded-full bg-border"
                            style={{ backgroundColor: i < score && level ? level.color : undefined }}
                          />
                        ))}
                      </div>
                      {level && (
                        <p className="mt-1.5 text-xs font-semibold" style={{ color: level.color }}>
                          {level.label}
                        </p>
                      )}
                    </div>
                  )}
                  <ul className="mt-3 space-y-1">
                    {PW_RULES.map((r, i) => {
                      const ok = r.test(password);
                      const optional = i === 3;
                      return (
                        <li key={r.label} className={`flex items-center gap-2 text-xs ${ok ? "text-green" : "text-muted"}`}>
                          <i className={`bi ${ok ? "bi-check-circle-fill" : "bi-circle"}`} aria-hidden />
                          {r.label}
                          {optional && <span className="text-[10px] text-muted/70">(recommended)</span>}
                        </li>
                      );
                    })}
                  </ul>
                </div>

                <div>
                  <label className="mb-2 block text-sm font-semibold text-ink">Confirm password</label>
                  <input
                    type={showPassword ? "text" : "password"}
                    value={confirm}
                    onChange={(e) => setConfirm(e.target.value)}
                    placeholder="••••••••"
                    autoComplete="new-password"
                    className={inputClass()}
                  />
                  {confirm && (
                    <p className={`mt-1.5 text-xs font-semibold ${confirm === password ? "text-green" : "text-red-500"}`}>
                      {confirm === password ? "Passwords match" : "Passwords don't match yet"}
                    </p>
                  )}
                </div>

                <div>
                  <label className="mb-2 block text-sm font-semibold text-ink">Phone number (optional)</label>
                  <input type="tel" value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="0821234567" autoComplete="tel" className={inputClass()} />
                </div>
              </>
            )}

            {/* ── Step 3: Finish ──────────────────────────────────── */}
            {step === 2 && (
              <>
                <div>
                  <label className="mb-2 block text-sm font-semibold text-ink">Referral code (optional)</label>
                  <div className="relative">
                    <input
                      value={referral}
                      onChange={(e) => setReferral(e.target.value.toUpperCase())}
                      placeholder="e.g. JANE4F2A"
                      className={inputClass("pr-10 tracking-widest")}
                    />
                    {refStatus !== "idle" && (
                      <span className="absolute right-3.5 top-1/2 -translate-y-1/2 text-base" aria-hidden>
                        {refStatus === "checking" && <i className="bi bi-three-dots text-muted" />}
                        {refStatus === "valid" && <i className="bi bi-check-circle-fill text-green" />}
                        {refStatus === "invalid" && <i className="bi bi-x-circle-fill text-red-500" />}
                      </span>
                    )}
                  </div>
                  {refStatus === "valid" && (
                    <p className="mt-1.5 text-xs font-semibold text-green">
                      Valid code — your referrer earns commission on your tips, at no cost to you.
                    </p>
                  )}
                  {refStatus === "invalid" && (
                    <p className="mt-1.5 text-xs font-semibold text-red-500">
                      That code doesn&apos;t exist — double-check it or clear the field.
                    </p>
                  )}
                </div>

                <details className="rounded-xl border border-border bg-white">
                  <summary className="cursor-pointer px-4 py-3 text-sm font-semibold text-ink">
                    Optional details <span className="font-normal text-muted">(gender, date of birth)</span>
                  </summary>
                  <div className="grid grid-cols-2 gap-3 px-4 pb-4">
                    <div>
                      <label className="mb-2 block text-xs font-semibold text-muted">Gender</label>
                      <select value={gender} onChange={(e) => setGender(e.target.value)} className={inputClass()}>
                        {GENDERS.map((g) => (
                          <option key={g.value} value={g.value}>{g.label}</option>
                        ))}
                      </select>
                    </div>
                    <div>
                      <label className="mb-2 block text-xs font-semibold text-muted">Date of birth</label>
                      <input type="date" value={dob} onChange={(e) => setDob(e.target.value)} className={inputClass()} />
                    </div>
                  </div>
                </details>

                <label className="flex cursor-pointer items-start gap-3">
                  <input type="checkbox" checked={isMinor} onChange={(e) => setIsMinor(e.target.checked)} className="mt-0.5 h-4 w-4 accent-teal" />
                  <span className="text-xs leading-relaxed text-muted">
                    This account is for someone under 18 (managed by a parent/guardian)
                  </span>
                </label>

                {isMinor && (
                  <div className="space-y-3 rounded-xl border border-teal/30 bg-primary/5 p-4">
                    <p className="text-sm font-bold text-teal">Parent / Guardian details</p>
                    <p className="text-xs text-muted">All account communications will go to the guardian.</p>
                    <input value={guardianName} onChange={(e) => setGuardianName(e.target.value)} placeholder="Guardian full name" className={inputClass()} />
                    <input type="email" value={guardianEmail} onChange={(e) => setGuardianEmail(e.target.value)} placeholder="parent@example.com" className={inputClass()} />
                  </div>
                )}

                <label className="flex cursor-pointer items-start gap-3">
                  <input type="checkbox" checked={acceptTerms} onChange={(e) => setAcceptTerms(e.target.checked)} className="mt-0.5 h-4 w-4 accent-teal" />
                  <span className="text-xs leading-relaxed text-muted">
                    I agree to the{" "}
                    <Link href="/terms" className="font-semibold text-teal hover:underline">Terms of Service</Link> and{" "}
                    <Link href="/privacy" className="font-semibold text-teal hover:underline">Privacy Policy</Link>
                  </span>
                </label>
              </>
            )}

            {error && (
              <div className="flex items-start gap-2 rounded-xl border border-red-500/30 bg-red-500/10 p-3 text-sm text-red-500">
                <span aria-hidden><i className="bi bi-exclamation-triangle-fill" /></span>
                <span>{error}</span>
              </div>
            )}

            {/* Nav buttons */}
            <div className="flex items-center gap-3 pt-1">
              {step > 0 && (
                <button
                  type="button"
                  onClick={() => { setError(null); setStep((s) => s - 1); }}
                  className="btn-ghost !px-5 !py-2.5 text-sm"
                >
                  Back
                </button>
              )}
              {step < STEPS.length - 1 ? (
                <button type="button" onClick={next} className="btn-primary ml-auto !px-7 text-sm">
                  Continue →
                </button>
              ) : (
                <button type="submit" disabled={loading} className="btn-primary ml-auto !px-7 text-sm disabled:opacity-50">
                  {loading
                    ? "Creating account…"
                    : role === "creator"
                      ? "Create account & set up my page →"
                      : "Create account"}
                </button>
              )}
            </div>
          </form>
        </div>

        <p className="mt-4 text-center text-[11px] text-muted">
          <i className="bi bi-shield-lock-fill mr-1 text-green" aria-hidden />
          Free to join · No credit card · 6% flat only when a tip lands
        </p>
      </div>
    </section>
  );
}

export default function RegisterPage() {
  return (
    <Suspense
      fallback={
        <section className="container-content grid min-h-[60vh] place-items-center">
          <div className="h-10 w-10 animate-spin rounded-full border-2 border-border border-t-green" />
        </section>
      }
    >
      <RegisterInner />
    </Suspense>
  );
}
