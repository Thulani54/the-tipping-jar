import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────

class AdminPortalScreen extends StatefulWidget {
  const AdminPortalScreen({super.key});

  @override
  State<AdminPortalScreen> createState() => _AdminPortalScreenState();
}

class _AdminPortalScreenState extends State<AdminPortalScreen> {
  int _tab = 0;

  static const _tabs = [
    (Icons.dashboard_outlined, 'Overview'),
    (Icons.people_outline, 'Users'),
    (Icons.receipt_long_outlined, 'Tips'),
    (Icons.verified_user_outlined, 'Creators'),
    (Icons.business_outlined, 'Enterprises'),
    (Icons.article_outlined, 'Blog'),
    (Icons.work_outline, 'Careers'),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final api = ApiService(authToken: auth.accessToken);
    final w = MediaQuery.of(context).size.width;
    final desktop = w > 900;

    Widget body;
    switch (_tab) {
      case 0: body = _OverviewTab(api: api); break;
      case 1: body = _UsersTab(api: api); break;
      case 2: body = _TipsTab(api: api); break;
      case 3: body = _CreatorsTab(api: api); break;
      case 4: body = _EnterprisesTab(api: api); break;
      case 5: body = _BlogTab(api: api); break;
      case 6: body = _CareersTab(api: api); break;
      default: body = const SizedBox();
    }

    if (desktop) {
      return Scaffold(
        backgroundColor: kDark,
        body: Row(children: [
          _Sidebar(
            selected: _tab,
            onSelect: (i) => setState(() => _tab = i),
            onLogout: () => _logout(context),
          ),
          Expanded(child: body),
        ]),
      );
    }

    return Scaffold(
      backgroundColor: kDark,
      appBar: AppBar(
        backgroundColor: kDarker,
        elevation: 0,
        title: Text('Admin Portal', style: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: kMuted, size: 20),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        backgroundColor: kDarker,
        indicatorColor: kPrimary.withOpacity(0.15),
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: _tabs.map((t) => NavigationDestination(
          icon: Icon(t.$1, color: kMuted, size: 20),
          selectedIcon: Icon(t.$1, color: kPrimary, size: 20),
          label: t.$2,
        )).toList(),
      ),
    );
  }

  Future<void> _logout(BuildContext ctx) async {
    await ctx.read<AuthProvider>().logout();
    if (ctx.mounted) ctx.go('/login');
  }
}

// ─── Sidebar (desktop) ────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  const _Sidebar({required this.selected, required this.onSelect, required this.onLogout});

  static const _tabs = [
    (Icons.dashboard_outlined, 'Overview'),
    (Icons.people_outline, 'Users'),
    (Icons.receipt_long_outlined, 'Tips'),
    (Icons.verified_user_outlined, 'Creators'),
    (Icons.business_outlined, 'Enterprises'),
    (Icons.article_outlined, 'Blog'),
    (Icons.work_outline, 'Careers'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    width: 220,
    color: kDarker,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 32),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: kPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.admin_panel_settings, color: kPrimary, size: 20),
          ),
          const SizedBox(height: 10),
          Text('Admin Portal', style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          Text('TippingJar', style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
        ]),
      ),
      const SizedBox(height: 28),
      const Divider(color: kBorder, height: 1),
      const SizedBox(height: 12),
      ..._tabs.asMap().entries.map((e) => _SidebarItem(
        icon: e.value.$1,
        label: e.value.$2,
        active: selected == e.key,
        onTap: () => onSelect(e.key),
      )),
      const Spacer(),
      const Divider(color: kBorder, height: 1),
      _SidebarItem(
        icon: Icons.logout,
        label: 'Logout',
        active: false,
        onTap: onLogout,
      ),
      const SizedBox(height: 16),
    ]),
  );
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SidebarItem({required this.icon, required this.label,
      required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? kPrimary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: active ? kPrimary : kMuted),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.dmSans(
              color: active ? kPrimary : kMuted,
              fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w500)),
        ]),
      ),
    ),
  );
}

// ─── Overview ─────────────────────────────────────────────────────────────────

class _OverviewTab extends StatefulWidget {
  final ApiService api;
  const _OverviewTab({required this.api});
  @override State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final s = await widget.api.getAdminStats();
      if (mounted) setState(() { _stats = s; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _Loader();
    final s = _stats ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionTitle('Platform Overview'),
        const SizedBox(height: 20),
        Wrap(spacing: 16, runSpacing: 16, children: [
          _StatCard('Total Users',       '${s['total_users'] ?? 0}',   Icons.people,          const Color(0xFF818CF8)),
          _StatCard('Creators',          '${s['total_creators'] ?? 0}', Icons.person_pin,       kPrimary),
          _StatCard('Fans',              '${s['total_fans'] ?? 0}',    Icons.favorite,         const Color(0xFFF87171)),
          _StatCard('Enterprises',       '${s['total_enterprises'] ?? 0}', Icons.business,     const Color(0xFF0097B2)),
          _StatCard('Total Tips',        '${s['total_tips'] ?? 0}',    Icons.receipt_long,     const Color(0xFFFBBF24)),
          _StatCard('Volume (R)',        'R ${_fmt(s['total_volume'])}', Icons.attach_money,   const Color(0xFF34D399)),
          _StatCard('Tips Today',        '${s['tips_today'] ?? 0}',    Icons.today,            kPrimary),
          _StatCard('Tips This Month',   '${s['tips_this_month'] ?? 0}', Icons.calendar_month, const Color(0xFF818CF8)),
          _StatCard('Pending KYC',       '${s['pending_kyc'] ?? 0}',  Icons.pending_actions,  const Color(0xFFFBBF24)),
          _StatCard('Pending Enterprises', '${s['pending_enterprises'] ?? 0}', Icons.hourglass_top, const Color(0xFFF87171)),
          _StatCard('Published Blogs',   '${s['published_blogs'] ?? 0}', Icons.article,        const Color(0xFF34D399)),
        ]),
      ]),
    );
  }

  String _fmt(dynamic v) {
    if (v == null) return '0';
    final d = double.tryParse(v.toString()) ?? 0;
    return d >= 1000 ? '${(d / 1000).toStringAsFixed(1)}k' : d.toStringAsFixed(0);
  }
}

