class TipModel {
  final int id;
  final String tipperName;
  final double amount;
  final String message;
  final String status;
  final DateTime createdAt;
  final String creatorSlug;
  final String creatorDisplayName;

  const TipModel({
    required this.id,
    required this.tipperName,
    required this.amount,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.creatorSlug,
    required this.creatorDisplayName,
  });

  factory TipModel.fromJson(Map<String, dynamic> j) => TipModel(
        id: j['id'] as int,
        tipperName: j['tipper_name'] as String? ?? 'Anonymous',
        amount: double.parse(j['amount'].toString()),
        message: j['message'] as String? ?? '',
        status: j['status'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
        creatorSlug: j['creator_slug'] as String? ?? '',
        creatorDisplayName: j['creator_display_name'] as String? ?? '',
      );

  String get relativeTime {
    final diff = DateTime.now().toUtc().difference(createdAt.toUtc());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}
