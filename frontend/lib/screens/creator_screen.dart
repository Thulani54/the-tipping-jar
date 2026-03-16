// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:ui';
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/commission_model.dart';
import '../models/creator.dart';
import '../models/creator_post_model.dart';
import '../models/jar_model.dart';
import '../models/milestone_model.dart';
import '../models/tier_model.dart';
import '../models/tip.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const _bgWhite   = Colors.white;
const _bgSage    = Color(0xFFF5F9F6);
const _ink       = Color(0xFF080F0B);
const _inkBody   = Color(0xFF38524A);
const _inkMuted  = Color(0xFF7A9487);
const _border    = Color(0xFFDBEAE1);
const _green     = Color(0xFF004423);
const _greenMid  = Color(0xFF006B3A);

// ─── Public creator profile + tip page ───────────────────────────────────────
class CreatorScreen extends StatefulWidget {
  final String slug;
  const CreatorScreen({super.key, required this.slug});
  @override
  State<CreatorScreen> createState() => _CreatorScreenState();
}

class _CreatorScreenState extends State<CreatorScreen> {
  Creator? _creator;
  List<Tip> _tips = [];
  List<JarModel> _jars = [];
  List<CreatorPostModel> _publicPosts = [];
  List<TierModel> _tiers = [];
  List<MilestoneModel> _milestones = [];
  CommissionSlotModel? _commissionSlot;
  // null = locked, non-null = unlocked (may be empty if no posts)
  List<CreatorPostModel>? _unlockedPosts;
  bool _hasTipped = false;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _loadError = null; });
    try {
      final auth = context.read<AuthProvider>();
      final api = ApiService();
      final authApi = ApiService(authToken: auth.accessToken);
      final results = await Future.wait([
        api.getCreator(widget.slug),
        api.getCreatorTips(widget.slug),
        api.getCreatorJars(widget.slug),
        api.getPublicPosts(widget.slug),
        api.getPublicTiers(widget.slug).catchError((_) => <TierModel>[]),
        api.getPublicMilestones(widget.slug).catchError((_) => <MilestoneModel>[]),
        // Check if logged-in user has tipped this creator
        if (auth.isAuthenticated)
          authApi.hasTipped(widget.slug).catchError((_) => false),
      ]);
      if (mounted) {
        final tipped = auth.isAuthenticated ? (results[6] as bool? ?? false) : false;
        // Auto-unlock posts if user has tipped
        List<CreatorPostModel>? unlocked;
        if (tipped && auth.user != null) {
          try {
            unlocked = await authApi.unlockPosts(widget.slug, auth.user!.email);
          } catch (_) {}
        }
        setState(() {
          _creator       = results[0] as Creator;
          _tips          = results[1] as List<Tip>;
          _jars          = results[2] as List<JarModel>;
          _publicPosts   = results[3] as List<CreatorPostModel>;
          _tiers         = results[4] as List<TierModel>;
          _milestones    = results[5] as List<MilestoneModel>;
          _hasTipped     = tipped;
          _unlockedPosts = unlocked;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loadError = e.toString(); _loading = false; });
    }
  }

  void _onUnlocked(List<CreatorPostModel> posts) {
    setState(() => _unlockedPosts = posts);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _splash();
    if (_loadError != null) return _error();

    final creator = _creator!;
    final wide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: _bgSage,
      body: Column(children: [
        _MiniNav(creatorName: creator.displayName),
        Expanded(
          child: wide
              ? _WideBody(
                  creator: creator, tips: _tips, jars: _jars,
                  publicPosts: _publicPosts, unlockedPosts: _unlockedPosts,
                  tiers: _tiers, milestones: _milestones,
                  commissionSlot: _commissionSlot,
                  onTipSent: _load, onUnlocked: _onUnlocked,
                )
              : _NarrowBody(
                  creator: creator, tips: _tips, jars: _jars,
                  publicPosts: _publicPosts, unlockedPosts: _unlockedPosts,
                  tiers: _tiers, milestones: _milestones,
                  commissionSlot: _commissionSlot,
                  onTipSent: _load, onUnlocked: _onUnlocked,
                ),
        ),
      ]),
    );
  }

  Widget _splash() => const Scaffold(
    backgroundColor: _bgSage,
    body: Center(child: CircularProgressIndicator(color: _green)),
  );

  Widget _error() => Scaffold(
    backgroundColor: _bgSage,
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.sentiment_dissatisfied_rounded, color: Color(0xFF6B7280), size: 48),
      const SizedBox(height: 16),
      Text('Creator not found', style: GoogleFonts.dmSans(
          color: const Color(0xFF111827), fontWeight: FontWeight.w700, fontSize: 18)),
      const SizedBox(height: 8),
      Text('Check the link and try again.',
          style: GoogleFonts.dmSans(color: const Color(0xFF6B7280), fontSize: 14)),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () => context.go('/'),
        style: ElevatedButton.styleFrom(backgroundColor: kPrimary,
            foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
        child: Text('Go home', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    ])),
  );
}

// ─── Mini navigation bar ─────────────────────────────────────────────────────
class _MiniNav extends StatelessWidget {
  final String creatorName;
  const _MiniNav({required this.creatorName});

  @override
  Widget build(BuildContext context) => Container(
    height: 56,
    color: _bgWhite,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    decoration: const BoxDecoration(
      color: _bgWhite,
      border: Border(bottom: BorderSide(color: _border)),
    ),
    child: Row(children: [
      GestureDetector(
        onTap: () => context.go('/'),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const AppLogoIcon(size: 26),
          const SizedBox(width: 8),
          Text('TippingJar', style: GoogleFonts.dmSans(
              color: _ink, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
      ),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: _green.withOpacity(0.07),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: _green.withOpacity(0.20)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.bolt_rounded, color: _greenMid, size: 13),
          const SizedBox(width: 4),
          Text('Powered by TippingJar',
              style: GoogleFonts.dmSans(color: _greenMid, fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
      ),
    ]),
  );
}

// ─── Wide: split layout ───────────────────────────────────────────────────────
class _WideBody extends StatelessWidget {
  final Creator creator;
  final List<Tip> tips;
  final List<JarModel> jars;
  final List<CreatorPostModel> publicPosts;
  final List<CreatorPostModel>? unlockedPosts;
  final List<TierModel> tiers;
  final List<MilestoneModel> milestones;
  final CommissionSlotModel? commissionSlot;
  final VoidCallback onTipSent;
  final void Function(List<CreatorPostModel>) onUnlocked;
  const _WideBody({
    required this.creator,
    required this.tips,
    required this.jars,
    required this.publicPosts,
    required this.unlockedPosts,
    required this.tiers,
    required this.milestones,
    this.commissionSlot,
    required this.onTipSent,
    required this.onUnlocked,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Left: hero banner + profile + content (sage tinted)
      Expanded(
        flex: 1,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _HeroBanner(creator: creator),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (creator.tipGoal != null) ...[
                  _GoalBar(tipGoal: creator.tipGoal!, totalTips: creator.totalTips),
                  const SizedBox(height: 24),
                ],
                if (jars.isNotEmpty) ...[
                  _JarsSection(jars: jars, creatorSlug: creator.slug),
                  const SizedBox(height: 32),
                ],
                if (tiers.isNotEmpty) ...[
                  _TiersSection(tiers: tiers, creatorSlug: creator.slug, creatorName: creator.displayName),
                  const SizedBox(height: 32),
                ],
                if (milestones.isNotEmpty) ...[
                  _MilestonesSection(milestones: milestones),
                  const SizedBox(height: 32),
                ],
                _LiveStreamBanner(creatorSlug: creator.slug, creator: creator),
                if (publicPosts.isNotEmpty) ...[
                  _ContentSection(
                    creatorSlug: creator.slug,
                    publicPosts: publicPosts,
                    unlockedPosts: unlockedPosts,
                    onUnlocked: onUnlocked,
                  ),
                  const SizedBox(height: 32),
                ],
                if (commissionSlot != null && commissionSlot!.isOpen) ...[
                  _CommissionsSection(slot: commissionSlot!, creatorSlug: creator.slug, creatorName: creator.displayName),
                  const SizedBox(height: 32),
                ],
                _TipFeed(tips: tips),
              ]),
            ),
          ]),
        ),
      ),
      // Divider
      Container(width: 1, color: _border),
      // Right: tip form on white panel
      Expanded(
        flex: 1,
        child: Container(
          color: _bgWhite,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(36, 36, 36, 36),
            child: _TipForm(creator: creator, onTipSent: onTipSent),
          ),
        ),
      ),
    ],
  );
}

