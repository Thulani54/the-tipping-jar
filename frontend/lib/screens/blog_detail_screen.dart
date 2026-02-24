import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/blog_post_model.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/app_nav.dart';

class BlogDetailScreen extends StatefulWidget {
  final String slug;
  const BlogDetailScreen({super.key, required this.slug});

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  BlogPostModel? _post;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final post = await ApiService().getBlog(widget.slug);
      if (mounted) setState(() { _post = post; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      appBar: AppNav(activeRoute: '/blog'),
      body: _loading
          ? const Center(child: SpinKitFadingCircle(color: kPrimary, size: 32))
          : _error != null
              ? _ErrorView(error: _error!, onRetry: () {
                  setState(() { _error = null; _loading = true; });
                  _load();
                })
              : _PostBody(post: _post!),
    );
  }
}

// ─── Post body ────────────────────────────────────────────────────────────────

class _PostBody extends StatelessWidget {
  final BlogPostModel post;
  const _PostBody({required this.post});

  @override
  Widget build(BuildContext context) {
    final color = _catColor(post.category);
    return SingleChildScrollView(
      child: Column(children: [
        // Hero banner
        Container(
          width: double.infinity,
          color: kDarker,
          padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Back link
                GestureDetector(
                  onTap: () => context.go('/blog'),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.arrow_back_ios, size: 13, color: kMuted),
                      const SizedBox(width: 4),
                      Text('All posts', style: GoogleFonts.dmSans(
                          color: kMuted, fontSize: 13)),
                    ]),
                  ),
                ),
                const SizedBox(height: 28),
                // Category tag
                _Tag(label: post.categoryLabel, color: color),
                const SizedBox(height: 20),
                // Title
                Text(post.title, style: GoogleFonts.dmSans(
                  color: Colors.white, fontWeight: FontWeight.w800,
                  fontSize: 38, letterSpacing: -1.2, height: 1.2,
                )).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15),
                const SizedBox(height: 16),
                // Excerpt
                Text(post.excerpt, style: GoogleFonts.dmSans(
                    color: kMuted, fontSize: 17, height: 1.65))
                    .animate().fadeIn(delay: 80.ms),
                const SizedBox(height: 24),
                // Meta row
                Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.15), shape: BoxShape.circle),
                    child: Center(child: Text(
                      post.authorName.isNotEmpty ? post.authorName[0] : 'T',
                      style: GoogleFonts.dmSans(color: color,
                          fontWeight: FontWeight.w800, fontSize: 13),
                    )),
                  ),
                  const SizedBox(width: 10),
                  Text(post.authorName, style: GoogleFonts.dmSans(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(width: 16),
                  Text(_formatDate(post.createdAt),
                      style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
                  const SizedBox(width: 10),
                  Text('·', style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
                  const SizedBox(width: 10),
                  Text(post.readTime,
                      style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
                ]),
                // Cover image
                if (post.coverImage != null) ...[
                  const SizedBox(height: 32),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(post.coverImage!,
                        width: double.infinity, height: 320, fit: BoxFit.cover),
                  ),
                ],
              ]),
            ),
          ),
        ),
        // Content area
        Container(
          width: double.infinity,
          color: kDark,
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: _HtmlContent(html: post.content ?? ''),
            ),
          ),
        ),
        // Footer
        Container(
          color: kDarker,
          padding: const EdgeInsets.all(24),
          child: const Text('© 2026 TippingJar. All rights reserved.',
              style: TextStyle(color: kMuted, fontSize: 12),
              textAlign: TextAlign.center),
        ),
      ]),
    );
  }
}

// ─── HTML content renderer ────────────────────────────────────────────────────

class _HtmlContent extends StatelessWidget {
  final String html;
  const _HtmlContent({required this.html});

  @override
  Widget build(BuildContext context) {
    if (html.trim().isEmpty) {
      return Text('No content available.',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 15));
    }
    return Html(
      data: html,
      style: {
        'body': Style(
          color: const Color(0xFFD1D5DB),
          fontFamily: 'DM Sans',
          fontSize: FontSize(16),
          lineHeight: LineHeight(1.75),
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
        'h1': Style(
          color: Colors.white,
          fontSize: FontSize(30),
          fontWeight: FontWeight.w800,
          margin: Margins.only(top: 36, bottom: 16),
          letterSpacing: -0.8,
        ),
        'h2': Style(
          color: Colors.white,
          fontSize: FontSize(24),
          fontWeight: FontWeight.w700,
          margin: Margins.only(top: 32, bottom: 12),
          letterSpacing: -0.5,
        ),
        'h3': Style(
          color: Colors.white,
          fontSize: FontSize(19),
          fontWeight: FontWeight.w700,
          margin: Margins.only(top: 24, bottom: 8),
        ),
        'p': Style(
          margin: Margins.only(bottom: 20),
        ),
        'strong, b': Style(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        'em, i': Style(
          fontStyle: FontStyle.italic,
        ),
        'u': Style(
          textDecoration: TextDecoration.underline,
        ),
        'a': Style(
          color: kPrimary,
          textDecoration: TextDecoration.underline,
        ),
        'ul': Style(
          margin: Margins.only(bottom: 20, left: 24),
        ),
        'ol': Style(
          margin: Margins.only(bottom: 20, left: 24),
        ),
        'li': Style(
          margin: Margins.only(bottom: 6),
        ),
        'blockquote': Style(
          color: kMuted,
          fontStyle: FontStyle.italic,
          border: Border(left: BorderSide(color: kPrimary, width: 3)),
          padding: HtmlPaddings.only(left: 16),
          margin: Margins.only(left: 0, bottom: 20),
        ),
        'code': Style(
          backgroundColor: kCardBg,
          color: const Color(0xFF86EFAC),
          fontFamily: 'monospace',
          fontSize: FontSize(13),
          padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
        ),
        'pre': Style(
          backgroundColor: kCardBg,
          color: const Color(0xFF86EFAC),
          fontFamily: 'monospace',
          fontSize: FontSize(13),
          padding: HtmlPaddings.all(16),
          margin: Margins.only(bottom: 20),
        ),
        'hr': Style(
          color: kBorder,
          margin: Margins.symmetric(vertical: 32),
        ),
        'img': Style(
          width: Width(double.infinity),
          margin: Margins.only(bottom: 20),
        ),
      },
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Post not found', style: GoogleFonts.dmSans(
            color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Text('The post you\'re looking for doesn\'t exist or has been removed.',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 15),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => context.go('/blog'),
          style: ElevatedButton.styleFrom(backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Back to Blog'),
        ),
      ]),
    ),
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Color _catColor(String category) {
  switch (category) {
    case 'product': return const Color(0xFF818CF8);
    case 'industry': return const Color(0xFF0097B2);
    case 'company': return const Color(0xFFFBBF24);
    case 'tips-tricks': return const Color(0xFFF87171);
    default: return kPrimary;
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(36),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(label, style: GoogleFonts.dmSans(
        color: color, fontWeight: FontWeight.w600, fontSize: 12)),
  );
}

String _formatDate(DateTime dt) {
  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[dt.month]} ${dt.day}, ${dt.year}';
}
