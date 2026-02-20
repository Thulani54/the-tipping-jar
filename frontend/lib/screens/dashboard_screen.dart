import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;

  // Mock data
  final _tipLink = 'tippingjar.io/u/yourname';

  final _tips = [
    _Tip('fan_alex',     'AlexG',     12.00, 'Keep making amazing content! Love your work 🔥',   '2 min ago'),
    _Tip('music_lover',  'MusicLover', 5.00,  'Your last track was 🔥',                           '18 min ago'),
    _Tip('daily_viewer', 'DailyView',  25.00, 'Been watching for 2 years — thank you!',           '1 hr ago'),
    _Tip('anon',         'Anonymous',  5.00,  '',                                                  '3 hr ago'),
    _Tip('superfan_22',  'SuperFan22', 50.00, 'Just discovered you last week and already obsessed.','5 hr ago'),
    _Tip('devjay',       'DevJay',     10.00, 'The tutorial series is incredibly helpful 🙏',     'Yesterday'),
    _Tip('nightowl',     'NightOwl',   5.00,  'Watching at 2am again lol',                        'Yesterday'),
    _Tip('creator_fan',  'CreatorFan', 20.00, 'One creator supporting another!',                  '2 days ago'),
  ];

  double get _totalEarnings => _tips.fold(0, (sum, t) => sum + t.amount);
  double get _thisMonth => _tips.take(5).fold(0, (sum, t) => sum + t.amount);
  double get _pendingPayout => 42.00;
  int    get _tipCount => _tips.length;

  final _weeklyData = [14.0, 28.0, 19.0, 45.0, 22.0, 57.0, 32.0];
  final _weekLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final wide = w > 900;

    return Scaffold(
      backgroundColor: kDark,
      body: wide ? _wideLayout() : _narrowLayout(),
      bottomNavigationBar: wide ? null : _bottomNav(),
    );
  }

  // ─── Wide layout (sidebar + content) ───────────────────────────────────────
  Widget _wideLayout() => Row(children: [
    _Sidebar(
      selected: _navIndex,
      onSelect: (i) => setState(() => _navIndex = i),
      onLogout: _logout,
    ),
    Expanded(child: _pageContent()),
  ]);

  // ─── Narrow layout (full content, bottom nav) ────────────────────────────
  Widget _narrowLayout() => _pageContent();

  Widget _bottomNav() => Container(
    decoration: const BoxDecoration(
      color: kDarker,
      border: Border(top: BorderSide(color: kBorder)),
    ),
    child: BottomNavigationBar(
      currentIndex: _navIndex,
      onTap: (i) => setState(() => _navIndex = i),
      backgroundColor: Colors.transparent,
      elevation: 0,
      selectedItemColor: kPrimary,
      unselectedItemColor: kMuted,
      selectedLabelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded, size: 20), label: 'Overview'),
        BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism, size: 20), label: 'Tips'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded, size: 20), label: 'Analytics'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded, size: 20), label: 'Profile'),
      ],
    ),
  );

  Widget _pageContent() {
    return switch (_navIndex) {
      0 => _OverviewPage(
          tips: _tips,
          totalEarnings: _totalEarnings,
          thisMonth: _thisMonth,
          pendingPayout: _pendingPayout,
          tipCount: _tipCount,
          weeklyData: _weeklyData,
          weekLabels: _weekLabels,
          tipLink: _tipLink,
          onCopyLink: _copyLink,
        ),
      1 => _TipsPage(tips: _tips),
      2 => _AnalyticsPage(
          weeklyData: _weeklyData,
          weekLabels: _weekLabels,
          totalEarnings: _totalEarnings,
          thisMonth: _thisMonth,
          tipCount: _tipCount,
        ),
      3 => _ProfilePage(tipLink: _tipLink, onCopyLink: _copyLink),
      _ => const SizedBox.shrink(),
    };
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _tipLink));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Tip link copied!',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
      backgroundColor: kPrimary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) context.go('/');
  }
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final int selected;
  final void Function(int) onSelect;
  final VoidCallback onLogout;
  const _Sidebar({required this.selected, required this.onSelect, required this.onLogout});

  static const _items = [
    (Icons.dashboard_rounded,      'Overview'),
    (Icons.volunteer_activism,     'Tips'),
    (Icons.bar_chart_rounded,      'Analytics'),
    (Icons.person_rounded,         'Profile'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    width: 220,
    color: kDarker,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 28),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
            child: const Icon(Icons.volunteer_activism, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Text('TippingJar', style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
      ),
      const SizedBox(height: 32),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text('CREATOR', style: GoogleFonts.inter(
            color: kMuted, fontSize: 10, fontWeight: FontWeight.w700,
            letterSpacing: 1.2)),
      ),
      const SizedBox(height: 8),
      ..._items.asMap().entries.map((e) => _SidebarItem(
        icon: e.value.$1, label: e.value.$2,
        active: selected == e.key,
        onTap: () => onSelect(e.key),
      )),
      const Spacer(),
      const Divider(color: kBorder, height: 1),
      _SidebarItem(
        icon: Icons.open_in_new_rounded, label: 'View tip page',
        active: false, onTap: () {},
      ),
      _SidebarItem(
        icon: Icons.logout_rounded, label: 'Sign out',
        active: false, onTap: onLogout,
        danger: true,
      ),
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
        color: active ? kPrimary.withOpacity(0.1) : Colors.transparent,
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
  final List<_Tip> tips;
  final double totalEarnings, thisMonth, pendingPayout;
  final int tipCount;
  final List<double> weeklyData;
  final List<String> weekLabels;
  final String tipLink;
  final VoidCallback onCopyLink;
  const _OverviewPage({required this.tips, required this.totalEarnings,
      required this.thisMonth, required this.pendingPayout,
      required this.tipCount, required this.weeklyData, required this.weekLabels,
      required this.tipLink, required this.onCopyLink});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      padding: EdgeInsets.all(w > 900 ? 32 : 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Good morning 👋', style: GoogleFonts.inter(
                color: kMuted, fontSize: 13)),
            Text('Your dashboard', style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w800,
                fontSize: 22, letterSpacing: -0.5)),
          ]),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: onCopyLink,
            icon: const Icon(Icons.link_rounded, size: 16, color: Colors.white),
            label: Text('Share tip link',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600,
                    fontSize: 13, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary, foregroundColor: Colors.white,
              elevation: 0, shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
            ),
          ),
        ]).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 28),

        // Stats row
        Wrap(spacing: 14, runSpacing: 14, children: [
          _StatCard('Total earned', '\$${totalEarnings.toStringAsFixed(2)}',
              Icons.account_balance_wallet_rounded, kPrimary, 0),
          _StatCard('This month', '\$${thisMonth.toStringAsFixed(2)}',
              Icons.calendar_month_rounded, const Color(0xFF60A5FA), 80),
          _StatCard('Pending payout', '\$${pendingPayout.toStringAsFixed(2)}',
              Icons.schedule_rounded, const Color(0xFFFBBF24), 160),
          _StatCard('Total tips', '$tipCount tips',
              Icons.volunteer_activism, const Color(0xFFF472B6), 240),
        ]),
        const SizedBox(height: 28),

        // Weekly chart
        _WeeklyChart(data: weeklyData, labels: weekLabels),
        const SizedBox(height: 28),

        // Recent tips
        Row(children: [
          Text('Recent tips', style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const Spacer(),
          Text('View all →', style: GoogleFonts.inter(
              color: kPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 14),
        ...tips.take(5).map((t) => _TipRow(tip: t)),

        const SizedBox(height: 28),
        // Payout CTA
        _PayoutBanner(pendingPayout: pendingPayout),
      ]),
    );
  }
}

