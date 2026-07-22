/// Model đại diện cho chi tiết Hồ sơ pháp lý.
class LegalProfileUiModel {
  final String entityType;
  final String legalName;
  final String taxCode;
  final String registeredAddress;
  final String city;
  final String ward;

  const LegalProfileUiModel({
    required this.entityType,
    required this.legalName,
    required this.taxCode,
    required this.registeredAddress,
    required this.city,
    required this.ward,
  });
}

/// Model đại diện cho chi tiết Hồ sơ tổ chức.
class OrganizationProfileUiModel {
  final String id;
  final String name;
  final String statusLabel;
  final String statusDescription;
  final String phone;
  final String email;
  final String address;
  final bool hasLegalProfile;
  final String legalNoticeTitle;
  final String legalNoticeMessage;
  final LegalProfileUiModel? legalProfile;

  const OrganizationProfileUiModel({
    required this.id,
    required this.name,
    required this.statusLabel,
    required this.statusDescription,
    required this.phone,
    required this.email,
    required this.address,
    required this.hasLegalProfile,
    required this.legalNoticeTitle,
    required this.legalNoticeMessage,
    this.legalProfile,
  });
}
