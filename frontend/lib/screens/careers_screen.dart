import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/job_opening_model.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/app_nav.dart';

class CareersScreen extends StatefulWidget {
  const CareersScreen({super.key});

  @override
  State<CareersScreen> createState() => _CareersScreenState();
}

class _CareersScreenState extends State<CareersScreen> {
  List<JobOpeningModel>? _jobs;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final jobs = await ApiService().getJobs();
      if (mounted) setState(() => _jobs = jobs);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      appBar: AppNav(activeRoute: '/careers'),
      body: SingleChildScrollView(
        child: Column(children: [
          _hero(),
          _perks(),
          _jobsSection(),
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
      Wrap(spacing: 20, runSpacing: 20, alignment: WrapAlignment.center, children: [
        _PerkCard(Icons.public_rounded,         'Fully remote',      'Work from anywhere. We care about results, not where you sit.'),
        _PerkCard(Icons.beach_access_rounded,   'Unlimited PTO',     'Take the time you need. We trust you.'),
        _PerkCard(Icons.account_balance_rounded,'Equity',            'Every full-time hire gets meaningful equity in TippingJar.'),
        _PerkCard(Icons.health_and_safety_rounded,'Health cover',    'Full medical, dental, and vision for you and your family.'),
        _PerkCard(Icons.laptop_mac_rounded,     'Hardware stipend',  'R35,000 to set up your ideal workspace.'),
        _PerkCard(Icons.school_rounded,         'Learning budget',   'R18,000/year for courses, books, and conferences.'),
      ]),
    ]),
  );

  Widget _jobsSection() {
    return Container(
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
          child: _jobsBody(),
        ),
      ]),
    );
  }

  Widget _jobsBody() {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Could not load jobs. Please try again later.',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 15),
            textAlign: TextAlign.center),
      );
    }
    if (_jobs == null) {
      return const SizedBox(height: 120,
          child: Center(child: SpinKitFadingCircle(color: kPrimary, size: 28)));
    }
    if (_jobs!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder)),
        child: Column(children: [
          const Icon(Icons.work_outline, color: kMuted, size: 36),
          const SizedBox(height: 14),
          Text('No open roles right now', style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Check back soon — we\'re always growing.',
              style: GoogleFonts.dmSans(color: kMuted, fontSize: 13),
              textAlign: TextAlign.center),
        ]),
      );
    }

    // Group by department
    final byDept = <String, List<JobOpeningModel>>{};
    for (final job in _jobs!) {
      byDept.putIfAbsent(job.department, () => []).add(job);
    }

    return Column(
      children: byDept.entries.toList().asMap().entries.map((entry) {
        final dept = entry.value.key;
        final jobs = entry.value.value;
        return Column(children: [
          if (entry.key > 0) const SizedBox(height: 28),
          _JobSection(dept: dept, jobs: jobs),
        ]);
      }).toList(),
    );
  }

  Widget _footer() => Container(
    color: kDarker,
    padding: const EdgeInsets.all(24),
    child: const Text('© 2026 TippingJar. All rights reserved.',
        style: TextStyle(color: kMuted, fontSize: 12), textAlign: TextAlign.center),
  );
}

// ─── Department colour ────────────────────────────────────────────────────────

Color _deptColor(String dept) {
  switch (dept.toLowerCase()) {
    case 'engineering': return const Color(0xFF818CF8);
    case 'design':      return kPrimary;
    case 'growth':
    case 'marketing':   return const Color(0xFFFBBF24);
    case 'operations':
    case 'finance':     return const Color(0xFFF87171);
    case 'product':     return const Color(0xFF0097B2);
    default:            return const Color(0xFF34D399);
  }
}

// ─── Perks card ───────────────────────────────────────────────────────────────

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

// ─── Job section ──────────────────────────────────────────────────────────────

class _JobSection extends StatelessWidget {
  final String dept;
  final List<JobOpeningModel> jobs;
  const _JobSection({required this.dept, required this.jobs});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(dept.toUpperCase(), style: GoogleFonts.dmSans(
          color: kMuted, fontWeight: FontWeight.w600, fontSize: 11,
          letterSpacing: 0.8)),
      const SizedBox(height: 10),
      ...jobs.map((j) => _JobCard(job: j)),
    ],
  );
}

// ─── Job card ─────────────────────────────────────────────────────────────────

class _JobCard extends StatelessWidget {
  final JobOpeningModel job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final color = _deptColor(job.department);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder)),
      child: Row(children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 14),
        Expanded(child: Text(job.title, style: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
        const SizedBox(width: 12),
        Text(job.location, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: kPrimary.withOpacity(0.25))),
          child: Text(job.employmentType, style: GoogleFonts.dmSans(
              color: kPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
        ),
      ]),
    ).animate().fadeIn(duration: 350.ms);
  }
}
