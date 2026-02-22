class MilestoneModel {
  final int id;
  final String title;
  final String description;
  final double targetAmount;
  final double currentMonthTotal;
  final double progressPct;
  final int? bonusPost;
  final bool isActive;
  final bool isAchieved;
  final String? achievedAt;
  final String createdAt;

  const MilestoneModel({
    required this.id,
    required this.title,
    required this.description,
    required this.targetAmount,
    required this.currentMonthTotal,
    required this.progressPct,
    this.bonusPost,
    required this.isActive,
    required this.isAchieved,
    this.achievedAt,
    required this.createdAt,
  });

  factory MilestoneModel.fromJson(Map<String, dynamic> j) => MilestoneModel(
        id: j['id'] as int,
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        targetAmount: double.tryParse(j['target_amount'].toString()) ?? 0,
        currentMonthTotal:
            double.tryParse(j['current_month_total']?.toString() ?? '0') ?? 0,
        progressPct:
            double.tryParse(j['progress_pct']?.toString() ?? '0') ?? 0,
        bonusPost: j['bonus_post'] as int?,
        isActive: j['is_active'] as bool? ?? true,
        isAchieved: j['is_achieved'] as bool? ?? false,
        achievedAt: j['achieved_at'] as String?,
        createdAt: j['created_at'] as String? ?? '',
      );
}