// ─── Users tab ────────────────────────────────────────────────────────────────

class _UsersTab extends StatefulWidget {
  final ApiService api;
  const _UsersTab({required this.api});
  @override State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String _roleFilter = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await widget.api.getAdminUsers(
        role: _roleFilter.isEmpty ? null : _roleFilter,
        search: _searchCtrl.text.trim(),
      );
      if (mounted) setState(() { _users = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Filters
      Container(
        color: kDarker,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(children: [
          Expanded(child: _SearchField(ctrl: _searchCtrl, onSubmit: _load)),
          const SizedBox(width: 12),
          _RoleChip('All', '', _roleFilter, (v) { setState(() => _roleFilter = v); _load(); }),
          _RoleChip('Fan', 'fan', _roleFilter, (v) { setState(() => _roleFilter = v); _load(); }),
          _RoleChip('Creator', 'creator', _roleFilter, (v) { setState(() => _roleFilter = v); _load(); }),
          _RoleChip('Enterprise', 'enterprise', _roleFilter, (v) { setState(() => _roleFilter = v); _load(); }),
          _RoleChip('Admin', 'admin', _roleFilter, (v) { setState(() => _roleFilter = v); _load(); }),
        ]),
      ),
      if (_loading) const Expanded(child: _Loader())
      else Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _users.length,
          itemBuilder: (_, i) {
            final u = _users[i];
            final roleColor = _roleColor(u['role'] as String? ?? '');
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: kCardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kBorder)),
              child: Row(children: [
                Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: roleColor.withOpacity(0.15), shape: BoxShape.circle),
                  child: Center(child: Text(
                    (u['email'] as String? ?? 'U')[0].toUpperCase(),
                    style: GoogleFonts.dmSans(color: roleColor, fontWeight: FontWeight.w700),
                  )),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(u['email'] as String? ?? '', style: GoogleFonts.dmSans(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim().isNotEmpty
                      ? '${u['first_name']} ${u['last_name']}'.trim()
                      : u['username'] as String? ?? '',
                      style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
                ])),
                _RoleBadge(u['role'] as String? ?? ''),
                const SizedBox(width: 12),
                _ActiveDot(u['is_active'] as bool? ?? true),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  color: kCardBg,
                  icon: const Icon(Icons.more_vert, color: kMuted, size: 18),
                  onSelected: (val) => _onUserAction(u, val),
                  itemBuilder: (_) => [
                    if ((u['is_active'] as bool? ?? true))
                      const PopupMenuItem(value: 'deactivate', child: Text('Deactivate', style: TextStyle(color: Colors.white, fontSize: 13))),
                    if (!(u['is_active'] as bool? ?? true))
                      const PopupMenuItem(value: 'activate', child: Text('Activate', style: TextStyle(color: Colors.white, fontSize: 13))),
                    const PopupMenuItem(value: 'make_admin', child: Text('Make Admin', style: TextStyle(color: Colors.white, fontSize: 13))),
                    const PopupMenuItem(value: 'make_fan', child: Text('Set as Fan', style: TextStyle(color: Colors.white, fontSize: 13))),
                  ],
                ),
              ]),
            );
          },
        ),
      ),
    ]);
  }

  Future<void> _onUserAction(Map<String, dynamic> user, String action) async {
    final id = user['id'] as int;
    try {
      switch (action) {
        case 'deactivate': await widget.api.adminUpdateUser(id, {'is_active': false}); break;
        case 'activate':   await widget.api.adminUpdateUser(id, {'is_active': true}); break;
        case 'make_admin': await widget.api.adminUpdateUser(id, {'role': 'admin'}); break;
        case 'make_fan':   await widget.api.adminUpdateUser(id, {'role': 'fan'}); break;
      }
      _load();
    } catch (e) {
      if (mounted) _showSnack(e.toString(), error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : kPrimary,
    ));
  }
}

// ─── Tips tab ─────────────────────────────────────────────────────────────────

class _TipsTab extends StatefulWidget {
  final ApiService api;
  const _TipsTab({required this.api});
  @override State<_TipsTab> createState() => _TipsTabState();
}

