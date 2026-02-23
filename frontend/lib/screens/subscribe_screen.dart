import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/creator.dart';
import '../models/tier_model.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';

// ─── Public subscription landing page ────────────────────────────────────────
class SubscribeScreen extends StatefulWidget {
  final String slug;
  const SubscribeScreen({super.key, required this.slug});

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen> {
  Creator? _creator;
  List<TierModel> _tiers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService().getCreator(widget.slug),
        ApiService().getPublicTiers(widget.slug),
      ]);
      if (mounted) {
        setState(() {
          _creator = results[0] as Creator;
          _tiers = (results[1] as List<TierModel>).where((t) => t.isActive).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: kDark,
        body: Center(child: CircularProgressIndicator(color: kPrimary)),
      );
    }
    if (_error != null || _creator == null) {
      return Scaffold(
        backgroundColor: kDark,
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.workspace_premium_outlined, color: kMuted, size: 56),
          const SizedBox(height: 16),
          Text('Creator not found', style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 8),
          Text('This subscribe page may have moved or the link is invalid.',
              style: GoogleFonts.dmSans(color: kMuted, fontSize: 14),
              textAlign: TextAlign.center),
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

    final creator = _creator!;
    final wide = MediaQuery.of(context).size.width > 860;

    return Scaffold(
      backgroundColor: kDark,
      body: Column(children: [
        _SubscribeNav(slug: widget.slug, creatorName: creator.displayName),
        Expanded(
          child: wide
              ? _WideContent(creator: creator, tiers: _tiers)
              : _NarrowContent(creator: creator, tiers: _tiers),
        ),
      ]),
    );
  }
}

// ─── Nav bar ─────────────────────────────────────────────────────────────────
class _SubscribeNav extends StatefulWidget {
  final String slug;
  final String creatorName;
  const _SubscribeNav({required this.slug, required this.creatorName});
  @override
  State<_SubscribeNav> createState() => _SubscribeNavState();
}

class _SubscribeNavState extends State<_SubscribeNav> {
  bool _copied = false;

  void _copy() {
    final url = 'www.tippingjar.co.za/creator/${widget.slug}/subscribe';
    Clipboard.setData(ClipboardData(text: url));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

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
      const SizedBox(width: 12),
      const Icon(Icons.chevron_right_rounded, color: kMuted, size: 16),
      const SizedBox(width: 6),
      GestureDetector(
        onTap: () => context.go('/creator/${widget.slug}'),
        child: Text(widget.slug,
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 13),
            overflow: TextOverflow.ellipsis),
      ),
      const SizedBox(width: 6),
      const Icon(Icons.chevron_right_rounded, color: kMuted, size: 16),
      const SizedBox(width: 6),
      Text('Subscribe', style: GoogleFonts.dmSans(
          color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      const Spacer(),
      AnimatedSwitcher(
        duration: 200.ms,
        child: _copied
            ? Container(
                key: const ValueKey('copied'),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kPrimary.withValues(alpha: 0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_rounded, color: kPrimary, size: 14),
                  const SizedBox(width: 6),
                  Text('Copied!', style: GoogleFonts.dmSans(
                      color: kPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              )
            : GestureDetector(
                key: const ValueKey('share'),
                onTap: _copy,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kBorder),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.share_rounded, color: kMuted, size: 14),
                    const SizedBox(width: 6),
                    Text('Share link', style: GoogleFonts.dmSans(
                        color: kMuted, fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                ),
              ),
      ),
    ]),
  );
}

// ─── Wide layout ──────────────────────────────────────────────────────────────
class _WideContent extends StatelessWidget {
  final Creator creator;
  final List<TierModel> tiers;
  const _WideContent({required this.creator, required this.tiers});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
    child: Column(children: [
      _CreatorHeader(creator: creator),
      const SizedBox(height: 48),
      _TiersGrid(tiers: tiers, creatorSlug: creator.slug, creatorName: creator.displayName),
      const SizedBox(height: 48),
      _BackToCreatorLink(slug: creator.slug, name: creator.displayName),
      const SizedBox(height: 48),
    ]),
  );
}

