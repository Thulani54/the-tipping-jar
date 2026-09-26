"use client";
import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  ArrowRight,
  Eye,
  EyeOff,
  LockKeyhole,
  AlertCircle,
} from "lucide-react";
import { useAuth } from "@/lib/auth";
import { AuthShell } from "@/components/AuthShell";
export default function LoginPage() {
  const { login, loading } = useAuth();
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  async function handleSubmit(event: React.FormEvent) {
    event.preventDefault();
    setError(null);
    if (!email.includes("@") || !password) {
      setError("Enter your email address and password.");
      return;
    }
    try {
      const user = await login(email.trim(), password);
      router.push(
        user.role === "admin"
          ? "/admin-portal"
          : user.role === "enterprise"
            ? "/enterprise-portal"
            : user.role === "creator"
              ? "/dashboard"
              : "/fan-dashboard",
      );
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : "Sign in failed. Please try again.",
      );
    }
  }
  return (
    <AuthShell
      title="Your people. Your passion. Your next chapter."
      description="Pick up where you left off. A little support can make a big difference."
    >
      <div className="tj-auth-form">
        <span className="tj-auth-form-icon">
          <LockKeyhole size={23} />
        </span>
        <p className="tj-auth-kicker">Welcome back</p>
        <h2>Good to see you again.</h2>
        <p className="tj-auth-subtitle">Sign in to your Tipping Jar account.</p>
        <form onSubmit={handleSubmit} className="tj-login-form">
          <div>
            <label htmlFor="login-email">Email address</label>
            <input
              id="login-email"
              type="email"
              autoComplete="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="you@example.com"
            />
          </div>
          <div>
            <label htmlFor="login-password">Password</label>
            <div className="tj-password-field">
              <input
                id="login-password"
                type={showPassword ? "text" : "password"}
                autoComplete="current-password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Enter your password"
              />
              <button
                type="button"
                aria-label={showPassword ? "Hide password" : "Show password"}
                aria-pressed={showPassword}
                onClick={() => setShowPassword(!showPassword)}
              >
                {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
          </div>
          {error && (
            <div className="tj-auth-error" role="alert">
              <AlertCircle size={18} />
              {error}
            </div>
          )}
          <button type="submit" disabled={loading} className="tj-auth-submit">
            {loading ? "Signing in…" : "Sign in"}
            <ArrowRight size={18} />
          </button>
        </form>
        <p className="tj-auth-switch">
          New here?{" "}
          <Link href="/register">
            Create your account <ArrowUpRightSmall />
          </Link>
        </p>
        <div className="tj-auth-bottom-note">
          <LockKeyhole size={14} />
          <span>Your account. Your community. All in one place.</span>
        </div>
      </div>
    </AuthShell>
  );
}
function ArrowUpRightSmall() {
  return (
    <svg aria-hidden width="13" height="13" viewBox="0 0 16 16" fill="none">
      <path d="M4 12 12 4M4 4h8v8" stroke="currentColor" strokeWidth="1.5" />
    </svg>
  );
}