class _TipsTabState extends State<_TipsTab> {
  List<Map<String, dynamic>> _tips = [];
  bool _loading = true;
  String _statusFilter = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await widget.api.getAdminTips(
        tipStatus: _statusFilter.isEmpty ? null : _statusFilter,
        search: _searchCtrl.text.trim(),
      );
      if (mounted) setState(() { _tips = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _tips.fold<double>(0, (s, t) =>
        s + (double.tryParse(t['amount']?.toString() ?? '0') ?? 0));

    return Column(children: [
      Container(
        color: kDarker,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(children: [
          Expanded(child: _SearchField(ctrl: _searchCtrl, hint: 'Search email or creator…', onSubmit: _load)),
          const SizedBox(width: 12),
          for (final s in ['', 'completed', 'pending', 'failed', 'refunded'])
            _RoleChip(s.isEmpty ? 'All' : s[0].toUpperCase() + s.substring(1),
                s, _statusFilter, (v) { setState(() => _statusFilter = v); _load(); }),
        ]),
      ),
      Container(
        color: kDarker.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(children: [
          Text('${_tips.length} tips', style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
          const SizedBox(width: 16),
          Text('Total: R${total.toStringAsFixed(2)}',
              style: GoogleFonts.dmSans(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
      if (_loading) const Expanded(child: _Loader())
      else Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _tips.length,
          itemBuilder: (_, i) {
            final t = _tips[i];
            final st = t['status'] as String? ?? '';
            final stColor = st == 'completed' ? const Color(0xFF34D399)
                : st == 'failed' ? const Color(0xFFF87171)
                : st == 'refunded' ? const Color(0xFF818CF8)
                : kMuted;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: kCardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kBorder)),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('R${t['amount'] ?? '0'}',
                        style: GoogleFonts.dmSans(color: Colors.white,
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: stColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(st, style: GoogleFonts.dmSans(
                          color: stColor, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text('From: ${t['tipper_name'] ?? ''} (${t['tipper_email'] ?? ''})',
                      style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
                  Text('To: ${t['creator_name'] ?? t['creator_slug'] ?? ''}',
                      style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
                  if ((t['message'] as String? ?? '').isNotEmpty)
                    Text('"${t['message']}"',
                        style: GoogleFonts.dmSans(color: kMuted, fontSize: 11,
                            fontStyle: FontStyle.italic)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(_shortDate(t['created_at'] as String? ?? ''),
                      style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
                  if ((t['paystack_reference'] as String? ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Ref: ${t['paystack_reference']}',
                        style: GoogleFonts.dmSans(color: kMuted, fontSize: 10),
                        overflow: TextOverflow.ellipsis),
                  ],
                ]),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}

// ─── Creators tab ─────────────────────────────────────────────────────────────

class _CreatorsTab extends StatefulWidget {
  final ApiService api;
  const _CreatorsTab({required this.api});
  @override State<_CreatorsTab> createState() => _CreatorsTabState();
}

class _CreatorsTabState extends State<_CreatorsTab> {
  List<Map<String, dynamic>> _creators = [];
  bool _loading = true;
  String _kycFilter = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await widget.api.getAdminCreators(
        kycStatus: _kycFilter.isEmpty ? null : _kycFilter,
        search: _searchCtrl.text.trim(),
      );
      if (mounted) setState(() { _creators = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: kDarker,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(children: [
          Expanded(child: _SearchField(ctrl: _searchCtrl, hint: 'Search creator…', onSubmit: _load)),
          const SizedBox(width: 12),
          for (final k in ['', 'not_started', 'pending', 'approved', 'declined'])
            _RoleChip(k.isEmpty ? 'All' : k.replaceAll('_', ' ').toUpperCase().substring(0, 1) + k.replaceAll('_', ' ').substring(1).toLowerCase(),
                k, _kycFilter, (v) { setState(() => _kycFilter = v); _load(); }),
        ]),
      ),
      if (_loading) const Expanded(child: _Loader())
      else Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _creators.length,
          itemBuilder: (_, i) => _CreatorCard(
            creator: _creators[i],
            onApprove: () async {
              await widget.api.adminKycApprove(_creators[i]['id'] as int);
              _load();
            },
            onDecline: (reason) async {
              await widget.api.adminKycDecline(_creators[i]['id'] as int, reason);
              _load();
            },
          ),
        ),
      ),
    ]);
  }
}

class _CreatorCard extends StatelessWidget {
  final Map<String, dynamic> creator;
  final VoidCallback onApprove;
  final ValueChanged<String> onDecline;
  const _CreatorCard({required this.creator, required this.onApprove, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    final kyc = creator['kyc_status'] as String? ?? 'not_started';
    final kycColor = kyc == 'approved' ? const Color(0xFF34D399)
        : kyc == 'declined' ? const Color(0xFFF87171)
        : kyc == 'pending' ? const Color(0xFFFBBF24)
        : kMuted;
    final docs = (creator['kyc_documents'] as List? ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(creator['display_name'] as String? ?? '', style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            Text(creator['email'] as String? ?? '',
                style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: kycColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20)),
            child: Text('KYC: $kyc'.replaceAll('_', ' '), style: GoogleFonts.dmSans(
                color: kycColor, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 10),
        // Bank info
        if ((creator['bank_name'] as String? ?? '').isNotEmpty)
          _InfoRow('Bank', '${creator['bank_name']} — ${creator['bank_account_number']}'),
        if ((creator['bank_account_holder'] as String? ?? '').isNotEmpty)
          _InfoRow('Account Holder', creator['bank_account_holder'] as String),
        if ((creator['bank_country'] as String? ?? '').isNotEmpty)
          _InfoRow('Country', creator['bank_country'] as String),
        _InfoRow('Total Tips', 'R${creator['total_tips'] ?? 0}'),
        // KYC documents
        if (docs.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Documents:', style: GoogleFonts.dmSans(
              color: kMuted, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Wrap(spacing: 8, runSpacing: 4, children: docs.map<Widget>((d) {
            final docStatus = d['status'] as String? ?? 'pending';
            final dc = docStatus == 'approved' ? const Color(0xFF34D399)
                : docStatus == 'declined' ? const Color(0xFFF87171) : kMuted;
            return GestureDetector(
              onTap: () {
                final url = d['file'] as String? ?? '';
                if (url.isNotEmpty) _openUrl(context, url);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: dc.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: dc.withOpacity(0.3))),
                child: Text('${d['doc_type'] ?? ''} ↗',
                    style: GoogleFonts.dmSans(color: dc, fontSize: 10)),
              ),
            );
          }).toList()),
        ],
        if (kyc == 'pending') ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ElevatedButton.icon(
              onPressed: onApprove,
              icon: const Icon(Icons.check, size: 15),
              label: const Text('Approve KYC'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF34D399),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            )),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _showDeclineDialog(context),
              icon: const Icon(Icons.close, size: 15),
              label: const Text('Decline'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF87171),
                  side: const BorderSide(color: Color(0xFFF87171)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            )),
          ]),
        ],
      ]),
    );
  }

  void _openUrl(BuildContext ctx, String url) {
    // navigate to external URL
  }

  Future<void> _showDeclineDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardBg,
        title: Text('Decline KYC', style: GoogleFonts.dmSans(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Reason (optional)',
            hintStyle: const TextStyle(color: kMuted),
            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: kBorder),
                borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: kPrimary),
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: kMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF87171)),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    if (ok == true) onDecline(ctrl.text.trim());
  }
}

// ─── Enterprises tab ──────────────────────────────────────────────────────────

class _EnterprisesTab extends StatefulWidget {
  final ApiService api;
  const _EnterprisesTab({required this.api});
  @override State<_EnterprisesTab> createState() => _EnterprisesTabState();
}

class _EnterprisesTabState extends State<_EnterprisesTab> {
  List<Map<String, dynamic>> _enterprises = [];
  bool _loading = true;
  String _filter = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await widget.api.getAdminEnterprises(
          approvalStatus: _filter.isEmpty ? null : _filter);
      if (mounted) setState(() { _enterprises = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: kDarker,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(children: [
          for (final f in ['', 'pending', 'approved', 'rejected'])
            _RoleChip(
              f.isEmpty ? 'All' : f[0].toUpperCase() + f.substring(1),
              f, _filter, (v) { setState(() => _filter = v); _load(); }),
        ]),
      ),
      if (_loading) const Expanded(child: _Loader())
      else Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _enterprises.length,
          itemBuilder: (_, i) => _EnterpriseCard(
            enterprise: _enterprises[i],
            onApprove: () async {
              await widget.api.adminEnterpriseApprove(_enterprises[i]['id'] as int);
              _load();
            },
            onReject: (reason) async {
              await widget.api.adminEnterpriseReject(_enterprises[i]['id'] as int, reason);
              _load();
            },
          ),
        ),
      ),
    ]);
  }
}

