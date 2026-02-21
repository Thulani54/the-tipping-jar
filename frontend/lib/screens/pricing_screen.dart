import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/app_nav.dart';

class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      appBar: AppNav(activeRoute: '/pricing'),
      body: SingleChildScrollView(
        child: Column(children: [
          _hero(),
          _tiers(context),
          _compare(),
          _faq(),
          _cta(context),
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
        child: Text('Pricing', style: GoogleFonts.inter(
            color: kPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
      ).animate().fadeIn(duration: 400.ms),
      const SizedBox(height: 20),
      Text('Simple, transparent pricing',
          style: GoogleFonts.inter(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 42, letterSpacing: -1.5),
          textAlign: TextAlign.center)
          .animate().fadeIn(delay: 80.ms).slideY(begin: 0.2),
      const SizedBox(height: 14),
      Text('Start free. Upgrade when you\'re ready. No hidden fees.',
          style: GoogleFonts.inter(color: kMuted, fontSize: 17, height: 1.6),
          textAlign: TextAlign.center)
          .animate().fadeIn(delay: 160.ms),
    ]),
  );

  Widget _tiers(BuildContext ctx) => Container(
    padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 28),
    color: kDark,
    child: Wrap(
      spacing: 24, runSpacing: 24, alignment: WrapAlignment.center,
      children: [
        _TierCard(
          name: 'Free', price: '\$0', period: '/month',
          desc: 'Perfect for getting started',
          features: [
            'Unlimited tips received',
            '5% platform fee per tip',
            'Public tip page',
            'Basic analytics',
            'Email notifications',
            'Stripe payouts (T+2)',
          ],
          cta: 'Get started free', isPro: false, ctx: ctx,
        ),
        _TierCard(
          name: 'Pro', price: '\$12', period: '/month',
          desc: 'For creators serious about growth',
          features: [
            'Everything in Free',
            '2.5% platform fee per tip',
            'Custom domain',
            'Advanced analytics & exports',
            'Priority payouts (T+1)',
            'Custom tip amounts & goals',
            'Remove TippingJar branding',
            'Priority email support',
          ],
          cta: 'Start Pro — 14 days free', isPro: true, ctx: ctx,
        ),
        _TierCard(
          name: 'Enterprise', price: 'Custom', period: '',
          desc: 'For platforms & large communities',
          features: [
            'Everything in Pro',
            'Custom platform fee',
            'White-label branding',
            'SSO & SCIM provisioning',
            'Dedicated account manager',
            'SLA guarantee',
            'Custom payout schedules',
            'Data processing agreement',
          ],
          cta: 'Contact sales', isPro: false, ctx: ctx,
        ),
      ],
    ),
  );

  Widget _compare() => Container(
    padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 28),
    color: kDarker,
    child: Column(children: [
      Text('Compare plans', style: GoogleFonts.inter(color: Colors.white,
          fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.8),
          textAlign: TextAlign.center),
      const SizedBox(height: 36),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
          },
          children: [
            _tableHeader(),
            ...[
              ('Platform fee',         '5%',      '2.5%',   'Custom'),
              ('Payouts',              'T+2',     'T+1',    'Custom'),
              ('Custom domain',        '✕',       '✓',      '✓'),
              ('Remove branding',      '✕',       '✓',      '✓'),
              ('Advanced analytics',   '✕',       '✓',      '✓'),
              ('Priority support',     '✕',       '✓',      '✓'),
              ('White-label',          '✕',       '✕',      '✓'),
              ('SSO & SCIM',           '✕',       '✕',      '✓'),
              ('SLA',                  '✕',       '✕',      '✓'),
            ].asMap().entries.map((e) => _tableRow(e.value, e.key.isEven)),
          ],
        ),
      ),
    ]),
  );

  TableRow _tableHeader() => TableRow(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: kBorder, width: 1.5)),
    ),
    children: ['Feature', 'Free', 'Pro', 'Enterprise'].map((h) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Text(h, style: GoogleFonts.inter(
            color: h == 'Pro' ? kPrimary : Colors.white,
            fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    ).toList(),
  );

  TableRow _tableRow((String, String, String, String) row, bool shaded) {
    final cells = [row.$1, row.$2, row.$3, row.$4];
    return TableRow(
      decoration: BoxDecoration(
        color: shaded ? kCardBg.withOpacity(0.4) : Colors.transparent,
      ),
      children: cells.asMap().entries.map((e) {
        final isCheck = e.value == '✓';
        final isCross = e.value == '✕';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Text(e.value,
              style: GoogleFonts.inter(
                  color: isCheck ? kPrimary : isCross ? kMuted.withOpacity(0.4) : kMuted,
                  fontSize: 13,
                  fontWeight: e.key == 0 ? FontWeight.w500 : FontWeight.w600)),
        );
      }).toList(),
    );
  }

  Widget _faq() => Container(
    padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 28),
    color: kDark,
    child: Column(children: [
      Text('Frequently asked', style: GoogleFonts.inter(color: Colors.white,
          fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.8),
          textAlign: TextAlign.center),
      const SizedBox(height: 36),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(children: [
          _FaqItem('Is the Free plan really free?',
              'Yes. You keep your page, receive unlimited tips, and pay zero monthly fee. We only take a 5% cut of each tip received.'),
          _FaqItem('When do I get paid?',
              'Free creators receive payouts 2 business days after a tip is processed. Pro creators get next-day payouts.'),
          _FaqItem('Can I cancel anytime?',
              'Absolutely. Cancel your Pro subscription any time from your dashboard — no lock-in, no questions asked.'),
          _FaqItem('What payment methods do fans use?',
              'Fans can tip via any major credit or debit card, Apple Pay, and Google Pay. Stripe handles all processing.'),
          _FaqItem('Do you offer refunds?',
              'Tips are non-refundable by default. If you believe a fraudulent tip occurred, contact our support team within 7 days.'),
        ]),
      ),
    ]),
  );

  Widget _cta(BuildContext ctx) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
    padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 40),
    decoration: BoxDecoration(
      color: kCardBg,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: kBorder),
    ),
    child: Column(children: [
      Text('Start for free today',
          style: GoogleFonts.inter(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.8),
          textAlign: TextAlign.center),
      const SizedBox(height: 10),
      Text('No credit card required. Upgrade whenever you want.',
          style: GoogleFonts.inter(color: kMuted, fontSize: 15),
          textAlign: TextAlign.center),
      const SizedBox(height: 28),
      ElevatedButton(
        onPressed: () => ctx.go('/register'),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary, foregroundColor: Colors.white,
          elevation: 0, shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
        ),
        child: Text('Create your free page →',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
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

class _TierCard extends StatelessWidget {
  final String name, price, period, desc, cta;
  final List<String> features;
  final bool isPro;
  final BuildContext ctx;
  const _TierCard({required this.name, required this.price, required this.period,
      required this.desc, required this.features, required this.cta,
      required this.isPro, required this.ctx});

  @override
  Widget build(BuildContext context) => Container(
    width: 300,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: kCardBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
          color: isPro ? kPrimary.withOpacity(0.5) : kBorder,
          width: isPro ? 2 : 1),
      boxShadow: isPro ? [BoxShadow(
          color: kPrimary.withOpacity(0.08), blurRadius: 40, offset: const Offset(0, 12))] : [],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (isPro) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(36)),
          child: Text('Most popular', style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
        ),
        const SizedBox(height: 12),
      ],
      Text(name, style: GoogleFonts.inter(
          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
      const SizedBox(height: 4),
      Text(desc, style: GoogleFonts.inter(color: kMuted, fontSize: 13)),
      const SizedBox(height: 16),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(price, style: GoogleFonts.inter(
            color: isPro ? kPrimary : Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: price.length > 4 ? 26 : 40, letterSpacing: -1.5)),
        if (period.isNotEmpty) ...[
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(period, style: GoogleFonts.inter(color: kMuted, fontSize: 13)),
          ),
        ],
      ]),
      const SizedBox(height: 24),
      ...features.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(children: [
          Icon(Icons.check_circle_rounded, color: kPrimary, size: 15),
          const SizedBox(width: 9),
          Expanded(child: Text(f, style: GoogleFonts.inter(
              color: Colors.white, fontSize: 13))),
        ]),
      )),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: isPro
            ? ElevatedButton(
                onPressed: () => ctx.go('/register'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary, foregroundColor: Colors.white,
                  elevation: 0, shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                ),
                child: Text(cta, style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              )
            : OutlinedButton(
                onPressed: () => name == 'Enterprise' ? null : ctx.go('/register'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: kBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                ),
                child: Text(cta, style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
      ),
    ]),
  );
}

class _FaqItem extends StatefulWidget {
  final String q, a;
  const _FaqItem(this.q, this.a);
  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _open = false;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: kCardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _open ? kPrimary.withOpacity(0.4) : kBorder),
    ),
    child: Column(children: [
      GestureDetector(
        onTap: () => setState(() => _open = !_open),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: Text(widget.q, style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
            AnimatedRotation(
              turns: _open ? 0.25 : 0,
              duration: 200.ms,
              child: Icon(Icons.chevron_right_rounded, color: kMuted, size: 20),
            ),
          ]),
        ),
      ),
      AnimatedCrossFade(
        firstChild: const SizedBox.shrink(),
        secondChild: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(widget.a, style: GoogleFonts.inter(
              color: kMuted, fontSize: 13, height: 1.6)),
        ),
        crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: 200.ms,
      ),
    ]),
  );
}
