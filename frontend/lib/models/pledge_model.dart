class PledgeModel {
  final int id;
  final String fanEmail;
  final String fanName;
  final int creator;
  final String creatorSlug;
  final String creatorDisplayName;
  final int? tier;
  final String? tierName;
  final double amount;
  final String status;
  final String? nextChargeDate;
  final String createdAt;

  const PledgeModel({
    required this.id,
    required this.fanEmail,
    required this.fanName,
    required this.creator,
    required this.creatorSlug,
    required this.creatorDisplayName,
    this.tier,
    this.tierName,
    required this.amount,
    required this.status,
    this.nextChargeDate,
    required this.createdAt,
  });

  factory PledgeModel.fromJson(Map<String, dynamic> j) => PledgeModel(
        id: j['id'] as int,
        fanEmail: j['fan_email'] as String? ?? '',
        fanName: j['fan_name'] as String? ?? 'Anonymous',
        creator: j['creator'] as int,
        creatorSlug: j['creator_slug'] as String? ?? '',
        creatorDisplayName: j['creator_display_name'] as String? ?? '',
        tier: j['tier'] as int?,
        tierName: j['tier_name'] as String?,
        amount: double.tryParse(j['amount'].toString()) ?? 0,
        status: j['status'] as String? ?? 'active',
        nextChargeDate: j['next_charge_date'] as String?,
        createdAt: j['created_at'] as String? ?? '',
      );

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isCancelled => status == 'cancelled';
}
