import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/creator_profile_model.dart';
import '../models/dashboard_stats.dart';
import '../models/jar_model.dart';
import '../models/tip_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';

// ─── Data bundle loaded in parallel ──────────────────────────────────────────
class _DashboardData {
  final CreatorProfileModel profile;
  final DashboardStats stats;
  final List<TipModel> tips;
  const _DashboardData(this.profile, this.stats, this.tips);
}

// ─── Root screen ─────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;
  _DashboardData? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<AuthProvider>().api;
      final results = await Future.wait([
        api.getMyCreatorProfile(),
        api.getDashboardStats(),
        api.getMyTips(),
      ]);
      if (mounted) {
        setState(() {
          _data = _DashboardData(
            results[0] as CreatorProfileModel,
            results[1] as DashboardStats,
            results[2] as List<TipModel>,
          );
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _onProfileUpdated(CreatorProfileModel updated) {
    setState(() {
      _data = _DashboardData(updated, _data!.stats, _data!.tips);
    });
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: kDark,
      body: wide ? _wideLayout() : _narrowLayout(),
      bottomNavigationBar: wide ? null : _loading || _error != null ? null : _bottomNav(),
    );
  }

  Widget _wideLayout() => Row(children: [
    _Sidebar(
      selected: _navIndex,
      onSelect: (i) => setState(() => _navIndex = i),
      onLogout: _logout,
      creatorSlug: _data?.profile.slug,
    ),
    Expanded(child: _body()),
  ]);

  Widget _narrowLayout() => _body();

  Widget _bottomNav() => Container(
    decoration: const BoxDecoration(
        color: kDarker, border: Border(top: BorderSide(color: kBorder))),
    child: BottomNavigationBar(
      currentIndex: _navIndex,
      onTap: (i) => setState(() => _navIndex = i),
      backgroundColor: Colors.transparent, elevation: 0,
      selectedItemColor: kPrimary, unselectedItemColor: kMuted,
      selectedLabelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded, size: 20), label: 'Overview'),
        BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism, size: 20), label: 'Tips'),
        BottomNavigationBarItem(icon: Icon(Icons.savings_rounded, size: 20), label: 'Jars'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded, size: 20), label: 'Analytics'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded, size: 20), label: 'Profile'),
      ],
    ),
  );

  Widget _body() {
    if (_loading) return _loadingState();
    if (_error != null) return _errorState();
    final d = _data!;
    return switch (_navIndex) {
      0 => _OverviewPage(
          profile: d.profile, stats: d.stats, tips: d.tips,
          onCopyLink: _copyLink, onRefresh: _load,
        ),
      1 => _TipsPage(tips: d.tips, onRefresh: _load),
      2 => _JarsPage(profile: d.profile),
      3 => _AnalyticsPage(stats: d.stats, tips: d.tips),
      4 => _ProfilePage(
          profile: d.profile,
          onCopyLink: _copyLink,
          onUpdated: _onProfileUpdated,
        ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _loadingState() => const Center(
    child: CircularProgressIndicator(color: kPrimary),
  );

  Widget _errorState() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
      const SizedBox(height: 16),
      Text('Failed to load dashboard', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 8),
      Text(_error!, style: GoogleFonts.inter(color: kMuted, fontSize: 12), textAlign: TextAlign.center),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: _load,
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: Text('Retry', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white,
            elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
      ),
    ]),
  );

  void _copyLink() {
    final link = 'tippingjar.io/u/${_data?.profile.slug ?? ''}';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Tip link copied!', style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
      backgroundColor: kPrimary, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) context.go('/');
  }
}

// ─── Sidebar ─────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final int selected;
  final void Function(int) onSelect;
  final VoidCallback onLogout;
  final String? creatorSlug;
  const _Sidebar({required this.selected, required this.onSelect, required this.onLogout, this.creatorSlug});

  static const _items = [
    (Icons.dashboard_rounded,  'Overview'),
    (Icons.volunteer_activism, 'Tips'),
    (Icons.savings_rounded,    'Jars'),
    (Icons.bar_chart_rounded,  'Analytics'),
    (Icons.person_rounded,     'Profile'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    width: 220, color: kDarker,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 28),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          const AppLogoIcon(size: 28),
          const SizedBox(width: 8),
          Text('TippingJar', style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
      ),
      const SizedBox(height: 32),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text('CREATOR', style: GoogleFonts.inter(
            color: kMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      ),
      const SizedBox(height: 8),
      ..._items.asMap().entries.map((e) => _SidebarItem(
          icon: e.value.$1, label: e.value.$2,
          active: selected == e.key, onTap: () => onSelect(e.key))),
      const Spacer(),
      const Divider(color: kBorder, height: 1),
      _SidebarItem(
          icon: Icons.open_in_new_rounded, label: 'View tip page',
          active: false,
          onTap: () {
            if (creatorSlug != null && creatorSlug!.isNotEmpty) {
              context.go('/creator/$creatorSlug');
            }
          }),
      _SidebarItem(icon: Icons.logout_rounded, label: 'Sign out',
          active: false, onTap: onLogout, danger: true),
      const SizedBox(height: 16),
    ]),
  );
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active, danger;
  final VoidCallback onTap;
  const _SidebarItem({required this.icon, required this.label,
      required this.active, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active ? kPrimary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Icon(icon, color: active ? kPrimary : danger ? Colors.redAccent : kMuted, size: 18),
        const SizedBox(width: 10),
        Text(label, style: GoogleFonts.inter(
            color: active ? kPrimary : danger ? Colors.redAccent : kMuted,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500, fontSize: 13)),
      ]),
    ),
  );
}

