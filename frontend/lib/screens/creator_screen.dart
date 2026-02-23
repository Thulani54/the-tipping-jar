import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/commission_model.dart';
import '../models/creator.dart';
import '../models/creator_post_model.dart';
import '../models/jar_model.dart';
import '../models/milestone_model.dart';
import '../models/tier_model.dart';
import '../models/tip.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';

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
      final api = ApiService();
      final results = await Future.wait([
        api.getCreator(widget.slug),
        api.getCreatorTips(widget.slug),
        api.getCreatorJars(widget.slug),
        api.getPublicPosts(widget.slug),
        api.getPublicTiers(widget.slug).catchError((_) => <TierModel>[]),
        api.getPublicMilestones(widget.slug).catchError((_) => <MilestoneModel>[]),
      ]);
      if (mounted) setState(() {
        _creator     = results[0] as Creator;
        _tips        = results[1] as List<Tip>;
        _jars        = results[2] as List<JarModel>;
        _publicPosts = results[3] as List<CreatorPostModel>;
        _tiers       = results[4] as List<TierModel>;
        _milestones  = results[5] as List<MilestoneModel>;
        _unlockedPosts = null;
        _loading = false;
      });
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
      backgroundColor: kDark,
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
    backgroundColor: kDark,
    body: Center(child: CircularProgressIndicator(color: kPrimary)),
  );

  Widget _error() => Scaffold(
    backgroundColor: kDark,
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.sentiment_dissatisfied_rounded, color: kMuted, size: 48),
      const SizedBox(height: 16),
      Text('Creator not found', style: GoogleFonts.dmSans(
          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
      const SizedBox(height: 8),
      Text('Check the link and try again.',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 14)),
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
    color: kDarker,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(children: [
      GestureDetector(
        onTap: () => context.go('/'),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const AppLogoIcon(size: 28),
          const SizedBox(width: 8),
          Text('TippingJar', style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
      ),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: kCardBg, borderRadius: BorderRadius.circular(36),
          border: Border.all(color: kBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.bolt_rounded, color: kPrimary, size: 13),
          const SizedBox(width: 4),
          Text('Powered by TippingJar',
              style: GoogleFonts.dmSans(color: kMuted, fontSize: 11, fontWeight: FontWeight.w500)),
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
      // Left: profile + jars + tiers + milestones + content + commissions + recent tips
      Expanded(
        flex: 4,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _CreatorCard(creator: creator),
            if (creator.tipGoal != null) ...[
              const SizedBox(height: 20),
              _GoalBar(tipGoal: creator.tipGoal!, totalTips: creator.totalTips),
            ],
            if (jars.isNotEmpty) ...[
              const SizedBox(height: 32),
              _JarsSection(jars: jars, creatorSlug: creator.slug),
            ],
            if (tiers.isNotEmpty) ...[
              const SizedBox(height: 32),
              _TiersSection(tiers: tiers, creatorSlug: creator.slug, creatorName: creator.displayName),
            ],
            if (milestones.isNotEmpty) ...[
              const SizedBox(height: 32),
              _MilestonesSection(milestones: milestones),
            ],
            if (publicPosts.isNotEmpty) ...[
              const SizedBox(height: 32),
              _ContentSection(
                creatorSlug: creator.slug,
                publicPosts: publicPosts,
                unlockedPosts: unlockedPosts,
                onUnlocked: onUnlocked,
              ),
            ],
            if (commissionSlot != null && commissionSlot!.isOpen) ...[
              const SizedBox(height: 32),
              _CommissionsSection(slot: commissionSlot!, creatorSlug: creator.slug, creatorName: creator.displayName),
            ],
            const SizedBox(height: 32),
            _TipFeed(tips: tips),
          ]),
        ),
      ),
      // Divider
      Container(width: 1, color: kBorder),
      // Right: tip form (sticky)
      Expanded(
        flex: 5,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
          child: _TipForm(creator: creator, onTipSent: onTipSent),
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
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _CreatorCard(creator: creator),
      if (creator.tipGoal != null) ...[
        const SizedBox(height: 16),
        _GoalBar(tipGoal: creator.tipGoal!, totalTips: creator.totalTips),
      ],
      if (jars.isNotEmpty) ...[
        const SizedBox(height: 24),
        _JarsSection(jars: jars, creatorSlug: creator.slug),
      ],
      if (tiers.isNotEmpty) ...[
        const SizedBox(height: 24),
        _TiersSection(tiers: tiers, creatorSlug: creator.slug, creatorName: creator.displayName),
      ],
      if (milestones.isNotEmpty) ...[
        const SizedBox(height: 24),
        _MilestonesSection(milestones: milestones),
      ],
      if (publicPosts.isNotEmpty) ...[
        const SizedBox(height: 24),
        _ContentSection(
          creatorSlug: creator.slug,
          publicPosts: publicPosts,
          unlockedPosts: unlockedPosts,
          onUnlocked: onUnlocked,
        ),
      ],
      if (commissionSlot != null && commissionSlot!.isOpen) ...[
        const SizedBox(height: 24),
        _CommissionsSection(slot: commissionSlot!, creatorSlug: creator.slug, creatorName: creator.displayName),
      ],
      const SizedBox(height: 28),
      _TipForm(creator: creator, onTipSent: onTipSent),
      const SizedBox(height: 32),
      _TipFeed(tips: tips),
    ]),
  );
}

