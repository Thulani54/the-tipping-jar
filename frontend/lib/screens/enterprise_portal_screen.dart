import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/enterprise_model.dart';
import '../models/pledge_model.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';

class EnterprisePortalScreen extends StatefulWidget {
  const EnterprisePortalScreen({super.key});

  @override
  State<EnterprisePortalScreen> createState() => _EnterprisePortalScreenState();
}

class _EnterprisePortalScreenState extends State<EnterprisePortalScreen> {
  int _tab = 0;

  EnterpriseModel? _enterprise;
  EnterpriseStats? _stats;
  List<EnterpriseMember> _members = [];
  List<FundDistribution> _distributions = [];

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
        api.getMyEnterprise(),
        api.getEnterpriseStats(),
        api.getEnterpriseMembers(),
        api.getEnterpriseDistributions(),
      ]);
      if (mounted) {
        setState(() {
          _enterprise = results[0] as EnterpriseModel;
          _stats = results[1] as EnterpriseStats;
          _members = results[2] as List<EnterpriseMember>;
          _distributions = results[3] as List<FundDistribution>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final wide = w > 860;

    return Scaffold(
      backgroundColor: kDark,
      body: wide ? _wideLayout() : _narrowLayout(),
    );
  }

  // ─── Wide layout: sidebar + content ──────────────────────────────────────────
  Widget _wideLayout() => Row(children: [
    _Sidebar(
      enterprise: _enterprise,
      selectedTab: _tab,
      onTab: (i) => setState(() => _tab = i),
    ),
    Expanded(child: _content()),
  ]);

  Widget _narrowLayout() => Column(children: [
    _AppBarNarrow(enterprise: _enterprise),
    _TabBar(selected: _tab, onTab: (i) => setState(() => _tab = i)),
    Expanded(child: _content()),
  ]);

  Widget _content() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kPrimary));
    }
    if (_error != null && _enterprise == null) {
      return _NoEnterprise(onCreated: _load);
    }
    return switch (_tab) {
      0 => _OverviewTab(enterprise: _enterprise!, stats: _stats),
      1 => _CreatorsTab(members: _members, onRefresh: _load, enterprise: _enterprise!),
      2 => _DistributionsTab(
          distributions: _distributions,
          members: _members,
          onCreated: _load,
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

// ─── Sidebar (wide) ───────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final EnterpriseModel? enterprise;
  final int selectedTab;
  final ValueChanged<int> onTab;

  const _Sidebar({required this.enterprise, required this.selectedTab, required this.onTab});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (Icons.dashboard_rounded, 'Overview'),
      (Icons.people_rounded, 'Creators'),
      (Icons.account_balance_wallet_rounded, 'Distributions'),
    ];

    return Container(
      width: 240,
      color: kDarker,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () => context.go('/'),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const AppLogoIcon(size: 28),
            const SizedBox(width: 8),
            Text('TippingJar',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          ]),
        ),
        const SizedBox(height: 8),
        Text('Enterprise Portal',
            style: GoogleFonts.inter(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        const SizedBox(height: 32),
        if (enterprise != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder)),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    enterprise!.name.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(enterprise!.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(enterprise!.plan.toUpperCase(),
                      style: GoogleFonts.inter(color: kPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 24),
        ],
        ...tabs.asMap().entries.map((e) => _NavItem(
          icon: e.value.$1,
          label: e.value.$2,
          selected: selectedTab == e.key,
          onTap: () => onTab(e.key),
        )),
        const Spacer(),
        _NavItem(
          icon: Icons.arrow_back_rounded,
          label: 'Back to app',
          selected: false,
          onTap: () => context.go('/dashboard'),
        ),
      ]),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? kPrimary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? kPrimary.withOpacity(0.3) : Colors.transparent),
        ),
        child: Row(children: [
          Icon(icon, color: selected ? kPrimary : kMuted, size: 18),
          const SizedBox(width: 10),
          Text(label,
              style: GoogleFonts.inter(
                  color: selected ? Colors.white : kMuted,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14)),
        ]),
      ),
    );
  }
}

class _AppBarNarrow extends StatelessWidget {
  final EnterpriseModel? enterprise;
  const _AppBarNarrow({required this.enterprise});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kDarker,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(children: [
        const AppLogoIcon(size: 24),
        const SizedBox(width: 8),
        Text('Enterprise Portal',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kMuted, size: 20),
          onPressed: () => context.go('/dashboard'),
        ),
      ]),
    );
  }
}

