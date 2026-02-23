import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/app_nav.dart';

class FeaturesScreen extends StatefulWidget {
  const FeaturesScreen({super.key});
  @override
  State<FeaturesScreen> createState() => _FeaturesScreenState();
}

class _FeaturesScreenState extends State<FeaturesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  static const _creatorFeatures = [
    (Icons.link_rounded, 'Shareable tip link',
        'Your personal URL (tippingjar.com/you) works everywhere — bio, YouTube, Twitch, email. Zero setup beyond copy & paste.',
        kPrimary),
    (Icons.bar_chart_rounded, 'Live dashboard',
        'See every tip the instant it arrives. Filter by date, amount, or tipper. Export your tip history as CSV for accounting.',
        kTeal),
    (Icons.flag_rounded, 'Monthly goal',
        'Set a public tip goal and watch a live progress bar motivate your fans to push you over the line.',
        kBlue),
    (Icons.palette_rounded, 'Page customisation',
        'Cover image, avatar, tagline, bio — make your page unmistakably yours. Changes go live in seconds.',
        kPrimary),
    (Icons.account_balance_rounded, 'Fast payouts',
        'Your money arrives in your bank account quickly after each tip. No holding periods — funds go straight to your bank.',
        kTeal),
    (Icons.notifications_rounded, 'Instant notifications',
        'Get an email or push notification the moment a fan tips you. Never miss a kind word.',
        kBlue),
  ];

  static const _fanFeatures = [
    (Icons.no_accounts_rounded, 'No account required',
        'Send a tip in under 30 seconds without registering. We only ask for a card number — nothing else.',
        kPrimary),
    (Icons.message_rounded, 'Personal messages',
        'Every tip can include a message up to 500 characters. Say what you\'ve been meaning to tell that creator.',
        kTeal),
    (Icons.history_rounded, 'Tip history',
        'Create a free fan account to see every tip you\'ve sent, download receipts, and follow your favourite creators.',
        kBlue),
    (Icons.favorite_rounded, 'Reaction emojis',
        'Add a reaction alongside your tip — 🔥 for fire content, ❤️ for love, 🎉 for milestones.',
        kPrimary),
    (Icons.receipt_long_rounded, 'Instant receipts',
        'An email receipt lands in your inbox within seconds of every tip. Forward it, save it, or use it as proof of support.',
        kTeal),
    (Icons.public_rounded, 'South Africa focused',
        'Built specifically for South African creators. Accept tips from fans locally and abroad using major cards.',
        kBlue),
  ];

  static const _platformFeatures = [
    (Icons.lock_rounded, 'PCI-DSS Level 1',
        'All card data is tokenised and encrypted before it ever leaves your browser. TippingJar never touches raw card numbers.',
        kPrimary),
    (Icons.speed_rounded, 'Sub-second payments',
        'Our payment integration processes tips in under 800 ms on average. No spinners, no waiting.',
        kTeal),
    (Icons.devices_rounded, 'Responsive everywhere',
        'TippingJar works perfectly on desktop, tablet, and mobile. The Flutter web app adapts to any screen size.',
        kBlue),
    (Icons.api_rounded, 'REST API',
        'Build on top of TippingJar. Our documented REST API lets you embed tips in your own apps and websites.',
        kPrimary),
    (Icons.flag_rounded, 'Proudly South African',
        'Built and hosted in South Africa, for South African creators. Local support, local understanding.',
        kTeal),
    (Icons.support_agent_rounded, 'Real support',
        'Reach a human within 4 hours via email. We are here to help you grow.',
        kBlue),
  ];

  List<(IconData, String, String, Color)> get _currentFeatures {
    if (_tab.index == 0) return _creatorFeatures;
    if (_tab.index == 1) return _fanFeatures;
    return _platformFeatures;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      appBar: AppNav(activeRoute: '/features'),
      body: SingleChildScrollView(
        child: Column(children: [
          _hero(context),
          _featureSection(context),
          _integrations(context),
          _cta(context),
          _footer(),
        ]),
      ),
    );
  }

  Widget _hero(BuildContext ctx) {
    return Container(
      width: double.infinity,
      color: kDarker,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
            child: Column(children: [
              _tag('Features'),
              const SizedBox(height: 20),
              Text('Built for creators\nwho mean business.',
                  style: headingXL(ctx), textAlign: TextAlign.center)
                  .animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: const Text(
                  'Every feature on TippingJar exists for one reason: to get more money into creators\' hands with less friction.',
                  style: kBodyStyle, textAlign: TextAlign.center,
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _featureSection(BuildContext ctx) {
    final tabs = ['For creators', 'For fans', 'Platform'];
    return Container(
      color: kDark,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      child: Column(children: [
        // Tab switcher
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: kBorder),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            ...tabs.asMap().entries.map((e) {
              final active = _tab.index == e.key;
              return GestureDetector(
                onTap: () => setState(() => _tab.animateTo(e.key)),
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? kPrimary : null,
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: Text(e.value,
                      style: GoogleFonts.dmSans(
                          color: active ? Colors.white : kMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
              );
            }),
          ]),
        ),
        const SizedBox(height: 56),
        Wrap(
          spacing: 20, runSpacing: 20, alignment: WrapAlignment.center,
          children: _currentFeatures.asMap().entries.map((e) {
            return _FeatureCard(
              icon: e.value.$1, title: e.value.$2,
              body: e.value.$3, color: e.value.$4, delay: e.key * 70,
            );
          }).toList(),
        ),
      ]),
    );
  }

  Widget _integrations(BuildContext ctx) {
    final items = [
      (Icons.play_circle_rounded, 'YouTube', 'Link in description'),
      (Icons.camera_alt_rounded, 'Instagram', 'Bio link'),
      (Icons.chat_bubble_rounded, 'Twitter / X', 'Pinned tweet'),
      (Icons.video_call_rounded, 'Twitch', 'Panel link'),
      (Icons.email_rounded, 'Newsletter', 'Footer CTA'),
    ];
    return Container(
      color: kDark,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      child: Column(children: [
        _tag('Works with everything'),
        const SizedBox(height: 16),
        Text('Paste your link. Done.',
            style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800,
                fontSize: 32, letterSpacing: -1),
            textAlign: TextAlign.center),
        const SizedBox(height: 40),
        Wrap(
          spacing: 14, runSpacing: 14, alignment: WrapAlignment.center,
          children: items.asMap().entries.map((e) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: kCardBg, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(e.value.$1, color: kPrimary, size: 18),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.value.$2, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(e.value.$3, style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
                ]),
              ]),
            ).animate().fadeIn(delay: (e.key * 60).ms, duration: 400.ms);
          }).toList(),
        ),
      ]),
    );
  }

  Widget _cta(BuildContext ctx) => Container(
    color: kDarker,
    padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
    child: Column(children: [
      Text('Get started for free — no credit card needed.',
          style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800,
              fontSize: 30, letterSpacing: -1),
          textAlign: TextAlign.center),
      const SizedBox(height: 28),
      ElevatedButton(
        onPressed: () => ctx.go('/register'),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary, foregroundColor: Colors.white,
          shadowColor: Colors.transparent, elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
        ),
        child: Text('Create your free page →',
            style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    ]),
  );

  Widget _footer() => Container(
    color: kDarker,
    padding: const EdgeInsets.all(24),
    child: const Text('© 2026 TippingJar. All rights reserved.',
        style: TextStyle(color: kMuted, fontSize: 12), textAlign: TextAlign.center),
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

// ─── Feature card ─────────────────────────────────────────────────────────────
class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title, body;
  final Color color;
  final int delay;
  const _FeatureCard({required this.icon, required this.title, required this.body, required this.color, required this.delay});
  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}
class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: 200.ms,
        width: 280,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _hovered ? widget.color.withOpacity(0.5) : kBorder),
          boxShadow: _hovered ? [BoxShadow(color: widget.color.withOpacity(0.12), blurRadius: 32, offset: const Offset(0, 8))] : [],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: widget.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(widget.icon, color: widget.color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(widget.title, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          Text(widget.body, style: GoogleFonts.dmSans(color: kMuted, fontSize: 13, height: 1.65)),
        ]),
      ).animate().fadeIn(delay: widget.delay.ms, duration: 400.ms).slideY(begin: 0.15, curve: Curves.easeOut),
    );
  }
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
