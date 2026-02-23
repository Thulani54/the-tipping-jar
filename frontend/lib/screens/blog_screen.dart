import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/app_nav.dart';

class BlogScreen extends StatelessWidget {
  const BlogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      appBar: AppNav(activeRoute: '/blog'),
      body: SingleChildScrollView(
        child: Column(children: [
          _hero(),
          _posts(context),
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

  Widget _posts(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 28),
    color: kDark,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(children: [
          // Featured post
          _FeaturedPost(
            tag: 'Creator guide',
            title: 'How to grow your tip income from \$0 to \$1,000/month',
            excerpt: 'We interviewed 20 creators who crossed the \$1K/month mark. Here\'s exactly what they did — from writing their first post to optimising their tip page CTA.',
            author: 'Lerato Dlamini', date: 'Feb 12, 2026', readTime: '8 min read',
            color: kPrimary,
          ),
          const SizedBox(height: 40),
          // Grid
          Wrap(
            spacing: 20, runSpacing: 20,
            children: _articles().asMap().entries.map((e) =>
              _ArticleCard(article: e.value, delay: 60 * e.key),
            ).toList(),
          ),
        ]),
      ),
    ),
  );

  List<_Article> _articles() => [
    _Article('Product', 'Introducing the TippingJar Developer API',
        'Build tip flows into your own platform with our new public REST API and webhook system.',
        'Feb 14, 2026', '5 min read', const Color(0xFF818CF8)),
    _Article('Creator guide', '5 ways to tell your audience about your tip page',
        'Getting the word out is half the battle. Here are five proven tactics from our top creators.',
        'Feb 8, 2026', '4 min read', kPrimary),
    _Article('Industry', 'The creator economy in 2026: what the numbers say',
        'Fan monetisation grew 34% year-over-year. We break down the data and what it means for independent creators.',
        'Jan 30, 2026', '6 min read', const Color(0xFF0097B2)),
    _Article('Product', 'Pro plan deep dive: analytics that actually help',
        'A tour of the new analytics dashboard — revenue forecasting, fan cohorts, and more.',
        'Jan 22, 2026', '7 min read', const Color(0xFFFBBF24)),
    _Article('Creator guide', 'Writing a tip page bio that converts',
        'The words on your tip page matter more than you think. Here\'s our formula.',
        'Jan 15, 2026', '3 min read', const Color(0xFFF87171)),
    _Article('Company', 'TippingJar crossed 2,400 creators — a milestone reflection',
        'What we\'ve learned from the first 2,400 creators who trusted us with their income.',
        'Jan 5, 2026', '5 min read', kPrimary),
  ];

  Widget _footer() => Container(
    color: kDarker,
    padding: const EdgeInsets.all(24),
    child: const Text('© 2026 TippingJar. All rights reserved.',
        style: TextStyle(color: kMuted, fontSize: 12), textAlign: TextAlign.center),
  );
}

class _Article {
  final String tag, title, excerpt, date, readTime;
  final Color color;
  const _Article(this.tag, this.title, this.excerpt, this.date, this.readTime, this.color);
}

class _FeaturedPost extends StatelessWidget {
  final String tag, title, excerpt, author, date, readTime;
  final Color color;
  const _FeaturedPost({required this.tag, required this.title, required this.excerpt,
      required this.author, required this.date, required this.readTime, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: kCardBg, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: kBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(tag, style: GoogleFonts.dmSans(
            color: color, fontWeight: FontWeight.w600, fontSize: 12)),
      ),
      const SizedBox(height: 16),
      Text(title, style: GoogleFonts.dmSans(color: Colors.white,
          fontWeight: FontWeight.w800, fontSize: 26, letterSpacing: -0.8, height: 1.25)),
      const SizedBox(height: 12),
      Text(excerpt, style: GoogleFonts.dmSans(color: kMuted, fontSize: 15, height: 1.65)),
      const SizedBox(height: 20),
      Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Center(child: Text(author[0], style: GoogleFonts.dmSans(
              color: color, fontWeight: FontWeight.w800, fontSize: 12))),
        ),
        const SizedBox(width: 8),
        Text(author, style: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(width: 16),
        Text(date, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
        const SizedBox(width: 12),
        Text('·', style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
        const SizedBox(width: 12),
        Text(readTime, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
      ]),
    ]),
  ).animate().fadeIn(duration: 400.ms);
}

class _ArticleCard extends StatelessWidget {
  final _Article article;
  final int delay;
  const _ArticleCard({required this.article, required this.delay});

  @override
  Widget build(BuildContext context) => Container(
    width: 300,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: kCardBg, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: article.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(36),
        ),
        child: Text(article.tag, style: GoogleFonts.dmSans(
            color: article.color, fontWeight: FontWeight.w600, fontSize: 11)),
      ),
      const SizedBox(height: 12),
      Text(article.title, style: GoogleFonts.dmSans(color: Colors.white,
          fontWeight: FontWeight.w700, fontSize: 15, height: 1.4)),
      const SizedBox(height: 8),
      Text(article.excerpt, style: GoogleFonts.dmSans(
          color: kMuted, fontSize: 12, height: 1.6),
          maxLines: 3, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 16),
      Row(children: [
        Text(article.date, style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
        const SizedBox(width: 8),
        Text('·', style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
        const SizedBox(width: 8),
        Text(article.readTime, style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
      ]),
    ]),
  ).animate().fadeIn(delay: delay.ms, duration: 400.ms).slideY(begin: 0.08);
}
