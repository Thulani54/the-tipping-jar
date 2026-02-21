class DisputeModel {
  final int id;
  final String reference;
  final String token;
  final String name;
  final String email;
  final String reason;
  final String reasonLabel;
  final String description;
  final String tipRef;
  final String status;
  final String statusLabel;
  final String adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DisputeModel({
    required this.id,
    required this.reference,
    required this.token,
    required this.name,
    required this.email,
    required this.reason,
    required this.reasonLabel,
    required this.description,
    required this.tipRef,
    required this.status,
    required this.statusLabel,
    required this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DisputeModel.fromJson(Map<String, dynamic> j) => DisputeModel(
        id: j['id'] as int,
        reference: j['reference'] as String? ?? '',
        token: j['token'] as String? ?? '',
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        reason: j['reason'] as String? ?? '',
        reasonLabel: j['reason_label'] as String? ?? '',
        description: j['description'] as String? ?? '',
        tipRef: j['tip_ref'] as String? ?? '',
        status: j['status'] as String? ?? 'open',
        statusLabel: j['status_label'] as String? ?? 'Open',
        adminNotes: j['admin_notes'] as String? ?? '',
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );

  bool get isOpen         => status == 'open';
  bool get isInvestigating => status == 'investigating';
  bool get isResolved     => status == 'resolved';
  bool get isClosed       => status == 'closed';
}
