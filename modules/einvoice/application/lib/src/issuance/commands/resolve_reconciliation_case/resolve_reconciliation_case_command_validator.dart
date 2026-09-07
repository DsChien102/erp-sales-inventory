import 'package:vet45_shared_application/application.dart';

import 'resolve_reconciliation_case_command.dart';

final class ResolveReconciliationCaseCommandValidator
    implements ICommandValidator<ResolveReconciliationCaseCommand> {
  @override
  Future<void> validate(ResolveReconciliationCaseCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('tenantId is required');
    }
    if (command.caseId.trim().isEmpty) {
      throw ValidationException('caseId is required');
    }
    if (command.outcome.trim().isEmpty) {
      throw ValidationException('outcome is required');
    }

    final outcome = command.outcome.trim().toUpperCase();
    if (!const {'SUCCESS', 'FAILURE', 'UNRESOLVED'}.contains(outcome)) {
      throw ValidationException('outcome is invalid');
    }

    final requiredEvidenceKeys = switch (outcome) {
      'SUCCESS' => const {
        'provider_reference',
        'invoice_number',
        'invoice_series',
        'issued_at',
      },
      'FAILURE' => const {'provider_code', 'provider_message'},
      _ => const <String>{},
    };
    for (final key in requiredEvidenceKeys) {
      final value = command.evidence?[key];
      if (value == null || value.toString().trim().isEmpty) {
        throw ValidationException('$key is required for $outcome');
      }
    }
  }
}