class _EnterpriseCard extends StatelessWidget {
  final Map<String, dynamic> enterprise;
  final VoidCallback onApprove;
  final ValueChanged<String> onReject;
  const _EnterpriseCard({required this.enterprise, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final st = enterprise['approval_status'] as String? ?? 'pending';
    final stColor = st == 'approved' ? const Color(0xFF34D399)
        : st == 'rejected' ? const Color(0xFFF87171) : const Color(0xFFFBBF24);
    final docs = (enterprise['documents'] as List? ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(enterprise['company_name'] as String? ?? '', style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            Text(enterprise['owner_email'] as String? ?? '',
                style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: stColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20)),
            child: Text(st, style: GoogleFonts.dmSans(
                color: stColor, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 10),
        if ((enterprise['registration_number'] as String? ?? '').isNotEmpty)
          _InfoRow('Reg No.', enterprise['registration_number'] as String),
        if ((enterprise['vat_number'] as String? ?? '').isNotEmpty)
          _InfoRow('VAT', enterprise['vat_number'] as String),
        _InfoRow('Plan', enterprise['plan'] as String? ?? ''),
        _InfoRow('Contact', enterprise['contact_email'] as String? ?? ''),
        if (docs.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Documents: ${docs.length}',
              style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
        ],
        if (st == 'pending') ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ElevatedButton.icon(
              onPressed: onApprove,
              icon: const Icon(Icons.check, size: 15),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF34D399),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            )),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _showRejectDialog(context),
              icon: const Icon(Icons.close, size: 15),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF87171),
                  side: const BorderSide(color: Color(0xFFF87171)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            )),
          ]),
        ],
      ]),
    );
  }

  Future<void> _showRejectDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardBg,
        title: Text('Reject Enterprise', style: GoogleFonts.dmSans(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Reason',
            hintStyle: const TextStyle(color: kMuted),
            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: kBorder),
                borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: kPrimary),
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: kMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF87171)),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok == true) onReject(ctrl.text.trim());
  }
}

// ─── Blog tab ─────────────────────────────────────────────────────────────────

class _BlogTab extends StatefulWidget {
  final ApiService api;
  const _BlogTab({required this.api});
  @override State<_BlogTab> createState() => _BlogTabState();
}

