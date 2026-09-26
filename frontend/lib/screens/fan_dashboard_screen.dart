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
// Fan Dashboard — tabbed: Home · Live · Content · Activity · Settings
// ─────────────────────────────────────────────────────────────────────────────

class FanDashboardScreen extends StatefulWidget {
  const FanDashboardScreen({super.key});

  @override
  State<FanDashboardScreen> createState() => _FanDashboardScreenState();
}

class _FanDashboardScreenState extends State<FanDashboardScreen> {
  int _tab = 0;
  final List<String> _tabLabels = ['Home', 'Live', 'Content', 'Activity', 'Settings'];
  final List<IconData> _tabIcons = [
    Icons.home_rounded,
    Icons.live_tv_rounded,
    Icons.grid_view_rounded,
    Icons.history_rounded,
    Icons.settings_rounded,
  ];

  // All data
  List<TipModel> _tips = [];
  List<Creator> _creators = [];
  List<PledgeModel> _pledges = [];
  List<TipStreakModel> _streaks = [];
  List<CommissionRequestModel> _commissions = [];
  List<Map<String, dynamic>> _liveStreams = [];
  List<Map<String, dynamic>> _feed = [];
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
        api.getAllLiveStreams().catchError((_) => <Map<String, dynamic>>[]),
        api.getGlobalFeed().catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _tips        = results[0] as List<TipModel>;
        _creators    = results[1] as List<Creator>;
        _pledges     = results[2] as List<PledgeModel>;
        _streaks     = results[3] as List<TipStreakModel>;
        _commissions = results[4] as List<CommissionRequestModel>;
        _liveStreams = results[5] as List<Map<String, dynamic>>;
        _feed        = results[6] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  int get _tipCount => _tips.length;
  double get _totalSpent => _tips.fold(0, (s, t) => s + t.amount);
  int get _creatorsSupported => _tips.map((t) => t.creatorSlug).toSet().length;

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
    final wide = MediaQuery.of(context).size.width > 820;

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
                  ? _ErrorView(error: _error!, onRetry: _load)
                  : wide
                      ? _WideLayout(
                          tab: _tab,
                          tabLabels: _tabLabels,
                          tabIcons: _tabIcons,
                          onTabChanged: (i) => setState(() => _tab = i),
                          child: _tabContent(username),
                        )
                      : _NarrowLayout(
                          tab: _tab,
                          tabLabels: _tabLabels,
                          tabIcons: _tabIcons,
                          onTabChanged: (i) => setState(() => _tab = i),
                          child: _tabContent(username),
                        ),
        ),
      ]),
    );
  }

  Widget _tabContent(String username) {
    return RefreshIndicator(
      color: kPrimary,
      backgroundColor: kCardBg,
      onRefresh: _load,
      child: switch (_tab) {
        0 => _HomeTab(
            greeting: _greeting,
            username: username,
            tipCount: _tipCount,
            totalSpent: _totalSpent,
            creatorsSupported: _creatorsSupported,
            liveStreams: _liveStreams,
            feed: _feed,
            creators: _creators,
          ),
        1 => _LiveTab(liveStreams: _liveStreams, onRefresh: _load),
        2 => _ContentTab(feed: _feed, creators: _creators, onRefresh: _load),
        3 => _ActivityTab(
            tips: _tips,
            pledges: _pledges,
            streaks: _streaks,
            commissions: _commissions,
            onRefresh: _load,
          ),
        4 => const _SettingsTab(),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

// ─── Wide layout: fixed left sidebar ─────────────────────────────────────────
class _WideLayout extends StatelessWidget {
  final int tab;
  final List<String> tabLabels;
  final List<IconData> tabIcons;
  final ValueChanged<int> onTabChanged;
  final Widget child;
  const _WideLayout({required this.tab, required this.tabLabels, required this.tabIcons,
      required this.onTabChanged, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // Sidebar
      Container(
        width: 220,
        color: kDarker,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        child: Column(children: [
          ...List.generate(tabLabels.length, (i) => _SidebarItem(
            icon: tabIcons[i],
            label: tabLabels[i],
            selected: tab == i,
            onTap: () => onTabChanged(i),
          )),
        ]),
      ),
      Container(width: 1, color: kBorder),
      // Content
      Expanded(child: child),
    ]);
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SidebarItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: 160.ms,
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.selected
                ? kPrimary.withOpacity(0.12)
                : _hovered ? kCardBg : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.selected ? kPrimary.withOpacity(0.3) : Colors.transparent,
            ),
          ),
          child: Row(children: [
            Icon(widget.icon,
                size: 18,
                color: widget.selected ? kPrimary : _hovered ? Colors.white : kMuted),
            const SizedBox(width: 12),
            Text(widget.label,
                style: GoogleFonts.dmSans(
                  color: widget.selected ? kPrimary : _hovered ? Colors.white : kMuted,
                  fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                )),
          ]),
        ),
      ),
    );
  }
}

