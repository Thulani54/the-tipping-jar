import type { ReactNode } from "react";

// Shared marketing-page hero — the landing page's navy stage in a compact
// form: eyebrow + headline + sub, floating blob/sparkle decorations, and the
// white wave hand-off into the page body. Server-safe (pure markup).
export function PageHero({
  eyebrow,
  title,
  sub,
  children,
}: {
  eyebrow: string;
  title: ReactNode;
  sub?: ReactNode;
  children?: ReactNode;
}) {
  return (
    <section className="relative overflow-hidden bg-navy">
      <span aria-hidden className="blob pointer-events-none absolute -left-10 top-16 h-40 w-40 rounded-full bg-mint/20" />
      <span aria-hidden className="blob pointer-events-none absolute -bottom-14 right-[16%] h-48 w-48 rounded-full bg-green/20" style={{ animationDelay: "-8s" }} />
      <span aria-hidden className="sparkle pointer-events-none absolute right-[26%] top-14 h-2.5 w-2.5 rounded-full bg-gold/80" />
      <span aria-hidden className="sparkle pointer-events-none absolute bottom-16 left-[20%] h-3 w-3 rounded-full bg-mint/70" style={{ animationDelay: "0.8s" }} />

      <div className="container-content relative py-14 text-center md:py-20">
        <p className="eyebrow !text-mint rise-in">{eyebrow}</p>
        <h1
          className="rise-in mx-auto mt-4 max-w-2xl font-display text-4xl font-extrabold leading-[1.05] tracking-[-0.02em] md:text-5xl"
          style={{ animationDelay: "0.05s" }}
        >
          {title}
        </h1>
        {sub && (
          <p
            className="rise-in mx-auto mt-5 max-w-xl text-lg leading-relaxed opacity-80"
            style={{ animationDelay: "0.1s" }}
          >
            {sub}
          </p>
        )}
        {children}
      </div>

      <svg
        aria-hidden
        viewBox="0 0 1440 64"
        preserveAspectRatio="none"
        className="relative block h-10 w-full text-white sm:h-12"
      >
        <path fill="currentColor" d="M0,40 C240,64 480,8 720,20 C960,32 1200,60 1440,28 L1440,64 L0,64 Z" />
      </svg>
    </section>
  );
}

// Matching closing CTA card — the landing page's gradient stage in card form.
// bg-navy stays in the class list so the global white-text rule applies; the
// inline gradient just paints over it.
export function PageCta({
  title,
  sub,
  children,
}: {
  title: ReactNode;
  sub?: ReactNode;
  children: ReactNode;
}) {
  return (
    <section className="container-content py-20">
      <div
        className="relative overflow-hidden rounded-[28px] bg-navy px-8 py-14 text-center ring-1 ring-white/10 md:px-16"
        style={{ background: "linear-gradient(140deg, #0f2439 0%, #12324f 55%, #0b2b26 100%)" }}
      >
        <span
          aria-hidden
          className="pointer-events-none absolute -bottom-24 -left-24 h-72 w-72 rounded-full opacity-30"
          style={{ background: "radial-gradient(circle, var(--mint) 0%, transparent 65%)" }}
        />
        <span aria-hidden className="sparkle pointer-events-none absolute right-[22%] top-10 h-3 w-3 rounded-full bg-gold/70" />
        <span aria-hidden className="sparkle pointer-events-none absolute bottom-10 left-[18%] h-2.5 w-2.5 rounded-full bg-mint/70" style={{ animationDelay: "0.7s" }} />
        <div className="relative">
          <h2 className="font-display text-3xl font-extrabold tracking-[-0.02em] md:text-4xl">{title}</h2>
          {sub && <p className="mx-auto mt-4 max-w-md opacity-75">{sub}</p>}
          <div className="mt-8 flex flex-wrap items-center justify-center gap-4">{children}</div>
        </div>
      </div>
    </section>
  );
}
