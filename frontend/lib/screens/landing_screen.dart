import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_logo.dart';

// ─── Palette ─────────────────────────────────────────────────────────────────
const _green      = Color(0xFF004423);
const _greenMid   = Color(0xFF006B3A);
const _greenBright= Color(0xFF00A854);
const _greenGlow  = Color(0xFFB8EACE);
const _bgWhite    = Colors.white;
const _bgSage     = Color(0xFFF5F9F6);
const _ink        = Color(0xFF080F0B);
const _inkBody    = Color(0xFF38524A);
const _inkMuted   = Color(0xFF7A9487);
const _border     = Color(0xFFDBEAE1);
const _darkBg     = Color(0xFF040907);
const _darkBorder = Color(0xFF172B1E);
const _darkScreen = Color(0xFF0D1810);
const _white      = Colors.white;

const _blue   = Color(0xFF2563EB);
const _cyan   = Color(0xFF0284C7);
const _teal   = Color(0xFF0D9488);
const _violet = Color(0xFF7C3AED);

// ─── Root ─────────────────────────────────────────────────────────────────────
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
  void dispose() { _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bgWhite,
    body: Stack(children: [
      ScrollConfiguration(
        behavior: _SmoothScroll(),
        child: SingleChildScrollView(
        controller: _scroll,
        physics: const ClampingScrollPhysics(),
        child: Column(children: [
          const _HeroSection(),
          const _EarningsTicker(),
          const _HowItWorksSection(),
          const _FeatureShowcase(),
          const _SocialProofSection(),
          const _CtaSection(),
          const _Footer(),
        ]),
      )),
      _NavBar(solid: _navSolid),
    ]),
  );
}

// ─── Smooth scroll behaviour (enables trackpad/mouse-wheel momentum on web) ───
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

