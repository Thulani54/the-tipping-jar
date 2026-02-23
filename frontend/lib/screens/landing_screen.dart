import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_logo.dart';

// ─── Palette ─────────────────────────────────────────────────────────────────
const _dark        = Color(0xFF0A0F0D);
const _darker      = Color(0xFF060A08);
const _orange      = Color(0xFF004423);
const _orangeLight = Color(0xFF1A6B3E);
const _pink        = Color(0xFF0097B2);
const _purple      = Color(0xFF2563EB);
const _cardBg      = Color(0xFF111A16);
const _border      = Color(0xFF1E2E26);
const _textMuted   = Color(0xFF7A9088);
const _white       = Colors.white;

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
      final solid = _scroll.offset > 60;
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
      backgroundColor: _dark,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scroll,
            child: Column(
              children: [
                const _HeroSection(),
                _StatsSection(),
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
      duration: 250.ms,
      color: solid ? _darker.withOpacity(0.95) : Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: w > 900 ? 64 : 24, vertical: 18),
          child: Row(
            children: [
              Row(children: [
                const AppLogoIcon(size: 32),
                const SizedBox(width: 10),
                Text('TippingJar',
                    style: GoogleFonts.inter(
                        color: _white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        letterSpacing: -0.3)),
              ]),
              const Spacer(),
              if (w > 1000) ...[
                _navLink('Features', context, '/features'),
                _navLink('How it works', context, '/how-it-works'),
                _navLink('Creators', context, '/creators'),
                _navLink('Enterprise', context, '/enterprise'),
                _navLink('Developers', context, '/developers'),
                const SizedBox(width: 8),
              ],
              _outlineBtn('Sign in', () => context.go('/login'), context),
              const SizedBox(width: 10),
              _solidBtn('Get started', () => context.go('/register'), context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navLink(String label, BuildContext ctx, String route) =>
      GestureDetector(
        onTap: () => ctx.go(route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label,
              style: GoogleFonts.inter(
                  color: _textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
      );

  Widget _outlineBtn(String label, VoidCallback onTap, BuildContext ctx) =>
      OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _white,
          side: const BorderSide(color: _border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
        ),
        child: Text(label,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
      );

  Widget _solidBtn(String label, VoidCallback onTap, BuildContext ctx) =>
      ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _orange,
          foregroundColor: _white,
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600, color: _white)),
      );
}

// ─── Hero ─────────────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final narrow = w < 860;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const NetworkImage(
            'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?auto=format&fit=crop&w=1920&q=80',
          ),
          fit: BoxFit.cover,
          colorFilter: const ColorFilter.mode(
            Color(0xFF001A0C),
            BlendMode.multiply,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Subtle dot-grid (light dots on dark photo background)
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter()),
          ),
          // Soft white glow at top-centre
          Positioned(
            top: -240,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 800,
                height: 640,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.04),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(
              narrow ? 24 : 48, 136, narrow ? 24 : 48, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Announcement pill ──
                _badge()
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.2, curve: Curves.easeOut),
                const SizedBox(height: 32),

                // ── Headline ──
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Text(
                    'Get paid by the people\nwho love your work.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: narrow ? 40 : 72,
                      fontWeight: FontWeight.w800,
                      height: 1.07,
                      letterSpacing: narrow ? -1.5 : -3.0,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 120.ms, duration: 600.ms)
                    .slideY(begin: 0.2, curve: Curves.easeOut),
                const SizedBox(height: 22),

                // ── Subtext ──
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Text(
                    'Set up your TippingJar page in 60 seconds. Share one link. '
                    'Let fans support you — no subscriptions, no friction.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.62), fontSize: 17, height: 1.65),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 240.ms, duration: 600.ms)
                    .slideY(begin: 0.2, curve: Curves.easeOut),
                const SizedBox(height: 40),

                // ── CTAs ──
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => context.go('/register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: _white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'Create your free page →',
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _white),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => context.go('/creators'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _white,
                        side: BorderSide(color: _white.withOpacity(0.3)),
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'See live examples',
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _white),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 360.ms, duration: 500.ms)
                    .slideY(begin: 0.15, curve: Curves.easeOut),
                const SizedBox(height: 24),

                // ── Trust line ──
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _dot(),
                    const SizedBox(width: 8),
                    Text('No credit card required',
                        style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.40), fontSize: 13)),
                    const SizedBox(width: 20),
                    _dot(),
                    const SizedBox(width: 8),
                    Text('Trusted by 2,400+ creators',
                        style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.40), fontSize: 13)),
                    const SizedBox(width: 20),
                    _dot(),
                    const SizedBox(width: 8),
                    Text('ZA-built · Powered by Paystack',
                        style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.40), fontSize: 13)),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 480.ms, duration: 500.ms),
                const SizedBox(height: 72),

                // ── Product preview ──
                const _ProductPreview()
                    .animate()
                    .fadeIn(delay: 580.ms, duration: 700.ms)
                    .slideY(begin: 0.12, curve: Curves.easeOut),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
                color: const Color(0xFF34D8A0),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF34D8A0).withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 1)
                ]),
          ),
          const SizedBox(width: 10),
          Text(
            "South Africa's creator tipping platform",
            style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.80),
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ]),
      );

  Widget _dot() => Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          shape: BoxShape.circle,
        ),
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

