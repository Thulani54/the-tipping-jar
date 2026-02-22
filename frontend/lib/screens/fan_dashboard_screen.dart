import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/commission_model.dart';
import '../models/creator.dart';
import '../models/pledge_model.dart';
import '../models/tip_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fan Dashboard
// ─────────────────────────────────────────────────────────────────────────────

class FanDashboardScreen extends StatefulWidget {
  const FanDashboardScreen({super.key});

  @override
  State<FanDashboardScreen> createState() => _FanDashboardScreenState();
}

class _FanDashboardScreenState extends State<FanDashboardScreen> {
  List<TipModel> _tips = [];
  List<Creator> _creators = [];
  List<PledgeModel> _pledges = [];
  List<TipStreakModel> _streaks = [];
  List<CommissionRequestModel> _commissions = [];
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
      final auth = context.read<AuthProvider>();
      final api = ApiService(authToken: auth.accessToken);
      final results = await Future.wait([
        api.getSentTips(),
        api.getCreators(),
        api.getMyPledges().catchError((_) => <PledgeModel>[]),
        api.getMyStreaks().catchError((_) => <TipStreakModel>[]),
        api.getMyCommissions().catchError((_) => <CommissionRequestModel>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _tips = results[0] as List<TipModel>;
        _creators = results[1] as List<Creator>;
        _pledges = results[2] as List<PledgeModel>;
        _streaks = results[3] as List<TipStreakModel>;
        _commissions = results[4] as List<CommissionRequestModel>;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Derived stats ─────────────────────────────────────────────────────────

  int get _tipCount => _tips.length;
  double get _totalSpent => _tips.fold(0, (s, t) => s + t.amount);
  int get _creatorsSupported =>
      _tips.map((t) => t.creatorSlug).toSet().length;

  // ── Greeting ─────────────────────────────────────────────────────────────

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final username = auth.user?.username ?? 'there';
    final wide = MediaQuery.of(context).size.width > 860;

    return Scaffold(
      backgroundColor: kDark,
      body: Column(children: [
        _TopBar(username: username, onLogout: () async {
          await auth.logout();
          if (mounted) context.go('/');
        }),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: kPrimary))
              : _error != null
                  ? _errorView()
                  : RefreshIndicator(
                      color: kPrimary,
                      backgroundColor: kCardBg,
                      onRefresh: _load,
                      child: wide
                          ? _wideLayout(username)
                          : _narrowLayout(username),
                    ),
        ),
      ]),
    );
  }

  Widget _errorView() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.wifi_off_rounded, color: kMuted, size: 48),
      const SizedBox(height: 16),
      Text('Could not load your data', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text(_error ?? '', style: GoogleFonts.inter(color: kMuted, fontSize: 12), textAlign: TextAlign.center),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: _load,
        style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
        child: const Text('Try again'),
      ),
    ]),
  );

  // ── Wide layout: left rail + right content ────────────────────────────────
  Widget _wideLayout(String username) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Left: welcome + stats + recent tips + pledges + streaks + commissions
      SizedBox(
        width: 400,
        child: ListView(padding: const EdgeInsets.all(32), children: [
          _WelcomeCard(greeting: _greeting, username: username, tipCount: _tipCount),
          const SizedBox(height: 20),
          _StatsRow(tipCount: _tipCount, totalSpent: _totalSpent, creatorsSupported: _creatorsSupported),
          const SizedBox(height: 32),
          _SectionHeader(title: 'Your tips', trailing: _tipCount > 0 ? '$_tipCount total' : null),
          const SizedBox(height: 12),
          _tips.isEmpty ? _emptyTips() : _tipsList(),
          if (_pledges.isNotEmpty) ...[
            const SizedBox(height: 32),
            _SectionHeader(title: 'My Pledges', subtitle: 'Your monthly commitments'),
            const SizedBox(height: 12),
            ..._pledges.map((p) => _PledgeCard(pledge: p, onRefresh: _load)),
          ],
          if (_streaks.isNotEmpty) ...[
            const SizedBox(height: 32),
            _SectionHeader(title: 'Supporter Streaks', subtitle: 'Consecutive months tipping'),
            const SizedBox(height: 12),
            ..._streaks.map((s) => _StreakCard(streak: s)),
          ],
          if (_commissions.isNotEmpty) ...[
            const SizedBox(height: 32),
            _SectionHeader(title: 'My Commissions', subtitle: 'Requests you\'ve submitted'),
            const SizedBox(height: 12),
            ..._commissions.map((c) => _FanCommissionCard(commission: c)),
          ],
        ]),
      ),
      // Divider
      Container(width: 1, color: kBorder),
      // Right: discover creators
      Expanded(
        child: ListView(padding: const EdgeInsets.all(32), children: [
          _SectionHeader(title: 'Discover creators', trailing: 'Browse all'),
          const SizedBox(height: 20),
          _creatorsGrid(),
        ]),
      ),
    ]);
  }

  // ── Narrow layout: stacked ────────────────────────────────────────────────
  Widget _narrowLayout(String username) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      _WelcomeCard(greeting: _greeting, username: username, tipCount: _tipCount),
      const SizedBox(height: 20),
      _StatsRow(tipCount: _tipCount, totalSpent: _totalSpent, creatorsSupported: _creatorsSupported),
      const SizedBox(height: 32),
      _SectionHeader(title: 'Your tips', trailing: _tipCount > 0 ? '$_tipCount total' : null),
      const SizedBox(height: 12),
      _tips.isEmpty ? _emptyTips() : _tipsList(),
      if (_pledges.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(title: 'My Pledges', subtitle: 'Your monthly commitments'),
        const SizedBox(height: 12),
        ..._pledges.map((p) => _PledgeCard(pledge: p, onRefresh: _load)),
      ],
      if (_streaks.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(title: 'Supporter Streaks', subtitle: 'Consecutive months tipping'),
        const SizedBox(height: 12),
        ..._streaks.map((s) => _StreakCard(streak: s)),
      ],
      if (_commissions.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(title: 'My Commissions', subtitle: 'Requests you\'ve submitted'),
        const SizedBox(height: 12),
        ..._commissions.map((c) => _FanCommissionCard(commission: c)),
      ],
      const SizedBox(height: 32),
      _SectionHeader(
        title: 'Discover creators',
        trailing: 'Browse all',
        onTrailingTap: () => context.go('/creators'),
      ),
      const SizedBox(height: 16),
      _creatorsScroll(),
    ]);
  }

  // ── Tips list ─────────────────────────────────────────────────────────────
  Widget _tipsList() => Column(
    children: _tips.take(10).toList().asMap().entries.map((e) =>
      _TipCard(tip: e.value, delay: e.key * 60)
          .animate().fadeIn(delay: (e.key * 60).ms, duration: 350.ms)
    ).toList(),
  );

  Widget _emptyTips() => Container(
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
    decoration: BoxDecoration(
      color: kCardBg, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kBorder),
    ),
    child: Column(children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), shape: BoxShape.circle),
        child: const Icon(Icons.volunteer_activism_outlined, color: kPrimary, size: 24),
      ),
      const SizedBox(height: 14),
      Text('No tips sent yet', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 6),
      Text('Find a creator you love and send your first tip!',
          style: GoogleFonts.inter(color: kMuted, fontSize: 13, height: 1.5),
          textAlign: TextAlign.center),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: () => context.go('/creators'),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
        ),
        child: Text('Browse creators', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    ]),
  ).animate().fadeIn(duration: 400.ms);

  // ── Creators grid (wide) ──────────────────────────────────────────────────
  Widget _creatorsGrid() {
    if (_creators.isEmpty) {
      return Center(child: Text('No creators yet', style: GoogleFonts.inter(color: kMuted)));
    }
    return Wrap(
      spacing: 16, runSpacing: 16,
      children: _creators.take(12).toList().asMap().entries.map((e) =>
        _CreatorCard(creator: e.value, delay: e.key * 50)
      ).toList(),
    );
  }

  // ── Creators horizontal scroll (narrow) ───────────────────────────────────
  Widget _creatorsScroll() {
    if (_creators.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _creators.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _CreatorCard(creator: _creators[i], delay: i * 50),
      ),
    );
  }
}