// ─── Navbar ───────────────────────────────────────────────────────────────────
class _NavBar extends StatelessWidget {
  final bool solid;
  const _NavBar({required this.solid});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return AnimatedContainer(
      duration: 220.ms,
      decoration: BoxDecoration(
        color: solid ? _bgWhite.withOpacity(0.97) : Colors.transparent,
        border: solid ? const Border(bottom: BorderSide(color: Color(0xFFE4EDE8), width: 1)) : const Border(),
        boxShadow: solid ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 2))] : [],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w > 900 ? 60 : 20, vertical: 15),
          child: Row(children: [
            Row(children: [
              const AppLogoIcon(size: 30),
              const SizedBox(width: 9),
              Text('TippingJar', style: GoogleFonts.dmSans(
                  color: _ink, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.5)),
            ]),
            const Spacer(),
            if (w > 1040) ...[
              _link('Features', context, '/features'),
              _link('How it works', context, '/how-it-works'),
              if (DateTime.now().isAfter(DateTime(2026, 3, 23)))
                _link('Creators', context, '/creators'),
              _link('Enterprise', context, '/enterprise'),
              _link('Blog', context, '/blog'),
              _link('Developers', context, '/developers'),
              const SizedBox(width: 16),
            ],
            GestureDetector(
              onTap: () => context.go('/login'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text('Sign in', style: GoogleFonts.dmSans(
                    color: _inkBody, fontSize: 13.5, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(width: 6),
            ElevatedButton(
              onPressed: () => context.go('/register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green, foregroundColor: _white,
                elevation: 0, shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
              ),
              child: Text('Get started', style: GoogleFonts.dmSans(fontSize: 13.5, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _link(String label, BuildContext ctx, String route) => GestureDetector(
    onTap: () => ctx.go(route),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(label, style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 13.5, fontWeight: FontWeight.w500)),
    ),
  );
}

// ─── Hero ─────────────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final narrow = w < 920;

    return Container(
      width: double.infinity,
      color: _bgWhite,
      child: Stack(children: [
        // Grid background
        Positioned.fill(child: CustomPaint(painter: _GridPainter())),
        // Radial glow — top right
        Positioned(top: -80, right: -80, child: Container(
          width: 640, height: 640,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              _greenGlow.withOpacity(0.50),
              Colors.transparent,
            ]),
          ),
        )),
        // Radial glow — bottom left (subtle)
        Positioned(bottom: -120, left: -80, child: Container(
          width: 400, height: 400,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              _greenGlow.withOpacity(0.20),
              Colors.transparent,
            ]),
          ),
        )),
        // Content
        Padding(
          padding: EdgeInsets.fromLTRB(narrow ? 24 : 60, 112, narrow ? 24 : 60, 80),
          child: narrow ? _narrow(context) : _wide(context),
        ),
      ]),
    );
  }

  Widget _wide(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      // Left — 54%
      Flexible(
        flex: 54,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          _badge().animate().fadeIn(duration: 500.ms).slideY(begin: 0.3, curve: Curves.easeOut),
          const SizedBox(height: 32),
          _headline(68)
              .animate().fadeIn(delay: 100.ms, duration: 600.ms).slideY(begin: 0.18, curve: Curves.easeOut),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              'Set up your TippingJar page in 60 seconds. Share one link. Let fans support you — no subscriptions, no friction.',
              style: GoogleFonts.dmSans(color: _inkBody, fontSize: 16.5, height: 1.72),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.15, curve: Curves.easeOut),
          const SizedBox(height: 40),
          _ctaRow(context)
              .animate().fadeIn(delay: 320.ms, duration: 500.ms).slideY(begin: 0.15, curve: Curves.easeOut),
          const SizedBox(height: 32),
          _socialProof().animate().fadeIn(delay: 440.ms, duration: 500.ms),
        ]),
      ),
      const SizedBox(width: 48),
      // Right — 46%
      Flexible(
        flex: 46,
        child: const _PhoneMockup()
            .animate().fadeIn(delay: 250.ms, duration: 700.ms)
            .slideX(begin: 0.06, curve: Curves.easeOut),
      ),
    ],
  );

  Widget _narrow(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      _badge().animate().fadeIn(duration: 500.ms).slideY(begin: 0.3, curve: Curves.easeOut),
      const SizedBox(height: 24),
      _headline(40)
          .animate().fadeIn(delay: 100.ms, duration: 600.ms).slideY(begin: 0.18, curve: Curves.easeOut),
      const SizedBox(height: 16),
      Text(
        'Set up your TippingJar page in 60 seconds. Share one link. Let fans support you — no subscriptions, no friction.',
        textAlign: TextAlign.center,
        style: GoogleFonts.dmSans(color: _inkBody, fontSize: 15.5, height: 1.72),
      ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
      const SizedBox(height: 32),
      _ctaRow(context).animate().fadeIn(delay: 320.ms, duration: 500.ms),
      const SizedBox(height: 28),
      _socialProof().animate().fadeIn(delay: 440.ms, duration: 500.ms),
      const SizedBox(height: 52),
      const _PhoneMockup()
          .animate().fadeIn(delay: 500.ms, duration: 700.ms).slideY(begin: 0.08, curve: Curves.easeOut),
    ],
  );

  // Headline — "love" uses gradient paint
  Widget _headline(double size) {
    final style = GoogleFonts.dmSans(
      color: _ink, fontSize: size, fontWeight: FontWeight.w800,
      height: 1.05, letterSpacing: size > 50 ? -2.8 : -1.2,
    );
    return Text.rich(
      TextSpan(style: style, children: [
        const TextSpan(text: 'Get paid by the people\nwho '),
        TextSpan(text: 'love', style: style.copyWith(
          foreground: Paint()
            ..shader = const LinearGradient(
              colors: [_greenMid, _greenBright],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(Rect.fromLTWH(0, 0, size * 2.4, size * 1.2)),
        )),
        const TextSpan(text: ' your work.'),
      ]),
    );
  }

  Widget _badge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      color: _green.withOpacity(0.07),
      border: Border.all(color: _green.withOpacity(0.22)),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6,
        decoration: BoxDecoration(
          color: _greenBright, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: _greenBright.withOpacity(0.6), blurRadius: 6, spreadRadius: 1)],
        ),
      ),
      const SizedBox(width: 9),
      Text("South Africa's creator tipping platform",
          style: GoogleFonts.dmSans(color: _green, fontSize: 12.5, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _ctaRow(BuildContext context) => Wrap(
    spacing: 12, runSpacing: 10,
    children: [
      ElevatedButton(
        onPressed: () => context.go('/register'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _green, foregroundColor: _white,
          elevation: 4, shadowColor: _green.withOpacity(0.30),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        ),
        child: Text('Create your free page →',
            style: GoogleFonts.dmSans(fontSize: 15.5, fontWeight: FontWeight.w600)),
      ),
      if (DateTime.now().isAfter(DateTime(2026, 3, 23)))
        OutlinedButton(
          onPressed: () => context.go('/creators'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _green,
            side: BorderSide(color: _green.withOpacity(0.30)),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
          ),
          child: Text('View Creators',
              style: GoogleFonts.dmSans(fontSize: 15.5, fontWeight: FontWeight.w600, color: _green)),
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
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 90, height: 34,
        child: Stack(children: avatars.asMap().entries.map((e) => Positioned(
          left: e.key * 20.0,
          child: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: e.value.$1, shape: BoxShape.circle,
              border: Border.all(color: _bgWhite, width: 2.5),
              boxShadow: [BoxShadow(color: e.value.$1.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Center(child: Text(e.value.$2,
                style: GoogleFonts.dmSans(color: _white, fontWeight: FontWeight.w700, fontSize: 11.5))),
          ),
        )).toList()),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          for (int i = 0; i < 5; i++)
            const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 14),
        ]),
        const SizedBox(height: 3),
        Text('Loved by 10,000+ creators',
            style: GoogleFonts.dmSans(color: _inkBody, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    ]);
  }
}

// ─── Grid background ──────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF004423).withOpacity(0.040)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const spacing = 52.0;
    for (double x = 0; x <= size.width; x += spacing)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y <= size.height; y += spacing)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Earnings ticker ──────────────────────────────────────────────────────────