// ─── Overview page ────────────────────────────────────────────────────────────
class _OverviewPage extends StatelessWidget {
  final CreatorProfileModel profile;
  final DashboardStats stats;
  final List<TipModel> tips;
  final VoidCallback onCopyLink, onRefresh;
  const _OverviewPage({required this.profile, required this.stats,
      required this.tips, required this.onCopyLink, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: kPrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(w > 900 ? 32 : 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$greeting 👋', style: GoogleFonts.inter(color: kMuted, fontSize: 13)),
              Text(profile.displayName.isEmpty ? profile.username : profile.displayName,
                  style: GoogleFonts.inter(color: Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5)),
            ]),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: onCopyLink,
              icon: const Icon(Icons.link_rounded, size: 16, color: Colors.white),
              label: Text('Share tip link', style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary, foregroundColor: Colors.white,
                elevation: 0, shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
              ),
            ),
          ]).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 28),

          // Stats
          Wrap(spacing: 14, runSpacing: 14, children: [
            _StatCard('Total earned', 'R${stats.totalEarned.toStringAsFixed(2)}',
                Icons.account_balance_wallet_rounded, kPrimary, 0),
            _StatCard('This month', 'R${stats.thisMonthEarned.toStringAsFixed(2)}',
                Icons.calendar_month_rounded, const Color(0xFF60A5FA), 80),
            _StatCard('Pending payout', 'R${stats.pendingPayout.toStringAsFixed(2)}',
                Icons.schedule_rounded, const Color(0xFFFBBF24), 160),
            _StatCard('Total tips', '${stats.tipCount}',
                Icons.volunteer_activism, const Color(0xFFF472B6), 240),
          ]),
          const SizedBox(height: 28),

          // Chart
          _WeeklyChart(data: stats.weeklyData, labels: stats.weekLabels),
          const SizedBox(height: 28),

          // Recent tips
          Row(children: [
            Text('Recent tips', style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            const Spacer(),
            if (tips.isEmpty)
              Text('No tips yet', style: GoogleFonts.inter(color: kMuted, fontSize: 13)),
          ]),
          const SizedBox(height: 14),

          if (tips.isEmpty)
            _EmptyTips()
          else
            ...tips.take(5).map((t) => _TipRow(tip: t)),

          if (stats.pendingPayout > 0) ...[
            const SizedBox(height: 28),
            _PayoutBanner(pendingPayout: stats.pendingPayout),
          ],

          if (!profile.hasBankConnected) ...[
            const SizedBox(height: 20),
            _BankCta(),
          ],
        ]),
      ),
    );
  }
}

// ─── Tips page ────────────────────────────────────────────────────────────────
class _TipsPage extends StatefulWidget {
  final List<TipModel> tips;
  final VoidCallback onRefresh;
  const _TipsPage({required this.tips, required this.onRefresh});
  @override
  State<_TipsPage> createState() => _TipsPageState();
}

class _TipsPageState extends State<_TipsPage> {
  String _filter = 'All';
  final _filters = ['All', 'Today', 'This week', 'This month'];

  List<TipModel> get _filtered {
    final now = DateTime.now();
    return widget.tips.where((t) {
      if (_filter == 'Today') {
        return t.createdAt.year == now.year &&
            t.createdAt.month == now.month &&
            t.createdAt.day == now.day;
      }
      if (_filter == 'This week') {
        return now.difference(t.createdAt).inDays <= 7;
      }
      if (_filter == 'This month') {
        return t.createdAt.year == now.year && t.createdAt.month == now.month;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final filtered = _filtered;
    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      color: kPrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(w > 900 ? 32 : 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tips received', style: GoogleFonts.inter(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5))
              .animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: _filters.map((f) {
              final active = _filter == f;
              return GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: AnimatedContainer(
                  duration: 150.ms,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? kPrimary : kCardBg,
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(color: active ? Colors.transparent : kBorder),
                  ),
                  child: Text(f, style: GoogleFonts.inter(
                      color: active ? Colors.white : kMuted,
                      fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              );
            }).toList()),
          ),
          const SizedBox(height: 20),
          if (filtered.isEmpty)
            _EmptyTips()
          else
            ...filtered.asMap().entries.map((e) =>
              _TipRow(tip: e.value)
                  .animate().fadeIn(delay: Duration(milliseconds: 40 * e.key), duration: 300.ms)),
        ]),
      ),
    );
  }
}

