"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useAuth } from "@/lib/auth";

const BENEFITS = [
  "Real-time tip notifications",
  "Receive money within 2 days",
  "Live fan activity dashboard",
];

export default function LoginPage() {
  const { login, loading } = useAuth();
  const router = useRouter();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    if (!email.includes("@")) {
      setError("Enter a valid email");
      return;
    }
    if (password.length < 8) {
      setError("Min 8 characters");
      return;
    }
    try {
      await login(email.trim(), password);
      router.push("/dashboard");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Sign in failed. Try again.");
    }
  }

  return (
    <section className="container-content grid items-center gap-16 py-16 lg:grid-cols-2 lg:py-24">
      {/* Branding panel */}
      <div className="hidden lg:block">
        <span className="inline-block rounded-full border border-border bg-card px-4 py-1.5 text-sm text-teal">
          Welcome back
        </span>
        <h1 className="heading-xl mt-6 max-w-md">
          Welcome{" "}
          <span className="bg-brand-gradient bg-clip-text text-transparent">
            back.
          </span>
        </h1>
        <p className="body-muted mt-5 max-w-md text-lg">
          Sign in to manage your tip page, track earnings, and connect with fans.
        </p>
        <ul className="mt-10 space-y-4">
          {BENEFITS.map((b) => (
            <li key={b} className="flex items-center gap-3">
              <span className="grid h-6 w-6 place-items-center rounded-full bg-primary/20 text-sm text-teal">
                <i className="bi bi-check-lg" />
              </span>
              <span className="font-medium text-ink">{b}</span>
            </li>
          ))}
        </ul>
      </div>

      {/* Form card */}
      <div className="mx-auto w-full max-w-md">
        <div className="card">
          <h2 className="text-2xl font-extrabold tracking-tight text-ink">
            Sign in to your account
          </h2>
          <p className="body-muted mt-2">
            Don&apos;t have an account?{" "}
            <Link href="/register" className="font-semibold text-teal hover:underline">
              Sign up
            </Link>
          </p>

          <form onSubmit={handleSubmit} className="mt-8 space-y-5">
            <div>
              <label className="mb-2 block text-sm font-semibold text-ink">
                Email address
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="you@example.com"
                autoComplete="email"
                className="w-full rounded-xl border border-border bg-dark px-4 py-3 text-sm text-ink placeholder:text-muted focus:border-teal focus:outline-none focus:ring-2 focus:ring-teal/30"
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
                autoComplete="current-password"
                className="w-full rounded-xl border border-border bg-dark px-4 py-3 text-sm text-ink placeholder:text-muted focus:border-teal focus:outline-none focus:ring-2 focus:ring-teal/30"
              />
              <div className="mt-2 text-right">
                <span className="text-xs font-medium text-teal">Forgot password?</span>
              </div>
            </div>

            {error && (
              <div className="flex items-start gap-2 rounded-xl border border-red-500/30 bg-red-500/10 p-3 text-sm text-red-400">
                <span aria-hidden><i className="bi bi-exclamation-triangle-fill" /></span>
                <span>{error}</span>
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="btn-primary w-full disabled:opacity-50"
            >
              {loading ? "Signing in…" : "Sign in"}
            </button>
          </form>

          <div className="my-6 flex items-center gap-3">
            <span className="h-px flex-1 bg-border" />
            <span className="text-xs text-muted">or continue with</span>
            <span className="h-px flex-1 bg-border" />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <button
              type="button"
              className="btn-ghost !py-2.5 text-sm"
              onClick={() => setError("Google sign-in coming soon!")}
            >
              Google
            </button>
            <button
              type="button"
              className="btn-ghost !py-2.5 text-sm"
              onClick={() => setError("GitHub sign-in coming soon!")}
            >
              GitHub
            </button>
          </div>
        </div>
      </div>
    </section>
  );
}
