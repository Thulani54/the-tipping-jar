"use client";

import { useState } from "react";
import Link from "next/link";
import { api } from "@/lib/api";

const SUBJECTS: [string, string][] = [
  ["general", "General Enquiry"],
  ["technical", "Technical Issue"],
  ["billing", "Billing / Payments"],
  ["partnership", "Partnership"],
  ["other", "Other"],
];

const CONTACT_CARDS = [
  {
    icon: "✉️",
    title: "SUPPORT",
    value: "support@tippingjar.co.za",
    sub: "Response within 1–2 business days",
  },
  {
    icon: "🛡️",
    title: "DISPUTES & BILLING",
    value: "support@tippingjar.co.za",
    sub: "File a formal dispute with reference tracking",
  },
  {
    icon: "🌐",
    title: "WEBSITE",
    value: "tippingjar.co.za",
    sub: "South Africa",
  },
];

const STATS = [
  { icon: "⏱️", label: "< 2 business days", desc: "Average response time" },
  { icon: "✅", label: "98% resolved", desc: "Satisfaction rate" },
  { icon: "🔒", label: "Encrypted", desc: "All messages secured" },
];

const FAQS: [string, string][] = [
  [
    "How do I file a dispute?",
    "Visit tippingjar.co.za/dispute, fill in the form, and you'll receive a tracking link by email within minutes.",
  ],
  [
    "How long does it take to process a payout?",
    "Payouts are processed within 2–5 business days after the tip is completed, depending on your bank.",
  ],
  [
    "My tip didn't go through. What should I do?",
    "Check your email for a failed payment notification, then try again or contact us for help.",
  ],
  [
    "Can I get a refund on a tip?",
    "Tips are generally non-refundable, but file a dispute and we'll investigate unauthorized or erroneous transactions.",
  ],
];

const inputClass =
  "w-full rounded-xl border border-border bg-dark px-4 py-3 text-sm text-white placeholder:text-muted focus:border-teal focus:outline-none";

function FaqItem({ q, a }: { q: string; a: string }) {
  const [open, setOpen] = useState(false);
  return (
    <button
      type="button"
      onClick={() => setOpen((v) => !v)}
      className="w-full rounded-xl border border-border bg-card p-4 text-left transition hover:border-teal/40"
    >
      <div className="flex items-center justify-between gap-4">
        <span className="text-sm font-semibold text-white">{q}</span>
        <span className="text-lg leading-none text-teal">{open ? "–" : "+"}</span>
      </div>
      {open && <p className="body-muted mt-3 text-[13px]">{a}</p>}
    </button>
  );
}

