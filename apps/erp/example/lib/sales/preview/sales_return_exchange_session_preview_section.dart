import 'package:flutter/material.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart';

import 'preview_section.dart';

/// Preview states for [SalesReturnExchangeSessionBody] (SG-11).
class SalesReturnExchangeSessionPreviewSection extends StatelessWidget {
  const SalesReturnExchangeSessionPreviewSection({super.key});

  static void _noopQty(String id, int quantityMicros) {}
  static void _noopCode(String id, String code) {}

  @override
  Widget build(BuildContext context) {
    return PreviewSection(
      title: 'SG-11 Return/exchange session body',
      description:
          'loading / blocked / catalog-empty / filled / error — không demo '
          'settlement totals.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PreviewStateRow(
            label: 'Loading',
            child: SizedBox(
              height: 120,
              child: SalesReturnExchangeSessionBody(
                state: const SalesReturnExchangeSessionState(
                  orderId: 'order-1',
                  status: SalesReturnExchangeSessionStatus.loading,
                ),
                onReturnQuantityChanged: _noopQty,
                onReturnReasonChanged: _noopCode,
                onReturnConditionChanged: _noopCode,
                onExchangeQuantityChanged: _noopQty,
              ),
            ),
          ),
          PreviewStateRow(
            label: 'Blocked',
            child: SizedBox(
              height: 160,
              child: SalesReturnExchangeSessionBody(
                state: const SalesReturnExchangeSessionState(
                  orderId: 'order-1',
                  orderNumber: 'SO-001',
                  status: SalesReturnExchangeSessionStatus.blocked,
                  blockers: [
                    SalesBlockerDto(
                      code: 'ORDER_LOCKED',
                      message: 'Đơn hàng đang bị khóa.',
                    ),
                  ],
                ),
                onRetry: () {},
                onReturnQuantityChanged: _noopQty,
                onReturnReasonChanged: _noopCode,
                onReturnConditionChanged: _noopCode,
                onExchangeQuantityChanged: _noopQty,
              ),
            ),
          ),
          PreviewStateRow(
            label: 'Catalog empty',
            child: SizedBox(
              height: 160,
              child: SalesReturnExchangeSessionBody(
                state: const SalesReturnExchangeSessionState(
                  orderId: 'order-1',
                  orderNumber: 'SO-001',
                  status: SalesReturnExchangeSessionStatus.catalogEmpty,
                ),
                onRetry: () {},
                onReturnQuantityChanged: _noopQty,
                onReturnReasonChanged: _noopCode,
                onReturnConditionChanged: _noopCode,
                onExchangeQuantityChanged: _noopQty,
              ),
            ),
          ),
          PreviewStateRow(
            label: 'Filled (ready)',
            child: SizedBox(
              height: 420,
              child: SalesReturnExchangeSessionBody(
                state: _filledState(),
                onReturnQuantityChanged: _noopQty,
                onReturnReasonChanged: _noopCode,
                onReturnConditionChanged: _noopCode,
                onExchangeQuantityChanged: _noopQty,
                onAddExchangePressed: () {},
              ),
            ),
          ),
          PreviewStateRow(
            label: 'Error (retryable)',
            child: SizedBox(
              height: 420,
              child: SalesReturnExchangeSessionBody(
                state: _filledState().copyWith(
                  status: SalesReturnExchangeSessionStatus.retryableFailure,
                  screenError: 'DEPENDENCY_UNAVAILABLE — thử lại sau.',
                ),
                onRetry: () {},
                onReturnQuantityChanged: _noopQty,
                onReturnReasonChanged: _noopCode,
                onReturnConditionChanged: _noopCode,
                onExchangeQuantityChanged: _noopQty,
                onAddExchangePressed: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }

  static SalesReturnExchangeSessionState _filledState() {
    return SalesReturnExchangeSessionState(
      orderId: 'order-1',
      orderNumber: 'SO-2026-00125',
      customerDisplayName: 'Khách A',
      sourceOrderVersion: 7,
      status: SalesReturnExchangeSessionStatus.ready,
      returnableLines: const [
        ReturnableOrderLineDto(
          salesOrderLineId: 'line-1',
          product: ProductSnapshotDto(
            productId: 'product-1',
            sku: 'SKU-1',
            displayName: 'Sản phẩm 1',
          ),
          unit: ProductUnitSnapshotDto(
            productUnitId: 'unit-1',
            unitCode: 'BOX',
            unitName: 'Hộp',
          ),
          soldQuantity: QuantityDto(quantityMicros: QuantityDto.scale * 2),
          returnableQuantity: QuantityDto(
            quantityMicros: QuantityDto.scale * 2,
          ),
          originalUnitPrice: MoneyDto(amountMinor: 50000, currencyCode: 'VND'),
        ),
      ],
      reasons: const [
        ReturnExchangePolicyOptionDto(
          code: 'DAMAGED',
          displayName: 'Hỏng',
          sortOrder: 100,
        ),
        ReturnExchangePolicyOptionDto(
          code: 'WRONG_ITEM',
          displayName: 'Sai hàng',
          sortOrder: 200,
        ),
      ],
      conditions: const [
        ReturnExchangePolicyOptionDto(
          code: 'OPENED',
          displayName: 'Đã mở',
          sortOrder: 100,
        ),
        ReturnExchangePolicyOptionDto(
          code: 'SEALED',
          displayName: 'Nguyên seal',
          sortOrder: 200,
        ),
      ],
      returnEdits: const [
        SalesReturnLineEdit(
          salesOrderLineId: 'line-1',
          quantityMicros: QuantityDto.scale,
          reasonCode: 'DAMAGED',
          conditionCode: 'OPENED',
        ),
      ],
      exchangeEdits: const [
        SalesExchangeLineEdit(
          productId: 'product-x',
          productUnitId: 'unit-x',
          productName: 'Hàng đổi mẫu',
          sku: 'SKU-X',
          unitLabel: 'Chai',
          unitPrice: MoneyDto(amountMinor: 75000, currencyCode: 'VND'),
          quantityMicros: QuantityDto.scale,
        ),
      ],
    );
  }
}
