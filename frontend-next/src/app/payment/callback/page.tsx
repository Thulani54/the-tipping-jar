"use client";

import { Suspense, useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { api } from "@/lib/api";

type Status = "loading" | "completed" | "failed" | "pending" | "error";

function CallbackInner() {
  const searchParams = useSearchParams();
  const creatorSlug = searchParams.get("creator_slug");
  const forcedStatus = searchParams.get("status"); // testing override

  // PayCloud returns our order id under one of several names; also scan any
  // value that looks like one of our references (tj… / rf…).
  const reference = useMemo(() => {
    const known = [
      "reference",
      "trxref",
      "merchant_order_no",
      "out_trade_no",
      "orderNo",
      "order_no",
      "tn",
    ];
    for (const k of known) {
      const v = searchParams.get(k);
      if (v) return v;
    }
    for (const [, v] of searchParams.entries()) {
      if (/^(tj|rf)[a-f0-9]{6,}/i.test(v)) return v;
    }
    return "";
  }, [searchParams]);

  const [status, setStatus] = useState<Status>("loading");

  useEffect(() => {
    let alive = true;

    if (forcedStatus === "completed" || forcedStatus === "failed" || forcedStatus === "pending") {
      setStatus(forcedStatus as Status);
      return;
    }
    if (!reference) {
      // We returned from PayCloud but can't identify the order — the payment
      // most likely went through; the signed webhook confirms it server-side.
      setStatus("pending");
      return;
    }

    // Poll our backend for the real transaction status (the webhook flips it
    // pending → completed shortly after payment).
    let tries = 0;
    async function poll() {
      try {
        const t = await api.getPayment(reference);
        if (!alive) return;
        if (t.status === "completed") return setStatus("completed");
        if (t.status === "failed") return setStatus("failed");
      } catch {
        // not found yet / transient — keep polling
      }
      tries += 1;
      if (tries >= 8) {
        if (alive) setStatus("pending");
        return;
      }
      window.setTimeout(poll, 2000);
    }
    setStatus("loading");
    poll();

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
        <IconCircle icon="bi-heart-fill" tone="teal" />
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
        <IconCircle icon="bi-exclamation-triangle-fill" tone="red" />
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
        <IconCircle icon="bi-hourglass-split" tone="amber" />
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
      <IconCircle icon="bi-wifi-off" tone="muted" />
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
  icon,
  tone,
}: {
  icon: string;
  tone: "teal" | "red" | "amber" | "muted";
}) {
  const bg = {
    teal: "bg-teal/12 text-teal",
    red: "bg-red-500/12 text-red-500",
    amber: "bg-amber-500/12 text-amber-500",
    muted: "bg-card text-muted",
  }[tone];
  return (
    <div
      className={`mx-auto grid h-16 w-16 place-items-center rounded-full text-3xl ${bg}`}
    >
      <i className={`bi ${icon}`} />
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
