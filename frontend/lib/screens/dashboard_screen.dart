// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_user.dart';
import '../models/commission_model.dart';
import '../models/creator_post_model.dart';
import '../models/creator_profile_model.dart';
import '../models/dashboard_stats.dart';
import '../models/jar_model.dart';
import '../models/milestone_model.dart';
import '../models/pledge_model.dart';
import '../models/tier_model.dart';
import '../models/tip_model.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';

// ─── Notification model ───────────────────────────────────────────────────────
class _NotifModel {
  final int id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const _NotifModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory _NotifModel.fromJson(Map<String, dynamic> j) => _NotifModel(
        id: j['id'] as int,
        type: j['type'] as String? ?? 'tip_received',
        title: j['title'] as String? ?? '',
        message: j['message'] as String? ?? '',
        isRead: j['is_read'] as bool? ?? false,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

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
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Notifications state
  List<_NotifModel> _notifications = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadNotifications();
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

  Future<void> _loadNotifications() async {
    try {
      final api = context.read<AuthProvider>().api;
      final raw = await api.getNotifications();
      if (mounted) {
        final notifs = raw.map(_NotifModel.fromJson).toList();
        setState(() {
          _notifications = notifs;
          _unreadCount = notifs.where((n) => !n.isRead).length;
        });
      }
    } catch (_) {}
  }

  Future<void> _markNotificationsRead() async {
    if (_unreadCount == 0) return;
    setState(() => _unreadCount = 0);
    try {
      final api = context.read<AuthProvider>().api;
      await api.markNotificationsRead();
      if (mounted) {
        setState(() {
          _notifications = _notifications.map((n) => _NotifModel(
            id: n.id, type: n.type, title: n.title, message: n.message,
            isRead: true, createdAt: n.createdAt,
          )).toList();
        });
      }
    } catch (_) {}
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
      key: _scaffoldKey,
      backgroundColor: kDark,
      appBar: wide ? null : _narrowAppBar(),
      drawer: wide ? null : _mobileDrawer(),
      body: wide ? _wideLayout() : _narrowLayout(),
      bottomNavigationBar: wide ? null : _loading || _error != null ? null : _bottomNav(),
    );
  }

  PreferredSizeWidget _narrowAppBar() => AppBar(
    backgroundColor: kDarker,
    elevation: 0,
    titleSpacing: 0,
    leading: IconButton(
      icon: const Icon(Iconsax.menu_1, color: kMuted, size: 20),
      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
    ),
    title: Row(mainAxisSize: MainAxisSize.min, children: [
      const AppLogoIcon(size: 20),
      const SizedBox(width: 7),
      Text('TippingJar',
          style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: -0.3)),
    ]),
    actions: [
      IconButton(
        icon: Stack(clipBehavior: Clip.none, children: [
          const Icon(Iconsax.notification, color: kMuted, size: 20),
          if (_unreadCount > 0)
            Positioned(
              right: -3, top: -3,
              child: Container(
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                child: Center(child: Text(
                  _unreadCount > 9 ? '9+' : '$_unreadCount',
                  style: GoogleFonts.dmSans(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
                )),
              ),
            ),
        ]),
        tooltip: 'Notifications',
        onPressed: () {
          setState(() => _navIndex = 7);
          _markNotificationsRead();
        },
      ),
      IconButton(
        icon: const Icon(Iconsax.profile_circle, color: kMuted, size: 20),
        tooltip: 'Profile',
        onPressed: () => setState(() => _navIndex = 6),
      ),
    ],
  );

  Widget _wideLayout() => Row(children: [
    _Sidebar(
      selected: _navIndex,
      onSelect: (i) {
        setState(() => _navIndex = i);
        if (i == 7) _markNotificationsRead();
      },
      onLogout: _logout,
      creatorSlug: _data?.profile.slug,
      unreadNotifCount: _unreadCount,
    ),
    Expanded(child: _body()),
  ]);

  Widget _narrowLayout() => _body();

  // Mobile nav shows 5 items; Jars(2) and Monetize(5) are in the drawer
  static const _mobileNavIndices = [0, 1, 3, 4, 6]; // maps mobile tab → _navIndex

  int get _mobileNavCurrentIndex {
    final i = _mobileNavIndices.indexOf(_navIndex);
    return i < 0 ? 0 : i; // fallback for drawer items (2, 5, 7)
  }

  Widget _bottomNav() => NavigationBar(
    selectedIndex: _mobileNavCurrentIndex,
    onDestinationSelected: (i) => setState(() => _navIndex = _mobileNavIndices[i]),
    backgroundColor: kDarker,
    indicatorColor: kPrimary.withValues(alpha: 0.15),
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    height: 64,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    destinations: [
      NavigationDestination(
        icon: const Icon(Iconsax.home_2, size: 20),
        selectedIcon: const Icon(Iconsax.home_25, size: 20, color: kPrimary),
        label: 'Home',
      ),
      NavigationDestination(
        icon: const Icon(Iconsax.money_recive, size: 20),
        selectedIcon: const Icon(Iconsax.money_recive5, size: 20, color: kPrimary),
        label: 'Tips',
      ),
      NavigationDestination(
        icon: const Icon(Iconsax.chart_2, size: 20),
        selectedIcon: const Icon(Iconsax.chart_25, size: 20, color: kPrimary),
        label: 'Analytics',
      ),
      NavigationDestination(
        icon: const Icon(Iconsax.gallery, size: 20),
        selectedIcon: const Icon(Iconsax.gallery5, size: 20, color: kPrimary),
        label: 'Content',
      ),
      NavigationDestination(
        icon: const Icon(Iconsax.profile_circle, size: 20),
        selectedIcon: const Icon(Iconsax.profile_circle5, size: 20, color: kPrimary),
        label: 'Profile',
      ),
    ],
  );

  Widget _mobileDrawer() => Drawer(
    backgroundColor: kDarker,
    child: SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            const AppLogoIcon(size: 28),
            const SizedBox(width: 8),
            Text('TippingJar', style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          ]),
        ),
        const Divider(color: kBorder, height: 1),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Text('NAVIGATION', style: GoogleFonts.dmSans(
              color: kMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
        ),
        _DrawerItem(Iconsax.home_2, 'Overview', _navIndex == 0, () { setState(() => _navIndex = 0); Navigator.pop(context); }),
        _DrawerItem(Iconsax.money_recive, 'Tips', _navIndex == 1, () { setState(() => _navIndex = 1); Navigator.pop(context); }),
        _DrawerItem(Iconsax.bucket_circle, 'Jars', _navIndex == 2, () { setState(() => _navIndex = 2); Navigator.pop(context); }),
        _DrawerItem(Iconsax.chart_2, 'Analytics', _navIndex == 3, () { setState(() => _navIndex = 3); Navigator.pop(context); }),
        _DrawerItem(Iconsax.gallery, 'Content', _navIndex == 4, () { setState(() => _navIndex = 4); Navigator.pop(context); }),
        _DrawerItem(Iconsax.dollar_circle, 'Monetize', _navIndex == 5, () { setState(() => _navIndex = 5); Navigator.pop(context); }),
        _DrawerItem(Iconsax.notification, 'Notifications', _navIndex == 7, () { setState(() => _navIndex = 7); Navigator.pop(context); }),
        const SizedBox(height: 8),
        const Divider(color: kBorder, height: 1),
        const Spacer(),
        if (_data?.profile.slug != null && _data!.profile.slug.isNotEmpty)
          _DrawerItem(Iconsax.export_2, 'View tip page', false, () {
            Navigator.pop(context);
            context.go('/creator/${_data!.profile.slug}');
          }),
        _DrawerItem(Iconsax.logout, 'Sign out', false, _logout, danger: true),
        const SizedBox(height: 12),
      ]),
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
          onNavigateToProfile: () => setState(() => _navIndex = 6),
        ),
      1 => _TipsPage(tips: d.tips, onRefresh: _load),
      2 => _JarsPage(profile: d.profile),
      3 => _AnalyticsPage(stats: d.stats, tips: d.tips),
      4 => _ContentPage(),
      5 => _MonetizePage(creatorSlug: d.profile.slug),
      6 => _ProfilePage(
          profile: d.profile,
          onCopyLink: _copyLink,
          onUpdated: _onProfileUpdated,
          onDeleteAccount: () async {
            await context.read<AuthProvider>().logout();
            if (mounted) context.go('/');
          },
        ),
      7 => _NotificationsPage(
          notifications: _notifications,
          onMarkRead: _markNotificationsRead,
          onRefresh: _loadNotifications,
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
      Text('Failed to load dashboard', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 8),
      Text(_error!, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12), textAlign: TextAlign.center),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: _load,
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: Text('Retry', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white,
            elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
      ),
    ]),
  );

  void _copyLink() {
    final link = 'www.tippingjar.co.za/u/${_data?.profile.slug ?? ''}';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Tip link copied!', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13)),
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
  final int unreadNotifCount;
  const _Sidebar({
    required this.selected, required this.onSelect, required this.onLogout,
    this.creatorSlug, this.unreadNotifCount = 0,
  });

  static const _items = [
    (Iconsax.home_2,        'Overview'),
    (Iconsax.money_recive,  'Tips'),
    (Iconsax.bucket_circle, 'Jars'),
    (Iconsax.chart_2,       'Analytics'),
    (Iconsax.gallery,       'Content'),
    (Iconsax.dollar_circle, 'Monetize'),
    (Iconsax.profile_circle,'Profile'),
    (Iconsax.notification,  'Notifications'),
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
          Text('TippingJar', style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
      ),
      const SizedBox(height: 32),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text('CREATOR', style: GoogleFonts.dmSans(
            color: kMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      ),
      const SizedBox(height: 8),
      ..._items.asMap().entries.map((e) {
        // Notifications item (index 7) gets the unread badge
        final badge = (e.key == 7 && unreadNotifCount > 0) ? unreadNotifCount : 0;
        return _SidebarItem(
          icon: e.value.$1, label: e.value.$2,
          active: selected == e.key, onTap: () => onSelect(e.key),
          badgeCount: badge,
        );
      }),
      const Spacer(),
      const Divider(color: kBorder, height: 1),
      _SidebarItem(
          icon: Iconsax.export_2, label: 'View tip page',
          active: false,
          onTap: () {
            if (creatorSlug != null && creatorSlug!.isNotEmpty) {
              context.go('/creator/$creatorSlug');
            }
          }),
      _SidebarItem(icon: Iconsax.logout, label: 'Sign out',
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
  final int badgeCount;
  const _SidebarItem({required this.icon, required this.label,
      required this.active, required this.onTap, this.danger = false, this.badgeCount = 0});

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
        Expanded(child: Text(label, style: GoogleFonts.dmSans(
            color: active ? kPrimary : danger ? Colors.redAccent : kMuted,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500, fontSize: 13))),
        if (badgeCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(8)),
            child: Text(badgeCount > 9 ? '9+' : '$badgeCount',
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
      ]),
    ),
  );
}

// ─── Drawer item (mobile only) ────────────────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool danger;
  const _DrawerItem(this.icon, this.label, this.active, this.onTap, {this.danger = false});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: active ? kPrimary : danger ? Colors.redAccent : kMuted, size: 20),
    title: Text(label, style: GoogleFonts.dmSans(
        color: active ? kPrimary : danger ? Colors.redAccent : kMuted,
        fontWeight: active ? FontWeight.w600 : FontWeight.w500, fontSize: 14)),
    tileColor: active ? kPrimary.withValues(alpha: 0.08) : Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    dense: true,
    onTap: onTap,
  );
}