class _TabBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTab;
  const _TabBar({required this.selected, required this.onTab});

  @override
  Widget build(BuildContext context) {
    final tabs = ['Overview', 'Creators', 'Distributions'];
    return Container(
      color: kDarker,
      child: Row(children: tabs.asMap().entries.map((e) {
        final active = e.key == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onTab(e.key),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(
                    color: active ? kPrimary : kBorder, width: active ? 2 : 1)),
              ),
              child: Text(e.value,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: active ? kPrimary : kMuted,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 13)),
            ),
          ),
        );
      }).toList()),
    );
  }
}

// ─── No enterprise state ──────────────────────────────────────────────────────
class _NoEnterprise extends StatefulWidget {
  final VoidCallback onCreated;
  const _NoEnterprise({required this.onCreated});

  @override
  State<_NoEnterprise> createState() => _NoEnterpriseState();
}

class _NoEnterpriseState extends State<_NoEnterprise> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      final api = context.read<AuthProvider>().api;
      await api.createEnterprise({'name': _nameCtrl.text.trim()});
      widget.onCreated();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: kPrimary.withOpacity(0.3)),
              ),
              child: const Icon(Icons.business_rounded, color: kPrimary, size: 28),
            ).animate().scale(duration: 400.ms),
            const SizedBox(height: 20),
            Text('Set up your enterprise',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800,
                    fontSize: 24, letterSpacing: -0.5),
                textAlign: TextAlign.center)
                .animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 8),
            Text('Give your enterprise account a name to get started.',
                style: GoogleFonts.inter(color: kMuted, fontSize: 14, height: 1.5),
                textAlign: TextAlign.center)
                .animate().fadeIn(delay: 180.ms),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: Column(children: [
                TextFormField(
                  controller: _nameCtrl,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  validator: (v) => (v?.trim().isNotEmpty ?? false) ? null : 'Name is required',
                  decoration: InputDecoration(
                    hintText: 'e.g. Acme Media Group',
                    hintStyle: GoogleFonts.inter(color: kMuted, fontSize: 14),
                    filled: true, fillColor: kCardBg,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: kBorder)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: kPrimary, width: 2)),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.red.withOpacity(0.5))),
                    focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: kPrimary.withOpacity(0.4),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                    ),
                    child: _saving
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Create enterprise',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final EnterpriseModel enterprise;
  final EnterpriseStats? stats;
  const _OverviewTab({required this.enterprise, required this.stats});

  @override
  Widget build(BuildContext context) {
    final s = stats;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Overview',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800,
                fontSize: 24, letterSpacing: -0.5))
            .animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 4),
        Text(enterprise.name, style: GoogleFonts.inter(color: kMuted, fontSize: 14)),
        const SizedBox(height: 28),

        // Stat cards
        Wrap(spacing: 16, runSpacing: 16, children: [
          _StatCard(
            label: 'Managed Creators',
            value: '${s?.creatorCount ?? enterprise.creatorCount}',
            icon: Icons.people_rounded,
          ),
          _StatCard(
            label: 'Total Tips Received',
            value: s != null ? '${s.tipCount}' : '—',
            icon: Icons.payments_rounded,
          ),
          _StatCard(
            label: 'Total Earned',
            value: s != null ? 'R${s.totalEarned.toStringAsFixed(2)}' : '—',
            icon: Icons.trending_up_rounded,
            highlight: true,
          ),
          _StatCard(
            label: 'Total Distributed',
            value: s != null ? 'R${s.totalDistributed.toStringAsFixed(2)}' : '—',
            icon: Icons.account_balance_wallet_rounded,
          ),
          _StatCard(
            label: 'Distributions',
            value: s != null ? '${s.distributionCount}' : '—',
            icon: Icons.receipt_long_rounded,
          ),
        ]),

        if (s != null && s.perCreator.isNotEmpty) ...[
          const SizedBox(height: 36),
          Text('Earnings per creator',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700,
                  fontSize: 16, letterSpacing: -0.3)),
          const SizedBox(height: 16),
          ...s.perCreator.map((row) => _CreatorEarningsRow(row: row)),
        ],
        const SizedBox(height: 36),
        _EnterpriseRecurringCard(enterprise: enterprise),
      ]),
    );
  }
}

