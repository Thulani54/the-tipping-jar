"use client";

// File a dispute — ported from frontend/lib/screens/dispute_screen.dart
// Posts to api.createDispute and shows the returned reference + tracking token.

import { useState } from "react";
import Link from "next/link";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import type { Dispute } from "@/types";

const REASONS: [string, string][] = [
  ["tip_not_received", "Tip Not Received by Creator"],
  ["wrong_amount", "Wrong Amount Charged"],
  ["unauthorized", "Unauthorized Transaction"],
  ["payout_issue", "Payout / Withdrawal Issue"],
  ["account_access", "Account Access Problem"],
  ["other", "Other"],
];

export default function DisputePage() {
  const { user } = useAuth();
  const [name, setName] = useState(user?.username ?? "");
  const [email, setEmail] = useState(user?.email ?? "");
  const [reason, setReason] = useState("other");
  const [tipRef, setTipRef] = useState("");
  const [description, setDescription] = useState("");

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<{ reference: string; token: string; dispute: Dispute } | null>(
    null,
  );
  const [copied, setCopied] = useState(false);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    if (!name.trim() || !email.includes("@")) {
      setError("Please provide your name and a valid email.");
      return;
    }
    if (description.trim().length < 20) {
      setError("Please describe what happened in at least 20 characters.");
      return;
    }
    setLoading(true);
    try {
      const res = await api.createDispute({
        name: name.trim(),
        email: email.trim(),
        reason,
        description: description.trim(),
        tip_ref: tipRef.trim() || undefined,
      });
      setResult(res);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  if (result) {
    return (
      <div className="container-content flex justify-center py-20">
        <div className="w-full max-w-lg">
          <div className="card !border-yellow-400/30 text-center">
            <div className="mx-auto grid h-16 w-16 place-items-center rounded-full bg-yellow-400/15 text-3xl text-yellow-500">
              <i className="bi bi-clipboard-check" />
            </div>
            <h1 className="mt-6 text-2xl font-extrabold tracking-tight text-ink">
              Dispute filed successfully
            </h1>
            <p className="body-muted mt-2">
              Keep your reference and tracking token safe — you can check your case status any time.
            </p>

            <div className="mt-6 space-y-3 text-left">
              <div className="rounded-xl border border-yellow-400/30 bg-[#0D1A14] p-4">
                <p className="text-xs font-semibold uppercase tracking-wide text-muted">
                  Reference number
                </p>
                <div className="mt-1 flex items-center justify-between gap-3">
                  <span className="font-mono text-lg font-bold text-yellow-400">
                    {result.reference}
                  </span>
                  <button
                    onClick={() => {
                      navigator.clipboard?.writeText(result.reference);
                      setCopied(true);
                      setTimeout(() => setCopied(false), 2000);
                    }}
                    className="rounded-lg border border-border px-3 py-1.5 text-xs font-semibold text-muted hover:border-teal hover:text-teal"
                  >
                    {copied ? "Copied" : "Copy"}
                  </button>
                </div>
              </div>
              <div className="rounded-xl border border-border bg-card p-4">
                <p className="text-xs font-semibold uppercase tracking-wide text-muted">
                  Tracking token
                </p>
                <p className="mt-1 break-all font-mono text-sm text-ink">{result.token}</p>
              </div>
            </div>

            <Link
              href={`/dispute/${result.token}`}
              className="btn-primary mt-6 inline-flex w-full"
            >
              Track my dispute →
            </Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <>
      {/* Header */}
      <section className="border-b border-border bg-darker">
        <div className="container-content py-16 text-center">
          <span className="inline-block rounded-full border border-yellow-400/30 bg-yellow-400/10 px-4 py-1.5 text-xs font-semibold text-yellow-400">
            Dispute Centre · tippingjar.co.za
          </span>
          <h1 className="heading-xl mt-5">File a dispute</h1>
          <p className="body-muted mx-auto mt-4 max-w-lg">
            Tell us what went wrong. You&apos;ll receive a tracking link by email so you can follow
            your case.
          </p>
        </div>
      </section>

      {/* Form */}
      <section className="container-content flex justify-center py-14">
        <form onSubmit={submit} className="w-full max-w-2xl space-y-5">
          <div className="rounded-xl border border-teal/25 bg-teal/5 p-4 text-sm text-muted">
            Already filed a dispute? Check your email for the tracking link, or open{" "}
            <span className="text-teal">tippingjar.co.za/dispute/&#123;your-token&#125;</span>.
          </div>

          <h2 className="text-base font-bold text-ink">Your details</h2>
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="Full name" value={name} onChange={setName} />
            <Field label="Email address" value={email} onChange={setEmail} type="email" />
          </div>

          <h2 className="pt-2 text-base font-bold text-ink">Dispute details</h2>
          <label className="block">
            <span className="mb-1.5 block text-xs font-medium text-muted">Reason</span>
            <select
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              className="w-full rounded-xl border border-border bg-card px-4 py-3 text-sm text-ink focus:border-teal focus:outline-none"
            >
              {REASONS.map(([val, lbl]) => (
                <option key={val} value={val} className="bg-card">
                  {lbl}
                </option>
              ))}
            </select>
          </label>

          <Field
            label="Tip ID / Payment reference (optional)"
            value={tipRef}
            onChange={setTipRef}
          />

          <label className="block">
            <span className="mb-1.5 block text-xs font-medium text-muted">
              Describe what happened in detail…
            </span>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={6}
              className="w-full rounded-xl border border-border bg-card px-4 py-3 text-sm text-ink placeholder:text-muted focus:border-teal focus:outline-none"
            />
          </label>

          {error && (
            <div className="rounded-lg border border-red-400/30 bg-red-400/10 p-3 text-sm text-red-400">
              {error}
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="inline-flex w-full items-center justify-center rounded-full bg-yellow-400 px-6 py-3.5 font-bold text-darker transition hover:opacity-90 disabled:opacity-60"
          >
            {loading ? "Submitting…" : "Submit dispute"}
          </button>
        </form>
      </section>
    </>
  );
}

function Field({
  label,
  value,
  onChange,
  type = "text",
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  type?: string;
}) {
  return (
    <label className="block">
      <span className="mb-1.5 block text-xs font-medium text-muted">{label}</span>
      <input
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="w-full rounded-xl border border-border bg-card px-4 py-3 text-sm text-ink placeholder:text-muted focus:border-teal focus:outline-none"
      />
    </label>
  );
}