// ─── Overview page ────────────────────────────────────────────────────────────
class _OverviewPage extends StatelessWidget {
  final CreatorProfileModel profile;
  final DashboardStats stats;
  final List<TipModel> tips;
  final VoidCallback onCopyLink, onRefresh;
  final VoidCallback onNavigateToProfile;
  const _OverviewPage({required this.profile, required this.stats,
      required this.tips, required this.onCopyLink, required this.onRefresh,
      required this.onNavigateToProfile});

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
              Text('$greeting 👋', style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
              Text(profile.displayName.isEmpty ? profile.username : profile.displayName,
                  style: GoogleFonts.dmSans(color: Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5)),
            ]),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: onCopyLink,
              icon: const Icon(Icons.link_rounded, size: 16, color: Colors.white),
              label: Text('Share tip link', style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary, foregroundColor: Colors.white,
                elevation: 0, shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
              ),
            ),
          ]).animate().fadeIn(duration: 400.ms),

          // Bank warning — shown immediately below greeting when not connected
          if (!profile.hasBankConnected) ...[
            const SizedBox(height: 16),
            _BankWarningBanner(onConnect: onNavigateToProfile)
                .animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: -0.1),
          ],
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

          // QR code — scan & pay
          _QrCodeCard(slug: profile.slug),
          const SizedBox(height: 28),

          // Recent tips
          Row(children: [
            Text('Recent tips', style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            const Spacer(),
            if (tips.isEmpty)
              Text('No tips yet', style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
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

  void _exportCsv() {
    final tips = _filtered;
    if (tips.isEmpty) return;
    final buf = StringBuffer('Date,Tipper,Amount (R),Message\n');
    for (final t in tips) {
      final date = DateFormat('yyyy-MM-dd HH:mm').format(t.createdAt);
      final tipper = t.tipperName.replaceAll('"', '""');
      final msg = t.message.replaceAll('"', '""');
      buf.write('"$date","$tipper",${t.amount.toStringAsFixed(2)},"$msg"\n');
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('CSV copied to clipboard — paste into a spreadsheet',
          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13)),
      backgroundColor: kPrimary, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
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
          Row(children: [
            Expanded(child: Text('Tips received', style: GoogleFonts.dmSans(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5))
                .animate().fadeIn(duration: 400.ms)),
            if (filtered.isNotEmpty)
              OutlinedButton.icon(
                onPressed: _exportCsv,
                icon: const Icon(Iconsax.document_download, size: 15),
                label: Text('Export CSV', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kMuted,
                  side: const BorderSide(color: kBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                ),
              ),
          ]),
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
                  child: Text(f, style: GoogleFonts.dmSans(
                      color: active ? Colors.white : kMuted,
                      fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              );
            }).toList()),
          ),
          const SizedBox(height: 20),
          if (filtered.isEmpty)
            _EmptyTips()
          else ...[
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kBorder)),
              child: Row(children: [
                Expanded(flex: 2, child: Text('Tipper', style: GoogleFonts.dmSans(
                    color: kMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
                Expanded(flex: 2, child: Text('Date', style: GoogleFonts.dmSans(
                    color: kMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
                Expanded(child: Text('Amount', textAlign: TextAlign.right, style: GoogleFonts.dmSans(
                    color: kMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
              ]),
            ),
            const SizedBox(height: 6),
            ...filtered.asMap().entries.map((e) =>
              _TipRow(tip: e.value)
                  .animate().fadeIn(delay: Duration(milliseconds: 40 * e.key), duration: 300.ms)),
            const SizedBox(height: 12),
            Text('${filtered.length} tip${filtered.length != 1 ? 's' : ''} · '
                'Total: R${filtered.fold(0.0, (s, t) => s + t.amount).toStringAsFixed(2)}',
                style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
          ],
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
        Text('Analytics', style: GoogleFonts.dmSans(color: Colors.white,
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
        Text('Top fans', style: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        if (stats.topFans.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text('No tips received yet',
                style: GoogleFonts.dmSans(color: kMuted, fontSize: 14)),
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
  final Future<void> Function() onDeleteAccount;
  const _ProfilePage(
      {required this.profile, required this.onCopyLink, required this.onUpdated,
       required this.onDeleteAccount});
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
  void didUpdateWidget(_ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      setState(() => _profile = widget.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final tipLink = 'www.tippingjar.co.za/u/${_profile.slug}';

    // Profile completion items
    final items = [
      ('Profile tagline', _profile.tagline.isNotEmpty),
      ('Monthly tip goal', _profile.tipGoal != null),
      ('Banking connected', _profile.hasBankConnected),
      ('Share your tip link', true),
    ];
    final done = items.where((i) => i.$2).length;
    final progress = done / items.length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(w > 900 ? 32 : 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Your profile', style: GoogleFonts.dmSans(color: Colors.white,
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
                  style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 26),
                )),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_profile.displayName.isNotEmpty ? _profile.displayName : _profile.username,
                    style: GoogleFonts.dmSans(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 18)),
                Text('@${_profile.slug}',
                    style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
                if (_profile.tagline.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(_profile.tagline,
                      style: GoogleFonts.dmSans(color: kMuted, fontSize: 12),
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
                child: Text('Edit', style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
              ),
            ]),
            const SizedBox(height: 20),
            const Divider(color: kBorder),
            const SizedBox(height: 16),
            Text('Tip page link', style: GoogleFonts.dmSans(
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
                    style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13))),
                GestureDetector(
                  onTap: widget.onCopyLink,
                  child: const Icon(Icons.copy_rounded, color: kMuted, size: 16),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 20),

        // QR code — scan & pay
        _QrCodeCard(slug: _profile.slug),
        const SizedBox(height: 20),

        // Profile completion
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: kCardBg,
              borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Profile completion', style: GoogleFonts.dmSans(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              const Spacer(),
              Text('${(progress * 100).round()}%', style: GoogleFonts.dmSans(
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
                Text(item.$1, style: GoogleFonts.dmSans(
                    color: item.$2 ? Colors.white : kMuted, fontSize: 13)),
              ]),
            )),
          ]),
        ),
        const SizedBox(height: 20),

        // Basic information (gender, DOB)
        const _BasicInfoCard(),
        const SizedBox(height: 20),

        // Creator info (niche, platforms, audience)
        _CreatorInfoCard(
          profile: _profile,
          onUpdated: (updated) {
            setState(() => _profile = updated);
            widget.onUpdated(updated);
          },
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
        const SizedBox(height: 20),

        // KYC documents
        _KycDocumentsCard(
          profile: _profile,
          onUpdated: (updated) {
            setState(() => _profile = updated);
            widget.onUpdated(updated);
          },
        ),
        const SizedBox(height: 20),

        // Security settings
        const _SecurityCard(),
        const SizedBox(height: 20),

        // Creator badge
        _BadgeCard(totalEarned: _profile.totalTips),
        const SizedBox(height: 20),

        // Settings
        _SettingsCard(),
        const SizedBox(height: 20),

        // Danger zone (delete account)
        _DangerZoneCard(onDeleteAccount: widget.onDeleteAccount),
        const SizedBox(height: 40),
      ]),
    );
  }

  Future<void> _showEditProfileDialog(BuildContext context) async {
    final nameCtrl = TextEditingController(text: _profile.displayName);
    final taglineCtrl = TextEditingController(text: _profile.tagline);
    final goalCtrl = TextEditingController(
        text: _profile.tipGoal?.toStringAsFixed(0) ?? '');
    final thankYouCtrl = TextEditingController(text: _profile.thankYouMessage);
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit profile', style: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        content: SingleChildScrollView(
          child: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
            _DlgField('Display name', nameCtrl, hint: 'Your public name',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (RegExp(r'[0-9]').hasMatch(v)) return 'Name cannot contain numbers';
                  return null;
                }),
            const SizedBox(height: 14),
            _DlgField('Tagline', taglineCtrl, hint: 'What you create — 80 chars', maxLength: 80),
            const SizedBox(height: 14),
            _DlgField('Monthly goal (R)', goalCtrl,
                hint: '100', keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            const SizedBox(height: 14),
            _DlgField('Thank-you message', thankYouCtrl,
                hint: 'Message sent to tippers after a successful tip',
                maxLines: 3, maxLength: 300),
          ])),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: kMuted)),
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
                  'thank_you_message': thankYouCtrl.text.trim(),
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
                : Text('Save', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
          ),
        ],
      )),
    );
  }
}

// ─── SA Banks list ─────────────────────────────────────────────────────────────
const _saBanks = [
  ('ABSA Bank',                 '632005'),
  ('African Bank',              '430000'),
  ('Bidvest Bank',              '462005'),
  ('Capitec Bank',              '470010'),
  ('Discovery Bank',            '679000'),
  ('FNB (First National Bank)', '250655'),
  ('Investec Bank',             '580105'),
  ('Mercantile Bank',           '450905'),
  ('Nedbank',                   '198765'),
  ('Old Mutual Bank',           '462005'),
  ('PostBank',                  '460005'),
  ('Standard Bank',             '051001'),
  ('TymeBank',                  '678910'),
];

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
            Text('Banking details', style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            Text(profile.hasBankConnected ? 'Connected' : 'Not connected',
                style: GoogleFonts.dmSans(
                    color: profile.hasBankConnected ? kPrimary : kMuted, fontSize: 12)),
          ])),
          ElevatedButton(
            onPressed: () => _showBankingDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: profile.hasBankConnected ? kCardBg : kPrimary,
              foregroundColor: Colors.white, elevation: 0,
              side: profile.hasBankConnected ? const BorderSide(color: kBorder) : BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
            ),
            child: Text(profile.hasBankConnected ? 'Edit' : 'Connect',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
          ),
        ]),
        if (profile.hasBankConnected) ...[
          const SizedBox(height: 16),
          const Divider(color: kBorder),
          const SizedBox(height: 12),
          _BankRow(Icons.business_rounded, 'Bank', profile.bankName),
          _BankRow(Icons.person_rounded, 'Account holder', profile.bankAccountHolder),
          _BankRow(Icons.credit_card_rounded, 'Account number',
              profile.bankAccountNumberMasked.isEmpty ? '—' : profile.bankAccountNumberMasked),
          _BankRow(Icons.account_balance_wallet_rounded, 'Account type',
              profile.bankAccountType == 'savings' ? 'Savings' : 'Cheque / Current'),
          _BankRow(Icons.public_rounded, 'Country', 'South Africa (ZAR)'),
        ],
      ]),
    );
  }

  Future<void> _showBankingDialog(BuildContext context) async {
    // Find current bank in _saBanks list, or default to first
    final currentBankName = profile.bankName;
    String selectedBank = _saBanks.any((b) => b.$1 == currentBankName)
        ? currentBankName
        : _saBanks[0].$1;
    String selectedBankCode = _saBanks.firstWhere(
        (b) => b.$1 == selectedBank, orElse: () => _saBanks[0]).$2;

    final holderCtrl = TextEditingController(text: profile.bankAccountHolder);
    final accountCtrl = TextEditingController();
    String accountType = profile.bankAccountType.isEmpty ? 'cheque' : profile.bankAccountType;
    bool saving = false;
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Banking details', style: GoogleFonts.dmSans(
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
                  style: GoogleFonts.dmSans(color: const Color(0xFFFBBF24), fontSize: 12, height: 1.4),
                )),
              ]),
            ),
            const SizedBox(height: 16),
            // Bank selector
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bank', style: GoogleFonts.dmSans(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedBank,
                dropdownColor: kCardBg,
                isExpanded: true,
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  filled: true, fillColor: kDark,
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kPrimary, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: _saBanks.map((b) => DropdownMenuItem(
                  value: b.$1,
                  child: Text(b.$1, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14)),
                )).toList(),
                onChanged: (v) => setS(() {
                  selectedBank = v ?? selectedBank;
                  selectedBankCode = _saBanks.firstWhere((b) => b.$1 == selectedBank).$2;
                }),
              ),
            ]),
            const SizedBox(height: 12),
            _DlgField('Account holder name', holderCtrl, hint: 'Full legal name',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (RegExp(r'[0-9]').hasMatch(v)) return 'Name cannot contain numbers';
                  return null;
                }),
            const SizedBox(height: 12),
            _DlgField('Account number', accountCtrl,
                hint: profile.bankAccountNumberMasked.isNotEmpty
                    ? profile.bankAccountNumberMasked
                    : 'Enter account number',
                obscure: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            const SizedBox(height: 12),
            // Account type
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Account type', style: GoogleFonts.dmSans(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Row(children: [
                _TypeChip('Cheque / Current', accountType == 'cheque', () => setS(() => accountType = 'cheque')),
                const SizedBox(width: 8),
                _TypeChip('Savings', accountType == 'savings', () => setS(() => accountType = 'savings')),
              ]),
            ]),
            const SizedBox(height: 12),
            // Country — locked to South Africa
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kDark, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: Row(children: [
                const Icon(Icons.public_rounded, color: kMuted, size: 16),
                const SizedBox(width: 10),
                Text('South Africa (ZAR)', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14)),
                const Spacer(),
                Text('Locked', style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
              ]),
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error!, style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 12)),
            ],
          ])),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: kMuted)),
          ),
          ElevatedButton(
            onPressed: saving ? null : () async {
              if (holderCtrl.text.trim().isEmpty) {
                setS(() => error = 'Account holder name is required.');
                return;
              }
              if (accountCtrl.text.trim().isEmpty && !profile.hasBankConnected) {
                setS(() => error = 'Account number is required.');
                return;
              }
              setS(() { saving = true; error = null; });
              try {
                final payload = <String, dynamic>{
                  'bank_name': selectedBank,
                  'bank_account_holder': holderCtrl.text.trim(),
                  'bank_routing_number': selectedBankCode,
                  'bank_account_type': accountType,
                  'bank_country': 'ZA',
                };
                if (accountCtrl.text.trim().isNotEmpty) {
                  payload['bank_account_number'] = accountCtrl.text.trim();
                }
                final api = context.read<AuthProvider>().api;
                final updated = await api.updateMyCreatorProfile(payload);
                if (ctx.mounted) Navigator.pop(ctx);
                onUpdated(updated);
              } catch (e) {
                setS(() { saving = false; error = e.toString().replaceFirst('Exception: ', ''); });
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
            child: saving
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Save details', style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
          ),
        ],
      )),
    );
  }
}