class _EarningsTicker extends StatefulWidget {
  const _EarningsTicker();
  @override
  State<_EarningsTicker> createState() => _EarningsTickerState();
}

class _EarningsTickerState extends State<_EarningsTicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  static const _items = [
    ('TM', 'Thulani M.', 'R850', _green),
    ('SK', 'Sarah K.', 'R1,240', Color(0xFF0097B2)),
    ('JD', 'James D.', 'R320', Color(0xFF7C3AED)),
    ('LT', 'Lena T.', 'R2,100', Color(0xFF0D9488)),
    ('RP', 'Raj P.', 'R670', Color(0xFF2563EB)),
    ('MC', 'Mia C.', 'R3,200', Color(0xFF0097B2)),
    ('NS', 'Naledi S.', 'R940', _green),
    ('AO', 'Amara O.', 'R1,800', Color(0xFF7C3AED)),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 28))
      ..repeat();
    _anim = Tween<double>(begin: 0, end: 1).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: _darkBg,
        border: const Border.symmetric(
          horizontal: BorderSide(color: _darkBorder, width: 1),
        ),
      ),
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            const itemW = 230.0;
            final totalW = _items.length * itemW * 2;
            final offset = -(_anim.value * totalW / 2) % (totalW / 2);

            return Transform.translate(
              offset: Offset(offset, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ..._items, ..._items,
                  ..._items, ..._items,
                ].map((e) => SizedBox(
                  width: itemW,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: e.$4.withOpacity(0.20), shape: BoxShape.circle,
                        border: Border.all(color: e.$4.withOpacity(0.35), width: 1),
                      ),
                      child: Center(child: Text(e.$1,
                          style: GoogleFonts.dmSans(
                              color: e.$4, fontSize: 8.5, fontWeight: FontWeight.w700))),
                    ),
                    const SizedBox(width: 8),
                    Text(e.$2, style: GoogleFonts.dmSans(
                        color: _white.withOpacity(0.55), fontSize: 12.5, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 6),
                    Text(e.$3, style: GoogleFonts.dmSans(
                        color: e.$4, fontSize: 12.5, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 20),
                    Container(width: 3, height: 3,
                        decoration: BoxDecoration(
                            color: _white.withOpacity(0.15), shape: BoxShape.circle)),
                  ]),
                )).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
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
              Positioned(left: 20, right: 20, bottom: -16, child: Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [BoxShadow(color: _green.withOpacity(0.35), blurRadius: 80, spreadRadius: 12)],
                ),
              )),
              IntrinsicHeight(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 2.5),
                      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                        const SizedBox(height: 80),
                        _btn(22), const SizedBox(height: 16),
                        _btn(50), const SizedBox(height: 10),
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
      color: _frame, borderRadius: BorderRadius.circular(50),
      border: Border.all(color: _frameEdge, width: 1.2),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 60, offset: const Offset(0, 28)),
        BoxShadow(color: _green.withOpacity(0.12), blurRadius: 90, spreadRadius: -4),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(49),
      child: Stack(children: [
        Column(mainAxisSize: MainAxisSize.min, children: [_statusBar(), _screen(), _homeBar()]),
        Positioned(top: 0, left: 0, right: 0, child: IgnorePointer(
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(49)),
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Colors.white.withOpacity(0.065), Colors.transparent],
                stops: const [0.0, 0.5],
              ),
            ),
          ),
        )),
      ]),
    ),
  );

  Widget _statusBar() => Container(
    height: 52, color: Colors.black,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Stack(alignment: Alignment.center, children: [
      Container(width: 108, height: 28,
          decoration: BoxDecoration(
              color: Colors.black, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2A2A2E)))),
      Row(children: [
        Text('9:41', style: GoogleFonts.dmSans(
            color: _white, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
        const Spacer(),
        Row(crossAxisAlignment: CrossAxisAlignment.end,
            children: [4.0, 7.0, 10.0, 13.0].map((h) => Padding(
              padding: const EdgeInsets.only(left: 1.5),
              child: Container(width: 3, height: h,
                  decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(0.5))),
            )).toList()),
        const SizedBox(width: 5),
        const Icon(Icons.wifi_rounded, color: _white, size: 13),
        const SizedBox(width: 4),
        Container(width: 22, height: 11,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: _white.withOpacity(0.4))),
          child: Padding(padding: const EdgeInsets.all(1.5),
            child: FractionallySizedBox(widthFactor: 0.80, alignment: Alignment.centerLeft,
              child: Container(decoration: BoxDecoration(
                  color: _white, borderRadius: BorderRadius.circular(1.5))),
            )),
        ),
      ]),
    ]),
  );

  Widget _screen() => Container(
    color: _darkScreen,
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Icon(Icons.arrow_back_ios_rounded, color: _white.withOpacity(0.28), size: 13),
        const Spacer(),
        Text('TippingJar', style: GoogleFonts.dmSans(
            color: _white, fontWeight: FontWeight.w700, fontSize: 12.5)),
        const Spacer(),
        Icon(Icons.ios_share_rounded, color: _white.withOpacity(0.28), size: 13),
      ]),
      const SizedBox(height: 14),
      Center(child: Column(children: [
        Container(width: 64, height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: _green.withOpacity(0.55), blurRadius: 22, spreadRadius: 2)],
            border: Border.all(color: _green.withOpacity(0.55), width: 2.5),
          ),
          child: Padding(padding: const EdgeInsets.all(2.5),
            child: Container(decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
              child: Center(child: Text('TM', style: GoogleFonts.dmSans(
                  color: _white, fontWeight: FontWeight.w800, fontSize: 17))),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Thulani M.', style: GoogleFonts.dmSans(
            color: _white, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: -0.2)),
        const SizedBox(height: 2),
        Text('Music Producer & Beatmaker', style: GoogleFonts.dmSans(
            color: _white.withOpacity(0.42), fontSize: 9.5)),
      ])),
      const SizedBox(height: 16),
      Text('Choose an amount', style: GoogleFonts.dmSans(
          color: _white.withOpacity(0.38), fontSize: 9.5, fontWeight: FontWeight.w500)),
      const SizedBox(height: 7),
      Row(children: [
        for (final e in [('R20', false), ('R50', true), ('R100', false), ('R200', false)]) ...[
          Expanded(child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: e.$2 ? _green : _white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: e.$2 ? _green : _white.withOpacity(0.09)),
            ),
            child: Text(e.$1, textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(color: _white, fontWeight: FontWeight.w700, fontSize: 10.5)),
          )),
          if (e.$1 != 'R200') const SizedBox(width: 4),
        ],
      ]),
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: _green, borderRadius: BorderRadius.circular(36),
          boxShadow: [BoxShadow(color: _green.withOpacity(0.50), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.favorite_rounded, color: _white, size: 11),
          const SizedBox(width: 5),
          Text('Send R50 tip', style: GoogleFonts.dmSans(
              color: _white, fontWeight: FontWeight.w700, fontSize: 11.5)),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Text('Recent tips', style: GoogleFonts.dmSans(
            color: _white.withOpacity(0.35), fontSize: 9.5, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
        const Spacer(),
        Text('See all →', style: GoogleFonts.dmSans(color: _greenBright.withOpacity(0.65), fontSize: 9)),
      ]),
      const SizedBox(height: 8),
      _tip('SK', 'Sarah K.', 'R50', '2m'),
      const SizedBox(height: 6),
      _tip('JD', 'James D.', 'R100', '14m'),
      const SizedBox(height: 6),
      _tip('?', 'Anonymous', 'R20', '1h', muted: true),
    ]),
  );

  Widget _tip(String i, String name, String amt, String t, {bool muted = false}) =>
      Row(children: [
        Container(width: 26, height: 26,
          decoration: BoxDecoration(
            color: muted ? _white.withOpacity(0.05) : _green.withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(i, style: GoogleFonts.dmSans(
              color: muted ? _white.withOpacity(0.25) : _greenBright,
              fontWeight: FontWeight.w700, fontSize: 8.5))),
        ),
        const SizedBox(width: 7),
        Expanded(child: Text(name, style: GoogleFonts.dmSans(
            color: muted ? _white.withOpacity(0.30) : _white.withOpacity(0.82),
            fontSize: 10.5, fontWeight: FontWeight.w500))),
        Text(amt, style: GoogleFonts.dmSans(
            color: _greenBright, fontWeight: FontWeight.w800, fontSize: 11)),
        const SizedBox(width: 5),
        Text(t, style: GoogleFonts.dmSans(color: _white.withOpacity(0.20), fontSize: 9)),
      ]);

  Widget _homeBar() => Container(
    height: 28, color: Colors.black,
    child: Center(child: Container(width: 100, height: 4,
        decoration: BoxDecoration(color: _white.withOpacity(0.20),
            borderRadius: BorderRadius.circular(2)))),
  );
}