class _BlogTabState extends State<_BlogTab> {
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await widget.api.getAdminBlogs();
      if (mounted) setState(() { _posts = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: kDarker,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(children: [
          Text('${_posts.length} posts', style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _openEditor(context, null),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Post'),
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ]),
      ),
      if (_loading) const Expanded(child: _Loader())
      else Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _posts.length,
          itemBuilder: (_, i) {
            final p = _posts[i];
            final published = p['is_published'] as bool? ?? false;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: kCardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kBorder)),
              child: Row(children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                      color: published ? const Color(0xFF34D399) : kMuted,
                      shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p['title'] as String? ?? '', style: GoogleFonts.dmSans(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('${p['category'] ?? ''} · ${p['author_name'] ?? ''} · ${_shortDate(p['created_at'] as String? ?? '')}',
                      style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
                ])),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: Icon(published ? Icons.visibility_off : Icons.visibility,
                        color: kMuted, size: 18),
                    tooltip: published ? 'Unpublish' : 'Publish',
                    onPressed: () => _togglePublish(p),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: kMuted, size: 18),
                    onPressed: () => _openEditor(context, p),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFF87171), size: 18),
                    onPressed: () => _confirmDelete(context, p),
                  ),
                ]),
              ]),
            );
          },
        ),
      ),
    ]);
  }

  Future<void> _togglePublish(Map<String, dynamic> post) async {
    final current = post['is_published'] as bool? ?? false;
    await widget.api.adminUpdateBlog(post['slug'] as String, {'is_published': !current});
    _load();
  }

  Future<void> _confirmDelete(BuildContext context, Map<String, dynamic> post) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardBg,
        title: Text('Delete Post?', style: GoogleFonts.dmSans(color: Colors.white)),
        content: Text('Are you sure you want to delete "${post['title']}"?',
            style: GoogleFonts.dmSans(color: kMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: kMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF87171)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.api.adminDeleteBlog(post['slug'] as String);
      _load();
    }
  }

  Future<void> _openEditor(BuildContext context, Map<String, dynamic>? post) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _BlogEditorDialog(api: widget.api, post: post),
    );
    if (result == true) _load();
  }
}

// ─── Blog editor dialog ───────────────────────────────────────────────────────

class _BlogEditorDialog extends StatefulWidget {
  final ApiService api;
  final Map<String, dynamic>? post;
  const _BlogEditorDialog({required this.api, this.post});
  @override State<_BlogEditorDialog> createState() => _BlogEditorDialogState();
}