// ─── Product preview ─────────────────────────────────────────────────────────
class _ProductPreview extends StatelessWidget {
  const _ProductPreview();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: _orange.withOpacity(0.06),
              blurRadius: 100,
              offset: const Offset(0, 32),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Browser chrome
            _BrowserBar(),
            // App content
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Creator header
                  _CreatorRow(),
                  const SizedBox(height: 24),
                  // Amount picker
                  _AmountRow(),
                  const SizedBox(height: 20),
                  // Send button
                  _SendButton(),
                  const SizedBox(height: 28),
                  // Divider
                  Row(children: [
                    Expanded(child: Divider(color: _border, thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text('Recent tips',
                          style: GoogleFonts.inter(
                              color: _textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6)),
                    ),
                    Expanded(child: Divider(color: _border, thickness: 1)),
                  ]),
                  const SizedBox(height: 16),
                  // Tip feed
                  _TipRow(
                      initials: 'SK',
                      name: 'Sarah K.',
                      amount: 'R50',
                      message: 'Love your beats! Keep going 🔥',
                      timeAgo: '2m'),
                  const SizedBox(height: 10),
                  _TipRow(
                      initials: 'JD',
                      name: 'James D.',
                      amount: 'R100',
                      message: 'Best producer in SA, no debate.',
                      timeAgo: '14m'),
                  const SizedBox(height: 10),
                  _TipRow(
                      initials: '?',
                      name: 'Anonymous',
                      amount: 'R20',
                      message: '',
                      timeAgo: '1h',
                      muted: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowserBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      color: _darker,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        // Traffic lights
        Row(children: [
          _trafficDot(const Color(0xFFFF5F57)),
          const SizedBox(width: 6),
          _trafficDot(const Color(0xFFFFBD2E)),
          const SizedBox(width: 6),
          _trafficDot(const Color(0xFF28CA41)),
        ]),
        const SizedBox(width: 16),
        // URL bar
        Expanded(
          child: Container(
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFF0A0F0D),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_rounded, size: 10, color: _textMuted.withOpacity(0.5)),
                const SizedBox(width: 5),
                Text(
                  'tippingjar.co.za/thulani',
                  style: GoogleFonts.inter(
                      color: _textMuted.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Icon(Icons.more_horiz_rounded, size: 16, color: _textMuted.withOpacity(0.3)),
      ]),
    );
  }

