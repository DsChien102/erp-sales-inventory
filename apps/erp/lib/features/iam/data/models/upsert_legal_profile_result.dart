import 'tenant_profile.dart';

/// Kết quả upsert hồ sơ pháp lý: đã lưu, hoặc cảnh báo trùng MST.
final class UpsertLegalProfileResult {
  const UpsertLegalProfileResult.saved({
    required this.profile,
    required this.tenantVersion,
  }) : warning = null;

  const UpsertLegalProfileResult.warning({
    required this.warning,
    required this.tenantVersion,
  }) : profile = null;

  final TenantLegalProfile? profile;
  final DuplicateTaxCodeWarning? warning;
  final int tenantVersion;

  bool get isSaved => profile != null;
  bool get isWarning => warning != null;

  factory UpsertLegalProfileResult.fromJson(Map<String, dynamic> row) {
    final tenantVersion = (row['tenant_version'] as num?)?.toInt() ?? 1;
    final warningRaw = row['warning'];
    if (warningRaw is Map && warningRaw.isNotEmpty) {
      final warning = Map<String, dynamic>.from(warningRaw);
      return UpsertLegalProfileResult.warning(
        tenantVersion: tenantVersion,
        warning: DuplicateTaxCodeWarning(
          code: warning['code'] as String? ?? DuplicateTaxCodeWarning.codeValue,
          message: warning['message'] as String? ?? 'Duplicate tax code',
        ),
      );
    }
    final profileRaw = row['profile'];
    final profileMap = profileRaw is Map
        ? Map<String, dynamic>.from(profileRaw)
        : row;
    return UpsertLegalProfileResult.saved(
      tenantVersion: tenantVersion,
      profile: TenantLegalProfile.fromJson(profileMap),
    );
  }
}

/// Cảnh báo trùng MST — nhánh thành công, không phải lỗi chặn.
final class DuplicateTaxCodeWarning {
  const DuplicateTaxCodeWarning({
    this.code = codeValue,
    required this.message,
  });

  static const codeValue = 'DUPLICATE_TAX_CODE_WARNING';

  final String code;
  final String message;
}
