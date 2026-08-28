import 'package:vet45_shared_application/application.dart';

import 'record_issuance_result_result.dart';

/// Internal — worker/inbox finalize issuance attempt.
/// dormant until S3b — S2b routes publish outcomes via [IIssuanceResultGateway]
/// directly in [PublishInvoiceCommandHandler]; do not dispatch from publish path.
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