// ─── Basic info card (gender, DOB) ────────────────────────────────────────────
class _BasicInfoCard extends StatefulWidget {
  const _BasicInfoCard();
  @override
  State<_BasicInfoCard> createState() => _BasicInfoCardState();
}

class _BasicInfoCardState extends State<_BasicInfoCard> {
  AppUser? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final u = await context.read<AuthProvider>().api.getMe();
      if (mounted) setState(() { _user = u; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kCardBg,
          borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.person_outline_rounded, color: kPrimary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('Basic information', style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
          ElevatedButton(
            onPressed: _loading || _user == null ? null : () => _showEditDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: kCardBg, foregroundColor: Colors.white, elevation: 0,
              side: const BorderSide(color: kBorder),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
            ),
            child: Text('Edit', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
          ),
        ]),
        if (_loading)
          const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator(color: kPrimary))
        else if (_user != null) ...[
          const SizedBox(height: 16),
          const Divider(color: kBorder),
          const SizedBox(height: 12),
          _BankRow(Icons.wc_rounded, 'Gender', _genderLabel(_user!.gender)),
          _BankRow(Icons.cake_rounded, 'Date of birth',
              _user!.dateOfBirth?.isNotEmpty == true ? _user!.dateOfBirth! : '—'),
          _BankRow(Icons.email_outlined, 'Email', _user!.email),
          _BankRow(Icons.phone_outlined, 'Phone',
              _user!.phoneNumber.isNotEmpty ? _user!.phoneNumber : '—'),
        ],
      ]),
    );
  }

  String _genderLabel(String g) {
    const map = {
      'male': 'Male', 'female': 'Female',
      'non_binary': 'Non-binary', 'prefer_not_to_say': 'Prefer not to say',
    };
    return map[g] ?? '—';
  }

  Future<void> _showEditDialog(BuildContext context) async {
    String gender = _user!.gender;
    final dobCtrl = TextEditingController(text: _user!.dateOfBirth ?? '');
    bool saving = false;
    String? error;

    const genders = [
      ('', 'Select…'),
      ('male', 'Male'),
      ('female', 'Female'),
      ('non_binary', 'Non-binary'),
      ('prefer_not_to_say', 'Prefer not to say'),
    ];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Basic information', style: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        content: SizedBox(width: 380, child: Column(mainAxisSize: MainAxisSize.min, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Gender', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: gender.isEmpty ? '' : gender,
              dropdownColor: kCardBg,
              isExpanded: true,
              style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true, fillColor: kDark,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kPrimary, width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: genders.map((g) => DropdownMenuItem(
                value: g.$1,
                child: Text(g.$2, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14)),
              )).toList(),
              onChanged: (v) => setS(() => gender = v ?? gender),
            ),
          ]),
          const SizedBox(height: 14),
          _DlgField('Date of birth', dobCtrl, hint: 'YYYY-MM-DD', keyboardType: TextInputType.datetime),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(error!, style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 12)),
          ],
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.dmSans(color: kMuted))),
          ElevatedButton(
            onPressed: saving ? null : () async {
              setS(() { saving = true; error = null; });
              try {
                final api = context.read<AuthProvider>().api;
                final payload = <String, dynamic>{};
                if (gender.isNotEmpty) payload['gender'] = gender;
                if (dobCtrl.text.trim().isNotEmpty) payload['date_of_birth'] = dobCtrl.text.trim();
                await api.updateUserProfile(payload);
                await _load();
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                setS(() { saving = false; error = e.toString().replaceFirst('Exception: ', ''); });
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
            child: saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Save', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
          ),
        ],
      )),
    );
  }
}

// ─── Creator info card (niche, platforms, audience) ───────────────────────────
class _CreatorInfoCard extends StatelessWidget {
  final CreatorProfileModel profile;
  final void Function(CreatorProfileModel) onUpdated;
  const _CreatorInfoCard({required this.profile, required this.onUpdated});

  @override
  Widget build(BuildContext context) {
    final niches = ['Music','Comedy','Fitness','Art','Gaming','Food','Tech','Lifestyle','Education','Fashion'];
    final audienceSizes = ['<1K','1K–10K','10K–50K','50K–100K','100K–500K','500K+'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kCardBg,
          borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.star_outline_rounded, color: kPrimary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('Creator info', style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
          ElevatedButton(
            onPressed: () => _showEditDialog(context, niches, audienceSizes),
            style: ElevatedButton.styleFrom(
              backgroundColor: kCardBg, foregroundColor: Colors.white, elevation: 0,
              side: const BorderSide(color: kBorder),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
            ),
            child: Text('Edit', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
          ),
        ]),
        const SizedBox(height: 16),
        const Divider(color: kBorder),
        const SizedBox(height: 12),
        _BankRow(Icons.category_outlined, 'Niche / Category', profile.category.isEmpty ? '—' : profile.category),
        _BankRow(Icons.people_outline_rounded, 'Audience size', profile.audienceSize.isEmpty ? '—' : profile.audienceSize),
        _BankRow(Icons.cake_outlined, 'Content age group', profile.ageGroup.isEmpty ? '—' : profile.ageGroup),
        _BankRow(Icons.wc_rounded, 'Audience gender', profile.audienceGender.isEmpty ? '—' : profile.audienceGender),
        if (profile.platforms.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.link_rounded, color: kMuted, size: 15),
            const SizedBox(width: 10),
            Text('Platforms', style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
            const Spacer(),
            Flexible(child: Text(profile.platforms, style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                textAlign: TextAlign.right)),
          ]),
        ],
      ]),
    );
  }

  Future<void> _showEditDialog(BuildContext context, List<String> niches, List<String> audienceSizes) async {
    String niche = profile.category;
    String audienceSize = profile.audienceSize;
    String ageGroup = profile.ageGroup;
    String audienceGender = profile.audienceGender;
    final platformsCtrl = TextEditingController(text: profile.platforms);
    bool saving = false;
    String? error;

    const ageGroups = ['Under 13','13–17','18–24','25–34','35–44','45+','All ages'];
    const genders = ['Mostly female','Mostly male','Both equally','Prefer not to say'];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Creator info', style: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        content: SingleChildScrollView(
          child: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Niche / Category', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: niches.map((n) {
              final active = niche == n;
              return GestureDetector(
                onTap: () => setS(() => niche = active ? '' : n),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? kPrimary.withValues(alpha: 0.12) : kDark,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: active ? kPrimary : kBorder, width: active ? 2 : 1),
                  ),
                  child: Text(n, style: GoogleFonts.dmSans(
                      color: active ? kPrimary : kMuted, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              );
            }).toList()),
            const SizedBox(height: 16),
            Text('Audience size', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: audienceSizes.map((s) {
              final active = audienceSize == s;
              return GestureDetector(
                onTap: () => setS(() => audienceSize = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? kPrimary.withValues(alpha: 0.12) : kDark,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: active ? kPrimary : kBorder, width: active ? 2 : 1),
                  ),
                  child: Text(s, style: GoogleFonts.dmSans(
                      color: active ? kPrimary : kMuted, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              );
            }).toList()),
            const SizedBox(height: 16),
            Text('Content age group', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: ageGroups.map((a) {
              final active = ageGroup == a;
              return GestureDetector(
                onTap: () => setS(() => ageGroup = a),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? kPrimary.withValues(alpha: 0.12) : kDark,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: active ? kPrimary : kBorder, width: active ? 2 : 1),
                  ),
                  child: Text(a, style: GoogleFonts.dmSans(
                      color: active ? kPrimary : kMuted, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              );
            }).toList()),
            const SizedBox(height: 16),
            Text('Audience gender', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: genders.map((g) {
              final active = audienceGender == g;
              return GestureDetector(
                onTap: () => setS(() => audienceGender = g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? kPrimary.withValues(alpha: 0.12) : kDark,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: active ? kPrimary : kBorder, width: active ? 2 : 1),
                  ),
                  child: Text(g, style: GoogleFonts.dmSans(
                      color: active ? kPrimary : kMuted, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              );
            }).toList()),
            const SizedBox(height: 16),
            _DlgField('Platforms (comma-separated)', platformsCtrl, hint: 'YouTube, TikTok, Instagram'),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error!, style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 12)),
            ],
          ])),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.dmSans(color: kMuted))),
          ElevatedButton(
            onPressed: saving ? null : () async {
              setS(() { saving = true; error = null; });
              try {
                final api = context.read<AuthProvider>().api;
                final updated = await api.updateMyCreatorProfile({
                  'category': niche,
                  'audience_size': audienceSize,
                  'age_group': ageGroup,
                  'audience_gender': audienceGender,
                  'platforms': platformsCtrl.text.trim(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                onUpdated(updated);
              } catch (e) {
                setS(() { saving = false; error = e.toString().replaceFirst('Exception: ', ''); });
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
            child: saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Save', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
          ),
        ],
      )),
    );
  }
}

