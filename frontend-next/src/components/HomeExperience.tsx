"use client";
import Image from "next/image";
import Link from "next/link";
import { useState } from "react";
import {
  ArrowRight,
  ArrowUpRight,
  Check,
  Heart,
  Link2,
  Wallet,
  ShieldCheck,
  Music2,
  Mic2,
  Camera,
  Palette,
  Church,
  HandHeart,
  ChartNoAxesCombined,
  LockKeyhole,
  QrCode,
  Sparkles,
  Plus,
  CircleCheck,
} from "lucide-react";
const AUDIENCES = [
  {
    label: "Creators",
    title: "More creating. More connection.",
    body: "Your next episode, artwork or big idea deserves more than a like. Give the people who love your work a simple way to support it.",
    benefits: [
      "A tip page that feels like you",
      "Campaign jars for your next project",
      "A studio for your share-ready graphics",
    ],
    icon: Mic2,
  },
  {
    label: "Organisations",
    title: "Small contributions. Shared purpose.",
    body: "Give your NGO, church or community initiative a home for support. Share what you’re working toward and keep your contributions organised.",
    benefits: [
      "A profile for your organisation",
      "Dedicated jars for community goals",
      "Transaction records in one place",
    ],
    icon: HandHeart,
  },
  {
    label: "Supporters",
    title: "A little thanks goes a long way.",
    body: "Found a creator who made your day? Open their personal link, choose a tip and leave a message. You don’t need to create an account to show your appreciation.",
    benefits: [
      "Support from R10",
      "Add a personal message",
      "Pay through hosted card checkout",
    ],
    icon: Heart,
  },
];
const FAQ = [
  [
    "Who can use Tipping Jar?",
    "Creators, artists, musicians, podcasters and organisations—including NGOs and churches—can create a profile. Complete your profile and verification requirements before receiving tips.",
  ],
  [
    "Do my supporters need an account?",
    "No. Supporters can open your personal tip link, choose an amount and pay by card without signing up.",
  ],
  [
    "What is the minimum tip?",
    "Tips start at R10. The payment page shows the applicable fee breakdown before checkout.",
  ],
  [
    "How do I receive my money?",
    "Completed payments appear in your dashboard. Add your banking details, complete verification and request a payout from your available balance.",
  ],
  [
    "Can my NGO or church register?",
    "Yes. Choose Organisation during onboarding and add your organisation’s details. You can create campaign jars and share your support link with your community.",
  ],
];
export function HomeExperience() {
  const [audience, setAudience] = useState(0);
  const [amount, setAmount] = useState(50);
  const active = AUDIENCES[audience];
  return (
    <>
      <div className="tj-announcement">
        <div className="tj-container">
          <span>
            <span className="tj-live-dot" />
            Made for South African creators & communities
          </span>
          <Link href="/how-it-works">
            Meet your new tip jar <ArrowRight size={14} />
          </Link>
        </div>
      </div>
      <section className="tj-hero">
        <Image
          src="/creator-studio-hero.webp"
          alt="A podcaster creating in a sunlit recording studio"
          fill
          priority
          sizes="100vw"
          className="tj-hero-photo"
        />
        <div className="tj-container tj-hero-content">
          <div className="tj-hero-copy">
            <span className="tj-hero-badge">
              <span />
              Your work. Your community. Your jar.
            </span>
            <h1>
              Keep doing
              <br />
              what you love.
              <br />
              <em>Let the support flow.</em>
            </h1>
            <p>
              A little appreciation can become your next big thing. Bring tips,
              goals and your community together with one simple link.
            </p>
            <div className="tj-hero-actions">
              <Link href="/register" className="tj-button">
                Start your jar <ArrowRight size={18} />
              </Link>
              <Link
                href="/how-it-works"
                className="tj-button tj-button-outline"
              >
                See how it works <ArrowUpRight size={18} />
              </Link>
            </div>
            <div className="tj-hero-checks">
              <span>
                <Check size={16} />
                Free to set up
              </span>
              <span>
                <Check size={16} />
                Tips from R10
              </span>
              <span>
                <Check size={16} />
                Made for SA
              </span>
            </div>
          </div>
        </div>
        <div className="tj-photo-caption">
          <span className="tj-caption-icon">
            <Mic2 size={20} />
          </span>
          <div>
            For the voices worth hearing.
            <small>And the people who keep them going.</small>
          </div>
        </div>
      </section>
      <section
        className="tj-community-strip"
        aria-label="Who Tipping Jar is for"
      >
        <div className="tj-container">
          <p>
            Whatever you create.
            <br />
            <strong>There’s a place for you here.</strong>
          </p>
          <div>
            {[
              [Music2, "Musicians"],
              [Mic2, "Podcasters"],
              [Camera, "Creators"],
              [Palette, "Artists"],
              [Church, "Communities"],
            ].map(([Icon, label]) => {
              const I = Icon as typeof Music2;
              return (
                <span key={label as string}>
                  <I size={22} strokeWidth={1.4} />
                  {label as string}
                </span>
              );
            })}
          </div>
        </div>
      </section>
      <section className="tj-section tj-container" id="how-it-works">
        <div className="tj-section-heading">
          <div>
            <p className="tj-section-label">
              A little support. A lot of possibility.
            </p>
            <h2>
              From “love your work”
              <br />
              to your next chapter.
            </h2>
          </div>
          <p>
            You bring the passion. We make it easier for your community to be
            part of what comes next.
          </p>
        </div>
        <div className="tj-steps">
          {[
            {
              icon: Link2,
              title: "Make it yours",
              text: "Create your page, tell your story and complete your profile. One link becomes your home for support.",
            },
            {
              icon: Heart,
              title: "Share it with your people",
              text: "Add your link to your bio, videos or WhatsApp. Supporters choose an amount and leave a little love.",
            },
            {
              icon: Wallet,
              title: "See your support add up",
              text: "Track completed tips, read messages and manage payout requests from your creator dashboard.",
            },
          ].map(({ icon: Icon, title, text }, i) => (
            <article key={title}>
              <div className="tj-step-top">
                <span>
                  <Icon size={24} strokeWidth={1.5} />
                </span>
                <small>0{i + 1}</small>
              </div>
              <h3>{title}</h3>
              <p>{text}</p>
            </article>
          ))}
        </div>
      </section>
      <section className="tj-feature-section">
        <div className="tj-container">
          <div className="tj-section-heading">
            <div>
              <p className="tj-section-label">More than a payment link</p>
              <h2>A home for your ambition.</h2>
            </div>
            <Link className="tj-text-link" href="/features">
              Explore all features <ArrowUpRight size={18} />
            </Link>
          </div>
          <div className="tj-feature-grid">
            <article className="tj-feature-lead">
              <div>
                <span className="tj-icon-tile">
                  <ChartNoAxesCombined size={23} />
                </span>
                <h3>
                  Every little bit.
                  <br />
                  The bigger picture.
                </h3>
                <p>
                  Your tips, supporters and goals, together in a dashboard that
                  helps you see where you’re going.
                </p>
                <Link href="/features" className="tj-text-link">
                  Meet your dashboard <ArrowRight size={17} />
                </Link>
              </div>
              <div
                className="tj-dashboard-preview"
                aria-label="Illustrative dashboard preview"
              >
                <div className="tj-preview-top">
                  <span>
                    <span className="tj-preview-dot" />
                    Your jar overview
                  </span>
                  <small>Example</small>
                </div>
                <p>Total support</p>
                <strong>
                  R2,450<span>.00</span>
                </strong>
                <div className="tj-chart" aria-hidden>
                  {[22, 32, 26, 43, 38, 54, 47, 68, 60, 83, 74, 100].map(
                    (h, i) => (
                      <span key={i} style={{ height: `${h}%` }} />
                    ),
                  )}
                </div>
                <div className="tj-preview-bottom">
                  <span>Small beginnings</span>
                  <span>
                    Big possibilities <Sparkles size={13} />
                  </span>
                </div>
                <div className="tj-preview-goal">
                  <span>Next project</span>
                  <b>70% of example goal</b>
                  <div>
                    <span />
                  </div>
                </div>
              </div>
            </article>
            <article className="tj-feature-small">
              <span className="tj-icon-tile">
                <LockKeyhole size={23} />
              </span>
              <h3>Give your inner circle more.</h3>
              <p>
                Bring your posts, videos and behind-the-scenes moments together
                in your exclusive content hub.
              </p>
              <Link href="/features" className="tj-text-link">
                Explore the media hub <ArrowUpRight size={17} />
              </Link>
            </article>
            <article className="tj-feature-small tj-feature-peach">
              <span className="tj-icon-tile">
                <QrCode size={23} />
              </span>
              <h3>Take your jar everywhere.</h3>
              <p>
                From your social bio to your next gig. Share a link, create a QR
                poster and design your own promo in Studio.
              </p>
              <Link href="/features" className="tj-text-link">
                See creator tools <ArrowUpRight size={17} />
              </Link>
            </article>
          </div>
        </div>
      </section>
      <section className="tj-section tj-container tj-demo-section">
        <div>
          <p className="tj-section-label">Simple feels good</p>
          <h2>
            A thoughtful gesture.
            <br />
            Just a few taps.
          </h2>
          <p className="tj-intro">
            A great episode. An inspiring performance. A project you believe in.
            Make someone’s day with a tip and a few kind words.
          </p>
          <ul className="tj-check-list">
            <li>
              <CircleCheck />
              Choose a tip from R10
            </li>
            <li>
              <CircleCheck />
              Add a message that means something
            </li>
            <li>
              <CircleCheck />
              Continue to secure card checkout
            </li>
          </ul>
          <Link href="/how-it-works" className="tj-text-link">
            See the full journey <ArrowRight size={18} />
          </Link>
        </div>
        <div className="tj-demo-stage">
          <div className="tj-tip-preview">
            <div className="tj-preview-top">
              <span>
                <Heart size={16} />A little appreciation
              </span>
              <small>Interactive preview</small>
            </div>
            <h3>Make their day.</h3>
            <p>Pick a little thank you.</p>
            <div className="tj-tip-options">
              {[10, 20, 50, 100].map((n) => (
                <button
                  key={n}
                  aria-pressed={amount === n}
                  onClick={() => setAmount(n)}
                >
                  R{n}
                </button>
              ))}
            </div>
            <div className="tj-note">
              “Keep creating. We’re here for it.”
              <Heart size={18} />
            </div>
            <div className="tj-demo-total" aria-live="polite">
              <span>Your tip</span>
              <strong>
                R{amount}
                <small>.00</small>
              </strong>
            </div>
            <Link href="/register" className="tj-button">
              Create a page like this <ArrowUpRight size={17} />
            </Link>
            <p className="tj-demo-disclaimer">
              <ShieldCheck size={14} />
              Demo only. No payment will be made.
            </p>
          </div>
        </div>
      </section>
      <section className="tj-audience-section">
        <div className="tj-container">
          <p className="tj-section-label">Different stories. One community.</p>
          <h2>
            Built for the people
            <br />
            who bring something to life.
          </h2>
          <div
            className="tj-audience-tabs"
            role="tablist"
            aria-label="Who Tipping Jar is for"
          >
            {AUDIENCES.map((a, i) => (
              <button
                id={`audience-${i}`}
                key={a.label}
                role="tab"
                aria-controls="audience-panel"
                aria-selected={audience === i}
                tabIndex={audience === i ? 0 : -1}
                onKeyDown={(event) => {
                  const keys = ["ArrowLeft", "ArrowRight", "Home", "End"];
                  if (!keys.includes(event.key)) return;
                  event.preventDefault();
                  const next =
                    event.key === "Home"
                      ? 0
                      : event.key === "End"
                        ? AUDIENCES.length - 1
                        : (i +
                            (event.key === "ArrowRight" ? 1 : -1) +
                            AUDIENCES.length) %
                          AUDIENCES.length;
                  setAudience(next);
                  document.getElementById(`audience-${next}`)?.focus();
                }}
                onClick={() => setAudience(i)}
              >
                {a.label}
                <ArrowUpRight size={16} />
              </button>
            ))}
          </div>
          <div
            id="audience-panel"
            role="tabpanel"
            aria-labelledby={`audience-${audience}`}
            className="tj-audience-panel"
          >
            <div className="tj-audience-art" aria-hidden>
              <active.icon size={76} strokeWidth={1} />
              <span>
                Good things grow
                <br />
                with good people.
              </span>
            </div>
            <div>
              <h3>{active.title}</h3>
              <p>{active.body}</p>
              <ul className="tj-check-list">
                {active.benefits.map((b) => (
                  <li key={b}>
                    <Check />
                    {b}
                  </li>
                ))}
              </ul>
              <Link href="/register" className="tj-button">
                Join Tipping Jar <ArrowRight size={18} />
              </Link>
            </div>
          </div>
        </div>
      </section>
      <section className="tj-section tj-container tj-faq-section">
        <div>
          <p className="tj-section-label">Good questions</p>
          <h2>
            A little clarity
            <br />
            before you start.
          </h2>
          <p>Something else on your mind?</p>
          <Link href="/contact" className="tj-text-link">
            Talk to our team <ArrowUpRight size={18} />
          </Link>
        </div>
        <div className="tj-faq-list">
          {FAQ.map(([q, a]) => (
            <details key={q}>
              <summary>
                {q}
                <Plus size={19} />
              </summary>
              <p>{a}</p>
            </details>
          ))}
        </div>
      </section>
      <section className="tj-container tj-cta-wrap">
        <div className="tj-closing">
          <div>
            <p>Your next chapter starts here.</p>
            <h2>
              Big dreams.
              <br />
              One little jar.
            </h2>
          </div>
          <div>
            <Link href="/register" className="tj-button">
              Start your jar <ArrowRight size={18} />
            </Link>
            <p className="tj-closing-note">Free to create. Yours to grow.</p>
          </div>
        </div>
      </section>
    </>
  );
}
