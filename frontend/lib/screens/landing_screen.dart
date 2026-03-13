import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_logo.dart';

// ─── Palette ─────────────────────────────────────────────────────────────────
const _green      = Color(0xFF004423);
const _greenLight = Color(0xFF006B3A);
const _greenGlow  = Color(0xFFD1F0DF);
const _bgWhite    = Colors.white;
const _bgSage     = Color(0xFFF6FAF7);
const _bgSageDeep = Color(0xFFEEF6F1);
const _ink        = Color(0xFF0A1612);
const _inkBody    = Color(0xFF3D5248);
const _inkMuted   = Color(0xFF7C9489);
const _border     = Color(0xFFDEECE4);
const _darkFooter = Color(0xFF050C08);
const _darkScreen = Color(0xFF0F1A14);
const _white      = Colors.white;

const _blue   = Color(0xFF2563EB);
const _cyan   = Color(0xFF0097B2);
const _teal   = Color(0xFF0D9488);
const _violet = Color(0xFF7C3AED);

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _scroll = ScrollController();
  bool _navSolid = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final solid = _scroll.offset > 40;
      if (solid != _navSolid) setState(() => _navSolid = solid);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgWhite,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scroll,
            child: Column(
              children: [
                const _HeroSection(),
                const _StatsStrip(),
                _HowItWorksSection(),
                _FeaturesSection(),
                _CreatorSpotlightSection(),
                _CtaSection(),
                _Footer(),
              ],
            ),
          ),
          _NavBar(solid: _navSolid),
        ],
      ),
    );
  }
}

