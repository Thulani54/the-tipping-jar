import Image from "next/image";
import Link from "next/link";
import type { ReactNode } from "react";
import { ArrowLeft, Heart, ShieldCheck } from "lucide-react";
import { Logo } from "@/components/Logo";

export function AuthShell({
  title,
  description,
  children,
}: {
  title: string;
  description: string;
  children: ReactNode;
}) {
  return (
    <div className="tj-auth">
      <header className="tj-auth-header">
        <Logo size={38} />
        <Link href="/">
          <ArrowLeft size={15} />
          Back to website
        </Link>
      </header>
      <main className="tj-auth-layout">
        <aside className="tj-auth-story">
          <Image
            src="/creator-studio-hero.webp"
            alt="A podcaster at work in her studio"
            fill
            sizes="(max-width: 900px) 100vw, 50vw"
            priority
          />
          <div className="tj-auth-story-content">
            <span className="tj-auth-tag">
              <Heart size={15} />
              Good things grow with good people.
            </span>
            <h1>{title}</h1>
            <p>{description}</p>
            <div className="tj-auth-story-note">
              <ShieldCheck size={18} />
              <span>
                A home for creators, supporters
                <br />
                and communities across South Africa.
              </span>
            </div>
          </div>
        </aside>
        <section className="tj-auth-form-area">
          {children}
          <p className="tj-auth-help">
            Need a hand? <Link href="/contact">Talk to our team</Link>
          </p>
        </section>
      </main>
      <footer className="tj-auth-footer">
        <span>© {new Date().getFullYear()} Tipping Jar</span>
        <div>
          <Link href="/privacy">Privacy</Link>
          <Link href="/terms">Terms</Link>
        </div>
      </footer>
    </div>
  );
}
