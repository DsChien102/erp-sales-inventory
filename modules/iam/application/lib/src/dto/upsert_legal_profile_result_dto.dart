import 'duplicate_tax_code_warning_dto.dart';
import 'tenant_legal_profile_dto.dart';

/// Result of upsert Legal Profile — saved profile or duplicate warning.
final class UpsertLegalProfileResultDto {
  const UpsertLegalProfileResultDto.saved({
    required this.profile,
    required this.tenantVersion,
  }) : warning = null;

  const UpsertLegalProfileResultDto.warning({
    required this.warning,
    required this.tenantVersion,
  }) : profile = null;

  final TenantLegalProfileDto? profile;
  final DuplicateTaxCodeWarningDto? warning;
  final int tenantVersion;

  bool get isSaved => profile != null;
  bool get isWarning => warning != null;
}
