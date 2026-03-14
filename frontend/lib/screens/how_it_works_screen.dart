import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_nav.dart';
import '../widgets/site_footer.dart';

// ─── Local palette (light) ────────────────────────────────────────────────────
const _bgWhite    = Colors.white;
const _bgSage     = Color(0xFFF5F9F6);
const _ink        = Color(0xFF080F0B);
const _inkBody    = Color(0xFF38524A);
const _inkMuted   = Color(0xFF7A9487);
const _border     = Color(0xFFDBEAE1);
const _green      = Color(0xFF004423);
const _greenMid   = Color(0xFF006B3A);
const _teal       = Color(0xFF0097B2);
const _blue       = Color(0xFF2563EB);

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

  static const _fanSteps = [
    (Icons.search_rounded, 'Discover creators',
        'Browse TippingJar\'s creator directory. Search by name, category, or trending. Every creator has a public page showing their work, bio, and tip feed.',
        _green),
    (Icons.volunteer_activism, 'Choose your amount',
        'Pick a quick amount (R5 · R10 · R20 · R50) or enter a custom value. No account needed — tip anonymously or leave your name and a message.',
        _teal),
    (Icons.credit_card_rounded, 'Pay securely',
        'Enter your card details on our fully encrypted, PCI-DSS compliant checkout. Your payment info is never stored on TippingJar servers.',
        _blue),
    (Icons.check_circle_rounded, 'Tip confirmed!',
        'Your tip lands on the creator\'s page instantly. They\'ll see your name and message in real time. You\'ll receive an email receipt automatically.',
        _green),
  ];

  static const _creatorSteps = [
    (Icons.person_add_alt_1_rounded, 'Sign up as a creator',
        'Register with your email, pick a username, and select the "Creator" role. Your profile slug becomes your unique tip link: tippingjar.com/you.',
        _green),
    (Icons.palette_rounded, 'Customise your page',
        'Upload a cover photo and avatar, write a tagline, and set a monthly tip goal. Your page goes live the moment you save — no approval required.',
        _teal),
    (Icons.account_balance_rounded, 'Connect your bank',
        'Link your South African bank account in under 2 minutes. TippingJar never holds your money — funds go straight to your bank account.',
        _blue),
    (Icons.share_rounded, 'Share your link',
        'Post tippingjar.com/you anywhere — your bio, videos, newsletter, or Linktree. Every visit is a potential tip. Watch your jar fill up in real time.',
        _green),
  ];

  static const _faqs = [
    ('How much does TippingJar take?',
        'TippingJar charges a 3% platform fee per tip. A 3% payment processing fee (excl. VAT) also applies. No subscriptions, no hidden charges — just transparent, simple pricing.'),
    ('When do I get paid?',
        'Funds are settled to your linked bank account on a rolling basis after each successful tip. Payout timing depends on your bank but is typically within 1–2 business days.'),
    ('Do fans need an account to tip?',
        'No. Fans can tip completely anonymously without registering. They just need a card. If they want to track their tips, they can create a free account.'),
    ('Which countries are supported?',
        'TippingJar is currently available in South Africa only. Creators must be based in South Africa to receive payouts. We plan to expand to more countries soon.'),
    ('Is my payment information safe?',
        'Yes. TippingJar never stores card details. All payment data is handled through a PCI-DSS Level 1 certified payment processor — the highest level of payment security available.'),
    ('Can I set a monthly tip goal?',
        'Absolutely. Add a goal amount on your creator profile. A progress bar appears on your tip page, giving fans a tangible target to rally around.'),
    ('What if a tip is refunded?',
        'Fans can request a refund within 7 days of tipping. Refunds are processed and deducted from your next payout. TippingJar will notify you by email.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgWhite,
      appBar: AppNav(activeRoute: '/how-it-works'),
      body: ScrollConfiguration(
        behavior: _SmoothScroll(),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(children: [
            _hero(context),
            _tabSection(context),
            _timeline(context),
            _securityStrip(context),
            _faqSection(context),
            _cta(context),
            const SiteFooter(),
          ]),
        ),
      ),
    );
  }

  Widget _hero(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.width;
    final mobile = w < 700;
    return Container(
      width: double.infinity,
      color: _bgSage,
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _LightDotPainter())),
        Positioned.fill(
          child: Padding(
          padding: EdgeInsets.symmetric(vertical: mobile ? 64 : 92, horizontal: 28),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            _tag('How it works'),
            const SizedBox(height: 22),
            Text('Simple for fans.\nPowerful for creators.',
                style: GoogleFonts.dmSans(
                    color: _ink, fontWeight: FontWeight.w800,
                    fontSize: mobile ? 34 : 52,
                    height: 1.07, letterSpacing: mobile ? -1.5 : -2.2),
                textAlign: TextAlign.center)
                .animate().fadeIn(duration: 500.ms).slideY(begin: 0.15),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Text(
                'TippingJar removes every barrier between appreciation and action. No complicated setup, no waiting periods — just simple, transparent fees.',
                style: GoogleFonts.dmSans(color: _inkBody, fontSize: 16.5, height: 1.7),
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
          ]),
          )),
      ]),
    );
  }

  Widget _tabSection(BuildContext ctx) {
    final steps = _tab.index == 0 ? _fanSteps : _creatorSteps;
    return Container(
      color: _bgWhite,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: _bgSage,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: _border),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _tabBtn('I\'m a fan', 0),
            _tabBtn('I\'m a creator', 1),
          ]),
        ),
        const SizedBox(height: 56),
        Wrap(
          spacing: 24, runSpacing: 24,
          alignment: WrapAlignment.center,
          children: steps.asMap().entries.map((e) => _StepCard(
            number: e.key + 1,
            icon: e.value.$1,
            title: e.value.$2,
            body: e.value.$3,
            color: e.value.$4,
            delay: e.key * 100,
          )).toList(),
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
          color: active ? _green : Colors.transparent,
          borderRadius: BorderRadius.circular(40),
          boxShadow: active ? [BoxShadow(
              color: _green.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 3))] : [],
        ),
        child: Text(label, style: GoogleFonts.dmSans(
            color: active ? Colors.white : _inkMuted,
            fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
  }

  Widget _timeline(BuildContext ctx) {
    final items = [
      (_green,  'Fan visits creator\'s page'),
      (_teal,   'Picks an amount & adds a message'),
      (_blue,   'Pays securely — fully encrypted'),
      (_green,  'Creator receives funds in their bank account'),
      (_teal,   'Creator sees tip on their dashboard'),
    ];

    return Container(
      color: _bgSage,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      child: Column(children: [
        _tag('The full journey'),
        const SizedBox(height: 14),
        Text('From tap to payout',
            style: GoogleFonts.dmSans(color: _ink, fontWeight: FontWeight.w800,
                fontSize: 34, letterSpacing: -1.2),
            textAlign: TextAlign.center)
            .animate().fadeIn(duration: 500.ms),
        const SizedBox(height: 8),
        Text('Every step, clear and fast.',
            style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 15),
            textAlign: TextAlign.center),
        const SizedBox(height: 48),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(children: items.asMap().entries.map((e) => _TimelineRow(
            color: e.value.$1,
            label: e.value.$2,
            isLast: e.key == items.length - 1,
            delay: e.key * 100,
          )).toList()),
        ),
      ]),
    );
  }

  Widget _securityStrip(BuildContext ctx) {
    final badges = [
      (Icons.lock_rounded, 'PCI-DSS Level 1'),
      (Icons.verified_rounded, 'Bank-grade Encryption'),
      (Icons.shield_rounded, 'TLS in transit'),
      (Icons.no_encryption_gmailerrorred_rounded, 'Zero card data stored'),
    ];
    return Container(
      color: _bgWhite,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(children: [
        Text('Your money is safe.',
            style: GoogleFonts.dmSans(color: _ink,
                fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.8),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('All payments are secured end-to-end. We never see your card number.',
            style: GoogleFonts.dmSans(color: _inkBody, fontSize: 15),
            textAlign: TextAlign.center),
        const SizedBox(height: 36),
        Wrap(
          spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
          children: badges.asMap().entries.map((e) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                    blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                      color: _green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(e.value.$1, color: _green, size: 17),
                ),
                const SizedBox(width: 12),
                Text(e.value.$2, style: GoogleFonts.dmSans(
                    color: _ink, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ).animate().fadeIn(delay: (e.key * 80).ms, duration: 400.ms);
          }).toList(),
        ),
      ]),
    );
  }

  Widget _faqSection(BuildContext ctx) {
    return Container(
      color: _bgSage,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      child: Column(children: [
        _tag('FAQ'),
        const SizedBox(height: 14),
        Text('Common questions',
            style: GoogleFonts.dmSans(color: _ink, fontWeight: FontWeight.w800,
                fontSize: 34, letterSpacing: -1.2),
            textAlign: TextAlign.center),
        const SizedBox(height: 40),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
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

  Widget _cta(BuildContext ctx) {
    final mobile = MediaQuery.of(ctx).size.width < 680;
    return Container(
      color: _bgWhite,
      padding: EdgeInsets.fromLTRB(mobile ? 16 : 32, 72, mobile ? 16 : 32, 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Container(
            padding: EdgeInsets.fromLTRB(
                mobile ? 28 : 56, mobile ? 48 : 56,
                mobile ? 28 : 56, mobile ? 40 : 56),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF003D1F), Color(0xFF00622E), Color(0xFF007A38)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: _green.withOpacity(0.28),
                    blurRadius: 56, offset: const Offset(0, 20)),
              ],
            ),
            child: Column(children: [
              Text('Ready to start?',
                  style: GoogleFonts.dmSans(
                      color: Colors.white, fontWeight: FontWeight.w800,
                      fontSize: mobile ? 32 : 46,
                      height: 1.05, letterSpacing: -1.8),
                  textAlign: TextAlign.center)
                  .animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 14),
              Text('Set up your jar in 60 seconds — no credit card needed.',
                  style: GoogleFonts.dmSans(
                      color: Colors.white.withOpacity(0.60), fontSize: 16, height: 1.6),
                  textAlign: TextAlign.center)
                  .animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 32),
              Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
                ElevatedButton(
                  onPressed: () => ctx.go('/register'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, foregroundColor: _green,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 17),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                  ),
                  child: Text('Create your page →', style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.w700, color: _green)),
                ),
                OutlinedButton(
                  onPressed: () => ctx.go('/creators'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.30)),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 17),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                  ),
                  child: Text('Browse creators', style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.85))),
                ),
              ]).animate().fadeIn(delay: 200.ms)
                  .scale(begin: const Offset(0.94, 0.94), curve: Curves.easeOut),
              const SizedBox(height: 18),
              Text('No credit card · Free forever',
                  style: GoogleFonts.dmSans(
                      color: Colors.white.withOpacity(0.40), fontSize: 12))
                  .animate().fadeIn(delay: 280.ms),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _tag(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: _green.withOpacity(0.08),
      border: Border.all(color: _green.withOpacity(0.20)),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(label, style: GoogleFonts.dmSans(
        color: _greenMid, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}

// ─── Step card ────────────────────────────────────────────────────────────────
class _StepCard extends StatefulWidget {
  final int number;
  final IconData icon;
  final String title, body;
  final Color color;
  final int delay;
  const _StepCard({required this.number, required this.icon,
      required this.title, required this.body, required this.color, required this.delay});
  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: _hovered ? widget.color.withOpacity(0.35) : const Color(0xFFDBEAE1)),
          boxShadow: _hovered
              ? [BoxShadow(color: widget.color.withOpacity(0.10), blurRadius: 32, offset: const Offset(0, 10))]
              : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(widget.icon, color: widget.color, size: 22),
            ),
            const Spacer(),
            Text('0${widget.number}',
                style: GoogleFonts.dmSans(
                    color: widget.color.withOpacity(0.20), fontSize: 36,
                    fontWeight: FontWeight.w900, letterSpacing: -1)),
          ]),
          const SizedBox(height: 20),
          Text(widget.title, style: GoogleFonts.dmSans(
              color: const Color(0xFF080F0B), fontWeight: FontWeight.w700, fontSize: 17)),
          const SizedBox(height: 10),
          Text(widget.body, style: GoogleFonts.dmSans(
              color: const Color(0xFF7A9487), fontSize: 13.5, height: 1.65)),
        ]),
      ).animate().fadeIn(delay: widget.delay.ms, duration: 500.ms)
          .slideY(begin: 0.15, curve: Curves.easeOut),
    );
  }
}

