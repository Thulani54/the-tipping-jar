"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { Menu, X } from "lucide-react";
import { Logo } from "@/components/Logo";
import { useAuth } from "@/lib/auth";
const LINKS = [
  { href: "/how-it-works", label: "How it works" },
  { href: "/features", label: "Features" },
  { href: "/pricing", label: "Pricing" },
  { href: "/blog", label: "Our journal" },
];
export function Nav() {
  const { isAuthenticated, isCreator, isAdmin } = useAuth();
  const pathname = usePathname();
  const [open, setOpen] = useState(false);
  const destination = isAdmin
    ? "/admin-portal"
    : isCreator
      ? "/dashboard"
      : "/fan-dashboard";
  return (
    <header className="tj-nav">
      <nav className="tj-container tj-nav-inner" aria-label="Main navigation">
        <Logo size={38} />
        <div className="tj-desktop-links">
          {LINKS.map(({ href, label }) => (
            <Link
              key={href}
              href={href}
              aria-current={pathname === href ? "page" : undefined}
            >
              <span>{label}</span>
            </Link>
          ))}
        </div>
        <div className="tj-nav-actions">
          <Link href={isAuthenticated ? destination : "/login"}>
            {isAuthenticated ? "My dashboard" : "Log in"}
          </Link>
          <Link
            href={isAuthenticated ? destination : "/register"}
            className="tj-button tj-button-small"
          >
            {isAuthenticated ? "Open dashboard" : "Start your jar"}
          </Link>
        </div>
        <button
          className="tj-menu-toggle"
          aria-label={open ? "Close menu" : "Open menu"}
          aria-expanded={open}
          aria-controls="mobile-navigation"
          onClick={() => setOpen(!open)}
        >
          {open ? <X /> : <Menu />}
        </button>
      </nav>
      {open && (
        <div id="mobile-navigation" className="tj-mobile-links">
          {LINKS.map((l) => (
            <Link href={l.href} key={l.href} onClick={() => setOpen(false)}>
              {l.label}
            </Link>
          ))}
          <Link
            href={isAuthenticated ? destination : "/login"}
            onClick={() => setOpen(false)}
          >
            {isAuthenticated ? "My dashboard" : "Log in"}
          </Link>
          <Link
            href={isAuthenticated ? destination : "/register"}
            className="tj-button"
            onClick={() => setOpen(false)}
          >
            {isAuthenticated ? "Open dashboard" : "Start your jar"}
          </Link>
        </div>
      )}
    </header>
  );
}