// ─── Top bar ─────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String username;
  final VoidCallback onLogout;
  const _TopBar({required this.username, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kDarker,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: SafeArea(
        bottom: false,
        child: Row(children: [
          GestureDetector(
            onTap: () => context.go('/'),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const AppLogoIcon(size: 30),
              const SizedBox(width: 8),
              Text('TippingJar', style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.w700,
                  fontSize: 16, letterSpacing: -0.3)),
            ]),
          ),
          const Spacer(),
          // Browse creators shortcut
          TextButton.icon(
            onPressed: () => context.go('/creators'),
            icon: const Icon(Icons.explore_outlined, size: 16, color: kMuted),
            label: Text('Explore', style: GoogleFonts.inter(color: kMuted, fontSize: 13, fontWeight: FontWeight.w500)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
          ),
          const SizedBox(width: 4),
          // Avatar + logout
          PopupMenuButton<String>(
            color: kCardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: kBorder)),
            offset: const Offset(0, 40),
            onSelected: (v) { if (v == 'logout') onLogout(); },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 10),
                  Text('Sign out', style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
                ]),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kCardBg, borderRadius: BorderRadius.circular(36),
                border: Border.all(color: kBorder),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 22, height: 22,
                  decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                  child: Center(
                    child: Text(username.isNotEmpty ? username[0].toUpperCase() : '?',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 7),
                Text(username, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, color: kMuted, size: 16),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Welcome card ─────────────────────────────────────────────────────────────
class _WelcomeCard extends StatelessWidget {
  final String greeting, username;
  final int tipCount;
  const _WelcomeCard({required this.greeting, required this.username, required this.tipCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF001A12), Color(0xFF001520)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$greeting, $username 👋',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800,
                fontSize: 22, letterSpacing: -0.5))
            .animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
        const SizedBox(height: 8),
        Text(
          tipCount == 0
              ? 'Ready to support your first creator?'
              : 'You\'ve sent $tipCount tip${tipCount == 1 ? '' : 's'} so far — amazing!',
          style: GoogleFonts.inter(color: kMuted, fontSize: 14, height: 1.5),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => context.go('/creators'),
          icon: const Icon(Icons.explore_outlined, size: 15),
          label: Text('Discover creators', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
          style: OutlinedButton.styleFrom(
            foregroundColor: kPrimary,
            side: const BorderSide(color: kPrimary, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
      ]),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int tipCount, creatorsSupported;
  final double totalSpent;
  const _StatsRow({required this.tipCount, required this.totalSpent, required this.creatorsSupported});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _StatChip(label: 'Tips sent', value: '$tipCount', icon: Icons.favorite_rounded, delay: 0),
      const SizedBox(width: 10),
      _StatChip(label: 'Total given', value: 'R${totalSpent.toStringAsFixed(0)}', icon: Icons.attach_money_rounded, delay: 80),
      const SizedBox(width: 10),
      _StatChip(label: 'Creators', value: '$creatorsSupported', icon: Icons.people_outline_rounded, delay: 160),
    ]);
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final int delay;
  const _StatChip({required this.label, required this.value, required this.icon, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: kCardBg, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: kPrimary, size: 16),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(color: kMuted, fontSize: 11)),
        ]),
      ).animate().fadeIn(delay: delay.ms, duration: 350.ms),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final String? subtitle;
  final VoidCallback? onTrailingTap;
  const _SectionHeader({required this.title, this.trailing, this.subtitle, this.onTrailingTap});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        const Spacer(),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(trailing!, style: GoogleFonts.inter(color: kMuted, fontSize: 12,
                decoration: onTrailingTap != null ? TextDecoration.underline : null)),
          ),
      ]),
      if (subtitle != null)
        Text(subtitle!, style: GoogleFonts.inter(color: kMuted, fontSize: 12)),
    ]);
  }
}

