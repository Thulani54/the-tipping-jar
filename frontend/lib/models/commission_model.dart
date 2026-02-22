class CommissionSlotModel {
  final int id;
  final bool isOpen;
  final double basePrice;
  final String description;
  final int turnaroundDays;
  final int maxActiveRequests;

  const CommissionSlotModel({
    required this.id,
    required this.isOpen,
    required this.basePrice,
    required this.description,
    required this.turnaroundDays,
    required this.maxActiveRequests,
  });

  factory CommissionSlotModel.fromJson(Map<String, dynamic> j) =>
      CommissionSlotModel(
        id: j['id'] as int,
        isOpen: j['is_open'] as bool? ?? false,
        basePrice: double.tryParse(j['base_price'].toString()) ?? 0,
        description: j['description'] as String? ?? '',
        turnaroundDays: j['turnaround_days'] as int? ?? 7,
        maxActiveRequests: j['max_active_requests'] as int? ?? 5,
      );

  Map<String, dynamic> toJson() => {
        'is_open': isOpen,
        'base_price': basePrice,
        'description': description,
        'turnaround_days': turnaroundDays,
        'max_active_requests': maxActiveRequests,
      };
}

class CommissionRequestModel {
  final int id;
  final int creator;
  final String creatorSlug;
  final String creatorDisplayName;
  final String fanName;
  final String fanEmail;
  final String title;
  final String description;
  final double agreedPrice;
  final String status;
  final String deliveryNote;
  final String createdAt;

  const CommissionRequestModel({
    required this.id,
    required this.creator,
    required this.creatorSlug,
    required this.creatorDisplayName,
    required this.fanName,
    required this.fanEmail,
    required this.title,
    required this.description,
    required this.agreedPrice,
    required this.status,
    required this.deliveryNote,
    required this.createdAt,
  });

  factory CommissionRequestModel.fromJson(Map<String, dynamic> j) =>
      CommissionRequestModel(
        id: j['id'] as int,
        creator: j['creator'] as int,
        creatorSlug: j['creator_slug'] as String? ?? '',
        creatorDisplayName: j['creator_display_name'] as String? ?? '',
        fanName: j['fan_name'] as String? ?? '',
        fanEmail: j['fan_email'] as String? ?? '',
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        agreedPrice: double.tryParse(j['agreed_price'].toString()) ?? 0,
        status: j['status'] as String? ?? 'pending',
        deliveryNote: j['delivery_note'] as String? ?? '',
        createdAt: j['created_at'] as String? ?? '',
      );

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
  bool get isCompleted => status == 'completed';
}

class TipStreakModel {
  final int id;
  final String fanEmail;
  final int creator;
  final String creatorSlug;
  final String creatorDisplayName;
  final int currentStreak;
  final int maxStreak;
  final String lastTipMonth;
  final List<String> badges;
  final String createdAt;

  const TipStreakModel({
    required this.id,
    required this.fanEmail,
    required this.creator,
    required this.creatorSlug,
    required this.creatorDisplayName,
    required this.currentStreak,
    required this.maxStreak,
    required this.lastTipMonth,
    required this.badges,
    required this.createdAt,
  });

  factory TipStreakModel.fromJson(Map<String, dynamic> j) => TipStreakModel(
        id: j['id'] as int,
        fanEmail: j['fan_email'] as String? ?? '',
        creator: j['creator'] as int,
        creatorSlug: j['creator_slug'] as String? ?? '',
        creatorDisplayName: j['creator_display_name'] as String? ?? '',
        currentStreak: j['current_streak'] as int? ?? 1,
        maxStreak: j['max_streak'] as int? ?? 1,
        lastTipMonth: j['last_tip_month'] as String? ?? '',
        badges: (j['badges'] as List?)?.map((e) => e.toString()).toList() ?? [],
        createdAt: j['created_at'] as String? ?? '',
      );
}
