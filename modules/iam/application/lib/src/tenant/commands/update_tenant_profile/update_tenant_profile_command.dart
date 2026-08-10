import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/tenant_dto.dart';

@RequiresPermission(IamPermissions.tenantProfileUpdate)
@RequiresTenant()
final class UpdateTenantProfileCommand extends CommandBase<TenantDto>
    implements ICommand<TenantDto>, ITenantScopedCommand {
  UpdateTenantProfileCommand({
    String? id,
    required this.tenantId,
    required this.displayName,
    required this.contactEmail,
    required this.contactPhone,
    required this.contactAddressText,
    required this.provinceCode,
    required this.communeCode,
    required this.expectedVersion,
  }) : super(id);

  @override
  final String tenantId;
  final String displayName;
  final String? contactEmail;
  final String? contactPhone;
  final String? contactAddressText;
  final String? provinceCode;
  final String? communeCode;
  final int expectedVersion;
}
