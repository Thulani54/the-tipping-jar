import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Palette ─────────────────────────────────────────────────────────────────
const _dark = Color(0xFF0A0F0D);
const _darker = Color(0xFF060A08);
const _orange = Color(0xFF00C896);      // primary green
const _orangeLight = Color(0xFF34D8A0); // light green
const _pink = Color(0xFF0097B2);        // ocean teal
const _purple = Color(0xFF2563EB);      // electric blue
const _cardBg = Color(0xFF111A16);
const _border = Color(0xFF1E2E26);
const _textMuted = Color(0xFF7A9088);
const _white = Colors.white;

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  final _scroll = ScrollController();
  late final AnimationController _floatCtrl;
  bool _navSolid = false;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _scroll.addListener(() {
      final solid = _scroll.offset > 60;
      if (solid != _navSolid) setState(() => _navSolid = solid);
    });
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
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
                _HeroSection(floatCtrl: _floatCtrl),
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
              // Logo
              Row(children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: _orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.volunteer_activism,
                      color: _white, size: 17),
                ),
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

  Widget _navLink(String label, BuildContext ctx, String route) => GestureDetector(
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _white)),
      );
}

// ─── Hero ─────────────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final AnimationController floatCtrl;
  const _HeroSection({required this.floatCtrl});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final narrow = w < 900;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 760),
      decoration: const BoxDecoration(
        color: _dark,
      ),
      child: Stack(
        children: [
          // Mesh blobs
          Positioned(
              top: 100, left: -80,
              child: _GlowBlob(color: _purple.withOpacity(0.10), size: 420)),
          Positioned(
              top: 200, right: -60,
              child: _GlowBlob(color: _pink.withOpacity(0.07), size: 360)),
          Positioned(
              bottom: 60, left: 200,
              child: _GlowBlob(color: _orange.withOpacity(0.08), size: 280)),

          // Content
          Padding(
            padding: EdgeInsets.only(
                top: 140,
                bottom: 100,
                left: narrow ? 24 : 80,
                right: narrow ? 24 : 80),
            child: narrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _heroText(context),
                      const SizedBox(height: 56),
                      _floatingCard(floatCtrl),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 5, child: _heroText(context)),
                      const SizedBox(width: 48),
                      Expanded(flex: 4, child: _floatingCard(floatCtrl)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _heroText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: _orange.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(100),
            color: _orange.withOpacity(0.08),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.bolt, color: _orange, size: 14),
            const SizedBox(width: 6),
            Text('Creator monetisation, simplified',
                style: GoogleFonts.inter(
                    color: _orange, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.3, curve: Curves.easeOut),
        const SizedBox(height: 28),

        // Headline
        Builder(builder: (ctx) {
          final fs = MediaQuery.of(ctx).size.width < 700 ? 42.0 : 60.0;
          final gradientPaint = Paint()
            ..shader = const LinearGradient(colors: [_orange, _pink])
                .createShader(const Rect.fromLTWH(0, 0, 400, 80));
          return RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                  fontSize: fs,
                  fontWeight: FontWeight.w800,
                  color: _white,
                  height: 1.08,
                  letterSpacing: -2.5),
              children: [
                const TextSpan(text: 'The easiest way\nfor fans to '),
                TextSpan(
                    text: 'tip\nthe creators',
                    style: TextStyle(foreground: gradientPaint)),
                const TextSpan(text: ' they love.'),
              ],
            ),
          );
        })
            .animate()
            .fadeIn(delay: 150.ms, duration: 600.ms)
            .slideY(begin: 0.25, curve: Curves.easeOut),
        const SizedBox(height: 24),

        // Subtitle
        Text(
          'TippingJar lets you support creators with a single tap — no subscriptions, no friction. Just genuine appreciation.',
          style: GoogleFonts.inter(
              color: _textMuted, fontSize: 17, height: 1.65),
        )
            .animate()
            .fadeIn(delay: 300.ms, duration: 600.ms)
            .slideY(begin: 0.25, curve: Curves.easeOut),
        const SizedBox(height: 40),

        // CTAs
        Wrap(spacing: 14, runSpacing: 12, children: [
          ElevatedButton(
            onPressed: () => context.go('/register'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: _white,
              shadowColor: Colors.transparent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(36)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Start tipping for free',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _white)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 16, color: _white),
            ]),
          ),
          OutlinedButton(
            onPressed: () => context.go('/login'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _white,
              side: const BorderSide(color: _border, width: 1.5),
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(36)),
            ),
            child: Text('Browse creators',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ])
            .animate()
            .fadeIn(delay: 450.ms, duration: 600.ms)
            .slideY(begin: 0.25, curve: Curves.easeOut),
        const SizedBox(height: 32),

        // Trust line
        Row(children: [
          ...List.generate(
              5,
              (_) => const Icon(Icons.star_rounded,
                  color: _orange, size: 16)),
          const SizedBox(width: 10),
          Text('Loved by 2,400+ creators worldwide',
              style: GoogleFonts.inter(
                  color: _textMuted, fontSize: 13)),
        ])
            .animate()
            .fadeIn(delay: 600.ms, duration: 500.ms),
      ],
    );
  }

  Widget _floatingCard(AnimationController ctrl) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final offset = math.sin(ctrl.value * math.pi) * 10;
        return Transform.translate(
          offset: Offset(0, offset),
          child: const _MockupCard(),
        );
      },
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 700.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut);
  }
}