// ─── Narrow: stacked layout ───────────────────────────────────────────────────
class _NarrowBody extends StatelessWidget {
  final Creator creator;
  final List<Tip> tips;
  final List<JarModel> jars;
  final List<CreatorPostModel> publicPosts;
  final List<CreatorPostModel>? unlockedPosts;
  final List<TierModel> tiers;
  final List<MilestoneModel> milestones;
  final CommissionSlotModel? commissionSlot;
  final VoidCallback onTipSent;
  final void Function(List<CreatorPostModel>) onUnlocked;
  const _NarrowBody({
    required this.creator,
    required this.tips,
    required this.jars,
    required this.publicPosts,
    required this.unlockedPosts,
    required this.tiers,
    required this.milestones,
    this.commissionSlot,
    required this.onTipSent,
    required this.onUnlocked,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _HeroBanner(creator: creator),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (creator.tipGoal != null) ...[
            _GoalBar(tipGoal: creator.tipGoal!, totalTips: creator.totalTips),
            const SizedBox(height: 20),
          ],
          if (jars.isNotEmpty) ...[
            _JarsSection(jars: jars, creatorSlug: creator.slug),
            const SizedBox(height: 24),
          ],
          if (tiers.isNotEmpty) ...[
            _TiersSection(tiers: tiers, creatorSlug: creator.slug, creatorName: creator.displayName),
            const SizedBox(height: 24),
          ],
          if (milestones.isNotEmpty) ...[
            _MilestonesSection(milestones: milestones),
            const SizedBox(height: 24),
          ],
          _LiveStreamBanner(creatorSlug: creator.slug, creator: creator),
          if (publicPosts.isNotEmpty) ...[
            _ContentSection(
              creatorSlug: creator.slug,
              publicPosts: publicPosts,
              unlockedPosts: unlockedPosts,
              onUnlocked: onUnlocked,
            ),
            const SizedBox(height: 24),
          ],
          if (commissionSlot != null && commissionSlot!.isOpen) ...[
            _CommissionsSection(slot: commissionSlot!, creatorSlug: creator.slug, creatorName: creator.displayName),
            const SizedBox(height: 24),
          ],
          _TipForm(creator: creator, onTipSent: onTipSent),
          const SizedBox(height: 32),
          _TipFeed(tips: tips),
        ]),
      ),
    ]),
  );
}

// ─── Hero banner ──────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final Creator creator;
  const _HeroBanner({required this.creator});

  Color get _accent {
    const colors = [kPrimary, Color(0xFF60A5FA), Color(0xFFF472B6),
        Color(0xFFFBBF24), Color(0xFF818CF8)];
    return colors[creator.slug.length % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    final hasCover = creator.coverImage != null && creator.coverImage!.isNotEmpty;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Cover image / gradient strip ─────────────────────────────────────
      SizedBox(
        height: 260,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Background — Positioned.fill forces explicit 0/0/0/0 CSS in HTML renderer
            Positioned.fill(
              child: hasCover
                  ? Image.network(
                      creator.coverImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => CustomPaint(
                        painter: _DefaultBannerPainter(
                            accent: accent,
                            initial: creator.displayName.isNotEmpty ? creator.displayName[0].toUpperCase() : '?'),
                        child: const SizedBox.expand(),
                      ),
                    )
                  : CustomPaint(
                      painter: _DefaultBannerPainter(
                          accent: accent,
                          initial: creator.displayName.isNotEmpty ? creator.displayName[0].toUpperCase() : '?'),
                      child: const SizedBox.expand(),
                    ),
            ),
            // Gradient overlay (always, so text is legible if image is bright)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.15),
                      Colors.black.withOpacity(0.55),
                    ],
                  ),
                ),
              ),
            ),
            // Avatar overlapping the bottom edge
            Positioned(
              left: 24,
              bottom: -36,
              child: Container(
              width: 92, height: 92,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12)],
              ),
              child: Center(
                child: creator.avatar != null && creator.avatar!.isNotEmpty
                    ? ClipOval(child: Image.network(creator.avatar!, fit: BoxFit.cover, width: 92, height: 92))
                    : Text(
                        creator.displayName.isNotEmpty ? creator.displayName[0].toUpperCase() : '?',
                        style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w900, fontSize: 38),
                      ),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          ),
        ],
      ),
      ),

      // ── Info below banner ─────────────────────────────────────────────────
      const SizedBox(height: 48), // space for avatar overlap
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(creator.displayName, style: GoogleFonts.dmSans(
              color: _ink, fontWeight: FontWeight.w800,
              fontSize: 26, letterSpacing: -0.6))
              .animate().fadeIn(delay: 80.ms, duration: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 2),
          Text('@${creator.slug}', style: GoogleFonts.dmSans(
              color: _inkMuted, fontSize: 13))
              .animate().fadeIn(delay: 120.ms, duration: 400.ms),
          if (creator.tagline.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(creator.tagline, style: GoogleFonts.dmSans(
                color: _inkBody, fontSize: 14, height: 1.5))
                .animate().fadeIn(delay: 160.ms, duration: 400.ms),
          ],
          const SizedBox(height: 16),
          Row(children: [
            _StatPill(
              icon: Icons.volunteer_activism_rounded,
              label: _tipTier(creator.totalTips),
              sub: 'tipped to ${creator.displayName}',
            ),
          ]).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 8),
        ]),
      ),
    ]);
  }

}

// ─── Default banner painter ────────────────────────────────────────────────────
class _DefaultBannerPainter extends CustomPainter {
  final Color accent;
  final String initial;
  const _DefaultBannerPainter({required this.accent, required this.initial});

  @override
  void paint(Canvas canvas, Size size) {
    // Rich gradient base
    final grad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(accent, Colors.black, 0.55)!,
        Color.lerp(accent, Colors.black, 0.30)!,
        Color.lerp(accent, Colors.white, 0.10)!,
      ],
      stops: const [0.0, 0.55, 1.0],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = grad.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Decorative circles (abstract depth)
    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.25), size.height * 1.1, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 1.1), size.height * 0.7, circlePaint);

    // Subtle ring
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.25), size.height * 0.75, ringPaint);

    // Dot grid (top-right quadrant)
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    const spacing = 22.0;
    for (double x = size.width * 0.5; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height * 0.6; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }

    // Large watermark initial (faint)
    final tp = TextPainter(
      text: TextSpan(
        text: initial,
        style: TextStyle(
          color: Colors.white.withOpacity(0.06),
          fontSize: size.height * 1.4,
          fontWeight: FontWeight.w900,
          letterSpacing: -8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width * 0.38, -size.height * 0.35));

    // Thin horizontal accent line near bottom
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 3, size.width * 0.35, 3),
      Paint()..color = accent.withOpacity(0.6),
    );
  }

  @override
  bool shouldRepaint(covariant _DefaultBannerPainter old) =>
      old.accent != accent || old.initial != initial;
}

// ─── Tip tier label helper ─────────────────────────────────────────────────────
String _tipTier(double amount) {
  if (amount <= 0)        return 'R0';
  if (amount < 10)        return 'R1+';
  if (amount < 50)        return 'R10+';
  if (amount < 100)       return 'R50+';
  if (amount < 500)       return 'R100+';
  if (amount < 1000)      return 'R500+';
  if (amount < 2500)      return 'R1k+';
  if (amount < 5000)      return 'R2.5k+';
  if (amount < 10000)     return 'R5k+';
  if (amount < 20000)     return 'R10k+';
  if (amount < 80000)     return 'R20k+';
  if (amount < 200000)    return 'R80k+';
  if (amount < 500000)    return 'R200k+';
  if (amount < 1000000)   return 'R500k+';
  if (amount < 2000000)   return 'R1M+';
  if (amount < 20000000)  return 'R2M+';
  return 'R20M+';
}

// ─── Name masking helper ────────────────────────────────────────────────────────
String _maskName(String name) {
  if (name.isEmpty) return 'A***';
  final visible = (name.length - 3).clamp(1, name.length);
  return name.substring(0, visible) + '***'.substring(0, name.length - visible < 3 ? name.length - visible : 3);
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  const _StatPill({required this.icon, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: _bgSage, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _border),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: _green, size: 16),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.dmSans(
            color: _ink, fontWeight: FontWeight.w800, fontSize: 15)),
        Text(sub, style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 11)),
      ]),
    ]),
  );
}

// ─── Monthly goal progress bar ────────────────────────────────────────────────
class _GoalBar extends StatelessWidget {
  final double tipGoal, totalTips;
  const _GoalBar({required this.tipGoal, required this.totalTips});