// ─── Tips page ────────────────────────────────────────────────────────────────
class _TipsPage extends StatefulWidget {
  final List<_Tip> tips;
  const _TipsPage({required this.tips});
  @override
  State<_TipsPage> createState() => _TipsPageState();
}

class _TipsPageState extends State<_TipsPage> {
  String _filter = 'All';
  final _filters = ['All', 'Today', 'This week', 'This month'];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      padding: EdgeInsets.all(w > 900 ? 32 : 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Tips received', style: GoogleFonts.inter(
            color: Colors.white, fontWeight: FontWeight.w800,
            fontSize: 22, letterSpacing: -0.5))
            .animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 20),
        // Filter chips
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
        ...widget.tips.asMap().entries.map((e) =>
          _TipRow(tip: e.value, showDate: true)
              .animate().fadeIn(delay: Duration(milliseconds: 40 * e.key), duration: 300.ms),
        ),
      ]),
    );
  }
}

// ─── Analytics page ───────────────────────────────────────────────────────────
class _AnalyticsPage extends StatelessWidget {
  final List<double> weeklyData;
  final List<String> weekLabels;
  final double totalEarnings, thisMonth;
  final int tipCount;
  const _AnalyticsPage({required this.weeklyData, required this.weekLabels,
      required this.totalEarnings, required this.thisMonth, required this.tipCount});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final avgTip = totalEarnings / tipCount;
    return SingleChildScrollView(
      padding: EdgeInsets.all(w > 900 ? 32 : 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Analytics', style: GoogleFonts.inter(
            color: Colors.white, fontWeight: FontWeight.w800,
            fontSize: 22, letterSpacing: -0.5))
            .animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 24),
        _WeeklyChart(data: weeklyData, labels: weekLabels),
        const SizedBox(height: 24),
        Wrap(spacing: 14, runSpacing: 14, children: [
          _StatCard('Total earned', '\$${totalEarnings.toStringAsFixed(2)}',
              Icons.paid_rounded, kPrimary, 0),
          _StatCard('Avg. tip size', '\$${avgTip.toStringAsFixed(2)}',
              Icons.trending_up_rounded, const Color(0xFF60A5FA), 60),
          _StatCard('Total tips', '$tipCount', Icons.volunteer_activism,
              const Color(0xFFF472B6), 120),
          _StatCard('This month', '\$${thisMonth.toStringAsFixed(2)}',
              Icons.calendar_today_rounded, const Color(0xFFFBBF24), 180),
        ]),
        const SizedBox(height: 24),
        // Top fans
        Text('Top fans', style: GoogleFonts.inter(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        _TopFanRow('SuperFan22', '\$50.00', 1),
        _TopFanRow('DailyView',  '\$25.00', 2),
        _TopFanRow('AlexG',      '\$12.00', 3),
        _TopFanRow('CreatorFan', '\$20.00', 4),
        _TopFanRow('DevJay',     '\$10.00', 5),
      ]),
    );
  }
}

