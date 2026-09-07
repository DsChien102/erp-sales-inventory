import 'package:vet45_shared_application/application.dart';

import '../start_auto_issuance/start_auto_issuance_result.dart';

/// Internal — re-evaluate an existing open auto-issuance process on partner update.
@RequiresTenant()
final class ReevaluateAutoIssuanceCommand extends CommandBase<AutoIssuanceResultDto>
    implements ICommand<AutoIssuanceResultDto>, ITenantScopedCommand {
  ReevaluateAutoIssuanceCommand({
    String? id,
    required this.tenantId,
    required this.processId,
    required this.sourceEventId,
  }) : super(id);

  @override
  final String tenantId;
  final String processId;
  final String sourceEventId;
}