// ─── Narrow layout: bottom nav ───────────────────────────────────────────────
class _NarrowLayout extends StatelessWidget {
  final int tab;
  final List<String> tabLabels;
  final List<IconData> tabIcons;
  final ValueChanged<int> onTabChanged;
  final Widget child;
  const _NarrowLayout({required this.tab, required this.tabLabels, required this.tabIcons,
      required this.onTabChanged, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(child: child),
      Container(
        decoration: BoxDecoration(
          color: kDarker,
          border: Border(top: BorderSide(color: kBorder)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: List.generate(tabLabels.length, (i) => Expanded(
              child: GestureDetector(
                onTap: () => onTabChanged(i),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(tabIcons[i],
                        size: 20,
                        color: tab == i ? kPrimary : kMuted),
                    const SizedBox(height: 3),
                    Text(tabLabels[i],
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: tab == i ? kPrimary : kMuted,
                          fontWeight: tab == i ? FontWeight.w700 : FontWeight.w500,
                        )),
                  ]),
                ),
              ),
            )),
          ),
        ),
      ),
    ]);
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
              Text('TippingJar', style: GoogleFonts.dmSans(
                  color: Colors.white, fontWeight: FontWeight.w700,
                  fontSize: 16, letterSpacing: -0.3)),
            ]),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => context.go('/creators'),
            icon: const Icon(Icons.explore_outlined, size: 16, color: kMuted),
            label: Text('Explore', style: GoogleFonts.dmSans(color: kMuted, fontSize: 13, fontWeight: FontWeight.w500)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
          ),
          const SizedBox(width: 4),
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
                  Text('Sign out', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13)),
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
                  child: Center(child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                  )),
                ),
                const SizedBox(width: 7),
                Text(username, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
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

// ─── Error view ───────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.wifi_off_rounded, color: kMuted, size: 48),
      const SizedBox(height: 16),
      Text('Could not load', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: onRetry,
        style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
        child: const Text('Try again'),
      ),
    ]));
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 0 — HOME
// ═══════════════════════════════════════════════════════════════════════════════
class _HomeTab extends StatelessWidget {
  final String greeting, username;
  final int tipCount, creatorsSupported;
  final double totalSpent;
  final List<Map<String, dynamic>> liveStreams, feed;
  final List<Creator> creators;

