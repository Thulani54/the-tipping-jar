"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";

const LENGTH = 6;

export default function OtpVerifyPage() {
  const router = useRouter();
  const { user, token, initialized, isAuthenticated } = useAuth();

  const [digits, setDigits] = useState<string[]>(Array(LENGTH).fill(""));
  const [error, setError] = useState<string | null>(null);
  const [info, setInfo] = useState<string | null>(null);
  const [verifying, setVerifying] = useState(false);
  const [resending, setResending] = useState(false);
  const [cooldown, setCooldown] = useState(0);
  const inputs = useRef<(HTMLInputElement | null)[]>([]);
  const requested = useRef(false);

  // Send an initial code once we have a session.
  useEffect(() => {
    if (!initialized) return;
    if (!isAuthenticated || !token) {
      router.push("/login");
      return;
    }
    if (requested.current) return;
    requested.current = true;
    api
      .requestOtp(token)
      .then(() => {
        setInfo("A one-time code has been sent.");
        setCooldown(60);
      })
      .catch(() => setError("Couldn't send a code — try Resend."));
  }, [initialized, isAuthenticated, token, router]);

  useEffect(() => {
    if (cooldown <= 0) return;
    const t = setInterval(() => setCooldown((c) => (c <= 1 ? 0 : c - 1)), 1000);
    return () => clearInterval(t);
  }, [cooldown]);

  const code = digits.join("");
  const target = user?.email ?? "your email";

  function setDigit(index: number, value: string) {
    const char = value.replace(/\D/g, "").slice(-1);
    setDigits((prev) => {
      const next = [...prev];
      next[index] = char;
      return next;
    });
    if (error) setError(null);
    if (char && index < LENGTH - 1) inputs.current[index + 1]?.focus();
  }

  function handleKeyDown(index: number, e: React.KeyboardEvent<HTMLInputElement>) {
    if (e.key === "Backspace" && !digits[index] && index > 0) {
      inputs.current[index - 1]?.focus();
    }
  }

  function handlePaste(e: React.ClipboardEvent<HTMLInputElement>) {
    e.preventDefault();
    const pasted = e.clipboardData.getData("text").replace(/\D/g, "").slice(0, LENGTH);
    if (!pasted) return;
    const next = Array(LENGTH).fill("");
    pasted.split("").forEach((c, i) => (next[i] = c));
    setDigits(next);
    inputs.current[Math.min(pasted.length, LENGTH - 1)]?.focus();
  }

  async function verify() {
    if (!token) return;
    if (code.length !== LENGTH) {
      setError("Enter the 6-digit code.");
      return;
    }
    setVerifying(true);
    setError(null);
    try {
      await api.verifyOtp(token, code);
      router.push("/dashboard");
    } catch {
      setError("Invalid or expired code. Try again or resend.");
      setVerifying(false);
    }
  }

  async function resend() {
    if (cooldown > 0 || resending || !token) return;
    setResending(true);
    setError(null);
    try {
      await api.requestOtp(token);
      setInfo("A new code has been sent.");
      setCooldown(60);
    } catch {
      setError("Couldn't resend — try again shortly.");
    } finally {
      setResending(false);
    }
  }

  return (
    <section className="container-content flex min-h-[70vh] items-center justify-center py-16">
      <div className="w-full max-w-md">
        <div className="card">
          <div className="mx-auto grid h-16 w-16 place-items-center rounded-full bg-primary/15 text-3xl">
            ✉️
          </div>
          <h1 className="mt-6 text-center text-2xl font-extrabold tracking-tight text-white">
            Check your email
          </h1>
          <p className="body-muted mt-2 text-center">
            We sent a 6-digit code to{" "}
            <span className="font-semibold text-white">{target}</span>.
          </p>

          <div className="mt-8">
            <label className="mb-3 block text-center text-sm font-semibold text-white">
              Verification code
            </label>
            <div className="flex justify-center gap-2.5">
              {digits.map((d, i) => (
                <input
                  key={i}
                  ref={(el) => {
                    inputs.current[i] = el;
                  }}
                  type="text"
                  inputMode="numeric"
                  maxLength={1}
                  value={d}
                  onChange={(e) => setDigit(i, e.target.value)}
                  onKeyDown={(e) => handleKeyDown(i, e)}
                  onPaste={handlePaste}
                  className="h-14 w-11 rounded-xl border border-border bg-dark text-center text-2xl font-bold text-white focus:border-teal focus:outline-none focus:ring-2 focus:ring-teal/30"
                />
              ))}
            </div>
          </div>

          {info && !error && (
            <p className="mt-4 text-center text-xs text-muted">{info}</p>
          )}
          {error && (
            <div className="mt-4 flex items-center justify-center gap-2 rounded-xl border border-red-500/30 bg-red-500/10 p-3 text-sm text-red-400">
              <span aria-hidden>⚠</span>
              <span>{error}</span>
            </div>
          )}

          <button
            type="button"
            onClick={verify}
            disabled={verifying}
            className="btn-primary mt-6 w-full disabled:opacity-50"
          >
            {verifying ? "Verifying…" : "Verify"}
          </button>

          <div className="mt-5 text-center">
            {cooldown > 0 ? (
              <span className="text-sm text-muted">Resend code in {cooldown}s</span>
            ) : (
              <button
                type="button"
                onClick={resend}
                disabled={resending}
                className="text-sm font-semibold text-teal hover:underline disabled:opacity-50"
              >
                {resending ? "Sending…" : "Resend code"}
              </button>
            )}
          </div>
        </div>
      </div>
    </section>
  );
}
