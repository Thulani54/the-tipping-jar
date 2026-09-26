import type { ReactNode } from "react";
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
    <section className="tj-page-hero">
      <div className="tj-container">
        <p className="tj-section-label">{eyebrow}</p>
        <h1>{title}</h1>
        {sub && <p className="tj-page-intro">{sub}</p>}
        {children}
      </div>
    </section>
  );
}
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
    <section className="tj-container tj-cta-wrap">
      <div className="tj-closing">
        <div>
          <h2>{title}</h2>
          {sub && <p>{sub}</p>}
        </div>
        <div className="tj-closing-actions">{children}</div>
      </div>
    </section>
  );
}
