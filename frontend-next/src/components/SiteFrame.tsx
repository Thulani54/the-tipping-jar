"use client";

import { usePathname } from "next/navigation";
import { Nav } from "@/components/Nav";
import { Footer } from "@/components/Footer";

// Routes that render as a full-bleed app shell — no marketing top nav / footer.
// The dashboard supplies its own sidebar navigation.
const BARE_PREFIXES = ["/dashboard", "/embed", "/overlay"];

export function SiteFrame({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const bare = BARE_PREFIXES.some(
    (p) => pathname === p || pathname.startsWith(`${p}/`),
  );

  if (bare || pathname === "/login" || pathname === "/register" || pathname === "/fan-dashboard") return <>{children}</>;

  return (
    <div className="marketing-site">
      <Nav />
      <main className="min-h-[70vh]">{children}</main>
      <Footer />
    </div>
  );
}
