import '../../ports/i_buyer_invoice_data_gateway.dart';

final class FakeBuyerInvoiceDataGateway implements IBuyerInvoiceDataGateway {
  FakeBuyerInvoiceDataGateway({required this.context});

  final BuyerCompletionContext context;
  Map<String, String?>? savedResolvedValues;
  List<String>? savedEligibleFields;

  @override
  Future<BuyerCompletionContext> loadCompletionContext({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required int expectedOrderVersion,
  }) async => context;

  @override
  Future<void> saveLockedCompletion({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required String salesOrderVersion,
    required List<String> eligibleFields,
    required Map<String, String?> resolvedValues,
  }) async {
    savedEligibleFields = eligibleFields;
    savedResolvedValues = resolvedValues;
  }
}