// ─── Enterprise Recurring Revenue card ───────────────────────────────────────
class _EnterpriseRecurringCard extends StatefulWidget {
  final EnterpriseModel enterprise;
  const _EnterpriseRecurringCard({required this.enterprise});
  @override
  State<_EnterpriseRecurringCard> createState() => _EnterpriseRecurringCardState();
}

class _EnterpriseRecurringCardState extends State<_EnterpriseRecurringCard> {
  List<PledgeModel> _pledges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = context.read<AuthProvider>().api;
      final pledges = await api.getCreatorPledges();
      if (mounted) setState(() { _pledges = pledges; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _pledges.where((p) => p.isActive).toList();
    final total = active.fold(0.0, (s, p) => s + p.amount);
    final topCreator = active.isEmpty ? null : (() {
      final byCreator = <String, double>{};
      for (final p in active) {
        byCreator[p.creatorDisplayName] = (byCreator[p.creatorDisplayName] ?? 0) + p.amount;
      }
      return byCreator.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    })();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Recurring Revenue', style: GoogleFonts.inter(
          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.3)),
      const SizedBox(height: 16),
      if (_loading)
        const Center(child: CircularProgressIndicator(color: kPrimary))
      else
        Wrap(spacing: 16, runSpacing: 16, children: [
          _StatCard(label: 'Active Pledges', value: '${active.length}', icon: Icons.repeat_rounded),
          _StatCard(label: 'Monthly Recurring', value: 'R${total.toStringAsFixed(0)}',
              icon: Icons.trending_up_rounded, highlight: true),
          if (topCreator != null)
            _StatCard(label: 'Top by Pledges', value: topCreator, icon: Icons.star_rounded),
        ]),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool highlight;
  const _StatCard({required this.label, required this.value,
      required this.icon, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: highlight ? kPrimary.withOpacity(0.4) : kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: (highlight ? kPrimary : kMuted).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: highlight ? kPrimary : kMuted, size: 18),
        ),
        const SizedBox(height: 12),
        Text(value,
            style: GoogleFonts.inter(color: highlight ? kPrimary : Colors.white,
                fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(color: kMuted, fontSize: 12)),
      ]),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }
}

class _CreatorEarningsRow extends StatelessWidget {
  final CreatorStatRow row;
  const _CreatorEarningsRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
          child: Center(child: Text(
            row.displayName.isNotEmpty ? row.displayName[0].toUpperCase() : '?',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
          )),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(row.displayName,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
        ),
        Text('${row.tips} tips',
            style: GoogleFonts.inter(color: kMuted, fontSize: 12)),
        const SizedBox(width: 16),
        Text('R${row.total.toStringAsFixed(2)}',
            style: GoogleFonts.inter(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
      ]),
    );
  }
}

// ─── Creators Tab ─────────────────────────────────────────────────────────────
class _CreatorsTab extends StatefulWidget {
  final List<EnterpriseMember> members;
  final VoidCallback onRefresh;
  final EnterpriseModel enterprise;
  const _CreatorsTab({required this.members, required this.onRefresh, required this.enterprise});

  @override
  State<_CreatorsTab> createState() => _CreatorsTabState();
}

class _CreatorsTabState extends State<_CreatorsTab> {
  bool _adding = false;
  final _slugCtrl = TextEditingController();
  String? _addError;

  @override
  void dispose() {
    _slugCtrl.dispose();
    super.dispose();
  }

  Future<void> _addCreator() async {
    final slug = _slugCtrl.text.trim();
    if (slug.isEmpty) return;
    setState(() { _adding = true; _addError = null; });
    try {
      final api = context.read<AuthProvider>().api;
      await api.addEnterpriseMember(slug);
      _slugCtrl.clear();
      widget.onRefresh();
    } catch (e) {
      setState(() {
        _addError = e.toString().replaceFirst('Exception: ', '');
        _adding = false;
      });
    }
  }

  Future<void> _remove(EnterpriseMember m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove creator?',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Remove ${m.displayName} from this enterprise?',
            style: GoogleFonts.inter(color: kMuted, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.inter(color: kMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800, foregroundColor: Colors.white),
            child: Text('Remove', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<AuthProvider>().api.removeEnterpriseMember(m.id);
      widget.onRefresh();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Managed Creators',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800,
                fontSize: 24, letterSpacing: -0.5))
            .animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 4),
        Text('${widget.members.length} creator${widget.members.length == 1 ? '' : 's'}',
            style: GoogleFonts.inter(color: kMuted, fontSize: 14)),
        const SizedBox(height: 28),