class _BlogEditorDialogState extends State<_BlogEditorDialog> {
  final _titleCtrl = TextEditingController();
  final _excerptCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _readTimeCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _category = 'creator-guide';
  bool _published = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      final p = widget.post!;
      _titleCtrl.text = p['title'] as String? ?? '';
      _excerptCtrl.text = p['excerpt'] as String? ?? '';
      _authorCtrl.text = p['author_name'] as String? ?? 'TippingJar Team';
      _readTimeCtrl.text = p['read_time'] as String? ?? '5 min read';
      _contentCtrl.text = p['content'] as String? ?? '';
      _category = p['category'] as String? ?? 'creator-guide';
      _published = p['is_published'] as bool? ?? false;
    } else {
      _authorCtrl.text = 'TippingJar Team';
      _readTimeCtrl.text = '5 min read';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _excerptCtrl.dispose();
    _authorCtrl.dispose(); _readTimeCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _insertTag(String open, String close) {
    final sel = _contentCtrl.selection;
    final text = _contentCtrl.text;
    if (sel.isValid && !sel.isCollapsed) {
      final selected = text.substring(sel.start, sel.end);
      final newText = text.replaceRange(sel.start, sel.end, '$open$selected$close');
      _contentCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: sel.start + open.length + selected.length + close.length),
      );
    } else {
      final pos = sel.isValid ? sel.start : text.length;
      final newText = text.substring(0, pos) + '$open$close' + text.substring(pos);
      _contentCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: pos + open.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.post != null;
    return Dialog(
      backgroundColor: kCardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kBorder)),
            ),
            child: Row(children: [
              Text(isEdit ? 'Edit Post' : 'New Blog Post',
                  style: GoogleFonts.dmSans(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 16)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: kMuted),
                onPressed: () => Navigator.pop(context, false),
              ),
            ]),
          ),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Title
              _FieldLabel('Title'),
              _Input(ctrl: _titleCtrl, hint: 'Post title…'),
              const SizedBox(height: 14),
              // Category + Author row
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _FieldLabel('Category'),
                  DropdownButtonFormField<String>(
                    value: _category,
                    dropdownColor: kDarker,
                    style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
                    decoration: _inputDecoration(),
                    items: const [
                      DropdownMenuItem(value: 'creator-guide', child: Text('Creator Guide')),
                      DropdownMenuItem(value: 'product', child: Text('Product')),
                      DropdownMenuItem(value: 'industry', child: Text('Industry')),
                      DropdownMenuItem(value: 'company', child: Text('Company')),
                      DropdownMenuItem(value: 'tips-tricks', child: Text('Tips & Tricks')),
                    ],
                    onChanged: (v) { if (v != null) setState(() => _category = v); },
                  ),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _FieldLabel('Author'),
                  _Input(ctrl: _authorCtrl, hint: 'Author name'),
                ])),
                const SizedBox(width: 12),
                SizedBox(width: 120, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _FieldLabel('Read time'),
                  _Input(ctrl: _readTimeCtrl, hint: '5 min read'),
                ])),
              ]),
              const SizedBox(height: 14),
              // Excerpt
              _FieldLabel('Excerpt (summary shown on listing)'),
              _Input(ctrl: _excerptCtrl, hint: 'Short summary…', maxLines: 3),
              const SizedBox(height: 14),
              // Content with toolbar
              _FieldLabel('Content'),
              // Formatting toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: kDarker,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                  border: Border.all(color: kBorder),
                ),
                child: Wrap(spacing: 4, children: [
                  _ToolbarBtn('B', bold: true,  onTap: () => _insertTag('<strong>', '</strong>')),
                  _ToolbarBtn('I', italic: true, onTap: () => _insertTag('<em>', '</em>')),
                  _ToolbarBtn('U', underline: true, onTap: () => _insertTag('<u>', '</u>')),
                  _ToolbarDivider(),
                  _ToolbarBtn('H1', onTap: () => _insertTag('<h1>', '</h1>')),
                  _ToolbarBtn('H2', onTap: () => _insertTag('<h2>', '</h2>')),
                  _ToolbarBtn('H3', onTap: () => _insertTag('<h3>', '</h3>')),
                  _ToolbarDivider(),
                  _ToolbarBtn('• List', onTap: () => _insertTag('<ul>\n  <li>', '</li>\n</ul>')),
                  _ToolbarBtn('1. List', onTap: () => _insertTag('<ol>\n  <li>', '</li>\n</ol>')),
                  _ToolbarDivider(),
                  _ToolbarBtn('Link', onTap: () => _insertTag('<a href="">', '</a>')),
                  _ToolbarBtn('" Quote', onTap: () => _insertTag('<blockquote>', '</blockquote>')),
                  _ToolbarBtn('`Code`', onTap: () => _insertTag('<code>', '</code>')),
                  _ToolbarBtn('--- HR', onTap: () {
                    final pos = _contentCtrl.selection.isValid
                        ? _contentCtrl.selection.start : _contentCtrl.text.length;
                    final t = _contentCtrl.text;
                    _contentCtrl.value = TextEditingValue(
                      text: t.substring(0, pos) + '\n<hr>\n' + t.substring(pos),
                      selection: TextSelection.collapsed(offset: pos + 6),
                    );
                  }),
                ]),
              ),
              TextField(
                controller: _contentCtrl,
                maxLines: 16,
                style: GoogleFonts.dmMono(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Write your post content in HTML…\n\nExample:\n<p>Hello world</p>\n<h2>A heading</h2>',
                  hintStyle: GoogleFonts.dmMono(color: kMuted, fontSize: 12),
                  filled: true,
                  fillColor: kDark,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                    borderSide: const BorderSide(color: kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                    borderSide: const BorderSide(color: kBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                    borderSide: const BorderSide(color: kPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Published toggle
              Row(children: [
                Switch(value: _published,
                    activeColor: kPrimary,
                    onChanged: (v) => setState(() => _published = v)),
                const SizedBox(width: 8),
                Text(_published ? 'Published (visible on site)' : 'Draft (hidden from public)',
                    style: GoogleFonts.dmSans(
                        color: _published ? const Color(0xFF34D399) : kMuted, fontSize: 13)),
              ]),
            ]),
          )),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: kBorder))),
            child: Row(children: [
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(color: kMuted)),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: _saving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isEdit ? 'Save Changes' : 'Create Post'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _excerptCtrl.text.trim().isEmpty ||
        _contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Title, excerpt and content are required.'),
          backgroundColor: Colors.red));
      return;
    }
    setState(() => _saving = true);
    try {
      final data = {
        'title': _titleCtrl.text.trim(),
        'excerpt': _excerptCtrl.text.trim(),
        'content': _contentCtrl.text.trim(),
        'category': _category,
        'author_name': _authorCtrl.text.trim(),
        'read_time': _readTimeCtrl.text.trim(),
        'is_published': _published,
      };
      if (widget.post != null) {
        await widget.api.adminUpdateBlog(widget.post!['slug'] as String, data);
      } else {
        await widget.api.adminCreateBlog(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Careers tab ─────────────────────────────────────────────────────────────

class _CareersTab extends StatefulWidget {
  final ApiService api;
  const _CareersTab({required this.api});
  @override State<_CareersTab> createState() => _CareersTabState();
}

class _CareersTabState extends State<_CareersTab> {
  List<Map<String, dynamic>> _jobs = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await widget.api.getAdminJobs();
      if (mounted) setState(() { _jobs = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: kDarker,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(children: [
          Text('${_jobs.length} roles', style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _openEditor(context, null),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Role'),
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ]),
      ),
      if (_loading) const Expanded(child: _Loader())
      else Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _jobs.length,
          itemBuilder: (_, i) {
            final j = _jobs[i];
            final active = j['is_active'] as bool? ?? true;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: kCardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kBorder)),
              child: Row(children: [
                Container(width: 8, height: 8,
                    decoration: BoxDecoration(
                        color: active ? const Color(0xFF34D399) : kMuted,
                        shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(j['title'] as String? ?? '', style: GoogleFonts.dmSans(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('${j['department'] ?? ''} · ${j['location'] ?? ''} · ${j['employment_type'] ?? ''}',
                      style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
                ])),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: Icon(active ? Icons.visibility_off : Icons.visibility,
                        color: kMuted, size: 18),
                    tooltip: active ? 'Deactivate' : 'Activate',
                    onPressed: () => _toggleActive(j),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: kMuted, size: 18),
                    onPressed: () => _openEditor(context, j),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFF87171), size: 18),
                    onPressed: () => _confirmDelete(context, j),
                  ),
                ]),
              ]),
            );
          },
        ),
      ),
    ]);
  }

  Future<void> _toggleActive(Map<String, dynamic> job) async {
    final current = job['is_active'] as bool? ?? true;
    await widget.api.adminUpdateJob(job['id'] as int, {'is_active': !current});
    _load();
  }

  Future<void> _confirmDelete(BuildContext context, Map<String, dynamic> job) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardBg,
        title: Text('Delete Role?', style: GoogleFonts.dmSans(color: Colors.white)),
        content: Text('Delete "${job['title']}"?',
            style: GoogleFonts.dmSans(color: kMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: kMuted))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF87171)),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await widget.api.adminDeleteJob(job['id'] as int);
      _load();
    }
  }

  Future<void> _openEditor(BuildContext context, Map<String, dynamic>? job) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _JobEditorDialog(api: widget.api, job: job),
    );
    if (result == true) _load();
  }
}

