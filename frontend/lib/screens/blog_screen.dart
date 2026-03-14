import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/blog_post_model.dart';
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

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  List<BlogPostModel>? _posts;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final posts = await ApiService().getBlogs();
      if (mounted) setState(() => _posts = posts);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgWhite,
      appBar: AppNav(activeRoute: '/blog'),
      body: ScrollConfiguration(
        behavior: _SmoothScroll(),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(children: [
            _hero(),
            _body(context),
            const SiteFooter(),
          ]),
        ),
      ),
    );
  }

  Widget _hero() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 28),
    color: _bgSage,
    child: Stack(children: [
      Positioned.fill(child: CustomPaint(painter: _LightDotPainter())),
      Positioned.fill(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _green.withOpacity(0.08),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: _green.withOpacity(0.20)),
          ),
          child: Text('Blog', style: GoogleFonts.dmSans(
              color: _greenMid, fontWeight: FontWeight.w600, fontSize: 12)),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 20),
        Text('Stories, tips & insights',
            style: GoogleFonts.dmSans(color: _ink, fontWeight: FontWeight.w800,
                fontSize: 44, letterSpacing: -1.8, height: 1.1),
            textAlign: TextAlign.center)
            .animate().fadeIn(delay: 80.ms).slideY(begin: 0.15),
        const SizedBox(height: 12),
        Text('Creator guides, product news, and the economics of tipping.',
            style: GoogleFonts.dmSans(color: _inkBody, fontSize: 17, height: 1.6),
            textAlign: TextAlign.center)
            .animate().fadeIn(delay: 160.ms),
      ])),
    ]),
  );

  Widget _body(BuildContext context) {
    if (_error != null) {
      return _emptyState('Could not load posts. Please try again later.');
    }
    if (_posts == null) {
      return const SizedBox(
        height: 300,
        child: Center(child: SpinKitFadingCircle(color: _green, size: 32)),
      );
    }
    if (_posts!.isEmpty) {
      return _emptyState('No blog posts yet. Check back soon!');
    }

    final featured = _posts!.first;
    final rest = _posts!.skip(1).toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 28),
      color: _bgWhite,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1020),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Section label
            Text('Latest', style: GoogleFonts.dmSans(
                color: _inkMuted, fontSize: 12, fontWeight: FontWeight.w700,
                letterSpacing: 0.8)),
            const SizedBox(height: 20),
            _FeaturedCard(post: featured),
            if (rest.isNotEmpty) ...[
              const SizedBox(height: 48),
              Container(height: 1, color: _border),
              const SizedBox(height: 32),
              Text('More articles', style: GoogleFonts.dmSans(
                  color: _inkMuted, fontSize: 12, fontWeight: FontWeight.w700,
                  letterSpacing: 0.8)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 20, runSpacing: 20,
                children: rest.asMap().entries.map((e) =>
                    _ArticleCard(post: e.value, delay: 60 * e.key),
                ).toList(),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _emptyState(String msg) => Container(
    height: 300,
    padding: const EdgeInsets.all(32),
    child: Center(
      child: Text(msg, style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 16),
          textAlign: TextAlign.center),
    ),
  );
}

// ─── Category colour ──────────────────────────────────────────────────────────
Color _catColor(String category) {
  switch (category) {
    case 'product':   return const Color(0xFF6366F1);
    case 'industry':  return const Color(0xFF0097B2);
    case 'company':   return const Color(0xFFF59E0B);
    case 'tips-tricks': return const Color(0xFF10B981);
    default:          return _green;
  }
}