// ─── Analytics page ───────────────────────────────────────────────────────────
class _AnalyticsPage extends StatelessWidget {
  final DashboardStats stats;
  final List<TipModel> tips;
  const _AnalyticsPage({required this.stats, required this.tips});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final avg = stats.tipCount > 0 ? stats.totalEarned / stats.tipCount : 0.0;
    return SingleChildScrollView(
      padding: EdgeInsets.all(w > 900 ? 32 : 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Analytics', style: GoogleFonts.inter(color: Colors.white,
            fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5))
            .animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 24),
        _WeeklyChart(data: stats.weeklyData, labels: stats.weekLabels),
        const SizedBox(height: 24),
        Wrap(spacing: 14, runSpacing: 14, children: [
          _StatCard('Total earned', 'R${stats.totalEarned.toStringAsFixed(2)}',
              Icons.paid_rounded, kPrimary, 0),
          _StatCard('Avg. tip size', 'R${avg.toStringAsFixed(2)}',
              Icons.trending_up_rounded, const Color(0xFF60A5FA), 60),
          _StatCard('Total tips', '${stats.tipCount}',
              Icons.volunteer_activism, const Color(0xFFF472B6), 120),
          _StatCard('This month', 'R${stats.thisMonthEarned.toStringAsFixed(2)}',
              Icons.calendar_today_rounded, const Color(0xFFFBBF24), 180),
        ]),
        const SizedBox(height: 24),
        Text('Top fans', style: GoogleFonts.inter(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        if (stats.topFans.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text('No tips received yet',
                style: GoogleFonts.inter(color: kMuted, fontSize: 14)),
          )
        else
          ...stats.topFans.asMap().entries.map((e) =>
              _TopFanRow(e.value.name, 'R${e.value.total.toStringAsFixed(2)}', e.key + 1)),
      ]),
    );
  }
}

// ─── Profile page ─────────────────────────────────────────────────────────────
class _ProfilePage extends StatefulWidget {
  final CreatorProfileModel profile;
  final VoidCallback onCopyLink;
  final void Function(CreatorProfileModel) onUpdated;
  const _ProfilePage(
      {required this.profile, required this.onCopyLink, required this.onUpdated});
  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  late CreatorProfileModel _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final tipLink = 'tippingjar.io/u/${_profile.slug}';

    // Profile completion items
    final items = [
      ('Profile tagline', _profile.tagline.isNotEmpty),
      ('Monthly tip goal', _profile.tipGoal != null),
      ('Banking connected', _profile.hasBankConnected),
      ('Share your tip link', false),
    ];
    final done = items.where((i) => i.$2).length;
    final progress = done / items.length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(w > 900 ? 32 : 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Your profile', style: GoogleFonts.inter(color: Colors.white,
            fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5))
            .animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 24),

        // Profile card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: kCardBg,
              borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 64, height: 64,
                decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                child: Center(child: Text(
                  (_profile.displayName.isNotEmpty ? _profile.displayName : _profile.username)[0].toUpperCase(),
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 26),
                )),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_profile.displayName.isNotEmpty ? _profile.displayName : _profile.username,
                    style: GoogleFonts.inter(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 18)),
                Text('@${_profile.slug}',
                    style: GoogleFonts.inter(color: kMuted, fontSize: 13)),
                if (_profile.tagline.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(_profile.tagline,
                      style: GoogleFonts.inter(color: kMuted, fontSize: 12),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ])),
              ElevatedButton(
                onPressed: () => _showEditProfileDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary, foregroundColor: Colors.white,
                  elevation: 0, shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                ),
                child: Text('Edit', style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
              ),
            ]),
            const SizedBox(height: 20),
            const Divider(color: kBorder),
            const SizedBox(height: 16),
            Text('Tip page link', style: GoogleFonts.inter(
                color: kMuted, fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: kDark,
                  borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
              child: Row(children: [
                const Icon(Icons.link_rounded, color: kMuted, size: 16),
                const SizedBox(width: 10),
                Expanded(child: Text(tipLink,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13))),
                GestureDetector(
                  onTap: widget.onCopyLink,
                  child: const Icon(Icons.copy_rounded, color: kMuted, size: 16),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 20),

        // Profile completion
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: kCardBg,
              borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Profile completion', style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              const Spacer(),
              Text('${(progress * 100).round()}%', style: GoogleFonts.inter(
                  color: kPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress, minHeight: 6, backgroundColor: kBorder,
                valueColor: const AlwaysStoppedAnimation<Color>(kPrimary),
              ),
            ),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Icon(item.$2 ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: item.$2 ? kPrimary : kMuted, size: 16),
                const SizedBox(width: 10),
                Text(item.$1, style: GoogleFonts.inter(
                    color: item.$2 ? Colors.white : kMuted, fontSize: 13)),
              ]),
            )),
          ]),
        ),
        const SizedBox(height: 20),

        // Banking details
        _BankingCard(
          profile: _profile,
          onUpdated: (updated) {
            setState(() => _profile = updated);
            widget.onUpdated(updated);
          },
        ),
      ]),
    );
  }

  Future<void> _showEditProfileDialog(BuildContext context) async {
    final nameCtrl = TextEditingController(text: _profile.displayName);
    final taglineCtrl = TextEditingController(text: _profile.tagline);
    final goalCtrl = TextEditingController(
        text: _profile.tipGoal?.toStringAsFixed(0) ?? '');
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit profile', style: GoogleFonts.inter(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
          _DlgField('Display name', nameCtrl, hint: 'Your public name'),
          const SizedBox(height: 14),
          _DlgField('Tagline', taglineCtrl, hint: 'What you create — 80 chars', maxLength: 80),
          const SizedBox(height: 14),
          _DlgField('Monthly goal (R)', goalCtrl,
              hint: '100', keyboardType: TextInputType.number),
        ])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: kMuted)),
          ),
          ElevatedButton(
            onPressed: saving ? null : () async {
              setS(() => saving = true);
              try {
                final api = context.read<AuthProvider>().api;
                final updated = await api.updateMyCreatorProfile({
                  'display_name': nameCtrl.text.trim(),
                  'tagline': taglineCtrl.text.trim(),
                  if (goalCtrl.text.isNotEmpty)
                    'tip_goal': double.tryParse(goalCtrl.text) ?? 0,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() => _profile = updated);
                widget.onUpdated(updated);
              } catch (e) {
                setS(() => saving = false);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
            child: saving
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
          ),
        ],
      )),
    );
  }
}

