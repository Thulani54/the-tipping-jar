import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/app_nav.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      appBar: AppNav(activeRoute: '/about'),
      body: SingleChildScrollView(
        child: Column(children: [
          _hero(),
          _mission(),
          _values(),
          _team(),
          _cta(context),
          _footer(),
        ]),
      ),
    );
  }

  Widget _hero() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 28),
    color: kDarker,
    child: Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: kPrimary.withOpacity(0.3)),
        ),
        child: Text('Our story', style: GoogleFonts.dmSans(
            color: kPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
      ).animate().fadeIn(duration: 400.ms),
      const SizedBox(height: 20),
      Text('We believe creators\ndeserve to be paid.',
          style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800,
              fontSize: 46, letterSpacing: -1.8, height: 1.1),
          textAlign: TextAlign.center)
          .animate().fadeIn(delay: 80.ms).slideY(begin: 0.2),
      const SizedBox(height: 20),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Text(
          'TippingJar was built by creators, for creators. We got tired of platforms taking 30% cuts, delaying payouts, and hiding creators behind algorithms. So we built something better.',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 17, height: 1.7),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 160.ms),
      ),
    ]),
  );

  Widget _mission() => Container(
    padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 28),
    color: kDark,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Our mission',
                    style: GoogleFonts.dmSans(color: kPrimary,
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 14),
                Text('Put money\ndirectly in\ncreators\' hands.',
                    style: GoogleFonts.dmSans(color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 34,
                        letterSpacing: -1.2, height: 1.2))
                    .animate().fadeIn(duration: 400.ms),
              ]),
            ),
            const SizedBox(width: 48),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 8),
                Text(
                  'We started TippingJar in 2025 after watching talented friends struggle to monetise their work on platforms that took most of the revenue and paid out monthly — if at all.',
                  style: GoogleFonts.dmSans(color: kMuted, fontSize: 15, height: 1.75),
                ),
                const SizedBox(height: 16),
                Text(
                  'We built a platform where creators receive tips directly, payouts hit their bank in 1-2 days, and the platform fee is tiny and transparent. No subscriptions. No algorithms. Just fans who want to say thank you.',
                  style: GoogleFonts.dmSans(color: kMuted, fontSize: 15, height: 1.75),
                ),
              ]).animate().fadeIn(delay: 100.ms, duration: 400.ms),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _values() => Container(
    padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 28),
    color: kDarker,
    child: Column(children: [
      Text('What we stand for',
          style: GoogleFonts.dmSans(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.8),
          textAlign: TextAlign.center),
      const SizedBox(height: 48),
      Wrap(spacing: 24, runSpacing: 24, alignment: WrapAlignment.center,
        children: [
          _ValueCard(Icons.bolt_rounded, 'Speed',
              'Payouts in 1-2 business days. No waiting weeks to access your own money.'),
          _ValueCard(Icons.visibility_rounded, 'Transparency',
              'A single, honest platform fee. No hidden cuts, no confusing tier gates.'),
          _ValueCard(Icons.favorite_rounded, 'Creator-first',
              'Every product decision starts with: does this help creators earn more?'),
          _ValueCard(Icons.security_rounded, 'Trust',
              'Bank-grade security, Stripe processing, and a team you can actually reach.'),
        ],
      ),
    ]),
  );

  Widget _team() => Container(
    padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 28),
    color: kDark,
    child: Column(children: [
      Text('The team',
          style: GoogleFonts.dmSans(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.8),
          textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Text('A small team with a big belief in the creator economy.',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 15),
          textAlign: TextAlign.center),
      const SizedBox(height: 48),
      Wrap(spacing: 24, runSpacing: 24, alignment: WrapAlignment.center,
        children: [
          _TeamCard('Lerato Dlamini', 'Co-founder & CEO', 'LD', const Color(0xFF00C896)),
          _TeamCard('Sipho Mokoena', 'Co-founder & CTO', 'SM', const Color(0xFF0097B2)),
          _TeamCard('Amara Osei', 'Head of Design', 'AO', const Color(0xFF818CF8)),
          _TeamCard('Thandi Khumalo', 'Head of Growth', 'TK', const Color(0xFFFBBF24)),
          _TeamCard('Ravi Naidoo', 'Lead Engineer', 'RN', const Color(0xFFF87171)),
          _TeamCard('Naledi Sithole', 'Head of Support', 'NS', const Color(0xFF34D399)),
        ],
      ),
    ]),
  );

  Widget _cta(BuildContext ctx) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
    padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 40),
    decoration: BoxDecoration(
      color: kCardBg,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: kBorder),
    ),
    child: Column(children: [
      Text('Join us on the mission',
          style: GoogleFonts.dmSans(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.8),
          textAlign: TextAlign.center),
      const SizedBox(height: 10),
      Text('Start your tip page today — it takes under a minute.',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 15),
          textAlign: TextAlign.center),
      const SizedBox(height: 28),
      Wrap(spacing: 14, runSpacing: 12, alignment: WrapAlignment.center, children: [
        ElevatedButton(
          onPressed: () => ctx.go('/register'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary, foregroundColor: Colors.white,
            elevation: 0, shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
          ),
          child: Text('Create your page',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
        ),
        OutlinedButton(
          onPressed: () => ctx.go('/careers'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: kBorder),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
          ),
          child: Text('View open roles',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15)),
        ),
      ]),
    ]),
  );

  Widget _footer() => Container(
    color: kDarker,
    padding: const EdgeInsets.all(24),
    child: const Text('© 2026 TippingJar. All rights reserved.',
        style: TextStyle(color: kMuted, fontSize: 12), textAlign: TextAlign.center),
  );
}

class _ValueCard extends StatelessWidget {
  final IconData icon;
  final String title, body;
  const _ValueCard(this.icon, this.title, this.body);
  @override
  Widget build(BuildContext context) => Container(
    width: 260,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: kCardBg, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: kPrimary, size: 20),
      ),
      const SizedBox(height: 14),
      Text(title, style: GoogleFonts.dmSans(
          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
      const SizedBox(height: 6),
      Text(body, style: GoogleFonts.dmSans(color: kMuted, fontSize: 13, height: 1.55)),
    ]),
  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
}

class _TeamCard extends StatelessWidget {
  final String name, role, initials;
  final Color color;
  const _TeamCard(this.name, this.role, this.initials, this.color);
  @override
  Widget build(BuildContext context) => Container(
    width: 180,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: kCardBg, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kBorder),
    ),
    child: Column(children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 2)),
        child: Center(child: Text(initials, style: GoogleFonts.dmSans(
            color: color, fontWeight: FontWeight.w800, fontSize: 16))),
      ),
      const SizedBox(height: 12),
      Text(name, style: GoogleFonts.dmSans(
          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
          textAlign: TextAlign.center),
      const SizedBox(height: 4),
      Text(role, style: GoogleFonts.dmSans(color: kMuted, fontSize: 11),
          textAlign: TextAlign.center),
    ]),
  );
}
