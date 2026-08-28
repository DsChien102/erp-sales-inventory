import 'package:vet45_einvoice_domain/domain.dart';

/// Read port: gathers the authoritative snapshot for per-order issuance readiness.
///
/// NOTE (S2a fake seam): the real implementation reads Theme 05 SalesOrder /
/// BuyerInvoiceSnapshot which do not exist in the DB yet — tests use a fake.
abstract interface class IIssuanceReadinessReadGateway {
  Future<IssuanceReadinessInput> load({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  });
}