export default function ContactPage() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [subject, setSubject] = useState("general");
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (name.trim() === "" || !email.includes("@") || message.trim().length < 10) {
      setError("Please fill in all fields. Your message should be at least 10 characters.");
      return;
    }
    setLoading(true);
    setError(null);
    try {
      await api.contact({
        name: name.trim(),
        email: email.trim(),
        subject,
        message: message.trim(),
      });
      setSubmitted(true);
    } catch {
      setError(
        "Something went wrong. Please try again or email us at support@tippingjar.co.za",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <>
      {/* Hero */}
      <section className="border-b border-border bg-darker">
        <div className="container-content py-20 text-center md:py-24">
          <span className="inline-block rounded-full border border-teal/30 bg-teal/10 px-4 py-1.5 text-xs font-semibold text-teal">
            Support · tippingjar.co.za
          </span>
          <h1 className="heading-xl mx-auto mt-6 max-w-2xl">Get in touch</h1>
          <p className="body-muted mx-auto mt-4 max-w-lg text-lg">
            Have a question, partnership idea, or need help? We respond within 1–2 business days.
          </p>
        </div>
      </section>

      {/* Form + contact info */}
      <section className="container-content py-16">
        <div className="grid gap-12 lg:grid-cols-5">
          {/* Form / success */}
          <div className="lg:col-span-3">
            {submitted ? (
              <div className="card text-center">
                <div className="mx-auto grid h-16 w-16 place-items-center rounded-full bg-brand-gradient text-2xl">
                  ✓
                </div>
                <h2 className="mt-6 text-2xl font-extrabold text-white">Message sent!</h2>
                <p className="body-muted mx-auto mt-3 max-w-sm">
                  Thanks for reaching out. We&apos;ve sent a confirmation to {email} and will get
                  back to you within 1–2 business days.
                </p>
                <button
                  type="button"
                  onClick={() => {
                    setSubmitted(false);
                    setMessage("");
                  }}
                  className="btn-ghost mt-7"
                >
                  Send another message
                </button>
              </div>
            ) : (
              <form onSubmit={handleSubmit} noValidate>
                <h2 className="text-2xl font-extrabold tracking-tight text-white">
                  Send us a message
                </h2>
                <p className="body-muted mt-1 text-[13px]">All fields required.</p>

                <div className="mt-7 grid gap-4 sm:grid-cols-2">
                  <input
                    className={inputClass}
                    placeholder="Full name"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                  />
                  <input
                    className={inputClass}
                    type="email"
                    placeholder="Email address"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                  />
                </div>

                <select
                  className={`${inputClass} mt-4`}
                  value={subject}
                  onChange={(e) => setSubject(e.target.value)}
                >
                  {SUBJECTS.map(([val, label]) => (
                    <option key={val} value={val} className="bg-dark">
                      {label}
                    </option>
                  ))}
                </select>

                <textarea
                  className={`${inputClass} mt-4 resize-y`}
                  rows={6}
                  placeholder="Message"
                  value={message}
                  onChange={(e) => setMessage(e.target.value)}
                />

                {error && (
                  <div className="mt-4 rounded-lg border border-red-500/40 bg-red-500/10 p-3 text-[13px] text-red-400">
                    {error}
                  </div>
                )}

                <button
                  type="submit"
                  disabled={loading}
                  className="btn-primary mt-6 w-full disabled:opacity-60"
                >
                  {loading ? "Sending…" : "Send message"}
                </button>

                <p className="mt-4 text-center text-[13px]">
                  <Link href="/dispute" className="text-teal underline hover:opacity-90">
                    Need to raise a dispute? Click here →
                  </Link>
                </p>
              </form>
            )}
          </div>

          {/* Contact cards */}
          <div className="lg:col-span-2">
            <h3 className="text-lg font-bold text-white">Other ways to reach us</h3>
            <div className="mt-5 space-y-3">
              {CONTACT_CARDS.map((c) => (
                <div key={c.title} className="flex items-center gap-4 rounded-xl border border-border bg-card p-4">
                  <span className="grid h-10 w-10 shrink-0 place-items-center rounded-lg bg-teal/10 text-lg">
                    {c.icon}
                  </span>
                  <div>
                    <p className="text-[11px] font-semibold uppercase tracking-wide text-muted">
                      {c.title}
                    </p>
                    <p className="text-[13px] font-semibold text-white">{c.value}</p>
                    <p className="text-[11px] text-muted">{c.sub}</p>
                  </div>
                </div>
              ))}
            </div>
            <div className="mt-5 flex items-center gap-3 rounded-xl border border-border bg-dark p-4">
              <span className="text-base">🕐</span>
              <div>
                <p className="text-[13px] font-semibold text-white">Support hours</p>
                <p className="text-xs text-muted">Mon–Fri, 08:00–17:00 SAST</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Stats */}
      <section className="border-y border-border bg-dark">
        <div className="container-content py-12">
          <div className="grid gap-4 sm:grid-cols-3">
            {STATS.map((s) => (
              <div key={s.label} className="card">
                <div className="text-xl">{s.icon}</div>
                <p className="mt-3 text-base font-extrabold text-white">{s.label}</p>
                <p className="text-xs text-muted">{s.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section className="container-content py-16">
        <h2 className="text-2xl font-extrabold tracking-tight text-white md:text-3xl">
          Frequently asked questions
        </h2>
        <div className="mx-auto mt-7 max-w-3xl space-y-2">
          {FAQS.map(([q, a]) => (
            <FaqItem key={q} q={q} a={a} />
          ))}
        </div>
      </section>
    </>
  );
}