  @override
  Widget build(BuildContext context) {
    final progress = (totalTips / tipGoal).clamp(0.0, 1.0);
    final pct = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgWhite, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Monthly goal', style: GoogleFonts.dmSans(
              color: _inkMuted, fontWeight: FontWeight.w600, fontSize: 12)),
          const Spacer(),
          Text('$pct%', style: GoogleFonts.dmSans(
              color: _green, fontWeight: FontWeight.w700, fontSize: 12)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress, minHeight: 6,
            backgroundColor: _border,
            valueColor: const AlwaysStoppedAnimation<Color>(_green),
          ),
        ),
        const SizedBox(height: 6),
        Text('R${totalTips.toStringAsFixed(0)} of R${tipGoal.toStringAsFixed(0)}',
            style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 12)),
      ]),
    ).animate().fadeIn(delay: 240.ms, duration: 400.ms);
  }
}

// ─── Public tip feed ──────────────────────────────────────────────────────────
class _TipFeed extends StatelessWidget {
  final List<Tip> tips;
  const _TipFeed({required this.tips});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Recent supporters', style: GoogleFonts.dmSans(
          color: _ink, fontWeight: FontWeight.w700, fontSize: 15)),
      const SizedBox(height: 12),
      if (tips.isEmpty)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28),
          alignment: Alignment.center,
          child: Column(children: [
            const Icon(Icons.favorite_border_rounded, color: _inkMuted, size: 32),
            const SizedBox(height: 10),
            Text('No tips yet — be the first!',
                style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 14)),
          ]),
        )
      else
        ...tips.take(5).toList().asMap().entries.map((e) => _PublicTipRow(tip: e.value, index: e.key)),
    ]);
  }
}

class _PublicTipRow extends StatelessWidget {
  final Tip tip;
  final int index;
  const _PublicTipRow({required this.tip, required this.index});

  Color get _color {
    final cols = [kPrimary, const Color(0xFF60A5FA), const Color(0xFFF472B6),
        const Color(0xFFFBBF24), const Color(0xFF818CF8)];
    return cols[tip.tipperName.length % cols.length];
  }

  String get _relative {
    final diff = DateTime.now().toUtc().difference(tip.createdAt.toUtc());
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _bgWhite, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _border),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Center(child: Text(
          tip.tipperName.isNotEmpty ? tip.tipperName[0].toUpperCase() : 'A',
          style: GoogleFonts.dmSans(color: _color, fontWeight: FontWeight.w800, fontSize: 14),
        )),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(_maskName(tip.tipperName), style: GoogleFonts.dmSans(
              color: _ink, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(width: 6),
          Text(_relative, style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 11)),
          const Spacer(),
          Text('R${tip.amount.toStringAsFixed(2)}', style: GoogleFonts.dmSans(
              color: _green, fontWeight: FontWeight.w800, fontSize: 13)),
        ]),
        if (tip.message.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(tip.message, style: GoogleFonts.dmSans(
              color: _inkBody, fontSize: 12, height: 1.45),
              maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ])),
    ]),
  ).animate().fadeIn(delay: Duration(milliseconds: 40 * index), duration: 300.ms);
}

// ─── Tip form ─────────────────────────────────────────────────────────────────
class _TipForm extends StatefulWidget {
  final Creator creator;
  final VoidCallback onTipSent;
  const _TipForm({required this.creator, required this.onTipSent});
  @override
  State<_TipForm> createState() => _TipFormState();
}

class _TipFormState extends State<_TipForm> {
  static const _presets = [5.0, 10.0, 20.0, 50.0, 100.0, 200.0];
  static const _platformFeePct = 3.0;
  static const _serviceFeePct  = 3.0;

  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _customCtrl  = TextEditingController();
  final _formKey     = GlobalKey<FormState>();

  double _amount = 20.0;
  double? _customAmount;
  bool _submitting   = false;
  bool _success      = false;
  // Paystack payment in progress — waiting for user to complete in browser
  bool _awaitingPayment = false;
  String? _paystackReference;
  bool _verifying    = false;
  String? _error;
  String _sentTo     = '';
  Timer? _pollTimer;

  bool get _usingCustom => _customAmount != null;
  double get _finalAmount => _usingCustom ? (_customAmount ?? _amount) : _amount;

