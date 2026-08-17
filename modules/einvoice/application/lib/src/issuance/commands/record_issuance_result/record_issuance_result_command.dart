import 'package:vet45_shared_application/application.dart';

import 'record_issuance_result_result.dart';

/// Internal — worker/inbox finalize issuance attempt.
@RequiresTenant()
final class RecordIssuanceResultCommand extends CommandBase<RecordIssuanceResultDto>
    implements ICommand<RecordIssuanceResultDto>, ITenantScopedCommand {
  RecordIssuanceResultCommand({
    String? id,
    required this.tenantId,
    required this.attemptId,
    required this.providerResult,
    required this.correlationId,
  }) : super(id);

  @override
  final String tenantId;
  final String attemptId;
  final Map<String, Object?> providerResult;
  final String correlationId;
}
