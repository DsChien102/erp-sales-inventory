import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_issuance_result_gateway.dart';
import '../../shared/issuance_result_evidence_dto.dart';
import 'record_issuance_result_command.dart';
import 'record_issuance_result_result.dart';

@CommandHandlerFor(RecordIssuanceResultCommand)
final class RecordIssuanceResultCommandHandler
    implements ICommandHandler<RecordIssuanceResultCommand, RecordIssuanceResultDto> {
  RecordIssuanceResultCommandHandler({
    required IIssuanceResultGateway gateway,
  }) : _gateway = gateway;

  final IIssuanceResultGateway _gateway;

  @override
  Future<RecordIssuanceResultDto> handle(
    RecordIssuanceResultCommand command,
  ) {
    return switch (command.evidence) {
      IssuanceSuccessEvidenceDto() => _gateway.recordSuccess(
        tenantId: command.tenantId,
        attemptId: command.attemptId,
        evidence: command.evidence,
      ),
      IssuanceDefiniteFailureEvidenceDto() => _gateway.recordDefiniteFailure(
        tenantId: command.tenantId,
        attemptId: command.attemptId,
        evidence: command.evidence,
      ),
      IssuanceUndeterminedEvidenceDto() => _gateway.recordUndetermined(
        tenantId: command.tenantId,
        attemptId: command.attemptId,
        evidence: command.evidence,
      ),
      IssuanceRetryableProviderRejectionEvidenceDto() => throw ValidationException(
        'retryable provider rejection must use publish retry gateway path',
      ),
    };
  }
}