  Widget _trafficDot(Color color) => Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _CreatorRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // Avatar
      Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: _orange,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text('TM',
              style: GoogleFonts.inter(
                  color: _white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Thulani M.',
              style: GoogleFonts.inter(
                  color: _white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: -0.3)),
          const SizedBox(height: 2),
          Text('Music Producer & Beatmaker',
              style: GoogleFonts.inter(color: _textMuted, fontSize: 13)),
        ]),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: _orange.withOpacity(0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
                color: _orange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: _orange.withOpacity(0.7),
                      blurRadius: 4,
                      spreadRadius: 1)
                ]),
          ),
          const SizedBox(width: 6),
          Text('Live',
              style: GoogleFonts.inter(
                  color: _orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    ]);
  }
}

class _AmountRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Choose an amount',
          style: GoogleFonts.inter(
              color: _textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 10),
      Row(children: [
        for (final entry in [
          ('R20', false),
          ('R50', true),
          ('R100', false),
          ('R200', false),
        ]) ...[
          _AmountChip(label: entry.$1, selected: entry.$2),
          const SizedBox(width: 8),
        ],
      ]),
    ]);
  }
}

class _AmountChip extends StatelessWidget {
  final String label;
  final bool selected;
  const _AmountChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? _orange : _dark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? _orange : _border,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: selected
            ? [BoxShadow(color: _orange.withOpacity(0.25), blurRadius: 12)]
            : [],
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              color: _white,
              fontWeight: FontWeight.w700,
              fontSize: 13)),
    );
  }
}

class _SendButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: _orange,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: _orange.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.favorite_rounded, color: _white, size: 15),
        const SizedBox(width: 8),
        Text('Send R50 tip',
            style: GoogleFonts.inter(
                color: _white, fontWeight: FontWeight.w700, fontSize: 14)),
      ]),
    );
  }
}

class _TipRow extends StatelessWidget {
  final String initials, name, amount, message, timeAgo;
  final bool muted;
  const _TipRow({
    required this.initials,
    required this.name,
    required this.amount,
    required this.message,
    required this.timeAgo,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _dark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(children: [
        // Avatar
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: muted
                ? _border
                : _orange.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(initials,
                style: GoogleFonts.inter(
                    color: muted ? _textMuted : _orange,
                    fontWeight: FontWeight.w700,
                    fontSize: 11)),
          ),
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(name,
                  style: GoogleFonts.inter(
                      color: muted ? _textMuted : _white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
              const Spacer(),
              Text(amount,
                  style: GoogleFonts.inter(
                      color: _orange,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
              const SizedBox(width: 8),
              Text(timeAgo,
                  style: GoogleFonts.inter(
                      color: _textMuted.withOpacity(0.5), fontSize: 11)),
            ]),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(message,
                  style: GoogleFonts.inter(
                      color: _textMuted, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ]),
        ),
      ]),
    );
  }
}

// ─── Glow blob (used in CTA section) ─────────────────────────────────────────
class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color, blurRadius: size * 0.8)],
        ),
      );
}

// ─── Stats ────────────────────────────────────────────────────────────────────
class _StatsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stats = [
      ('2,400+', 'Creators'),
      ('R3.6M+', 'Tips sent'),
      ('48', 'Countries'),
      ('4.9★', 'Avg rating'),
    ];
    return Container(
      color: _darker,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        runSpacing: 24,
        spacing: 40,
        children: stats.asMap().entries.map((e) {
          return Column(children: [
            Text(e.value.$1,
                style: GoogleFonts.inter(
                    color: _white,
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    letterSpacing: -1))
                .animate()
                .fadeIn(delay: (e.key * 100).ms, duration: 500.ms),
            const SizedBox(height: 4),
            Text(e.value.$2,
                style: GoogleFonts.inter(
                    color: _textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ]);
        }).toList(),
      ),
    );
  }
}

