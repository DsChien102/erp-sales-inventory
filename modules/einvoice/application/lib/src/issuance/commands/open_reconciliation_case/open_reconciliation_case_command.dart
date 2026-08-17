import 'package:vet45_shared_application/application.dart';

import 'open_reconciliation_case_result.dart';

@RequiresTenant()
final class OpenReconciliationCaseCommand extends CommandBase<ReconciliationCaseDto>
    implements ICommand<ReconciliationCaseDto>, ITenantScopedCommand {
  OpenReconciliationCaseCommand({
    String? id,
    required this.tenantId,
    required this.attemptId,
    required this.reason,
  }) : super(id);

  @override
  final String tenantId;
  final String attemptId;
  final String reason;
}
