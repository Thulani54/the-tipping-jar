"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useAuth } from "@/lib/auth";

type Role = "fan" | "creator" | "enterprise";

const ROLES: { value: Role; label: string; icon: string }[] = [
  { value: "fan", label: "Tipper", icon: "bi-emoji-smile-fill" },
  { value: "creator", label: "Creator", icon: "bi-star-fill" },
  { value: "enterprise", label: "Enterprise", icon: "bi-building" },
];

const PANEL: Record<Role, { heading: string; sub: string; perks: [string, string, string][] }> = {
  fan: {
    heading: "Support creators you love.",
    sub: "Tip your favourite creators instantly — no account needed.",
    perks: [
      ["bi-lightning-charge-fill", "Instant tips", "Support your favourite creators in seconds."],
      ["bi-cash-stack", "Any amount", "Tip R5 or R5 000 — totally up to you."],
      ["bi-heart-fill", "Support directly", "Every cent goes straight to the creator."],
    ],
  },
  creator: {
    heading: "Start earning from day one.",
    sub: "Join 2,400+ creators already filling their jar every day.",
    perks: [
      ["bi-rocket-takeoff-fill", "Live in 60 seconds", "Your tip page is public the moment you save."],
      ["bi-bank", "2-day payouts", "Receive money directly to your bank within 2 days."],
      ["bi-bar-chart-fill", "Real-time analytics", "Watch tips roll in on your dashboard."],
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

function passwordScore(pw: string): number {
  if (!pw) return 0;
  let s = 0;
  if (pw.length >= 6) s++;
  if (/[0-9]/.test(pw)) s++;
  if (/[^a-zA-Z0-9\s]/.test(pw)) s++;
  if (/[A-Z]/.test(pw)) s++;
  return s;
}

const STRENGTH = [
  { label: "Weak", color: "#EF4444" },
  { label: "Fair", color: "#F97316" },
  { label: "Good", color: "#EAB308" },
  { label: "Strong", color: "#0097B2" },
];

function inputClass(extra = "") {
  return `w-full rounded-xl border border-border bg-dark px-4 py-3 text-sm text-ink placeholder:text-muted focus:border-teal focus:outline-none focus:ring-2 focus:ring-teal/30 ${extra}`;
}

export default function RegisterPage() {
  const { register, loading } = useAuth();
  const router = useRouter();

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
  const [isMinor, setIsMinor] = useState(false);
  const [guardianName, setGuardianName] = useState("");
  const [guardianEmail, setGuardianEmail] = useState("");
  const [acceptTerms, setAcceptTerms] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const score = useMemo(() => passwordScore(password), [password]);
  const level = score > 0 ? STRENGTH[score - 1] : null;

  const panel = PANEL[role];

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);

    if (username.trim().length < 3) return setError("Username must be at least 3 characters");
    if (!email.includes("@")) return setError("Enter a valid email");
    if (password.length < 6) return setError("Password must be at least 6 characters");
    if (!/[0-9]/.test(password)) return setError("Add at least 1 number to your password");
    if (!/[^a-zA-Z0-9\s]/.test(password)) return setError("Add at least 1 special character to your password");
    if (password !== confirm) return setError("Passwords do not match");
    if (!acceptTerms) return setError("Please accept the Terms of Service and Privacy Policy to continue.");

    try {
      // Only fields supported by api.register are submitted. Extra fields
      // (name, gender, dob, guardian) are collected visually for parity with
      // the Flutter flow but not yet wired to the /api/v2 backend.
      // TODO(api): persist first/last name, gender, date_of_birth, guardian details.
      await register({
        email: email.trim(),
        password,
        username: username.trim(),
        role,
        phone_number: phone.trim() || undefined,
        referral_code: referral.trim() || undefined,
      });
      router.push("/dashboard");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Registration failed. Try again.");
    }
  }

  return (
    <section className="container-content grid items-start gap-16 py-16 lg:grid-cols-2 lg:py-24">
      {/* Branding panel */}
      <div className="hidden lg:block lg:sticky lg:top-24">
        <span className="inline-block rounded-full border border-border bg-card px-4 py-1.5 text-sm text-teal">
          Create your account
        </span>
        <h1 className="heading-xl mt-6 max-w-md">{panel.heading}</h1>
        <p className="body-muted mt-5 max-w-md text-lg">{panel.sub}</p>
        <ul className="mt-10 space-y-6">
          {panel.perks.map(([icon, title, body]) => (
            <li key={title} className="flex items-start gap-4">
              <span className="grid h-9 w-9 shrink-0 place-items-center rounded-lg bg-primary/15 text-lg text-primary">
                <i className={`bi ${icon}`} />
              </span>
              <div>
                <p className="font-semibold text-ink">{title}</p>
                <p className="body-muted mt-0.5">{body}</p>
              </div>
            </li>
          ))}
        </ul>
      </div>

      {/* Form card */}
      <div className="mx-auto w-full max-w-lg">
        <div className="card">
          <h2 className="text-2xl font-extrabold tracking-tight text-ink">
            Create your account
          </h2>
          <p className="body-muted mt-2">
            Already have an account?{" "}
            <Link href="/login" className="font-semibold text-teal hover:underline">
              Sign in
            </Link>
          </p>

          {/* Role toggle */}
          <p className="mt-7 text-sm font-semibold text-ink">I am a…</p>
          <div className="mt-3 grid grid-cols-3 gap-2.5">
            {ROLES.map((r) => {
              const active = role === r.value;
              return (
                <button
                  key={r.value}
                  type="button"
                  onClick={() => setRole(r.value)}
                  className={`flex items-center justify-center gap-2 rounded-xl border px-2 py-3 text-sm font-semibold transition ${
                    active
                      ? "border-teal bg-primary/15 text-teal"
                      : "border-border bg-dark text-muted hover:border-teal/50"
                  }`}
                >
                  <span aria-hidden><i className={`bi ${r.icon}`} /></span>
                  {r.label}
                </button>
              );
            })}
          </div>

          <form onSubmit={handleSubmit} className="mt-6 space-y-4">
            {/* Names (visual only) */}
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="mb-2 block text-sm font-semibold text-ink">First name</label>
                <input
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                  placeholder="Jane"
                  className={inputClass()}
                />
              </div>
              <div>
                <label className="mb-2 block text-sm font-semibold text-ink">Last name</label>
                <input
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                  placeholder="Doe"
                  className={inputClass()}
                />
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

            <div>
              <div className="mb-2 flex items-center justify-between">
                <label className="block text-sm font-semibold text-ink">Password</label>
                <button
                  type="button"
                  onClick={() => setShowPassword((s) => !s)}
                  className="text-xs text-muted hover:text-ink"
                >
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
                        className="h-1 flex-1 rounded-full"
                        style={{ backgroundColor: i < score && level ? level.color : "#1E2E26" }}
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
            </div>

            <div>
              <label className="mb-2 block text-sm font-semibold text-ink">
                Phone number (optional)
              </label>
              <input
                type="tel"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="0821234567"
                autoComplete="tel"
                className={inputClass()}
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="mb-2 block text-sm font-semibold text-ink">Gender (optional)</label>
                <select
                  value={gender}
                  onChange={(e) => setGender(e.target.value)}
                  className={inputClass()}
                >
                  {GENDERS.map((g) => (
                    <option key={g.value} value={g.value} className="bg-card">
                      {g.label}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="mb-2 block text-sm font-semibold text-ink">
                  Date of birth (optional)
                </label>
                <input
                  type="date"
                  value={dob}
                  onChange={(e) => setDob(e.target.value)}
                  className={inputClass()}
                />
              </div>
            </div>

            {/* Referral code (submitted) */}
            <div>
              <label className="mb-2 block text-sm font-semibold text-ink">
                Referral code (optional)
              </label>
              <input
                value={referral}
                onChange={(e) => setReferral(e.target.value.toUpperCase())}
                placeholder="e.g. JANE4F2A"
                className={inputClass("tracking-widest")}
              />
            </div>

            {/* Minor / guardian (visual only) */}
            <label className="flex cursor-pointer items-start gap-3">
              <input
                type="checkbox"
                checked={isMinor}
                onChange={(e) => setIsMinor(e.target.checked)}
                className="mt-0.5 h-4 w-4 accent-teal"
              />
              <span className="text-xs leading-relaxed text-muted">
                This account is for someone under 18 (managed by a parent/guardian)
              </span>
            </label>

            {isMinor && (
              <div className="space-y-3 rounded-xl border border-border bg-dark p-4">
                <p className="text-sm font-bold text-teal">Parent / Guardian Details</p>
                <p className="text-xs text-muted">
                  All account communications will go to the guardian.
                </p>
                <input
                  value={guardianName}
                  onChange={(e) => setGuardianName(e.target.value)}
                  placeholder="Guardian full name"
                  className={inputClass()}
                />
                <input
                  type="email"
                  value={guardianEmail}
                  onChange={(e) => setGuardianEmail(e.target.value)}
                  placeholder="parent@example.com"
                  className={inputClass()}
                />
              </div>
            )}

            {error && (
              <div className="flex items-start gap-2 rounded-xl border border-red-500/30 bg-red-500/10 p-3 text-sm text-red-400">
                <span aria-hidden><i className="bi bi-exclamation-triangle-fill" /></span>
                <span>{error}</span>
              </div>
            )}

            {/* Terms */}
            <label className="flex cursor-pointer items-start gap-3">
              <input
                type="checkbox"
                checked={acceptTerms}
                onChange={(e) => setAcceptTerms(e.target.checked)}
                className="mt-0.5 h-4 w-4 accent-teal"
              />
              <span className="text-xs leading-relaxed text-muted">
                I agree to the{" "}
                <span className="font-semibold text-teal">Terms of Service</span> and{" "}
                <span className="font-semibold text-teal">Privacy Policy</span>
              </span>
            </label>

            <button
              type="submit"
              disabled={loading}
              className="btn-primary w-full disabled:opacity-50"
            >
              {loading ? "Creating account…" : "Create account"}
            </button>
          </form>
        </div>
      </div>
    </section>
  );
}