// ─── How it works ─────────────────────────────────────────────────────────────
class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  static const _steps = [
    (Icons.person_add_alt_1_rounded, 'Create your page',
        'Sign up in under a minute. Customise your profile, set a tip goal, and add your cover.', _green),
    (Icons.link_rounded, 'Share your link',
        'Post your TippingJar link anywhere — Instagram, YouTube, TikTok, or your newsletter.', _blue),
    (Icons.account_balance_wallet_rounded, 'Get paid',
        'Fans tip instantly via card. Funds land in your bank — no waiting, no middleman.', _teal),
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Container(
      width: double.infinity,
      color: _bgSage,
      padding: EdgeInsets.symmetric(vertical: 100, horizontal: w > 900 ? 60 : 24),
      child: Column(children: [
        _SectionHeader(
          tag: 'How it works',
          title: 'Simple. Fast.\nThree steps.',
          sub: 'No complicated setup. Just you, your fans, and a jar worth filling.',
        ),
        const SizedBox(height: 64),
        w > 860
            ? _desktopSteps()
            : Wrap(spacing: 20, runSpacing: 20, alignment: WrapAlignment.center,
                children: _steps.asMap().entries.map((e) =>
                    _StepCard(n: e.key + 1, icon: e.value.$1, title: e.value.$2,
                        body: e.value.$3, color: e.value.$4, delay: e.key * 120)).toList()),
      ]),
    );
  }

  Widget _desktopSteps() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _steps.asMap().entries.expand((e) {
        final card = Expanded(child: _StepCard(
          n: e.key + 1, icon: e.value.$1, title: e.value.$2,
          body: e.value.$3, color: e.value.$4, delay: e.key * 120,
        ));
        if (e.key < _steps.length - 1) {
          return [
            card,
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Column(children: [
                Container(width: 48, height: 1,
                    color: _border),
                const SizedBox(height: 2),
                Icon(Icons.arrow_forward_rounded, color: _border, size: 14),
              ]),
            ),
          ];
        }
        return [card];
      }).toList(),
    );
  }
}

