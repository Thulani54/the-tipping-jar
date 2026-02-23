import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/app_nav.dart';

class CareersScreen extends StatelessWidget {
  const CareersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      appBar: AppNav(activeRoute: '/careers'),
      body: SingleChildScrollView(
        child: Column(children: [
          _hero(),
          _perks(),
          _jobs(),
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
        child: Text('We\'re hiring', style: GoogleFonts.dmSans(
            color: kPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
      ).animate().fadeIn(duration: 400.ms),
      const SizedBox(height: 20),
      Text('Build the future of\nthe creator economy',
          style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800,
              fontSize: 46, letterSpacing: -1.8, height: 1.1),
          textAlign: TextAlign.center)
          .animate().fadeIn(delay: 80.ms).slideY(begin: 0.2),
      const SizedBox(height: 20),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Text(
          'We\'re a small, fully remote team with a big mission. If you care deeply about creators and love building great products, we\'d love to hear from you.',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 17, height: 1.7),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 160.ms),
      ),
    ]),
  );

  Widget _perks() => Container(
    padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 28),
    color: kDark,
    child: Column(children: [
      Text('Why TippingJar',
          style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800,
              fontSize: 28, letterSpacing: -0.8),
          textAlign: TextAlign.center),
      const SizedBox(height: 40),
      Wrap(spacing: 20, runSpacing: 20, alignment: WrapAlignment.center,
        children: [
          _PerkCard(Icons.public_rounded, 'Fully remote', 'Work from anywhere. We care about results, not where you sit.'),
          _PerkCard(Icons.beach_access_rounded, 'Unlimited PTO', 'Take the time you need. We trust you.'),
          _PerkCard(Icons.account_balance_rounded, 'Equity', 'Every full-time hire gets meaningful equity in TippingJar.'),
          _PerkCard(Icons.health_and_safety_rounded, 'Health cover', 'Full medical, dental, and vision for you and your family.'),
          _PerkCard(Icons.laptop_mac_rounded, 'Hardware stipend', '\$2,000 to set up your ideal workspace.'),
          _PerkCard(Icons.school_rounded, 'Learning budget', '\$1,000/year for courses, books, and conferences.'),
        ],
      ),
    ]),
  );

  Widget _jobs() => Container(
    padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 28),
    color: kDarker,
    child: Column(children: [
      Text('Open roles',
          style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800,
              fontSize: 28, letterSpacing: -0.8),
          textAlign: TextAlign.center),
      const SizedBox(height: 36),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(children: [
          _JobSection('Engineering', [
            _Job('Senior Full-Stack Engineer', 'Remote', 'Full-time', const Color(0xFF818CF8)),
            _Job('Flutter Engineer', 'Remote', 'Full-time', const Color(0xFF818CF8)),
            _Job('DevOps / Platform Engineer', 'Remote', 'Full-time', const Color(0xFF818CF8)),
          ]),
          const SizedBox(height: 28),
          _JobSection('Design', [
            _Job('Product Designer', 'Remote', 'Full-time', kPrimary),
          ]),
          const SizedBox(height: 28),
          _JobSection('Growth', [
            _Job('Head of Creator Marketing', 'Remote', 'Full-time', const Color(0xFFFBBF24)),
            _Job('Creator Success Manager', 'Remote', 'Full-time', const Color(0xFFFBBF24)),
          ]),
          const SizedBox(height: 28),
          _JobSection('Operations', [
            _Job('Finance & Compliance Lead', 'Remote', 'Full-time', const Color(0xFFF87171)),
          ]),
        ]),
      ),
    ]),
  );

  Widget _footer() => Container(
    color: kDarker,
    padding: const EdgeInsets.all(24),
    child: const Text('© 2026 TippingJar. All rights reserved.',
        style: TextStyle(color: kMuted, fontSize: 12), textAlign: TextAlign.center),
  );
}

class _PerkCard extends StatelessWidget {
  final IconData icon;
  final String title, body;
  const _PerkCard(this.icon, this.title, this.body);
  @override
  Widget build(BuildContext context) => Container(
    width: 240,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 38, height: 38,
          decoration: BoxDecoration(color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: kPrimary, size: 18)),
      const SizedBox(height: 12),
      Text(title, style: GoogleFonts.dmSans(
          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 5),
      Text(body, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12, height: 1.55)),
    ]),
  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
}

class _Job {
  final String title, location, type;
  final Color color;
  const _Job(this.title, this.location, this.type, this.color);
}

class _JobSection extends StatelessWidget {
  final String dept;
  final List<_Job> jobs;
  const _JobSection(this.dept, this.jobs);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(dept, style: GoogleFonts.dmSans(
          color: kMuted, fontWeight: FontWeight.w600, fontSize: 12,
          letterSpacing: 0.6)),
      const SizedBox(height: 10),
      ...jobs.map((j) => _JobCard(job: j)),
    ],
  );
}

class _JobCard extends StatelessWidget {
  final _Job job;
  const _JobCard({required this.job});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder)),
    child: Row(children: [
      Container(width: 8, height: 8,
          decoration: BoxDecoration(color: job.color, shape: BoxShape.circle)),
      const SizedBox(width: 14),
      Expanded(child: Text(job.title, style: GoogleFonts.dmSans(
          color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
      const SizedBox(width: 12),
      Text(job.location, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
      const SizedBox(width: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: kPrimary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: kPrimary.withOpacity(0.25))),
        child: Text(job.type, style: GoogleFonts.dmSans(
            color: kPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
      ),
    ]),
  ).animate().fadeIn(duration: 350.ms);
}
