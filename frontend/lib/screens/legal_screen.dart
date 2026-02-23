import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/app_nav.dart';

// ─── Shared legal page widget ─────────────────────────────────────────────────
class LegalScreen extends StatelessWidget {
  final String title, subtitle, route;
  final List<_LegalSection> sections;
  const LegalScreen({super.key,
      required this.title, required this.subtitle,
      required this.route, required this.sections});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      appBar: AppNav(activeRoute: route),
      body: SingleChildScrollView(
        child: Column(children: [
          _hero(),
          _body(),
          _footer(),
        ]),
      ),
    );
  }

  Widget _hero() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 28),
    color: kDarker,
    child: Column(children: [
      Text(title,
          style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800,
              fontSize: 40, letterSpacing: -1.5),
          textAlign: TextAlign.center)
          .animate().fadeIn(duration: 400.ms).slideY(begin: 0.15),
      const SizedBox(height: 12),
      Text(subtitle,
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 15),
          textAlign: TextAlign.center)
          .animate().fadeIn(delay: 80.ms, duration: 400.ms),
    ]),
  );

  Widget _body() => Container(
    padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 28),
    color: kDark,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sections.asMap().entries.map((e) =>
            _SectionWidget(section: e.value, delay: 80 * e.key),
          ).toList(),
        ),
      ),
    ),
  );

  Widget _footer() => Container(
    color: kDarker,
    padding: const EdgeInsets.all(24),
    child: const Text('© 2026 TippingJar. All rights reserved.',
        style: TextStyle(color: kMuted, fontSize: 12), textAlign: TextAlign.center),
  );
}

class _LegalSection {
  final String heading;
  final String body;
  const _LegalSection(this.heading, this.body);
}

class _SectionWidget extends StatelessWidget {
  final _LegalSection section;
  final int delay;
  const _SectionWidget({required this.section, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 36),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(section.heading,
            style: GoogleFonts.dmSans(color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 10),
        Container(height: 2, width: 32, color: kPrimary),
        const SizedBox(height: 14),
        Text(section.body,
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 14, height: 1.8)),
      ]),
    ).animate().fadeIn(delay: delay.ms, duration: 400.ms);
  }
}

// ─── Privacy Policy ───────────────────────────────────────────────────────────
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) => LegalScreen(
    title: 'Privacy Policy',
    subtitle: 'Last updated: February 1, 2026',
    route: '/privacy',
    sections: const [
      _LegalSection('1. Information we collect',
          'We collect information you provide directly to us, such as your name, email address, username, and payment details when you register for an account or create a creator profile. We also automatically collect certain information about your device and how you interact with our services, including IP address, browser type, operating system, referring URLs, and pages viewed.'),
      _LegalSection('2. How we use your information',
          'We use the information we collect to provide, maintain, and improve our services; process transactions and send related information including confirmations and receipts; send you technical notices and support messages; respond to your comments and questions; monitor and analyse usage patterns; and detect, investigate, and prevent fraudulent transactions and other illegal activities.'),
      _LegalSection('3. Information sharing',
          'We do not sell, trade, or rent your personal information to third parties. We may share your information with Stripe, our payment processor, to complete transactions. We may also disclose information if we believe it is reasonably necessary to comply with a law, regulation, legal process, or governmental request.'),
      _LegalSection('4. Cookies',
          'We use cookies and similar tracking technologies to track activity on our service and to hold certain information. Cookies are files with a small amount of data which may include an anonymous unique identifier. You can instruct your browser to refuse all cookies or to indicate when a cookie is being sent.'),
      _LegalSection('5. Data retention',
          'We retain personal information for as long as your account is active or as needed to provide you services. You may request deletion of your personal data at any time by contacting us at privacy@tippingjar.io. We will respond within 30 days.'),
      _LegalSection('6. Security',
          'We take reasonable measures to help protect information about you from loss, theft, misuse and unauthorised access, disclosure, alteration and destruction. All data is encrypted in transit using TLS 1.3 and at rest using AES-256. We are SOC 2 Type II certified.'),
      _LegalSection('7. Your rights',
          'Depending on your location, you may have the right to access, correct, or delete your personal data; the right to data portability; the right to object to or restrict processing; and the right to withdraw consent. To exercise these rights, please contact privacy@tippingjar.io.'),
      _LegalSection('8. Contact',
          'If you have any questions about this Privacy Policy, please contact us at privacy@tippingjar.io or by post at TippingJar Ltd, 1 Creator Lane, Cape Town, 8001, South Africa.'),
    ],
  );
}