// ─── KYC Documents card ───────────────────────────────────────────────────────
class _KycDocumentsCard extends StatefulWidget {
  final CreatorProfileModel profile;
  final void Function(CreatorProfileModel) onUpdated;
  const _KycDocumentsCard({required this.profile, required this.onUpdated});
  @override
  State<_KycDocumentsCard> createState() => _KycDocumentsCardState();
}

class _KycDocumentsCardState extends State<_KycDocumentsCard> {
  static const _docTypes = [
    ('national_id',      'SA ID Book / Smart Card', Icons.badge_rounded),
    ('passport',         'Passport', Icons.menu_book_rounded),
    ('proof_of_bank',    'Proof of Bank Account', Icons.account_balance_rounded),
    ('proof_of_address', 'Proof of Address', Icons.home_rounded),
    ('selfie',           'Selfie with ID', Icons.camera_alt_rounded),
  ];

  final _uploading = <String, bool>{};

  @override
  Widget build(BuildContext context) {
    final kyc = widget.profile;
    final docs = kyc.kycDocuments;

    // Headline status chip
    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    switch (kyc.kycStatus) {
      case 'approved':
        statusColor = const Color(0xFF22C55E);
        statusIcon = Icons.verified_rounded;
        statusLabel = 'Verified';
        break;
      case 'pending':
        statusColor = const Color(0xFFFBBF24);
        statusIcon = Icons.hourglass_top_rounded;
        statusLabel = 'Under review';
        break;
      case 'declined':
        statusColor = Colors.redAccent;
        statusIcon = Icons.cancel_rounded;
        statusLabel = 'Declined';
        break;
      default:
        statusColor = kMuted;
        statusIcon = Icons.upload_file_rounded;
        statusLabel = 'Not started';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kCardBg,
          borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
            child: Icon(statusIcon, color: statusColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Identity verification (KYC)', style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            Text(statusLabel, style: GoogleFonts.dmSans(color: statusColor, fontSize: 12)),
          ])),
        ]),

        // Decline reason banner
        if (kyc.kycStatus == 'declined' && kyc.kycDeclineReason.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 14),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Reason: ${kyc.kycDeclineReason}',
                style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 12, height: 1.4),
              )),
            ]),
          ),
        ],

        const SizedBox(height: 16),
        const Divider(color: kBorder),
        const SizedBox(height: 12),

        Text('Upload documents below. At least your SA ID and proof of bank account are required.',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 12, height: 1.5)),
        const SizedBox(height: 16),

        ..._docTypes.map((dt) {
          final docType = dt.$1;
          final label = dt.$2;
          final icon = dt.$3;
          final existing = docs.where((d) => d.docType == docType).firstOrNull;
          final isUploading = _uploading[docType] == true;

          Color chipColor;
          String chipLabel;
          if (existing != null) {
            switch (existing.status) {
              case 'approved':
                chipColor = const Color(0xFF22C55E);
                chipLabel = 'Approved';
                break;
              case 'declined':
                chipColor = Colors.redAccent;
                chipLabel = 'Declined — re-upload';
                break;
              default:
                chipColor = const Color(0xFFFBBF24);
                chipLabel = 'Pending review';
            }
          } else {
            chipColor = kMuted;
            chipLabel = 'Not uploaded';
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Icon(icon, color: kMuted, size: 18),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                if (existing?.declineReason.isNotEmpty == true)
                  Text(existing!.declineReason, style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 11)),
              ])),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: chipColor.withValues(alpha: 0.4)),
                ),
                child: Text(chipLabel, style: GoogleFonts.dmSans(color: chipColor, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              // Upload/re-upload button — hide if approved
              if (existing?.status != 'approved')
                GestureDetector(
                  onTap: isUploading ? null : () => _pickAndUpload(docType),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8)),
                    child: isUploading
                        ? const Padding(padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2))
                        : const Icon(Icons.upload_rounded, color: kPrimary, size: 16),
                  ),
                ),
            ]),
          );
        }),
      ]),
    );
  }

  Future<void> _pickAndUpload(String docType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    final file = result.files.single;

    setState(() => _uploading[docType] = true);
    try {
      final api = context.read<AuthProvider>().api;
      await api.uploadKycDocument(docType, file.bytes!, file.name);
      // Reload profile to get updated KYC docs
      final updated = await api.getMyCreatorProfile();
      widget.onUpdated(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed: ${e.toString().replaceFirst('Exception: ', '')}',
              style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _uploading[docType] = false);
    }
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
      Text(label, style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
      const Spacer(),
      Text(value, style: GoogleFonts.dmSans(
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
      child: Text(label, style: GoogleFonts.dmSans(
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
  final int? maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  const _DlgField(this.label, this.ctrl,
      {required this.hint, this.obscure = false, this.maxLength, this.maxLines,
       this.keyboardType, this.inputFormatters, this.validator});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.dmSans(
          color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl,
        obscureText: obscure,
        maxLength: maxLength,
        maxLines: maxLines ?? 1,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 14),
          filled: true, fillColor: kDark,
          counterStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 11),
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
      Text(value, style: GoogleFonts.dmSans(
          color: Colors.white, fontWeight: FontWeight.w800,
          fontSize: 20, letterSpacing: -0.5)),
      const SizedBox(height: 3),
      Text(label, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
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
          style: GoogleFonts.dmSans(color: _avatarColor, fontWeight: FontWeight.w800, fontSize: 15),
        )),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(tip.tipperName, style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(width: 8),
          Text(tip.relativeTime, style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
        ]),
        if (tip.message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(tip.message, style: GoogleFonts.dmSans(
                color: kMuted, fontSize: 12, height: 1.4),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
      ])),
      const SizedBox(width: 12),
      Text('R${tip.amount.toStringAsFixed(2)}', style: GoogleFonts.dmSans(
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
          Text('This week', style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          const Spacer(),
          Text('R${total.toStringAsFixed(0)} total', style: GoogleFonts.dmSans(
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
          textDirection: ui.TextDirection.ltr,
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
        textDirection: ui.TextDirection.ltr,
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
      Text('#$rank', style: GoogleFonts.dmSans(
          color: rank <= 3 ? kPrimary : kMuted,
          fontWeight: FontWeight.w800, fontSize: 14)),
      const SizedBox(width: 14),
      Expanded(child: Text(name, style: GoogleFonts.dmSans(
          color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
      Text(amount, style: GoogleFonts.dmSans(
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
          Text('Payout Details', style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('R${pendingPayout.toStringAsFixed(2)} is pending payout to your linked bank account.',
              style: GoogleFonts.dmSans(color: kMuted, fontSize: 13, height: 1.5)),
          const SizedBox(height: 14),
          _payoutRow(Icons.schedule_rounded, 'Arrives in 1–2 business days after Stripe processes your payout.'),
          _payoutRow(Icons.account_balance_rounded, 'Paid directly to the bank account set up in your Profile → Banking Details.'),
          _payoutRow(Icons.info_outline_rounded, 'Payouts are automatic once your balance exceeds R50. No manual action required.'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () { Navigator.of(context).pop(); },
            child: Text('Update banking details in Profile →',
                style: GoogleFonts.dmSans(
                    color: kPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Got it', style: GoogleFonts.dmSans(
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
      Expanded(child: Text(text, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12, height: 1.5))),
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
            style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        Text('Arrives in your bank in 1-2 business days.',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
      ])),
      const SizedBox(width: 12),
      ElevatedButton(
        onPressed: () => _showPayoutDialog(context),
        style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary, foregroundColor: Colors.white,
            elevation: 0, shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
        child: Text('Request payout', style: GoogleFonts.dmSans(
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
      Text('No tips yet', style: GoogleFonts.dmSans(
          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 6),
      Text('Share your tip link to start receiving tips.',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
    ]),
  );
}

class _BankWarningBanner extends StatelessWidget {
  final VoidCallback onConnect;
  const _BankWarningBanner({required this.onConnect});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: BoxDecoration(
      color: const Color(0xFFFBBF24).withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.warning_amber_rounded, color: Color(0xFFFBBF24), size: 20),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Connect your bank to receive payouts', style: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        Text('Add your banking details so we can pay you out.',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
      ])),
      const SizedBox(width: 12),
      GestureDetector(
        onTap: onConnect,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFBBF24),
            borderRadius: BorderRadius.circular(36),
          ),
          child: Text('Connect now', style: GoogleFonts.dmSans(
              color: const Color(0xFF1A1A1A), fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ),
    ]),
  );
}

// ─── Content page ─────────────────────────────────────────────────────────────
class _ContentPage extends StatefulWidget {
  @override
  State<_ContentPage> createState() => _ContentPageState();
}

class _ContentPageState extends State<_ContentPage> {
  List<CreatorPostModel> _posts = [];
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
      final posts = await context.read<AuthProvider>().api.getMyPosts();
      if (mounted) setState(() { _posts = posts; _loading = false; });
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
              ? Center(child: Text(_error!, style: GoogleFonts.dmSans(color: kMuted)))
              : ListView(
                  padding: const EdgeInsets.all(28),
                  children: [
                    // Header
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Exclusive Content', style: GoogleFonts.dmSans(
                            color: Colors.white, fontWeight: FontWeight.w800,
                            fontSize: 22, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text('Only tippers who have sent you money can unlock these posts.',
                            style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
                      ])),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showPostDialog(context),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text('New post', style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary, foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 28),

                    if (_posts.isEmpty)
                      _emptyState()
                    else
                      ..._posts.asMap().entries.map((e) =>
                        _PostCard(
                          post: e.value,
                          onEdit: () => _showPostDialog(context, post: e.value),
                          onDelete: () => _confirmDelete(context, e.value),
                        ).animate().fadeIn(delay: (e.key * 60).ms, duration: 350.ms)),
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
          decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.photo_library_outlined, color: kPrimary, size: 32),
        ),
        const SizedBox(height: 20),
        Text('No posts yet', style: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 8),
        Text('Create exclusive content that only your tippers can unlock.',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => _showPostDialog(context),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: Text('Create your first post',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
          ),
        ),
      ]),
    ),
  );

  Future<void> _confirmDelete(BuildContext context, CreatorPostModel post) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete "${post.title}"?',
            style: GoogleFonts.dmSans(color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text('This post will be permanently deleted.',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: kMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
            child: Text('Delete', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final api = context.read<AuthProvider>().api;
      final messenger = ScaffoldMessenger.of(context);
      try {
        await api.deletePost(post.id);
        _load();
      } catch (_) {
        messenger.showSnackBar(const SnackBar(content: Text('Failed to delete post')));
      }
    }
  }

  Future<void> _showPostDialog(BuildContext context, {CreatorPostModel? post}) async {
    await showDialog(
      context: context,
      builder: (_) => _PostFormDialog(
        post: post,
        onSaved: _load,
      ),
    );
  }
}

// ─── Post card (dashboard) ────────────────────────────────────────────────────
class _PostCard extends StatelessWidget {
  final CreatorPostModel post;
  final VoidCallback onEdit, onDelete;
  const _PostCard({required this.post, required this.onEdit, required this.onDelete});

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
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: kCardBg, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kBorder),
    ),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
            color: _typeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(_typeIcon, color: _typeColor, size: 20),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(post.title, style: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: _typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(36)),
            child: Text(post.postType.toUpperCase(), style: GoogleFonts.dmSans(
                color: _typeColor, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Text(
            '${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 11),
          ),
          const SizedBox(width: 8),
          if (!post.isPublished)
            Text('Draft', style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
        ]),
      ])),
      PopupMenuButton<String>(
        color: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: kBorder)),
        onSelected: (v) {
          if (v == 'edit') onEdit();
          if (v == 'delete') onDelete();
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'edit', child: Row(children: [
            const Icon(Icons.edit_rounded, color: Colors.white, size: 15),
            const SizedBox(width: 10),
            Text('Edit', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13)),
          ])),
          PopupMenuItem(value: 'delete', child: Row(children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 15),
            const SizedBox(width: 10),
            Text('Delete', style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 13)),
          ])),
        ],
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: kDark, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.more_horiz_rounded, color: kMuted, size: 18),
        ),
      ),
    ]),
  );
}