  const _HomeTab({
    required this.greeting, required this.username,
    required this.tipCount, required this.creatorsSupported, required this.totalSpent,
    required this.liveStreams, required this.feed, required this.creators,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(28), children: [
      // Welcome
      _WelcomeCard(greeting: greeting, username: username, tipCount: tipCount),
      const SizedBox(height: 20),
      // Stats
      Row(children: [
        _StatChip(label: 'Tips sent', value: '$tipCount', icon: Icons.favorite_rounded, delay: 0),
        const SizedBox(width: 10),
        _StatChip(label: 'Total given', value: 'R${totalSpent.toStringAsFixed(0)}', icon: Icons.attach_money_rounded, delay: 60),
        const SizedBox(width: 10),
        _StatChip(label: 'Creators', value: '$creatorsSupported', icon: Icons.people_outline_rounded, delay: 120),
      ]),
      // Live now section
      if (liveStreams.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(
          title: 'Live now',
          trailing: '${liveStreams.length} live',
          icon: Icons.fiber_manual_record,
          iconColor: Colors.redAccent,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: liveStreams.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _LiveNowCard(stream: liveStreams[i]),
          ),
        ),
      ],
      // Recent content
      if (feed.isNotEmpty) ...[
        const SizedBox(height: 32),
        const _SectionHeader(title: 'Recent content', icon: Icons.article_outlined),
        const SizedBox(height: 14),
        ...feed.take(5).toList().asMap().entries.map((e) =>
            _FeedCard(post: e.value, delay: e.key * 50)),
      ],
      // Discover
      const SizedBox(height: 32),
      _SectionHeader(
        title: 'Discover creators',
        trailingWidget: GestureDetector(
          onTap: () => context.go('/creators'),
          child: Text('See all', style: GoogleFonts.dmSans(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        icon: Icons.explore_outlined,
      ),
      const SizedBox(height: 14),
      SizedBox(
        height: 160,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: creators.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => _CreatorCard(creator: creators[i], delay: i * 40),
        ),
      ),
      const SizedBox(height: 20),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 1 — LIVE
// ═══════════════════════════════════════════════════════════════════════════════
class _LiveTab extends StatelessWidget {
  final List<Map<String, dynamic>> liveStreams;
  final VoidCallback onRefresh;
  const _LiveTab({required this.liveStreams, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(28), children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 7, height: 7, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('Live now', style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(width: 12),
        Text('${liveStreams.length} stream${liveStreams.length == 1 ? '' : 's'}',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
        const Spacer(),
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded, color: kMuted, size: 18),
          tooltip: 'Refresh',
          padding: EdgeInsets.zero,
        ),
      ]),
      const SizedBox(height: 20),
      if (liveStreams.isEmpty)
        _EmptyState(
          icon: Icons.live_tv_rounded,
          title: 'No one is live right now',
          subtitle: 'Check back later or explore creators to see who goes live.',
          actionLabel: 'Browse creators',
          onAction: () => context.go('/creators'),
        )
      else
        ...liveStreams.asMap().entries.map((e) =>
            _LiveStreamRow(stream: e.value, delay: e.key * 60).animate()
                .fadeIn(delay: (e.key * 60).ms, duration: 350.ms)),
      const SizedBox(height: 20),
    ]);
  }
}

class _LiveStreamRow extends StatelessWidget {
  final Map<String, dynamic> stream;
  final int delay;
  const _LiveStreamRow({required this.stream, required this.delay});

  @override
  Widget build(BuildContext context) {
    final slug = stream['creator_slug'] as String? ?? '';
    final name = stream['creator_display_name'] as String? ?? slug;
    final title = stream['title'] as String? ?? 'Live Stream';
    final avatar = stream['creator_avatar'] as String?;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: () => context.go('/creator/$slug'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
        ),
        child: Row(children: [
          // Avatar with live ring
          Stack(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.redAccent, width: 2),
              ),
              child: ClipOval(child: avatar != null
                  ? Image.network(avatar, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _InitialCircle(initial: initial, size: 52))
                  : _InitialCircle(initial: initial, size: 52)),
            ),
            Positioned(bottom: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: kDark, shape: BoxShape.circle),
                child: Container(width: 8, height: 8,
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
              ),
            ),
          ]),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 3),
            Text(title, style: GoogleFonts.dmSans(color: kMuted, fontSize: 13, height: 1.4),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => context.go('/creator/$slug'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
            ),
            child: Text('Join', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2 — CONTENT (global feed)
// ═══════════════════════════════════════════════════════════════════════════════
class _ContentTab extends StatelessWidget {
  final List<Map<String, dynamic>> feed;
  final List<Creator> creators;
  final VoidCallback onRefresh;
  const _ContentTab({required this.feed, required this.creators, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(28), children: [
      const _SectionHeader(title: 'Latest posts', icon: Icons.article_outlined),
      const SizedBox(height: 16),
      if (feed.isEmpty)
        _EmptyState(
          icon: Icons.article_outlined,
          title: 'No posts yet',
          subtitle: 'When creators publish content it will appear here.',
          actionLabel: 'Browse creators',
          onAction: () => context.go('/creators'),
        )
      else ...[
        ...feed.asMap().entries.map((e) => _FeedCard(post: e.value, delay: e.key * 40)),
        const SizedBox(height: 24),
      ],
      // Creators to follow
      const _SectionHeader(title: 'Find creators', icon: Icons.search_rounded),
      const SizedBox(height: 14),
      Wrap(
        spacing: 12, runSpacing: 12,
        children: creators.take(12).toList().asMap().entries.map((e) =>
            _CreatorCard(creator: e.value, delay: e.key * 30)).toList(),
      ),
      const SizedBox(height: 24),
    ]);
  }
}

class _FeedCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final int delay;
  const _FeedCard({required this.post, required this.delay});

  IconData get _typeIcon {
    final type = post['post_type'] as String? ?? '';
    return switch (type) {
      'video' => Icons.play_circle_outline_rounded,
      'audio' => Icons.audiotrack_rounded,
      'image' => Icons.image_outlined,
      _ => Icons.article_outlined,
    };
  }

  Color get _typeColor {
    final type = post['post_type'] as String? ?? '';
    return switch (type) {
      'video' => const Color(0xFF60A5FA),
      'audio' => const Color(0xFFA78BFA),
      'image' => const Color(0xFF34D399),
      _ => kMuted,
    };
  }

  @override
  Widget build(BuildContext context) {
    final slug = post['creator_slug'] as String? ?? '';
    final name = post['creator_display_name'] as String? ?? '';
    final title = post['title'] as String? ?? 'Untitled';
    final type = post['post_type'] as String? ?? 'text';
    final createdAt = post['created_at'] as String? ?? '';
    final dt = DateTime.tryParse(createdAt);
    final timeAgo = dt != null ? _relativeTime(dt) : '';

    return GestureDetector(
      onTap: () => context.go('/creator/$slug'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: _typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon, color: _typeColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Row(children: [
              Text(name, style: GoogleFonts.dmSans(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
              Text(' · $timeAgo', style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
            ]),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(type, style: GoogleFonts.dmSans(color: _typeColor, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    ).animate().fadeIn(delay: delay.ms, duration: 350.ms);
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 3 — ACTIVITY
// ═══════════════════════════════════════════════════════════════════════════════
class _ActivityTab extends StatelessWidget {
  final List<TipModel> tips;
  final List<PledgeModel> pledges;
  final List<TipStreakModel> streaks;
  final List<CommissionRequestModel> commissions;
  final VoidCallback onRefresh;
  const _ActivityTab({required this.tips, required this.pledges, required this.streaks,
      required this.commissions, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(28), children: [
      // Tips
      const _SectionHeader(title: 'Your tips', icon: Icons.favorite_rounded),
      const SizedBox(height: 14),
      if (tips.isEmpty)
        _EmptyState(
          icon: Icons.volunteer_activism_outlined,
          title: 'No tips sent yet',
          subtitle: 'Find a creator you love and send your first tip!',
          actionLabel: 'Browse creators',
          onAction: () => context.go('/creators'),
        )
      else
        ...tips.take(10).toList().asMap().entries.map((e) =>
            _TipCard(tip: e.value, delay: e.key * 50)),

      // Pledges
      if (pledges.isNotEmpty) ...[
        const SizedBox(height: 28),
        const _SectionHeader(title: 'My pledges', icon: Icons.repeat_rounded),
        const SizedBox(height: 14),
        ...pledges.map((p) => _PledgeCard(pledge: p, onRefresh: onRefresh)),
      ],

      // Streaks
      if (streaks.isNotEmpty) ...[
        const SizedBox(height: 28),
        const _SectionHeader(title: 'Supporter streaks', icon: Icons.local_fire_department_rounded),
        const SizedBox(height: 14),
        ...streaks.map((s) => _StreakCard(streak: s)),
      ],

      // Commissions
      if (commissions.isNotEmpty) ...[
        const SizedBox(height: 28),
        const _SectionHeader(title: 'My commissions', icon: Icons.assignment_outlined),
        const SizedBox(height: 14),
        ...commissions.map((c) => _FanCommissionCard(commission: c)),
      ],

      const SizedBox(height: 24),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 4 — SETTINGS
// ═══════════════════════════════════════════════════════════════════════════════
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(28), children: [
      const _SectionHeader(title: 'Account settings', icon: Icons.security_rounded),
      const SizedBox(height: 16),
      const _FanSecurityCard(),
      const SizedBox(height: 24),
      // Profile settings placeholder
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Account', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          _SettingRow(
            icon: Icons.explore_outlined,
            label: 'Browse all creators',
            onTap: () => context.go('/creators'),
          ),
          _SettingRow(
            icon: Icons.logout_rounded,
            label: 'Sign out',
            danger: true,
            onTap: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/');
            },
          ),
        ]),
      ),
      const SizedBox(height: 24),
    ]);
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _SettingRow({required this.icon, required this.label, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.redAccent : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(children: [
          Icon(icon, color: danger ? Colors.redAccent : kMuted, size: 17),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: GoogleFonts.dmSans(color: color, fontSize: 13))),
          Icon(Icons.chevron_right_rounded, color: kBorder, size: 18),
        ]),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

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
            style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800,
                fontSize: 22, letterSpacing: -0.5))
            .animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
        const SizedBox(height: 8),
        Text(
          tipCount == 0
              ? 'Ready to support your first creator?'
              : 'You\'ve sent $tipCount tip${tipCount == 1 ? '' : 's'} — amazing!',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 14, height: 1.5),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => context.go('/creators'),
          icon: const Icon(Icons.explore_outlined, size: 15),
          label: Text('Discover creators', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
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
          Text(value, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
        ]),
      ).animate().fadeIn(delay: delay.ms, duration: 350.ms),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final Widget? trailingWidget;
  final IconData? icon;
  final Color? iconColor;
  const _SectionHeader({required this.title, this.trailing, this.trailingWidget, this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (icon != null) ...[
        Icon(icon, color: iconColor ?? kMuted, size: 16),
        const SizedBox(width: 8),
      ],
      Text(title, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      const Spacer(),
      if (trailingWidget != null) trailingWidget!
      else if (trailing != null)
        Text(trailing!, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
    ]);
  }
}

// Compact live-now card for horizontal scroll on Home tab
class _LiveNowCard extends StatelessWidget {
  final Map<String, dynamic> stream;
  const _LiveNowCard({required this.stream});

  @override
  Widget build(BuildContext context) {
    final slug = stream['creator_slug'] as String? ?? '';
    final name = stream['creator_display_name'] as String? ?? slug;
    final title = stream['title'] as String? ?? 'Live';
    final avatar = stream['creator_avatar'] as String?;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: () => context.go('/creator/$slug'),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.redAccent, width: 1.5)),
              child: ClipOval(child: avatar != null
                  ? Image.network(avatar, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _InitialCircle(initial: initial, size: 36))
                  : _InitialCircle(initial: initial, size: 36)),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)),
              child: Text('LIVE', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(name, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(title, style: GoogleFonts.dmSans(color: kMuted, fontSize: 11),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

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
          width: 160,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _hovered ? kPrimary.withOpacity(0.5) : kBorder),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _InitialCircle(initial: _initials, size: 40),
            const SizedBox(height: 10),
            Text(widget.creator.displayName,
                style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(widget.creator.tagline,
                style: GoogleFonts.dmSans(color: kMuted, fontSize: 11),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/creator/${widget.creator.slug}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary.withOpacity(0.15),
                  foregroundColor: kPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                ),
                child: Text('View', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 11)),
              ),
            ),
          ]),
        ),
      ),
    ).animate().fadeIn(delay: widget.delay.ms, duration: 400.ms).slideY(begin: 0.08);
  }
}

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
          color: kCardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder),
        ),
        child: Row(children: [
          _InitialCircle(initial: _initials, size: 40),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(tip.creatorDisplayName,
                  style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                  overflow: TextOverflow.ellipsis)),
              Text('R${tip.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.dmSans(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
            ]),
            if (tip.message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(tip.message, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12, height: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 4),
            Text(tip.relativeTime, style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
          ])),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: kBorder, size: 18),
        ]),
      ),
    ).animate().fadeIn(delay: delay.ms, duration: 350.ms);
  }
}

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
          Text(pledge.creatorDisplayName, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          if (pledge.tierName != null)
            Text(pledge.tierName!, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('R${pledge.amount.toStringAsFixed(0)}/mo',
              style: GoogleFonts.dmSans(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(36)),
            child: Text(pledge.status.toUpperCase(), style: GoogleFonts.dmSans(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
      ]),
    );
  }
}

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
              style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          Text(streak.creatorDisplayName, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
          if (streak.badges.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: streak.badges.map((b) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: kPrimary.withValues(alpha: 0.3))),
              child: Text(b, style: GoogleFonts.dmSans(color: kPrimary, fontSize: 10, fontWeight: FontWeight.w700)),
            )).toList()),
          ],
        ])),
        Text('Best: ${streak.maxStreak}mo', style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
      ]),
    );
  }
}

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
          Expanded(child: Text(commission.title,
              style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(36)),
            child: Text(commission.status.toUpperCase(), style: GoogleFonts.dmSans(color: _statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 4),
        Text(commission.creatorDisplayName, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
        Text('R${commission.agreedPrice.toStringAsFixed(0)} agreed',
            style: GoogleFonts.dmSans(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _EmptyState({required this.icon, required this.title, required this.subtitle, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
      child: Column(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: kPrimary, size: 24),
        ),
        const SizedBox(height: 16),
        Text(title, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 8),
        Text(subtitle, style: GoogleFonts.dmSans(color: kMuted, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
            ),
            child: Text(actionLabel!, style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ],
      ]),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ─── Security/2FA card ────────────────────────────────────────────────────────
class _FanSecurityCard extends StatefulWidget {
  const _FanSecurityCard();
  @override
  State<_FanSecurityCard> createState() => _FanSecurityCardState();
}

class _FanSecurityCardState extends State<_FanSecurityCard> {
  bool _saving = false;

  Future<void> _toggle(bool enabled) async {
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().setTwoFa(enabled);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update 2FA.',
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
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Two-factor authentication',
              style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            twoFaEnabled ? 'Verification code sent on each login.' : '2FA is off.',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 12),
          ),
        ])),
        const SizedBox(width: 16),
        _saving
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2))
            : Switch(value: twoFaEnabled, onChanged: _toggle, activeColor: kPrimary),
      ]),
    );
  }
}

// ─── Shared primitive: initial circle ────────────────────────────────────────
class _InitialCircle extends StatelessWidget {
  final String initial;
  final double size;
  const _InitialCircle({required this.initial, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
      child: Center(child: Text(
        initial.isNotEmpty ? initial[0] : '?',
        style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800,
            fontSize: size * 0.35),
      )),
    );
  }
}