// ─── Narrow layout ────────────────────────────────────────────────────────────
class _NarrowContent extends StatelessWidget {
  final Creator creator;
  final List<TierModel> tiers;
  const _NarrowContent({required this.creator, required this.tiers});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
    child: Column(children: [
      _CreatorHeader(creator: creator),
      const SizedBox(height: 36),
      _TiersGrid(tiers: tiers, creatorSlug: creator.slug, creatorName: creator.displayName),
      const SizedBox(height: 36),
      _BackToCreatorLink(slug: creator.slug, name: creator.displayName),
      const SizedBox(height: 36),
    ]),
  );
}

// ─── Creator header ───────────────────────────────────────────────────────────
class _CreatorHeader extends StatelessWidget {
  final Creator creator;
  const _CreatorHeader({required this.creator});

  Color _avatarColor(String name) {
    const palette = [
      Color(0xFF00C896), Color(0xFF6366F1), Color(0xFFF59E0B),
      Color(0xFFEF4444), Color(0xFF8B5CF6), Color(0xFF10B981),
    ];
    return palette[name.codeUnits.fold(0, (a, b) => a + b) % palette.length];
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: _avatarColor(creator.displayName),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          creator.displayName.isNotEmpty
              ? creator.displayName[0].toUpperCase()
              : '?',
          style: GoogleFonts.dmSans(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 36),
        ),
      ),
    ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack),
    const SizedBox(height: 16),
    Text(creator.displayName,
        style: GoogleFonts.dmSans(color: Colors.white,
            fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.6))
        .animate().fadeIn(delay: 60.ms),
    const SizedBox(height: 4),
    Text('@${creator.slug}',
        style: GoogleFonts.dmSans(color: kMuted, fontSize: 15))
        .animate().fadeIn(delay: 100.ms),
    const SizedBox(height: 20),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(children: [
        Text('Choose a monthly support level',
            style: GoogleFonts.dmSans(color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.3)),
        const SizedBox(height: 6),
        Text(
          'Your pledge supports ${creator.displayName} every month and unlocks exclusive perks.',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 14, height: 1.5),
          textAlign: TextAlign.center,
        ),
      ]),
    ).animate().fadeIn(delay: 140.ms),
  ]);
}

// ─── Tiers grid ───────────────────────────────────────────────────────────────
class _TiersGrid extends StatelessWidget {
  final List<TierModel> tiers;
  final String creatorSlug;
  final String creatorName;
  const _TiersGrid({required this.tiers, required this.creatorSlug, required this.creatorName});

  @override
  Widget build(BuildContext context) {
    if (tiers.isEmpty) {
      return Column(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: kPrimary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.workspace_premium_outlined, color: kPrimary, size: 32),
        ),
        const SizedBox(height: 20),
        Text('No tiers available yet',
            style: GoogleFonts.dmSans(color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 8),
        Text('$creatorName hasn\'t set up any subscription tiers yet.',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 14),
            textAlign: TextAlign.center),
      ]);
    }

    return Wrap(
      spacing: 16, runSpacing: 16,
      alignment: WrapAlignment.center,
      children: tiers.asMap().entries.map((e) => _SubscribeTierCard(
        tier: e.value,
        creatorSlug: creatorSlug,
        creatorName: creatorName,
      ).animate().fadeIn(delay: (e.key * 80).ms, duration: 400.ms)).toList(),
    );
  }
}

// ─── Subscribe tier card ──────────────────────────────────────────────────────
class _SubscribeTierCard extends StatelessWidget {
  final TierModel tier;
  final String creatorSlug;
  final String creatorName;
  const _SubscribeTierCard({required this.tier, required this.creatorSlug, required this.creatorName});

