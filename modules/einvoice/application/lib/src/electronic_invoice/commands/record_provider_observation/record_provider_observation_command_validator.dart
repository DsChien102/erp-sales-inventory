import 'package:vet45_shared_application/application.dart';

import 'record_provider_observation_command.dart';

abstract final class ProviderObservationDetailsPolicy {
  static const allowedKeys = <String>{
    'publishStatus',
    'eInvoiceStatus',
    'referenceType',
    'sendTaxStatus',
    'invoiceCode',
    'invNo',
    'invSeries',
    'publishedTime',
    'transactionId',
  };
}

final class RecordProviderObservationCommandValidator
    implements ICommandValidator<RecordProviderObservationCommand> {
  @override
  Future<void> validate(RecordProviderObservationCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('tenantId is required');
    }
    if (command.electronicInvoiceId.trim().isEmpty) {
      throw ValidationException('electronicInvoiceId is required');
    }
    if (command.providerStateCode.trim().isEmpty) {
      throw ValidationException('providerStateCode is required');
    }
    if (command.deduplicationKey.trim().isEmpty) {
      throw ValidationException('deduplicationKey is required');
    }
    if (command.providerInteractionReference.trim().isEmpty) {
      throw ValidationException('providerInteractionReference is required');
    }
    if (command.source.trim().isEmpty) {
      throw ValidationException('source is required');
    }

    for (final key in command.detailsSnapshot.keys) {
      if (!ProviderObservationDetailsPolicy.allowedKeys.contains(key)) {
        throw ValidationException('detailsSnapshot key not allowed: $key');
      }
    }
  }
}