// ─── Banking details card ─────────────────────────────────────────────────────
class _BankingCard extends StatelessWidget {
  final CreatorProfileModel profile;
  final void Function(CreatorProfileModel) onUpdated;
  const _BankingCard({required this.profile, required this.onUpdated});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kCardBg,
          borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.account_balance_rounded, color: kPrimary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Banking details', style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            Text(profile.hasBankConnected ? 'Connected' : 'Not connected',
                style: GoogleFonts.inter(
                    color: profile.hasBankConnected ? kPrimary : kMuted, fontSize: 12)),
          ])),
          ElevatedButton(
            onPressed: () => _showBankingDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: profile.hasBankConnected
                  ? kCardBg : kPrimary,
              foregroundColor: Colors.white,
              elevation: 0, shadowColor: Colors.transparent,
              side: profile.hasBankConnected
                  ? const BorderSide(color: kBorder) : BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
            ),
            child: Text(profile.hasBankConnected ? 'Edit' : 'Connect',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13,
                    color: profile.hasBankConnected ? Colors.white : Colors.white)),
          ),
        ]),
        if (profile.hasBankConnected) ...[
          const SizedBox(height: 16),
          const Divider(color: kBorder),
          const SizedBox(height: 12),
          _BankRow(Icons.business_rounded, 'Bank', profile.bankName),
          _BankRow(Icons.person_rounded, 'Account holder', profile.bankAccountHolder),
          _BankRow(Icons.credit_card_rounded, 'Account number',
              profile.bankAccountNumberMasked.isEmpty
                  ? '—' : profile.bankAccountNumberMasked),
          _BankRow(Icons.route_rounded, 'Routing / sort code', profile.bankRoutingNumber.isEmpty ? '—' : profile.bankRoutingNumber),
          _BankRow(Icons.account_balance_wallet_rounded, 'Account type',
              profile.bankAccountType == 'savings' ? 'Savings' : 'Checking'),
          _BankRow(Icons.public_rounded, 'Country', profile.bankCountry),
        ],
      ]),
    );
  }

  Future<void> _showBankingDialog(BuildContext context) async {
    final bankNameCtrl = TextEditingController(text: profile.bankName);
    final holderCtrl = TextEditingController(text: profile.bankAccountHolder);
    final accountCtrl = TextEditingController();
    final routingCtrl = TextEditingController(text: profile.bankRoutingNumber);
    String accountType = profile.bankAccountType.isEmpty ? 'checking' : profile.bankAccountType;
    String country = profile.bankCountry.isEmpty ? 'US' : profile.bankCountry;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Banking details', style: GoogleFonts.inter(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        content: SingleChildScrollView(
          child: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.lock_outline_rounded, color: Color(0xFFFBBF24), size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Your banking details are stored securely and used only for payouts.',
                  style: GoogleFonts.inter(color: const Color(0xFFFBBF24), fontSize: 12, height: 1.4),
                )),
              ]),
            ),
            const SizedBox(height: 16),
            _DlgField('Bank name', bankNameCtrl, hint: 'e.g. Chase, Barclays'),
            const SizedBox(height: 12),
            _DlgField('Account holder name', holderCtrl, hint: 'Full legal name'),
            const SizedBox(height: 12),
            _DlgField('Account number', accountCtrl,
                hint: profile.bankAccountNumberMasked.isNotEmpty
                    ? profile.bankAccountNumberMasked
                    : 'Enter account number',
                obscure: true),
            const SizedBox(height: 12),
            _DlgField('Routing / sort code / BSB', routingCtrl,
                hint: 'e.g. 021000021'),
            const SizedBox(height: 12),
            // Account type
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Account type', style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Row(children: [
                _TypeChip('Checking', accountType == 'checking', () => setS(() => accountType = 'checking')),
                const SizedBox(width: 8),
                _TypeChip('Savings', accountType == 'savings', () => setS(() => accountType = 'savings')),
              ]),
            ]),
            const SizedBox(height: 12),
            // Country
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Country', style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: country,
                dropdownColor: kCardBg,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  filled: true, fillColor: kDark,
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kPrimary, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'US', child: Text('United States (USD)')),
                  DropdownMenuItem(value: 'ZA', child: Text('South Africa (ZAR)')),
                  DropdownMenuItem(value: 'GB', child: Text('United Kingdom (GBP)')),
                  DropdownMenuItem(value: 'AU', child: Text('Australia (AUD)')),
                  DropdownMenuItem(value: 'NG', child: Text('Nigeria (NGN)')),
                  DropdownMenuItem(value: 'KE', child: Text('Kenya (KES)')),
                  DropdownMenuItem(value: 'GH', child: Text('Ghana (GHS)')),
                  DropdownMenuItem(value: 'EU', child: Text('Europe (EUR)')),
                  DropdownMenuItem(value: 'CA', child: Text('Canada (CAD)')),
                ],
                onChanged: (v) => setS(() => country = v ?? country),
              ),
            ]),
          ])),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: kMuted)),
          ),
          ElevatedButton(
            onPressed: saving ? null : () async {
              if (bankNameCtrl.text.trim().isEmpty || holderCtrl.text.trim().isEmpty) return;
              setS(() => saving = true);
              try {
                final payload = <String, dynamic>{
                  'bank_name': bankNameCtrl.text.trim(),
                  'bank_account_holder': holderCtrl.text.trim(),
                  'bank_routing_number': routingCtrl.text.trim(),
                  'bank_account_type': accountType,
                  'bank_country': country,
                };
                if (accountCtrl.text.trim().isNotEmpty) {
                  payload['bank_account_number'] = accountCtrl.text.trim();
                }
                final api = context.read<AuthProvider>().api;
                final updated = await api.updateMyCreatorProfile(payload);
                if (ctx.mounted) Navigator.pop(ctx);
                onUpdated(updated);
              } catch (e) {
                setS(() => saving = false);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
            child: saving
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Save details', style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
          ),
        ],
      )),
    );
  }
}

