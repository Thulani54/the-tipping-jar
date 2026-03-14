import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_nav.dart';
import '../widgets/site_footer.dart';

// ─── Local palette (light) ────────────────────────────────────────────────────
const _bgWhite   = Colors.white;
const _bgSage    = Color(0xFFF5F9F6);
const _ink       = Color(0xFF080F0B);
const _inkBody   = Color(0xFF38524A);
const _inkMuted  = Color(0xFF7A9487);
const _border    = Color(0xFFDBEAE1);
const _cardBg    = Colors.white;
const _green     = Color(0xFF004423);
const _greenMid  = Color(0xFF006B3A);

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
        'Your personal URL works everywhere — bio, YouTube, Twitch, email. Zero setup beyond copy & paste.',
        _green),
    (Icons.bar_chart_rounded, 'Live dashboard',
        'See every tip the instant it arrives. Filter by date, amount, or tipper. Export your history as CSV.',
        Color(0xFF0097B2)),
    (Icons.flag_rounded, 'Monthly goal',
        'Set a public tip goal and watch a live progress bar motivate your fans to push you over the line.',
        Color(0xFF2563EB)),
    (Icons.palette_rounded, 'Page customisation',
        'Cover image, avatar, tagline, bio — make your page unmistakably yours. Changes go live in seconds.',
        _green),
    (Icons.account_balance_rounded, 'Fast payouts',
        'Your money arrives in your bank account quickly after each tip. No holding periods — straight to your bank.',
        Color(0xFF0097B2)),
    (Icons.notifications_rounded, 'Instant notifications',
        'Get an email the moment a fan tips you. Never miss a kind word.',
        Color(0xFF2563EB)),
  ];

  static const _fanFeatures = [
    (Icons.no_accounts_rounded, 'No account required',
        'Send a tip in under 30 seconds without registering. We only ask for a card — nothing else.',
        _green),
    (Icons.message_rounded, 'Personal messages',
        'Every tip can include a message up to 500 characters. Say what you\'ve been meaning to tell that creator.',
        Color(0xFF0097B2)),
    (Icons.history_rounded, 'Tip history',
        'Create a free fan account to see every tip you\'ve sent and follow your favourite creators.',
        Color(0xFF2563EB)),
    (Icons.favorite_rounded, 'Reaction emojis',
        'Add a reaction alongside your tip — 🔥 for fire content, ❤️ for love, 🎉 for milestones.',
        _green),
    (Icons.receipt_long_rounded, 'Instant receipts',
        'An email receipt lands in your inbox within seconds of every tip.',
        Color(0xFF0097B2)),
    (Icons.public_rounded, 'South Africa focused',
        'Built specifically for South African creators. Accept tips from fans locally and abroad.',
        Color(0xFF2563EB)),
  ];

  static const _platformFeatures = [
    (Icons.lock_rounded, 'PCI-DSS Level 1',
        'All card data is tokenised and encrypted before it leaves your browser. We never touch raw card numbers.',
        _green),
    (Icons.speed_rounded, 'Sub-second payments',
        'Our payment integration processes tips in under 800 ms on average. No spinners, no waiting.',
        Color(0xFF0097B2)),
    (Icons.devices_rounded, 'Responsive everywhere',
        'TippingJar works perfectly on desktop, tablet, and mobile. Adapts to any screen size.',
        Color(0xFF2563EB)),
    (Icons.api_rounded, 'REST API',
        'Our documented REST API lets you embed tips in your own apps and websites.',
        _green),
    (Icons.flag_rounded, 'Proudly South African',
        'Built and hosted in South Africa, for South African creators. Local support, local understanding.',
        Color(0xFF0097B2)),
    (Icons.support_agent_rounded, 'Real support',
        'Reach a human within 4 hours via email. We are here to help you grow.',
        Color(0xFF2563EB)),
  ];

  List<(IconData, String, String, Color)> get _currentFeatures {
    if (_tab.index == 0) return _creatorFeatures;
    if (_tab.index == 1) return _fanFeatures;
    return _platformFeatures;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgWhite,
      appBar: AppNav(activeRoute: '/features'),
      body: ScrollConfiguration(
        behavior: _SmoothScroll(),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(children: [
            _hero(context),
            _featureSection(context),
            _integrations(context),
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
          padding: EdgeInsets.symmetric(vertical: mobile ? 64 : 88, horizontal: 28),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            _tag('Features'),
            const SizedBox(height: 20),
            Text('Built for creators\nwho mean business.',
                style: GoogleFonts.dmSans(
                    color: _ink, fontWeight: FontWeight.w800,
                    fontSize: mobile ? 34 : 50, height: 1.08, letterSpacing: -2.0),
                textAlign: TextAlign.center)
                .animate().fadeIn(duration: 500.ms).slideY(begin: 0.15),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Text(
                'Every feature exists for one reason: to get more money into creators\' hands with less friction.',
                style: GoogleFonts.dmSans(color: _inkBody, fontSize: 16.5, height: 1.7),
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
          ]),
          )),
      ]),
    );
  }

  Widget _featureSection(BuildContext ctx) {
    final tabs = ['For creators', 'For fans', 'Platform'];
    return Container(
      color: _bgWhite,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      child: Column(children: [
        // Tab switcher
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: _bgSage,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: _border),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            ...tabs.asMap().entries.map((e) {
              final active = _tab.index == e.key;
              return GestureDetector(
                onTap: () => setState(() => _tab.animateTo(e.key)),
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? _green : Colors.transparent,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: active ? [BoxShadow(
                        color: _green.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 3))] : [],
                  ),
                  child: Text(e.value, style: GoogleFonts.dmSans(
                      color: active ? Colors.white : _inkMuted,
                      fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              );
            }),
          ]),
        ),
        const SizedBox(height: 56),
        Wrap(
          spacing: 20, runSpacing: 20, alignment: WrapAlignment.center,
          children: _currentFeatures.asMap().entries.map((e) => _FeatureCard(
            icon: e.value.$1, title: e.value.$2,
            body: e.value.$3, color: e.value.$4, delay: e.key * 70,
          )).toList(),
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
      color: _bgSage,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      child: Column(children: [
        _tag('Works with everything'),
        const SizedBox(height: 16),
        Text('Paste your link. Done.',
            style: GoogleFonts.dmSans(color: _ink, fontWeight: FontWeight.w800,
                fontSize: 34, letterSpacing: -1.2),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('No integrations to configure. One link works everywhere.',
            style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 15),
            textAlign: TextAlign.center),
        const SizedBox(height: 40),
        Wrap(
          spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
          children: items.asMap().entries.map((e) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                    blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(e.value.$1, color: _green, size: 18),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.value.$2, style: GoogleFonts.dmSans(
                      color: _ink, fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(e.value.$3, style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 11)),
                ]),
              ]),
            ).animate().fadeIn(delay: (e.key * 60).ms, duration: 400.ms);
          }).toList(),
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
              Text('Ready to start earning?',
                  style: GoogleFonts.dmSans(
                      color: Colors.white, fontWeight: FontWeight.w800,
                      fontSize: mobile ? 32 : 46,
                      height: 1.05, letterSpacing: -1.8),
                  textAlign: TextAlign.center)
                  .animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 14),
              Text('Create your free page in under a minute.',
                  style: GoogleFonts.dmSans(
                      color: Colors.white.withOpacity(0.60), fontSize: 16, height: 1.6),
                  textAlign: TextAlign.center)
                  .animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => ctx.go('/register'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, foregroundColor: _green,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                ),
                child: Text('Create your free page →',
                    style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: _green)),
              ).animate().fadeIn(delay: 200.ms)
                  .scale(begin: const Offset(0.94, 0.94), curve: Curves.easeOut),
              const SizedBox(height: 18),
              Text('No credit card · Free forever · Cancel anytime',
                  style: GoogleFonts.dmSans(
                      color: Colors.white.withOpacity(0.45), fontSize: 12))
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

// ─── Feature card ─────────────────────────────────────────────────────────────
class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title, body;
  final Color color;
  final int delay;
  const _FeatureCard({required this.icon, required this.title,
      required this.body, required this.color, required this.delay});
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _hovered ? widget.color.withOpacity(0.40) : const Color(0xFFDBEAE1)),
          boxShadow: _hovered
              ? [BoxShadow(color: widget.color.withOpacity(0.10), blurRadius: 28, offset: const Offset(0, 8))]
              : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: widget.color.withOpacity(0.09),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(widget.icon, color: widget.color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(widget.title, style: GoogleFonts.dmSans(
              color: const Color(0xFF080F0B), fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          Text(widget.body, style: GoogleFonts.dmSans(
              color: const Color(0xFF7A9487), fontSize: 13, height: 1.65)),
        ]),
      ).animate().fadeIn(delay: widget.delay.ms, duration: 400.ms)
          .slideY(begin: 0.12, curve: Curves.easeOut),
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
