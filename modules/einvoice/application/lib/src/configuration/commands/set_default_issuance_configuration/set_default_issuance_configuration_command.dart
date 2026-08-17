import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../queries/get_issuance_profile/issuance_profile_dto.dart';

@RequiresPermission(EInvoicePermissions.manageConfiguration)
@RequiresTenant()
final class SetDefaultIssuanceConfigurationCommand extends CommandBase<IssuanceProfileDto>
    implements ICommand<IssuanceProfileDto>, ITenantScopedCommand {
  SetDefaultIssuanceConfigurationCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.templateId,
    required this.signingConfigId,
    this.expectedProfileVersion,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String templateId;
  final String signingConfigId;
  final int? expectedProfileVersion;
}
