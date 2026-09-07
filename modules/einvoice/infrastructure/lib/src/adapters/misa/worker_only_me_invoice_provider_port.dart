import 'package:vet45_einvoice_application/application.dart';

/// Client-host guard that prevents ERP processes from making MISA HTTP calls.
final class WorkerOnlyMeInvoiceProviderPort implements IMeInvoiceProviderPort {
  Never _reject() {
    throw StateError('MISA provider HTTP operations are worker-only');
  }

  @override
  Future<MeInvoiceAuthOutcome> authenticateAndListTemplates({
    required String tenantId,
    required String connectionId,
  }) async => _reject();

  @override
  Future<MeInvoicePreviewOutcome> previewUnpublished({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
  }) async => _reject();

  @override
  void validateCanonical({required Map<String, Object?> canonicalInvoice}) {
    _reject();
  }

  @override
  Future<MeInvoicePublishOutcome> publish({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
    required String idempotencyKey,
  }) async => _reject();

  @override
  Future<MeInvoiceIssuanceStatusOutcome> getStatus({
    required String tenantId,
    required String idempotencyKey,
    required String payloadHash,
    String? providerReference,
  }) async => _reject();
}