class _BankRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _BankRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Icon(icon, color: kMuted, size: 15),
      const SizedBox(width: 10),
      Text(label, style: GoogleFonts.inter(color: kMuted, fontSize: 13)),
      const Spacer(),
      Text(value, style: GoogleFonts.inter(
          color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
    ]),
  );
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TypeChip(this.label, this.active, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: active ? kPrimary.withValues(alpha: 0.12) : kDark,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: active ? kPrimary : kBorder, width: active ? 2 : 1),
      ),
      child: Text(label, style: GoogleFonts.inter(
          color: active ? kPrimary : kMuted,
          fontWeight: FontWeight.w600, fontSize: 13)),
    ),
  );
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _DlgField extends StatelessWidget {
  final String label, hint;
  final TextEditingController ctrl;
  final bool obscure;
  final int? maxLength;
  final TextInputType? keyboardType;
  const _DlgField(this.label, this.ctrl,
      {required this.hint, this.obscure = false, this.maxLength, this.keyboardType});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.inter(
          color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl,
        obscureText: obscure,
        maxLength: maxLength,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: kMuted, fontSize: 14),
          filled: true, fillColor: kDark,
          counterStyle: GoogleFonts.inter(color: kMuted, fontSize: 11),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimary, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ],
  );
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final int delay;
  const _StatCard(this.label, this.value, this.icon, this.color, this.delay);

  @override
  Widget build(BuildContext context) => Container(
    width: 180,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: kCardBg,
        borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(height: 14),
      Text(value, style: GoogleFonts.inter(
          color: Colors.white, fontWeight: FontWeight.w800,
          fontSize: 20, letterSpacing: -0.5)),
      const SizedBox(height: 3),
      Text(label, style: GoogleFonts.inter(color: kMuted, fontSize: 12)),
    ]),
  ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms).slideY(begin: 0.1);
}

class _TipRow extends StatelessWidget {
  final TipModel tip;
  const _TipRow({required this.tip});

  Color get _avatarColor {
    final colors = [kPrimary, const Color(0xFF60A5FA), const Color(0xFFF472B6),
        const Color(0xFFFBBF24), const Color(0xFF818CF8)];
    return colors[tip.tipperName.length % colors.length];
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: kCardBg,
        borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
            color: _avatarColor.withValues(alpha: 0.15), shape: BoxShape.circle),
        child: Center(child: Text(
          tip.tipperName.isNotEmpty ? tip.tipperName[0].toUpperCase() : 'A',
          style: GoogleFonts.inter(color: _avatarColor, fontWeight: FontWeight.w800, fontSize: 15),
        )),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(tip.tipperName, style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(width: 8),
          Text(tip.relativeTime, style: GoogleFonts.inter(color: kMuted, fontSize: 11)),
        ]),
        if (tip.message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(tip.message, style: GoogleFonts.inter(
                color: kMuted, fontSize: 12, height: 1.4),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
      ])),
      const SizedBox(width: 12),
      Text('R${tip.amount.toStringAsFixed(2)}', style: GoogleFonts.inter(
          color: kPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
    ]),
  );
}

