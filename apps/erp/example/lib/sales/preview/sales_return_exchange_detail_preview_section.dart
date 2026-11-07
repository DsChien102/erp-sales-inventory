import 'package:flutter/material.dart';
import 'package:erp/features/sales/data/models.dart';
import 'package:erp/features/sales/presentation.dart'
    hide SalesOrderLifecycleStatus;

import 'preview_section.dart';

/// Preview states for SG-13 result/detail bodies.
class SalesReturnExchangeDetailPreviewSection extends StatelessWidget {
  const SalesReturnExchangeDetailPreviewSection({super.key});

  static final _loadedState = SalesReturnExchangeDetailState(
    orderId: 'order-1',
    returnExchangeId: 'return-1',
    status: SalesReturnExchangeDetailStatus.loaded,
    detail: SalesReturnExchangeDetailVm(
      returnExchangeId: 'return-1',
      salesOrderId: 'order-1',
      referenceNumber: 'RE-1',
      status: ReturnExchangeStatus.confirmed,
      version: 2,
      lines: const [
        ReturnExchangeDetailLineDto(
          lineId: 'line-1',
          kind: ReturnExchangeLineKind.returnLine,
          product: ProductSnapshotDto(
            productId: 'p1',
            sku: 'SKU-1',
            displayName: 'Sản phẩm trả',
          ),
          unit: ProductUnitSnapshotDto(
            productUnitId: 'u1',
            unitCode: 'BOX',
            unitName: 'Hộp',
          ),
          quantity: QuantityDto(quantityMicros: QuantityDto.scale),
          unitPrice: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
          lineTotal: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
          originalSalesOrderLineId: 'sol-1',
          reasonCode: 'DAMAGED',
          conditionCode: 'OPENED',
        ),
      ],
      valuation: const ReturnExchangeValuationDto(
        returnValue: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
        exchangeValue: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        settlementDifference: MoneyDto(
          amountMinor: -100000,
          currencyCode: 'VND',
        ),
        settlementPlan: ReturnExchangeSettlementPlanDto(
          currencyCode: 'VND',
          netDifferenceMinor: -100000,
          collectAmountMinor: 0,
          refundAmountMinor: 100000,
          receivableCreateAmountMinor: 0,
          receivableReverseAmountMinor: 0,
          processedCollectMinor: 0,
          processedRefundMinor: 0,
          pendingReceivableCreateMinor: 0,
          pendingReceivableReverseMinor: 0,
          remainderCollectMinor: 0,
          remainderRefundMinor: 100000,
          sourceOrderVersion: 7,
          sourceSettlementVersion: 3,
        ),
        sourceOrderVersion: 7,
      ),
      settlementPlan: const ReturnExchangeSettlementPlanDto(
        currencyCode: 'VND',
        netDifferenceMinor: -100000,
        collectAmountMinor: 0,
        refundAmountMinor: 100000,
        receivableCreateAmountMinor: 0,
        receivableReverseAmountMinor: 0,
        processedCollectMinor: 0,
        processedRefundMinor: 0,
        pendingReceivableCreateMinor: 0,
        pendingReceivableReverseMinor: 0,
        remainderCollectMinor: 0,
        remainderRefundMinor: 100000,
        sourceOrderVersion: 7,
        sourceSettlementVersion: 3,
      ),
      completionReady: false,
    ),
    orderDetail: SalesOrderDetailDto(
      order: const SalesOrderDto(
        salesOrderId: 'order-1',
        orderNumber: 'SO-1',
        version: 7,
        lifecycleStatus: SalesOrderLifecycleStatus.completed,
        lockStatus: SalesOrderLockStatus.unlocked,
        total: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
      ),
      committedAt: DateTime.utc(2026, 8, 12),
      store: const StoreSnapshotDto(
        storeId: 'store-1',
        storeCode: 'HCM-01',
        displayName: 'Chi nhánh 1',
      ),
      seller: const ActorSnapshotDto(actorId: 'actor-1', displayName: 'Minh'),
      customer: const CustomerSnapshotDto(
        customerId: 'customer-1',
        displayName: 'Khách A',
      ),
      lines: const [],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return PreviewSection(
      title: 'SG-13 Return/exchange result & detail bodies',
      description:
          'loading / loaded / failure — authoritative detail only, '
          'không demo customer/timestamp.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PreviewStateRow(
            label: 'Result loading',
            child: SizedBox(
              height: 160,
              child: SalesReturnExchangeResultBody(
                state: const SalesReturnExchangeDetailState(
                  orderId: 'order-1',
                  returnExchangeId: 'return-1',
                  status: SalesReturnExchangeDetailStatus.loading,
                ),
                onGoHome: () {},
                onViewOrderDetail: () {},
              ),
            ),
          ),
          PreviewStateRow(
            label: 'Result loaded',
            child: SizedBox(
              height: 320,
              child: SalesReturnExchangeResultBody(
                state: _loadedState,
                onGoHome: () {},
                onViewOrderDetail: () {},
                onViewReturnSlipDetail: () {},
              ),
            ),
          ),
          PreviewStateRow(
            label: 'Result failure',
            child: SizedBox(
              height: 200,
              child: SalesReturnExchangeResultBody(
                state: const SalesReturnExchangeDetailState(
                  orderId: 'order-1',
                  returnExchangeId: 'return-1',
                  status: SalesReturnExchangeDetailStatus.failure,
                  screenError: 'Không tải được kết quả.',
                ),
                onGoHome: () {},
                onViewOrderDetail: () {},
                onRetry: () {},
              ),
            ),
          ),
          PreviewStateRow(
            label: 'Detail loaded',
            child: SizedBox(
              height: 320,
              child: SalesReturnExchangeDetailBody(
                state: _loadedState,
                onOpenActions: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
