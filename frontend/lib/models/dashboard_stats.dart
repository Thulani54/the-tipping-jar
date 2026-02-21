class TopFan {
  final String name;
  final double total;
  const TopFan({required this.name, required this.total});
  factory TopFan.fromJson(Map<String, dynamic> j) => TopFan(
        name: j['name'] as String,
        total: (j['total'] as num).toDouble(),
      );
}

class DashboardStats {
  final double totalEarned;
  final double thisMonthEarned;
  final int tipCount;
  final double pendingPayout;
  final List<double> weeklyData;
  final List<String> weekLabels;
  final List<TopFan> topFans;

  const DashboardStats({
    required this.totalEarned,
    required this.thisMonthEarned,
    required this.tipCount,
    required this.pendingPayout,
    required this.weeklyData,
    required this.weekLabels,
    required this.topFans,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
        totalEarned: (j['total_earned'] as num).toDouble(),
        thisMonthEarned: (j['this_month_earned'] as num).toDouble(),
        tipCount: j['tip_count'] as int,
        pendingPayout: (j['pending_payout'] as num).toDouble(),
        weeklyData:
            (j['weekly_data'] as List).map((e) => (e as num).toDouble()).toList(),
        weekLabels: (j['week_labels'] as List).cast<String>(),
        topFans: (j['top_fans'] as List)
            .map((e) => TopFan.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
