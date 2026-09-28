import '../../shared/services/configuration_readiness_evaluator.dart' show ReadinessWarning;
import '../buyer_completion/effective_buyer_invoice_data.dart';
import '../enums/buyer_completion_status.dart';

/// Authoritative snapshot fed to IssuanceReadinessEvaluator (gathered by the read gateway).
final class IssuanceReadinessInput {
  const IssuanceReadinessInput({
    required this.orderCompleted,
    required this.hasElectronicInvoice,
    required this.hasActiveOperation,
    required this.configReady,
    required this.providerConnected,
    required this.providerSupportsPreview,
    required this.buyer,
    required this.buyerCompletionState,
    this.commercialDataMappable = true,
    this.configWarnings = const [],
    this.sourceBlockers = const [],
  });

  final bool orderCompleted;
  final bool hasElectronicInvoice;
  final bool hasActiveOperation;
  final bool configReady;
  final bool providerConnected;
  final bool providerSupportsPreview;
  final EffectiveBuyerInvoiceData buyer;
  final BuyerCompletionStatus buyerCompletionState;

  /// EP-02/US-01 FR-06 / EC-04: whether the SalesOrder commercial data can be
  /// mapped to a CanonicalInvoiceModel. When false, readiness is blocked and no
  /// preview may be requested. Defaults to true (permissive) until Theme 05
  /// commercial data is available to evaluate — see gateway TODO(Theme05).
  final bool commercialDataMappable;

  final List<ReadinessWarning> configWarnings;

  /// Mã chặn do Theme 05 xác lập trên nguồn (vd `ORDER_FULLY_RETURNED`).
  final List<String> sourceBlockers;
}