// ─── How it works ─────────────────────────────────────────────────────────────
class _HowItWorksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      (
        Icons.person_add_alt_1_rounded,
        'Create your page',
        'Sign up as a creator in 60 seconds. Customise your profile, set a tip goal, and share your link.',
        _orange,
      ),
      (
        Icons.link_rounded,
        'Share your link',
        'Post your TippingJar link anywhere — Twitter, Instagram, YouTube, your newsletter.',
        _pink,
      ),
      (
        Icons.account_balance_wallet_rounded,
        'Collect tips',
        'Fans drop tips instantly via card. Funds land in your Paystack account — no waiting, no middleman.',
        _purple,
      ),
    ];

    return _SectionWrapper(
      dark: true,
      child: Column(
        children: [
          _SectionHeader(
            tag: 'How it works',
            title: 'From zero to tipping\nin three steps',
            subtitle:
                'No complicated setup. Just you, your fans, and a jar worth filling.',
          ),
          const SizedBox(height: 56),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: steps.asMap().entries.map((e) {
              final s = e.value;
              return _StepCard(
                number: e.key + 1,
                icon: s.$1,
                title: s.$2,
                body: s.$3,
                color: s.$4,
                delay: e.key * 120,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatefulWidget {
  final int number;
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final int delay;
  const _StepCard(
      {required this.number,
      required this.icon,
      required this.title,
      required this.body,
      required this.color,
      required this.delay});

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: 200.ms,
        width: 300,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _hovered ? _cardBg : const Color(0xFF111118),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: _hovered
                  ? widget.color.withOpacity(0.5)
                  : _border),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                      color: widget.color.withOpacity(0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 12))
                ]
              : [],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: widget.color, size: 22),
            ),
            const Spacer(),
            Text('0${widget.number}',
                style: GoogleFonts.inter(
                    color: widget.color.withOpacity(0.3),
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1)),
          ]),
          const SizedBox(height: 20),
          Text(widget.title,
              style: GoogleFonts.inter(
                  color: _white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17)),
          const SizedBox(height: 10),
          Text(widget.body,
              style: GoogleFonts.inter(
                  color: _textMuted, fontSize: 14, height: 1.6)),
        ]),
      )
          .animate()
          .fadeIn(delay: widget.delay.ms, duration: 500.ms)
          .slideY(begin: 0.2, curve: Curves.easeOut),
    );
  }
}

// ─── Features ─────────────────────────────────────────────────────────────────
class _FeaturesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final features = [
      (Icons.flash_on_rounded, 'Instant payouts',
          'No holding periods. Paystack sends money straight to your bank.', _orange),
      (Icons.face_rounded, 'Anonymous tips',
          'Fans can tip without creating an account — zero friction.', _pink),
      (Icons.bar_chart_rounded, 'Live analytics',
          'Watch tips roll in with a real-time dashboard built for creators.', _purple),
      (Icons.lock_rounded, 'Bank-grade security',
          'All payments processed by Paystack — PCI-DSS compliant, always.', const Color(0xFF22D3EE)),
      (Icons.palette_rounded, 'Custom pages',
          'Personalise your tip page with cover art, a tagline, and a monthly goal.', const Color(0xFF4ADE80)),
      (Icons.public_rounded, 'Works worldwide',
          'Accept tips in 135+ currencies across 48 countries.', _orangeLight),
    ];

    return _SectionWrapper(
      dark: false,
      child: Column(children: [
        _SectionHeader(
          tag: 'Features',
          title: 'Everything a creator\nactually needs',
          subtitle:
              'We cut the fluff and kept only what matters for getting paid.',
          dark: false,
        ),
        const SizedBox(height: 56),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: features.asMap().entries.map((e) {
            return _FeatureCard(
              icon: e.value.$1,
              title: e.value.$2,
              body: e.value.$3,
              color: e.value.$4,
              delay: e.key * 80,
            );
          }).toList(),
        ),
      ]),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final int delay;
  const _FeatureCard(
      {required this.icon,
      required this.title,
      required this.body,
      required this.color,
      required this.delay});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: 200.ms,
        width: 280,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _hovered
              ? const Color(0xFFF5F5FA)
              : const Color(0xFFF8F8FC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: _hovered
                  ? widget.color.withOpacity(0.4)
                  : const Color(0xFFE8E8F0)),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                      color: widget.color.withOpacity(0.12),
                      blurRadius: 32,
                      offset: const Offset(0, 8))
                ]
              : [
                  const BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 8,
                      offset: Offset(0, 2))
                ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.icon, color: widget.color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(widget.title,
              style: GoogleFonts.inter(
                  color: const Color(0xFF0D0D12),
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 8),
          Text(widget.body,
              style: GoogleFonts.inter(
                  color: const Color(0xFF6B6B80),
                  fontSize: 13,
                  height: 1.6)),
        ]),
      )
          .animate()
          .fadeIn(delay: widget.delay.ms, duration: 400.ms)
          .slideY(begin: 0.15, curve: Curves.easeOut),
    );
  }
}

