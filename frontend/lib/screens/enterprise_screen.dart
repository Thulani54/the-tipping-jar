import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/app_nav.dart';

class EnterpriseScreen extends StatelessWidget {
  const EnterpriseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      appBar: AppNav(activeRoute: '/enterprise'),
      body: SingleChildScrollView(
        child: Column(children: [
          _hero(context),
          _logos(),
          _features(context),
          _pricing(context),
          _testimonials(),
          _cta(context),
          _footer(),
        ]),
      ),
    );
  }

  // ─── Hero ──────────────────────────────────────────────────────────────────
  Widget _hero(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: w > 900 ? 80 : 28, vertical: 96),
      decoration: const BoxDecoration(color: kDarker),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: kPrimary.withOpacity(0.3)),
          ),
          child: Text('Enterprise',
              style: GoogleFonts.inter(
                  color: kPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 20),
        Text('Tipping at scale\nfor your platform',
            style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: w > 700 ? 56 : 36,
                letterSpacing: -2,
                height: 1.05),
            textAlign: TextAlign.center)
            .animate().fadeIn(delay: 80.ms, duration: 500.ms).slideY(begin: 0.2),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Text(
            'Power fan monetisation for communities of any size. White-label, custom contracts, dedicated infrastructure, and a 99.99% SLA.',
            style: GoogleFonts.inter(color: kMuted, fontSize: 18, height: 1.65),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 160.ms, duration: 500.ms),
        ),
        const SizedBox(height: 40),
        Wrap(spacing: 14, runSpacing: 12, alignment: WrapAlignment.center, children: [
          ElevatedButton(
            onPressed: () => context.go('/contact'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
            ),
            child: Text('Contact sales',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
          ),
          OutlinedButton(
            onPressed: () => context.go('/enterprise-portal'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: kBorder),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
            ),
            child: Text('Go to portal',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ]).animate().fadeIn(delay: 240.ms, duration: 500.ms),
      ]),
    );
  }

  // ─── Client logos ──────────────────────────────────────────────────────────
  Widget _logos() => Container(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 28),
    color: kDark,
    child: Column(children: [
      Text('Trusted by leading platforms',
          style: GoogleFonts.inter(color: kMuted, fontSize: 13,
              fontWeight: FontWeight.w500, letterSpacing: 0.5),
          textAlign: TextAlign.center),
      const SizedBox(height: 28),
      Wrap(
        spacing: 32, runSpacing: 16, alignment: WrapAlignment.center,
        children: ['Streamio', 'CreatorHub', 'FanBridge', 'PodPay', 'LiveLink', 'ArtPass']
            .map((name) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorder),
              ),
              child: Text(name,
                  style: GoogleFonts.inter(
                      color: kMuted, fontWeight: FontWeight.w700, fontSize: 13)),
            ))
            .toList(),
      ),
    ]),
  );

  // ─── Enterprise features ───────────────────────────────────────────────────
  Widget _features(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final features = [
      (Icons.shield_rounded,          'SOC 2 Type II',           'Fully audited security controls with annual third-party pen testing.'),
      (Icons.business_rounded,        'White-label',             'Your brand, your domain — TippingJar is invisible to your users.'),
      (Icons.api_rounded,             'Enterprise API',          'High-throughput REST + webhooks with dedicated rate limits.'),
      (Icons.support_agent_rounded,   'Dedicated support',       '24/7 Slack channel with a named account manager and 1-hour SLA.'),
      (Icons.account_balance_rounded, 'Custom payouts',          'Bespoke settlement schedules, multi-currency, and T+1 options.'),
      (Icons.analytics_rounded,       'Advanced analytics',      'Real-time dashboards, cohort analysis, and raw data exports.'),
      (Icons.lock_rounded,            'SSO & SCIM',              'SAML 2.0, OIDC, Okta, and Azure AD provisioning out of the box.'),
      (Icons.tune_rounded,            'Custom contracts',        'Volume pricing, MSA, BAA, and data processing agreements.'),
    ];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 72),
      color: kDarker,
      child: Column(children: [
        Text('Built for the enterprise',
            style: GoogleFonts.inter(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: -1),
            textAlign: TextAlign.center)
            .animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 48),
        Wrap(
          spacing: 20, runSpacing: 20,
          alignment: WrapAlignment.center,
          children: features.asMap().entries.map((e) =>
            _FeatureCard(
              icon: e.value.$1,
              title: e.value.$2,
              body: e.value.$3,
              delay: 60 * e.key,
            ),
          ).toList(),
        ),
      ]),
    );
  }

  // ─── Pricing ───────────────────────────────────────────────────────────────
  Widget _pricing(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 72),
      color: kDark,
      child: Column(children: [
        Text('Transparent pricing',
            style: GoogleFonts.inter(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: -1),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('No surprises. Scale pricing with your growth.',
            style: GoogleFonts.inter(color: kMuted, fontSize: 16),
            textAlign: TextAlign.center),
        const SizedBox(height: 48),
        Wrap(spacing: 24, runSpacing: 24, alignment: WrapAlignment.center,
          children: [
            _PricingCard(
              name: 'Growth',
              price: '\$499',
              period: '/month',
              features: [
                'Up to 50K tips / month',
                '1.5% platform fee',
                'Custom domain',
                'Analytics dashboard',
                'Email support',
              ],
              isPrimary: false,
            ),
            _PricingCard(
              name: 'Scale',
              price: '\$1,499',
              period: '/month',
              features: [
                'Up to 500K tips / month',
                '1.0% platform fee',
                'White-label branding',
                'SSO & SCIM',
                'Dedicated Slack channel',
                'Custom payouts',
              ],
              isPrimary: true,
            ),
            _PricingCard(
              name: 'Custom',
              price: 'Contact us',
              period: '',
              features: [
                'Unlimited tips',
                'Custom fee structure',
                'On-premise option',
                'SLA guarantee',
                'Named account manager',
                'Data processing agreement',
              ],
              isPrimary: false,
            ),
          ],
        ),
      ]),
    );
  }

  // ─── Testimonials ──────────────────────────────────────────────────────────
  Widget _testimonials() => Container(
    color: kDarker,
    padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 28),
    child: Column(children: [
      Text('What enterprise customers say',
          style: GoogleFonts.inter(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.8),
          textAlign: TextAlign.center),
      const SizedBox(height: 40),
      Wrap(spacing: 24, runSpacing: 24, alignment: WrapAlignment.center,
        children: [
          _TestimonialCard(
            quote: 'TippingJar\'s enterprise plan cut our integration time from weeks to a single afternoon. The white-label support is flawless.',
            name: 'Sarah Chen',
            role: 'CTO at Streamio',
            initials: 'SC',
          ),
          _TestimonialCard(
            quote: 'We process over 200K tips a month. The uptime, the support response time, and the custom payout schedule are exactly what we needed.',
            name: 'Marcus O\'Brien',
            role: 'Head of Payments, CreatorHub',
            initials: 'MO',
          ),
          _TestimonialCard(
            quote: 'The dedicated Slack channel with our account manager makes us feel like they\'re part of our team. Highly recommended.',
            name: 'Priya Nair',
            role: 'VP Engineering, FanBridge',
            initials: 'PN',
          ),
        ],
      ),
    ]),
  );

  // ─── CTA ───────────────────────────────────────────────────────────────────
  Widget _cta(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 56),
    padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 40),
    decoration: BoxDecoration(
      color: kCardBg,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: kBorder),
    ),
    child: Column(children: [
      Container(
        width: 56, height: 56,
        decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
        child: const Icon(Icons.business_rounded, color: Colors.white, size: 24),
      ),
      const SizedBox(height: 20),
      Text('Ready to talk?',
          style: GoogleFonts.inter(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: -1),
          textAlign: TextAlign.center),
      const SizedBox(height: 10),
      Text('Our sales team will respond within one business day.',
          style: GoogleFonts.inter(color: kMuted, fontSize: 16),
          textAlign: TextAlign.center),
      const SizedBox(height: 32),
      ElevatedButton(
        onPressed: () => context.go('/contact'),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
        ),
        child: Text('Schedule a demo',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
      ),
    ]),
  );

  Widget _footer() => Container(
    color: kDarker,
    padding: const EdgeInsets.all(24),
    child: const Text('© 2026 TippingJar. All rights reserved.',
        style: TextStyle(color: kMuted, fontSize: 12),
        textAlign: TextAlign.center),
  );
}