// ─── Navbar ───────────────────────────────────────────────────────────────────
class _NavBar extends StatelessWidget {
  final bool solid;
  const _NavBar({required this.solid});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return AnimatedContainer(
      duration: 200.ms,
      decoration: BoxDecoration(
        color: solid ? _bgWhite.withOpacity(0.96) : Colors.transparent,
        border: solid
            ? const Border(bottom: BorderSide(color: Color(0xFFE8F0EB), width: 1))
            : const Border(),
        boxShadow: solid
            ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 2))]
            : [],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w > 900 ? 64 : 24, vertical: 16),
          child: Row(
            children: [
              Row(children: [
                const AppLogoIcon(size: 30),
                const SizedBox(width: 9),
                Text('TippingJar',
                    style: GoogleFonts.dmSans(
                        color: _ink, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.4)),
              ]),
              const Spacer(),
              if (w > 1020) ...[
                _navLink('Features', context, '/features'),
                _navLink('How it works', context, '/how-it-works'),
                if (DateTime.now().isAfter(DateTime(2026, 3, 23)))
                  _navLink('Creators', context, '/creators'),
                _navLink('Enterprise', context, '/enterprise'),
                _navLink('Blog', context, '/blog'),
                _navLink('Developers', context, '/developers'),
                const SizedBox(width: 12),
              ],
              GestureDetector(
                onTap: () => context.go('/login'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Text('Sign in',
                      style: GoogleFonts.dmSans(
                          color: _inkBody, fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(width: 4),
              _solidBtn('Get started →', () => context.go('/register')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navLink(String label, BuildContext ctx, String route) => GestureDetector(
        onTap: () => ctx.go(route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label,
              style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      );

  Widget _solidBtn(String label, VoidCallback onTap) => ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: _white,
          shadowColor: _green.withOpacity(0.30),
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        ),
        child: Text(label, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
      );
}

// ─── Hero ─────────────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final narrow = w < 900;

    return Container(
      width: double.infinity,
      color: _bgWhite,
      child: Stack(
        children: [
          // Fine dot grid
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
          // Green mesh gradient top-right
          Positioned(
            top: -100, right: -100,
            child: Container(
              width: 700, height: 700,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _greenGlow.withOpacity(0.55),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(narrow ? 24 : 64, 110, narrow ? 24 : 64, 72),
            child: narrow ? _narrowLayout(context) : _wideLayout(context),
          ),
        ],
      ),
    );
  }

  Widget _wideLayout(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _badge().animate().fadeIn(duration: 500.ms).slideY(begin: 0.3, curve: Curves.easeOut),
                const SizedBox(height: 28),
                _headline(64, TextAlign.left)
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 600.ms)
                    .slideY(begin: 0.2, curve: Curves.easeOut),
                const SizedBox(height: 22),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Text(
                    'Set up your TippingJar page in 60 seconds. Share one link. Let fans support you — no subscriptions, no friction.',
                    style: GoogleFonts.dmSans(color: _inkBody, fontSize: 16.5, height: 1.7),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.2, curve: Curves.easeOut),
                const SizedBox(height: 36),
                _ctaRow(context)
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 500.ms)
                    .slideY(begin: 0.15, curve: Curves.easeOut),
                const SizedBox(height: 28),
                _socialProof()
                    .animate()
                    .fadeIn(delay: 420.ms, duration: 500.ms),
              ],
            ),
          ),
          const SizedBox(width: 56),
          Expanded(
            child: const _PhoneMockup()
                .animate()
                .fadeIn(delay: 300.ms, duration: 700.ms)
                .slideX(begin: 0.06, curve: Curves.easeOut),
          ),
        ],
      );

  Widget _narrowLayout(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _badge().animate().fadeIn(duration: 500.ms).slideY(begin: 0.3, curve: Curves.easeOut),
          const SizedBox(height: 24),
          _headline(40, TextAlign.center)
              .animate()
              .fadeIn(delay: 100.ms, duration: 600.ms)
              .slideY(begin: 0.2, curve: Curves.easeOut),
          const SizedBox(height: 16),
          Text(
            'Set up your TippingJar page in 60 seconds. Share one link. Let fans support you — no subscriptions, no friction.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(color: _inkBody, fontSize: 15, height: 1.7),
          ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.2, curve: Curves.easeOut),
          const SizedBox(height: 28),
          _ctaRow(context)
              .animate()
              .fadeIn(delay: 300.ms, duration: 500.ms),
          const SizedBox(height: 24),
          _socialProof().animate().fadeIn(delay: 400.ms, duration: 500.ms),
          const SizedBox(height: 48),
          const _PhoneMockup()
              .animate()
              .fadeIn(delay: 500.ms, duration: 700.ms)
              .slideY(begin: 0.1, curve: Curves.easeOut),
        ],
      );

  // Headline with "love" highlighted in green
  Widget _headline(double size, TextAlign align) => Text.rich(
        TextSpan(
          style: GoogleFonts.dmSans(
            color: _ink, fontSize: size, fontWeight: FontWeight.w800,
            height: 1.06, letterSpacing: size > 50 ? -2.5 : -1.2,
          ),
          children: const [
            TextSpan(text: 'Get paid by the people\nwho '),
            TextSpan(text: 'love', style: TextStyle(color: _green)),
            TextSpan(text: ' your work.'),
          ],
        ),
        textAlign: align,
      );

  Widget _badge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: _green.withOpacity(0.07),
          border: Border.all(color: _green.withOpacity(0.20)),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.55), blurRadius: 6, spreadRadius: 1)],
            ),
          ),
          const SizedBox(width: 9),
          Text("South Africa's creator tipping platform",
              style: GoogleFonts.dmSans(color: _green, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _ctaRow(BuildContext context) => Wrap(
        spacing: 12,
        runSpacing: 10,
        children: [
          ElevatedButton(
            onPressed: () => context.go('/register'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: _white,
              elevation: 3,
              shadowColor: _green.withOpacity(0.35),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 17),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            ),
            child: Text('Create your free page →',
                style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          if (DateTime.now().isAfter(DateTime(2026, 3, 23)))
            OutlinedButton(
              onPressed: () => context.go('/creators'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _green,
                side: BorderSide(color: _green.withOpacity(0.30)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 17),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
              ),
              child: Text('View Creators',
                  style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: _green)),
            ),
        ],
      );

  Widget _socialProof() {
    final avatars = [
      (const Color(0xFF0097B2), 'M'),
      (const Color(0xFF7C3AED), 'R'),
      (_green, 'L'),
      (const Color(0xFF0D9488), 'S'),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar stack
        SizedBox(
          width: 88,
          height: 32,
          child: Stack(
            children: avatars.asMap().entries.map((e) => Positioned(
              left: e.key * 20.0,
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: e.value.$1,
                  shape: BoxShape.circle,
                  border: Border.all(color: _bgWhite, width: 2),
                ),
                child: Center(child: Text(e.value.$2,
                    style: GoogleFonts.dmSans(color: _white, fontWeight: FontWeight.w700, fontSize: 11))),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              for (int i = 0; i < 5; i++)
                const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 13),
            ]),
            const SizedBox(height: 2),
            Text('Loved by 10,000+ creators',
                style: GoogleFonts.dmSans(color: _inkBody, fontSize: 12.5, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}

// ─── Dot grid ─────────────────────────────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF004423).withOpacity(0.045)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double x = 0; x <= size.width + spacing; x += spacing) {
      for (double y = 0; y <= size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Stats strip ──────────────────────────────────────────────────────────────
class _StatsStrip extends StatelessWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final stats = [
      ('10,000+', 'Creators'),
      ('R2M+', 'In tips paid'),
      ('48', 'Countries'),
      ('60 sec', 'To get started'),
    ];

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _bgSage,
        border: Border.symmetric(
          horizontal: BorderSide(color: _border, width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: 28, horizontal: w > 900 ? 64 : 24),
      child: w < 600
          ? Wrap(
              spacing: 32,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: stats.map(_statItem).toList(),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: stats.map(_statItem).toList(),
            ),
    );
  }

  Widget _statItem((String, String) s) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(s.$1,
              style: GoogleFonts.dmSans(
                  color: _green, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
          const SizedBox(height: 2),
          Text(s.$2,
              style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      );
}

// ─── Phone mockup ─────────────────────────────────────────────────────────────
class _PhoneMockup extends StatelessWidget {
  const _PhoneMockup();

  static const _frame = Color(0xFF1C1C1E);
  static const _frameEdge = Color(0xFF48484A);
  static const _frameBtn = Color(0xFF3A3A3C);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 6),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Glow pool under phone
              Positioned(
                left: 20, right: 20, bottom: -16,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: _green.withOpacity(0.28),
                        blurRadius: 70,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
              IntrinsicHeight(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 2.5),
                      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                        const SizedBox(height: 80),
                        _btn(22),
                        const SizedBox(height: 16),
                        _btn(50),
                        const SizedBox(height: 10),
                        _btn(50),
                      ]),
                    ),
                    Flexible(child: _body()),
                    Padding(
                      padding: const EdgeInsets.only(left: 2.5),
                      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                        const SizedBox(height: 128),
                        _btn(70),
                      ]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn(double h) => Container(
        width: 4, height: h,
        decoration: BoxDecoration(color: _frameBtn, borderRadius: BorderRadius.circular(2)));

  Widget _body() => Container(
        decoration: BoxDecoration(
          color: _frame,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: _frameEdge, width: 1.2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 60, offset: const Offset(0, 28)),
            BoxShadow(color: _green.withOpacity(0.10), blurRadius: 80, spreadRadius: -4),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(49),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [_statusBar(), _screen(), _homeBar()],
              ),
              // Glass sheen
              Positioned(
                top: 0, left: 0, right: 0,
                child: IgnorePointer(
                  child: Container(
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(49)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [Colors.white.withOpacity(0.06), Colors.transparent],
                        stops: const [0.0, 0.5],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _statusBar() => Container(
        height: 52,
        color: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 108, height: 28,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2A2A2E), width: 1),
              ),
            ),
            Row(children: [
              Text('9:41',
                  style: GoogleFonts.dmSans(
                      color: _white, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
              const Spacer(),
              Row(crossAxisAlignment: CrossAxisAlignment.end,
                  children: [4.0, 7.0, 10.0, 13.0].map((h) => Padding(
                        padding: const EdgeInsets.only(left: 1.5),
                        child: Container(
                          width: 3, height: h,
                          decoration: BoxDecoration(
                              color: _white, borderRadius: BorderRadius.circular(0.5)),
                        ),
                      )).toList()),
              const SizedBox(width: 5),
              const Icon(Icons.wifi_rounded, color: _white, size: 13),
              const SizedBox(width: 4),
              Container(
                width: 22, height: 11,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: _white.withOpacity(0.4), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(1.5),
                  child: FractionallySizedBox(
                    widthFactor: 0.80,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(1.5)),
                    ),
                  ),
                ),
              ),
            ]),
          ],
        ),
      );

  Widget _screen() => Container(
        color: _darkScreen,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Icon(Icons.arrow_back_ios_rounded, color: _white.withOpacity(0.35), size: 13),
              const Spacer(),
              Text('TippingJar',
                  style: GoogleFonts.dmSans(color: _white, fontWeight: FontWeight.w700, fontSize: 12.5)),
              const Spacer(),
              Icon(Icons.ios_share_rounded, color: _white.withOpacity(0.35), size: 13),
            ]),
            const SizedBox(height: 14),
            Center(
              child: Column(children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _green.withOpacity(0.5), blurRadius: 20, spreadRadius: 2)],
                    border: Border.all(color: _green.withOpacity(0.5), width: 2.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.5),
                    child: Container(
                      decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                      child: Center(child: Text('TM',
                          style: GoogleFonts.dmSans(color: _white, fontWeight: FontWeight.w800, fontSize: 17))),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Thulani M.',
                    style: GoogleFonts.dmSans(
                        color: _white, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: -0.2)),
                const SizedBox(height: 2),
                Text('Music Producer & Beatmaker',
                    style: GoogleFonts.dmSans(color: _white.withOpacity(0.45), fontSize: 10)),
              ]),
            ),
            const SizedBox(height: 16),
            Text('Choose an amount',
                style: GoogleFonts.dmSans(color: _white.withOpacity(0.40), fontSize: 9.5, fontWeight: FontWeight.w500)),
            const SizedBox(height: 7),
            Row(children: [
              for (final e in [('R20', false), ('R50', true), ('R100', false), ('R200', false)]) ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: e.$2 ? _green : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(color: e.$2 ? _green : Colors.white.withOpacity(0.10)),
                    ),
                    child: Text(e.$1,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                            color: _white, fontWeight: FontWeight.w700, fontSize: 10.5)),
                  ),
                ),
                if (e.$1 != 'R200') const SizedBox(width: 4),
              ],
            ]),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(36),
                boxShadow: [BoxShadow(color: _green.withOpacity(0.45), blurRadius: 14, offset: const Offset(0, 4))],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.favorite_rounded, color: _white, size: 11),
                const SizedBox(width: 5),
                Text('Send R50 tip',
                    style: GoogleFonts.dmSans(color: _white, fontWeight: FontWeight.w700, fontSize: 11.5)),
              ]),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Text('Recent tips',
                  style: GoogleFonts.dmSans(
                      color: _white.withOpacity(0.38), fontSize: 9.5, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
              const Spacer(),
              Text('See all →',
                  style: GoogleFonts.dmSans(color: _green.withOpacity(0.70), fontSize: 9)),
            ]),
            const SizedBox(height: 8),
            _tip('SK', 'Sarah K.', 'R50', '2m'),
            const SizedBox(height: 6),
            _tip('JD', 'James D.', 'R100', '14m'),
            const SizedBox(height: 6),
            _tip('?', 'Anonymous', 'R20', '1h', muted: true),
          ],
        ),
      );

  Widget _tip(String i, String name, String amt, String t, {bool muted = false}) => Row(children: [
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            color: muted ? Colors.white.withOpacity(0.06) : _green.withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(i,
              style: GoogleFonts.dmSans(color: muted ? _white.withOpacity(0.3) : _green,
                  fontWeight: FontWeight.w700, fontSize: 8.5))),
        ),
        const SizedBox(width: 7),
        Expanded(child: Text(name,
            style: GoogleFonts.dmSans(
                color: muted ? _white.withOpacity(0.35) : _white.withOpacity(0.85),
                fontSize: 10.5, fontWeight: FontWeight.w500))),
        Text(amt,
            style: GoogleFonts.dmSans(color: _green, fontWeight: FontWeight.w800, fontSize: 11)),
        const SizedBox(width: 5),
        Text(t,
            style: GoogleFonts.dmSans(color: _white.withOpacity(0.22), fontSize: 9)),
      ]);

  Widget _homeBar() => Container(
        height: 28,
        color: Colors.black,
        child: Center(
          child: Container(
            width: 100, height: 4,
            decoration: BoxDecoration(
                color: _white.withOpacity(0.22), borderRadius: BorderRadius.circular(2)),
          ),
        ),
      );
}

