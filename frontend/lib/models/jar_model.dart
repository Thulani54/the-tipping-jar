class JarModel {
  final int id;
  final String creatorSlug;
  final String name;
  final String slug;
  final String description;
  final double? goal;
  final double totalRaised;
  final int tipCount;
  final double? progressPct;
  final bool isActive;
  final DateTime createdAt;

  const JarModel({
    required this.id,
    required this.creatorSlug,
    required this.name,
    required this.slug,
    required this.description,
    this.goal,
    required this.totalRaised,
    required this.tipCount,
    this.progressPct,
    required this.isActive,
    required this.createdAt,
  });

  factory JarModel.fromJson(Map<String, dynamic> j) => JarModel(
        id: j['id'] as int,
        creatorSlug: j['creator_slug'] as String? ?? '',
        name: j['name'] as String,
        slug: j['slug'] as String,
        description: j['description'] as String? ?? '',
        goal: j['goal'] != null ? double.parse(j['goal'].toString()) : null,
        totalRaised: double.parse((j['total_raised'] ?? 0).toString()),
        tipCount: j['tip_count'] as int? ?? 0,
        progressPct: j['progress_pct'] != null
            ? double.parse(j['progress_pct'].toString())
            : null,
        isActive: j['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  String get shareUrl => '/creator/$creatorSlug/jar/$slug';
}
