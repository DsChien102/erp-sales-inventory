import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/checkout_line_input.dart';
import '../../../shared/checkout_precheck_dto.dart';
import '../../../shared/payment_intent_input.dart';
import '../../../shared/sales_contract_base.dart';

@RequiresPermission(SalesPermissions.finalizeCheckout)
@RequiresTenant()
final class PrecheckSalesOrderCheckoutQuery extends SalesReadContract<CheckoutPrecheckDto>
    implements IQuery<CheckoutPrecheckDto>, ITenantScopedCommand {
  PrecheckSalesOrderCheckoutQuery({
    super.id,
    super.tenantId,
    super.actorId,
    required this.storeId,
    this.customerId,
    required this.currencyCode,
    this.paymentDueDate,
    required List<CheckoutLineInput> lines,
    required List<PaymentIntentInput> paymentIntents,
    this.expectedSourceVersion,
  }) : lines = List.unmodifiable(lines),
       paymentIntents = List.unmodifiable(paymentIntents);

  final String storeId;
  final String? customerId;
  final String currencyCode;
  final DateTime? paymentDueDate;
  final List<CheckoutLineInput> lines;
  final List<PaymentIntentInput> paymentIntents;
  final int? expectedSourceVersion;

  PrecheckSalesOrderCheckoutQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => PrecheckSalesOrderCheckoutQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    storeId: storeId,
    customerId: customerId,
    currencyCode: currencyCode,
    paymentDueDate: paymentDueDate,
    lines: lines,
    paymentIntents: paymentIntents,
    expectedSourceVersion: expectedSourceVersion,
  );
}