// ─── How it works ─────────────────────────────────────────────────────────────
class _HowItWorksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.person_add_alt_1_rounded, 'Create your page',
          'Sign up in 60 seconds. Customise your profile, set a tip goal, and share your link.', _green),
      (Icons.link_rounded, 'Share your link',
          'Post your TippingJar link anywhere — Instagram, YouTube, TikTok, or your newsletter.', _blue),
      (Icons.account_balance_wallet_rounded, 'Collect tips',
          'Fans tip instantly via card. Funds land in your bank — no waiting, no middleman.', _teal),
    ];

    return _Section(
      alt: false,
      child: Column(children: [
        _Header(tag: 'How it works', title: 'Simple. Fast.\nThree steps.',
            sub: 'No complicated setup. Just you, your fans, and a jar worth filling.'),
        const SizedBox(height: 56),
        Wrap(spacing: 24, runSpacing: 24, alignment: WrapAlignment.center,
            children: steps.asMap().entries.map((e) => _StepCard(
                  number: e.key + 1, icon: e.value.$1,
                  title: e.value.$2, body: e.value.$3,
                  color: e.value.$4, delay: e.key * 120,
                )).toList()),
      ]),
    );
  }
}

class _StepCard extends StatefulWidget {
  final int number;
  final IconData icon;
  final String title, body;
  final Color color;
  final int delay;
  const _StepCard({required this.number, required this.icon, required this.title,
      required this.body, required this.color, required this.delay});
  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: 180.ms,
        width: 300,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _h ? _bgSageDeep : _bgWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _h ? widget.color.withOpacity(0.35) : _border),
          boxShadow: _h
              ? [BoxShadow(color: widget.color.withOpacity(0.10), blurRadius: 36, offset: const Offset(0, 10))]
              : [const BoxShadow(color: Color(0x06000000), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.10), borderRadius: BorderRadius.circular(14)),
              child: Icon(widget.icon, color: widget.color, size: 22),
            ),
            const Spacer(),
            Text('0${widget.number}',
                style: GoogleFonts.dmSans(color: widget.color.withOpacity(0.18),
                    fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
          ]),
          const SizedBox(height: 20),
          Text(widget.title,
              style: GoogleFonts.dmSans(color: _ink, fontWeight: FontWeight.w700, fontSize: 17)),
          const SizedBox(height: 8),
          Text(widget.body,
              style: GoogleFonts.dmSans(color: _inkBody, fontSize: 14, height: 1.65)),
        ]),
      )
          .animate()
          .fadeIn(delay: widget.delay.ms, duration: 500.ms)
          .slideY(begin: 0.18, curve: Curves.easeOut),
    );
  }
}

