class CreatorPostModel {
  final int id;
  final String title;
  final String postType; // text | image | video | file
  final String body;
  final String? mediaUrl;
  final String videoUrl;
  final bool isPublished;
  final DateTime createdAt;

  const CreatorPostModel({
    required this.id,
    required this.title,
    required this.postType,
    required this.body,
    this.mediaUrl,
    required this.videoUrl,
    required this.isPublished,
    required this.createdAt,
  });

  factory CreatorPostModel.fromJson(Map<String, dynamic> j) => CreatorPostModel(
        id: j['id'] as int,
        title: j['title'] as String? ?? '',
        postType: j['post_type'] as String? ?? 'text',
        body: j['body'] as String? ?? '',
        mediaUrl: j['media_url'] as String?,
        videoUrl: j['video_url'] as String? ?? '',
        isPublished: j['is_published'] as bool? ?? true,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  /// Public teaser: only id, title, postType, createdAt fields are guaranteed.
  factory CreatorPostModel.fromPublicJson(Map<String, dynamic> j) => CreatorPostModel(
        id: j['id'] as int,
        title: j['title'] as String? ?? '',
        postType: j['post_type'] as String? ?? 'text',
        body: '',
        videoUrl: '',
        isPublished: true,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