  double get _platformFee => double.parse(
      (_finalAmount * _platformFeePct / 100).toStringAsFixed(2));
  double get _serviceFee => double.parse(
      (_finalAmount * _serviceFeePct / 100).toStringAsFixed(2));
  double get _creatorNet => double.parse(
      (_finalAmount - _platformFee - _serviceFee).toStringAsFixed(2));

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _messageCtrl.dispose();
    _customCtrl.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: 500.ms,
      child: _success
          ? _successState()
          : _awaitingPayment
              ? _awaitingState()
              : _formState(),
    );
  }

  // ── Awaiting Paystack payment ──────────────────────────────────────
  Widget _awaitingState() => Container(
    key: const ValueKey('awaiting'),
    padding: const EdgeInsets.all(36),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(24),
      border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
    ),
    child: Column(children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: kPrimary.withValues(alpha: 0.10), shape: BoxShape.circle),
        child: const Icon(Icons.open_in_browser_rounded, color: kPrimary, size: 32),
      ).animate().scale(duration: 400.ms),
      const SizedBox(height: 20),
      Text('Complete your payment', style: GoogleFonts.dmSans(
          color: const Color(0xFF111827), fontWeight: FontWeight.w800,
          fontSize: 22, letterSpacing: -0.4))
          .animate().fadeIn(delay: 100.ms),
      const SizedBox(height: 8),
      Text(
        'A Paystack payment page opened in your browser.\nFinish the payment there and come back.',
        style: GoogleFonts.dmSans(color: const Color(0xFF6B7280), fontSize: 14, height: 1.55),
        textAlign: TextAlign.center,
      ).animate().fadeIn(delay: 150.ms),
      const SizedBox(height: 12),
      // Fee summary
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(children: [
          _FeeRow('Tip amount', 'R${_finalAmount.toStringAsFixed(2)}', const Color(0xFF111827)),
          const SizedBox(height: 4),
          _FeeRow('Platform fee (${_platformFeePct.toInt()}%)', '- R${_platformFee.toStringAsFixed(2)}', const Color(0xFF6B7280)),
          _FeeRow('Service fee (${_serviceFeePct.toInt()}%)', '- R${_serviceFee.toStringAsFixed(2)}', const Color(0xFF6B7280)),
          const Divider(color: Color(0xFFE5E7EB), height: 12),
          _FeeRow('Creator receives', 'R${_creatorNet.toStringAsFixed(2)}', kPrimary, bold: true),
        ]),
      ).animate().fadeIn(delay: 200.ms),
      const SizedBox(height: 28),
      if (_verifying)
        const CircularProgressIndicator(color: kPrimary, strokeWidth: 2)
      else ...[
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _checkPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
            ),
            child: Text("I've paid — confirm", style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
          ),
        ).animate().fadeIn(delay: 250.ms),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _cancelPayment,
          child: Text('Cancel', style: GoogleFonts.dmSans(color: const Color(0xFF6B7280), fontSize: 13)),
        ).animate().fadeIn(delay: 300.ms),
      ],
    ]),
  );

  // ── Success ───────────────────────────────────────────────────────
  Widget _successState() => Container(
    key: const ValueKey('success'),
    padding: const EdgeInsets.all(36),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(24),
      border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
    ),
    child: Column(children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: kPrimary.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: const Icon(Icons.favorite_rounded, color: kPrimary, size: 34),
      ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
      const SizedBox(height: 20),
      Text('Tip sent! 🎉', style: GoogleFonts.dmSans(
          color: const Color(0xFF111827), fontWeight: FontWeight.w800,
          fontSize: 26, letterSpacing: -0.5))
          .animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),
      const SizedBox(height: 8),
      Text(
        'You sent R${_finalAmount.toStringAsFixed(2)} to $_sentTo',
        style: GoogleFonts.dmSans(color: const Color(0xFF6B7280), fontSize: 15, height: 1.5),
        textAlign: TextAlign.center,
      ).animate().fadeIn(delay: 200.ms),
      const SizedBox(height: 6),
      Text(
        '${_nameCtrl.text.trim().isEmpty ? 'You' : _nameCtrl.text.trim()} just made someone\'s day.',
        style: GoogleFonts.dmSans(color: const Color(0xFF6B7280), fontSize: 13),
        textAlign: TextAlign.center,
      ).animate().fadeIn(delay: 250.ms),
      const SizedBox(height: 32),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _reset,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
          ),
          child: Text('Send another tip', style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
        ),
      ).animate().fadeIn(delay: 300.ms),
      const SizedBox(height: 12),
      TextButton(
        onPressed: () => context.go('/'),
        child: Text('Back to home', style: GoogleFonts.dmSans(
            color: const Color(0xFF6B7280), fontSize: 14, fontWeight: FontWeight.w500)),
      ).animate().fadeIn(delay: 350.ms),
    ]),
  );

  // ── Form ──────────────────────────────────────────────────────────
  static const _inputFill   = _bgSage;
  static const _labelColor  = _ink;
  static const _hintColor   = _inkMuted;
  static const _inputBorder = _border;

  Widget _formState() => Container(
    key: const ValueKey('form'),
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: _bgWhite,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _border),
      boxShadow: [BoxShadow(
          color: _green.withOpacity(0.06),
          blurRadius: 20, offset: const Offset(0, 4))],
    ),
    child: Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header — creator identity row
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _green.withOpacity(0.10),
              shape: BoxShape.circle,
              border: Border.all(color: _border, width: 1.5),
            ),
            child: Center(
              child: widget.creator.avatar != null && widget.creator.avatar!.isNotEmpty
                  ? ClipOval(child: Image.network(widget.creator.avatar!, fit: BoxFit.cover, width: 44, height: 44))
                  : Text(
                      widget.creator.displayName.isNotEmpty ? widget.creator.displayName[0].toUpperCase() : 'T',
                      style: GoogleFonts.dmSans(color: _green, fontWeight: FontWeight.w800, fontSize: 18),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Supporting', style: GoogleFonts.dmSans(color: _hintColor, fontSize: 11, fontWeight: FontWeight.w500)),
            Text(widget.creator.displayName, style: GoogleFonts.dmSans(
                color: _labelColor, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3)),
          ])),
          // Live amount badge
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(36),
            ),
            child: Text(
              'R${_finalAmount.toStringAsFixed(0)}',
              style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5),
            ),
          ),
        ]).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 20),
        Container(height: 1, color: _border),
        const SizedBox(height: 20),

        // Amount presets
        _AmountGrid(
          presets: _presets,
          selected: _usingCustom ? null : _amount,
          onSelect: (v) => setState(() {
            _amount = v;
            _customAmount = null;
            _customCtrl.clear();
          }),
        ),
        const SizedBox(height: 12),

        // Custom amount
        TextFormField(
          controller: _customCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
          style: GoogleFonts.dmSans(color: _labelColor, fontSize: 14),
          onChanged: (v) {
            final parsed = double.tryParse(v);
            setState(() => _customAmount = parsed);
          },
          decoration: InputDecoration(
            hintText: 'Custom amount',
            hintStyle: GoogleFonts.dmSans(color: _hintColor, fontSize: 14),
            prefixText: 'R ',
            prefixStyle: GoogleFonts.dmSans(color: _hintColor, fontSize: 14),
            filled: true, fillColor: _inputFill,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: _usingCustom ? kPrimary : _inputBorder,
                  width: _usingCustom ? 2 : 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 20),

        // Name
        Text('Your name (optional)', style: GoogleFonts.dmSans(
            color: _labelColor, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameCtrl,
          style: GoogleFonts.dmSans(color: _labelColor, fontSize: 14),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            if (RegExp(r'[0-9]').hasMatch(v)) return 'Name cannot contain numbers';
            return null;
          },
          decoration: InputDecoration(
            hintText: 'Anonymous',
            hintStyle: GoogleFonts.dmSans(color: _hintColor, fontSize: 14),
            prefixIcon: const Icon(Icons.person_outline_rounded, color: _hintColor, size: 18),
            filled: true, fillColor: _inputFill,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _inputBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kPrimary, width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.5))),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 14),

        // Email
        Text('Email (for receipt)', style: GoogleFonts.dmSans(
            color: _labelColor, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.dmSans(color: _labelColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'you@example.com (optional)',
            hintStyle: GoogleFonts.dmSans(color: _hintColor, fontSize: 14),
            prefixIcon: const Icon(Icons.email_outlined, color: _hintColor, size: 18),
            filled: true, fillColor: _inputFill,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _inputBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kPrimary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 14),

        // Message
        Text('Message (optional)', style: GoogleFonts.dmSans(
            color: _labelColor, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _messageCtrl,
          maxLines: 3,
          maxLength: 280,
          style: GoogleFonts.dmSans(color: _labelColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Say something nice… 👋',
            hintStyle: GoogleFonts.dmSans(color: _hintColor, fontSize: 14),
            filled: true, fillColor: _inputFill,
            counterStyle: GoogleFonts.dmSans(color: _hintColor, fontSize: 11),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _inputBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kPrimary, width: 2)),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 15),
              const SizedBox(width: 8),
              Expanded(child: Text(_error!, style: GoogleFonts.dmSans(
                  color: Colors.redAccent, fontSize: 12))),
            ]),
          ),
        ],
        const SizedBox(height: 20),

        // Submit
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _submitting || _finalAmount < 1 ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary, foregroundColor: Colors.white,
              disabledBackgroundColor: kPrimary.withValues(alpha: 0.4),
              elevation: 0, shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
            ),
            child: _submitting
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    _finalAmount < 1
                        ? 'Enter an amount (R1 minimum)'
                        : 'Send R${_finalAmount.toStringAsFixed(2)} tip  →',
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
                  ),
          ),
        ),
        const SizedBox(height: 14),

        // Security note
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.lock_outline_rounded, color: _inkMuted, size: 13),
          const SizedBox(width: 5),
          Text('Secure payments via Paystack',
              style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 12)),
        ]),
      ]),
    ),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _submitting = true; _error = null; });
    try {
      final resp = await ApiService().initiateTip(
        creatorSlug: widget.creator.slug,
        amount: _finalAmount,
        tipperName: _nameCtrl.text.trim().isEmpty ? 'Anonymous' : _nameCtrl.text.trim(),
        tipperEmail: _emailCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
      );

      _sentTo = widget.creator.displayName;

      // Dev mode: tip created immediately as completed
      if (resp['dev_mode'] == true) {
        widget.onTipSent();
        setState(() { _success = true; _submitting = false; });
        return;
      }

      // Production: open Paystack authorization URL
      final authUrl = resp['authorization_url'] as String?;
      final reference = resp['reference'] as String?;
      if (authUrl != null && authUrl.isNotEmpty) {
        final uri = Uri.parse(authUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        setState(() {
          _paystackReference = reference;
          _awaitingPayment = true;
          _submitting = false;
        });
        // Auto-poll every 5s for up to 3 minutes
        _startPolling(reference!);
      } else {
        widget.onTipSent();
        setState(() { _success = true; _submitting = false; });
      }
    } catch (e) {
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _submitting = false;
      });
    }
  }

  void _startPolling(String reference) {
    _pollTimer?.cancel();
    int polls = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (t) async {
      polls++;
      if (polls > 36 || !mounted) { t.cancel(); return; }
      try {
        final result = await ApiService().verifyTip(reference);
        final s = result['status'] as String? ?? '';
        if (s == 'completed') {
          t.cancel();
          widget.onTipSent();
          if (mounted) setState(() { _success = true; _awaitingPayment = false; });
        } else if (s == 'failed') {
          t.cancel();
          if (mounted) setState(() {
            _awaitingPayment = false;
            _error = 'Payment failed. Please try again.';
          });
        }
      } catch (_) {}
    });
  }

  Future<void> _checkPayment() async {
    if (_paystackReference == null) return;
    setState(() => _verifying = true);
    try {
      final result = await ApiService().verifyTip(_paystackReference!);
      final s = result['status'] as String? ?? '';
      if (s == 'completed') {
        _pollTimer?.cancel();
        widget.onTipSent();
        setState(() { _success = true; _awaitingPayment = false; _verifying = false; });
      } else if (s == 'failed') {
        _pollTimer?.cancel();
        setState(() { _awaitingPayment = false; _verifying = false;
            _error = 'Payment failed. Please try again.'; });
      } else {
        setState(() => _verifying = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Payment not confirmed yet. Please complete it in your browser.',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w500)),
            backgroundColor: Colors.white, behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        }
      }
    } catch (_) {
      setState(() => _verifying = false);
    }
  }

  void _cancelPayment() {
    _pollTimer?.cancel();
    setState(() { _awaitingPayment = false; _paystackReference = null; _submitting = false; });
  }

  void _reset() {
    _pollTimer?.cancel();
    _nameCtrl.clear();
    _emailCtrl.clear();
    _messageCtrl.clear();
    _customCtrl.clear();
    setState(() {
      _success = false;
      _awaitingPayment = false;
      _paystackReference = null;
      _amount = 20.0;
      _customAmount = null;
      _error = null;
    });
  }
}

