import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_nav.dart';
import '../widgets/site_footer.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const _bgWhite    = Colors.white;
const _bgSage     = Color(0xFFF5F9F6);
const _ink        = Color(0xFF080F0B);
const _inkBody    = Color(0xFF38524A);
const _inkMuted   = Color(0xFF7A9487);
const _border     = Color(0xFFDBEAE1);
const _green      = Color(0xFF004423);
const _greenMid   = Color(0xFF006B3A);

class EnterpriseScreen extends StatelessWidget {
  const EnterpriseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgWhite,
      appBar: AppNav(activeRoute: '/enterprise'),
      body: ScrollConfiguration(
        behavior: _SmoothScroll(),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(children: [
            _hero(context),
            _logos(),
            _features(context),
            _cta(context),
            const SiteFooter(),
          ]),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final mobile = w < 700;
    return Container(
      width: double.infinity,
      color: _bgSage,
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _LightDotPainter())),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: mobile ? 64 : 96),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: _green.withOpacity(0.20)),
              ),
              child: Text('Enterprise', style: GoogleFonts.dmSans(
                  color: _greenMid, fontWeight: FontWeight.w600, fontSize: 12)),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 22),
            Text('Tipping at scale\nfor your platform',
                style: GoogleFonts.dmSans(
                    color: _ink, fontWeight: FontWeight.w800,
                    fontSize: mobile ? 34 : 54,
                    letterSpacing: -2.0, height: 1.05),
                textAlign: TextAlign.center)
                .animate().fadeIn(delay: 80.ms, duration: 500.ms).slideY(begin: 0.15),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                'Power fan monetisation for communities of any size. White-label, custom contracts, dedicated infrastructure, and a 99.99% SLA.',
                style: GoogleFonts.dmSans(color: _inkBody, fontSize: 17, height: 1.7),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 160.ms, duration: 500.ms),
            ),
            const SizedBox(height: 36),
            Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
              ElevatedButton(
                onPressed: () => context.go('/contact'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green, foregroundColor: Colors.white,
                  elevation: 0, shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                ),
                child: Text('Contact sales', style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
              ),
              OutlinedButton(
                onPressed: () => context.go('/enterprise-portal'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _ink,
                  side: BorderSide(color: _border),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                ),
                child: Text('Go to portal', style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600, fontSize: 15, color: _inkBody)),
              ),
            ]).animate().fadeIn(delay: 240.ms, duration: 500.ms),
          ]),
        ),
      ]),
    );
  }

  Widget _logos() => Container(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 28),
    color: _bgWhite,
    child: Column(children: [
      Container(height: 1, color: _border, margin: const EdgeInsets.only(bottom: 32)),
      Text('Trusted by leading platforms',
          style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 12,
              fontWeight: FontWeight.w600, letterSpacing: 0.8),
          textAlign: TextAlign.center),
      const SizedBox(height: 24),
      Wrap(
        spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
        children: ['Streamio', 'CreatorHub', 'FanBridge', 'PodPay', 'LiveLink', 'ArtPass']
            .map((name) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: _bgSage,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              child: Text(name, style: GoogleFonts.dmSans(
                  color: _inkMuted, fontWeight: FontWeight.w700, fontSize: 13)),
            ))
            .toList(),
      ),
      const SizedBox(height: 32),
      Container(height: 1, color: _border),
    ]),
  );

  Widget _features(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final features = [
      (Icons.shield_rounded,          'SOC 2 Type II',        'Fully audited security controls with annual third-party pen testing.'),
      (Icons.business_rounded,        'White-label',          'Your brand, your domain — TippingJar is invisible to your users.'),
      (Icons.api_rounded,             'Enterprise API',       'High-throughput REST + webhooks with dedicated rate limits.'),
      (Icons.support_agent_rounded,   'Dedicated support',    '24/7 Slack channel with a named account manager and 1-hour SLA.'),
      (Icons.account_balance_rounded, 'Custom payouts',       'Bespoke settlement schedules, multi-currency, and T+1 options.'),
      (Icons.analytics_rounded,       'Advanced analytics',   'Real-time dashboards, cohort analysis, and raw data exports.'),
      (Icons.lock_rounded,            'SSO & SCIM',           'SAML 2.0, OIDC, Okta, and Azure AD provisioning out of the box.'),
      (Icons.tune_rounded,            'Custom contracts',     'Volume pricing, MSA, BAA, and data processing agreements.'),
    ];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 72),
      color: _bgSage,
      child: Column(children: [
        Text('Built for the enterprise',
            style: GoogleFonts.dmSans(color: _ink, fontWeight: FontWeight.w800,
                fontSize: 34, letterSpacing: -1.2),
            textAlign: TextAlign.center)
            .animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 8),
        Text('Everything you need to run tipping at scale.',
            style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 15),
            textAlign: TextAlign.center),
        const SizedBox(height: 48),
        Wrap(
          spacing: 16, runSpacing: 16,
          alignment: WrapAlignment.center,
          children: features.asMap().entries.map((e) => _FeatureCard(
            icon: e.value.$1, title: e.value.$2, body: e.value.$3, delay: 60 * e.key,
          )).toList(),
        ),
      ]),
    );
  }

  Widget _cta(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width < 680;
    return Container(
      color: _bgWhite,
      padding: EdgeInsets.fromLTRB(mobile ? 16 : 32, 72, mobile ? 16 : 32, 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Container(
            padding: EdgeInsets.fromLTRB(
                mobile ? 28 : 56, mobile ? 48 : 60,
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
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.business_rounded, color: Colors.white, size: 26),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 20),
              Text('Ready to talk?',
                  style: GoogleFonts.dmSans(
                      color: Colors.white, fontWeight: FontWeight.w800,
                      fontSize: mobile ? 32 : 46,
                      height: 1.05, letterSpacing: -1.8),
                  textAlign: TextAlign.center)
                  .animate().fadeIn(delay: 80.ms),
              const SizedBox(height: 12),
              Text('Our sales team will respond within one business day.',
                  style: GoogleFonts.dmSans(
                      color: Colors.white.withOpacity(0.60), fontSize: 16, height: 1.6),
                  textAlign: TextAlign.center)
                  .animate().fadeIn(delay: 140.ms),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/contact'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, foregroundColor: _green,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                ),
                child: Text('Schedule a demo', style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700, fontSize: 15, color: _green)),
              ).animate().fadeIn(delay: 200.ms)
                  .scale(begin: const Offset(0.94, 0.94), curve: Curves.easeOut),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Feature card ─────────────────────────────────────────────────────────────
class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title, body;
  final int delay;
  const _FeatureCard({required this.icon, required this.title,
      required this.body, required this.delay});
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _hovered ? const Color(0xFF004423).withOpacity(0.35) : const Color(0xFFDBEAE1)),
          boxShadow: _hovered
              ? [BoxShadow(color: const Color(0xFF004423).withOpacity(0.10),
                  blurRadius: 24, offset: const Offset(0, 8))]
              : [BoxShadow(color: Colors.black.withOpacity(0.04),
                  blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF004423).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.icon, color: const Color(0xFF004423), size: 20),
          ),
          const SizedBox(height: 14),
          Text(widget.title, style: GoogleFonts.dmSans(
              color: const Color(0xFF080F0B), fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 6),
          Text(widget.body, style: GoogleFonts.dmSans(
              color: const Color(0xFF7A9487), fontSize: 13, height: 1.6)),
        ]),
      ).animate().fadeIn(delay: widget.delay.ms, duration: 400.ms)
          .slideY(begin: 0.1, curve: Curves.easeOut),
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
