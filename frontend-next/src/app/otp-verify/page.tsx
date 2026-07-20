"use client";

import Link from "next/link";
import { useAuth } from "@/lib/auth";

// NOTE: The /api/v2 backend does not yet implement two-factor / OTP
// verification, and login already fully authenticates the user. This page must
// therefore NOT present a code-entry UI that "verifies" any input — that would
// be security theatre / a fake auth gate. It is an honest placeholder until a
// real, server-verified OTP endpoint exists.
export default function OtpVerifyPage() {
  const { user, isAuthenticated } = useAuth();
  const target = user?.email ?? "your email";

  return (
    <section className="container-content flex min-h-[70vh] items-center justify-center py-16">
      <div className="w-full max-w-md">
        <div className="card text-center">
          <div className="mx-auto grid h-16 w-16 place-items-center rounded-full bg-primary/15 text-3xl">
            🛡️
          </div>

          <h1 className="mt-6 text-2xl font-extrabold tracking-tight text-white">
            Two-factor verification
          </h1>

          <div className="mt-5 rounded-xl border border-yellow-500/30 bg-yellow-500/10 p-4 text-left text-sm text-yellow-200">
            <p className="font-semibold">Not enabled yet</p>
            <p className="mt-1 text-yellow-200/80">
              Email/SMS 2-factor verification isn&apos;t active on the new
              platform yet. When it launches, a real one-time code will be sent
              to <span className="font-semibold text-white">{target}</span> and
              verified by the server before you can continue. This screen is a
              placeholder — it does not grant access on its own.
            </p>
          </div>

          <div className="mt-7 flex flex-col gap-3">
            {isAuthenticated ? (
              <Link href="/dashboard" className="btn-primary w-full">
                Continue to dashboard
              </Link>
            ) : (
              <Link href="/login" className="btn-primary w-full">
                Go to login
              </Link>
            )}
            <Link href="/" className="btn-ghost w-full">
              Back to home
            </Link>
          </div>
        </div>
      </div>
    </section>
  );
}
