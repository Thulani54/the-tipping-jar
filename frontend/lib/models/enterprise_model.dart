class EnterpriseDocument {
  final int id;
  final String docType;
  final String docTypeDisplay;
  final String? fileUrl;
  final String uploadedAt;

  const EnterpriseDocument({
    required this.id,
    required this.docType,
    required this.docTypeDisplay,
    this.fileUrl,
    required this.uploadedAt,
  });

  factory EnterpriseDocument.fromJson(Map<String, dynamic> j) => EnterpriseDocument(
        id: j['id'] as int,
        docType: j['doc_type'] as String? ?? '',
        docTypeDisplay: j['doc_type_display'] as String? ?? '',
        fileUrl: j['file_url'] as String?,
        uploadedAt: j['uploaded_at'] as String? ?? '',
      );
}

class EnterpriseModel {
  final int id;
  final String name;
  final String slug;
  final String? logo;
  final String website;
  final String plan;
  final bool isActive;
  final int creatorCount;
  final String createdAt;
  // Approval
  final String approvalStatus;
  final String rejectionReason;
  // Company info
  final String companyNameLegal;
  final String companyRegNumber;
  final String vatNumber;
  final String contactName;
  final String contactEmail;
  final String contactPhone;
  final List<EnterpriseDocument> documents;

  const EnterpriseModel({
    required this.id,
    required this.name,
    required this.slug,
    this.logo,
    required this.website,
    required this.plan,
    required this.isActive,
    required this.creatorCount,
    required this.createdAt,
    required this.approvalStatus,
    required this.rejectionReason,
    required this.companyNameLegal,
    required this.companyRegNumber,
    required this.vatNumber,
    required this.contactName,
    required this.contactEmail,
    required this.contactPhone,
    required this.documents,
  });

  bool get isPending  => approvalStatus == 'pending';
  bool get isApproved => approvalStatus == 'approved';
  bool get isRejected => approvalStatus == 'rejected';

  factory EnterpriseModel.fromJson(Map<String, dynamic> j) => EnterpriseModel(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        slug: j['slug'] as String? ?? '',
        logo: j['logo'] as String?,
        website: j['website'] as String? ?? '',
        plan: j['plan'] as String? ?? 'growth',
        isActive: j['is_active'] as bool? ?? true,
        creatorCount: j['creator_count'] as int? ?? 0,
        createdAt: j['created_at'] as String? ?? '',
        approvalStatus: j['approval_status'] as String? ?? 'pending',
        rejectionReason: j['rejection_reason'] as String? ?? '',
        companyNameLegal: j['company_name_legal'] as String? ?? '',
        companyRegNumber: j['company_registration_number'] as String? ?? '',
        vatNumber: j['vat_number'] as String? ?? '',
        contactName: j['contact_name'] as String? ?? '',
        contactEmail: j['contact_email'] as String? ?? '',
        contactPhone: j['contact_phone'] as String? ?? '',
        documents: (j['documents'] as List? ?? [])
            .map((e) => EnterpriseDocument.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class EnterpriseMember {
  final int id;
  final int creatorId;
  final String creatorSlug;
  final String displayName;
  final String? avatar;
  final String tagline;
  final double totalTips;
  final bool isActive;
  final String joinedAt;

  const EnterpriseMember({
    required this.id,
    required this.creatorId,
    required this.creatorSlug,
    required this.displayName,
    this.avatar,
    required this.tagline,
    required this.totalTips,
    required this.isActive,
    required this.joinedAt,
  });

  factory EnterpriseMember.fromJson(Map<String, dynamic> j) => EnterpriseMember(
        id: j['id'] as int,
        creatorId: j['creator_id'] as int? ?? 0,
        creatorSlug: j['creator_slug'] as String? ?? '',
        displayName: j['display_name'] as String? ?? '',
        avatar: j['avatar'] as String?,
        tagline: j['tagline'] as String? ?? '',
        totalTips: double.parse((j['total_tips'] ?? 0).toString()),
        isActive: j['is_active'] as bool? ?? true,
        joinedAt: j['joined_at'] as String? ?? '',
      );
}

class EnterpriseStats {
  final int creatorCount;
  final int tipCount;
  final double totalEarned;
  final double totalDistributed;
  final int distributionCount;
  final List<CreatorStatRow> perCreator;

  const EnterpriseStats({
    required this.creatorCount,
    required this.tipCount,
    required this.totalEarned,
    required this.totalDistributed,
    required this.distributionCount,
    required this.perCreator,
  });

  factory EnterpriseStats.fromJson(Map<String, dynamic> j) => EnterpriseStats(
        creatorCount: j['creator_count'] as int? ?? 0,
        tipCount: j['tip_count'] as int? ?? 0,
        totalEarned: double.parse((j['total_earned'] ?? 0).toString()),
        totalDistributed: double.parse((j['total_distributed'] ?? 0).toString()),
        distributionCount: j['distribution_count'] as int? ?? 0,
        perCreator: (j['per_creator'] as List? ?? [])
            .map((e) => CreatorStatRow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CreatorStatRow {
  final String slug;
  final String displayName;
  final double total;
  final int tips;

  const CreatorStatRow({
    required this.slug,
    required this.displayName,
    required this.total,
    required this.tips,
  });

  factory CreatorStatRow.fromJson(Map<String, dynamic> j) => CreatorStatRow(
        slug: j['slug'] as String? ?? '',
        displayName: j['display_name'] as String? ?? '',
        total: double.parse((j['total'] ?? 0).toString()),
        tips: j['tips'] as int? ?? 0,
      );
}

class FundDistributionItem {
  final int id;
  final String distributionReference;
  final String creatorSlug;
  final String displayName;
  final double amount;
  final String status;
  final String reference;
  final String? paidAt;

  const FundDistributionItem({
    required this.id,
    required this.distributionReference,
    required this.creatorSlug,
    required this.displayName,
    required this.amount,
    required this.status,
    required this.reference,
    this.paidAt,
  });

  factory FundDistributionItem.fromJson(Map<String, dynamic> j) =>
      FundDistributionItem(
        id: j['id'] as int,
        distributionReference: j['distribution_reference'] as String? ?? '',
        creatorSlug: j['creator_slug'] as String? ?? '',
        displayName: j['display_name'] as String? ?? '',
        amount: double.parse((j['amount'] ?? 0).toString()),
        status: j['status'] as String? ?? 'pending',
        reference: j['reference'] as String? ?? '',
        paidAt: j['paid_at'] as String?,
      );
}

class FundDistribution {
  final int id;
  final String reference;
  final double totalAmount;
  final String notes;
  final String distributedByUsername;
  final String distributedAt;
  final List<FundDistributionItem> items;

  const FundDistribution({
    required this.id,
    required this.reference,
    required this.totalAmount,
    required this.notes,
    required this.distributedByUsername,
    required this.distributedAt,
    required this.items,
  });

  factory FundDistribution.fromJson(Map<String, dynamic> j) => FundDistribution(
        id: j['id'] as int,
        reference: j['reference'] as String? ?? '',
        totalAmount: double.parse((j['total_amount'] ?? 0).toString()),
        notes: j['notes'] as String? ?? '',
        distributedByUsername: j['distributed_by_username'] as String? ?? '',
        distributedAt: j['distributed_at'] as String? ?? '',
        items: (j['items'] as List? ?? [])
            .map((e) => FundDistributionItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