class _WeeklyChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  const _WeeklyChart({required this.data, required this.labels});

  @override
  Widget build(BuildContext context) {
    final total = data.fold(0.0, (a, b) => a + b);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kCardBg,
          borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('This week', style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          const Spacer(),
          Text('R${total.toStringAsFixed(0)} total', style: GoogleFonts.inter(
              color: kPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          height: 120,
          child: CustomPaint(
            size: Size.infinite,
            painter: _BarChartPainter(data: data, labels: labels),
          ),
        ),
      ]),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  _BarChartPainter({required this.data, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = data.reduce(math.max);
    if (maxVal == 0) {
      // Draw empty bars
      final paint = Paint()..color = kPrimary.withValues(alpha: 0.12)..style = PaintingStyle.fill;
      final barW = (size.width / data.length) * 0.5;
      final gap = (size.width / data.length) * 0.5;
      final textH = 18.0;
      for (var i = 0; i < data.length; i++) {
        final x = i * (barW + gap) + gap / 2;
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(x, size.height - textH - 10, barW, 10),
            const Radius.circular(4)), paint);
        final tp = TextPainter(
          text: TextSpan(text: labels[i], style: TextStyle(
              color: kMuted, fontSize: 10, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x + barW / 2 - tp.width / 2, size.height - textH + 4));
      }
      return;
    }
    final barW = (size.width / data.length) * 0.5;
    final gap = (size.width / data.length) * 0.5;
    final textH = 18.0;
    final chartH = size.height - textH;
    for (var i = 0; i < data.length; i++) {
      final x = i * (barW + gap) + gap / 2;
      final barH = math.max((data[i] / maxVal) * chartH * 0.88, data[i] > 0 ? 4.0 : 0.0);
      final y = chartH - barH;
      final paint = Paint()
        ..color = data[i] == maxVal ? kPrimary : kPrimary.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barW, barH), const Radius.circular(4)), paint);
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: TextStyle(
            color: kMuted, fontSize: 10, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + barW / 2 - tp.width / 2, chartH + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) =>
      old.data != data || old.labels != labels;
}

class _TopFanRow extends StatelessWidget {
  final String name, amount;
  final int rank;
  const _TopFanRow(this.name, this.amount, this.rank);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: kCardBg,
        borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
    child: Row(children: [
      Text('#$rank', style: GoogleFonts.inter(
          color: rank <= 3 ? kPrimary : kMuted,
          fontWeight: FontWeight.w800, fontSize: 14)),
      const SizedBox(width: 14),
      Expanded(child: Text(name, style: GoogleFonts.inter(
          color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
      Text(amount, style: GoogleFonts.inter(
          color: kPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
    ]),
  ).animate().fadeIn(delay: Duration(milliseconds: rank * 50), duration: 300.ms);
}

class _PayoutBanner extends StatelessWidget {
  final double pendingPayout;
  const _PayoutBanner({required this.pendingPayout});

  void _showPayoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.account_balance_rounded, color: kPrimary, size: 18),
          ),
          const SizedBox(width: 12),
          Text('Payout Details', style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('R${pendingPayout.toStringAsFixed(2)} is pending payout to your linked bank account.',
              style: GoogleFonts.inter(color: kMuted, fontSize: 13, height: 1.5)),
          const SizedBox(height: 14),
          _payoutRow(Icons.schedule_rounded, 'Arrives in 1–2 business days after Stripe processes your payout.'),
          _payoutRow(Icons.account_balance_rounded, 'Paid directly to the bank account set up in your Profile → Banking Details.'),
          _payoutRow(Icons.info_outline_rounded, 'Payouts are automatic once your balance exceeds R50. No manual action required.'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () { Navigator.of(context).pop(); },
            child: Text('Update banking details in Profile →',
                style: GoogleFonts.inter(
                    color: kPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Got it', style: GoogleFonts.inter(
                color: kPrimary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _payoutRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 14, color: kPrimary),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: GoogleFonts.inter(color: kMuted, fontSize: 12, height: 1.5))),
    ]),
  );

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: kPrimary.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kPrimary.withValues(alpha: 0.25)),
    ),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.account_balance_rounded, color: kPrimary, size: 20),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('R${pendingPayout.toStringAsFixed(2)} pending payout',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        Text('Arrives in your bank in 1-2 business days.',
            style: GoogleFonts.inter(color: kMuted, fontSize: 12)),
      ])),
      const SizedBox(width: 12),
      ElevatedButton(
        onPressed: () => _showPayoutDialog(context),
        style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary, foregroundColor: Colors.white,
            elevation: 0, shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
        child: Text('Request payout', style: GoogleFonts.inter(
            fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white)),
      ),
    ]),
  );
}

