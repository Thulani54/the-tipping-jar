export const metadata = {
  title: "Privacy Policy — Tipping Jar",
  description: "How Tipping Jar collects, uses, and protects your information.",
};

const SECTIONS: [string, string][] = [
  [
    "1. Information we collect",
    "We collect information you provide directly to us, such as your name, email address, username, and payment details when you register for an account or create a creator profile. We also automatically collect certain information about your device and how you interact with our services, including IP address, browser type, operating system, referring URLs, and pages viewed.",
  ],
  [
    "2. How we use your information",
    "We use the information we collect to provide, maintain, and improve our services; process transactions and send related information including confirmations and receipts; send you technical notices and support messages; respond to your comments and questions; monitor and analyse usage patterns; and detect, investigate, and prevent fraudulent transactions and other illegal activities.",
  ],
  [
    "3. Information sharing",
    "We do not sell, trade, or rent your personal information to third parties. We may share your information with Paystack, our payment processor, to complete transactions. We may also disclose information if we believe it is reasonably necessary to comply with a law, regulation, legal process, or governmental request.",
  ],
  [
    "4. Cookies",
    "We use cookies and similar tracking technologies to track activity on our service and to hold certain information. Cookies are files with a small amount of data which may include an anonymous unique identifier. You can instruct your browser to refuse all cookies or to indicate when a cookie is being sent.",
  ],
  [
    "5. Data retention",
    "We retain personal information for as long as your account is active or as needed to provide you services. You may request deletion of your personal data at any time by contacting us at privacy@tippingjar.co.za. We will respond within 30 days.",
  ],
  [
    "6. Security",
    "We take reasonable measures to help protect information about you from loss, theft, misuse and unauthorised access, disclosure, alteration and destruction. All data is encrypted in transit using TLS 1.3 and at rest using AES-256.",
  ],
  [
    "7. Your rights",
    "Depending on your location, you may have the right to access, correct, or delete your personal data; the right to data portability; the right to object to or restrict processing; and the right to withdraw consent. To exercise these rights, please contact privacy@tippingjar.co.za.",
  ],
  [
    "8. Contact",
    "If you have any questions about this Privacy Policy, please contact us at privacy@tippingjar.co.za or by post at TippingJar, Cape Town, South Africa.",
  ],
];

export default function PrivacyPage() {
  return (
    <>
      <section className="border-b border-border bg-dark">
        <div className="container-content py-20 text-center md:py-24">
          <span className="inline-block rounded-full border border-teal/30 bg-teal/10 px-4 py-1.5 text-xs font-semibold text-teal">
            Legal
          </span>
          <h1 className="heading-xl mt-6">Privacy Policy</h1>
          <p className="body-muted mt-4 text-sm">Last updated: February 1, 2026</p>
        </div>
      </section>

      <section className="container-content py-16">
        <div className="mx-auto max-w-3xl">
          {SECTIONS.map(([heading, body]) => (
            <div key={heading} className="mb-10">
              <h2 className="text-lg font-bold tracking-tight text-white">{heading}</h2>
              <div className="mt-3 h-0.5 w-9 rounded bg-brand-gradient" />
              <p className="mt-4 text-[15px] leading-loose text-muted">{body}</p>
            </div>
          ))}
        </div>
      </section>
    </>
  );
}
