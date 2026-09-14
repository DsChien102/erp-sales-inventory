import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/checkout_line_input.dart';
import '../../../shared/checkout_result_dto.dart';
import '../../../shared/payment_intent_input.dart';
import '../../../shared/sales_commercial_snapshot_input.dart';
import '../../../shared/sales_contract_base.dart';

@RequiresPermission(SalesPermissions.finalizeCheckout)
@RequiresTenant()
final class FinalizeSalesOrderCommand extends SalesMutationContract<CheckoutResultDto> {
  FinalizeSalesOrderCommand({
    super.id,
    super.tenantId,
    super.actorId,
    required this.storeId,
    this.sourceDraftId,
    this.customerId,
    required this.currencyCode,
    this.orderNote,
    this.paymentDueDate,
    required List<CheckoutLineInput> lines,
    required List<PaymentIntentInput> paymentIntents,
    required this.commercialSnapshot,
    required super.idempotencyKey,
    required super.payloadHash,
    required super.correlationId,
    super.causationId,
    super.expectedSourceVersion,
  }) : lines = List.unmodifiable(lines),
       paymentIntents = List.unmodifiable(paymentIntents);

  final String storeId;
  final String? sourceDraftId;
  final String? customerId;
  final String currencyCode;
  final String? orderNote;
  final DateTime? paymentDueDate;
  final List<CheckoutLineInput> lines;
  final List<PaymentIntentInput> paymentIntents;
  final SalesCommercialSnapshotInput commercialSnapshot;

  FinalizeSalesOrderCommand withExecutionContext({
    required String tenantId,
    required String actorId,
  }) => FinalizeSalesOrderCommand(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    storeId: storeId,
    sourceDraftId: sourceDraftId,
    customerId: customerId,
    currencyCode: currencyCode,
    orderNote: orderNote,
    paymentDueDate: paymentDueDate,
    lines: lines,
    paymentIntents: paymentIntents,
    commercialSnapshot: commercialSnapshot,
    idempotencyKey: idempotencyKey,
    payloadHash: payloadHash!,
    correlationId: correlationId!,
    causationId: causationId,
    expectedSourceVersion: expectedSourceVersion,
  );
}
