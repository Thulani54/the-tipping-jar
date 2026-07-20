"use client";

import { Suspense, useEffect, useState } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";

type Status = "loading" | "completed" | "failed" | "pending" | "error";

function CallbackInner() {
  const searchParams = useSearchParams();
  // Paystack redirects back with ?reference=… (or ?trxref=…).
  const reference =
    searchParams.get("reference") ?? searchParams.get("trxref") ?? "";
  // Allow ?status=completed|failed|pending for testing the various states.
  const forcedStatus = searchParams.get("status");
  const creatorSlug = searchParams.get("creator_slug");

  const [status, setStatus] = useState<Status>("loading");

  useEffect(() => {
    let alive = true;

    async function verify() {
      setStatus("loading");
      // TODO(api): verify payment reference — no verify endpoint exists in the
      // /api/v2 client yet. This simulates the verification round-trip and
      // resolves from the query params. Replace with api.verifyTip(reference).
      await new Promise((r) => setTimeout(r, 1200));
      if (!alive) return;

      if (!reference && !forcedStatus) {
        setStatus("error");
        return;
      }
      if (forcedStatus === "completed") return setStatus("completed");
      if (forcedStatus === "failed") return setStatus("failed");
      if (forcedStatus === "pending") return setStatus("pending");
      // Default: with a reference but no confirmed status, treat as completed
      // (the placeholder happy path). Real logic would poll the verify endpoint.
      setStatus(reference ? "completed" : "pending");
    }

    verify();
    return () => {
      alive = false;
    };
  }, [reference, forcedStatus]);

  if (status === "loading") {
    return (
      <Shell>
        <div className="mx-auto h-10 w-10 animate-spin rounded-full border-2 border-border border-t-teal" />
        <p className="mt-5 text-muted">Confirming your payment…</p>
      </Shell>
    );
  }

  if (status === "completed") {
    return (
      <Shell>
        <IconCircle emoji="💚" tone="teal" />
        <h1 className="mt-6 text-2xl font-extrabold">Payment received!</h1>
        <p className="body-muted mx-auto mt-3 max-w-sm">
          Your tip has been sent. The creator will love it!
        </p>
        {reference && (
          <p className="mt-4 font-mono text-xs text-muted">Ref: {reference}</p>
        )}
        <Link href="/" className="btn-primary mt-8 w-full">
          Back to TippingJar
        </Link>
      </Shell>
    );
  }

  if (status === "failed") {
    return (
      <Shell>
        <IconCircle emoji="⚠️" tone="red" />
        <h1 className="mt-6 text-2xl font-extrabold">
          Payment was not completed
        </h1>
        <p className="body-muted mx-auto mt-3 max-w-sm">
          Your card was not charged. This can happen if the payment window was
          closed, the card was declined, or the session timed out.
        </p>
        <div className="mt-8 flex w-full flex-col gap-3">
          {creatorSlug && (
            <Link href={`/creator/${creatorSlug}`} className="btn-primary w-full">
              Try again
            </Link>
          )}
          <Link href="/" className="btn-ghost w-full">
            Go home
          </Link>
        </div>
      </Shell>
    );
  }

  if (status === "pending") {
    return (
      <Shell>
        <IconCircle emoji="⏳" tone="amber" />
        <h1 className="mt-6 text-2xl font-extrabold">
          Payment still processing
        </h1>
        <p className="body-muted mx-auto mt-3 max-w-sm">
          Your payment is taking a bit longer than usual. If your card was
          charged, the tip will be confirmed shortly.
        </p>
        <button
          onClick={() => window.location.reload()}
          className="btn-primary mt-8 w-full"
        >
          Check again
        </button>
        <Link href="/" className="btn-ghost mt-3 w-full">
          Go home
        </Link>
      </Shell>
    );
  }

  // error
  return (
    <Shell>
      <IconCircle emoji="📡" tone="muted" />
      <h1 className="mt-6 text-2xl font-extrabold">
        Could not reach the server
      </h1>
      <p className="body-muted mx-auto mt-3 max-w-sm">
        Check your connection and try again.
      </p>
      <button
        onClick={() => window.location.reload()}
        className="btn-primary mt-8 w-full"
      >
        Retry
      </button>
      <Link href="/" className="btn-ghost mt-3 w-full">
        Go home
      </Link>
    </Shell>
  );
}

function Shell({ children }: { children: React.ReactNode }) {
  return (
    <section className="container-content grid min-h-[70vh] place-items-center py-24">
      <div className="w-full max-w-md text-center">{children}</div>
    </section>
  );
}

function IconCircle({
  emoji,
  tone,
}: {
  emoji: string;
  tone: "teal" | "red" | "amber" | "muted";
}) {
  const bg = {
    teal: "bg-teal/12",
    red: "bg-red-500/12",
    amber: "bg-amber-500/12",
    muted: "bg-card",
  }[tone];
  return (
    <div
      className={`mx-auto grid h-16 w-16 place-items-center rounded-full text-3xl ${bg}`}
    >
      {emoji}
    </div>
  );
}

export default function PaymentCallbackPage() {
  return (
    <Suspense
      fallback={
        <Shell>
          <div className="mx-auto h-10 w-10 animate-spin rounded-full border-2 border-border border-t-teal" />
        </Shell>
      }
    >
      <CallbackInner />
    </Suspense>
  );
}
