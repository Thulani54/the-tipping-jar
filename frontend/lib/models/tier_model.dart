class TierModel {
  final int id;
  final String name;
  final double price;
  final String description;
  final List<String> perks;
  final bool isActive;
  final int sortOrder;
  final String createdAt;

  const TierModel({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.perks,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
  });

  factory TierModel.fromJson(Map<String, dynamic> j) => TierModel(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        price: double.tryParse(j['price'].toString()) ?? 0,
        description: j['description'] as String? ?? '',
        perks: (j['perks'] as List?)?.map((e) => e.toString()).toList() ?? [],
        isActive: j['is_active'] as bool? ?? true,
        sortOrder: j['sort_order'] as int? ?? 0,
        createdAt: j['created_at'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'description': description,
        'perks': perks,
        'is_active': isActive,
        'sort_order': sortOrder,
      };
}