// ─── Creator spotlight ────────────────────────────────────────────────────────
class _CreatorSpotlightSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final creators = [
      ('Mia Chen', 'Illustrator & comic artist', 'R3,240', _pink, 'MC'),
      ('Raj Patel', 'Indie game developer', 'R1,870', _purple, 'RP'),
      ('Lena Torres', 'Music producer & DJ', 'R5,100', _orange, 'LT'),
    ];

    return _SectionWrapper(
      dark: true,
      child: Column(children: [
        _SectionHeader(
          tag: 'Creator spotlight',
          title: 'Real creators,\nreal tips',
          subtitle: 'Join thousands already filling their jar every day.',
        ),
        const SizedBox(height: 56),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: creators.asMap().entries.map((e) {
            final c = e.value;
            return _CreatorCard(
              name: c.$1,
              role: c.$2,
              earned: c.$3,
              color: c.$4,
              initials: c.$5,
              delay: e.key * 130,
            );
          }).toList(),
        ),
      ]),
    );
  }
}

class _CreatorCard extends StatelessWidget {
  final String name, role, earned, initials;
  final Color color;
  final int delay;
  const _CreatorCard(
      {required this.name,
      required this.role,
      required this.earned,
      required this.initials,
      required this.color,
      required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          height: 72,
          decoration: BoxDecoration(
            color: color.withOpacity(0.35),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: _cardBg, width: 3),
            ),
            child: Center(
              child: Text(initials,
                  style: GoogleFonts.inter(
                      color: _white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.inter(
                          color: _white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  Text(role,
                      style: GoogleFonts.inter(
                          color: _textMuted, fontSize: 12)),
                ]),
          ),
        ]),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _dark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: Row(children: [
            Icon(Icons.volunteer_activism, color: color, size: 16),
            const SizedBox(width: 8),
            Text('Total tips earned',
                style: GoogleFonts.inter(
                    color: _textMuted, fontSize: 12)),
            const Spacer(),
            Text(earned,
                style: GoogleFonts.inter(
                    color: _white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15)),
          ]),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go('/explore'),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withOpacity(0.4)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(36)),
            ),
            child: Text('Send a tip',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    )
        .animate()
        .fadeIn(delay: delay.ms, duration: 500.ms)
        .slideY(begin: 0.2, curve: Curves.easeOut);
  }
}

