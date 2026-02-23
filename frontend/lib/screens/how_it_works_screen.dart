import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/app_nav.dart';

class HowItWorksScreen extends StatefulWidget {
  const HowItWorksScreen({super.key});
  @override
  State<HowItWorksScreen> createState() => _HowItWorksScreenState();
}

class _HowItWorksScreenState extends State<HowItWorksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _openFaq = -1;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ─── data ─────────────────────────────────────────────────────────────────
  static const _fanSteps = [
    (
      Icons.search_rounded,
      'Discover creators',
      'Browse TippingJar\'s creator directory. Search by name, category, or trending. Every creator has a public page showing their work, bio, and tip feed.',
      kPrimary,
    ),
    (
      Icons.volunteer_activism,
      'Choose your amount',
      'Pick a quick amount (R5 · R10 · R20 · R50) or enter a custom value. No account needed — tip anonymously or leave your name and a message.',
      kTeal,
    ),
    (
      Icons.credit_card_rounded,
      'Pay securely',
      'Enter your card details on our fully encrypted, PCI-DSS compliant checkout. Your payment info is never stored on TippingJar servers — bank-grade security from end to end.',
      kBlue,
    ),
    (
      Icons.check_circle_rounded,
      'Tip confirmed!',
      'Your tip lands on the creator\'s page instantly. They\'ll see your name and message in real time. You\'ll receive an email receipt automatically.',
      kPrimary,
    ),
  ];

  static const _creatorSteps = [
    (
      Icons.person_add_alt_1_rounded,
      'Sign up as a creator',
      'Register with your email, pick a username, and select the "Creator" role. Your profile slug becomes your unique tip link: tippingjar.com/you.',
      kPrimary,
    ),
    (
      Icons.palette_rounded,
      'Customise your page',
      'Upload a cover photo and avatar, write a tagline, and set a monthly tip goal. Your page goes live the moment you save — no approval required.',
      kTeal,
    ),
    (
      Icons.account_balance_rounded,
      'Connect your bank',
      'Link your South African bank account in under 2 minutes. TippingJar never holds your money — funds go straight to your bank account, fast and reliable.',
      kBlue,
    ),
    (
      Icons.share_rounded,
      'Share your link',
      'Post tippingjar.com/you anywhere — your bio, videos, newsletter, or Linktree. Every visit is a potential tip. Watch your jar fill up in real time on your dashboard.',
      kPrimary,
    ),
  ];

  static const _faqs = [
    (
      'How much does TippingJar take?',
      'TippingJar charges a 3% platform fee per tip. A 3% payment processing fee (excl. VAT) also applies to each transaction. No subscriptions, no hidden charges — just transparent, simple pricing.'
    ),
    (
      'When do I get paid?',
      'Funds are settled to your linked bank account on a rolling basis after each successful tip. Payout timing depends on your bank but is typically within 1–2 business days.'
    ),
    (
      'Do fans need an account to tip?',
      'No. Fans can tip completely anonymously without registering. They just need a card. If they want to track their tips or leave a profile name, they can create a free account.'
    ),
    (
      'Which countries are supported?',
      'TippingJar is currently available in South Africa only. Creators must be based in South Africa to receive payouts. We plan to expand to more countries soon.'
    ),
    (
      'Is my payment information safe?',
      'Yes. TippingJar never stores card details. All payment data is handled through a PCI-DSS Level 1 certified payment processor — the highest level of payment security available.'
    ),
    (
      'Can I set a monthly tip goal?',
      'Absolutely. Add a goal amount on your creator profile. A progress bar appears on your tip page, giving fans a tangible target to rally around.'
    ),
    (
      'What if a tip is refunded?',
      'Fans can request a refund within 7 days of tipping. Refunds are processed and deducted from your next payout. TippingJar will notify you by email.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      appBar: AppNav(activeRoute: '/how-it-works'),
      body: SingleChildScrollView(
        child: Column(children: [
          _hero(context),
          _tabSection(context),
          _timeline(context),
          _securityStrip(context),
          _faqSection(context),
          _cta(context),
          _footer(),
        ]),
      ),
    );
  }

  // ─── Hero ────────────────────────────────────────────────────────────────
  Widget _hero(BuildContext ctx) {
    return Container(
      width: double.infinity,
      color: kDarker,
      child: Stack(
        children: [
          // Dot grid background
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
            child: Column(children: [
              _tag('How it works'),
              const SizedBox(height: 20),
              Text('Simple for fans.\nPowerful for creators.',
                  style: headingXL(ctx),
                  textAlign: TextAlign.center)
                  .animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: const Text(
                  'TippingJar removes every barrier between appreciation and action. No complicated setup, no waiting periods — just simple, transparent fees.',
                  style: kBodyStyle,
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
            ]),
          ),
        ],
      ),
    );
  }

  // ─── Tab section ─────────────────────────────────────────────────────────
  Widget _tabSection(BuildContext ctx) {
    final steps = _tab.index == 0 ? _fanSteps : _creatorSteps;
    return Container(
      color: kDark,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      child: Column(children: [
        // Tab bar
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: kBorder),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _tabBtn('I\'m a fan', 0),
            _tabBtn('I\'m a creator', 1),
          ]),
        ),
        const SizedBox(height: 56),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: steps.asMap().entries.map((e) {
            return _StepDetailCard(
              number: e.key + 1,
              icon: e.value.$1,
              title: e.value.$2,
              body: e.value.$3,
              color: e.value.$4,
              delay: e.key * 100,
            );
          }).toList(),
        ),
      ]),
    );
  }

  Widget _tabBtn(String label, int index) {
    final active = _tab.index == index;
    return GestureDetector(
      onTap: () => setState(() => _tab.animateTo(index)),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: active ? kPrimary : null,
          borderRadius: BorderRadius.circular(36),
        ),
        child: Text(label,
            style: GoogleFonts.dmSans(
                color: active ? Colors.white : kMuted,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
      ),
    );
  }

  // ─── Visual timeline ──────────────────────────────────────────────────────
  Widget _timeline(BuildContext ctx) {
    final items = [
      (kPrimary, 'Fan visits creator\'s page'),
      (kTeal,    'Picks an amount & adds a message'),
      (kBlue,    'Pays securely — fully encrypted'),
      (kPrimary, 'Creator receives funds in their bank account'),
      (kTeal,    'Creator sees tip on their dashboard'),
    ];

    return Container(
      color: kDarker,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      child: Column(children: [
        _tag('The full journey'),
        const SizedBox(height: 16),
        Text('From tap to payout',
            style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 32,
                letterSpacing: -1),
            textAlign: TextAlign.center)
            .animate().fadeIn(duration: 500.ms),
        const SizedBox(height: 48),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(children: items.asMap().entries.map((e) {
            final last = e.key == items.length - 1;
            return _TimelineRow(
              color: e.value.$1,
              label: e.value.$2,
              isLast: last,
              delay: e.key * 100,
            );
          }).toList()),
        ),
      ]),
    );
  }

  // ─── Security strip ───────────────────────────────────────────────────────
  Widget _securityStrip(BuildContext ctx) {
    final badges = [
      (Icons.lock_rounded, 'PCI-DSS Level 1'),
      (Icons.verified_rounded, 'Bank-grade Encryption'),
      (Icons.shield_rounded, 'Bank-grade TLS'),
      (Icons.no_encryption_gmailerrorred_rounded, 'Zero data stored'),
    ];
    return Container(
      color: kDark,
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Column(children: [
        const Text('Your money is safe.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 26)),
        const SizedBox(height: 8),
        const Text('All payments are secured end-to-end. We never see your card number.',
            style: kBodyStyle, textAlign: TextAlign.center),
        const SizedBox(height: 36),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: badges.asMap().entries.map((e) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(e.value.$1, color: kPrimary, size: 18),
                const SizedBox(width: 10),
                Text(e.value.$2,
                    style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ]),
            ).animate().fadeIn(delay: (e.key * 80).ms, duration: 400.ms);
          }).toList(),
        ),
      ]),
    );
  }

  // ─── FAQ ─────────────────────────────────────────────────────────────────
  Widget _faqSection(BuildContext ctx) {
    return Container(
      color: kDarker,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      child: Column(children: [
        _tag('FAQ'),
        const SizedBox(height: 16),
        Text('Common questions',
            style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 32,
                letterSpacing: -1),
            textAlign: TextAlign.center),
        const SizedBox(height: 40),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(children: _faqs.asMap().entries.map((e) {
            final open = _openFaq == e.key;
            return _FaqItem(
              question: e.value.$1,
              answer: e.value.$2,
              open: open,
              onTap: () => setState(() => _openFaq = open ? -1 : e.key),
            );
          }).toList()),
        ),
      ]),
    );
  }

  // ─── CTA ─────────────────────────────────────────────────────────────────
  Widget _cta(BuildContext ctx) {
    return Container(
      color: kDark,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(children: [
        Text('Ready to start?',
            style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 36,
                letterSpacing: -1),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        const Text('Set up your jar in 60 seconds — no credit card needed.',
            style: kBodyStyle, textAlign: TextAlign.center),
        const SizedBox(height: 32),
        Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
          ElevatedButton(
            onPressed: () => ctx.go('/register'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary, foregroundColor: Colors.white,
              shadowColor: Colors.transparent, elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
            ),
            child: Text('Create your page →',
                style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          OutlinedButton(
            onPressed: () => ctx.go('/creators'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: kBorder),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
            ),
            child: Text('Browse creators',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ]),
      ]),
    );
  }

  Widget _footer() => Container(
    color: kDarker,
    padding: const EdgeInsets.all(24),
    child: const Text('© 2026 TippingJar. All rights reserved.',
        style: TextStyle(color: kMuted, fontSize: 12),
        textAlign: TextAlign.center),
  );

  Widget _tag(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: kPrimary.withOpacity(0.1),
      border: Border.all(color: kPrimary.withOpacity(0.3)),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(label, style: GoogleFonts.dmSans(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}

// ─── Dot grid background ─────────────────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    const spacing = 30.0;
    const radius = 1.0;
    for (double x = 0; x <= size.width + spacing; x += spacing) {
      for (double y = 0; y <= size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Step detail card ─────────────────────────────────────────────────────────
class _StepDetailCard extends StatefulWidget {
  final int number;
  final IconData icon;
  final String title, body;
  final Color color;
  final int delay;
  const _StepDetailCard({required this.number, required this.icon,
      required this.title, required this.body, required this.color, required this.delay});
  @override
  State<_StepDetailCard> createState() => _StepDetailCardState();
}

class _StepDetailCardState extends State<_StepDetailCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: 200.ms,
        width: 300,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _hovered ? kCardBg.withOpacity(0.9) : kCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _hovered ? widget.color.withOpacity(0.5) : kBorder),
          boxShadow: _hovered ? [BoxShadow(color: widget.color.withOpacity(0.12), blurRadius: 40, offset: const Offset(0, 12))] : [],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: widget.color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(widget.icon, color: widget.color, size: 22),
            ),
            const Spacer(),
            Text('0${widget.number}',
                style: GoogleFonts.dmSans(color: widget.color.withOpacity(0.25), fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
          ]),
          const SizedBox(height: 20),
          Text(widget.title, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
          const SizedBox(height: 10),
          Text(widget.body, style: GoogleFonts.dmSans(color: kMuted, fontSize: 14, height: 1.65)),
        ]),
      ).animate().fadeIn(delay: widget.delay.ms, duration: 500.ms).slideY(begin: 0.2, curve: Curves.easeOut),
    );
  }
}