class _StepCard extends StatefulWidget {
  final int n;
  final IconData icon;
  final String title, body;
  final Color color;
  final int delay;
  const _StepCard({required this.n, required this.icon, required this.title,
      required this.body, required this.color, required this.delay});
  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _h = true),
    onExit: (_) => setState(() => _h = false),
    child: AnimatedContainer(
      duration: 180.ms,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: _h ? _bgWhite : _bgWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _h ? widget.color.withOpacity(0.30) : _border),
        boxShadow: _h
            ? [BoxShadow(color: widget.color.withOpacity(0.10), blurRadius: 40, offset: const Offset(0, 12))]
            : [const BoxShadow(color: Color(0x06000000), blurRadius: 14, offset: Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Huge step number
        Text('0${widget.n}',
            style: GoogleFonts.dmSans(
                color: widget.color.withOpacity(0.14), fontSize: 52,
                fontWeight: FontWeight.w900, letterSpacing: -2.5, height: 1)),
        const SizedBox(height: 16),
        Container(width: 44, height: 44,
          decoration: BoxDecoration(
              color: widget.color.withOpacity(0.10), borderRadius: BorderRadius.circular(12)),
          child: Icon(widget.icon, color: widget.color, size: 22),
        ),
        const SizedBox(height: 16),
        Text(widget.title, style: GoogleFonts.dmSans(
            color: _ink, fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 10),
        Text(widget.body, style: GoogleFonts.dmSans(
            color: _inkBody, fontSize: 14, height: 1.65)),
      ]),
    ).animate().fadeIn(delay: widget.delay.ms, duration: 500.ms).slideY(begin: 0.2, curve: Curves.easeOut),
  );
}

// ─── Feature showcase ─────────────────────────────────────────────────────────
class _FeatureShowcase extends StatelessWidget {
  const _FeatureShowcase();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final wide = w > 900;

    final features = [
      (Icons.flash_on_rounded, 'Instant payouts', 'Funds go straight to your bank with no holding periods.', _green),
      (Icons.face_rounded, 'Anonymous tips', 'Fans tip without creating an account — zero friction.', _cyan),
      (Icons.bar_chart_rounded, 'Live analytics', 'Real-time dashboard shows every tip as it lands.', _blue),
      (Icons.lock_rounded, 'Bank-grade security', 'PCI-DSS compliant. Always protected.', _teal),
      (Icons.palette_rounded, 'Custom branding', 'Cover art, tagline, and monthly goals.', _violet),
      (Icons.public_rounded, 'Works worldwide', '135+ currencies across 48 countries.', _greenMid),
    ];