// ─── Features ─────────────────────────────────────────────────────────────────
class _FeaturesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final features = [
      (Icons.flash_on_rounded, 'Instant payouts', 'No holding periods. Funds go straight to your bank — fast.', _green),
      (Icons.face_rounded, 'Anonymous tips', 'Fans tip without creating an account — zero friction.', _cyan),
      (Icons.bar_chart_rounded, 'Live analytics', 'Watch tips roll in with a real-time dashboard built for creators.', _blue),
      (Icons.lock_rounded, 'Bank-grade security', 'PCI-DSS compliant. Your fans\' payments are always protected.', _teal),
      (Icons.palette_rounded, 'Custom pages', 'Cover art, tagline, monthly goal — make it yours.', _violet),
      (Icons.public_rounded, 'Works worldwide', 'Accept tips in 135+ currencies across 48 countries.', _greenLight),
    ];

    return _Section(
      alt: true,
      child: Column(children: [
        _Header(
          tag: 'Features',
          title: 'Everything a creator\nactually needs',
          sub: 'We cut the fluff and kept only what matters for getting paid.',
        ),
        const SizedBox(height: 56),
        Wrap(spacing: 18, runSpacing: 18, alignment: WrapAlignment.center,
            children: features.asMap().entries.map((e) => _FeatureCard(
                  icon: e.value.$1, title: e.value.$2,
                  body: e.value.$3, color: e.value.$4,
                  delay: e.key * 80,
                )).toList()),
      ]),
    );
  }
}

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
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: 180.ms,
        width: 270,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _bgWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _h ? widget.color.withOpacity(0.30) : _border),
          boxShadow: _h
              ? [BoxShadow(color: widget.color.withOpacity(0.09), blurRadius: 28, offset: const Offset(0, 8))]
              : [const BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.09), borderRadius: BorderRadius.circular(12)),
            child: Icon(widget.icon, color: widget.color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(widget.title,
              style: GoogleFonts.dmSans(color: _ink, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 7),
          Text(widget.body,
              style: GoogleFonts.dmSans(color: _inkBody, fontSize: 13, height: 1.65)),
        ]),
      )
          .animate()
          .fadeIn(delay: widget.delay.ms, duration: 400.ms)
          .slideY(begin: 0.12, curve: Curves.easeOut),
    );
  }
}

