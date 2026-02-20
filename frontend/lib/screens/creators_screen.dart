import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/creator.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/app_nav.dart';

// ─── Mock data (shown when API is unreachable) ────────────────────────────────
final _mockCreators = [
  Creator.fromJson({'id': 1, 'username': 'alexjohnson', 'display_name': 'Alex Johnson',
    'slug': 'alexjohnson', 'tagline': 'Illustrator & comic artist', 'cover_image': null,
    'avatar': null, 'tip_goal': '500.00', 'total_tips': '3240.00'}),
  Creator.fromJson({'id': 2, 'username': 'rajpatel', 'display_name': 'Raj Patel',
    'slug': 'rajpatel', 'tagline': 'Indie game developer', 'cover_image': null,
    'avatar': null, 'tip_goal': '300.00', 'total_tips': '1870.00'}),
  Creator.fromJson({'id': 3, 'username': 'lenatv', 'display_name': 'Lena Torres',
    'slug': 'lenatv', 'tagline': 'Music producer & DJ', 'cover_image': null,
    'avatar': null, 'tip_goal': '1000.00', 'total_tips': '5100.00'}),
  Creator.fromJson({'id': 4, 'username': 'miadesigns', 'display_name': 'Mia Chen',
    'slug': 'miadesigns', 'tagline': 'UI/UX designer & educator', 'cover_image': null,
    'avatar': null, 'tip_goal': '400.00', 'total_tips': '2600.00'}),
  Creator.fromJson({'id': 5, 'username': 'devwithdan', 'display_name': 'Dan Okafor',
    'slug': 'devwithdan', 'tagline': 'Open-source developer & YouTuber', 'cover_image': null,
    'avatar': null, 'tip_goal': '750.00', 'total_tips': '4400.00'}),
  Creator.fromJson({'id': 6, 'username': 'sophiawrites', 'display_name': 'Sophia Bauer',
    'slug': 'sophiawrites', 'tagline': 'Fiction writer & poet', 'cover_image': null,
    'avatar': null, 'tip_goal': '200.00', 'total_tips': '980.00'}),
  Creator.fromJson({'id': 7, 'username': 'chefmarco', 'display_name': 'Marco Ricci',
    'slug': 'chefmarco', 'tagline': 'Home chef & food photographer', 'cover_image': null,
    'avatar': null, 'tip_goal': '300.00', 'total_tips': '1540.00'}),
  Creator.fromJson({'id': 8, 'username': 'zoeanimates', 'display_name': 'Zoe Kim',
    'slug': 'zoeanimates', 'tagline': '2D animator & motion designer', 'cover_image': null,
    'avatar': null, 'tip_goal': '600.00', 'total_tips': '3780.00'}),
];

const _categories = ['All', 'Art', 'Music', 'Code', 'Writing', 'Gaming', 'Food', 'Design'];

final _creatorColors = [kPrimary, kTeal, kBlue, const Color(0xFF7C3AED),
  const Color(0xFFDB2777), const Color(0xFFD97706), const Color(0xFF059669), const Color(0xFF0284C7)];

class CreatorsScreen extends StatefulWidget {
  const CreatorsScreen({super.key});
  @override
  State<CreatorsScreen> createState() => _CreatorsScreenState();
}