// ─── CTA ──────────────────────────────────────────────────────────────────────
class _CtaSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
        decoration: BoxDecoration(
          color: const Color(0xFF001A12),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _border),
        ),
        child: Stack(
          children: [
            Positioned(
                top: -40,
                right: -40,
                child: _GlowBlob(
                    color: _orange.withOpacity(0.2), size: 300)),
            Positioned(
                bottom: -60,
                left: 40,
                child: _GlowBlob(
                    color: _purple.withOpacity(0.2), size: 260)),
            Column(children: [
              Text('Ready to fill your jar?',
                  style: GoogleFonts.inter(
                      color: _white,
                      fontWeight: FontWeight.w800,
                      fontSize: 42,
                      letterSpacing: -1.5),
                  textAlign: TextAlign.center)
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOut),
              const SizedBox(height: 16),
              Text('Set up your creator page in under a minute.\nNo credit card required.',
                  style: GoogleFonts.inter(
                      color: _textMuted, fontSize: 16, height: 1.6),
                  textAlign: TextAlign.center)
                  .animate()
                  .fadeIn(delay: 150.ms, duration: 500.ms),
              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: () => context.go('/register'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: _white,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 36, vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(36)),
                ),
                child: Text('Create your free page →',
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _white)),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 500.ms)
                  .scale(
                      begin: const Offset(0.93, 0.93),
                      curve: Curves.easeOut),
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
    return Container(
      color: _darker,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: Column(children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const AppLogoIcon(size: 28),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text('TippingJar',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                color: _white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Text('Supporting creators,\none tip at a time.',
                        style: GoogleFonts.inter(
                            color: _textMuted,
                            fontSize: 13,
                            height: 1.6)),
                  ]),
            ),
            ...[
              ('Product',  [('Features', '/features'), ('Pricing', '/pricing'), ('Changelog', '/changelog')]),
              ('Company',  [('About', '/about'), ('Blog', '/blog'), ('Careers', '/careers')]),
              ('Legal',    [('Privacy', '/privacy'), ('Terms', '/terms'), ('Cookies', '/cookies')]),
            ].map((col) => Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(col.$1,
                            style: GoogleFonts.inter(
                                color: _white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        const SizedBox(height: 12),
                        ...col.$2.map((link) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GestureDetector(
                                onTap: () => context.go(link.$2),
                                child: Text(link.$1,
                                    style: GoogleFonts.inter(
                                        color: _textMuted, fontSize: 13)),
                              ),
                            )),
                      ]),
                )),
          ],
        ),
        const SizedBox(height: 40),
        const Divider(color: _border),
        const SizedBox(height: 20),
        Text('© 2026 TippingJar. All rights reserved.',
            style: GoogleFonts.inter(
                color: _textMuted, fontSize: 12)),
      ]),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────
class _SectionWrapper extends StatelessWidget {
  final bool dark;
  final Widget child;
  const _SectionWrapper({required this.dark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: dark ? _dark : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 40),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String tag;
  final String title;
  final String subtitle;
  final bool dark;
  const _SectionHeader(
      {required this.tag,
      required this.title,
      required this.subtitle,
      this.dark = true});

  @override
  Widget build(BuildContext context) {
    final titleColor = dark ? _white : const Color(0xFF0D0D12);
    final subtitleColor = dark ? _textMuted : const Color(0xFF6B6B80);

    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: _orange.withOpacity(dark ? 0.1 : 0.08),
          border: Border.all(color: _orange.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(tag,
            style: GoogleFonts.inter(
                color: _orange,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      )
          .animate()
          .fadeIn(duration: 400.ms),
      const SizedBox(height: 16),
      Text(title,
          style: GoogleFonts.inter(
              color: titleColor,
              fontWeight: FontWeight.w800,
              fontSize: 38,
              height: 1.15,
              letterSpacing: -1.2),
          textAlign: TextAlign.center)
          .animate()
          .fadeIn(delay: 100.ms, duration: 500.ms)
          .slideY(begin: 0.15, curve: Curves.easeOut),
      const SizedBox(height: 14),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Text(subtitle,
            style: GoogleFonts.inter(
                color: subtitleColor, fontSize: 16, height: 1.65),
            textAlign: TextAlign.center),
      )
          .animate()
          .fadeIn(delay: 200.ms, duration: 500.ms),
    ]);
  }
}