// ─── Post create/edit dialog ──────────────────────────────────────────────────
class _PostFormDialog extends StatefulWidget {
  final CreatorPostModel? post;
  final VoidCallback onSaved;
  const _PostFormDialog({this.post, required this.onSaved});
  @override
  State<_PostFormDialog> createState() => _PostFormDialogState();
}

class _PostFormDialogState extends State<_PostFormDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late final TextEditingController _videoUrlCtrl;
  late String _postType;
  late bool _isPublished;
  bool _saving = false;
  String? _error;
  String? _pickedFileName;
  List<int>? _pickedFileBytes;

  @override
  void initState() {
    super.initState();
    final p = widget.post;
    _titleCtrl    = TextEditingController(text: p?.title ?? '');
    _bodyCtrl     = TextEditingController(text: p?.body ?? '');
    _videoUrlCtrl = TextEditingController(text: p?.videoUrl ?? '');
    _postType     = p?.postType ?? 'text';
    _isPublished  = p?.isPublished ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _videoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _pickedFileName = result.files.single.name;
        _pickedFileBytes = result.files.single.bytes!.toList();
      });
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Title is required.');
      return;
    }
    setState(() { _saving = true; _error = null; });

    final fields = <String, String>{
      'title':        _titleCtrl.text.trim(),
      'body':         _bodyCtrl.text.trim(),
      'post_type':    _postType,
      'video_url':    _videoUrlCtrl.text.trim(),
      'is_published': _isPublished.toString(),
    };

    try {
      final api = context.read<AuthProvider>().api;
      if (widget.post == null) {
        await api.createPost(
          fields,
          fileBytes: _pickedFileBytes != null
              ? Uint8List.fromList(_pickedFileBytes!) : null,
          fileName: _pickedFileName,
        );
      } else {
        await api.updatePost(
          widget.post!.id,
          fields,
          fileBytes: _pickedFileBytes != null
              ? Uint8List.fromList(_pickedFileBytes!) : null,
          fileName: _pickedFileName,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to save. Try again.'; _saving = false; });
    }
  }

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 14),
    filled: true, fillColor: kDark,
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.post != null;
    return Dialog(
      backgroundColor: kCardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.photo_library_outlined, color: kPrimary, size: 18),
                ),
                const SizedBox(width: 12),
                Text(isEdit ? 'Edit post' : 'New post', style: GoogleFonts.dmSans(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: kMuted),
                ),
              ]),
              const SizedBox(height: 24),

              // Title
              Text('Title *', style: GoogleFonts.dmSans(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
                decoration: _deco('Post title'),
              ),
              const SizedBox(height: 16),

              // Post type
              Text('Post type', style: GoogleFonts.dmSans(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _postType,
                dropdownColor: kCardBg,
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
                decoration: _deco(''),
                items: const [
                  DropdownMenuItem(value: 'text',  child: Text('Text')),
                  DropdownMenuItem(value: 'image', child: Text('Image')),
                  DropdownMenuItem(value: 'video', child: Text('Video')),
                  DropdownMenuItem(value: 'file',  child: Text('File')),
                ],
                onChanged: (v) => setState(() => _postType = v ?? _postType),
              ),
              const SizedBox(height: 16),

              // Body
              Text('Body (optional)', style: GoogleFonts.dmSans(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyCtrl,
                maxLines: 4,
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
                decoration: _deco('Write your exclusive content here…'),
              ),
              const SizedBox(height: 16),

              // Video URL (only for video type)
              if (_postType == 'video') ...[
                Text('Video URL (YouTube / Vimeo)', style: GoogleFonts.dmSans(
                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _videoUrlCtrl,
                  style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
                  decoration: _deco('https://youtube.com/watch?v=...'),
                ),
                const SizedBox(height: 16),
              ],

              // File picker (for image/file types)
              if (_postType == 'image' || _postType == 'file') ...[
                Text('Upload file', style: GoogleFonts.dmSans(
                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: kDark, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _pickedFileName != null ? kPrimary : kBorder),
                    ),
                    child: Row(children: [
                      Icon(
                        _pickedFileName != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                        color: _pickedFileName != null ? kPrimary : kMuted, size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                        _pickedFileName ?? (widget.post?.mediaUrl != null
                            ? 'Current file — tap to replace'
                            : 'Tap to choose a file'),
                        style: GoogleFonts.dmSans(
                            color: _pickedFileName != null ? kPrimary : kMuted, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      )),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Published toggle
              Row(children: [
                Expanded(child: Text('Published', style: GoogleFonts.dmSans(
                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
                Switch(
                  value: _isPublished,
                  onChanged: (v) => setState(() => _isPublished = v),
                  activeThumbColor: kPrimary,
                ),
              ]),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 13)),
              ],
              const SizedBox(height: 24),

              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.dmSans(
                      color: kMuted, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
                    disabledBackgroundColor: kPrimary.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isEdit ? 'Save changes' : 'Publish post',
                          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
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
              ? Center(child: Text(_error!, style: GoogleFonts.dmSans(color: kMuted)))
              : ListView(
                  padding: const EdgeInsets.all(28),
                  children: [
                    // Header
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Your Jars', style: GoogleFonts.dmSans(
                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text('Create named jars for campaigns, goals, or specific purposes.',
                            style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
                      ])),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateDialog(context),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text('New jar', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13)),
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
        Text('No jars yet', style: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 8),
        Text('Create a jar for a campaign, project,\nor any reason you want to collect tips.',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => _showCreateDialog(context),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: Text('Create your first jar', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14)),
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
    final link = 'www.tippingjar.co.za/creator/${widget.profile.slug}/jar/${jar.slug}';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Jar link copied!', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13)),
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
            style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text('This jar will be deactivated. Existing tips will be preserved.',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.dmSans(color: kMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
            child: Text('Delete', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
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
            Text(jar.name, style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            if (jar.description.isNotEmpty)
              Text(jar.description, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12),
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
            Text('Progress', style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
            Text('${jar.progressPct!.toStringAsFixed(1)}%',
                style: GoogleFonts.dmSans(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 11)),
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
              Text('www.tippingjar.co.za/creator/$profileSlug/jar/${jar.slug}',
                  style: GoogleFonts.dmSans(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w500),
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
      Text(label, style: GoogleFonts.dmSans(color: kMuted, fontSize: 11, fontWeight: FontWeight.w500)),
    ]),
  );

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, Color color) =>
      PopupMenuItem(
        value: value,
        child: Row(children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.dmSans(color: color, fontSize: 13)),
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
                Text(widget.title, style: GoogleFonts.dmSans(
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
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
                validator: (v) => (v?.trim().length ?? 0) >= 2 ? null : 'Min 2 characters',
                decoration: _deco('e.g. New Laptop Fund'),
              ),
              const SizedBox(height: 16),

              _dialogLabel('Description (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: widget.descCtrl,
                maxLines: 3,
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
                decoration: _deco('Tell people what this jar is for…'),
              ),
              const SizedBox(height: 16),

              _dialogLabel('Goal amount (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: widget.goalCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                  return null;
                },
                decoration: _deco('e.g. 500').copyWith(prefixText: 'R  ',
                    prefixStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 14)),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 13)),
              ],
              const SizedBox(height: 24),

              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.dmSans(color: kMuted, fontWeight: FontWeight.w600)),
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
                      : Text('Save jar', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14)),
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
      style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13));

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 14),
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

// ─── Security card ────────────────────────────────────────────────────────────
class _SecurityCard extends StatefulWidget {
  const _SecurityCard();
  @override
  State<_SecurityCard> createState() => _SecurityCardState();
}

class _SecurityCardState extends State<_SecurityCard> {
  bool _saving = false;

  Future<void> _toggle(bool enabled) async {
    // Show risk warning before disabling
    if (!enabled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: kCardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            const Icon(Iconsax.warning_2, color: Color(0xFFFBBF24), size: 20),
            const SizedBox(width: 8),
            Text('Disable 2FA?', style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('This will remove the extra security layer from your account.',
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14, height: 1.5)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('⚠ Security risks:', style: GoogleFonts.dmSans(
                    color: Colors.redAccent, fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 6),
                Text('• Anyone with your password can log in without a code\n'
                    '• Your earnings and payout info will be less protected\n'
                    '• We strongly recommend keeping 2FA enabled',
                    style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 12, height: 1.5)),
              ]),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Keep 2FA on', style: GoogleFonts.dmSans(color: kPrimary, fontWeight: FontWeight.w700)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Disable anyway', style: GoogleFonts.dmSans(color: Colors.redAccent, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().setTwoFa(enabled);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            enabled ? '2FA enabled — you will need a code on next login.' : '2FA disabled — no code required on login.',
            style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: kPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update 2FA setting.',
              style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final twoFaEnabled = context.watch<AuthProvider>().user?.twoFaEnabled ?? true;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: kCardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Security', style: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Two-factor authentication (2FA)',
                style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              twoFaEnabled
                  ? 'A verification code is sent to your email on each login.'
                  : '2FA is off — anyone with your password can log in.',
              style: GoogleFonts.dmSans(color: kMuted, fontSize: 12),
            ),
          ])),
          const SizedBox(width: 16),
          _saving
              ? const SizedBox(width: 24, height: 24,
                  child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2))
              : Switch(
                  value: twoFaEnabled,
                  onChanged: _toggle,
                  activeColor: kPrimary,
                ),
        ]),
      ]),
    );
  }
}

// ─── Monetize page ────────────────────────────────────────────────────────────
class _MonetizePage extends StatefulWidget {
  final String creatorSlug;
  const _MonetizePage({required this.creatorSlug});
  @override
  State<_MonetizePage> createState() => _MonetizePageState();
}