// ─── Tip card ─────────────────────────────────────────────────────────────────
class _TipCard extends StatelessWidget {
  final TipModel tip;
  final int delay;
  const _TipCard({required this.tip, required this.delay});

  String get _initials {
    final name = tip.creatorDisplayName;
    return name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase().padRight(1, '?');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/creator/${tip.creatorSlug}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
        ),
        child: Row(children: [
          // Avatar
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
            child: Center(child: Text(_initials,
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(tip.creatorDisplayName,
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
              ),
              Text('R${tip.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
            ]),
            if (tip.message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(tip.message,
                  style: GoogleFonts.inter(color: kMuted, fontSize: 12, height: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 4),
            Text(tip.relativeTime, style: GoogleFonts.inter(color: kMuted, fontSize: 11)),
          ])),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: kBorder, size: 18),
        ]),
      ),
    );
  }
}

// ─── Creator card ─────────────────────────────────────────────────────────────
class _CreatorCard extends StatefulWidget {
  final Creator creator;
  final int delay;
  const _CreatorCard({required this.creator, required this.delay});
  @override
  State<_CreatorCard> createState() => _CreatorCardState();
}

class _CreatorCardState extends State<_CreatorCard> {
  bool _hovered = false;
  String get _initials => widget.creator.displayName.split(' ')
      .map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go('/creator/${widget.creator.slug}'),
        child: AnimatedContainer(
          duration: 180.ms,
          width: 180,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _hovered ? kPrimary.withOpacity(0.5) : kBorder),
            boxShadow: _hovered
                ? [BoxShadow(color: kPrimary.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 6))]
                : [],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
              child: Center(child: Text(_initials,
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))),
            ),
            const SizedBox(height: 10),
            Text(widget.creator.displayName,
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(widget.creator.tagline,
                style: GoogleFonts.inter(color: kMuted, fontSize: 11, height: 1.4),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/creator/${widget.creator.slug}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary.withOpacity(0.15),
                  foregroundColor: kPrimary,
                  elevation: 0, shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                ),
                child: Text('Tip', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ),
          ]),
        ),
      ),
    ).animate().fadeIn(delay: widget.delay.ms, duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOut);
  }
}