    return Container(
      width: double.infinity,
      color: _bgWhite,
      padding: EdgeInsets.symmetric(vertical: 100, horizontal: wide ? 60 : 24),
      child: Column(children: [
        _SectionHeader(
          tag: 'Features',
          title: 'Everything a creator\nactually needs',
          sub: 'We cut the fluff and kept only what matters for getting paid.',
        ),
        const SizedBox(height: 64),
        if (wide)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Left — hero feature
            Expanded(
              flex: 5,
              child: _HeroFeatureCard().animate()
                  .fadeIn(duration: 500.ms).slideX(begin: -0.06, curve: Curves.easeOut),
            ),
            const SizedBox(width: 20),
            // Right — feature grid 2×3
            Expanded(
              flex: 7,
              child: Wrap(
                spacing: 16, runSpacing: 16,
                children: features.asMap().entries.map((e) => _FeatureChip(
                  icon: e.value.$1, title: e.value.$2,
                  body: e.value.$3, color: e.value.$4, delay: e.key * 70,
                )).toList(),
              ),
            ),
          ])
        else
          Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.center,
              children: features.asMap().entries.map((e) => _FeatureChip(
                icon: e.value.$1, title: e.value.$2,
                body: e.value.$3, color: e.value.$4, delay: e.key * 70,
              )).toList()),
      ]),
    );
  }
}

class _HeroFeatureCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [_green.withOpacity(0.95), _greenMid.withOpacity(0.90)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _green.withOpacity(0.30), blurRadius: 40, offset: const Offset(0, 16))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 52, height: 52,
          decoration: BoxDecoration(
            color: _white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.account_balance_rounded, color: _white, size: 24),
        ),
        const SizedBox(height: 28),
        Text('Instant\nPayouts', style: GoogleFonts.dmSans(
            color: _white, fontSize: 36, fontWeight: FontWeight.w800,
            height: 1.1, letterSpacing: -1.2)),
        const SizedBox(height: 14),
        Text(
          'No waiting periods. No holds. No mystery. Tips go from your fans\' cards directly into your bank account — usually within hours.',
          style: GoogleFonts.dmSans(color: _white.withOpacity(0.78), fontSize: 14.5, height: 1.7),
        ),
        const SizedBox(height: 32),
        // Mini stats row
        Row(children: [
          _stat('R2M+', 'Paid out'),
          const SizedBox(width: 28),
          _stat('< 24h', 'Average payout'),
          const SizedBox(width: 28),
          _stat('0%', 'Hidden fees'),
        ]),
      ]),
    );
  }

  Widget _stat(String val, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(val, style: GoogleFonts.dmSans(
          color: _white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      Text(label, style: GoogleFonts.dmSans(
          color: _white.withOpacity(0.60), fontSize: 11.5)),
    ],
  );
}

class _FeatureChip extends StatefulWidget {
  final IconData icon;
  final String title, body;
  final Color color;
  final int delay;
  const _FeatureChip({required this.icon, required this.title,
      required this.body, required this.color, required this.delay});
  @override
  State<_FeatureChip> createState() => _FeatureChipState();
}

class _FeatureChipState extends State<_FeatureChip> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final chipW = w > 900 ? (w - 120 - 20 - 16) * 7 / 13 / 2 - 8.0 : 280.0;
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: 160.ms,
        width: chipW.clamp(180, 320),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _h ? _bgSage : _bgWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _h ? widget.color.withOpacity(0.28) : _border),
          boxShadow: _h
              ? [BoxShadow(color: widget.color.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 6))]
              : [const BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 3))],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 38, height: 38,
            decoration: BoxDecoration(
                color: widget.color.withOpacity(0.09), borderRadius: BorderRadius.circular(10)),
            child: Icon(widget.icon, color: widget.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.title, style: GoogleFonts.dmSans(
                color: _ink, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 4),
            Text(widget.body, style: GoogleFonts.dmSans(
                color: _inkBody, fontSize: 12.5, height: 1.55)),
          ])),
        ]),
      ).animate().fadeIn(delay: widget.delay.ms, duration: 400.ms).slideY(begin: 0.12, curve: Curves.easeOut),
    );
  }
}

// ─── Social proof ─────────────────────────────────────────────────────────────
class _SocialProofSection extends StatelessWidget {
  const _SocialProofSection();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final creators = [
      ('Mia Chen', 'Illustrator & comic artist', 'R3,240 earned', _cyan, 'MC',
          '"TippingJar changed how I think about my work. Woke up to R800 while I slept."'),
      ('Raj Patel', 'Indie game developer', 'R1,870 earned', _violet, 'RP',
          '"Set it up in 5 minutes. My community tipped me R600 on launch day alone."'),
      ('Lena Torres', 'Music producer & DJ', 'R5,100 earned', _green, 'LT',
          '"Finally a platform built for African creators. No PayPal nonsense."'),
    ];