// ── Fee row helper ────────────────────────────────────────────────────────────
class _FeeRow extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool bold;
  const _FeeRow(this.label, this.value, this.color, {this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: Row(children: [
      Expanded(child: Text(label, style: GoogleFonts.dmSans(
          color: color, fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400))),
      Text(value, style: GoogleFonts.dmSans(
          color: color, fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
    ]),
  );
}

// ─── Jars section (public creator page) ──────────────────────────────────────
class _JarsSection extends StatelessWidget {
  final List<JarModel> jars;
  final String creatorSlug;
  const _JarsSection({required this.jars, required this.creatorSlug});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.savings_rounded, color: _green, size: 16),
        const SizedBox(width: 8),
        Text('Active Jars',
            style: GoogleFonts.dmSans(color: _ink, fontWeight: FontWeight.w700, fontSize: 15)),
      ]),
      const SizedBox(height: 12),
      ...jars.asMap().entries.map((e) => _JarCard(jar: e.value, delay: e.key * 80)
          .animate().fadeIn(delay: (e.key * 80).ms, duration: 350.ms)),
    ]);
  }
}

class _JarCard extends StatefulWidget {
  final JarModel jar;
  final int delay;
  const _JarCard({required this.jar, required this.delay});
  @override
  State<_JarCard> createState() => _JarCardState();
}

class _JarCardState extends State<_JarCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final jar = widget.jar;
    final progress = jar.progressPct != null ? jar.progressPct! / 100 : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go('/creator/${jar.creatorSlug}/jar/${jar.slug}'),
        child: AnimatedContainer(
          duration: 180.ms,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _bgWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _hovered ? _green.withOpacity(0.40) : _border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                    color: _green.withOpacity(0.09), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.savings_rounded, color: _green, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(jar.name,
                    style: GoogleFonts.dmSans(color: _ink, fontWeight: FontWeight.w700, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
              ),
              Text('R${jar.totalRaised.toStringAsFixed(0)} raised',
                  style: GoogleFonts.dmSans(color: _green, fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
            if (jar.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(jar.description,
                  style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 12, height: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            if (progress != null) ...[
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Goal: R${jar.goal!.toStringAsFixed(0)}',
                    style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 11)),
                Text('${jar.progressPct!.toStringAsFixed(0)}%',
                    style: GoogleFonts.dmSans(color: _green, fontWeight: FontWeight.w700, fontSize: 11)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: _border,
                  valueColor: const AlwaysStoppedAnimation(_green),
                  minHeight: 5,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(children: [
              Text('${jar.tipCount} tip${jar.tipCount == 1 ? '' : 's'}',
                  style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 11)),
              const Spacer(),
              Text('Tip this jar →',
                  style: GoogleFonts.dmSans(color: _green, fontWeight: FontWeight.w600, fontSize: 12)),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ─── Live room: Jitsi embed + comments + tip panel ───────────────────────────
class _LiveStreamBanner extends StatefulWidget {
  final String creatorSlug;
  final Creator creator;
  const _LiveStreamBanner({required this.creatorSlug, required this.creator});

  @override
  State<_LiveStreamBanner> createState() => _LiveStreamBannerState();
}

class _LiveStreamBannerState extends State<_LiveStreamBanner> {
  Map<String, dynamic>? _stream;
  bool _hasTipped = false;
  bool _checkingAccess = true;
  Timer? _streamPollTimer;
  Timer? _commentPollTimer;

  final List<Map<String, dynamic>> _comments = [];
  int _lastCommentId = 0;
  final _commentCtrl = TextEditingController();
  final _scrollCtrl  = ScrollController();
  bool _joining = false;
  bool _streamEndedWhileWatching = false;
  static int _iframeCount = 0;

  @override
  void initState() {
    super.initState();
    _initAccess();
    _streamPollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkStream());
  }

  @override
  void dispose() {
    _streamPollTimer?.cancel();
    _commentPollTimer?.cancel();
    _commentCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _initAccess() async {
    final auth = context.read<AuthProvider>();
    // Check tip access for authenticated users
    if (auth.isAuthenticated) {
      try {
        final tipped = await ApiService(authToken: auth.accessToken)
            .hasTipped(widget.creatorSlug);
        if (mounted) setState(() => _hasTipped = tipped);
      } catch (_) {}
    }
    if (mounted) setState(() => _checkingAccess = false);
    await _checkStream();
  }

  Future<void> _checkStream() async {
    try {
      final s = await ApiService().getActiveLiveStream(widget.creatorSlug);
      final wasLive = _stream != null;
      if (mounted) setState(() {
        // If fan was watching and stream just ended, show the ended overlay
        if (wasLive && s == null && _joining) {
          _streamEndedWhileWatching = true;
          _joining = false;
        }
        _stream = s;
        // Reset "ended" state when a new stream starts
        if (s != null && _streamEndedWhileWatching) _streamEndedWhileWatching = false;
      });
      if (!wasLive && s != null) _startCommentPoll();
      if (wasLive && s == null) _commentPollTimer?.cancel();
    } catch (_) {}
  }

  void _startCommentPoll() {
    _commentPollTimer?.cancel();
    _commentPollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollComments());
    _pollComments();
  }

  Future<void> _pollComments() async {
    try {
      final fresh = await ApiService().getLiveComments(
        widget.creatorSlug, since: _lastCommentId,
      );
      if (fresh.isEmpty || !mounted) return;
      setState(() {
        _comments.addAll(fresh);
        _lastCommentId = fresh.last['id'] as int;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {}
  }

  Future<void> _sendComment() async {
    final msg  = _commentCtrl.text.trim();
    if (msg.isEmpty) return;
    final auth = context.read<AuthProvider>();
    final name = auth.user?.username ?? 'Guest';
    _commentCtrl.clear();
    try {
      await ApiService().postLiveComment(widget.creatorSlug, name, msg);
    } catch (_) {}
  }

  Future<void> _joinStream(String roomName) async {
    // Show disclaimer first
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: _green.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.lock_rounded, color: _green, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('Before you join', style: GoogleFonts.dmSans(
              color: _ink, fontWeight: FontWeight.w800, fontSize: 16))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _disclaimerRow(Icons.lock_outline_rounded, 'End-to-end encrypted',
              'This stream is private and encrypted. We cannot view or access this chat.'),
          const SizedBox(height: 14),
          _disclaimerRow(Icons.visibility_off_rounded, 'Observer only',
              'You will watch and listen only. Audio and video sharing are disabled for viewers.'),
          const SizedBox(height: 14),
          _disclaimerRow(Icons.block_rounded, 'No explicit content',
              'Do not share or request explicit content. Violations may result in account suspension.'),
          const SizedBox(height: 14),
          _disclaimerRow(Icons.gavel_rounded, 'Terms of use',
              'By joining you confirm you have read and accept the Tipping Jar Terms of Use.'),
        ]),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green, foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('I understand, join stream',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;

    final auth = context.read<AuthProvider>();
    // Jitsi URL parser JSON.parses every value — strings must be JSON-quoted
    final username = auth.user?.username ?? 'Guest';
    final displayName = Uri.encodeComponent('"$username"');
    _iframeCount++;
    final viewId = 'jitsi-fan-$_iframeCount';
    // Observer-only: no audio/video, disable prejoin
    final src = 'https://meet.tippingjar.co.za/$roomName'
        '#config.prejoinConfig.enabled=false'
        '&config.prejoinPageEnabled=false'
        '&config.startWithAudioMuted=true'
        '&config.startWithVideoMuted=true'
        '&config.startSilent=true'
        '&config.disableAudioLevels=true'
        '&config.enableNoisyMicDetection=false'
        '&config.toolbarButtons=["fullscreen","tileview","hangup"]'
        '&userInfo.displayName=$displayName';
    ui_web.platformViewRegistry.registerViewFactory(viewId, (_) {
      final iframe = html.IFrameElement()
        ..src = src
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'fullscreen; autoplay';
      return iframe;
    });
    setState(() => _joining = true);
  }

  Widget _disclaimerRow(IconData icon, String title, String body) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: _green.withValues(alpha: 0.08), shape: BoxShape.circle),
        child: Icon(icon, color: _green, size: 14),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.dmSans(color: _ink, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 2),
        Text(body, style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 12, height: 1.4)),
      ])),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAccess) return const SizedBox.shrink();
    // Keep banner visible when stream ended while fan was watching
    if (_stream == null && !_streamEndedWhileWatching) return const SizedBox.shrink();

    final title    = _stream?['title'] as String? ?? 'Live Stream';
    final roomName = _stream?['room_name'] as String? ?? '';
    final wide     = MediaQuery.of(context).size.width > 800;
    final auth     = context.watch<AuthProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        // ── Header bar ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.04),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(bottom: BorderSide(color: Colors.red.withValues(alpha: 0.15))),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _streamEndedWhileWatching ? Colors.grey : Colors.red,
                borderRadius: BorderRadius.circular(36),
              ),
              child: Text(_streamEndedWhileWatching ? '■ ENDED' : '● LIVE',
                  style: GoogleFonts.dmSans(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: GoogleFonts.dmSans(
                color: _ink, fontWeight: FontWeight.w700, fontSize: 14),
                overflow: TextOverflow.ellipsis)),
            if (_streamEndedWhileWatching)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                child: Text('Ended', style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
              )
            else if (auth.isAuthenticated && auth.user != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(auth.user!.username,
                    style: GoogleFonts.dmSans(color: _green, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
          ]),
        ),

        // ── Access gate or live room ─────────────────────────────────────
        if (_streamEndedWhileWatching)
          _videoSection(roomName)  // show "stream ended" full width
        else if (!_hasTipped)
          _tipGate(auth)
        else
          SizedBox(
            height: wide ? 520 : 640,
            child: wide
                ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Expanded(flex: 3, child: _videoSection(roomName)),
                    Container(width: 1, color: Colors.red.withValues(alpha: 0.12)),
                    SizedBox(width: 320, child: _sidePanel()),
                  ])
                : Column(children: [
                    SizedBox(height: 280, child: _videoSection(roomName)),
                    Expanded(child: _sidePanel()),
                  ]),
          ),
      ]),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ── Tip gate: shown to users who haven't tipped ──────────────────────────
  Widget _tipGate(AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(color: _green.withValues(alpha: 0.08), shape: BoxShape.circle),
          child: const Icon(Icons.lock_rounded, color: _green, size: 28),
        ),
        const SizedBox(height: 16),
        Text('Tip to watch live',
            style: GoogleFonts.dmSans(color: _ink, fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 8),
        Text(
          'Only supporters who\'ve tipped ${widget.creator.displayName} can join the live stream.',
          style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 13, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            Scrollable.ensureVisible(context,
                duration: const Duration(milliseconds: 400), curve: Curves.easeOut,
                alignment: 1.0);
          },
          icon: const Icon(Icons.favorite_rounded, size: 16),
          label: Text('Tip ${widget.creator.displayName}',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _green, foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
          ),
        ),
        if (!auth.isAuthenticated) ...[
          const SizedBox(height: 12),
          Text('Already tipped? Log in to your account.',
              style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 12)),
        ],
      ]),
    );
  }

  Widget _videoSection(String roomName) {
    // Stream ended while the fan was watching
    if (_streamEndedWhileWatching) {
      return Container(
        color: const Color(0xFF0A0F0B),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: const Icon(Icons.stop_circle_outlined, color: Colors.white54, size: 32),
          ),
          const SizedBox(height: 16),
          Text('Stream has ended', style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 6),
          Text('The creator has ended this live session.',
              style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 13)),
        ])),
      );
    }
    if (!_joining) {
      return Container(
        color: const Color(0xFF0A0F0B),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.videocam_rounded, color: Colors.red, size: 32),
          ),
          const SizedBox(height: 16),
          Text('Tap to join the live stream',
              style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _joinStream(roomName),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text('Join Stream',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
            ),
          ),
        ])),
      );
    }
    return ClipRRect(
      child: HtmlElementView(viewType: 'jitsi-fan-$_iframeCount'),
    );
  }

  Widget _sidePanel() {
    return Column(children: [
      // Comment feed
      Expanded(
        child: _comments.isEmpty
            ? Center(child: Text('No comments yet.\nBe the first!',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 13, height: 1.5)))
            : ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                itemCount: _comments.length,
                itemBuilder: (_, i) {
                  final c = _comments[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.12), shape: BoxShape.circle),
                        child: Center(child: Text(
                          (c['username'] as String).isNotEmpty
                              ? (c['username'] as String)[0].toUpperCase() : '?',
                          style: GoogleFonts.dmSans(
                              color: _green, fontWeight: FontWeight.w700, fontSize: 12),
                        )),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c['username'] as String,
                            style: GoogleFonts.dmSans(
                                color: _green, fontWeight: FontWeight.w700, fontSize: 11)),
                        Text(c['message'] as String,
                            style: GoogleFonts.dmSans(color: _ink, fontSize: 13, height: 1.4)),
                      ])),
                    ]),
                  );
                },
              ),
      ),

      // Tip button
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Scrollable.ensureVisible(context,
                  duration: const Duration(milliseconds: 400), curve: Curves.easeOut,
                  alignment: 1.0);
            },
            icon: const Icon(Icons.favorite_rounded, size: 16),
            label: Text('Tip ${widget.creator.displayName}',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green, foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),

      // Divider + comment input (no name field — uses logged-in username)
      Container(height: 1, color: _border),
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _commentCtrl,
              style: GoogleFonts.dmSans(fontSize: 13, color: _ink),
              onSubmitted: (_) => _sendComment(),
              decoration: InputDecoration(
                hintText: 'Say something...',
                hintStyle: GoogleFonts.dmSans(fontSize: 13, color: _inkMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                isDense: true,
                filled: true, fillColor: _bgSage,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _green, width: 1.5)),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _sendComment,
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ]),
      ),
    ]);
  }
}

