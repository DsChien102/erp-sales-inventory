import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/sales/data/models.dart';

import 'package:erp/features/sales/logic/sales_transaction_result_state.dart';
import 'package:erp/features/sales/presentation/widgets/sales_result_header_card.dart';

void main() {
  Widget host(SalesTransactionResultState state) => MaterialApp(
    home: Scaffold(
      body: SalesResultHeaderCard(
        state: state,
        onViewOrderDetail: () {},
      ),
    ),
  );

  final committedAt = DateTime(2026, 9, 8, 1, 47);

  SalesOrderResultDto buildOrderResult({DateTime? soldAt}) => SalesOrderResultDto(
    order: const SalesOrderDto(
      salesOrderId: 'order-1',
      orderNumber: 'DH202609080002',
      version: 1,
      lifecycleStatus: SalesOrderLifecycleStatus.completed,
      lockStatus: SalesOrderLockStatus.unlocked,
      total: MoneyDto(amountMinor: 4160, currencyCode: 'VND'),
    ),
    committedAt: soldAt ?? committedAt,
    store: const StoreSnapshotDto(
      storeId: 'store-1',
      storeCode: 'S1',
      displayName: 'Store 1',
    ),
    seller: const ActorSnapshotDto(actorId: 'seller-1', displayName: 'Seller 1'),
  );

  testWidgets('displays Tiền mặt when only cash was paid', (tester) async {
    final state = SalesTransactionResultState(
      order: buildOrderResult(),
      payment: const SalesOrderPaymentSummaryDto(
        status: SalesSettlementStatus.paid,
        orderTotal: MoneyDto(amountMinor: 4160, currencyCode: 'VND'),
        paidTotal: MoneyDto(amountMinor: 4160, currencyCode: 'VND'),
        outstandingTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        originalOrder: SalesOrderPaymentOriginalBreakdownDto(
          orderTotal: MoneyDto(amountMinor: 4160, currencyCode: 'VND'),
          paidCash: MoneyDto(amountMinor: 4160, currencyCode: 'VND'),
          paidBank: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
          outstanding: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        ),
      ),
    );

    await tester.pumpWidget(host(state));

    expect(find.text('08/09/2026 · 01:47 · Tiền mặt'), findsOneWidget);
  });

  testWidgets('displays Chuyển khoản when only bank transfer was paid', (tester) async {
    final state = SalesTransactionResultState(
      order: buildOrderResult(),
      payment: const SalesOrderPaymentSummaryDto(
        status: SalesSettlementStatus.paid,
        orderTotal: MoneyDto(amountMinor: 4160, currencyCode: 'VND'),
        paidTotal: MoneyDto(amountMinor: 4160, currencyCode: 'VND'),
        outstandingTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        originalOrder: SalesOrderPaymentOriginalBreakdownDto(
          orderTotal: MoneyDto(amountMinor: 4160, currencyCode: 'VND'),
          paidCash: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
          paidBank: MoneyDto(amountMinor: 4160, currencyCode: 'VND'),
          outstanding: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        ),
      ),
    );

    await tester.pumpWidget(host(state));

    expect(find.text('08/09/2026 · 01:47 · Chuyển khoản'), findsOneWidget);
  });

  testWidgets('displays Tiền mặt + chuyển khoản when both methods were used', (tester) async {
    final state = SalesTransactionResultState(
      order: buildOrderResult(),
      payment: const SalesOrderPaymentSummaryDto(
        status: SalesSettlementStatus.paid,
        orderTotal: MoneyDto(amountMinor: 4160, currencyCode: 'VND'),
        paidTotal: MoneyDto(amountMinor: 4160, currencyCode: 'VND'),
        outstandingTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        originalOrder: SalesOrderPaymentOriginalBreakdownDto(
          orderTotal: MoneyDto(amountMinor: 4160, currencyCode: 'VND'),
          paidCash: MoneyDto(amountMinor: 2000, currencyCode: 'VND'),
          paidBank: MoneyDto(amountMinor: 2160, currencyCode: 'VND'),
          outstanding: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        ),
      ),
    );

    await tester.pumpWidget(host(state));

    expect(find.text('08/09/2026 · 01:47 · Tiền mặt + chuyển khoản'), findsOneWidget);
  });

  testWidgets('displays Chưa thanh toán when originalOrder has zero cash and zero bank', (
    tester,
  ) async {
    final state = SalesTransactionResultState(
      order: buildOrderResult(),
      payment: const SalesOrderPaymentSummaryDto(
        status: SalesSettlementStatus.unpaid,
        orderTotal: MoneyDto(amountMinor: 4160, currencyCode: 'VND'),
        paidTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        outstandingTotal: MoneyDto(amountMinor: 4160, currencyCode: 'VND'),
        originalOrder: SalesOrderPaymentOriginalBreakdownDto(
          orderTotal: MoneyDto(amountMinor: 4160, currencyCode: 'VND'),
          paidCash: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
          paidBank: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
          outstanding: MoneyDto(amountMinor: 4160, currencyCode: 'VND'),
        ),
      ),
    );

    await tester.pumpWidget(host(state));

    expect(find.text('08/09/2026 · 01:47 · Chưa thanh toán'), findsOneWidget);
  });

  testWidgets('displays Chưa thanh toán when originalOrder is null but paidTotal is zero', (
    tester,
  ) async {
    final state = SalesTransactionResultState(
      order: buildOrderResult(),
      payment: const SalesOrderPaymentSummaryDto(
        status: SalesSettlementStatus.unpaid,
        orderTotal: MoneyDto(amountMinor: 4160, currencyCode: 'VND'),
        paidTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        outstandingTotal: MoneyDto(amountMinor: 4160, currencyCode: 'VND'),
      ),
    );

    await tester.pumpWidget(host(state));

    expect(find.text('08/09/2026 · 01:47 · Chưa thanh toán'), findsOneWidget);
  });

  testWidgets('displays Tiền mặt as fallback when originalOrder is null but paidTotal > 0', (
    tester,
  ) async {
    final state = SalesTransactionResultState(
      order: buildOrderResult(),
      payment: const SalesOrderPaymentSummaryDto(
        status: SalesSettlementStatus.paid,
        orderTotal: MoneyDto(amountMinor: 4160, currencyCode: 'VND'),
        paidTotal: MoneyDto(amountMinor: 4160, currencyCode: 'VND'),
        outstandingTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
      ),
    );

    await tester.pumpWidget(host(state));

    expect(find.text('08/09/2026 · 01:47 · Tiền mặt'), findsOneWidget);
  });

  testWidgets('displays Đang đồng bộ when order is not yet loaded', (tester) async {
    const state = SalesTransactionResultState();

    await tester.pumpWidget(host(state));

    expect(find.text('Đang đồng bộ · Tiền mặt'), findsOneWidget);
  });
}
