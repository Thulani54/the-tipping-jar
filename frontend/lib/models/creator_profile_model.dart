class CreatorProfileModel {
  final int id;
  final String username;
  final String displayName;
  final String slug;
  final String tagline;
  final double? tipGoal;
  final double totalTips;
  final bool hasBankConnected;
  final String bankName;
  final String bankAccountHolder;
  final String bankAccountNumberMasked;
  final String bankRoutingNumber;
  final String bankAccountType;
  final String bankCountry;

  const CreatorProfileModel({
    required this.id,
    required this.username,
    required this.displayName,
    required this.slug,
    required this.tagline,
    required this.tipGoal,
    required this.totalTips,
    required this.hasBankConnected,
    required this.bankName,
    required this.bankAccountHolder,
    required this.bankAccountNumberMasked,
    required this.bankRoutingNumber,
    required this.bankAccountType,
    required this.bankCountry,
  });

  factory CreatorProfileModel.fromJson(Map<String, dynamic> j) =>
      CreatorProfileModel(
        id: j['id'] as int,
        username: j['username'] as String? ?? '',
        displayName: j['display_name'] as String? ?? '',
        slug: j['slug'] as String? ?? '',
        tagline: j['tagline'] as String? ?? '',
        tipGoal: j['tip_goal'] != null ? double.parse(j['tip_goal'].toString()) : null,
        totalTips: double.parse((j['total_tips'] ?? 0).toString()),
        hasBankConnected: j['has_bank_connected'] as bool? ?? false,
        bankName: j['bank_name'] as String? ?? '',
        bankAccountHolder: j['bank_account_holder'] as String? ?? '',
        bankAccountNumberMasked: j['bank_account_number_masked'] as String? ?? '',
        bankRoutingNumber: j['bank_routing_number'] as String? ?? '',
        bankAccountType: j['bank_account_type'] as String? ?? 'checking',
        bankCountry: j['bank_country'] as String? ?? 'US',
      );

  CreatorProfileModel copyWith({
    String? displayName,
    String? tagline,
    double? tipGoal,
    bool? hasBankConnected,
    String? bankName,
    String? bankAccountHolder,
    String? bankAccountNumberMasked,
    String? bankRoutingNumber,
    String? bankAccountType,
    String? bankCountry,
  }) =>
      CreatorProfileModel(
        id: id,
        username: username,
        displayName: displayName ?? this.displayName,
        slug: slug,
        tagline: tagline ?? this.tagline,
        tipGoal: tipGoal ?? this.tipGoal,
        totalTips: totalTips,
        hasBankConnected: hasBankConnected ?? this.hasBankConnected,
        bankName: bankName ?? this.bankName,
        bankAccountHolder: bankAccountHolder ?? this.bankAccountHolder,
        bankAccountNumberMasked:
            bankAccountNumberMasked ?? this.bankAccountNumberMasked,
        bankRoutingNumber: bankRoutingNumber ?? this.bankRoutingNumber,
        bankAccountType: bankAccountType ?? this.bankAccountType,
        bankCountry: bankCountry ?? this.bankCountry,
      );
}