class _EmptyTips extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 40),
    alignment: Alignment.center,
    child: Column(children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: const Icon(Icons.volunteer_activism, color: kPrimary, size: 26),
      ),
      const SizedBox(height: 14),
      Text('No tips yet', style: GoogleFonts.inter(
          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 6),
      Text('Share your tip link to start receiving tips.',
          style: GoogleFonts.inter(color: kMuted, fontSize: 13)),
    ]),
  );
}

class _BankCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFFBBF24).withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.25)),
    ),
    child: Row(children: [
      const Icon(Icons.warning_amber_rounded, color: Color(0xFFFBBF24), size: 20),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Connect your bank to receive payouts', style: GoogleFonts.inter(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        Text('Go to Profile → Banking details to add your account.',
            style: GoogleFonts.inter(color: kMuted, fontSize: 12)),
      ])),
    ]),
  );
}

// ─── Jars page ────────────────────────────────────────────────────────────────
class _JarsPage extends StatefulWidget {
  final CreatorProfileModel profile;
  const _JarsPage({required this.profile});
  @override
  State<_JarsPage> createState() => _JarsPageState();
}

class _JarsPageState extends State<_JarsPage> {
  List<JarModel> _jars = [];
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
      final api = context.read<AuthProvider>().api;
      final jars = await api.getMyJars();
      if (mounted) setState(() { _jars = jars; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: kPrimary, backgroundColor: kCardBg,
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _error != null
              ? Center(child: Text(_error!, style: GoogleFonts.inter(color: kMuted)))
              : ListView(
                  padding: const EdgeInsets.all(28),
                  children: [
                    // Header
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Your Jars', style: GoogleFonts.inter(
                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text('Create named jars for campaigns, goals, or specific purposes.',
                            style: GoogleFonts.inter(color: kMuted, fontSize: 13)),
                      ])),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateDialog(context),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text('New jar', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary, foregroundColor: Colors.white,
                          elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 28),

                    if (_jars.isEmpty)
                      _emptyState()
                    else
                      ..._jars.asMap().entries.map((e) =>
                        _JarDashCard(
                          jar: e.value,
                          profileSlug: widget.profile.slug,
                          onEdit: () => _showEditDialog(context, e.value),
                          onDelete: () => _confirmDelete(context, e.value),
                          onCopyLink: () => _copyLink(e.value),
                        ).animate().fadeIn(delay: (e.key * 60).ms, duration: 350.ms)
                      ),
                  ],
                ),
    );
  }

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.savings_rounded, color: kPrimary, size: 32),
        ),
        const SizedBox(height: 20),
        Text('No jars yet', style: GoogleFonts.inter(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 8),
        Text('Create a jar for a campaign, project,\nor any reason you want to collect tips.',
            style: GoogleFonts.inter(color: kMuted, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => _showCreateDialog(context),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: Text('Create your first jar', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
          ),
        ),
      ]),
    ),
  );

  void _copyLink(JarModel jar) {
    final link = 'tippingjar.io/creator/${widget.profile.slug}/jar/${jar.slug}';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Jar link copied!', style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
      backgroundColor: kPrimary, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _confirmDelete(BuildContext context, JarModel jar) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete "${jar.name}"?',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text('This jar will be deactivated. Existing tips will be preserved.',
            style: GoogleFonts.inter(color: kMuted, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.inter(color: kMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
            child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      try {
        await context.read<AuthProvider>().api.deleteJar(jar.id);
        _load();
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete jar')));
      }
    }
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final goalCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (_) => _JarFormDialog(
        title: 'Create a jar',
        nameCtrl: nameCtrl,
        descCtrl: descCtrl,
        goalCtrl: goalCtrl,
        formKey: formKey,
        onSave: () async {
          if (!formKey.currentState!.validate()) return;
          final goal = double.tryParse(goalCtrl.text.trim());
          await context.read<AuthProvider>().api.createJar(
            name: nameCtrl.text.trim(),
            description: descCtrl.text.trim(),
            goal: goal,
          );
          if (mounted) { Navigator.pop(context); _load(); }
        },
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, JarModel jar) async {
    final nameCtrl = TextEditingController(text: jar.name);
    final descCtrl = TextEditingController(text: jar.description);
    final goalCtrl = TextEditingController(text: jar.goal?.toStringAsFixed(0) ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (_) => _JarFormDialog(
        title: 'Edit jar',
        nameCtrl: nameCtrl,
        descCtrl: descCtrl,
        goalCtrl: goalCtrl,
        formKey: formKey,
        onSave: () async {
          if (!formKey.currentState!.validate()) return;
          final goal = double.tryParse(goalCtrl.text.trim());
          await context.read<AuthProvider>().api.updateJar(jar.id, {
            'name': nameCtrl.text.trim(),
            'description': descCtrl.text.trim(),
            'goal': goal,
          });
          if (mounted) { Navigator.pop(context); _load(); }
        },
      ),
    );
  }
}

// ─── Jar dashboard card ───────────────────────────────────────────────────────
class _JarDashCard extends StatelessWidget {
  final JarModel jar;
  final String profileSlug;
  final VoidCallback onEdit, onDelete, onCopyLink;
  const _JarDashCard({
    required this.jar,
    required this.profileSlug,
    required this.onEdit,
    required this.onDelete,
    required this.onCopyLink,
  });

  @override
  Widget build(BuildContext context) {
    final progress = jar.progressPct != null ? jar.progressPct! / 100 : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardBg, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.savings_rounded, color: kPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(jar.name, style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            if (jar.description.isNotEmpty)
              Text(jar.description, style: GoogleFonts.inter(color: kMuted, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          // Actions
          PopupMenuButton<String>(
            color: kCardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: kBorder)),
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'copy') onCopyLink();
              if (v == 'view') context.go('/creator/$profileSlug/jar/${jar.slug}');
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              _menuItem('edit',   Icons.edit_rounded,         'Edit jar',         Colors.white),
              _menuItem('copy',   Icons.link_rounded,          'Copy share link',  Colors.white),
              _menuItem('view',   Icons.open_in_new_rounded,   'View public page', Colors.white),
              _menuItem('delete', Icons.delete_outline_rounded, 'Delete',          Colors.redAccent),
            ],
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: kDark, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.more_horiz_rounded, color: kMuted, size: 18),
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // Stats
        Row(children: [
          _statChip(Icons.favorite_rounded, '${jar.tipCount} tip${jar.tipCount == 1 ? '' : 's'}'),
          const SizedBox(width: 10),
          _statChip(Icons.attach_money_rounded, 'R${jar.totalRaised.toStringAsFixed(0)} raised'),
          if (jar.goal != null) ...[
            const SizedBox(width: 10),
            _statChip(Icons.flag_rounded, 'Goal: R${jar.goal!.toStringAsFixed(0)}'),
          ],
        ]),

        // Progress bar
        if (progress != null) ...[
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Progress', style: GoogleFonts.inter(color: kMuted, fontSize: 11)),
            Text('${jar.progressPct!.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 11)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: kBorder,
              valueColor: const AlwaysStoppedAnimation(kPrimary),
              minHeight: 6,
            ),
          ),
        ],

        const SizedBox(height: 14),
        // Copy link button
        GestureDetector(
          onTap: onCopyLink,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: kPrimary.withOpacity(0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.link_rounded, color: kPrimary, size: 14),
              const SizedBox(width: 6),
              Text('tippingjar.io/creator/$profileSlug/jar/${jar.slug}',
                  style: GoogleFonts.inter(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _statChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
        color: kDark, borderRadius: BorderRadius.circular(36), border: Border.all(color: kBorder)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: kMuted, size: 12),
      const SizedBox(width: 5),
      Text(label, style: GoogleFonts.inter(color: kMuted, fontSize: 11, fontWeight: FontWeight.w500)),
    ]),
  );

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, Color color) =>
      PopupMenuItem(
        value: value,
        child: Row(children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.inter(color: color, fontSize: 13)),
        ]),
      );
}