// ─── Creator card ─────────────────────────────────────────────────────────────
class _CreatorCard extends StatelessWidget {
  final Creator creator;
  const _CreatorCard({required this.creator});

  Color get _avatarColor {
    final colors = [kPrimary, const Color(0xFF60A5FA), const Color(0xFFF472B6),
        const Color(0xFFFBBF24), const Color(0xFF818CF8)];
    return colors[creator.slug.length % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Avatar
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: _avatarColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: _avatarColor.withValues(alpha: 0.4), width: 2),
        ),
        child: Center(
          child: Text(
            creator.displayName.isNotEmpty
                ? creator.displayName[0].toUpperCase() : '?',
            style: GoogleFonts.dmSans(
                color: _avatarColor, fontWeight: FontWeight.w900, fontSize: 34),
          ),
        ),
      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
      const SizedBox(height: 16),

      // Name + slug
      Text(creator.displayName, style: GoogleFonts.dmSans(
          color: Colors.white, fontWeight: FontWeight.w800,
          fontSize: 28, letterSpacing: -0.8))
          .animate().fadeIn(delay: 80.ms, duration: 400.ms).slideY(begin: 0.1),
      const SizedBox(height: 4),
      Text('@${creator.slug}', style: GoogleFonts.dmSans(color: kMuted, fontSize: 14))
          .animate().fadeIn(delay: 120.ms, duration: 400.ms),

      // Tagline
      if (creator.tagline.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(creator.tagline, style: GoogleFonts.dmSans(
            color: Colors.white.withValues(alpha: 0.75), fontSize: 15, height: 1.5))
            .animate().fadeIn(delay: 160.ms, duration: 400.ms),
      ],

      const SizedBox(height: 20),
      const Divider(color: kBorder),
      const SizedBox(height: 16),