// ─── Exclusive content section ────────────────────────────────────────────────
class _ContentSection extends StatelessWidget {
  final String creatorSlug;
  final List<CreatorPostModel> publicPosts;
  final List<CreatorPostModel>? unlockedPosts;
  final void Function(List<CreatorPostModel>) onUnlocked;

  const _ContentSection({
    required this.creatorSlug,
    required this.publicPosts,
    required this.unlockedPosts,
    required this.onUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = unlockedPosts != null;
    final posts = isUnlocked ? unlockedPosts! : publicPosts;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Row(children: [
        const Icon(Icons.lock_rounded, color: kPrimary, size: 16),
        const SizedBox(width: 8),
        Text('Exclusive Content',
            style: GoogleFonts.dmSans(
                color: const Color(0xFF111827), fontWeight: FontWeight.w700, fontSize: 15)),
        const Spacer(),
        if (!isUnlocked)
          GestureDetector(
            onTap: () => _showUnlockDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: kPrimary.withValues(alpha: 0.4)),
              ),
              child: Text('Unlock with email',
                  style: GoogleFonts.dmSans(
                      color: kPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          ),
      ]),
      const SizedBox(height: 12),

      // Post cards
      ...posts.asMap().entries.map((e) {
        if (isUnlocked) {
          return _UnlockedPostCard(post: e.value)
              .animate()
              .fadeIn(delay: (e.key * 60).ms, duration: 350.ms);
        } else {
          return _LockedPostCard(post: e.value, onUnlock: () => _showUnlockDialog(context))
              .animate()
              .fadeIn(delay: (e.key * 60).ms, duration: 350.ms);
        }
      }),
    ]);
  }

  Future<void> _showUnlockDialog(BuildContext context) async {
    final emailCtrl = TextEditingController();
    bool loading = false;
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Unlock exclusive content',
              style: GoogleFonts.dmSans(
                  color: const Color(0xFF111827), fontWeight: FontWeight.w700, fontSize: 16)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              'Enter the email you used when tipping to unlock the content.',
              style: GoogleFonts.dmSans(color: const Color(0xFF6B7280), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.dmSans(color: const Color(0xFF111827), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'you@example.com',
                hintStyle: GoogleFonts.dmSans(color: const Color(0xFF6B7280), fontSize: 14),
                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF6B7280), size: 18),
                filled: true, fillColor: const Color(0xFFF8F9FA),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kPrimary, width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error!, style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 12)),
            ],
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.dmSans(color: const Color(0xFF6B7280))),
            ),
            StatefulBuilder(
              builder: (_, setBtn) => ElevatedButton(
                onPressed: loading ? null : () async {
                  final email = emailCtrl.text.trim();
                  if (email.isEmpty) return;
                  setS(() { loading = true; error = null; });
                  try {
                    final posts = await ApiService().unlockPosts(creatorSlug, email);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      onUnlocked(posts);
                    }
                  } catch (e) {
                    setS(() {
                      loading = false;
                      error = e.toString().contains('no_tip')
                          ? 'No tip found for this email. Tip the creator first!'
                          : 'Something went wrong. Please try again.';
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary, foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
                child: loading
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Unlock', style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedPostCard extends StatelessWidget {
  final CreatorPostModel post;
  final VoidCallback onUnlock;
  const _LockedPostCard({required this.post, required this.onUnlock});

  // Fake placeholder rows that look like real content behind the blur
  Widget _buildPlaceholderContent() {
    if (post.postType == 'image') {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          height: 90, width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.image_rounded, color: Color(0xFFD1D5DB), size: 36),
        ),
        const SizedBox(height: 10),
        _fakeTextLine(width: 0.7),
        const SizedBox(height: 6),
        _fakeTextLine(width: 0.5),
      ]);
    }
    if (post.postType == 'video') {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          height: 90, width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.play_circle_outline_rounded, color: Color(0xFFD1D5DB), size: 36),
        ),
        const SizedBox(height: 10),
        _fakeTextLine(width: 0.6),
        const SizedBox(height: 6),
        _fakeTextLine(width: 0.4),
      ]);
    }
    // text / file
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _fakeTextLine(width: 1.0),
      const SizedBox(height: 7),
      _fakeTextLine(width: 0.85),
      const SizedBox(height: 7),
      _fakeTextLine(width: 0.65),
      const SizedBox(height: 7),
      _fakeTextLine(width: 0.75),
    ]);
  }

  Widget _fakeTextLine({required double width}) => FractionallySizedBox(
    widthFactor: width,
    child: Container(
      height: 10,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onUnlock,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(children: [
        // ── Blurred placeholder content ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
          child: _buildPlaceholderContent(),
        ),

        // ── Frosted glass overlay ────────────────────────────────────────
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4.5, sigmaY: 4.5),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.55),
                    Colors.white.withValues(alpha: 0.80),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Title bar (always readable above blur) ───────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Row(children: [
            Expanded(child: Text(
              post.title,
              style: GoogleFonts.dmSans(
                  color: const Color(0xFF111827), fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            )),
            const Icon(Icons.lock_rounded, color: Color(0xFF6B7280), size: 15),
          ]),
        ),

        // ── Centre CTA ───────────────────────────────────────────────────
        Positioned(
          bottom: 14, left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: kPrimary.withValues(alpha: 0.5)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.lock_open_rounded, color: kPrimary, size: 13),
                const SizedBox(width: 6),
                Text('Tip to unlock',
                    style: GoogleFonts.dmSans(
                        color: kPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
              ]),
            ),
          ),
        ),
      ]),
    ),
  );
}