// ─── Terms of Service ─────────────────────────────────────────────────────────
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});
  @override
  Widget build(BuildContext context) => LegalScreen(
    title: 'Terms of Service',
    subtitle: 'Last updated: February 1, 2026',
    route: '/terms',
    sections: const [
      _LegalSection('1. Acceptance of terms',
          'By accessing or using TippingJar, you agree to be bound by these Terms of Service and our Privacy Policy. If you do not agree to these terms, please do not use our service. We may update these terms at any time, and continued use of the service constitutes acceptance of the updated terms.'),
      _LegalSection('2. Eligibility',
          'You must be at least 18 years of age to use TippingJar. By using the service you represent and warrant that you are at least 18 years old and that you have the legal capacity to enter into a binding agreement with us.'),
      _LegalSection('3. Creator accounts',
          'Creators are responsible for all content on their tip page, including profile information, images, and links. You agree not to post content that is illegal, abusive, fraudulent, or infringes on any third-party rights. We reserve the right to remove any content and terminate accounts that violate these terms.'),
      _LegalSection('4. Payments and fees',
          'TippingJar charges a platform fee on each tip received, as described on our Pricing page. Stripe processes all payments and may charge additional processing fees. Payouts are subject to Stripe\'s terms and conditions. TippingJar is not responsible for delays in payouts caused by Stripe or your bank.'),
      _LegalSection('5. Prohibited uses',
          'You may not use TippingJar for any unlawful purpose or in violation of these terms. Prohibited uses include, but are not limited to: facilitating illegal activity, money laundering, fraud, impersonation, or the sale of illegal goods or services. We reserve the right to terminate accounts engaged in prohibited uses without notice.'),
      _LegalSection('6. Intellectual property',
          'The TippingJar name, logo, and all related marks are trademarks of TippingJar Ltd. You may not use these marks without our prior written permission. Content you upload remains yours; by posting it, you grant us a non-exclusive licence to display it in connection with the service.'),
      _LegalSection('7. Limitation of liability',
          'To the maximum extent permitted by applicable law, TippingJar shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising out of your use of the service. Our total liability in connection with the service shall not exceed the fees you paid to us in the 12 months preceding the claim.'),
      _LegalSection('8. Governing law',
          'These terms are governed by the laws of the Republic of South Africa. Any disputes arising out of or in connection with these terms shall be subject to the exclusive jurisdiction of the courts of Cape Town, South Africa.'),
      _LegalSection('9. Contact',
          'For questions about these Terms of Service, please contact us at legal@tippingjar.io.'),
    ],
  );
}

// ─── Cookie Policy ────────────────────────────────────────────────────────────
class CookiesScreen extends StatelessWidget {
  const CookiesScreen({super.key});
  @override
  Widget build(BuildContext context) => LegalScreen(
    title: 'Cookie Policy',
    subtitle: 'Last updated: February 1, 2026',
    route: '/cookies',
    sections: const [
      _LegalSection('What are cookies?',
          'Cookies are small text files stored on your device when you visit a website. They help websites remember your preferences, keep you logged in, and understand how you use the site. We use both session cookies (which expire when you close your browser) and persistent cookies (which remain until you delete them or they expire).'),
      _LegalSection('Cookies we use',
          'We use the following categories of cookies:\n\n• Strictly necessary: Required for the site to function. These include session management and security tokens. They cannot be disabled.\n\n• Analytics: Help us understand how visitors interact with the site (e.g. pages visited, time on site). We use privacy-friendly analytics that do not track individuals across sites.\n\n• Preferences: Remember your settings, such as theme or language.\n\n• Stripe: Our payment processor sets cookies to detect fraud and keep payment sessions secure.'),
      _LegalSection('Third-party cookies',
          'Stripe, our payment processor, may set cookies on your device when you make or receive a tip. These cookies are governed by Stripe\'s own privacy and cookie policies. We do not use advertising or tracking cookies from any other third parties.'),
      _LegalSection('Managing cookies',
          'You can control and/or delete cookies through your browser settings. Most browsers allow you to block or delete cookies. Note that disabling strictly necessary cookies may prevent TippingJar from functioning correctly. To opt out of analytics cookies, you can use the "Do Not Track" setting in your browser.'),
      _LegalSection('Changes to this policy',
          'We may update this Cookie Policy from time to time. The "Last updated" date at the top of the page will reflect any changes. Continued use of TippingJar after changes constitutes your acceptance of the updated policy.'),
      _LegalSection('Contact',
          'If you have questions about our use of cookies, please contact us at privacy@tippingjar.io.'),
    ],
  );
}
