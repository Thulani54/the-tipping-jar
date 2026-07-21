"use client";

// Partner application — ported from frontend/lib/screens/partner_apply_screen.dart
// Multi-step: Company → Contact → Documents → Success.
// There is no partner-application endpoint in the available api, so submission is
// a client-side placeholder. TODO(api) markers note what's needed.

import { useState } from "react";
import Link from "next/link";
import { api } from "@/lib/api";

type Step = 0 | 1 | 2 | 3; // Company, Contact, Documents, Success

const STEP_LABELS = ["Company", "Contact", "Documents"];

const DOCS: { key: string; label: string }[] = [
  { key: "cipc", label: "Company Registration (CIPC)" },
  { key: "vat", label: "VAT Certificate" },
  { key: "id", label: "Director ID / Passport" },
  { key: "bank", label: "Bank Confirmation Letter" },
];

export default function PartnerApplyPage() {
  const [step, setStep] = useState<Step>(0);
  const [submitting, setSubmitting] = useState(false);

  // Company
  const [name, setName] = useState("");
  const [website, setWebsite] = useState("");
  const [description, setDescription] = useState("");
  const [use, setUse] = useState("");
  const [legalName, setLegalName] = useState("");
  const [regNum, setRegNum] = useState("");
  const [vat, setVat] = useState("");

  // Contact
  const [contactName, setContactName] = useState("");
  const [contactEmail, setContactEmail] = useState("");
  const [contactPhone, setContactPhone] = useState("");

  // Documents (filename only — placeholder)
  const [docs, setDocs] = useState<Record<string, string | null>>({});

  const [error, setError] = useState<string | null>(null);

  const companyValid = name.trim() && description.trim() && use.trim();
  const contactValid = contactName.trim() && contactEmail.includes("@");

  const submitContact = async () => {
    setError(null);
    if (!contactValid) {
      setError("Please provide a name and a valid email.");
      return;
    }
    setSubmitting(true);
    try {
      await api.partnerApply({
        name: contactName.trim(),
        email: contactEmail.trim(),
        company: (legalName || name).trim(),
        website: website.trim(),
        app_type: "partner",
        message:
          `Platform: ${name}\n` +
          `What it does: ${description}\n` +
          `Intended use: ${use}\n` +
          (regNum ? `CIPC: ${regNum}\n` : "") +
          (vat ? `VAT: ${vat}\n` : "") +
          (contactPhone ? `Phone: ${contactPhone}` : ""),
      });
      setStep(2);
    } catch {
      setError("Couldn't submit your application. Please try again.");
    } finally {
      setSubmitting(false);
    }
  };

  if (step === 3) return <SuccessView />;

  return (
    <div className="container-content flex justify-center py-16">
      <div className="w-full max-w-xl">
        <StepIndicator current={step} />

        {step === 0 && (
          <section className="mt-10">
            <h1 className="text-2xl font-extrabold tracking-tight text-ink">Company details</h1>
            <p className="body-muted mt-2">
              Tell us about your business and how you plan to use the Platform API.
            </p>
            <div className="mt-8 space-y-4">
              <Field label="Platform / app name *" value={name} onChange={setName} />
              <Field label="Website URL" value={website} onChange={setWebsite} />
              <Field
                label="What does your platform do? *"
                value={description}
                onChange={setDescription}
                textarea
              />
              <Field
                label="How will you use TippingJar? *"
                value={use}
                onChange={setUse}
                textarea
              />
              <div className="pt-2 text-xs font-semibold uppercase tracking-wide text-muted">
                Company info
              </div>
              <Field label="Legal company name" value={legalName} onChange={setLegalName} />
              <div className="grid gap-4 sm:grid-cols-2">
                <Field label="Registration number (CIPC)" value={regNum} onChange={setRegNum} />
                <Field label="VAT number (optional)" value={vat} onChange={setVat} />
              </div>
            </div>
            <button
              onClick={() => companyValid && setStep(1)}
              disabled={!companyValid}
              className="btn-primary mt-8 w-full disabled:cursor-not-allowed disabled:opacity-50"
            >
              Continue
            </button>
          </section>
        )}

        {step === 1 && (
          <section className="mt-10">
            <h1 className="text-2xl font-extrabold tracking-tight text-ink">Primary contact</h1>
            <p className="body-muted mt-2">Who should we contact regarding your application?</p>
            <div className="mt-8 space-y-4">
              <Field label="Full name *" value={contactName} onChange={setContactName} />
              <Field
                label="Email address *"
                value={contactEmail}
                onChange={setContactEmail}
                type="email"
              />
              <Field
                label="Phone number"
                value={contactPhone}
                onChange={setContactPhone}
                type="tel"
              />
            </div>
            {error && <p className="mt-4 text-sm text-red-400">{error}</p>}
            <div className="mt-8 flex gap-4">
              <button
                onClick={() => setStep(0)}
                disabled={submitting}
                className="btn-ghost flex-1"
              >
                Back
              </button>
              <button
                onClick={submitContact}
                disabled={submitting}
                className="btn-primary flex-[2] disabled:opacity-60"
              >
                {submitting ? "Submitting…" : "Submit & continue"}
              </button>
            </div>
          </section>
        )}

        {step === 2 && (
          <section className="mt-10">
            <h1 className="text-2xl font-extrabold tracking-tight text-ink">
              Supporting documents
            </h1>
            <p className="body-muted mt-2">
              Upload verification documents to speed up review. All optional — you can upload later.
            </p>
            <div className="mt-8 space-y-3">
              {DOCS.map((d) => (
                <DocRow
                  key={d.key}
                  label={d.label}
                  filename={docs[d.key] ?? null}
                  onPick={(f) => setDocs((prev) => ({ ...prev, [d.key]: f }))}
                />
              ))}
            </div>
            {/* TODO(api): upload platform documents endpoint */}
            <div className="mt-8 flex gap-4">
              <button onClick={() => setStep(3)} className="btn-ghost flex-1">
                Skip for now
              </button>
              <button onClick={() => setStep(3)} className="btn-primary flex-[2]">
                Upload &amp; finish
              </button>
            </div>
          </section>
        )}
      </div>
    </div>
  );
}

