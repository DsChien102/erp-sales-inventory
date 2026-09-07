import 'package:uuid/uuid.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/issuance_result_evidence_dto.dart';
import 'record_issuance_result_command.dart';

final class RecordIssuanceResultCommandValidator
    implements ICommandValidator<RecordIssuanceResultCommand> {
  @override
  Future<void> validate(RecordIssuanceResultCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('tenantId is required');
    }
    if (command.attemptId.trim().isEmpty) {
      throw ValidationException('attemptId is required');
    }
    if (command.correlationId.trim().isEmpty) {
      throw ValidationException('correlationId is required');
    }
    if (command.evidence.idempotencyKey.trim().isEmpty) {
      throw ValidationException('idempotencyKey is required');
    }
    if (!Uuid.isValidUUID(fromString: command.evidence.idempotencyKey)) {
      throw ValidationException('idempotencyKey must be a canonical UUID');
    }
    if (command.evidence.payloadHash.trim().isEmpty) {
      throw ValidationException('payloadHash is required');
    }

    switch (command.evidence) {
      case IssuanceSuccessEvidenceDto success:
        if (success.invoiceNumber.trim().isEmpty) {
          throw ValidationException('invoiceNumber is required for success evidence');
        }
        if (success.invoiceSeries.trim().isEmpty) {
          throw ValidationException('invoiceSeries is required for success evidence');
        }
      case IssuanceDefiniteFailureEvidenceDto failure:
        if (failure.providerCode.trim().isEmpty) {
          throw ValidationException('providerCode is required for failure evidence');
        }
        if (failure.providerMessage.trim().isEmpty) {
          throw ValidationException('providerMessage is required for failure evidence');
        }
      case IssuanceUndeterminedEvidenceDto undetermined:
        if (undetermined.reasonCode.trim().isEmpty) {
          throw ValidationException('reasonCode is required for undetermined evidence');
        }
    }
  }
}
