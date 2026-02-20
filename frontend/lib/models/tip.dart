class Tip {
  final int id;
  final String tipperName;
  final double amount;
  final String message;
  final String status;
  final DateTime createdAt;

  Tip({
    required this.id,
    required this.tipperName,
    required this.amount,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory Tip.fromJson(Map<String, dynamic> json) {
    return Tip(
      id: json['id'],
      tipperName: json['tipper_name'] ?? 'Anonymous',
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      message: json['message'] ?? '',
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
