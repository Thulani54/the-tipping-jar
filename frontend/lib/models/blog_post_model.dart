class BlogPostModel {
  final int id;
  final String title;
  final String slug;
  final String category;
  final String excerpt;
  final String? content; // only present in detail view
  final String? coverImage;
  final String authorName;
  final String readTime;
  final DateTime createdAt;

  const BlogPostModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.category,
    required this.excerpt,
    this.content,
    this.coverImage,
    required this.authorName,
    required this.readTime,
    required this.createdAt,
  });

  factory BlogPostModel.fromJson(Map<String, dynamic> j) => BlogPostModel(
        id: j['id'] as int,
        title: j['title'] as String? ?? '',
        slug: j['slug'] as String? ?? '',
        category: j['category'] as String? ?? 'creator-guide',
        excerpt: j['excerpt'] as String? ?? '',
        content: j['content'] as String?,
        coverImage: j['cover_image'] as String?,
        authorName: j['author_name'] as String? ?? 'TippingJar Team',
        readTime: j['read_time'] as String? ?? '5 min read',
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  /// Human-readable category label.
  String get categoryLabel {
    const labels = {
      'creator-guide': 'Creator Guide',
      'product': 'Product',
      'industry': 'Industry',
      'company': 'Company',
      'tips-tricks': 'Tips & Tricks',
    };
    return labels[category] ?? category;
  }
}