// ─── Job editor dialog ────────────────────────────────────────────────────────

class _JobEditorDialog extends StatefulWidget {
  final ApiService api;
  final Map<String, dynamic>? job;
  const _JobEditorDialog({required this.api, this.job});
  @override State<_JobEditorDialog> createState() => _JobEditorDialogState();
}

class _JobEditorDialogState extends State<_JobEditorDialog> {
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _department = 'Engineering';
  String _employmentType = 'Full-time';
  bool _active = true;
  bool _saving = false;

  static const _departments = [
    'Engineering', 'Design', 'Growth', 'Operations',
    'Marketing', 'Product', 'Finance', 'Other',
  ];
  static const _types = ['Full-time', 'Part-time', 'Contract', 'Internship'];

  @override
  void initState() {
    super.initState();
    if (widget.job != null) {
      final j = widget.job!;
      _titleCtrl.text = j['title'] as String? ?? '';
      _locationCtrl.text = j['location'] as String? ?? 'Remote';
      _descCtrl.text = j['description'] as String? ?? '';
      _department = j['department'] as String? ?? 'Engineering';
      _employmentType = j['employment_type'] as String? ?? 'Full-time';
      _active = j['is_active'] as bool? ?? true;
    } else {
      _locationCtrl.text = 'Remote';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _locationCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  void _insertTag(String open, String close) {
    final sel = _descCtrl.selection;
    final text = _descCtrl.text;
    if (sel.isValid && !sel.isCollapsed) {
      final selected = text.substring(sel.start, sel.end);
      final newText = text.replaceRange(sel.start, sel.end, '$open$selected$close');
      _descCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
            offset: sel.start + open.length + selected.length + close.length),
      );
    } else {
      final pos = sel.isValid ? sel.start : text.length;
      final newText = text.substring(0, pos) + '$open$close' + text.substring(pos);
      _descCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: pos + open.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.job != null;
    return Dialog(
      backgroundColor: kCardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: 680, maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
            child: Row(children: [
              Text(isEdit ? 'Edit Role' : 'New Job Opening',
                  style: GoogleFonts.dmSans(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 16)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close, color: kMuted),
                  onPressed: () => Navigator.pop(context, false)),
            ]),
          ),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _FieldLabel('Job Title'),
              _Input(ctrl: _titleCtrl, hint: 'e.g. Senior Flutter Engineer'),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _FieldLabel('Department'),
                  DropdownButtonFormField<String>(
                    value: _department,
                    dropdownColor: kDarker,
                    style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
                    decoration: _inputDecoration(),
                    items: _departments.map((d) =>
                        DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (v) { if (v != null) setState(() => _department = v); },
                  ),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _FieldLabel('Type'),
                  DropdownButtonFormField<String>(
                    value: _employmentType,
                    dropdownColor: kDarker,
                    style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
                    decoration: _inputDecoration(),
                    items: _types.map((t) =>
                        DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) { if (v != null) setState(() => _employmentType = v); },
                  ),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _FieldLabel('Location'),
                  _Input(ctrl: _locationCtrl, hint: 'Remote'),
                ])),
              ]),
              const SizedBox(height: 14),
              _FieldLabel('Job Description'),
              // Toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: kDarker,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                  border: Border.all(color: kBorder),
                ),
                child: Wrap(spacing: 4, children: [
                  _ToolbarBtn('B', bold: true,   onTap: () => _insertTag('<strong>', '</strong>')),
                  _ToolbarBtn('I', italic: true,  onTap: () => _insertTag('<em>', '</em>')),
                  _ToolbarBtn('U', underline: true, onTap: () => _insertTag('<u>', '</u>')),
                  _ToolbarDivider(),
                  _ToolbarBtn('H2', onTap: () => _insertTag('<h2>', '</h2>')),
                  _ToolbarBtn('H3', onTap: () => _insertTag('<h3>', '</h3>')),
                  _ToolbarDivider(),
                  _ToolbarBtn('• List', onTap: () => _insertTag('<ul>\n  <li>', '</li>\n</ul>')),
                  _ToolbarBtn('1. List', onTap: () => _insertTag('<ol>\n  <li>', '</li>\n</ol>')),
                ]),
              ),
              TextField(
                controller: _descCtrl,
                maxLines: 12,
                style: GoogleFonts.dmMono(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Describe the role, responsibilities, requirements…',
                  hintStyle: GoogleFonts.dmMono(color: kMuted, fontSize: 12),
                  filled: true, fillColor: kDark,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                    borderSide: const BorderSide(color: kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                    borderSide: const BorderSide(color: kBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                    borderSide: const BorderSide(color: kPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Switch(value: _active, activeColor: kPrimary,
                    onChanged: (v) => setState(() => _active = v)),
                const SizedBox(width: 8),
                Text(_active ? 'Active (visible on careers page)' : 'Inactive (hidden)',
                    style: GoogleFonts.dmSans(
                        color: _active ? const Color(0xFF34D399) : kMuted, fontSize: 13)),
              ]),
            ]),
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: kBorder))),
            child: Row(children: [
              const Spacer(),
              TextButton(onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel', style: TextStyle(color: kMuted))),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: _saving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isEdit ? 'Save Changes' : 'Create Role'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Job title is required.'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _saving = true);
    try {
      final data = {
        'title': _titleCtrl.text.trim(),
        'department': _department,
        'location': _locationCtrl.text.trim().isEmpty ? 'Remote' : _locationCtrl.text.trim(),
        'employment_type': _employmentType,
        'description': _descCtrl.text.trim(),
        'is_active': _active,
      };
      if (widget.job != null) {
        await widget.api.adminUpdateJob(widget.job!['id'] as int, data);
      } else {
        await widget.api.adminCreateJob(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
    width: 180,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18)),
      const SizedBox(height: 12),
      Text(value, style: GoogleFonts.dmSans(
          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
      const SizedBox(height: 4),
      Text(label, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
    ]),
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: GoogleFonts.dmSans(
      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18));
}

class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) =>
      const Center(child: SpinKitFadingCircle(color: kPrimary, size: 32));
}