// ─── Profile page ─────────────────────────────────────────────────────────────
class _ProfilePage extends StatelessWidget {
  final String tipLink;
  final VoidCallback onCopyLink;
  const _ProfilePage({required this.tipLink, required this.onCopyLink});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      padding: EdgeInsets.all(w > 900 ? 32 : 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Your profile', style: GoogleFonts.inter(
            color: Colors.white, fontWeight: FontWeight.w800,
            fontSize: 22, letterSpacing: -0.5))
            .animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 24),
        // Profile card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: kCardBg, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 64, height: 64,
                decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Your Name', style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                Text('@yourname', style: GoogleFonts.inter(color: kMuted, fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(color: kPrimary.withOpacity(0.3)),
                  ),
                  child: Text('Creator', style: GoogleFonts.inter(
                      color: kPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
                ),
              ]),
              const Spacer(),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary, foregroundColor: Colors.white,
                  elevation: 0, shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                ),
                child: Text('Edit profile', style: GoogleFonts.inter(
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
              decoration: BoxDecoration(
                color: kDark, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder),
              ),
              child: Row(children: [
                const Icon(Icons.link_rounded, color: kMuted, size: 16),
                const SizedBox(width: 10),
                Expanded(child: Text(tipLink,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13))),
                GestureDetector(
                  onTap: onCopyLink,
                  child: const Icon(Icons.copy_rounded, color: kMuted, size: 16),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        // Profile completion
        _ProfileCompletion(),
        const SizedBox(height: 20),
        // Payout settings
        _PayoutSettings(),
      ]),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _Tip {
  final String username, displayName, time, message;
  final double amount;
  const _Tip(this.username, this.displayName, this.amount, this.message, this.time);
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
    decoration: BoxDecoration(
      color: kCardBg, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(height: 14),
      Text(value, style: GoogleFonts.inter(
          color: Colors.white, fontWeight: FontWeight.w800,
          fontSize: 20, letterSpacing: -0.5)),
      const SizedBox(height: 3),
      Text(label, style: GoogleFonts.inter(color: kMuted, fontSize: 12)),
    ]),
  ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
   .slideY(begin: 0.1);
}

class _TipRow extends StatelessWidget {
  final _Tip tip;
  final bool showDate;
  const _TipRow({required this.tip, this.showDate = false});

