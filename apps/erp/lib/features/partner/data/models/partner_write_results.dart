/// Warning returned on successful mutations (e.g. duplicate hints).
final class PartnerWarningDto {
  const PartnerWarningDto({
    required this.code,
    this.field,
    required this.message,
  });

  final String code;
  final String? field;
  final String message;

  static List<PartnerWarningDto> listFromJson(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return raw
        .map(
          (item) => PartnerWarningDto(
            code: (item as Map)['code'] as String,
            message: item['message'] as String? ?? '',
            field: item['field'] as String?,
          ),
        )
        .toList(growable: false);
  }
}

/// Result of a successful partner create mutation.
final class CreatePartnerResult {
  const CreatePartnerResult({
    required this.partnerId,
    this.warnings = const [],
  });

  factory CreatePartnerResult.fromJson(Map<String, dynamic> row) {
    return CreatePartnerResult(
      partnerId: row['partner_id'] as String,
      warnings: PartnerWarningDto.listFromJson(row['warnings']),
    );
  }

  final String partnerId;
  final List<PartnerWarningDto> warnings;
}

/// Result of a successful partner profile update.
final class UpdatePartnerProfileResult {
  const UpdatePartnerProfileResult({
    required this.partnerId,
    required this.expectedVersion,
    this.warnings = const [],
  });

  factory UpdatePartnerProfileResult.fromJson(Map<String, dynamic> row) {
    return UpdatePartnerProfileResult(
      partnerId: row['partner_id'] as String,
      expectedVersion: row['expected_version'] as int,
      warnings: PartnerWarningDto.listFromJson(row['warnings']),
    );
  }

  final String partnerId;
  final int expectedVersion;
  final List<PartnerWarningDto> warnings;
}

/// Result of adding an organization contact link.
final class AddOrganizationContactResult {
  const AddOrganizationContactResult({
    required this.organizationPartnerId,
    required this.personPartnerId,
  });

  factory AddOrganizationContactResult.fromJson(Map<String, dynamic> row) {
    return AddOrganizationContactResult(
      organizationPartnerId: row['organization_partner_id'] as String,
      personPartnerId: row['person_partner_id'] as String,
    );
  }

  final String organizationPartnerId;
  final String personPartnerId;
}

/// Kết quả ngừng hoạt động / kích hoạt lại / xoá mềm (cùng hai trường).
final class PartnerVersionResult {
  const PartnerVersionResult({
    required this.partnerId,
    required this.expectedVersion,
  });

  factory PartnerVersionResult.fromJson(Map<String, dynamic> row) {
    return PartnerVersionResult(
      partnerId: row['partner_id'] as String,
      expectedVersion: row['expected_version'] as int,
    );
  }

  final String partnerId;
  final int expectedVersion;
}

/// Soft-delete eligibility check result.
final class DeleteEligibilityDto {
  const DeleteEligibilityDto({
    required this.eligible,
    this.reason,
  });

  factory DeleteEligibilityDto.fromJson(Map<String, dynamic> row) {
    return DeleteEligibilityDto(
      eligible: row['eligible'] as bool,
      reason: row['reason'] as String?,
    );
  }

  final bool eligible;
  final String? reason;
}
