export const metadata = {
  title: "Cookie Policy — Tipping Jar",
  description: "How Tipping Jar uses cookies and similar technologies.",
};

const SECTIONS: [string, string][] = [
  [
    "What are cookies?",
    "Cookies are small text files stored on your device when you visit a website. They help websites remember your preferences, keep you logged in, and understand how you use the site. We use both session cookies (which expire when you close your browser) and persistent cookies (which remain until you delete them or they expire).",
  ],
  [
    "Cookies we use",
    "We use the following categories of cookies:\n\n• Strictly necessary: Required for the site to function. These include session management and security tokens. They cannot be disabled.\n\n• Analytics: Help us understand how visitors interact with the site (e.g. pages visited, time on site). We use privacy-friendly analytics that do not track individuals across sites.\n\n• Preferences: Remember your settings, such as theme or language.\n\n• Paystack: Our payment processor sets cookies to detect fraud and keep payment sessions secure.",
  ],
  [
    "Third-party cookies",
    "Paystack, our payment processor, may set cookies on your device when you make or receive a tip. These cookies are governed by Paystack's own privacy and cookie policies. We do not use advertising or tracking cookies from any other third parties.",
  ],
  [
    "Managing cookies",
    'You can control and/or delete cookies through your browser settings. Most browsers allow you to block or delete cookies. Note that disabling strictly necessary cookies may prevent TippingJar from functioning correctly. To opt out of analytics cookies, you can use the "Do Not Track" setting in your browser.',
  ],
  [
    "Changes to this policy",
    'We may update this Cookie Policy from time to time. The "Last updated" date at the top of the page will reflect any changes. Continued use of TippingJar after changes constitutes your acceptance of the updated policy.',
  ],
  [
    "Contact",
    "If you have questions about our use of cookies, please contact us at privacy@tippingjar.co.za.",
  ],
];

export default function CookiesPage() {
  return (
    <>
      <section className="border-b border-border bg-dark">
        <div className="container-content py-20 text-center md:py-24">
          <span className="inline-block rounded-full border border-teal/30 bg-teal/10 px-4 py-1.5 text-xs font-semibold text-teal">
            Legal
          </span>
          <h1 className="heading-xl mt-6">Cookie Policy</h1>
          <p className="body-muted mt-4 text-sm">Last updated: February 1, 2026</p>
        </div>
      </section>

      <section className="container-content py-16">
        <div className="mx-auto max-w-3xl">
          {SECTIONS.map(([heading, body]) => (
            <div key={heading} className="mb-10">
              <h2 className="text-lg font-bold tracking-tight text-white">{heading}</h2>
              <div className="mt-3 h-0.5 w-9 rounded bg-brand-gradient" />
              <div className="mt-4 space-y-4">
                {body.split("\n\n").map((para, i) => (
                  <p key={i} className="text-[15px] leading-loose text-muted">
                    {para}
                  </p>
                ))}
              </div>
            </div>
          ))}
        </div>
      </section>
    </>
  );
}