  Color get _avatarColor {
    final colors = [kPrimary, const Color(0xFF60A5FA), const Color(0xFFF472B6),
        const Color(0xFFFBBF24), const Color(0xFF818CF8)];
    return colors[tip.username.length % colors.length];
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: kCardBg, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kBorder),
    ),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: _avatarColor.withOpacity(0.15), shape: BoxShape.circle),
        child: Center(child: Text(tip.displayName[0],
            style: GoogleFonts.inter(color: _avatarColor,
                fontWeight: FontWeight.w800, fontSize: 15))),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(tip.displayName, style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(width: 8),
          Text(tip.time, style: GoogleFonts.inter(color: kMuted, fontSize: 11)),
        ]),
        if (tip.message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(tip.message,
                style: GoogleFonts.inter(color: kMuted, fontSize: 12, height: 1.4),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
      ])),
      const SizedBox(width: 12),
      Text('\$${tip.amount.toStringAsFixed(2)}',
          style: GoogleFonts.inter(
              color: kPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
    ]),
  );
}

class _WeeklyChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  const _WeeklyChart({required this.data, required this.labels});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: kCardBg, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('This week', style: GoogleFonts.inter(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
        const Spacer(),
        Text('\$${data.fold(0.0, (a, b) => a + b).toStringAsFixed(0)} total',
            style: GoogleFonts.inter(color: kPrimary, fontWeight: FontWeight.w700,
                fontSize: 13)),
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

class _BarChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  _BarChartPainter({required this.data, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = data.reduce(math.max);
    final barW = (size.width / data.length) * 0.5;
    final gap   = (size.width / data.length) * 0.5;
    final textH = 18.0;
    final chartH = size.height - textH;

    for (var i = 0; i < data.length; i++) {
      final x = i * (barW + gap) + gap / 2;
      final barH = (data[i] / maxVal) * chartH * 0.88;
      final y = chartH - barH;

      // Bar
      final paint = Paint()
        ..color = i == 5 ? kPrimary : kPrimary.withOpacity(0.35)
        ..style = PaintingStyle.fill;
      final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barW, barH), const Radius.circular(4));
      canvas.drawRRect(rrect, paint);

      // Label
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(color: kMuted, fontSize: 10,
              fontFamily: 'Inter', fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + barW / 2 - tp.width / 2, chartH + 4));
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _TopFanRow extends StatelessWidget {
  final String name, amount;
  final int rank;
  const _TopFanRow(this.name, this.amount, this.rank);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kCardBg, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kBorder),
    ),
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

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: kPrimary.withOpacity(0.07),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kPrimary.withOpacity(0.25)),
    ),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.account_balance_rounded, color: kPrimary, size: 20),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('\$${pendingPayout.toStringAsFixed(2)} pending payout',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        Text('Scheduled to arrive in your bank in 1-2 business days.',
            style: GoogleFonts.inter(color: kMuted, fontSize: 12)),
      ])),
      const SizedBox(width: 12),
      ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary, foregroundColor: Colors.white,
          elevation: 0, shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
        ),
        child: Text('Request payout', style: GoogleFonts.inter(
            fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white)),
      ),
    ]),
  );
}

class _ProfileCompletion extends StatelessWidget {
  const _ProfileCompletion();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: kCardBg, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Profile completion', style: GoogleFonts.inter(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        const Spacer(),
        Text('70%', style: GoogleFonts.inter(
            color: kPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
      ]),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: 0.7, minHeight: 6,
          backgroundColor: kBorder,
          valueColor: const AlwaysStoppedAnimation<Color>(kPrimary),
        ),
      ),
      const SizedBox(height: 16),
      ...[
        ('Add a profile photo',    true),
        ('Write your tagline',     true),
        ('Set a monthly goal',     true),
        ('Connect your bank',      false),
        ('Share your tip link',    false),
      ].map((item) => Padding(
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
  );
}

class _PayoutSettings extends StatelessWidget {
  const _PayoutSettings();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: kCardBg, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Payout settings', style: GoogleFonts.inter(
          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 16),
      _SettingRow(Icons.account_balance_rounded, 'Bank account',   'Not connected'),
      _SettingRow(Icons.schedule_rounded,        'Payout schedule','Automatic (T+2)'),
      _SettingRow(Icons.currency_exchange_rounded,'Currency',      'USD'),
    ]),
  );
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _SettingRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Icon(icon, color: kMuted, size: 16),
      const SizedBox(width: 10),
      Text(label, style: GoogleFonts.inter(color: kMuted, fontSize: 13)),
      const Spacer(),
      Text(value, style: GoogleFonts.inter(
          color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(width: 8),
      const Icon(Icons.chevron_right_rounded, color: kMuted, size: 16),
    ]),
  );
}