// ─── Pledge card (fan dashboard) ──────────────────────────────────────────────
class _PledgeCard extends StatelessWidget {
  final PledgeModel pledge;
  final VoidCallback onRefresh;
  const _PledgeCard({required this.pledge, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final statusColor = pledge.isActive ? const Color(0xFF10B981) : kMuted;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
      child: Row(children: [
        Container(width: 40, height: 40,
            decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.repeat_rounded, color: kPrimary, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(pledge.creatorDisplayName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          if (pledge.tierName != null)
            Text(pledge.tierName!, style: GoogleFonts.inter(color: kMuted, fontSize: 12)),
          if (pledge.nextChargeDate != null)
            Text('Next: ${pledge.nextChargeDate}', style: GoogleFonts.inter(color: kMuted, fontSize: 11)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('R${pledge.amount.toStringAsFixed(0)}/mo', style: GoogleFonts.inter(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(36)),
            child: Text(pledge.status.toUpperCase(), style: GoogleFonts.inter(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
        if (pledge.isActive) ...[
          const SizedBox(width: 10),
          TextButton(
            onPressed: () async {
              final api = context.read<AuthProvider>().api;
              await api.updatePledge(pledge.id, 'cancelled');
              onRefresh();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent, padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
            child: Text('Cancel', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.redAccent)),
          ),
        ],
      ]),
    );
  }
}

// ─── Streak card (fan dashboard) ──────────────────────────────────────────────
class _StreakCard extends StatelessWidget {
  final TipStreakModel streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
      child: Row(children: [
        const Text('\u{1F525}', style: TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${streak.currentStreak} month${streak.currentStreak == 1 ? '' : 's'} streak',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          Text(streak.creatorDisplayName, style: GoogleFonts.inter(color: kMuted, fontSize: 12)),
          if (streak.badges.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: streak.badges.map((b) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: kPrimary.withValues(alpha: 0.3))),
              child: Text(b, style: GoogleFonts.inter(color: kPrimary, fontSize: 10, fontWeight: FontWeight.w700)),
            )).toList()),
          ],
        ])),
        Text('Best: ${streak.maxStreak}mo', style: GoogleFonts.inter(color: kMuted, fontSize: 11)),
      ]),
    );
  }
}

// ─── Fan commission card ──────────────────────────────────────────────────────
class _FanCommissionCard extends StatelessWidget {
  final CommissionRequestModel commission;
  const _FanCommissionCard({required this.commission});

  Color get _statusColor => switch (commission.status) {
    'accepted' => const Color(0xFF10B981),
    'declined' => Colors.redAccent,
    'completed' => const Color(0xFF60A5FA),
    _ => const Color(0xFFFBBF24),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(commission.title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(36)),
            child: Text(commission.status.toUpperCase(), style: GoogleFonts.inter(color: _statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 4),
        Text(commission.creatorDisplayName, style: GoogleFonts.inter(color: kMuted, fontSize: 12)),
        Text('R${commission.agreedPrice.toStringAsFixed(0)} agreed', style: GoogleFonts.inter(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
        if (commission.deliveryNote.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(commission.deliveryNote, style: GoogleFonts.inter(color: const Color(0xFF60A5FA), fontSize: 12, height: 1.4)),
        ],
      ]),
    );
  }
}