    return Container(
      width: double.infinity,
      color: _bgSage,
      padding: EdgeInsets.symmetric(vertical: 100, horizontal: w > 900 ? 60 : 24),
      child: Column(children: [
        _SectionHeader(
          tag: 'Creator spotlight',
          title: 'Creators who\'re\nalready earning',
          sub: 'Join thousands filling their jar every day.',
        ),
        const SizedBox(height: 64),
        Wrap(
          spacing: 20, runSpacing: 20, alignment: WrapAlignment.center,
          children: creators.asMap().entries.map((e) {
            final c = e.value;
            return _TestimonialCard(
              name: c.$1, role: c.$2, earned: c.$3,
              color: c.$4, initials: c.$5, quote: c.$6,
              delay: e.key * 140,
            );
          }).toList(),
        ),
      ]),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final String name, role, earned, initials, quote;
  final Color color;
  final int delay;
  const _TestimonialCard({required this.name, required this.role, required this.earned,
      required this.initials, required this.quote, required this.color, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _bgWhite, borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: const [BoxShadow(color: Color(0x07000000), blurRadius: 20, offset: Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Earned badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: color.withOpacity(0.20)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.volunteer_activism_rounded, color: color, size: 13),
            const SizedBox(width: 6),
            Text(earned, style: GoogleFonts.dmSans(
                color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 20),
        // Quote
        Text(quote, style: GoogleFonts.dmSans(
            color: _ink, fontSize: 14.5, height: 1.65, fontWeight: FontWeight.w500)),
        const SizedBox(height: 24),
        const Divider(color: _border, height: 1),
        const SizedBox(height: 20),
        // Creator
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.28), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Center(child: Text(initials, style: GoogleFonts.dmSans(
                color: _white, fontWeight: FontWeight.w800, fontSize: 13))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: GoogleFonts.dmSans(
                color: _ink, fontWeight: FontWeight.w700, fontSize: 14)),
            Text(role, style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 12)),
          ])),
          Row(children: [for (int i = 0; i < 5; i++)
              const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 12)]),
        ]),
      ]),
    )
        .animate()
        .fadeIn(delay: delay.ms, duration: 500.ms)
        .slideY(begin: 0.18, curve: Curves.easeOut);
  }
}

// ─── CTA ──────────────────────────────────────────────────────────────────────
class _CtaSection extends StatelessWidget {
  const _CtaSection();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final mobile = w < 680;

    final stats = [
      ('12 000+', 'Active creators'),
      ('R 2.4M+', 'Paid out this month'),
      ('1–2 days', 'Average payout time'),
    ];

    final trustPills = ['No credit card', 'Free forever', 'Cancel anytime'];

    return Container(
      color: _bgSage,
      padding: EdgeInsets.fromLTRB(mobile ? 16 : 32, 0, mobile ? 16 : 32, 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF003D1F), Color(0xFF00622E), Color(0xFF007A38)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _green.withOpacity(0.30),
                  blurRadius: 60,
                  offset: const Offset(0, 24),
                ),
              ],
            ),
            child: Stack(children: [
              // subtle dot grid overlay
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: CustomPaint(painter: _DotGridPainter()),
                ),
              ),
              // top-right glow
              Positioned(
                top: -60, right: -60,
                child: Container(
                  width: 280, height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _greenBright.withOpacity(0.18),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              // content
              Padding(
                padding: EdgeInsets.fromLTRB(
                    mobile ? 28 : 56, mobile ? 48 : 60,
                    mobile ? 28 : 56, mobile ? 40 : 56),
                child: Column(children: [
                  // stats strip
                  if (!mobile)
                    Container(
                      margin: const EdgeInsets.only(bottom: 44),
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.10)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: stats.map((s) => Column(children: [
                          Text(s.$1, style: GoogleFonts.dmSans(
                              color: _white, fontWeight: FontWeight.w800,
                              fontSize: 22, letterSpacing: -0.8)),
                          const SizedBox(height: 2),
                          Text(s.$2, style: GoogleFonts.dmSans(
                              color: Colors.white.withOpacity(0.55), fontSize: 12)),
                        ])).toList(),
                      ),
                    ).animate().fadeIn(duration: 400.ms),

                  // headline
                  Text('Ready to fill\nyour jar?',
                      style: GoogleFonts.dmSans(
                          color: _white, fontWeight: FontWeight.w800,
                          fontSize: mobile ? 40 : 58,
                          height: 1.05, letterSpacing: -2.2),
                      textAlign: TextAlign.center)
                      .animate().fadeIn(delay: 80.ms, duration: 500.ms)
                      .slideY(begin: 0.12, curve: Curves.easeOut),
                  const SizedBox(height: 16),
                  Text('Create your page in under a minute.\nStart earning from your very first tip.',
                      style: GoogleFonts.dmSans(
                          color: Colors.white.withOpacity(0.60),
                          fontSize: mobile ? 14.5 : 16, height: 1.65),
                      textAlign: TextAlign.center)
                      .animate().fadeIn(delay: 160.ms, duration: 500.ms),
                  const SizedBox(height: 36),

                  // buttons
                  Wrap(
                    spacing: 12, runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => context.go('/register'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _white,
                          foregroundColor: _green,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                        ),
                        child: Text('Create your free page →',
                            style: GoogleFonts.dmSans(
                                fontSize: 15, fontWeight: FontWeight.w700, color: _green)),
                      ),
                      OutlinedButton(
                        onPressed: () => context.go('/features'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _white,
                          side: BorderSide(color: Colors.white.withOpacity(0.30)),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                        ),
                        child: Text('See how it works',
                            style: GoogleFonts.dmSans(
                                fontSize: 15, fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.85))),
                      ),
                    ],
                  ).animate().fadeIn(delay: 240.ms, duration: 500.ms)
                      .scale(begin: const Offset(0.94, 0.94), curve: Curves.easeOut),
                  const SizedBox(height: 24),

                  // trust pills
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: trustPills.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: Colors.white.withOpacity(0.14)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.check_circle_rounded,
                            size: 12, color: _greenGlow),
                        const SizedBox(width: 5),
                        Text(t, style: GoogleFonts.dmSans(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 11.5, fontWeight: FontWeight.w500)),
                      ]),
                    )).toList(),
                  ).animate().fadeIn(delay: 340.ms, duration: 400.ms),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double x = 0; x <= size.width; x += spacing)
      for (double y = 0; y <= size.height; y += spacing)
        canvas.drawCircle(Offset(x, y), 1.2, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}


