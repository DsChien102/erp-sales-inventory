import 'package:flutter/material.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart';

import 'preview_section.dart';

/// Preview states for [SalesReturnExchangeSettlementBody] (SG-12).
class SalesReturnExchangeSettlementPreviewSection extends StatelessWidget {
  const SalesReturnExchangeSettlementPreviewSection({super.key});

  static const _refundVm = SalesReturnExchangeSettlementVm(
    returnExchangeId: 'return-1',
    currencyCode: 'VND',
    netDifferenceMinor: -400000,
    storeRefundMinor: 400000,
    customerCollectMinor: 0,
    receivableCreateMinor: 0,
    receivableReverseMinor: 150000,
    sourceOrderVersion: 7,
    sourceSettlementVersion: 3,
  );

  static const _collectVm = SalesReturnExchangeSettlementVm(
    returnExchangeId: 'return-1',
    currencyCode: 'VND',
    netDifferenceMinor: 300000,
    storeRefundMinor: 0,
    customerCollectMinor: 300000,
    receivableCreateMinor: 200000,
    receivableReverseMinor: 0,
    sourceOrderVersion: 7,
    sourceSettlementVersion: 3,
  );

  static const _zeroVm = SalesReturnExchangeSettlementVm(
    returnExchangeId: 'return-1',
    currencyCode: 'VND',
    netDifferenceMinor: 0,
    storeRefundMinor: 0,
    customerCollectMinor: 0,
    receivableCreateMinor: 0,
    receivableReverseMinor: 0,
    sourceOrderVersion: 7,
    sourceSettlementVersion: 3,
  );

  @override
  Widget build(BuildContext context) {
    return PreviewSection(
      title: 'SG-12 Return/exchange settlement body',
      description:
          'loading / blocked / refund / collect / zero / error — read-only '
          'plan, không payment/debt/due-date.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PreviewStateRow(
            label: 'Loading',
            child: SizedBox(
              height: 120,
              child: SalesReturnExchangeSettlementBody(
                state: const SalesReturnExchangeSettlementState(
                  orderId: 'order-1',
                  returnExchangeId: 'return-1',
                  status: SalesReturnExchangeSettlementStatus.loading,
                ),
              ),
            ),
          ),
          PreviewStateRow(
            label: 'Blocked',
            child: SizedBox(
              height: 160,
              child: SalesReturnExchangeSettlementBody(
                state: const SalesReturnExchangeSettlementState(
                  orderId: 'order-1',
                  returnExchangeId: 'return-1',
                  status: SalesReturnExchangeSettlementStatus.blocked,
                  blockers: [
                    SalesBlockerDto(
                      code: 'WINDOW_EXPIRED',
                      message: 'Hết hạn đổi/trả.',
                    ),
                  ],
                ),
                onRetry: () {},
              ),
            ),
          ),
          PreviewStateRow(
            label: 'Refund plan',
            child: SizedBox(
              height: 280,
              child: SalesReturnExchangeSettlementBody(
                state: const SalesReturnExchangeSettlementState(
                  orderId: 'order-1',
                  returnExchangeId: 'return-1',
                  draftVersion: 2,
                  settlement: _refundVm,
                  status: SalesReturnExchangeSettlementStatus.ready,
                ),
              ),
            ),
          ),
          PreviewStateRow(
            label: 'Collect plan',
            child: SizedBox(
              height: 280,
              child: SalesReturnExchangeSettlementBody(
                state: const SalesReturnExchangeSettlementState(
                  orderId: 'order-1',
                  returnExchangeId: 'return-1',
                  draftVersion: 2,
                  settlement: _collectVm,
                  status: SalesReturnExchangeSettlementStatus.ready,
                ),
              ),
            ),
          ),
          PreviewStateRow(
            label: 'Zero plan',
            child: SizedBox(
              height: 240,
              child: SalesReturnExchangeSettlementBody(
                state: const SalesReturnExchangeSettlementState(
                  orderId: 'order-1',
                  returnExchangeId: 'return-1',
                  draftVersion: 2,
                  settlement: _zeroVm,
                  status: SalesReturnExchangeSettlementStatus.ready,
                ),
              ),
            ),
          ),
          PreviewStateRow(
            label: 'Error',
            child: SizedBox(
              height: 160,
              child: SalesReturnExchangeSettlementBody(
                state: const SalesReturnExchangeSettlementState(
                  orderId: 'order-1',
                  returnExchangeId: 'return-1',
                  status: SalesReturnExchangeSettlementStatus.failure,
                  screenError: 'Không tải được quyết toán.',
                ),
                onRetry: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