// ─── Creator spotlight ────────────────────────────────────────────────────────
class _CreatorSpotlightSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final creators = [
      ('Mia Chen', 'Illustrator & comic artist', 'R3,240', _cyan, 'MC'),
      ('Raj Patel', 'Indie game developer', 'R1,870', _violet, 'RP'),
      ('Lena Torres', 'Music producer & DJ', 'R5,100', _green, 'LT'),
    ];

    return _Section(
      alt: false,
      child: Column(children: [
        _Header(
          tag: 'Creator spotlight',
          title: 'Real creators,\nreal tips',
          sub: 'Join thousands already filling their jar every day.',
        ),
        const SizedBox(height: 56),
        Wrap(spacing: 20, runSpacing: 20, alignment: WrapAlignment.center,
            children: creators.asMap().entries.map((e) {
              final c = e.value;
              return _CreatorCard(
                  name: c.$1, role: c.$2, earned: c.$3,
                  color: c.$4, initials: c.$5, delay: e.key * 130);
            }).toList()),
      ]),
    );
  }
}

class _CreatorCard extends StatelessWidget {
  final String name, role, earned, initials;
  final Color color;
  final int delay;
  const _CreatorCard({required this.name, required this.role, required this.earned,
      required this.initials, required this.color, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 278,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _bgWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: const [BoxShadow(color: Color(0x07000000), blurRadius: 18, offset: Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Cover placeholder with gradient
        Container(
          height: 68,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Icon(Icons.music_note_rounded, color: color.withOpacity(0.25), size: 28),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
                color: color, shape: BoxShape.circle,
                border: Border.all(color: _bgWhite, width: 3),
                boxShadow: [BoxShadow(color: color.withOpacity(0.30), blurRadius: 10, offset: const Offset(0, 3))]),
            child: Center(child: Text(initials,
                style: GoogleFonts.dmSans(color: _white, fontWeight: FontWeight.w800, fontSize: 13))),
          ),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: GoogleFonts.dmSans(color: _ink, fontWeight: FontWeight.w700, fontSize: 14.5)),
            Text(role, style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: _bgSage, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
          child: Row(children: [
            Icon(Icons.volunteer_activism, color: color, size: 15),
            const SizedBox(width: 7),
            Text('Total earned',
                style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 12)),
            const Spacer(),
            Text(earned,
                style: GoogleFonts.dmSans(color: _ink, fontWeight: FontWeight.w800, fontSize: 15)),
          ]),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go('/explore'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color.withOpacity(0.09),
              foregroundColor: color,
              elevation: 0,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Send a tip',
                style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ),
        ),
      ]),
    )
        .animate()
        .fadeIn(delay: delay.ms, duration: 500.ms)
        .slideY(begin: 0.18, curve: Curves.easeOut);
  }
}