// ─── Timeline row ─────────────────────────────────────────────────────────────
class _TimelineRow extends StatelessWidget {
  final Color color;
  final String label;
  final bool isLast;
  final int delay;
  const _TimelineRow({required this.color, required this.label, required this.isLast, required this.delay});
  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5), width: 2)),
          child: Icon(Icons.check, color: color, size: 16),
        ),
        if (!isLast)
          Container(width: 2, height: 40, color: kBorder),
      ]),
      const SizedBox(width: 16),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 7, bottom: 16),
          child: Text(label, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
        ),
      ),
    ]).animate().fadeIn(delay: delay.ms, duration: 400.ms).slideX(begin: -0.1, curve: Curves.easeOut);
  }
}

// ─── FAQ item ─────────────────────────────────────────────────────────────────
class _FaqItem extends StatelessWidget {
  final String question, answer;
  final bool open;
  final VoidCallback onTap;
  const _FaqItem({required this.question, required this.answer, required this.open, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: open ? kPrimary.withOpacity(0.4) : kBorder),
      ),
      child: Column(children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(children: [
              Expanded(child: Text(question, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15))),
              const SizedBox(width: 12),
              AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration: 200.ms,
                child: Icon(Icons.keyboard_arrow_down_rounded, color: open ? kPrimary : kMuted),
              ),
            ]),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Text(answer, style: GoogleFonts.dmSans(color: kMuted, fontSize: 14, height: 1.65)),
          ),
          crossFadeState: open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: 200.ms,
        ),
      ]),
    );
  }
}