class _RoleChip extends StatelessWidget {
  final String label, value, current;
  final ValueChanged<String> onSelect;
  const _RoleChip(this.label, this.value, this.current, this.onSelect);

  @override
  Widget build(BuildContext context) {
    final active = current == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? kPrimary.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? kPrimary.withOpacity(0.4) : kBorder),
          ),
          child: Text(label, style: GoogleFonts.dmSans(
              color: active ? kPrimary : kMuted,
              fontSize: 11, fontWeight: active ? FontWeight.w600 : FontWeight.w500)),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final VoidCallback onSubmit;
  const _SearchField({required this.ctrl, this.hint = 'Search…', required this.onSubmit});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
    onSubmitted: (_) => onSubmit(),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 13),
      prefixIcon: const Icon(Icons.search, color: kMuted, size: 18),
      filled: true, fillColor: kDark,
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kPrimary)),
    ),
  );
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge(this.role);
  @override
  Widget build(BuildContext context) {
    final c = _roleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Text(role, style: GoogleFonts.dmSans(
          color: c, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _ActiveDot extends StatelessWidget {
  final bool active;
  const _ActiveDot(this.active);
  @override
  Widget build(BuildContext context) => Container(
    width: 8, height: 8,
    decoration: BoxDecoration(
        color: active ? const Color(0xFF34D399) : const Color(0xFFF87171),
        shape: BoxShape.circle),
  );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(children: [
      Text('$label: ', style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
      Expanded(child: Text(value, style: GoogleFonts.dmSans(
          color: Colors.white, fontSize: 11), overflow: TextOverflow.ellipsis)),
    ]),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: GoogleFonts.dmSans(
        color: kMuted, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

class _Input extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final int maxLines;
  const _Input({required this.ctrl, required this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    maxLines: maxLines,
    style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
    decoration: _inputDecoration(hint: hint),
  );
}

InputDecoration _inputDecoration({String hint = ''}) => InputDecoration(
  hintText: hint,
  hintStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 13),
  filled: true, fillColor: kDark,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: kBorder)),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: kBorder)),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: kPrimary)),
);

class _ToolbarBtn extends StatelessWidget {
  final String label;
  final bool bold, italic, underline;
  final VoidCallback onTap;
  const _ToolbarBtn(this.label, {this.bold = false, this.italic = false,
      this.underline = false, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(color: kCardBg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: kBorder)),
        child: Text(label, style: GoogleFonts.dmSans(
            color: Colors.white, fontSize: 11,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            decoration: underline ? TextDecoration.underline : TextDecoration.none)),
      ),
    ),
  );
}

class _ToolbarDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 1, height: 24,
    child: VerticalDivider(color: kBorder, width: 1),
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Color _roleColor(String role) {
  switch (role) {
    case 'creator': return kPrimary;
    case 'enterprise': return const Color(0xFF0097B2);
    case 'admin': return const Color(0xFF818CF8);
    case 'fan': return const Color(0xFFFBBF24);
    default: return kMuted;
  }
}

String _shortDate(String iso) {
  if (iso.isEmpty) return '';
  try {
    final d = DateTime.parse(iso);
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${m[d.month]} ${d.day}, ${d.year}';
  } catch (_) { return ''; }
}