// ─── Footer ───────────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final mobile = w < 700;
    final cols = [
      ('Product',  [('Features', '/features')]),
      ('Company',  [('About', '/about'), ('Blog', '/blog')]),
      ('Legal',    [('Privacy', '/privacy'), ('Terms', '/terms'), ('Cookies', '/cookies')]),
    ];

    final brand = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const AppLogoIcon(size: 26),
        const SizedBox(width: 8),
        Text('TippingJar', style: GoogleFonts.dmSans(
            color: _ink, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.4)),
      ]),
      const SizedBox(height: 12),
      Text('Supporting creators,\none tip at a time.',
          style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 13, height: 1.65)),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: _greenBright.withOpacity(0.08),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: _greenBright.withOpacity(0.22)),
        ),
        child: Text('🇿🇦  Proudly South African', style: GoogleFonts.dmSans(
            color: _greenMid, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    ]);

    Widget col((String, List<(String, String)>) c) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(c.$1, style: GoogleFonts.dmSans(
            color: _ink, fontWeight: FontWeight.w700, fontSize: 12,
            letterSpacing: 0.6)),
        const SizedBox(height: 12),
        ...c.$2.map((l) => Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go(l.$2),
              child: Text(l.$1, style: GoogleFonts.dmSans(
                  color: _inkMuted, fontSize: 13, height: 1.4)),
            ),
          ),
        )),
      ],
    );

    return Container(
      color: _bgSage,
      child: Column(children: [
        Container(height: 1, color: _border),
        Padding(
          padding: EdgeInsets.fromLTRB(mobile ? 24 : 64, 52, mobile ? 24 : 64, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (mobile) ...[
              brand,
              const SizedBox(height: 36),
              Wrap(spacing: 40, runSpacing: 28, children: cols.map(col).toList()),
            ] else
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: brand),
                ...cols.map((c) => Expanded(child: col(c))),
              ]),
            const SizedBox(height: 44),
            Container(height: 1, color: _border),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('© 2026 TippingJar (Pty) Ltd.',
                      style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 12)),
                  if (!mobile)
                    Text('Made with ♥ for creators.',
                        style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 12)),
                ],
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String tag, title, sub;
  const _SectionHeader({required this.tag, required this.title, required this.sub});

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
        Text(tag, style: GoogleFonts.dmSans(
            color: _green, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    ).animate().fadeIn(duration: 400.ms),
    const SizedBox(height: 16),
    Text(title,
        style: GoogleFonts.dmSans(
            color: _ink, fontWeight: FontWeight.w800, fontSize: 40,
            height: 1.12, letterSpacing: -1.5),
        textAlign: TextAlign.center)
        .animate().fadeIn(delay: 100.ms, duration: 500.ms)
        .slideY(begin: 0.12, curve: Curves.easeOut),
    const SizedBox(height: 14),
    ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Text(sub,
          style: GoogleFonts.dmSans(color: _inkBody, fontSize: 16, height: 1.7),
          textAlign: TextAlign.center),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
  ]);
}