class _UnlockedPostCard extends StatelessWidget {
  final CreatorPostModel post;
  const _UnlockedPostCard({required this.post});

  IconData get _typeIcon => switch (post.postType) {
    'image' => Icons.image_rounded,
    'video' => Icons.play_circle_outline_rounded,
    'file'  => Icons.attach_file_rounded,
    _       => Icons.article_rounded,
  };

  Color get _typeColor => switch (post.postType) {
    'image' => const Color(0xFF60A5FA),
    'video' => const Color(0xFFF472B6),
    'file'  => const Color(0xFFFBBF24),
    _       => kPrimary,
  };

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(_typeIcon, color: _typeColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(post.title, style: GoogleFonts.dmSans(
            color: const Color(0xFF111827), fontWeight: FontWeight.w700, fontSize: 14),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
        const Icon(Icons.lock_open_rounded, color: kPrimary, size: 15),
      ]),

      // Body text
      if (post.body.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(post.body, style: GoogleFonts.dmSans(
            color: const Color(0xFF111827).withValues(alpha: 0.85), fontSize: 13, height: 1.55)),
      ],

      // Image
      if (post.postType == 'image' && post.mediaUrl != null) ...[
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            post.mediaUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, obj, err) => Container(
              height: 120,
              color: const Color(0xFFF8F9FA),
              child: const Center(child: Icon(Icons.broken_image_rounded, color: Color(0xFF6B7280))),
            ),
          ),
        ),
      ],

      // Video link
      if (post.postType == 'video' && post.videoUrl.isNotEmpty) ...[
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final uri = Uri.tryParse(post.videoUrl);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF472B6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF472B6).withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.play_circle_outline_rounded,
                  color: Color(0xFFF472B6), size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(post.videoUrl, style: GoogleFonts.dmSans(
                  color: const Color(0xFFF472B6), fontSize: 12),
                  overflow: TextOverflow.ellipsis)),
              const Icon(Icons.open_in_new_rounded,
                  color: Color(0xFFF472B6), size: 13),
            ]),
          ),
        ),
      ],

      // File download
      if (post.postType == 'file' && post.mediaUrl != null) ...[
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final uri = Uri.tryParse(post.mediaUrl!);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFBBF24).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.download_rounded, color: Color(0xFFFBBF24), size: 18),
              const SizedBox(width: 8),
              Text('Download file', style: GoogleFonts.dmSans(
                  color: const Color(0xFFFBBF24), fontWeight: FontWeight.w600,
                  fontSize: 13)),
            ]),
          ),
        ),
      ],
    ]),
  );
}

// ─── Amount preset grid ───────────────────────────────────────────────────────
class _AmountGrid extends StatelessWidget {
  final List<double> presets;
  final double? selected;
  final void Function(double) onSelect;
  const _AmountGrid({required this.presets, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8, runSpacing: 8,
    children: presets.map((v) {
      final active = selected == v;
      return GestureDetector(
        onTap: () => onSelect(v),
        child: AnimatedContainer(
          duration: 150.ms,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: active ? _green : _bgSage,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
                color: active ? _green : _border,
                width: 1.5),
          ),
          child: Text('R${v.toInt()}', style: GoogleFonts.dmSans(
              color: active ? Colors.white : _ink,
              fontWeight: FontWeight.w700, fontSize: 14)),
        ),
      );
    }).toList(),
  );
}

// ─── Support Tiers section ────────────────────────────────────────────────────
class _TiersSection extends StatelessWidget {
  final List<TierModel> tiers;
  final String creatorSlug;
  final String creatorName;
  const _TiersSection({required this.tiers, required this.creatorSlug, required this.creatorName});

  @override
  Widget build(BuildContext context) {
    final active = tiers.where((t) => t.isActive).toList();
    if (active.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 32),
      Text('Support Tiers', style: GoogleFonts.dmSans(
          color: _ink, fontWeight: FontWeight.w800, fontSize: 20,
          letterSpacing: -0.4)),
      const SizedBox(height: 4),
      Text('Choose a monthly support level', style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 13)),
      const SizedBox(height: 16),
      Wrap(
        spacing: 12, runSpacing: 12,
        children: active.asMap().entries.map((e) => _TierCard(
          tier: e.value,
          creatorSlug: creatorSlug,
          creatorName: creatorName,
        ).animate().fadeIn(delay: (e.key * 60).ms, duration: 350.ms)).toList(),
      ),
    ]);
  }
}

class _TierCard extends StatelessWidget {
  final TierModel tier;
  final String creatorSlug;
  final String creatorName;
  const _TierCard({required this.tier, required this.creatorSlug, required this.creatorName});

  @override
  Widget build(BuildContext context) => Container(
    width: 240,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _bgWhite,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(tier.name, style: GoogleFonts.dmSans(
          color: _ink, fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 4),
      Text('R${tier.price.toStringAsFixed(0)}/month', style: GoogleFonts.dmSans(
          color: _green, fontWeight: FontWeight.w800, fontSize: 18)),
      if (tier.description.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(tier.description, style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 12, height: 1.4)),
      ],
      if (tier.perks.isNotEmpty) ...[
        const SizedBox(height: 12),
        ...tier.perks.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            const Icon(Icons.check_circle_outline_rounded, color: _green, size: 14),
            const SizedBox(width: 6),
            Expanded(child: Text(p, style: GoogleFonts.dmSans(color: _inkBody, fontSize: 12))),
          ]),
        )),
      ],
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => _PledgeDialog(
              creatorSlug: creatorSlug,
              creatorName: creatorName,
              tier: tier,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
          ),
          child: Text('Subscribe R${tier.price.toStringAsFixed(0)}/mo',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ),
    ]),
  );
}

// ─── Pledge dialog ────────────────────────────────────────────────────────────
class _PledgeDialog extends StatefulWidget {
  final String creatorSlug;
  final String creatorName;
  final TierModel tier;
  const _PledgeDialog({required this.creatorSlug, required this.creatorName, required this.tier});

  @override
  State<_PledgeDialog> createState() => _PledgeDialogState();
}