function StepIndicator({ current }: { current: number }) {
  return (
    <div className="flex items-center">
      {STEP_LABELS.map((label, i) => (
        <div key={label} className="flex flex-1 flex-col items-center">
          <div className="flex w-full items-center">
            {i > 0 && (
              <div className={`h-px flex-1 ${i <= current ? "bg-teal" : "bg-border"}`} />
            )}
            <div
              className={`grid h-7 w-7 place-items-center rounded-full border text-xs font-bold ${
                i < current
                  ? "border-teal bg-teal text-ink"
                  : i === current
                    ? "border-teal bg-teal/15 text-teal"
                    : "border-border bg-card text-muted"
              }`}
            >
              {i < current ? "✓" : i + 1}
            </div>
            {i < STEP_LABELS.length - 1 && (
              <div className={`h-px flex-1 ${i < current ? "bg-teal" : "bg-border"}`} />
            )}
          </div>
          <span
            className={`mt-2 text-xs ${i === current ? "font-semibold text-ink" : "text-muted"}`}
          >
            {label}
          </span>
        </div>
      ))}
    </div>
  );
}

function Field({
  label,
  value,
  onChange,
  textarea,
  type = "text",
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  textarea?: boolean;
  type?: string;
}) {
  const cls =
    "w-full rounded-xl border border-border bg-card px-4 py-3 text-sm text-ink placeholder:text-muted focus:border-teal focus:outline-none";
  return (
    <label className="block">
      <span className="mb-1.5 block text-xs font-medium text-muted">{label}</span>
      {textarea ? (
        <textarea
          value={value}
          onChange={(e) => onChange(e.target.value)}
          rows={3}
          className={cls}
        />
      ) : (
        <input type={type} value={value} onChange={(e) => onChange(e.target.value)} className={cls} />
      )}
    </label>
  );
}

function DocRow({
  label,
  filename,
  onPick,
}: {
  label: string;
  filename: string | null;
  onPick: (name: string | null) => void;
}) {
  return (
    <div
      className={`flex items-center gap-3 rounded-xl border bg-card px-4 py-3.5 ${
        filename ? "border-teal/40" : "border-border"
      }`}
    >
      <span className="text-lg">{filename ? "✅" : "📎"}</span>
      <div className="min-w-0 flex-1">
        <p className={`text-sm ${filename ? "text-ink" : "text-muted"}`}>{label}</p>
        {filename && <p className="truncate text-xs text-teal">{filename}</p>}
      </div>
      <label className="cursor-pointer rounded-lg border border-border px-3.5 py-2 text-xs font-semibold text-teal hover:border-teal">
        {filename ? "Replace" : "Select"}
        <input
          type="file"
          accept=".pdf,.jpg,.jpeg,.png"
          className="hidden"
          onChange={(e) => onPick(e.target.files?.[0]?.name ?? null)}
        />
      </label>
    </div>
  );
}

function SuccessView() {
  return (
    <div className="container-content flex justify-center py-24">
      <div className="max-w-md text-center">
        <div className="mx-auto grid h-20 w-20 place-items-center rounded-full border border-teal/40 bg-primary/10 text-4xl">
          ✓
        </div>
        <h1 className="mt-7 text-2xl font-extrabold tracking-tight text-ink">
          Application submitted!
        </h1>
        <p className="body-muted mt-3">
          Thank you for applying to the TippingJar Partner Program. Our team will review your
          application within 48 business hours and contact you via the email you provided.
        </p>
        <Link href="/developers" className="btn-primary mt-8 inline-flex">
          Back to developer docs
        </Link>
      </div>
    </div>
  );
}