class _MonetizePageState extends State<_MonetizePage> {
  int _tab = 0; // 0=Tiers, 1=Pledges, 2=Milestones, 3=Commissions
  List<TierModel> _tiers = [];
  List<PledgeModel> _pledges = [];
  List<MilestoneModel> _milestones = [];
  CommissionSlotModel? _slot;
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
      final api = context.read<AuthProvider>().api;
      final results = await Future.wait([
        api.getMyTiers(),
        api.getCreatorPledges(),
        api.getMyMilestones(),
        api.getMyCommissionSlot(),
        api.getMyCommissions(),
      ]);
      if (mounted) {
        setState(() {
          _tiers = results[0] as List<TierModel>;
          _pledges = results[1] as List<PledgeModel>;
          _milestones = results[2] as List<MilestoneModel>;
          _slot = results[3] as CommissionSlotModel;
          _commissions = results[4] as List<CommissionRequestModel>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: kPrimary));
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Failed to load', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(_error!, style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load,
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
            child: const Text('Retry')),
      ]));
    }

    return Column(children: [
      // Segment tabs
      Container(
        color: kDarker,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Monetize', style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text('Manage recurring revenue streams', style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _tabChip('Tiers', 0),
              const SizedBox(width: 8),
              _tabChip('Pledges', 1),
              const SizedBox(width: 8),
              _tabChip('Milestones', 2),
              const SizedBox(width: 8),
              _tabChip('Commissions', 3),
            ]),
          ),
          const SizedBox(height: 1),
        ]),
      ),
      const Divider(color: kBorder, height: 1),
      Expanded(child: RefreshIndicator(
        color: kPrimary, backgroundColor: kCardBg,
        onRefresh: _load,
        child: switch (_tab) {
          0 => _TiersSubView(tiers: _tiers, onRefresh: _load, creatorSlug: widget.creatorSlug),
          1 => _PledgesSubView(pledges: _pledges),
          2 => _MilestonesSubView(milestones: _milestones, onRefresh: _load),
          3 => _CommissionsSubView(slot: _slot, commissions: _commissions, onRefresh: _load),
          _ => const SizedBox.shrink(),
        },
      )),
    ]);
  }

  Widget _tabChip(String label, int index) => GestureDetector(
    onTap: () => setState(() => _tab = index),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: _tab == index ? kPrimary.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(bottom: BorderSide(
          color: _tab == index ? kPrimary : Colors.transparent, width: 2,
        )),
      ),
      child: Text(label, style: GoogleFonts.dmSans(
          color: _tab == index ? kPrimary : kMuted,
          fontWeight: _tab == index ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13)),
    ),
  );
}

// ─── Tiers sub-view ───────────────────────────────────────────────────────────
class _TiersSubView extends StatelessWidget {
  final List<TierModel> tiers;
  final VoidCallback onRefresh;
  final String creatorSlug;
  const _TiersSubView({required this.tiers, required this.onRefresh, required this.creatorSlug});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(28), children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Support Tiers', style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
          Text('Named price tiers fans can subscribe to monthly.',
              style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
        ])),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
            onPressed: () {
              final link = 'www.tippingjar.co.za/creator/$creatorSlug/subscribe';
              Clipboard.setData(ClipboardData(text: link));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Subscribe page link copied!',
                    style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13)),
                backgroundColor: kPrimary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 2),
              ));
            },
            icon: const Icon(Icons.share_rounded, size: 15),
            label: Text('Share page', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: kPrimary,
              side: const BorderSide(color: kPrimary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showTierDialog(context),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text('Add Tier', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13)),
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13)),
          ),
        ]),
      ]),
      const SizedBox(height: 24),
      if (tiers.isEmpty)
        _empty('No tiers yet', 'Create a tier like "Super Fan – R100/month" with perks.',
            Icons.workspace_premium_outlined)
      else
        ...tiers.asMap().entries.map((e) => _TierCard(tier: e.value, onRefresh: onRefresh)
            .animate().fadeIn(delay: (e.key * 60).ms, duration: 350.ms)),
    ]);
  }

  Future<void> _showTierDialog(BuildContext context, {TierModel? tier}) async {
    await showDialog(context: context, builder: (_) => _TierFormDialog(tier: tier, onSaved: onRefresh));
  }

  Widget _empty(String title, String sub, IconData icon) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(children: [
        Container(width: 72, height: 72,
            decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: kPrimary, size: 32)),
        const SizedBox(height: 20),
        Text(title, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 8),
        Text(sub, style: GoogleFonts.dmSans(color: kMuted, fontSize: 14, height: 1.5), textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _TierCard extends StatelessWidget {
  final TierModel tier;
  final VoidCallback onRefresh;
  const _TierCard({required this.tier, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.workspace_premium_outlined, color: kPrimary, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tier.name, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            Text('R${tier.price.toStringAsFixed(0)}/month', style: GoogleFonts.dmSans(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
          ])),
          // Active badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (tier.isActive ? const Color(0xFF10B981) : kMuted).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(36),
            ),
            child: Text(tier.isActive ? 'Active' : 'Inactive', style: GoogleFonts.dmSans(
                color: tier.isActive ? const Color(0xFF10B981) : kMuted, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            color: kCardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: kBorder)),
            onSelected: (v) async {
              final api = context.read<AuthProvider>().api;
              if (v == 'toggle') {
                await api.updateTier(tier.id, {'is_active': !tier.isActive});
                onRefresh();
              } else if (v == 'delete') {
                await api.deleteTier(tier.id);
                onRefresh();
              } else if (v == 'edit') {
                await showDialog(context: context, builder: (_) => _TierFormDialog(tier: tier, onSaved: onRefresh));
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: _popItem(Icons.edit_rounded, 'Edit', Colors.white)),
              PopupMenuItem(value: 'toggle', child: _popItem(
                  tier.isActive ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  tier.isActive ? 'Deactivate' : 'Activate', Colors.white)),
              PopupMenuItem(value: 'delete', child: _popItem(Icons.delete_outline_rounded, 'Delete', Colors.redAccent)),
            ],
            child: Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: kDark, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.more_horiz_rounded, color: kMuted, size: 18)),
          ),
        ]),
        if (tier.description.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(tier.description, style: GoogleFonts.dmSans(color: kMuted, fontSize: 13, height: 1.4)),
        ],
        if (tier.perks.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 6, children: tier.perks.map((p) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: kDark, borderRadius: BorderRadius.circular(36), border: Border.all(color: kBorder)),
            child: Text(p, style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
          )).toList()),
        ],
      ]),
    );
  }

  Widget _popItem(IconData icon, String label, Color color) => Row(children: [
    Icon(icon, color: color, size: 15), const SizedBox(width: 10),
    Text(label, style: GoogleFonts.dmSans(color: color, fontSize: 13)),
  ]);
}

class _TierFormDialog extends StatefulWidget {
  final TierModel? tier;
  final VoidCallback onSaved;
  const _TierFormDialog({this.tier, required this.onSaved});
  @override
  State<_TierFormDialog> createState() => _TierFormDialogState();
}

class _TierFormDialogState extends State<_TierFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _perkCtrl;
  late List<String> _perks;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.tier;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _priceCtrl = TextEditingController(text: t?.price.toStringAsFixed(0) ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _perkCtrl = TextEditingController();
    _perks = List<String>.from(t?.perks ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _priceCtrl.dispose();
    _descCtrl.dispose(); _perkCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _priceCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final data = {
      'name': _nameCtrl.text.trim(),
      'price': double.tryParse(_priceCtrl.text.trim()) ?? 0,
      'description': _descCtrl.text.trim(),
      'perks': _perks,
    };
    try {
      final api = context.read<AuthProvider>().api;
      if (widget.tier == null) {
        await api.createTier(data);
      } else {
        await api.updateTier(widget.tier!.id, data);
      }
      if (mounted) { Navigator.pop(context); widget.onSaved(); }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint, hintStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 14),
    filled: true, fillColor: kDark,
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimary, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: kCardBg,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 36, height: 36,
                decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.workspace_premium_outlined, color: kPrimary, size: 18)),
            const SizedBox(width: 12),
            Text(widget.tier == null ? 'New Tier' : 'Edit Tier', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
            const Spacer(),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: kMuted)),
          ]),
          const SizedBox(height: 24),
          Text('Tier name *', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(controller: _nameCtrl, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14), decoration: _deco('e.g. Super Fan')),
          const SizedBox(height: 16),
          Text('Monthly price (R) *', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(controller: _priceCtrl, keyboardType: TextInputType.number, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14), decoration: _deco('e.g. 100')),
          const SizedBox(height: 16),
          Text('Description', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(controller: _descCtrl, maxLines: 3, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14), decoration: _deco('What do subscribers get?')),
          const SizedBox(height: 16),
          Text('Perks', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: _perkCtrl, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14), decoration: _deco('Add a perk…'))),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final p = _perkCtrl.text.trim();
                if (p.isNotEmpty) { setState(() { _perks.add(p); _perkCtrl.clear(); }); }
              },
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
              child: const Icon(Icons.add_rounded, size: 18),
            ),
          ]),
          if (_perks.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 6, children: _perks.map((p) => Chip(
              label: Text(p, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 12)),
              backgroundColor: kDark,
              side: const BorderSide(color: kBorder),
              deleteIcon: const Icon(Icons.close, size: 14, color: kMuted),
              onDeleted: () => setState(() => _perks.remove(p)),
            )).toList()),
          ],
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.dmSans(color: kMuted, fontWeight: FontWeight.w600))),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
              child: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(widget.tier == null ? 'Create Tier' : 'Save Changes', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ]),
        ])),
      ),
    ),
  );
}

// ─── Pledges sub-view ─────────────────────────────────────────────────────────
class _PledgesSubView extends StatelessWidget {
  final List<PledgeModel> pledges;
  const _PledgesSubView({required this.pledges});

  @override
  Widget build(BuildContext context) {
    final activePledges = pledges.where((p) => p.isActive).toList();
    final totalMonthly = activePledges.fold(0.0, (s, p) => s + p.amount);

    return ListView(padding: const EdgeInsets.all(28), children: [
      Text('Incoming Pledges', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
      const SizedBox(height: 4),
      Text('Monthly commitments from your fans.', style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kPrimary.withValues(alpha: 0.25))),
        child: Row(children: [
          const Icon(Icons.repeat_rounded, color: kPrimary, size: 22),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('R${totalMonthly.toStringAsFixed(2)}/month recurring', style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5)),
            Text('${activePledges.length} active pledge${activePledges.length == 1 ? '' : 's'}',
                style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
          ]),
        ]),
      ),
      const SizedBox(height: 24),
      if (pledges.isEmpty)
        Center(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text('No pledges yet. Fans pledge via your public page.',
              style: GoogleFonts.dmSans(color: kMuted, fontSize: 14), textAlign: TextAlign.center),
        ))
      else
        ...pledges.asMap().entries.map((e) {
          final p = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
            child: Row(children: [
              Container(width: 38, height: 38,
                  decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Center(child: Text(
                    p.fanName.isNotEmpty ? p.fanName[0].toUpperCase() : '?',
                    style: GoogleFonts.dmSans(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                  ))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.fanName, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                Text(p.fanEmail, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
                if (p.tierName != null)
                  Text('Tier: ${p.tierName}', style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
                if (p.nextChargeDate != null)
                  Text('Next charge: ${p.nextChargeDate}', style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('R${p.amount.toStringAsFixed(0)}/mo', style: GoogleFonts.dmSans(
                    color: kPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (p.isActive ? const Color(0xFF10B981) : kMuted).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: Text(p.status.toUpperCase(), style: GoogleFonts.dmSans(
                      color: p.isActive ? const Color(0xFF10B981) : kMuted, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ]),
            ]),
          ).animate().fadeIn(delay: (e.key * 50).ms, duration: 300.ms);
        }),
    ]);
  }
}

// ─── Milestones sub-view ──────────────────────────────────────────────────────
class _MilestonesSubView extends StatelessWidget {
  final List<MilestoneModel> milestones;
  final VoidCallback onRefresh;
  const _MilestonesSubView({required this.milestones, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(28), children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Milestone Goals', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
          Text('Monthly revenue targets for your supporters to rally behind.',
              style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
        ])),
        ElevatedButton.icon(
          onPressed: () => _showMilestoneDialog(context),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: Text('Add Goal', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13)),
          style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13)),
        ),
      ]),
      const SizedBox(height: 24),
      if (milestones.isEmpty)
        Center(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(children: [
            Container(width: 72, height: 72,
                decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.flag_rounded, color: kPrimary, size: 32)),
            const SizedBox(height: 20),
            Text('No milestones yet', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Set a monthly goal to motivate your community.',
                style: GoogleFonts.dmSans(color: kMuted, fontSize: 14, height: 1.5), textAlign: TextAlign.center),
          ]),
        ))
      else
        ...milestones.asMap().entries.map((e) {
          final m = e.value;
          final progress = (m.progressPct / 100).clamp(0.0, 1.0);
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: m.isAchieved ? const Color(0xFF10B981).withValues(alpha: 0.4) : kBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(m.title, style: GoogleFonts.dmSans(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
                if (m.isAchieved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(36)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 12),
                      const SizedBox(width: 4),
                      Text('Achieved!', style: GoogleFonts.dmSans(color: const Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w700)),
                    ]),
                  )
                else
                  Text('${m.progressPct.toStringAsFixed(1)}%', style: GoogleFonts.dmSans(
                      color: kPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: kBorder,
                  valueColor: AlwaysStoppedAnimation(m.isAchieved ? const Color(0xFF10B981) : kPrimary),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text('R${m.currentMonthTotal.toStringAsFixed(0)} / R${m.targetAmount.toStringAsFixed(0)} this month',
                  style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
              if (m.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(m.description, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12, height: 1.4)),
              ],
            ]),
          ).animate().fadeIn(delay: (e.key * 60).ms, duration: 350.ms);
        }),
    ]);
  }

  Future<void> _showMilestoneDialog(BuildContext context) async {
    await showDialog(context: context, builder: (_) => _MilestoneFormDialog(onSaved: onRefresh));
  }
}

