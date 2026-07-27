import Link from "next/link";
import { Logo } from "@/components/Logo";

const COLS: { title: string; links: { href: string; label: string }[] }[] = [
  {
    title: "Product",
    links: [
      { href: "/features", label: "Features" },
      { href: "/how-it-works", label: "How it works" },
      { href: "/pricing", label: "Pricing" },
      { href: "/creators", label: "Creators" },
    ],
  },
  {
    title: "Company",
    links: [
      { href: "/about", label: "About" },
      { href: "/blog", label: "Blog" },
      { href: "/careers", label: "Careers" },
      { href: "/contact", label: "Contact" },
    ],
  },
  {
    title: "Developers",
    links: [
      { href: "/developers", label: "API" },
      { href: "/enterprise", label: "Enterprise" },
      { href: "/partner-apply", label: "Partner" },
      { href: "/changelog", label: "Changelog" },
    ],
  },
  {
    title: "Legal",
    links: [
      { href: "/privacy", label: "Privacy" },
      { href: "/terms", label: "Terms" },
      { href: "/cookies", label: "Cookies" },
      { href: "/dispute", label: "Disputes" },
    ],
  },
];

export function Footer() {
  return (
    <footer className="border-t border-border bg-dark">
      <div className="container-content grid gap-10 py-14 md:grid-cols-5">
        <div className="md:col-span-1">
          <Logo />
          <p className="body-muted mt-4 max-w-xs">
            The fan-tipping platform for African creators.
          </p>
        </div>
        {COLS.map((c) => (
          <div key={c.title}>
            <h4 className="mb-3 text-sm font-semibold text-ink">{c.title}</h4>
            <ul className="space-y-2">
              {c.links.map((l) => (
                <li key={l.href}>
                  <Link href={l.href} className="text-sm text-muted hover:text-ink">
                    {l.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>
      <div className="border-t border-border">
        <div className="container-content flex flex-col items-center justify-between gap-2 py-6 text-sm text-muted md:flex-row">
          <span>© {new Date().getFullYear()} Tipping Jar. All rights reserved.</span>
          <span className="inline-flex items-center gap-1.5">
            <i className="bi bi-geo-alt-fill text-green" />
            Made in South Africa
          </span>
        </div>
      </div>
    </footer>
  );
}
