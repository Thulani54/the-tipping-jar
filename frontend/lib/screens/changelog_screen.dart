import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/app_nav.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      appBar: AppNav(activeRoute: '/changelog'),
      body: SingleChildScrollView(
        child: Column(children: [
          _hero(),
          _entries(),
          _footer(),
        ]),
      ),
    );
  }

  Widget _hero() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 28),
    color: kDarker,
    child: Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: kPrimary.withOpacity(0.3)),
        ),
        child: Text('Changelog', style: GoogleFonts.dmSans(
            color: kPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
      ).animate().fadeIn(duration: 400.ms),
      const SizedBox(height: 20),
      Text('What\'s new',
          style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800,
              fontSize: 42, letterSpacing: -1.5),
          textAlign: TextAlign.center)
          .animate().fadeIn(delay: 80.ms).slideY(begin: 0.2),
      const SizedBox(height: 14),
      Text('Every update, improvement, and fix — documented.',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 17, height: 1.6),
          textAlign: TextAlign.center)
          .animate().fadeIn(delay: 160.ms),
    ]),
  );

  Widget _entries() => Container(
    padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 28),
    color: kDark,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: _releases().asMap().entries.map((e) =>
            _ReleaseCard(release: e.value, delay: 60 * e.key),
          ).toList(),
        ),
      ),
    ),
  );

  List<_Release> _releases() => [
    _Release(
      version: 'v1.4.0', date: 'Feb 14, 2026', badge: 'New',
      title: 'Developer API + Webhooks',
      summary: 'The TippingJar REST API is now publicly available. Developers can create tip flows, manage creators, and react to events in real time with signed webhooks.',
      items: [
        'Public REST API with JWT auth',
        'Webhook events: tip.completed, tip.failed, payout.initiated, payout.completed',
        'Official SDKs for Python, Node.js, Dart, and Go',
        'Interactive API playground in dashboard',
      ],
    ),
    _Release(
      version: 'v1.3.2', date: 'Jan 28, 2026', badge: 'Fix',
      title: 'Payout reliability improvements',
      summary: 'Several edge cases in the Stripe payout flow have been resolved. Payouts now retry automatically on transient failures.',
      items: [
        'Auto-retry on Stripe timeout (up to 3 attempts)',
        'Fixed duplicate payout bug for creators with multiple bank accounts',
        'Improved payout failure email notifications',
      ],
    ),
    _Release(
      version: 'v1.3.0', date: 'Jan 10, 2026', badge: 'New',
      title: 'Pro plan & advanced analytics',
      summary: 'Introducing the Pro plan with lower fees, priority payouts, and a brand-new analytics dashboard with cohort analysis.',
      items: [
        'Pro plan — \$12/month, 2.5% fee, T+1 payouts',
        'Revenue chart, tip heatmap, fan retention cohort',
        'CSV data export',
        'Custom tip amount goals with progress bar',
        'Remove TippingJar branding from tip pages',
      ],
    ),
    _Release(
      version: 'v1.2.0', date: 'Dec 19, 2025', badge: 'New',
      title: 'Creator discovery & categories',
      summary: 'Fans can now browse and search all creators by category. Creators can tag their content type for better discoverability.',
      items: [
        'Creator search by name and tagline',
        'Category filter (Music, Art, Gaming, Podcasts, Writing, Tech)',
        'Featured creators strip on Creators page',
        'Monthly tip goal progress bar on creator profiles',
      ],
    ),
    _Release(
      version: 'v1.1.0', date: 'Dec 1, 2025', badge: 'New',
      title: 'Apple Pay & Google Pay',
      summary: 'Fans can now tip using Apple Pay and Google Pay in addition to cards, making the tip flow one tap on mobile.',
      items: [
        'Apple Pay on Safari (iOS & macOS)',
        'Google Pay on Chrome (Android & desktop)',
        'Payment method icons on tip pages',
      ],
    ),
    _Release(
      version: 'v1.0.0', date: 'Nov 15, 2025', badge: 'Launch',
      title: 'TippingJar is live 🎉',
      summary: 'The first public release of TippingJar. Creators can set up a tip page in 60 seconds and start receiving fan support powered by Stripe.',
      items: [
        'Creator profiles with custom slug and tagline',
        'Tip pages with custom messages',
        'Stripe payment processing',
        'T+2 bank payouts',
        'Basic tip feed and notifications',
      ],
    ),
  ];

  Widget _footer() => Container(
    color: kDarker,
    padding: const EdgeInsets.all(24),
    child: const Text('© 2026 TippingJar. All rights reserved.',
        style: TextStyle(color: kMuted, fontSize: 12), textAlign: TextAlign.center),
  );
}

class _Release {
  final String version, date, badge, title, summary;
  final List<String> items;
  const _Release({required this.version, required this.date, required this.badge,
      required this.title, required this.summary, required this.items});
}

class _ReleaseCard extends StatelessWidget {
  final _Release release;
  final int delay;
  const _ReleaseCard({required this.release, required this.delay});

  Color get _badgeColor => switch (release.badge) {
    'New'    => kPrimary,
    'Fix'    => const Color(0xFFFBBF24),
    'Launch' => const Color(0xFF818CF8),
    _        => kMuted,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Timeline dot + line
        Column(children: [
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(color: _badgeColor, shape: BoxShape.circle),
          ),
          Container(width: 1, height: 200, color: kBorder),
        ]),
        const SizedBox(width: 24),
        // Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(color: _badgeColor.withOpacity(0.3)),
                  ),
                  child: Text(release.badge, style: GoogleFonts.dmSans(
                      color: _badgeColor, fontWeight: FontWeight.w700, fontSize: 11)),
                ),
                const SizedBox(width: 10),
                Text(release.version, style: GoogleFonts.jetBrainsMono(
                    color: kMuted, fontSize: 12)),
                const Spacer(),
                Text(release.date, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
              ]),
              const SizedBox(height: 12),
              Text(release.title, style: GoogleFonts.dmSans(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
              const SizedBox(height: 8),
              Text(release.summary, style: GoogleFonts.dmSans(
                  color: kMuted, fontSize: 13, height: 1.6)),
              const SizedBox(height: 16),
              ...release.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Icon(Icons.arrow_right_rounded, color: _badgeColor, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(item, style: GoogleFonts.dmSans(
                      color: Colors.white, fontSize: 13))),
                ]),
              )),
            ]),
          ).animate().fadeIn(delay: delay.ms, duration: 400.ms).slideX(begin: 0.05),
        ),
      ]),
    );
  }
}