class _PledgeDialogState extends State<_PledgeDialog> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _done = false;
  String? _error;
  String? _payUrl;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Email is required');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService().createPledge(
        creatorSlug: widget.creatorSlug,
        amount: widget.tier.price,
        tierId: widget.tier.id,
        fanEmail: email,
        fanName: name.isEmpty ? 'Anonymous' : name,
      );
      if (!mounted) return;
      if (result['authorization_url'] != null) {
        setState(() { _loading = false; _payUrl = result['authorization_url']; });
        final uri = Uri.parse(_payUrl!);
        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        setState(() { _loading = false; _done = true; });
      }
    } catch (e) {
      setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: Text(
      _done ? 'Pledge Active!' : 'Subscribe to ${widget.tier.name}',
      style: GoogleFonts.dmSans(color: const Color(0xFF111827), fontWeight: FontWeight.w700, fontSize: 16),
    ),
    content: _done
        ? Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_rounded, color: kPrimary, size: 48),
            const SizedBox(height: 12),
            Text(
              'You\'re now supporting ${widget.creatorName} with R${widget.tier.price.toStringAsFixed(0)}/month.',
              style: GoogleFonts.dmSans(color: const Color(0xFF6B7280), fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ])
        : Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              'R${widget.tier.price.toStringAsFixed(0)}/month · ${widget.tier.name}',
              style: GoogleFonts.dmSans(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              style: GoogleFonts.dmSans(color: const Color(0xFF111827), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Your name (optional)',
                hintStyle: GoogleFonts.dmSans(color: const Color(0xFF6B7280), fontSize: 14),
                prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF6B7280), size: 18),
                filled: true, fillColor: const Color(0xFFF8F9FA),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kPrimary, width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.dmSans(color: const Color(0xFF111827), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'your@email.com *',
                hintStyle: GoogleFonts.dmSans(color: const Color(0xFF6B7280), fontSize: 14),
                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF6B7280), size: 18),
                filled: true, fillColor: const Color(0xFFF8F9FA),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kPrimary, width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 12)),
            ],
          ]),
    actions: _done
        ? [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
              child: Text('Done', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
            ),
          ]
        : [
            TextButton(
              onPressed: _loading ? null : () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.dmSans(color: const Color(0xFF6B7280))),
            ),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
              child: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Subscribe', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
            ),
          ],
  );
}

// ─── Milestones section ───────────────────────────────────────────────────────
class _MilestonesSection extends StatelessWidget {
  final List<MilestoneModel> milestones;
  const _MilestonesSection({required this.milestones});

  @override
  Widget build(BuildContext context) {
    final active = milestones.where((m) => m.isActive).toList();
    if (active.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 32),
      Text('Milestones', style: GoogleFonts.dmSans(
          color: _ink, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.4)),
      const SizedBox(height: 4),
      Text('Help unlock these goals', style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 13)),
      const SizedBox(height: 16),
      ...active.asMap().entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _MilestoneCard(milestone: e.value)
            .animate().fadeIn(delay: (e.key * 60).ms, duration: 350.ms),
      )),
    ]);
  }
}

class _MilestoneCard extends StatelessWidget {
  final MilestoneModel milestone;
  const _MilestoneCard({required this.milestone});

  @override
  Widget build(BuildContext context) {
    final progress = (milestone.progressPct / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: milestone.isAchieved
            ? _green.withOpacity(0.45)
            : _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(milestone.title, style: GoogleFonts.dmSans(
              color: _ink, fontWeight: FontWeight.w700, fontSize: 15))),
          if (milestone.isAchieved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _green.withOpacity(0.35)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle_rounded, color: _green, size: 13),
                const SizedBox(width: 4),
                Text('Unlocked!', style: GoogleFonts.dmSans(
                    color: _green, fontWeight: FontWeight.w700, fontSize: 11)),
              ]),
            ),
        ]),
        if (milestone.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(milestone.description, style: GoogleFonts.dmSans(
              color: _inkMuted, fontSize: 12, height: 1.4)),
        ],
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: _border,
            valueColor: AlwaysStoppedAnimation<Color>(
                milestone.isAchieved ? _green : _green.withOpacity(0.65)),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            'R${milestone.currentMonthTotal.toStringAsFixed(0)} raised this month',
            style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 11),
          ),
          Text(
            'Goal: R${milestone.targetAmount.toStringAsFixed(0)}',
            style: GoogleFonts.dmSans(color: _inkBody, fontWeight: FontWeight.w600, fontSize: 11),
          ),
        ]),
      ]),
    );
  }
}

// ─── Commissions section ──────────────────────────────────────────────────────
class _CommissionsSection extends StatelessWidget {
  final CommissionSlotModel slot;
  final String creatorSlug;
  final String creatorName;
  const _CommissionsSection({required this.slot, required this.creatorSlug, required this.creatorName});

  @override
  Widget build(BuildContext context) {
    if (!slot.isOpen) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 32),
      Text('Commission Work', style: GoogleFonts.dmSans(
          color: _ink, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.4)),
      const SizedBox(height: 4),
      Text('Request custom work from $creatorName', style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 13)),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _bgWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.09),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _green.withOpacity(0.30)),
              ),
              child: Text('Open for commissions', style: GoogleFonts.dmSans(
                  color: _greenMid, fontWeight: FontWeight.w600, fontSize: 11)),
            ),
          ]),
          const SizedBox(height: 12),
          Text(
            'From R${slot.basePrice.toStringAsFixed(0)}',
            style: GoogleFonts.dmSans(color: _green, fontWeight: FontWeight.w800, fontSize: 22),
          ),
          if (slot.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(slot.description, style: GoogleFonts.dmSans(color: _inkBody, fontSize: 13, height: 1.5)),
          ],
          const SizedBox(height: 6),
          Text('Turnaround: ${slot.turnaroundDays} days',
              style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => _CommissionDialog(
                  creatorSlug: creatorSlug,
                  creatorName: creatorName,
                  basePrice: slot.basePrice,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
              ),
              child: Text('Request a Commission',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ]),
      ),
    ]);
  }
}

// ─── Commission request dialog ────────────────────────────────────────────────
class _CommissionDialog extends StatefulWidget {
  final String creatorSlug;
  final String creatorName;
  final double basePrice;
  const _CommissionDialog({required this.creatorSlug, required this.creatorName, required this.basePrice});

  @override
  State<_CommissionDialog> createState() => _CommissionDialogState();
}

class _CommissionDialogState extends State<_CommissionDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  bool _loading = false;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _priceCtrl.text = widget.basePrice.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    if (title.isEmpty || desc.isEmpty || email.isEmpty) {
      setState(() => _error = 'Title, description, and email are required.');
      return;
    }
    if (price < widget.basePrice) {
      setState(() => _error = 'Price must be at least R${widget.basePrice.toStringAsFixed(0)}.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService().submitCommissionRequest(widget.creatorSlug, {
        'title': title,
        'description': desc,
        'fan_name': _nameCtrl.text.trim().isEmpty ? 'Anonymous' : _nameCtrl.text.trim(),
        'fan_email': email,
        'agreed_price': price,
      });
      if (mounted) setState(() { _loading = false; _done = true; });
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.dmSans(color: const Color(0xFF6B7280), fontSize: 14),
    prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 18),
    filled: true, fillColor: const Color(0xFFF8F9FA),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: Text(
      _done ? 'Request Sent!' : 'Request a Commission',
      style: GoogleFonts.dmSans(color: const Color(0xFF111827), fontWeight: FontWeight.w700, fontSize: 16),
    ),
    content: _done
        ? Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_rounded, color: kPrimary, size: 48),
            const SizedBox(height: 12),
            Text(
              '${widget.creatorName} will review your request and get back to you.',
              style: GoogleFonts.dmSans(color: const Color(0xFF6B7280), fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ])
        : SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: _titleCtrl,
                style: GoogleFonts.dmSans(color: const Color(0xFF111827), fontSize: 14),
                decoration: _dec('Commission title *', Icons.title_rounded),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: GoogleFonts.dmSans(color: const Color(0xFF111827), fontSize: 14),
                decoration: _dec('Describe what you want *', Icons.description_outlined).copyWith(prefixIcon: null),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameCtrl,
                style: GoogleFonts.dmSans(color: const Color(0xFF111827), fontSize: 14),
                decoration: _dec('Your name (optional)', Icons.person_outline_rounded),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.dmSans(color: const Color(0xFF111827), fontSize: 14),
                decoration: _dec('Your email *', Icons.email_outlined),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.dmSans(color: const Color(0xFF111827), fontSize: 14),
                decoration: _dec('Agreed price (R) *', Icons.payments_outlined),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 12)),
              ],
            ]),
          ),
    actions: _done
        ? [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
              child: Text('Done', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
            ),
          ]
        : [
            TextButton(
              onPressed: _loading ? null : () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.dmSans(color: const Color(0xFF6B7280))),
            ),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
              child: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Send Request', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
            ),
          ],
  );
}
