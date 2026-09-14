import 'package:vet45_sales_application/application.dart';

import '../models/return_exchange_order/sales_return_exchange_detail_vm.dart';
import '../models/return_exchange_order/sales_return_exchange_session_vm.dart';
import '../models/return_exchange_order/sales_return_exchange_settlement_vm.dart';

abstract final class SalesReturnExchangeMapper {
  static SalesReturnExchangeSessionVm toSessionVm({
    required SalesOrderDetailDto order,
    required ReturnableOrderLinesDto returnable,
    required ReturnExchangeFormPolicyDto policy,
    String? returnExchangeId,
    int? draftVersion,
  }) {
    final customer = order.customer;
    if (customer == null) {
      throw const SalesContractException(
        'DEPENDENCY_UNAVAILABLE',
        message: 'Sales order customer snapshot is required for return/exchange session.',
      );
    }
    return SalesReturnExchangeSessionVm(
      salesOrderId: order.order.salesOrderId,
      orderNumber: order.order.orderNumber,
      customerDisplayName: customer.displayName,
      sourceOrderVersion: returnable.sourceVersion,
      returnableLines: returnable.lines,
      reasons: policy.reasons,
      conditions: policy.conditions,
      returnExchangeId: returnExchangeId,
      draftVersion: draftVersion,
    );
  }

  static SalesReturnExchangeSettlementVm toSettlementVm({
    required String returnExchangeId,
    required ReturnExchangeValuationDto valuation,
  }) {
    final plan = valuation.settlementPlan;
    return SalesReturnExchangeSettlementVm(
      returnExchangeId: returnExchangeId,
      currencyCode: plan.currencyCode,
      netDifferenceMinor: plan.netDifferenceMinor,
      storeRefundMinor: plan.refundAmountMinor,
      customerCollectMinor: plan.collectAmountMinor,
      receivableCreateMinor: plan.receivableCreateAmountMinor,
      receivableReverseMinor: plan.receivableReverseAmountMinor,
      sourceOrderVersion: plan.sourceOrderVersion,
      sourceSettlementVersion: plan.sourceSettlementVersion,
      pricingSourceVersion: plan.pricingSourceVersion,
    );
  }

  static SalesReturnExchangeDetailVm toDetailVm(ReturnExchangeDetailDto detail) {
    return SalesReturnExchangeDetailVm(
      returnExchangeId: detail.result.returnExchangeId,
      salesOrderId: detail.result.salesOrderId,
      referenceNumber: detail.referenceNumber,
      status: detail.result.status,
      version: detail.result.version,
      entrySource: detail.entrySource,
      createdAt: detail.createdAt,
      confirmedByActorId: detail.confirmedByActorId,
      confirmedAt: detail.confirmedAt,
      completedAt: detail.completedAt,
      lines: detail.lines,
      valuation: detail.valuation,
      settlementPlan: detail.settlementPlan,
      completionReady: detail.completionReady,
    );
  }
}
