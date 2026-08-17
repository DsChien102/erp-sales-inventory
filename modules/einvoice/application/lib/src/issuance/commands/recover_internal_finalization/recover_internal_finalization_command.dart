import 'package:vet45_shared_application/application.dart';

import 'recover_internal_finalization_result.dart';

@RequiresTenant()
final class RecoverInternalFinalizationCommand extends CommandBase<RecoverInternalFinalizationResultDto>
    implements ICommand<RecoverInternalFinalizationResultDto>, ITenantScopedCommand {
  RecoverInternalFinalizationCommand({
    String? id,
    required this.tenantId,
    required this.attemptId,
  }) : super(id);

  @override
  final String tenantId;
  final String attemptId;
}