class _CreatorsScreenState extends State<CreatorsScreen> {
  List<Creator> _creators = [];
  List<Creator> _filtered = [];
  bool _loading = true;
  String _search = '';
  String _category = 'All';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService().getCreators();
      if (mounted) {
        setState(() {
          _creators = data.isEmpty ? _mockCreators : data;
          _filtered = _creators;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _creators = _mockCreators;
          _filtered = _mockCreators;
          _loading = false;
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filtered = _creators.where((c) {
        final matchSearch = _search.isEmpty ||
            c.displayName.toLowerCase().contains(_search.toLowerCase()) ||
            c.tagline.toLowerCase().contains(_search.toLowerCase());
        return matchSearch;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final featured = _creators.take(3).toList();

    return Scaffold(
      backgroundColor: kDark,
      appBar: AppNav(activeRoute: '/creators'),
      body: SingleChildScrollView(
        child: Column(children: [
          _hero(context),
          _statsBar(),
          _featuredSection(featured, context),
          _browseSection(context),
          _becomeCta(context),
          _footer(),
        ]),
      ),
    );
  }

  // ─── Hero ──────────────────────────────────────────────────────────────────
  Widget _hero(BuildContext ctx) {
    return Container(
      width: double.infinity,
      color: kDarker,
      padding: const EdgeInsets.fromLTRB(24, 72, 24, 56),
      child: Column(children: [
        _tag('Discover creators'),
        const SizedBox(height: 20),
        Text('Support the people\nwho make your day.',
            style: headingXL(ctx), textAlign: TextAlign.center)
            .animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: const Text(
            'Browse creators across art, music, code, writing, and more. Drop a tip — it takes 30 seconds and means the world to them.',
            style: kBodyStyle, textAlign: TextAlign.center,
          ),
        ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
        const SizedBox(height: 36),

        // Search bar
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            onChanged: (v) {
              _search = v;
              _applyFilters();
            },
            decoration: InputDecoration(
              hintText: 'Search creators…',
              hintStyle: const TextStyle(color: kMuted),
              prefixIcon: const Icon(Icons.search, color: kMuted),
              filled: true,
              fillColor: kCardBg,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(36),
                borderSide: const BorderSide(color: kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(36),
                borderSide: const BorderSide(color: kPrimary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ).animate().fadeIn(delay: 250.ms, duration: 500.ms),
      ]),
    );
  }

  // ─── Stats bar ─────────────────────────────────────────────────────────────
  Widget _statsBar() {
    final stats = [
      ('${_creators.length}', 'Active creators'),
      ('\$180K+', 'Tips sent'),
      ('48', 'Countries'),
    ];
    return Container(
      color: kDark,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 48, runSpacing: 16,
        children: stats.asMap().entries.map((e) => Column(children: [
          Text(e.value.$1, style: GoogleFonts.inter(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -1))
              .animate().fadeIn(delay: (e.key * 80).ms, duration: 400.ms),
          Text(e.value.$2, style: GoogleFonts.inter(color: kMuted, fontSize: 13)),
        ])).toList(),
      ),
    );
  }

  // ─── Featured ──────────────────────────────────────────────────────────────
  Widget _featuredSection(List<Creator> featured, BuildContext ctx) {
    if (featured.isEmpty) return const SizedBox.shrink();
    return Container(
      color: kDarker,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(children: [
        _tag('Featured creators'),
        const SizedBox(height: 16),
        Text('Making waves this month',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800,
                fontSize: 30, letterSpacing: -1),
            textAlign: TextAlign.center),
        const SizedBox(height: 40),
        Wrap(
          spacing: 20, runSpacing: 20, alignment: WrapAlignment.center,
          children: featured.asMap().entries.map((e) => _FeaturedCard(
            creator: e.value,
            color: _creatorColors[e.key % _creatorColors.length],
            delay: e.key * 120,
          )).toList(),
        ),
      ]),
    );
  }

  // ─── Browse ────────────────────────────────────────────────────────────────
  Widget _browseSection(BuildContext ctx) {
    return Container(
      color: kDark,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('All creators',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22)),
          Text('${_filtered.length} creators',
              style: GoogleFonts.inter(color: kMuted, fontSize: 13)),
        ]),
        const SizedBox(height: 20),

        // Category chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((cat) {
              final active = _category == cat;
              return GestureDetector(
                onTap: () => setState(() => _category = cat),
                child: AnimatedContainer(
                  duration: 200.ms,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: active ? kPrimary : kCardBg,
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(color: active ? Colors.transparent : kBorder),
                  ),
                  child: Text(cat, style: GoogleFonts.inter(
                      color: active ? Colors.white : kMuted,
                      fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 32),

        _loading
            ? const Center(child: CircularProgressIndicator(color: kPrimary))
            : _filtered.isEmpty
                ? _emptyState()
                : Wrap(
                    spacing: 18, runSpacing: 18, alignment: WrapAlignment.start,
                    children: _filtered.asMap().entries.map((e) => _CreatorBrowseCard(
                      creator: e.value,
                      color: _creatorColors[e.key % _creatorColors.length],
                      delay: (e.key * 60).clamp(0, 500),
                    )).toList(),
                  ),
      ]),
    );
  }

  Widget _emptyState() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Column(children: [
      const Icon(Icons.search_off_rounded, color: kMuted, size: 48),
      const SizedBox(height: 12),
      Text('No creators found for "$_search"',
          style: GoogleFonts.inter(color: kMuted, fontSize: 15)),
      const SizedBox(height: 8),
      TextButton(
        onPressed: () { _searchCtrl.clear(); setState(() { _search = ''; _applyFilters(); }); },
        child: const Text('Clear search', style: TextStyle(color: kPrimary)),
      ),
    ]),
  );

