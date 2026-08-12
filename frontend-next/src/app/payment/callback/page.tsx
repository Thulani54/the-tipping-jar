"use client";

import { Suspense, useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { api } from "@/lib/api";
import type { Creator } from "@/types";

type Status = "loading" | "completed" | "failed" | "pending" | "error";

function CallbackInner() {
  const searchParams = useSearchParams();
  const creatorSlug = searchParams.get("creator_slug");
  const forcedStatus = searchParams.get("status"); // testing override

  // PayCloud returns our order id under one of several names; we also always
  // inject it ourselves as `ref` on the return URL (server-side, in checkout)
  // — plus scan any value that looks like one of our references (tj… / rf…).
  const reference = useMemo(() => {
    const known = [
      "ref",
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
  const [creator, setCreator] = useState<Creator | null>(null);

  useEffect(() => {
    if (creatorSlug) {
      api.getCreator(creatorSlug).then(setCreator).catch(() => null);
    }
  }, [creatorSlug]);

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

    // Poll by RECONCILING with the gateway: the backend asks PayCloud for the
    // order's real status and syncs our record (the signed webhook remains the
    // primary completion path — this covers missed/late notifies and orders
    // that never notify because the card step was abandoned).
    let tries = 0;
    async function poll() {
      try {
        const r = await api.reconcilePayment(reference);
        if (!alive) return;
        if (r.status === "completed") return setStatus("completed");
        if (r.status === "failed") return setStatus("failed");
      } catch {
        // not found yet / transient — fall back to a plain read
        try {
          const t = await api.getPayment(reference);
          if (!alive) return;
          if (t.status === "completed") return setStatus("completed");
          if (t.status === "failed") return setStatus("failed");
        } catch {
          /* keep polling */
        }
      }
      tries += 1;
      // Poll for ~60s total — 3D-Secure OTP + gateway settlement can eat 30s+
      // before the notify arrives. Backoff: 2s, 2s, 3s, 3s, 4s, 5s, 6s, 8s,
      // 10s, 15s → ~58s cumulative.
      if (tries >= 10) {
        if (alive) setStatus("pending");
        return;
      }
      const delays = [2000, 2000, 3000, 3000, 4000, 5000, 6000, 8000, 10000, 15000];
      window.setTimeout(poll, delays[tries - 1] ?? 5000);
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
          Your tip has been sent{creator ? ` to ${creator.display_name}` : ""}. The creator will love it!
        </p>
        {creator?.thanks_note && (
          <blockquote className="mx-auto mt-4 max-w-sm rounded-2xl border border-mint/40 bg-mint/10 px-5 py-4 text-sm text-ink">
            &ldquo;{creator.thanks_note}&rdquo;
            <footer className="mt-1.5 text-xs text-muted">— {creator.display_name}</footer>
          </blockquote>
        )}
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
