class ApiKeyModel {
  final int id;
  final String name;
  final String prefix;
  /// Only non-null immediately after creation — the backend never returns it again.
  final String? rawKey;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  const ApiKeyModel({
    required this.id,
    required this.name,
    required this.prefix,
    this.rawKey,
    required this.isActive,
    required this.createdAt,
    this.lastUsedAt,
  });

  factory ApiKeyModel.fromJson(Map<String, dynamic> j) => ApiKeyModel(
        id: j['id'] as int,
        name: j['name'] as String? ?? 'My Key',
        prefix: j['prefix'] as String? ?? '',
        rawKey: j['key'] as String?,
        isActive: j['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(j['created_at'] as String),
        lastUsedAt: j['last_used_at'] != null
            ? DateTime.tryParse(j['last_used_at'] as String)
            : null,
      );
}