      // Stats
      Row(children: [
        _StatPill(
          icon: Icons.volunteer_activism_rounded,
          label: 'R${creator.totalTips.toStringAsFixed(0)}',
          sub: 'total received',
        ),
      ]).animate().fadeIn(delay: 200.ms, duration: 400.ms),
    ]);
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  const _StatPill({required this.icon, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: kCardBg, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kBorder),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: kPrimary, size: 16),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
        Text(sub, style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
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
        color: kCardBg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Monthly goal', style: GoogleFonts.dmSans(
              color: kMuted, fontWeight: FontWeight.w600, fontSize: 12)),
          const Spacer(),
          Text('$pct%', style: GoogleFonts.dmSans(
              color: kPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress, minHeight: 6,
            backgroundColor: kBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(kPrimary),
          ),
        ),
        const SizedBox(height: 6),
        Text('R${totalTips.toStringAsFixed(0)} of R${tipGoal.toStringAsFixed(0)}',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
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
          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
      const SizedBox(height: 12),
      if (tips.isEmpty)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28),
          alignment: Alignment.center,
          child: Column(children: [
            const Icon(Icons.favorite_border_rounded, color: kMuted, size: 32),
            const SizedBox(height: 10),
            Text('No tips yet — be the first!',
                style: GoogleFonts.dmSans(color: kMuted, fontSize: 14)),
          ]),
        )
      else
        ...tips.asMap().entries.map((e) => _PublicTipRow(tip: e.value, index: e.key)),
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
      color: kCardBg, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kBorder),
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
          Text(tip.tipperName, style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(width: 6),
          Text(_relative, style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
          const Spacer(),
          Text('R${tip.amount.toStringAsFixed(2)}', style: GoogleFonts.dmSans(
              color: kPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
        ]),
        if (tip.message.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(tip.message, style: GoogleFonts.dmSans(
              color: kMuted, fontSize: 12, height: 1.45),
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
      color: kCardBg, borderRadius: BorderRadius.circular(24),
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
          color: Colors.white, fontWeight: FontWeight.w800,
          fontSize: 22, letterSpacing: -0.4))
          .animate().fadeIn(delay: 100.ms),
      const SizedBox(height: 8),
      Text(
        'A Paystack payment page opened in your browser.\nFinish the payment there and come back.',
        style: GoogleFonts.dmSans(color: kMuted, fontSize: 14, height: 1.55),
        textAlign: TextAlign.center,
      ).animate().fadeIn(delay: 150.ms),
      const SizedBox(height: 12),
      // Fee summary
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: kDark, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Column(children: [
          _FeeRow('Tip amount', 'R${_finalAmount.toStringAsFixed(2)}', Colors.white),
          const SizedBox(height: 4),
          _FeeRow('Platform fee (${_platformFeePct.toInt()}%)', '- R${_platformFee.toStringAsFixed(2)}', kMuted),
          _FeeRow('Service fee (${_serviceFeePct.toInt()}%)', '- R${_serviceFee.toStringAsFixed(2)}', kMuted),
          const Divider(color: kBorder, height: 12),
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
          child: Text('Cancel', style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
        ).animate().fadeIn(delay: 300.ms),
      ],
    ]),
  );

  // ── Success ───────────────────────────────────────────────────────
  Widget _successState() => Container(
    key: const ValueKey('success'),
    padding: const EdgeInsets.all(36),
    decoration: BoxDecoration(
      color: kCardBg, borderRadius: BorderRadius.circular(24),
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
          color: Colors.white, fontWeight: FontWeight.w800,
          fontSize: 26, letterSpacing: -0.5))
          .animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),
      const SizedBox(height: 8),
      Text(
        'You sent R${_finalAmount.toStringAsFixed(2)} to $_sentTo',
        style: GoogleFonts.dmSans(color: kMuted, fontSize: 15, height: 1.5),
        textAlign: TextAlign.center,
      ).animate().fadeIn(delay: 200.ms),
      const SizedBox(height: 6),
      Text(
        '${_nameCtrl.text.trim().isEmpty ? 'You' : _nameCtrl.text.trim()} just made someone\'s day.',
        style: GoogleFonts.dmSans(color: kMuted, fontSize: 13),
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
            color: kMuted, fontSize: 14, fontWeight: FontWeight.w500)),
      ).animate().fadeIn(delay: 350.ms),
    ]),
  );

  // ── Form ──────────────────────────────────────────────────────────
  Widget _formState() => Container(
    key: const ValueKey('form'),
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: kCardBg, borderRadius: BorderRadius.circular(24),
      border: Border.all(color: kBorder),
      boxShadow: [BoxShadow(
          color: kPrimary.withValues(alpha: 0.04),
          blurRadius: 32, offset: const Offset(0, 8))],
    ),
    child: Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Text(
          'Support ${widget.creator.displayName} 💚',
          style: GoogleFonts.dmSans(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.4),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 4),
        Text('Choose an amount and leave a message.',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 13))
            .animate().fadeIn(delay: 60.ms, duration: 400.ms),
        const SizedBox(height: 24),

        // Amount presets
        Text('Amount', style: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 10),
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
          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
          onChanged: (v) {
            final parsed = double.tryParse(v);
            setState(() => _customAmount = parsed);
          },
          decoration: InputDecoration(
            hintText: 'Custom amount',
            hintStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 14),
            prefixText: '\$ ',
            prefixStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 14),
            filled: true, fillColor: kDark,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: _usingCustom ? kPrimary : kBorder,
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

        // Fee breakdown preview
        AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kPrimary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kPrimary.withValues(alpha: 0.2)),
          ),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.volunteer_activism_rounded, color: kPrimary, size: 14),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Sending to ${widget.creator.displayName}',
                style: GoogleFonts.dmSans(color: kPrimary, fontWeight: FontWeight.w600, fontSize: 13),
              )),
              Text('R${_finalAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.dmSans(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
            const SizedBox(height: 8),
            _FeeRow('Platform fee (${_platformFeePct.toInt()}%)', '- R${_platformFee.toStringAsFixed(2)}', kMuted),
            _FeeRow('Service fee (${_serviceFeePct.toInt()}%)', '- R${_serviceFee.toStringAsFixed(2)}', kMuted),
            const Divider(color: kBorder, height: 10),
            _FeeRow('Creator receives', 'R${_creatorNet.toStringAsFixed(2)}', Colors.white, bold: true),
          ]),
        ),
        const SizedBox(height: 20),

        // Name
        Text('Your name (optional)', style: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameCtrl,
          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Anonymous',
            hintStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 14),
            prefixIcon: const Icon(Icons.person_outline_rounded, color: kMuted, size: 18),
            filled: true, fillColor: kDark,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kPrimary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 14),

        // Email (for payment receipt)
        Text('Email (for payment receipt)', style: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'you@example.com (optional)',
            hintStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 14),
            prefixIcon: const Icon(Icons.email_outlined, color: kMuted, size: 18),
            filled: true, fillColor: kDark,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kPrimary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 14),

        // Message
        Text('Leave a message (optional)', style: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _messageCtrl,
          maxLines: 3,
          maxLength: 280,
          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Say something nice… 👋',
            hintStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 14),
            filled: true, fillColor: kDark,
            counterStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 11),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kBorder)),
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
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
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
          const Icon(Icons.lock_outline_rounded, color: kMuted, size: 13),
          const SizedBox(width: 5),
          Text('Secure payments via Paystack',
              style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
        ]),
      ]),
    ),
  );

  Future<void> _submit() async {
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
            backgroundColor: kCardBg, behavior: SnackBarBehavior.floating,
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
        const Icon(Icons.savings_rounded, color: kPrimary, size: 16),
        const SizedBox(width: 8),
        Text('Active Jars',
            style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
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
            color: kCardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _hovered ? kPrimary.withValues(alpha: 0.5) : kBorder),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.savings_rounded, color: kPrimary, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(jar.name,
                    style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
              ),
              Text('R${jar.totalRaised.toStringAsFixed(0)} raised',
                  style: GoogleFonts.dmSans(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
            if (jar.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(jar.description,
                  style: GoogleFonts.dmSans(color: kMuted, fontSize: 12, height: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            if (progress != null) ...[
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Goal: R${jar.goal!.toStringAsFixed(0)}',
                    style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
                Text('${jar.progressPct!.toStringAsFixed(0)}%',
                    style: GoogleFonts.dmSans(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 11)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: kBorder,
                  valueColor: const AlwaysStoppedAnimation(kPrimary),
                  minHeight: 5,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(children: [
              Text('${jar.tipCount} tip${jar.tipCount == 1 ? '' : 's'}',
                  style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
              const Spacer(),
              Text('Tip this jar →',
                  style: GoogleFonts.dmSans(color: kPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
            ]),
          ]),
        ),
      ),
    );
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
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
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
          backgroundColor: kCardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Unlock exclusive content',
              style: GoogleFonts.dmSans(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              'Enter the email you used when tipping to unlock the content.',
              style: GoogleFonts.dmSans(color: kMuted, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'you@example.com',
                hintStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.email_outlined, color: kMuted, size: 18),
                filled: true, fillColor: kDark,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kBorder)),
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
              child: Text('Cancel', style: GoogleFonts.dmSans(color: kMuted)),
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
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.image_rounded, color: Colors.white24, size: 36),
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
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.play_circle_outline_rounded, color: Colors.white24, size: 36),
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
        color: Colors.white.withValues(alpha: 0.12),
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
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
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
                    kCardBg.withValues(alpha: 0.55),
                    kCardBg.withValues(alpha: 0.80),
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
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            )),
            const Icon(Icons.lock_rounded, color: kMuted, size: 15),
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
      color: kCardBg,
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
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
        const Icon(Icons.lock_open_rounded, color: kPrimary, size: 15),
      ]),

      // Body text
      if (post.body.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(post.body, style: GoogleFonts.dmSans(
            color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.55)),
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
              color: kDark,
              child: const Center(child: Icon(Icons.broken_image_rounded, color: kMuted)),
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
            color: active ? kPrimary.withValues(alpha: 0.12) : kDark,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
                color: active ? kPrimary : kBorder,
                width: active ? 2 : 1),
          ),
          child: Text('R${v.toInt()}', style: GoogleFonts.dmSans(
              color: active ? kPrimary : Colors.white,
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
          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20,
          letterSpacing: -0.4)),
      const SizedBox(height: 4),
      Text('Choose a monthly support level', style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
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
      color: kCardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(tier.name, style: GoogleFonts.dmSans(
          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 4),
      Text('R${tier.price.toStringAsFixed(0)}/month', style: GoogleFonts.dmSans(
          color: kPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
      if (tier.description.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(tier.description, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12, height: 1.4)),
      ],
      if (tier.perks.isNotEmpty) ...[
        const SizedBox(height: 12),
        ...tier.perks.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            const Icon(Icons.check_circle_outline_rounded, color: kPrimary, size: 14),
            const SizedBox(width: 6),
            Expanded(child: Text(p, style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 12))),
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
    backgroundColor: kCardBg,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: Text(
      _done ? 'Pledge Active!' : 'Subscribe to ${widget.tier.name}',
      style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
    ),
    content: _done
        ? Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_rounded, color: kPrimary, size: 48),
            const SizedBox(height: 12),
            Text(
              'You\'re now supporting ${widget.creatorName} with R${widget.tier.price.toStringAsFixed(0)}/month.',
              style: GoogleFonts.dmSans(color: kMuted, fontSize: 13, height: 1.5),
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
              style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Your name (optional)',
                hintStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.person_outline_rounded, color: kMuted, size: 18),
                filled: true, fillColor: kDark,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kPrimary, width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'your@email.com *',
                hintStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.email_outlined, color: kMuted, size: 18),
                filled: true, fillColor: kDark,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kBorder)),
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
              child: Text('Cancel', style: GoogleFonts.dmSans(color: kMuted)),
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
          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.4)),
      const SizedBox(height: 4),
      Text('Help unlock these goals', style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
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
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: milestone.isAchieved
            ? kPrimary.withValues(alpha: 0.5)
            : kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(milestone.title, style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
          if (milestone.isAchieved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kPrimary.withValues(alpha: 0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle_rounded, color: kPrimary, size: 13),
                const SizedBox(width: 4),
                Text('Unlocked!', style: GoogleFonts.dmSans(
                    color: kPrimary, fontWeight: FontWeight.w700, fontSize: 11)),
              ]),
            ),
        ]),
        if (milestone.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(milestone.description, style: GoogleFonts.dmSans(
              color: kMuted, fontSize: 12, height: 1.4)),
        ],
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: kDark,
            valueColor: AlwaysStoppedAnimation<Color>(
                milestone.isAchieved ? kPrimary : kPrimary.withValues(alpha: 0.7)),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            'R${milestone.currentMonthTotal.toStringAsFixed(0)} raised this month',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 11),
          ),
          Text(
            'Goal: R${milestone.targetAmount.toStringAsFixed(0)}',
            style: GoogleFonts.dmSans(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 11),
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
          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.4)),
      const SizedBox(height: 4),
      Text('Request custom work from $creatorName', style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
              ),
              child: Text('Open for commissions', style: GoogleFonts.dmSans(
                  color: Colors.greenAccent, fontWeight: FontWeight.w600, fontSize: 11)),
            ),
          ]),
          const SizedBox(height: 12),
          Text(
            'From R${slot.basePrice.toStringAsFixed(0)}',
            style: GoogleFonts.dmSans(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 22),
          ),
          if (slot.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(slot.description, style: GoogleFonts.dmSans(color: kMuted, fontSize: 13, height: 1.5)),
          ],
          const SizedBox(height: 6),
          Text('Turnaround: ${slot.turnaroundDays} days',
              style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12)),
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
    hintStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 14),
    prefixIcon: Icon(icon, color: kMuted, size: 18),
    filled: true, fillColor: kDark,
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: kCardBg,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: Text(
      _done ? 'Request Sent!' : 'Request a Commission',
      style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
    ),
    content: _done
        ? Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_rounded, color: kPrimary, size: 48),
            const SizedBox(height: 12),
            Text(
              '${widget.creatorName} will review your request and get back to you.',
              style: GoogleFonts.dmSans(color: kMuted, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ])
        : SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: _titleCtrl,
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
                decoration: _dec('Commission title *', Icons.title_rounded),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
                decoration: _dec('Describe what you want *', Icons.description_outlined).copyWith(prefixIcon: null),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameCtrl,
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
                decoration: _dec('Your name (optional)', Icons.person_outline_rounded),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
                decoration: _dec('Your email *', Icons.email_outlined),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
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
              child: Text('Cancel', style: GoogleFonts.dmSans(color: kMuted)),
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