// ─── Featured card ────────────────────────────────────────────────────────────
class _FeaturedCard extends StatefulWidget {
  final BlogPostModel post;
  const _FeaturedCard({required this.post});
  @override
  State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final color = _catColor(widget.post.category);
    return GestureDetector(
      onTap: () => context.push('/blog/${widget.post.slug}'),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _hovered ? color.withOpacity(0.35) : _border),
            boxShadow: _hovered
                ? [BoxShadow(color: color.withOpacity(0.10), blurRadius: 28, offset: const Offset(0, 8))]
                : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _Tag(label: widget.post.categoryLabel, color: color),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F9F6),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('Featured', style: GoogleFonts.dmSans(
                    color: _inkMuted, fontSize: 11, fontWeight: FontWeight.w500)),
              ),
            ]),
            const SizedBox(height: 18),
            Text(widget.post.title, style: GoogleFonts.dmSans(
                color: _ink, fontWeight: FontWeight.w800,
                fontSize: 26, letterSpacing: -0.8, height: 1.2)),
            const SizedBox(height: 12),
            Text(widget.post.excerpt, style: GoogleFonts.dmSans(
                color: _inkBody, fontSize: 15, height: 1.7)),
            const SizedBox(height: 24),
            Container(height: 1, color: _border),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Center(child: Text(
                  widget.post.authorName.isNotEmpty ? widget.post.authorName[0] : 'T',
                  style: GoogleFonts.dmSans(
                      color: color, fontWeight: FontWeight.w800, fontSize: 12),
                )),
              ),
              const SizedBox(width: 8),
              Text(widget.post.authorName, style: GoogleFonts.dmSans(
                  color: _ink, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 14),
              Text(_formatDate(widget.post.createdAt),
                  style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 12)),
              Text('  ·  ', style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 12)),
              Text(widget.post.readTime,
                  style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 12)),
              const Spacer(),
              AnimatedDefaultTextStyle(
                duration: 150.ms,
                style: GoogleFonts.dmSans(
                    color: _hovered ? color : _inkMuted,
                    fontSize: 13, fontWeight: FontWeight.w600),
                child: const Text('Read more →'),
              ),
            ]),
          ]),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ─── Article card ─────────────────────────────────────────────────────────────
class _ArticleCard extends StatefulWidget {
  final BlogPostModel post;
  final int delay;
  const _ArticleCard({required this.post, required this.delay});
  @override
  State<_ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<_ArticleCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final color = _catColor(widget.post.category);
    return GestureDetector(
      onTap: () => context.push('/blog/${widget.post.slug}'),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: 200.ms,
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _hovered ? color.withOpacity(0.35) : _border),
            boxShadow: _hovered
                ? [BoxShadow(color: color.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6))]
                : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _Tag(label: widget.post.categoryLabel, color: color),
              const Spacer(),
              Text(widget.post.readTime, style: GoogleFonts.dmSans(
                  color: _inkMuted, fontSize: 11)),
            ]),
            const SizedBox(height: 14),
            Text(widget.post.title, style: GoogleFonts.dmSans(
                color: _ink, fontWeight: FontWeight.w700, fontSize: 15, height: 1.4)),
            const SizedBox(height: 8),
            Text(widget.post.excerpt, style: GoogleFonts.dmSans(
                color: _inkBody, fontSize: 12.5, height: 1.65),
                maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 18),
            Row(children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.10), shape: BoxShape.circle),
                child: Center(child: Text(
                  widget.post.authorName.isNotEmpty ? widget.post.authorName[0] : 'T',
                  style: GoogleFonts.dmSans(
                      color: color, fontWeight: FontWeight.w800, fontSize: 10),
                )),
              ),
              const SizedBox(width: 7),
              Expanded(child: Text(widget.post.authorName, style: GoogleFonts.dmSans(
                  color: _inkMuted, fontSize: 11, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis)),
              Text(_formatDate(widget.post.createdAt),
                  style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 11)),
            ]),
          ]),
        ),
      ),
    ).animate().fadeIn(delay: widget.delay.ms, duration: 400.ms)
        .slideY(begin: 0.08, curve: Curves.easeOut);
  }
}

// ─── Tag pill ─────────────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: color.withOpacity(0.22)),
    ),
    child: Text(label, style: GoogleFonts.dmSans(
        color: color, fontWeight: FontWeight.w600, fontSize: 11)),
  );
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

String _formatDate(DateTime dt) {
  const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[dt.month]} ${dt.day}, ${dt.year}';
}