// ─── Timeline row ─────────────────────────────────────────────────────────────
class _TimelineRow extends StatelessWidget {
  final Color color;
  final String label;
  final bool isLast;
  final int delay;
  const _TimelineRow({required this.color, required this.label,
      required this.isLast, required this.delay});
  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: color.withOpacity(0.10), shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.40), width: 2)),
          child: Icon(Icons.check_rounded, color: color, size: 16),
        ),
        if (!isLast)
          Container(width: 2, height: 40,
              color: const Color(0xFFDBEAE1)),
      ]),
      const SizedBox(width: 16),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 7, bottom: 16),
          child: Text(label, style: GoogleFonts.dmSans(
              color: const Color(0xFF080F0B), fontSize: 15, fontWeight: FontWeight.w500)),
        ),
      ),
    ]).animate().fadeIn(delay: delay.ms, duration: 400.ms)
        .slideX(begin: -0.08, curve: Curves.easeOut);
  }
}

// ─── FAQ item ─────────────────────────────────────────────────────────────────
class _FaqItem extends StatelessWidget {
  final String question, answer;
  final bool open;
  final VoidCallback onTap;
  const _FaqItem({required this.question, required this.answer,
      required this.open, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: open ? const Color(0xFF004423).withOpacity(0.35) : const Color(0xFFDBEAE1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(children: [
              Expanded(child: Text(question, style: GoogleFonts.dmSans(
                  color: const Color(0xFF080F0B), fontWeight: FontWeight.w600, fontSize: 15))),
              const SizedBox(width: 12),
              AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration: 200.ms,
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    color: open ? const Color(0xFF004423) : const Color(0xFF7A9487)),
              ),
            ]),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Text(answer, style: GoogleFonts.dmSans(
                color: const Color(0xFF38524A), fontSize: 14, height: 1.7)),
          ),
          crossFadeState: open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: 200.ms,
        ),
      ]),
    );
  }
}

// ─── Light dot painter ────────────────────────────────────────────────────────
class _LightDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF004423).withOpacity(0.06)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double x = 0; x <= size.width; x += spacing)
      for (double y = 0; y <= size.height; y += spacing)
        canvas.drawCircle(Offset(x, y), 1.2, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Smooth scroll ────────────────────────────────────────────────────────────
class _SmoothScroll extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}