  // ─── Become a creator CTA ──────────────────────────────────────────────────
  Widget _becomeCta(BuildContext ctx) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 40),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF001A12), Color(0xFF001520)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kBorder),
        ),
        child: Column(children: [
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
            child: const Icon(Icons.volunteer_activism, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 20),
          Text('Are you a creator?',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800,
                  fontSize: 32, letterSpacing: -1),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          const Text('Set up your tip page in 60 seconds. It\'s completely free.',
              style: kBodyStyle, textAlign: TextAlign.center),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => ctx.go('/register'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary, foregroundColor: Colors.white,
              shadowColor: Colors.transparent, elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
            ),
            child: Text('Create your page →',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ]),
      ),
    );
  }

  Widget _footer() => Container(
    color: kDark,
    padding: const EdgeInsets.all(32),
    child: const Text('© 2026 TippingJar. All rights reserved.',
        style: TextStyle(color: kMuted, fontSize: 12), textAlign: TextAlign.center),
  );

  Widget _tag(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: kPrimary.withOpacity(0.1),
      border: Border.all(color: kPrimary.withOpacity(0.3)),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(label, style: GoogleFonts.inter(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}

// ─── Featured card ────────────────────────────────────────────────────────────
class _FeaturedCard extends StatefulWidget {
  final Creator creator;
  final Color color;
  final int delay;
  const _FeaturedCard({required this.creator, required this.color, required this.delay});
  @override
  State<_FeaturedCard> createState() => _FeaturedCardState();
}
class _FeaturedCardState extends State<_FeaturedCard> {
  bool _hovered = false;
  String get _initials => widget.creator.displayName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

  @override
  Widget build(BuildContext context) {
    final tips = widget.creator.totalTips;
    final goal = widget.creator.tipGoal;
    final progress = goal != null && goal > 0 ? (tips / goal).clamp(0.0, 1.0) : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go('/creator/${widget.creator.slug}'),
        child: AnimatedContainer(
          duration: 200.ms,
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _hovered ? widget.color.withOpacity(0.5) : kBorder),
            boxShadow: _hovered ? [BoxShadow(color: widget.color.withOpacity(0.15), blurRadius: 40, offset: const Offset(0, 12))] : [],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Cover
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [widget.color.withOpacity(0.5), widget.color.withOpacity(0.1)]),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [widget.color, widget.color.withOpacity(0.6)]),
                  shape: BoxShape.circle,
                  border: Border.all(color: kCardBg, width: 3),
                ),
                child: Center(child: Text(_initials, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.creator.displayName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15), overflow: TextOverflow.ellipsis),
                Text(widget.creator.tagline, style: GoogleFonts.inter(color: kMuted, fontSize: 12), overflow: TextOverflow.ellipsis),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: widget.color.withOpacity(0.12), borderRadius: BorderRadius.circular(36)),
                child: Text('Featured', style: GoogleFonts.inter(color: widget.color, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ]),
            if (progress != null) ...[
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Monthly goal', style: GoogleFonts.inter(color: kMuted, fontSize: 11)),
                Text('${(progress * 100).toStringAsFixed(0)}%', style: GoogleFonts.inter(color: widget.color, fontWeight: FontWeight.w700, fontSize: 11)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: kBorder,
                  valueColor: AlwaysStoppedAnimation(widget.color),
                  minHeight: 6,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [widget.color, widget.color.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(36),
                ),
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/tip/${widget.creator.slug}'),
                  icon: const Icon(Icons.volunteer_activism, size: 15),
                  label: const Text('Send a tip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                    foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    ).animate().fadeIn(delay: widget.delay.ms, duration: 500.ms).slideY(begin: 0.2, curve: Curves.easeOut);
  }
}

// ─── Browse card ──────────────────────────────────────────────────────────────
class _CreatorBrowseCard extends StatefulWidget {
  final Creator creator;
  final Color color;
  final int delay;
  const _CreatorBrowseCard({required this.creator, required this.color, required this.delay});
  @override
  State<_CreatorBrowseCard> createState() => _CreatorBrowseCardState();
}
class _CreatorBrowseCardState extends State<_CreatorBrowseCard> {
  bool _hovered = false;
  String get _initials => widget.creator.displayName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go('/creator/${widget.creator.slug}'),
        child: AnimatedContainer(
          duration: 180.ms,
          width: 240,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _hovered ? widget.color.withOpacity(0.4) : kBorder),
            boxShadow: _hovered ? [BoxShadow(color: widget.color.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, 6))] : [],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [widget.color, widget.color.withOpacity(0.5)]),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(_initials, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.creator.displayName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
                Text(widget.creator.tagline, style: GoogleFonts.inter(color: kMuted, fontSize: 11), overflow: TextOverflow.ellipsis),
              ])),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Icon(Icons.volunteer_activism, color: widget.color, size: 14),
              const SizedBox(width: 5),
              Text('\$${widget.creator.totalTips.toStringAsFixed(0)} earned',
                  style: GoogleFonts.inter(color: kMuted, fontSize: 12)),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go('/tip/${widget.creator.slug}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: widget.color,
                  side: BorderSide(color: widget.color.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                ),
                child: Text('Tip', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    ).animate().fadeIn(delay: widget.delay.ms, duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOut);
  }
}
