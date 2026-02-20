class Creator {
  final int id;
  final String username;
  final String displayName;
  final String slug;
  final String tagline;
  final String? coverImage;
  final String? avatar;
  final double? tipGoal;
  final double totalTips;

  Creator({
    required this.id,
    required this.username,
    required this.displayName,
    required this.slug,
    required this.tagline,
    this.coverImage,
    this.avatar,
    this.tipGoal,
    required this.totalTips,
  });

  factory Creator.fromJson(Map<String, dynamic> json) {
    return Creator(
      id: json['id'],
      username: json['username'] ?? '',
      displayName: json['display_name'],
      slug: json['slug'],
      tagline: json['tagline'] ?? '',
      coverImage: json['cover_image'],
      avatar: json['avatar'],
      tipGoal: json['tip_goal'] != null
          ? double.tryParse(json['tip_goal'].toString())
          : null,
      totalTips: double.tryParse(json['total_tips'].toString()) ?? 0,
    );
  }
}
