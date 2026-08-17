import 'package:vet45_shared_application/application.dart';

import 'resolve_reconciliation_case_result.dart';

@RequiresTenant()
final class ResolveReconciliationCaseCommand extends CommandBase<ReconciliationCaseDto>
    implements ICommand<ReconciliationCaseDto>, ITenantScopedCommand {
  ResolveReconciliationCaseCommand({
    String? id,
    required this.tenantId,
    required this.caseId,
    required this.outcome,
  }) : super(id);

  @override
  final String tenantId;
  final String caseId;
  final String outcome;
}
