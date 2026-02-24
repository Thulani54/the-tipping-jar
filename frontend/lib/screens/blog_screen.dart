import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/blog_post_model.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/app_nav.dart';

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
      backgroundColor: kDark,
      appBar: AppNav(activeRoute: '/blog'),
      body: SingleChildScrollView(
        child: Column(children: [
          _hero(),
          _body(context),
          _footer(),
        ]),
      ),
    );
  }

  Widget _hero() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 28),
    color: kDarker,
    child: Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: kPrimary.withOpacity(0.3)),
        ),
        child: Text('Blog', style: GoogleFonts.dmSans(
            color: kPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
      ).animate().fadeIn(duration: 400.ms),
      const SizedBox(height: 20),
      Text('Stories, tips & insights',
          style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800,
              fontSize: 42, letterSpacing: -1.5),
          textAlign: TextAlign.center)
          .animate().fadeIn(delay: 80.ms).slideY(begin: 0.2),
      const SizedBox(height: 14),
      Text('Creator guides, product news, and the economics of tipping.',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 17, height: 1.6),
          textAlign: TextAlign.center)
          .animate().fadeIn(delay: 160.ms),
    ]),
  );

  Widget _body(BuildContext context) {
    if (_error != null) {
      return _emptyState('Could not load posts. Please try again later.');
    }
    if (_posts == null) {
      return const SizedBox(
        height: 300,
        child: Center(child: SpinKitFadingCircle(color: kPrimary, size: 32)),
      );
    }
    if (_posts!.isEmpty) {
      return _emptyState('No blog posts yet. Check back soon!');
    }

    final featured = _posts!.first;
    final rest = _posts!.skip(1).toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 28),
      color: kDark,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(children: [
            _FeaturedCard(post: featured),
            if (rest.isNotEmpty) ...[
              const SizedBox(height: 40),
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
      child: Text(msg, style: GoogleFonts.dmSans(color: kMuted, fontSize: 16),
          textAlign: TextAlign.center),
    ),
  );

  Widget _footer() => Container(
    color: kDarker,
    padding: const EdgeInsets.all(24),
    child: const Text('© 2026 TippingJar. All rights reserved.',
        style: TextStyle(color: kMuted, fontSize: 12), textAlign: TextAlign.center),
  );
}

// ─── Category colour mapping ──────────────────────────────────────────────────

Color _catColor(String category) {
  switch (category) {
    case 'product':
      return const Color(0xFF818CF8);
    case 'industry':
      return const Color(0xFF0097B2);
    case 'company':
      return const Color(0xFFFBBF24);
    case 'tips-tricks':
      return const Color(0xFFF87171);
    default:
      return kPrimary;
  }
}

// ─── Featured card ────────────────────────────────────────────────────────────

class _FeaturedCard extends StatelessWidget {
  final BlogPostModel post;
  const _FeaturedCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final color = _catColor(post.category);
    return GestureDetector(
      onTap: () => context.push('/blog/${post.slug}'),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: kCardBg, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kBorder),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _Tag(label: post.categoryLabel, color: color),
              const Spacer(),
              Text('Featured', style: GoogleFonts.dmSans(
                  color: kMuted, fontSize: 11, fontStyle: FontStyle.italic)),
            ]),
            const SizedBox(height: 16),
            Text(post.title, style: GoogleFonts.dmSans(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 26, letterSpacing: -0.8, height: 1.25)),
            const SizedBox(height: 12),
            Text(post.excerpt, style: GoogleFonts.dmSans(
                color: kMuted, fontSize: 15, height: 1.65)),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.15), shape: BoxShape.circle),
                child: Center(child: Text(
                  post.authorName.isNotEmpty ? post.authorName[0] : 'T',
                  style: GoogleFonts.dmSans(
                      color: color, fontWeight: FontWeight.w800, fontSize: 12),
                )),
              ),
              const SizedBox(width: 8),
              Text(post.authorName, style: GoogleFonts.dmSans(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 16),
              Text(_formatDate(post.createdAt),
                  style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
              const SizedBox(width: 12),
              Text('·', style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
              const SizedBox(width: 12),
              Text(post.readTime,
                  style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
              const Spacer(),
              Text('Read more →', style: GoogleFonts.dmSans(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ─── Article card ─────────────────────────────────────────────────────────────

class _ArticleCard extends StatelessWidget {
  final BlogPostModel post;
  final int delay;
  const _ArticleCard({required this.post, required this.delay});

  @override
  Widget build(BuildContext context) {
    final color = _catColor(post.category);
    return GestureDetector(
      onTap: () => context.push('/blog/${post.slug}'),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: kCardBg, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Tag(label: post.categoryLabel, color: color),
            const SizedBox(height: 12),
            Text(post.title, style: GoogleFonts.dmSans(color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 15, height: 1.4)),
            const SizedBox(height: 8),
            Text(post.excerpt, style: GoogleFonts.dmSans(
                color: kMuted, fontSize: 12, height: 1.6),
                maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            Row(children: [
              Text(_formatDate(post.createdAt),
                  style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
              const SizedBox(width: 8),
              Text('·', style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
              const SizedBox(width: 8),
              Text(post.readTime,
                  style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
            ]),
          ]),
        ),
      ),
    ).animate().fadeIn(delay: delay.ms, duration: 400.ms).slideY(begin: 0.08);
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(36),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Text(label, style: GoogleFonts.dmSans(
        color: color, fontWeight: FontWeight.w600, fontSize: 11)),
  );
}

String _formatDate(DateTime dt) {
  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[dt.month]} ${dt.day}, ${dt.year}';
}
