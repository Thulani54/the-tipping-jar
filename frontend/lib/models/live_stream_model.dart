class LiveStreamModel {
  final int id;
  final String roomName;
  final String title;
  final bool isLive;
  final DateTime startedAt;
  final DateTime? endedAt;

  const LiveStreamModel({
    required this.id,
    required this.roomName,
    required this.title,
    required this.isLive,
    required this.startedAt,
    this.endedAt,
  });

  factory LiveStreamModel.fromJson(Map<String, dynamic> json) => LiveStreamModel(
        id:        json['id'] as int,
        roomName:  json['room_name'] as String,
        title:     json['title'] as String? ?? '',
        isLive:    json['is_live'] as bool,
        startedAt: DateTime.parse(json['started_at'] as String),
        endedAt:   json['ended_at'] != null
            ? DateTime.parse(json['ended_at'] as String)
            : null,
      );
}
