import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/creator.dart';
import '../services/api_service.dart';
import '../widgets/app_nav.dart';
import '../widgets/site_footer.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const _bgWhite   = Colors.white;
const _bgSage    = Color(0xFFF5F9F6);
const _ink       = Color(0xFF080F0B);
const _inkBody   = Color(0xFF38524A);
const _inkMuted  = Color(0xFF7A9487);
const _border    = Color(0xFFDBEAE1);
const _green     = Color(0xFF004423);
const _greenMid  = Color(0xFF006B3A);

// ─── Creator accent colours ───────────────────────────────────────────────────
const _accentColors = [
  Color(0xFF004423), Color(0xFF0097B2), Color(0xFF2563EB),
  Color(0xFF7C3AED), Color(0xFFDB2777), Color(0xFFD97706),
  Color(0xFF059669), Color(0xFF0284C7),
];

Color _accentFor(int index) => _accentColors[index % _accentColors.length];

// ─── Mock data ────────────────────────────────────────────────────────────────
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
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService().getCreators();
      if (mounted) setState(() {
        _creators = data.isEmpty ? _mockCreators : data;
        _filtered = _creators;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _creators = _mockCreators;
        _filtered = _mockCreators;
        _loading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filtered = _creators.where((c) {
        return _search.isEmpty ||
            c.displayName.toLowerCase().contains(_search.toLowerCase()) ||
            c.tagline.toLowerCase().contains(_search.toLowerCase());
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
    return Scaffold(
      backgroundColor: _bgWhite,
      appBar: AppNav(activeRoute: '/creators'),
      body: ScrollConfiguration(
        behavior: _SmoothScroll(),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(children: [
            _hero(context),
            _statsBar(),
            _featuredSection(context),
            _browseSection(context),
            _cta(context),
            const SiteFooter(),
          ]),
        ),
      ),
    );
  }

  // ─── Hero ────────────────────────────────────────────────────────────────────
  Widget _hero(BuildContext ctx) {
    return Container(
      width: double.infinity,
      color: _bgSage,
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _LightDotPainter())),
        SizedBox(width: double.infinity, child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 72, 24, 56),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: _green.withOpacity(0.20)),
              ),
              child: Text('Discover creators', style: GoogleFonts.dmSans(
                  color: _greenMid, fontWeight: FontWeight.w600, fontSize: 12)),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 20),
            Text('Support the people\nwho make your day.',
                style: GoogleFonts.dmSans(
                    color: _ink, fontWeight: FontWeight.w800,
                    fontSize: 50, letterSpacing: -2.0, height: 1.08),
                textAlign: TextAlign.center)
                .animate().fadeIn(delay: 80.ms, duration: 500.ms).slideY(begin: 0.15),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Text(
                'Browse creators across art, music, code, writing, and more. Drop a tip — it takes 30 seconds and means the world to them.',
                style: GoogleFonts.dmSans(color: _inkBody, fontSize: 16.5, height: 1.7),
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn(delay: 160.ms, duration: 500.ms),
            const SizedBox(height: 36),
            // Search bar
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: TextField(
                controller: _searchCtrl,
                style: GoogleFonts.dmSans(color: _ink, fontSize: 15),
                onChanged: (v) { _search = v; _applyFilters(); },
                decoration: InputDecoration(
                  hintText: 'Search creators…',
                  hintStyle: GoogleFonts.dmSans(color: _inkMuted, fontSize: 15),
                  prefixIcon: const Icon(Icons.search_rounded, color: _inkMuted, size: 20),
                  filled: true,
                  fillColor: _bgWhite,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(36),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(36),
                    borderSide: const BorderSide(color: _green, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ).animate().fadeIn(delay: 240.ms, duration: 500.ms),
          ]),
        )),
      ]),
    );
  }

  // ─── Stats bar ───────────────────────────────────────────────────────────────
  Widget _statsBar() {
    final stats = [
      ('${_creators.length}+', 'Active creators'),
      ('R3.6M+', 'Tips sent'),
      ('🇿🇦', 'South Africa'),
    ];
    return Container(
      color: _bgWhite,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(children: [
        Container(height: 1, color: _border),
        const SizedBox(height: 28),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 64, runSpacing: 20,
          children: stats.asMap().entries.map((e) => Column(children: [
            Text(e.value.$1, style: GoogleFonts.dmSans(
                color: _green, fontWeight: FontWeight.w800,
                fontSize: 30, letterSpacing: -1))
                .animate().fadeIn(delay: (e.key * 80).ms, duration: 400.ms),
            const SizedBox(height: 2),
            Text(e.value.$2, style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 13)),
          ])).toList(),
        ),
        const SizedBox(height: 28),
        Container(height: 1, color: _border),
      ]),
    );
  }

  // ─── Featured ─────────────────────────────────────────────────────────────────
  Widget _featuredSection(BuildContext ctx) {
    final featured = _creators.take(3).toList();
    if (featured.isEmpty) return const SizedBox.shrink();
    return Container(
      color: _bgSage,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _green.withOpacity(0.08),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: _green.withOpacity(0.20)),
          ),
          child: Text('Featured', style: GoogleFonts.dmSans(
              color: _greenMid, fontWeight: FontWeight.w600, fontSize: 12)),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 14),
        Text('Making waves this month',
            style: GoogleFonts.dmSans(color: _ink, fontWeight: FontWeight.w800,
                fontSize: 32, letterSpacing: -1.2),
            textAlign: TextAlign.center)
            .animate().fadeIn(delay: 60.ms, duration: 400.ms),
        const SizedBox(height: 40),
        Wrap(
          spacing: 20, runSpacing: 20, alignment: WrapAlignment.center,
          children: featured.asMap().entries.map((e) => _FeaturedCard(
            creator: e.value,
            color: _accentFor(e.key),
            delay: e.key * 100,
          )).toList(),
        ),
      ]),
    );
  }

  // ─── Browse ───────────────────────────────────────────────────────────────────
  Widget _browseSection(BuildContext ctx) {
    return Container(
      color: _bgWhite,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('All creators',
              style: GoogleFonts.dmSans(color: _ink, fontWeight: FontWeight.w800,
                  fontSize: 24, letterSpacing: -0.6)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _bgSage, borderRadius: BorderRadius.circular(36),
              border: Border.all(color: _border),
            ),
            child: Text('${_filtered.length} creators',
                style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 32),
        _loading
            ? const SizedBox(height: 200,
                child: Center(child: SpinKitFadingCircle(color: _green, size: 32)))
            : _filtered.isEmpty
                ? _emptyState()
                : Wrap(
                    spacing: 18, runSpacing: 18, alignment: WrapAlignment.start,
                    children: _filtered.asMap().entries.map((e) => _CreatorBrowseCard(
                      creator: e.value,
                      color: _accentFor(e.key),
                      delay: (e.key * 50).clamp(0, 400),
                    )).toList(),
                  ),
      ]),
    );
  }

  Widget _emptyState() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 56),
    child: Column(children: [
      const Icon(Icons.search_off_rounded, color: _inkMuted, size: 48),
      const SizedBox(height: 12),
      Text('No creators found for "$_search"',
          style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 15)),
      const SizedBox(height: 8),
      TextButton(
        onPressed: () { _searchCtrl.clear(); setState(() { _search = ''; _applyFilters(); }); },
        child: Text('Clear search', style: GoogleFonts.dmSans(
            color: _green, fontWeight: FontWeight.w600)),
      ),
    ]),
  );

  // ─── CTA ──────────────────────────────────────────────────────────────────────
  Widget _cta(BuildContext ctx) {
    final mobile = MediaQuery.of(ctx).size.width < 680;
    return Container(
      color: _bgSage,
      padding: EdgeInsets.fromLTRB(mobile ? 16 : 32, 72, mobile ? 16 : 32, 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Container(
            padding: EdgeInsets.fromLTRB(
                mobile ? 28 : 56, mobile ? 48 : 60,
                mobile ? 28 : 56, mobile ? 40 : 56),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF003D1F), Color(0xFF00622E), Color(0xFF007A38)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: _green.withOpacity(0.28),
                    blurRadius: 56, offset: const Offset(0, 20)),
              ],
            ),
            child: Column(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12), shape: BoxShape.circle),
                child: const Icon(Icons.volunteer_activism_rounded,
                    color: Colors.white, size: 26),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 20),
              Text('Are you a creator?',
                  style: GoogleFonts.dmSans(
                      color: Colors.white, fontWeight: FontWeight.w800,
                      fontSize: mobile ? 32 : 46, height: 1.05, letterSpacing: -1.8),
                  textAlign: TextAlign.center)
                  .animate().fadeIn(delay: 80.ms),
              const SizedBox(height: 12),
              Text('Set up your tip page in 60 seconds. Completely free.',
                  style: GoogleFonts.dmSans(
                      color: Colors.white.withOpacity(0.60), fontSize: 16, height: 1.6),
                  textAlign: TextAlign.center)
                  .animate().fadeIn(delay: 140.ms),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => ctx.go('/register'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, foregroundColor: _green,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                ),
                child: Text('Create your page →', style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700, fontSize: 15, color: _green)),
              ).animate().fadeIn(delay: 200.ms)
                  .scale(begin: const Offset(0.94, 0.94), curve: Curves.easeOut),
              const SizedBox(height: 16),
              Text('No credit card · Free forever',
                  style: GoogleFonts.dmSans(
                      color: Colors.white.withOpacity(0.40), fontSize: 12))
                  .animate().fadeIn(delay: 260.ms),
            ]),
          ),
        ),
      ),
    );
  }
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
  String get _initials => widget.creator.displayName
      .split(' ').map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

  @override
  Widget build(BuildContext context) {
    final tips = widget.creator.totalTips;
    final goal = widget.creator.tipGoal;
    final progress = goal != null && goal > 0 ? (tips / goal).clamp(0.0, 1.0) : null;
    final c = widget.color;

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
            color: _bgWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _hovered ? c.withOpacity(0.40) : _border),
            boxShadow: _hovered
                ? [BoxShadow(color: c.withOpacity(0.12), blurRadius: 36, offset: const Offset(0, 10))]
                : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Mini cover strip with avatar
            Stack(clipBehavior: Clip.none, children: [
              Container(
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [c.withOpacity(0.18), c.withOpacity(0.08)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Positioned(
                left: 16, bottom: -20,
                child: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: _bgWhite, width: 3),
                  ),
                  child: Center(child: Text(_initials, style: GoogleFonts.dmSans(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))),
                ),
              ),
              Positioned(
                right: 12, top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(color: c.withOpacity(0.30)),
                  ),
                  child: Text('Featured', style: GoogleFonts.dmSans(
                      color: c, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
            const SizedBox(height: 28),
            Text(widget.creator.displayName, style: GoogleFonts.dmSans(
                color: _ink, fontWeight: FontWeight.w700, fontSize: 15),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(widget.creator.tagline, style: GoogleFonts.dmSans(
                color: _inkMuted, fontSize: 12), overflow: TextOverflow.ellipsis),
            if (progress != null) ...[
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Monthly goal', style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 11)),
                Text('${(progress * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.dmSans(color: c, fontWeight: FontWeight.w700, fontSize: 11)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: LinearProgressIndicator(
                  value: progress, backgroundColor: _border,
                  valueColor: AlwaysStoppedAnimation(c), minHeight: 5,
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/creator/${widget.creator.slug}'),
                icon: const Icon(Icons.volunteer_activism_rounded, size: 15),
                label: Text('Send a tip', style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green, foregroundColor: Colors.white,
                  elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                ),
              ),
            ),
          ]),
        ),
      ),
    ).animate().fadeIn(delay: widget.delay.ms, duration: 500.ms)
        .slideY(begin: 0.15, curve: Curves.easeOut);
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
  String get _initials => widget.creator.displayName
      .split(' ').map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
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
            color: _bgWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _hovered ? c.withOpacity(0.40) : _border),
            boxShadow: _hovered
                ? [BoxShadow(color: c.withOpacity(0.10), blurRadius: 24, offset: const Offset(0, 6))]
                : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: c.withOpacity(0.12), shape: BoxShape.circle,
                  border: Border.all(color: c.withOpacity(0.25)),
                ),
                child: Center(child: Text(_initials, style: GoogleFonts.dmSans(
                    color: c, fontWeight: FontWeight.w800, fontSize: 14))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.creator.displayName, style: GoogleFonts.dmSans(
                    color: _ink, fontWeight: FontWeight.w700, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                Text(widget.creator.tagline, style: GoogleFonts.dmSans(
                    color: _inkMuted, fontSize: 11), overflow: TextOverflow.ellipsis),
              ])),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Icon(Icons.volunteer_activism_rounded, color: c, size: 14),
              const SizedBox(width: 5),
              Text('R${widget.creator.totalTips.toStringAsFixed(0)} earned',
                  style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 12)),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go('/creator/${widget.creator.slug}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: c,
                  side: BorderSide(color: c.withOpacity(0.40)),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                ),
                child: Text('Tip', style: GoogleFonts.dmSans(
                    fontSize: 12, fontWeight: FontWeight.w700, color: c)),
              ),
            ),
          ]),
        ),
      ),
    ).animate().fadeIn(delay: widget.delay.ms, duration: 400.ms)
        .slideY(begin: 0.08, curve: Curves.easeOut);
  }
}

// ─── Light dot painter ────────────────────────────────────────────────────────
class _LightDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF004423).withOpacity(0.06)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double x = 0; x <= size.width; x += spacing)
      for (double y = 0; y <= size.height; y += spacing)
        canvas.drawCircle(Offset(x, y), 1.2, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Smooth scroll ────────────────────────────────────────────────────────────
class _SmoothScroll extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}
