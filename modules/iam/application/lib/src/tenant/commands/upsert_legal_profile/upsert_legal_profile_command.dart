import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'upsert_legal_profile_result_dto.dart';

@RequiresPermission(IamPermissions.tenantLegalProfileUpdate)
@RequiresTenant()
final class UpsertLegalProfileCommand
    extends CommandBase<UpsertLegalProfileResultDto>
    implements ICommand<UpsertLegalProfileResultDto>, ITenantScopedCommand {
  UpsertLegalProfileCommand({
    String? id,
    required this.tenantId,
    required this.legalEntityType,
    required this.legalName,
    required this.taxCode,
    required this.registeredAddressText,
    required this.provinceCode,
    required this.communeCode,
    required this.expectedVersion,
    required this.allowDuplicateTaxCode,
  }) : super(id);

  @override
  final String tenantId;
  final String legalEntityType;
  final String legalName;
  final String taxCode;
  final String? registeredAddressText;
  final String? provinceCode;
  final String? communeCode;
  final int expectedVersion;
  final bool allowDuplicateTaxCode;
}
