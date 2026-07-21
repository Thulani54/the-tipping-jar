"use client";

import Link from "next/link";
import { useState } from "react";
import { Logo } from "@/components/Logo";
import { useAuth } from "@/lib/auth";

const LINKS = [
  { href: "/creators", label: "Creators" },
  { href: "/features", label: "Features" },
  { href: "/how-it-works", label: "How it works" },
  { href: "/pricing", label: "Pricing" },
  { href: "/blog", label: "Blog" },
];

export function Nav() {
  const { isAuthenticated, isCreator, logout } = useAuth();
  const [open, setOpen] = useState(false);

  return (
    <header className="sticky top-0 z-50 border-b border-border bg-darker/80 backdrop-blur">
      <nav className="container-content flex h-16 items-center justify-between">
        <Logo />

        <div className="hidden items-center gap-7 md:flex">
          {LINKS.map((l) => (
            <Link key={l.href} href={l.href} className="text-sm text-muted hover:text-ink">
              {l.label}
            </Link>
          ))}
        </div>

        <div className="hidden items-center gap-3 md:flex">
          {isAuthenticated ? (
            <>
              <Link href={isCreator ? "/dashboard" : "/fan-dashboard"} className="btn-ghost !py-2 !px-4 text-sm">
                Dashboard
              </Link>
              <button onClick={logout} className="text-sm text-muted hover:text-ink">
                Log out
              </button>
            </>
          ) : (
            <>
              <Link href="/login" className="text-sm text-muted hover:text-ink">
                Log in
              </Link>
              <Link href="/register" className="btn-primary !py-2 !px-4 text-sm">
                Get started
              </Link>
            </>
          )}
        </div>

        <button
          className="md:hidden text-ink"
          onClick={() => setOpen((v) => !v)}
          aria-label="Toggle menu"
        >
          ☰
        </button>
      </nav>

      {open && (
        <div className="border-t border-border md:hidden">
          <div className="container-content flex flex-col gap-3 py-4">
            {LINKS.map((l) => (
              <Link key={l.href} href={l.href} className="text-muted" onClick={() => setOpen(false)}>
                {l.label}
              </Link>
            ))}
            {isAuthenticated ? (
              <button onClick={logout} className="text-left text-muted">
                Log out
              </button>
            ) : (
              <>
                <Link href="/login" className="text-muted" onClick={() => setOpen(false)}>
                  Log in
                </Link>
                <Link href="/register" className="btn-primary" onClick={() => setOpen(false)}>
                  Get started
                </Link>
              </>
            )}
          </div>
        </div>
      )}
    </header>
  );
}