// ─── Feature Card ─────────────────────────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title, body;
  final int delay;
  const _FeatureCard({required this.icon, required this.title,
      required this.body, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: kPrimary, size: 20),
        ),
        const SizedBox(height: 14),
        Text(title,
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 6),
        Text(body,
            style: GoogleFonts.inter(color: kMuted, fontSize: 13, height: 1.55)),
      ]),
    ).animate().fadeIn(delay: delay.ms, duration: 400.ms).slideY(begin: 0.1);
  }
}

// ─── Pricing Card ─────────────────────────────────────────────────────────────
class _PricingCard extends StatelessWidget {
  final String name, price, period;
  final List<String> features;
  final bool isPrimary;
  const _PricingCard({required this.name, required this.price,
      required this.period, required this.features, required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isPrimary ? kPrimary.withOpacity(0.5) : kBorder,
            width: isPrimary ? 2 : 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (isPrimary) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: kPrimary,
              borderRadius: BorderRadius.circular(36),
            ),
            child: Text('Most popular',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
          ),
          const SizedBox(height: 12),
        ],
        Text(name, style: GoogleFonts.inter(
            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(price, style: GoogleFonts.inter(
              color: isPrimary ? kPrimary : Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: price.length > 6 ? 24 : 38,
              letterSpacing: -1.5)),
          if (period.isNotEmpty) ...[
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(period,
                  style: GoogleFonts.inter(color: kMuted, fontSize: 13)),
            ),
          ],
        ]),
        const SizedBox(height: 24),
        ...features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Icon(Icons.check_circle_rounded, color: kPrimary, size: 16),
            const SizedBox(width: 10),
            Expanded(child: Text(f,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13))),
          ]),
        )),
        const SizedBox(height: 24),
        Builder(builder: (ctx) => SizedBox(
          width: double.infinity,
          child: isPrimary
              ? ElevatedButton(
                  onPressed: () => ctx.go('/enterprise-portal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary, foregroundColor: Colors.white,
                    elevation: 0, shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(36)),
                  ),
                  child: Text('Get started',
                      style: GoogleFonts.inter(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                )
              : OutlinedButton(
                  onPressed: () => ctx.go('/contact'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: kBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(36)),
                  ),
                  child: Text('Contact sales',
                      style: GoogleFonts.inter(
                          color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                ),
        )),
      ]),
    );
  }
}

// ─── Testimonial Card ─────────────────────────────────────────────────────────
class _TestimonialCard extends StatelessWidget {
  final String quote, name, role, initials;
  const _TestimonialCard({required this.quote, required this.name,
      required this.role, required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: List.generate(5, (_) =>
            const Icon(Icons.star_rounded, color: kPrimary, size: 16))),
        const SizedBox(height: 14),
        Text('"$quote"',
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 14, height: 1.6,
                fontStyle: FontStyle.italic)),
        const SizedBox(height: 20),
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
            child: Center(child: Text(initials,
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            Text(role, style: GoogleFonts.inter(color: kMuted, fontSize: 12)),
          ]),
        ]),
      ]),
    );
  }
}