class _MilestoneFormDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const _MilestoneFormDialog({required this.onSaved});
  @override
  State<_MilestoneFormDialog> createState() => _MilestoneFormDialogState();
}

class _MilestoneFormDialogState extends State<_MilestoneFormDialog> {
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() { _titleCtrl.dispose(); _targetCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint, hintStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 14),
    filled: true, fillColor: kDark,
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimary, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _targetCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final api = context.read<AuthProvider>().api;
      await api.createMilestone({
        'title': _titleCtrl.text.trim(),
        'target_amount': double.tryParse(_targetCtrl.text.trim()) ?? 0,
        'description': _descCtrl.text.trim(),
      });
      if (mounted) { Navigator.pop(context); widget.onSaved(); }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: kCardBg,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.flag_rounded, color: kPrimary, size: 18)),
            const SizedBox(width: 12),
            Text('New Milestone', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
            const Spacer(),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: kMuted)),
          ]),
          const SizedBox(height: 24),
          Text('Title *', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(controller: _titleCtrl, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14), decoration: _deco('e.g. Studio upgrade')),
          const SizedBox(height: 16),
          Text('Target amount (R) *', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(controller: _targetCtrl, keyboardType: TextInputType.number, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14), decoration: _deco('e.g. 5000')),
          const SizedBox(height: 16),
          Text('Description', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(controller: _descCtrl, maxLines: 3, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14), decoration: _deco('Tell your audience what this milestone unlocks...')),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.dmSans(color: kMuted, fontWeight: FontWeight.w600))),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
              child: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Create Goal', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ]),
        ]),
      ),
    ),
  );
}

// ─── Commissions sub-view ─────────────────────────────────────────────────────
class _CommissionsSubView extends StatefulWidget {
  final CommissionSlotModel? slot;
  final List<CommissionRequestModel> commissions;
  final VoidCallback onRefresh;
  const _CommissionsSubView({required this.slot, required this.commissions, required this.onRefresh});
  @override
  State<_CommissionsSubView> createState() => _CommissionsSubViewState();
}

class _CommissionsSubViewState extends State<_CommissionsSubView> {
  bool _toggling = false;

  Color _statusColor(String status) => switch (status) {
    'accepted' => const Color(0xFF10B981),
    'declined' => Colors.redAccent,
    'completed' => const Color(0xFF60A5FA),
    _ => const Color(0xFFFBBF24),
  };

  @override
  Widget build(BuildContext context) {
    final slot = widget.slot;
    return ListView(padding: const EdgeInsets.all(28), children: [
      Text('Commissions', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
      const SizedBox(height: 4),
      Text('Accept custom commission requests from fans.', style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
      const SizedBox(height: 20),

      // Open/closed toggle
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
        child: Column(children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Accept commissions', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              Text('When on, fans can submit requests from your public page.',
                  style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
            ])),
            _toggling
                ? const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2))
                : Switch(
                    value: slot?.isOpen ?? false,
                    onChanged: slot == null ? null : (v) async {
                      setState(() => _toggling = true);
                      try {
                        final api = context.read<AuthProvider>().api;
                        await api.updateCommissionSlot({...slot.toJson(), 'is_open': v});
                        widget.onRefresh();
                      } finally {
                        if (mounted) setState(() => _toggling = false);
                      }
                    },
                    activeThumbColor: kPrimary,
                  ),
          ]),
          if (slot != null && slot.isOpen) ...[
            const SizedBox(height: 16),
            const Divider(color: kBorder),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Text('Base price: R${slot.basePrice.toStringAsFixed(0)}',
                  style: GoogleFonts.dmSans(color: kMuted, fontSize: 13))),
              Text('${slot.turnaroundDays} day turnaround',
                  style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
            ]),
            if (slot.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(slot.description, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12, height: 1.4)),
            ],
          ],
        ]),
      ),
      const SizedBox(height: 28),

      Text('Requests (${widget.commissions.length})', style: GoogleFonts.dmSans(
          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
      const SizedBox(height: 12),
      if (widget.commissions.isEmpty)
        Center(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text('No commission requests yet.', style: GoogleFonts.dmSans(color: kMuted, fontSize: 14)),
        ))
      else
        ...widget.commissions.asMap().entries.map((e) {
          final c = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(c.title, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _statusColor(c.status).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(36)),
                  child: Text(c.status.toUpperCase(), style: GoogleFonts.dmSans(color: _statusColor(c.status), fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 6),
              Text('${c.fanName} (${c.fanEmail})', style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
              Text('R${c.agreedPrice.toStringAsFixed(0)} agreed', style: GoogleFonts.dmSans(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              Text(c.description, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
              if (c.deliveryNote.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Delivery: ${c.deliveryNote}', style: GoogleFonts.dmSans(color: const Color(0xFF60A5FA), fontSize: 12, height: 1.4)),
              ],
              if (c.isPending) ...[
                const SizedBox(height: 14),
                Row(children: [
                  ElevatedButton(
                    onPressed: () async {
                      await context.read<AuthProvider>().api.updateCommission(c.id, {'status': 'accepted'});
                      widget.onRefresh();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white,
                        elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                    child: Text('Accept', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () async {
                      await context.read<AuthProvider>().api.updateCommission(c.id, {'status': 'declined'});
                      widget.onRefresh();
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                    child: Text('Decline', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.redAccent)),
                  ),
                ]),
              ],
              if (c.isAccepted) ...[
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () async {
                    await context.read<AuthProvider>().api.updateCommission(c.id, {'status': 'completed'});
                    widget.onRefresh();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF60A5FA), foregroundColor: Colors.white,
                      elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                  child: Text('Mark Complete', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ]),
          ).animate().fadeIn(delay: (e.key * 60).ms, duration: 350.ms);
        }),
    ]);
  }
}

// ─── Badge card ───────────────────────────────────────────────────────────────
class _BadgeCard extends StatelessWidget {
  final double totalEarned;
  const _BadgeCard({required this.totalEarned});

  static const _tiers = [
    (50000.0, '💎', 'Diamond', Color(0xFF67E8F9), 'Top 1% of creators on TippingJar'),
    (5000.0,  '🥇', 'Gold',    Color(0xFFFBBF24), 'Consistently earning creator'),
    (500.0,   '🥈', 'Silver',  Color(0xFF94A3B8), 'Growing creator'),
    (0.0,     '🥉', 'Bronze',  Color(0xFFB97333), 'Getting started'),
  ];

  @override
  Widget build(BuildContext context) {
    final tier = _tiers.firstWhere((t) => totalEarned >= t.$1);
    final nextIndex = _tiers.indexOf(tier) - 1;
    final next = nextIndex >= 0 ? _tiers[nextIndex] : null;
    final progress = next != null && next.$1 > tier.$1
        ? ((totalEarned - tier.$1) / (next.$1 - tier.$1)).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardBg, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tier.$4.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: tier.$4.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(9)),
            child: Center(child: Text(tier.$2, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${tier.$3} Creator', style: GoogleFonts.dmSans(
                color: tier.$4, fontWeight: FontWeight.w700, fontSize: 14)),
            Text(tier.$5, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: tier.$4.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(36),
              border: Border.all(color: tier.$4.withValues(alpha: 0.3)),
            ),
            child: Text('R${totalEarned.toStringAsFixed(0)} earned',
                style: GoogleFonts.dmSans(color: tier.$4, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        if (next != null) ...[
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress, minHeight: 5, backgroundColor: kBorder,
                valueColor: AlwaysStoppedAnimation<Color>(tier.$4),
              ),
            )),
            const SizedBox(width: 10),
            Text('R${next.$1.toStringAsFixed(0)} for ${next.$3}',
                style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
          ]),
        ],
      ]),
    );
  }
}

// ─── Settings card ────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: kCardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
            child: const Icon(Iconsax.setting_2, color: kPrimary, size: 18),
          ),
          const SizedBox(width: 12),
          Text('Settings', style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
        const SizedBox(height: 16),
        const Divider(color: kBorder),
        const SizedBox(height: 8),
        _SettingsRow(Iconsax.notification, 'Email notifications', 'Receive email for new tips',
            trailing: Switch(
              value: true, onChanged: (_) {},
              activeColor: kPrimary,
            )),
        const SizedBox(height: 4),
        _SettingsRow(Iconsax.language_square, 'Language', 'English (ZA)',
            trailing: const Icon(Iconsax.arrow_right_3, color: kMuted, size: 16)),
        const SizedBox(height: 4),
        _SettingsRow(Iconsax.shield, 'Privacy', 'Control who sees your profile',
            trailing: const Icon(Iconsax.arrow_right_3, color: kMuted, size: 16)),
      ]),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Widget trailing;
  const _SettingsRow(this.icon, this.label, this.subtitle, {required this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(icon, color: kMuted, size: 18),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        Text(subtitle, style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
      ])),
      trailing,
    ]),
  );
}

// ─── Danger zone (delete account) ─────────────────────────────────────────────
class _DangerZoneCard extends StatefulWidget {
  final Future<void> Function() onDeleteAccount;
  const _DangerZoneCard({required this.onDeleteAccount});
  @override
  State<_DangerZoneCard> createState() => _DangerZoneCardState();
}

class _DangerZoneCardState extends State<_DangerZoneCard> {
  Future<void> _showDeleteDialog() async {
    final pwCtrl = TextEditingController();
    bool deleting = false;
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Iconsax.trash, color: Colors.redAccent, size: 20),
          const SizedBox(width: 8),
          Text('Delete account', style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('This will permanently delete your account, profile, and all data. '
               'This action cannot be undone.',
              style: GoogleFonts.dmSans(color: kMuted, fontSize: 13, height: 1.5)),
          const SizedBox(height: 16),
          Text('Enter your password to confirm:',
              style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: pwCtrl,
            obscureText: true,
            style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: GoogleFonts.dmSans(color: kMuted),
              filled: true, fillColor: kDark,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 12)),
          ],
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: kMuted)),
          ),
          ElevatedButton(
            onPressed: deleting ? null : () async {
              setS(() { deleting = true; error = null; });
              try {
                final api = context.read<AuthProvider>().api;
                await api.deleteAccount(pwCtrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
                await widget.onDeleteAccount();
              } catch (e) {
                setS(() {
                  error = e.toString().replaceFirst('Exception: ', '');
                  deleting = false;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
            ),
            child: deleting
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Delete my account', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.redAccent.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Danger zone', style: GoogleFonts.dmSans(
            color: Colors.redAccent, fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 4),
        Text('Permanently delete your account and all data.',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
      ])),
      const SizedBox(width: 16),
      OutlinedButton(
        onPressed: _showDeleteDialog,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
        ),
        child: Text('Delete account', style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    ]),
  );
}

