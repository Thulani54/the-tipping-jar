// Dispute tracking — ported from the DisputeTrackingScreen in dispute_screen.dart
// Async server component: fetches the dispute by token and shows a status timeline.

import Link from "next/link";
import { api } from "@/lib/api";
import type { Dispute } from "@/types";

const REASON_LABELS: Record<string, string> = {
  tip_not_received: "Tip Not Received by Creator",
  wrong_amount: "Wrong Amount Charged",
  unauthorized: "Unauthorized Transaction",
  payout_issue: "Payout / Withdrawal Issue",
  account_access: "Account Access Problem",
  other: "Other",
};

const STATUS_LABELS: Record<string, string> = {
  open: "Open",
  investigating: "Under Investigation",
  resolved: "Resolved",
  closed: "Closed",
};

const STEPS: [string, string, string][] = [
  ["open", "Opened", "Dispute received and queued for review"],
  ["investigating", "Under Investigation", "Our team is reviewing your case"],
  ["resolved", "Resolved", "A resolution has been reached"],
  ["closed", "Closed", "Case closed"],
];

const ACTIVE_INDEX: Record<string, number> = {
  open: 0,
  investigating: 1,
  resolved: 2,
  closed: 3,
};

function fmt(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso || "—";
  return d.toLocaleString("en-ZA", {
    day: "numeric",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export default async function DisputeTrackingPage({
  params,
}: {
  params: Promise<{ token: string }>;
}) {
  const { token } = await params;

  let dispute: Dispute | null = null;
  try {
    dispute = await api.trackDispute(token);
  } catch {
    dispute = null;
  }

  if (!dispute) {
    return (
      <div className="container-content grid min-h-[60vh] place-items-center text-center">
        <div>
          <div className="text-4xl">🔎</div>
          <h1 className="mt-4 text-2xl font-bold text-white">Dispute not found</h1>
          <p className="body-muted mx-auto mt-2 max-w-sm">
            Please check your tracking link — it may be incorrect or expired.
          </p>
          <Link href="/dispute" className="btn-primary mt-6 inline-flex">
            File a dispute
          </Link>
        </div>
      </div>
    );
  }

  const active = ACTIVE_INDEX[dispute.status] ?? 0;
  const statusLabel = STATUS_LABELS[dispute.status] ?? dispute.status;
  const details: [string, string][] = [
    ["Name", dispute.name],
    ["Email", dispute.email],
    ["Reason", REASON_LABELS[dispute.reason] ?? dispute.reason],
    ...(dispute.tip_ref ? ([["Tip reference", dispute.tip_ref]] as [string, string][]) : []),
    ["Filed on", fmt(dispute.created_at)],
  ];

  return (
    <div className="container-content flex justify-center py-14">
      <div className="w-full max-w-2xl">
        <Link href="/contact" className="text-sm text-muted hover:text-white">
          ‹ Support
        </Link>

        <div className="mt-6 flex flex-wrap items-start justify-between gap-4">
          <div>
            <p className="font-mono text-xs font-bold text-yellow-400">
              {/* Dispute type exposes token; reference is not in the shape */}
              {dispute.token}
            </p>
            <h1 className="mt-1 text-2xl font-extrabold tracking-tight text-white">
              Dispute details
            </h1>
          </div>
          <StatusBadge status={dispute.status} label={statusLabel} />
        </div>

        {/* Timeline */}
        <div className="card mt-8">
          <ol>
            {STEPS.map(([key, title, sub], i) => {
              const done = i < active;
              const current = i === active;
              return (
                <li key={key} className="flex gap-4">
                  <div className="flex flex-col items-center">
                    <div
                      className={`grid h-6 w-6 place-items-center rounded-full border-2 text-[10px] ${
                        done
                          ? "border-primary bg-primary text-white"
                          : current
                            ? "border-primary bg-primary/15 text-teal"
                            : "border-muted/30 bg-card text-transparent"
                      }`}
                    >
                      {done ? "✓" : current ? "●" : ""}
                    </div>
                    {i < STEPS.length - 1 && (
                      <div className={`w-0.5 flex-1 ${i < active ? "bg-primary" : "bg-muted/20"}`} />
                    )}
                  </div>
                  <div className={`pb-6 ${i === STEPS.length - 1 ? "pb-0" : ""}`}>
                    <p
                      className={`text-sm font-semibold ${
                        done || current ? "text-white" : "text-muted"
                      }`}
                    >
                      {title}
                    </p>
                    <p className="mt-0.5 text-xs text-muted">{sub}</p>
                  </div>
                </li>
              );
            })}
          </ol>
        </div>

        {/* Case details */}
        <div className="card mt-4">
          <p className="text-xs font-bold uppercase tracking-widest text-muted">Case details</p>
          <dl className="mt-4 space-y-3">
            {details.map(([label, value]) => (
              <div key={label} className="flex gap-4">
                <dt className="w-32 shrink-0 text-sm text-muted">{label}</dt>
                <dd className="text-sm text-white">{value}</dd>
              </div>
            ))}
          </dl>
        </div>

        {/* Description */}
        <div className="card mt-4">
          <p className="text-xs font-bold uppercase tracking-widest text-muted">Description</p>
          <p className="mt-3 whitespace-pre-line text-sm leading-relaxed text-white">
            {dispute.description}
          </p>
        </div>

        <p className="mt-8 text-center text-xs text-muted">
          Need help? Email support@tippingjar.co.za with your token {dispute.token}
        </p>
      </div>
    </div>
  );
}

function StatusBadge({ status, label }: { status: string; label: string }) {
  const color =
    status === "open"
      ? "border-yellow-400/40 bg-yellow-400/10 text-yellow-400"
      : status === "investigating"
        ? "border-teal/40 bg-teal/10 text-teal"
        : status === "resolved"
          ? "border-primary/40 bg-primary/15 text-teal"
          : "border-border bg-card text-muted";
  return (
    <span className={`rounded-full border px-3 py-1.5 text-xs font-bold ${color}`}>{label}</span>
  );
}
