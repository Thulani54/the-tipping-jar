export const metadata = {
  title: "Terms of Service — Tipping Jar",
  description: "The terms governing your use of Tipping Jar.",
};

const SECTIONS: [string, string][] = [
  [
    "1. Acceptance of terms",
    "By accessing or using TippingJar, you agree to be bound by these Terms of Service and our Privacy Policy. If you do not agree to these terms, please do not use our service. We may update these terms at any time, and continued use of the service constitutes acceptance of the updated terms.",
  ],
  [
    "2. Eligibility",
    "You must be at least 18 years of age to use TippingJar. By using the service you represent and warrant that you are at least 18 years old and that you have the legal capacity to enter into a binding agreement with us.",
  ],
  [
    "3. Creator accounts",
    "Creators are responsible for all content on their tip page, including profile information, images, and links. You agree not to post content that is illegal, abusive, fraudulent, or infringes on any third-party rights. We reserve the right to remove any content and terminate accounts that violate these terms.",
  ],
  [
    "4. Payments and fees",
    "TippingJar charges a platform fee on each tip received, as described on our Pricing page. Paystack processes all payments and may charge additional processing fees. Payouts are subject to Paystack's terms and conditions. TippingJar is not responsible for delays in payouts caused by Paystack or your bank.",
  ],
  [
    "5. Prohibited uses",
    "You may not use TippingJar for any unlawful purpose or in violation of these terms. Prohibited uses include, but are not limited to: facilitating illegal activity, money laundering, fraud, impersonation, or the sale of illegal goods or services. We reserve the right to terminate accounts engaged in prohibited uses without notice.",
  ],
  [
    "6. Intellectual property",
    "The TippingJar name, logo, and all related marks are trademarks of TippingJar. You may not use these marks without our prior written permission. Content you upload remains yours; by posting it, you grant us a non-exclusive licence to display it in connection with the service.",
  ],
  [
    "7. Limitation of liability",
    "To the maximum extent permitted by applicable law, TippingJar shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising out of your use of the service. Our total liability in connection with the service shall not exceed the fees you paid to us in the 12 months preceding the claim.",
  ],
  [
    "8. Governing law",
    "These terms are governed by the laws of the Republic of South Africa. Any disputes arising out of or in connection with these terms shall be subject to the exclusive jurisdiction of the courts of Cape Town, South Africa.",
  ],
  [
    "9. Contact",
    "For questions about these Terms of Service, please contact us at legal@tippingjar.co.za.",
  ],
];

export default function TermsPage() {
  return (
    <>
      <section className="border-b border-border bg-dark">
        <div className="container-content py-20 text-center md:py-24">
          <span className="inline-block rounded-full border border-teal/30 bg-teal/10 px-4 py-1.5 text-xs font-semibold text-teal">
            Legal
          </span>
          <h1 className="heading-xl mt-6">Terms of Service</h1>
          <p className="body-muted mt-4 text-sm">Last updated: February 1, 2026</p>
        </div>
      </section>

      <section className="container-content py-16">
        <div className="mx-auto max-w-3xl">
          {SECTIONS.map(([heading, body]) => (
            <div key={heading} className="mb-10">
              <h2 className="text-lg font-bold tracking-tight text-ink">{heading}</h2>
              <div className="mt-3 h-0.5 w-9 rounded bg-brand-gradient" />
              <p className="mt-4 text-[15px] leading-loose text-muted">{body}</p>
            </div>
          ))}
        </div>
      </section>
    </>
  );
}