        // Add creator
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kCardBg, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Add a creator',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _slugCtrl,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Creator slug (e.g. john-doe)',
                    hintStyle: GoogleFonts.inter(color: kMuted, fontSize: 13),
                    filled: true, fillColor: kDarker,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kBorder)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kPrimary, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _adding ? null : _addCreator,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary, foregroundColor: Colors.white,
                  disabledBackgroundColor: kPrimary.withOpacity(0.4),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _adding
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Add', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ]),
            if (_addError != null) ...[
              const SizedBox(height: 8),
              Text(_addError!, style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13)),
            ],
          ]),
        ),

        const SizedBox(height: 24),

        if (widget.members.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(children: [
                const Icon(Icons.people_outline_rounded, color: kMuted, size: 40),
                const SizedBox(height: 12),
                Text('No creators yet. Add one above.',
                    style: GoogleFonts.inter(color: kMuted, fontSize: 14)),
              ]),
            ),
          )
        else
          ...widget.members.map((m) => _MemberCard(member: m, onRemove: () => _remove(m))),
      ]),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final EnterpriseMember member;
  final VoidCallback onRemove;
  const _MemberCard({required this.member, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
          child: Center(child: Text(
            member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
          )),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(member.displayName,
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 2),
            Text('@${member.creatorSlug}',
                style: GoogleFonts.inter(color: kMuted, fontSize: 12)),
            if (member.tagline.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(member.tagline,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: kMuted, fontSize: 12)),
            ],
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('R${member.totalTips.toStringAsFixed(2)}',
              style: GoogleFonts.inter(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 2),
          Text('total tips', style: GoogleFonts.inter(color: kMuted, fontSize: 11)),
        ]),
        const SizedBox(width: 12),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: kMuted, size: 18),
          color: kCardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (val) {
            if (val == 'view') context.go('/creator/${member.creatorSlug}');
            if (val == 'remove') onRemove();
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'view',
                child: Text('View profile', style: GoogleFonts.inter(color: Colors.white, fontSize: 13))),
            PopupMenuItem(value: 'remove',
                child: Text('Remove', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13))),
          ],
        ),
      ]),
    ).animate().fadeIn(duration: 250.ms);
  }
}

// ─── Distributions Tab ────────────────────────────────────────────────────────
class _DistributionsTab extends StatefulWidget {
  final List<FundDistribution> distributions;
  final List<EnterpriseMember> members;
  final VoidCallback onCreated;
  const _DistributionsTab({required this.distributions, required this.members, required this.onCreated});

  @override
  State<_DistributionsTab> createState() => _DistributionsTabState();
}

class _DistributionsTabState extends State<_DistributionsTab> {
  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (_) => _CreateDistributionDialog(
        members: widget.members,
        onCreated: () {
          Navigator.pop(context);
          widget.onCreated();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Fund Distributions',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800,
                      fontSize: 24, letterSpacing: -0.5))
                  .animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 4),
              Text('Record and track fund disbursements to creators.',
                  style: GoogleFonts.inter(color: kMuted, fontSize: 14)),
            ]),
          ),
          ElevatedButton.icon(
            onPressed: _showCreateDialog,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('New Distribution',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary, foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
            ),
          ),
        ]),
        const SizedBox(height: 28),

        if (widget.distributions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 64),
              child: Column(children: [
                const Icon(Icons.account_balance_wallet_outlined, color: kMuted, size: 40),
                const SizedBox(height: 12),
                Text('No distributions yet.',
                    style: GoogleFonts.inter(color: kMuted, fontSize: 14)),
                const SizedBox(height: 8),
                Text('Create one to record fund disbursements to your creators.',
                    style: GoogleFonts.inter(color: kMuted, fontSize: 13),
                    textAlign: TextAlign.center),
              ]),
            ),
          )
        else
          ...widget.distributions.map((d) => _DistributionCard(dist: d)),
      ]),
    );
  }
}

class _DistributionCard extends StatefulWidget {
  final FundDistribution dist;
  const _DistributionCard({required this.dist});

  @override
  State<_DistributionCard> createState() => _DistributionCardState();
}