// ─── Notifications page ────────────────────────────────────────────────────────
class _NotificationsPage extends StatelessWidget {
  final List<_NotifModel> notifications;
  final VoidCallback onMarkRead;
  final VoidCallback onRefresh;
  const _NotificationsPage({
    required this.notifications,
    required this.onMarkRead,
    required this.onRefresh,
  });

  static IconData _iconFor(String type) => switch (type) {
    'welcome'        => Icons.celebration_rounded,
    'first_tip'      => Icons.emoji_events_rounded,
    'tip_received'   => Iconsax.money_recive,
    'tip_goal'       => Icons.flag_rounded,
    'first_jar'      => Iconsax.bucket_circle,
    'first_thousand' => Icons.workspace_premium_rounded,
    'summary'        => Iconsax.chart_2,
    _                => Iconsax.notification,
  };

  static Color _colorFor(String type) => switch (type) {
    'welcome'        => kPrimary,
    'first_tip'      => const Color(0xFFF59E0B),
    'tip_received'   => kPrimary,
    'tip_goal'       => const Color(0xFF6366F1),
    'first_jar'      => const Color(0xFF10B981),
    'first_thousand' => const Color(0xFFF59E0B),
    'summary'        => const Color(0xFF3B82F6),
    _                => kMuted,
  };

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final hasUnread = notifications.any((n) => !n.isRead);

    return SingleChildScrollView(
      padding: EdgeInsets.all(w > 900 ? 32 : 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Notifications', style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5))
                .animate().fadeIn(duration: 400.ms),
            Text('Activity and milestones on your page.',
                style: GoogleFonts.dmSans(color: kMuted, fontSize: 13))
                .animate().fadeIn(delay: 80.ms),
          ])),
          if (hasUnread)
            TextButton.icon(
              onPressed: onMarkRead,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 14, color: kPrimary),
              label: Text('Mark all read', style: GoogleFonts.dmSans(color: kPrimary, fontSize: 12)),
            ),
        ]),
        const SizedBox(height: 24),
        if (notifications.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Iconsax.notification_bing, color: kMuted, size: 48),
                const SizedBox(height: 16),
                Text('No notifications yet', style: GoogleFonts.dmSans(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 6),
                Text('Tips, milestones, and updates will appear here.',
                    style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
              ]),
            ),
          )
        else
          ...notifications.asMap().entries.map((e) {
            final n = e.value;
            final color = _colorFor(n.type);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: n.isRead ? kCardBg : kCardBg.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: n.isRead ? kBorder : color.withValues(alpha: 0.35)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(_iconFor(n.type), color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(n.title, style: GoogleFonts.dmSans(
                        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
                    if (!n.isRead)
                      Container(width: 6, height: 6,
                          decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                  ]),
                  const SizedBox(height: 3),
                  Text(n.message, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12, height: 1.4),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(_timeAgo(n.createdAt), style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
                ])),
              ]),
            ).animate().fadeIn(delay: Duration(milliseconds: 40 * e.key), duration: 300.ms);
          }),
      ]),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM yyyy').format(dt);
  }
}

// ─── QR code card ─────────────────────────────────────────────────────────────
class _QrCodeCard extends StatefulWidget {
  final String slug;
  const _QrCodeCard({required this.slug});
  @override
  State<_QrCodeCard> createState() => _QrCodeCardState();
}

class _QrCodeCardState extends State<_QrCodeCard> {
  late final TextEditingController _msgCtrl;

  @override
  void initState() {
    super.initState();
    final url = 'https://www.tippingjar.co.za/u/${widget.slug}';
    _msgCtrl = TextEditingController(
      text: '💚 Tip me on TippingJar!\n\n'
          'Scan my QR code or visit my tip page — every rand helps me '
          'keep creating! 🙏\n\n'
          '👉 $url\n\n'
          '#TippingJar #SupportCreators',
    );
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tipUrl = 'https://www.tippingjar.co.za/u/${widget.slug}';
    final w = MediaQuery.of(context).size.width;
    final wide = w > 700;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              _QrBox(tipUrl: tipUrl),
              const SizedBox(width: 28),
              Expanded(child: _QrInfo(
                tipUrl: tipUrl,
                onShare: () => _showShareDialog(context, tipUrl),
              )),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              _QrBox(tipUrl: tipUrl),
              const SizedBox(height: 20),
              _QrInfo(
                tipUrl: tipUrl,
                onShare: () => _showShareDialog(context, tipUrl),
              ),
            ]),
    ).animate().fadeIn(duration: 400.ms);
  }

  Future<void> _downloadQrPng(String tipUrl) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 600, 600));
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 600, 600),
        Paint()..color = Colors.white,
      );
      final painter = QrPainter(
        data: tipUrl,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        color: const Color(0xFF0A0A0F),
        emptyColor: Colors.white,
        gapless: true,
      );
      painter.paint(canvas, const Size(600, 600));
      final picture = recorder.endRecording();
      final img = await picture.toImage(600, 600);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();
      final blob = html.Blob([pngBytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'tippingjar-qr.png')
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (_) {}
  }

  void _showShareDialog(BuildContext context, String tipUrl) {
    final defaultMsg = '💚 Tip me on TippingJar!\n\n'
        'Scan my QR code or visit my tip page — every rand helps me '
        'keep creating! 🙏\n\n'
        '👉 $tipUrl\n\n'
        '#TippingJar #SupportCreators';

    void launchShare(String url) =>
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: kCardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Header
                Row(children: [
                  const Icon(Icons.share_rounded, color: kPrimary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Share your tip page', style: GoogleFonts.dmSans(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
                  IconButton(onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, color: kMuted, size: 18),
                      padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                ]),
                const SizedBox(height: 20),

                // QR + Download
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Column(children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: QrImageView(
                        data: tipUrl, version: QrVersions.auto, size: 130,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0A0A0F)),
                        dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square, color: Color(0xFF0A0A0F)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _downloadQrPng(tipUrl),
                      icon: const Icon(Icons.download_rounded, size: 14, color: kPrimary),
                      label: Text('Download QR', style: GoogleFonts.dmSans(
                          color: kPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kPrimary),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
                    ),
                  ]),
                ]),
                const SizedBox(height: 20),
                const Divider(color: kBorder),
                const SizedBox(height: 16),

                // Share platforms
                Text('Share on', style: GoogleFonts.dmSans(
                    color: kMuted, fontSize: 11, fontWeight: FontWeight.w700,
                    letterSpacing: 0.8)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _SharePlatformBtn(
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    icon: Icons.chat_rounded,
                    onTap: () {
                      final encoded = Uri.encodeComponent(_msgCtrl.text);
                      launchShare('https://wa.me/?text=$encoded');
                    },
                  ),
                  _SharePlatformBtn(
                    label: 'X / Twitter',
                    color: const Color(0xFF000000),
                    icon: Icons.alternate_email_rounded,
                    onTap: () {
                      final encoded = Uri.encodeComponent(_msgCtrl.text);
                      launchShare('https://twitter.com/intent/tweet?text=$encoded');
                    },
                  ),
                  _SharePlatformBtn(
                    label: 'Facebook',
                    color: const Color(0xFF1877F2),
                    icon: Icons.facebook_rounded,
                    onTap: () {
                      final encoded = Uri.encodeComponent(tipUrl);
                      launchShare('https://www.facebook.com/sharer/sharer.php?u=$encoded');
                    },
                  ),
                  _SharePlatformBtn(
                    label: 'Telegram',
                    color: const Color(0xFF2AABEE),
                    icon: Icons.send_rounded,
                    onTap: () {
                      final url = Uri.encodeComponent(tipUrl);
                      final text = Uri.encodeComponent(_msgCtrl.text);
                      launchShare('https://t.me/share/url?url=$url&text=$text');
                    },
                  ),
                  _SharePlatformBtn(
                    label: 'LinkedIn',
                    color: const Color(0xFF0A66C2),
                    icon: Icons.work_outline_rounded,
                    onTap: () {
                      final encoded = Uri.encodeComponent(tipUrl);
                      launchShare('https://www.linkedin.com/sharing/share-offsite/?url=$encoded');
                    },
                  ),
                ]),

                const SizedBox(height: 20),
                const Divider(color: kBorder),
                const SizedBox(height: 16),

                // Editable message
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Caption / Message', style: GoogleFonts.dmSans(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  TextButton(
                    onPressed: () => setS(() => _msgCtrl.text = defaultMsg),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: Text('Reset', style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
                  ),
                ]),
                const SizedBox(height: 8),
                TextField(
                  controller: _msgCtrl,
                  maxLines: 5,
                  style: GoogleFonts.dmSans(color: Colors.white, fontSize: 12, height: 1.5),
                  decoration: InputDecoration(
                    filled: true, fillColor: kDark,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kBorder)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kPrimary, width: 2)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),

                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: tipUrl));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Link copied!')));
                    },
                    icon: const Icon(Icons.link_rounded, size: 14, color: kMuted),
                    label: Text('Copy link', style: GoogleFonts.dmSans(
                        color: kMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _msgCtrl.text));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Caption copied — now paste it when sharing!')));
                    },
                    icon: const Icon(Icons.copy_rounded, size: 14, color: Colors.white),
                    label: Text('Copy caption', style: GoogleFonts.dmSans(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary, elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Share platform button ────────────────────────────────────────────────────
class _SharePlatformBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _SharePlatformBtn({required this.label, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.dmSans(
            color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _QrBox extends StatelessWidget {
  final String tipUrl;
  const _QrBox({required this.tipUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: QrImageView(
        data: tipUrl,
        version: QrVersions.auto,
        size: 160,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Color(0xFF0A0A0F),
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Color(0xFF0A0A0F),
        ),
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      ),
    );
  }
}

class _QrInfo extends StatelessWidget {
  final String tipUrl;
  final VoidCallback onShare;
  const _QrInfo({required this.tipUrl, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Iconsax.scan, color: kPrimary, size: 18),
        const SizedBox(width: 8),
        Text('Scan & Pay', style: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: onShare,
          icon: const Icon(Icons.share_rounded, size: 14, color: Colors.white),
          label: Text('Share', style: GoogleFonts.dmSans(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary, elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      Text('Share your QR code so fans can tip you instantly — no link needed. '
          'Works with any QR scanner or camera app.',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 13, height: 1.5)),
      const SizedBox(height: 16),
      GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: tipUrl));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tip link copied!')),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: kDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kBorder),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.link_rounded, color: kMuted, size: 14),
            const SizedBox(width: 8),
            Flexible(child: Text(tipUrl,
                style: GoogleFonts.dmSans(color: kMuted, fontSize: 12),
                overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 10),
            const Icon(Icons.copy_rounded, color: kPrimary, size: 14),
          ]),
        ),
      ),
    ]);
  }
}
