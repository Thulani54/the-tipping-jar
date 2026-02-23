class KycDocumentModel {
  final int id;
  final String docType;
  final String docTypeDisplay;
  final String? fileUrl;
  final String status; // 'pending' | 'approved' | 'declined'
  final String declineReason;
  final DateTime uploadedAt;

  const KycDocumentModel({
    required this.id,
    required this.docType,
    required this.docTypeDisplay,
    this.fileUrl,
    required this.status,
    required this.declineReason,
    required this.uploadedAt,
  });

  factory KycDocumentModel.fromJson(Map<String, dynamic> j) => KycDocumentModel(
        id: j['id'] as int,
        docType: j['doc_type'] as String? ?? '',
        docTypeDisplay: j['doc_type_display'] as String? ?? '',
        fileUrl: j['file_url'] as String?,
        status: j['status'] as String? ?? 'pending',
        declineReason: j['decline_reason'] as String? ?? '',
        uploadedAt: DateTime.tryParse(j['uploaded_at'] as String? ?? '') ?? DateTime.now(),
      );
}

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
  final String thankYouMessage;
  // Creator info
  final String category;
  final String platforms;
  final String audienceSize;
  final String ageGroup;
  final String audienceGender;
  // KYC
  final String kycStatus; // 'not_started' | 'pending' | 'approved' | 'declined'
  final String kycDeclineReason;
  final List<KycDocumentModel> kycDocuments;

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
    this.thankYouMessage = '',
    this.category = '',
    this.platforms = '',
    this.audienceSize = '',
    this.ageGroup = '',
    this.audienceGender = '',
    this.kycStatus = 'not_started',
    this.kycDeclineReason = '',
    this.kycDocuments = const [],
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
        bankCountry: j['bank_country'] as String? ?? 'ZA',
        thankYouMessage: j['thank_you_message'] as String? ?? '',
        category: j['category'] as String? ?? '',
        platforms: j['platforms'] as String? ?? '',
        audienceSize: j['audience_size'] as String? ?? '',
        ageGroup: j['age_group'] as String? ?? '',
        audienceGender: j['audience_gender'] as String? ?? '',
        kycStatus: j['kyc_status'] as String? ?? 'not_started',
        kycDeclineReason: j['kyc_decline_reason'] as String? ?? '',
        kycDocuments: (j['kyc_documents'] as List<dynamic>? ?? [])
            .map((d) => KycDocumentModel.fromJson(d as Map<String, dynamic>))
            .toList(),
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
    String? thankYouMessage,
    String? category,
    String? platforms,
    String? audienceSize,
    String? ageGroup,
    String? audienceGender,
    String? kycStatus,
    String? kycDeclineReason,
    List<KycDocumentModel>? kycDocuments,
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
        bankAccountNumberMasked: bankAccountNumberMasked ?? this.bankAccountNumberMasked,
        bankRoutingNumber: bankRoutingNumber ?? this.bankRoutingNumber,
        bankAccountType: bankAccountType ?? this.bankAccountType,
        bankCountry: bankCountry ?? this.bankCountry,
        thankYouMessage: thankYouMessage ?? this.thankYouMessage,
        category: category ?? this.category,
        platforms: platforms ?? this.platforms,
        audienceSize: audienceSize ?? this.audienceSize,
        ageGroup: ageGroup ?? this.ageGroup,
        audienceGender: audienceGender ?? this.audienceGender,
        kycStatus: kycStatus ?? this.kycStatus,
        kycDeclineReason: kycDeclineReason ?? this.kycDeclineReason,
        kycDocuments: kycDocuments ?? this.kycDocuments,
      );
}