class _DistributionCardState extends State<_DistributionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final dist = widget.dist;
    final allPaid = dist.items.isNotEmpty &&
        dist.items.every((i) => i.status == 'paid');
    final hasAnyPaid = dist.items.any((i) => i.status == 'paid');

    Color statusColor = kMuted;
    String statusLabel = 'Pending';
    if (allPaid) { statusColor = kPrimary; statusLabel = 'Paid'; }
    else if (hasAnyPaid) { statusColor = Colors.orange; statusLabel = 'Partial'; }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: kPrimary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(dist.reference,
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(dist.distributedAt.length >= 10
                      ? dist.distributedAt.substring(0, 10)
                      : dist.distributedAt,
                      style: GoogleFonts.inter(color: kMuted, fontSize: 12)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(statusLabel,
                    style: GoogleFonts.inter(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              Text('R${dist.totalAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(width: 8),
              Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: kMuted, size: 20),
            ]),
          ),
        ),
        if (_expanded && dist.items.isNotEmpty) ...[
          const Divider(color: kBorder, height: 1),
          ...dist.items.map((item) => _DistributionItemRow(item: item)),
          if (dist.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(children: [
                const Icon(Icons.notes_rounded, color: kMuted, size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text(dist.notes,
                    style: GoogleFonts.inter(color: kMuted, fontSize: 12, fontStyle: FontStyle.italic))),
              ]),
            ),
        ],
      ]),
    ).animate().fadeIn(duration: 250.ms);
  }
}

class _DistributionItemRow extends StatelessWidget {
  final FundDistributionItem item;
  const _DistributionItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (item.status) {
      'paid' => kPrimary,
      'failed' => Colors.redAccent,
      _ => kMuted,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(item.displayName,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        if (item.reference.isNotEmpty)
          Text(item.reference, style: GoogleFonts.inter(color: kMuted, fontSize: 11)),
        const SizedBox(width: 12),
        Text('R${item.amount.toStringAsFixed(2)}',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(width: 8),
        Text(item.status.toUpperCase(),
            style: GoogleFonts.inter(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ─── Create Distribution Dialog ───────────────────────────────────────────────
class _CreateDistributionDialog extends StatefulWidget {
  final List<EnterpriseMember> members;
  final VoidCallback onCreated;
  const _CreateDistributionDialog({required this.members, required this.onCreated});

  @override
  State<_CreateDistributionDialog> createState() => _CreateDistributionDialogState();
}

class _CreateDistributionDialogState extends State<_CreateDistributionDialog> {
  final _notesCtrl = TextEditingController();
  final Map<String, TextEditingController> _amountCtrls = {};
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final m in widget.members) {
      _amountCtrls[m.creatorSlug] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final c in _amountCtrls.values) c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final items = <Map<String, dynamic>>[];
    for (final m in widget.members) {
      final raw = _amountCtrls[m.creatorSlug]?.text.trim() ?? '';
      if (raw.isEmpty) continue;
      final amount = double.tryParse(raw);
      if (amount == null || amount <= 0) {
        setState(() => _error = 'Invalid amount for ${m.displayName}');
        return;
      }
      items.add({'creator_slug': m.creatorSlug, 'amount': amount});
    }
    if (items.isEmpty) {
      setState(() => _error = 'Enter at least one amount.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await context.read<AuthProvider>().api.createDistribution(
        notes: _notesCtrl.text.trim(),
        items: items,
      );
      widget.onCreated();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kCardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('New Fund Distribution',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 6),
            Text('Allocate funds to your managed creators.',
                style: GoogleFonts.inter(color: kMuted, fontSize: 13)),
            const SizedBox(height: 24),

            Expanded(
              child: ListView(children: [
                ...widget.members.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                      child: Center(child: Text(
                        m.displayName.isNotEmpty ? m.displayName[0].toUpperCase() : '?',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      )),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(m.displayName,
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
                    ),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        controller: _amountCtrls[m.creatorSlug],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'R 0.00',
                          hintStyle: GoogleFonts.inter(color: kMuted, fontSize: 13),
                          prefixText: 'R ',
                          prefixStyle: GoogleFonts.inter(color: kMuted, fontSize: 13),
                          filled: true, fillColor: kDarker,
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: kBorder)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: kPrimary, width: 2)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ),
                  ]),
                )),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesCtrl,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Notes (optional)',
                    hintStyle: GoogleFonts.inter(color: kMuted, fontSize: 13),
                    filled: true, fillColor: kDarker,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kBorder)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kPrimary, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ]),
            ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: kBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                  ),
                  child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary, foregroundColor: Colors.white,
                    disabledBackgroundColor: kPrimary.withOpacity(0.4),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Create', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