// ─── CTA ──────────────────────────────────────────────────────────────────────
class _CtaSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 88, horizontal: 40),
        decoration: BoxDecoration(
          color: const Color(0xFF001810),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF1A3028)),
        ),
        child: Stack(
          children: [
            // Glow blob top right
            Positioned(
              top: -60, right: -60,
              child: Container(
                width: 320, height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [_green.withOpacity(0.22), Colors.transparent]),
                ),
              ),
            ),
            // Glow blob bottom left
            Positioned(
              bottom: -60, left: 20,
              child: Container(
                width: 260, height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [_blue.withOpacity(0.15), Colors.transparent]),
                ),
              ),
            ),
            Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _greenGlow.withOpacity(0.10),
                  border: Border.all(color: _greenGlow.withOpacity(0.25)),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('Get started today',
                    style: GoogleFonts.dmSans(
                        color: _greenGlow, fontSize: 12, fontWeight: FontWeight.w600)),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 20),
              Text('Ready to fill your jar?',
                  style: GoogleFonts.dmSans(
                      color: _white, fontWeight: FontWeight.w800, fontSize: 44, letterSpacing: -1.8),
                  textAlign: TextAlign.center)
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 500.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOut),
              const SizedBox(height: 14),
              Text('Set up your creator page in under a minute.\nNo credit card required.',
                  style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 16, height: 1.65),
                  textAlign: TextAlign.center)
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 500.ms),
              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: () => context.go('/register'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _white,
                  foregroundColor: _green,
                  shadowColor: Colors.black.withOpacity(0.15),
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                ),
                child: Text('Create your free page →',
                    style: GoogleFonts.dmSans(
                        fontSize: 16, fontWeight: FontWeight.w700, color: _green)),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 500.ms)
                  .scale(begin: const Offset(0.93, 0.93), curve: Curves.easeOut),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final mobile = w < 700;
    final cols = [
      ('Product', [('Features', '/features')]),
      ('Company', [('About', '/about'), ('Blog', '/blog')]),
      ('Legal', [('Privacy', '/privacy'), ('Terms', '/terms'), ('Cookies', '/cookies')]),
    ];

    final brand = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const AppLogoIcon(size: 28),
        const SizedBox(width: 8),
        Text('TippingJar',
            style: GoogleFonts.dmSans(color: _white, fontWeight: FontWeight.w700, fontSize: 15)),
      ]),
      const SizedBox(height: 12),
      Text('Supporting creators,\none tip at a time.',
          style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 13, height: 1.6)),
    ]);

    Widget col((String, List<(String, String)>) c) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.$1,
                style: GoogleFonts.dmSans(color: _white, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 12),
            ...c.$2.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => context.go(l.$2),
                    child: Text(l.$1,
                        style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 13)),
                  ),
                )),
          ],
        );

    return Container(
      color: _darkFooter,
      padding: EdgeInsets.symmetric(horizontal: mobile ? 24 : 48, vertical: 52),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (mobile) ...[
          brand,
          const SizedBox(height: 32),
          Wrap(spacing: 40, runSpacing: 28, children: cols.map(col).toList()),
        ] else
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: brand),
            ...cols.map((c) => Expanded(child: col(c))),
          ]),
        const SizedBox(height: 44),
        const Divider(color: Color(0xFF1A2E22)),
        const SizedBox(height: 20),
        Row(children: [
          Text('© 2026 TippingJar. All rights reserved.',
              style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 12)),
          const Spacer(),
          Text('Proudly South African 🇿🇦',
              style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 12)),
        ]),
      ]),
    );
  }
}