// ─── Jar create/edit dialog ───────────────────────────────────────────────────
class _JarFormDialog extends StatefulWidget {
  final String title;
  final TextEditingController nameCtrl, descCtrl, goalCtrl;
  final GlobalKey<FormState> formKey;
  final Future<void> Function() onSave;
  const _JarFormDialog({
    required this.title,
    required this.nameCtrl,
    required this.descCtrl,
    required this.goalCtrl,
    required this.formKey,
    required this.onSave,
  });
  @override
  State<_JarFormDialog> createState() => _JarFormDialogState();
}

class _JarFormDialogState extends State<_JarFormDialog> {
  bool _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kCardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: widget.formKey,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.savings_rounded, color: kPrimary, size: 18),
                ),
                const SizedBox(width: 12),
                Text(widget.title, style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: kMuted),
                ),
              ]),
              const SizedBox(height: 24),

              _dialogLabel('Jar name *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: widget.nameCtrl,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                validator: (v) => (v?.trim().length ?? 0) >= 2 ? null : 'Min 2 characters',
                decoration: _deco('e.g. New Laptop Fund'),
              ),
              const SizedBox(height: 16),

              _dialogLabel('Description (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: widget.descCtrl,
                maxLines: 3,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                decoration: _deco('Tell people what this jar is for…'),
              ),
              const SizedBox(height: 16),

              _dialogLabel('Goal amount (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: widget.goalCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                  return null;
                },
                decoration: _deco('e.g. 500').copyWith(prefixText: 'R  ',
                    prefixStyle: GoogleFonts.inter(color: kMuted, fontSize: 14)),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13)),
              ],
              const SizedBox(height: 24),

              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.inter(color: kMuted, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
                    disabledBackgroundColor: kPrimary.withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Save jar', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      await widget.onSave();
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to save. Try again.'; _saving = false; });
    }
  }

  Widget _dialogLabel(String t) => Text(t,
      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13));

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(color: kMuted, fontSize: 14),
    filled: true, fillColor: kDark,
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimary, width: 2)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.withOpacity(0.5))),
    focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
