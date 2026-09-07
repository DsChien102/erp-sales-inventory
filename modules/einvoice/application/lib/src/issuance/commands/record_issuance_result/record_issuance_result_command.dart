import 'package:vet45_shared_application/application.dart';

import '../../shared/issuance_result_evidence_dto.dart';
import 'record_issuance_result_result.dart';

/// Internal — worker/inbox finalize issuance attempt with typed evidence.
@RequiresTenant()
final class RecordIssuanceResultCommand extends CommandBase<RecordIssuanceResultDto>
    implements ICommand<RecordIssuanceResultDto>, ITenantScopedCommand {
  RecordIssuanceResultCommand({
    String? id,
    required this.tenantId,
    required this.attemptId,
    required this.correlationId,
    required this.evidence,
  }) : super(id);

  @override
  final String tenantId;
  final String attemptId;
  final String correlationId;
  final IssuanceResultEvidenceDto evidence;
}