// ─── Shared ───────────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final bool alt;
  final Widget child;
  const _Section({required this.alt, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: alt ? _bgSage : _bgWhite,
        padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 40),
        child: child,
      );
}

class _Header extends StatelessWidget {
  final String tag, title, sub;
  const _Header({required this.tag, required this.title, required this.sub});

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
          decoration: BoxDecoration(
            color: _green.withOpacity(0.07),
            border: Border.all(color: _green.withOpacity(0.22)),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 5, height: 5,
                decoration: const BoxDecoration(color: _green, shape: BoxShape.circle)),
            const SizedBox(width: 7),
            Text(tag, style: GoogleFonts.dmSans(color: _green, fontSize: 11.5, fontWeight: FontWeight.w600)),
          ]),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 16),
        Text(title,
            style: GoogleFonts.dmSans(
                color: _ink, fontWeight: FontWeight.w800, fontSize: 38, height: 1.14, letterSpacing: -1.3),
            textAlign: TextAlign.center)
            .animate()
            .fadeIn(delay: 100.ms, duration: 500.ms)
            .slideY(begin: 0.12, curve: Curves.easeOut),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Text(sub,
              style: GoogleFonts.dmSans(color: _inkBody, fontSize: 16, height: 1.7),
              textAlign: TextAlign.center),
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
      ]);
}

