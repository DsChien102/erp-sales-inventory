import 'package:vet45_einvoice_domain/domain.dart';

/// Snapshot needed to resolve + (maybe) lock buyer invoice completion.
/// Maps the buyer_invoice_completions row (§4.4.3): completionSource is a
/// projection of resolved_values into the same shape as base. EffectiveBuyerInvoiceData
/// is Runtime and is NEVER stored — the handler recomputes it.
final class BuyerCompletionContext {
  const BuyerCompletionContext({
    required this.base,
    this.completionSource,
    required this.status,
    required this.salesOrderVersion, // varchar(100) in SQL → String here (§4.4.3)
    required this.buyerPartnerId,
    this.eligibleFields = const [],
  });

  final BuyerInvoiceSourceFields base;
  final BuyerInvoiceSourceFields? completionSource; // from resolved_values
  final BuyerCompletionStatus status;
  final String salesOrderVersion;
  final String buyerPartnerId;
  final List<String> eligibleFields; // e.g. ['taxCode','email','address']
}

/// Read/persist port for buyer invoice completion (S2a fake seam).
abstract interface class IBuyerInvoiceDataGateway {
  Future<BuyerCompletionContext> loadCompletionContext({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required int expectedOrderVersion, // command boundary stays int
  });

  /// Persist the completion fields per §4.4.3 — NOT the runtime effective blob.
  Future<void> saveLockedCompletion({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required String salesOrderVersion,
    required List<String> eligibleFields,
    required Map<String, String?> resolvedValues,
  });
}