// ─── Floating UI mockup ───────────────────────────────────────────────────────
class _MockupCard extends StatelessWidget {
  const _MockupCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: _purple.withOpacity(0.2),
              blurRadius: 60,
              offset: const Offset(0, 20)),
        ],
      ),
      child: Column(
        children: [
          // Profile row
          Row(children: [
            _avatar('AJ', _orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Alex Johnson',
                      style: GoogleFonts.inter(
                          color: _white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  Text('@alexcreates',
                      style: GoogleFonts.inter(
                          color: _textMuted, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text('Creator',
                  style: GoogleFonts.inter(
                      color: _orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            )
          ]),
          const SizedBox(height: 20),

          // Tip amount selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _dark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Column(children: [
              Text('Choose an amount',
                  style: GoogleFonts.inter(
                      color: _textMuted, fontSize: 12)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['\$1', '\$5', '\$10', '\$25'].map((a) {
                  final selected = a == '\$5';
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? _orange : _cardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: selected ? Colors.transparent : _border),
                    ),
                    child: Text(a,
                        style: GoogleFonts.inter(
                            color: _white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  );
                }).toList(),
              ),
            ]),
          ),
          const SizedBox(height: 14),

          // Tip feed items
          ..._tipItems(),
          const SizedBox(height: 16),

          // Send button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _orange,
              borderRadius: BorderRadius.circular(36),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.volunteer_activism,
                    color: _white, size: 16),
                const SizedBox(width: 8),
                Text('Send \$5 tip',
                    style: GoogleFonts.inter(
                        color: _white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _tipItems() {
    final items = [
      ('Sarah M.', '\$10', 'Keep up the amazing work! 🔥', 'SM', _pink),
      ('David K.', '\$25', 'Best creator on the internet.', 'DK', _purple),
    ];
    return items.map((t) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _dark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Row(children: [
          _avatar(t.$1.split(' ').map((w) => w[0]).join(), t.$5,
              size: 30, fontSize: 11),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(t.$1,
                      style: GoogleFonts.inter(
                          color: _white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                  const Spacer(),
                  Text(t.$2,
                      style: GoogleFonts.inter(
                          color: _orange,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ]),
                Text(t.$3,
                    style: GoogleFonts.inter(
                        color: _textMuted, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ]),
      );
    }).toList();
  }

  Widget _avatar(String initials, Color color,
      {double size = 40, double fontSize = 14}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color, color.withOpacity(0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(initials,
            style: GoogleFonts.inter(
                color: _white,
                fontWeight: FontWeight.w700,
                fontSize: fontSize)),
      ),
    );
  }
}

// ─── Glow blob ────────────────────────────────────────────────────────────────
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
      ('\$180K+', 'Tips sent'),
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
                .fadeIn(delay: (e.key * 100).ms, duration: 500.ms)
                .slideY(begin: 0.3, curve: Curves.easeOut),
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
        'Fans drop tips instantly via card. Funds land in your Stripe account — no waiting, no middleman.',
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
          'No holding periods. Stripe sends money straight to your bank.', _orange),
      (Icons.face_rounded, 'Anonymous tips',
          'Fans can tip without creating an account — zero friction.', _pink),
      (Icons.bar_chart_rounded, 'Live analytics',
          'Watch tips roll in with a real-time dashboard built for creators.', _purple),
      (Icons.lock_rounded, 'Bank-grade security',
          'All payments processed by Stripe — PCI-DSS compliant, always.', const Color(0xFF22D3EE)),
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
      ('Mia Chen', 'Illustrator & comic artist', '\$3,240', _pink, 'MC'),
      ('Raj Patel', 'Indie game developer', '\$1,870', _purple, 'RP'),
      ('Lena Torres', 'Music producer & DJ', '\$5,100', _orange, 'LT'),
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
        // Cover strip
        Container(
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [color.withOpacity(0.6), color.withOpacity(0.15)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
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
            onPressed: () {},
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
          gradient: const LinearGradient(
            colors: [Color(0xFF001A12), Color(0xFF001520)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _border),
        ),
        child: Stack(
          children: [
            Positioned(
                top: -40, right: -40,
                child: _GlowBlob(
                    color: _orange.withOpacity(0.2), size: 300)),
            Positioned(
                bottom: -60, left: 40,
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
            // Brand
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: _orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.volunteer_activism,
                            color: _white, size: 14),
                      ),
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
            // Links
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