  @override
  Widget build(BuildContext context) => Container(
    width: 280,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: kCardBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: kBorder),
      boxShadow: [BoxShadow(
        color: kPrimary.withValues(alpha: 0.04),
        blurRadius: 24, offset: const Offset(0, 6),
      )],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: kPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('Monthly', style: GoogleFonts.dmSans(
              color: kPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
        ),
      ]),
      const SizedBox(height: 14),
      Text(tier.name, style: GoogleFonts.dmSans(
          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
      const SizedBox(height: 8),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('R${tier.price.toStringAsFixed(0)}',
            style: GoogleFonts.dmSans(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 32)),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text('/month', style: GoogleFonts.dmSans(color: kMuted, fontSize: 14)),
        ),
      ]),
      if (tier.description.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(tier.description, style: GoogleFonts.dmSans(
            color: kMuted, fontSize: 13, height: 1.5)),
      ],
      if (tier.perks.isNotEmpty) ...[
        const SizedBox(height: 16),
        const Divider(color: kBorder, height: 1),
        const SizedBox(height: 16),
        ...tier.perks.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.check_circle_rounded, color: kPrimary, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(p, style: GoogleFonts.dmSans(
                color: Colors.white70, fontSize: 13, height: 1.4))),
          ]),
        )),
      ],
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => _SubscribePledgeDialog(
              creatorSlug: creatorSlug,
              creatorName: creatorName,
              tier: tier,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
          ),
          child: Text('Subscribe · R${tier.price.toStringAsFixed(0)}/mo',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      ),
    ]),
  );
}

// ─── Pledge dialog ────────────────────────────────────────────────────────────
class _SubscribePledgeDialog extends StatefulWidget {
  final String creatorSlug;
  final String creatorName;
  final TierModel tier;
  const _SubscribePledgeDialog({
    required this.creatorSlug,
    required this.creatorName,
    required this.tier,
  });

  @override
  State<_SubscribePledgeDialog> createState() => _SubscribePledgeDialogState();
}

class _SubscribePledgeDialogState extends State<_SubscribePledgeDialog> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Email is required to set up your pledge.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService().createPledge(
        creatorSlug: widget.creatorSlug,
        amount: widget.tier.price,
        tierId: widget.tier.id,
        fanEmail: email,
        fanName: _nameCtrl.text.trim().isEmpty ? 'Anonymous' : _nameCtrl.text.trim(),
      );
      if (!mounted) return;
      if (result['authorization_url'] != null) {
        setState(() { _loading = false; });
        final uri = Uri.parse(result['authorization_url'] as String);
        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        setState(() { _loading = false; _done = true; });
      }
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: kCardBg,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: Text(
      _done ? 'You\'re in!' : 'Subscribe to ${widget.tier.name}',
      style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
    ),
    content: _done
        ? Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: kPrimary, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'You\'re now supporting ${widget.creatorName} with R${widget.tier.price.toStringAsFixed(0)}/month. Thank you!',
              style: GoogleFonts.dmSans(color: kMuted, fontSize: 14, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ])
        : Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kDark, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: Row(children: [
                const Icon(Icons.workspace_premium_outlined, color: kPrimary, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.tier.name, style: GoogleFonts.dmSans(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  Text('R${widget.tier.price.toStringAsFixed(0)}/month',
                      style: GoogleFonts.dmSans(color: kPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                ])),
              ]),
            ),
            const SizedBox(height: 16),
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
              decoration: _dec('your@email.com *', Icons.email_outlined),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 12)),
            ],
            const SizedBox(height: 4),
            Text('Your card will be charged monthly until you cancel.',
                style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
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
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Subscribe', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
            ),
          ],
  );

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
}

// ─── Back to creator link ─────────────────────────────────────────────────────
class _BackToCreatorLink extends StatelessWidget {
  final String slug;
  final String name;
  const _BackToCreatorLink({required this.slug, required this.name});

  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.arrow_back_rounded, color: kMuted, size: 14),
    const SizedBox(width: 6),
    GestureDetector(
      onTap: () => context.go('/creator/$slug'),
      child: Text('Back to $name\'s page',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 13,
              decoration: TextDecoration.underline, decorationColor: kMuted)),
    ),
  ]);
}
