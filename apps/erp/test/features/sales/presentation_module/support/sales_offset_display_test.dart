import 'package:erp/features/sales/data/models.dart' as app;
import 'package:erp/features/sales/presentation.dart';
import 'package:erp/features/sales/presentation/models/sales_order_settlement/sales_order_payment_vm.dart';
import 'package:erp/features/sales/presentation/support/sales_order_detail_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

app.MoneyDto _m(int v) => app.MoneyDto(amountMinor: v, currencyCode: 'VND');

app.SalesPaymentTransactionDto _tx(
  String id,
  app.SalesPaymentTransactionType type,
  String code,
  String orderId,
) => app.SalesPaymentTransactionDto(
  transactionId: id,
  method: app.SalesPaymentMethod.offset,
  amount: _m(500000),
  status: app.SalesPaymentStatus.confirmed,
  recordedAt: DateTime.utc(2026, 11, 19),
  transactionType: type,
  direction: type == app.SalesPaymentTransactionType.refund
      ? app.SalesPaymentDirection.outflow
      : app.SalesPaymentDirection.inflow,
  counterpartOrderCode: code,
  counterpartSalesOrderId: orderId,
);

SalesOrderPaymentVm _vm(
  List<app.SalesPaymentTransactionDto> txs, {
  int collectedOffset = 0,
  int refundedOffset = 0,
}) => SalesOrderDetailMapper.toPaymentVm(
  summary: app.SalesOrderPaymentSummaryDto(
    status: app.SalesSettlementStatus.partiallyPaid,
    orderTotal: _m(4000000),
    paidTotal: _m(4000000),
    outstandingTotal: _m(0),
    collectedOffset: _m(collectedOffset),
    refundedOffset: _m(refundedOffset),
  ),
  settlement: app.SalesOrderSettlementDto(
    settlementId: 's',
    salesOrderId: 'o1',
    version: 1,
    status: app.SalesSettlementStatus.partiallyPaid,
    orderTotal: _m(4000000),
    paidTotal: _m(4000000),
    refundedTotal: _m(0),
    outstanding: _m(0),
  ),
  transactions: app.SalesPaymentTransactionsDto(
    page: app.OpaqueCursorPageDto<app.SalesPaymentTransactionDto>(items: txs, hasMore: false),
  ),
);

void main() {
  test('offset transactions get Cấn trừ labels and counterpart', () {
    final vm = _vm([
      _tx('t1', app.SalesPaymentTransactionType.refund, 'DH-002', 'o2'),
      _tx('t2', app.SalesPaymentTransactionType.collection, 'DH-001', 'o1'),
    ]);
    expect(vm.transactions[0].methodLabel, 'Cấn trừ · sang DH-002');
    expect(vm.transactions[0].kindLabel, isNull);
    expect(vm.transactions[0].counterpartSalesOrderId, 'o2');
    expect(vm.transactions[1].methodLabel, 'Cấn trừ · từ DH-001');
  });

  test('offsetMinor sums collected and refunded offsets; cash rows unchanged', () {
    expect(_vm(const [], refundedOffset: 500000).offsetMinor, 500000);
    expect(_vm(const [], collectedOffset: 200000).offsetMinor, 200000);
    expect(_vm(const []).offsetMinor, 0);
  });

  test('timeline maps offset event and keeps customer-collection description', () {
    final history = SalesOrderDetailMapper.toHistoryVm(
      timeline: app.SalesOrderTimelineDto(
        salesOrderId: 'o1',
        entries: [
          app.SalesOrderTimelineEntryDto(
            eventId: 'e1',
            eventType: 'receivable_offset_recorded.v1',
            occurredAt: DateTime.utc(2026, 11, 19),
            sourceVersion: 1,
          ),
          app.SalesOrderTimelineEntryDto(
            eventId: 'e2',
            eventType: 'sales_payment_recorded.v1',
            occurredAt: DateTime.utc(2026, 11, 19),
            sourceVersion: 1,
            description: 'Ghi nhận thu nợ theo khách',
          ),
        ],
      ),
      returns: app.SalesOrderReturnSummaryDto(salesOrderId: 'o1', returns: []),
    );
    expect(history.timeline[0].title, 'Cấn trừ công nợ');
    expect(history.timeline[1].title, 'Ghi nhận thu nợ theo khách');
  });

  testWidgets('debt page shows Đã cấn trừ only when offset > 0 and opens counterpart', (
    tester,
  ) async {
    String? opened;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => SalesOrderPaymentDebtPage(
            orderNumber: 'DH-001',
            customerName: 'Anh Tuấn',
            payment: _vm(
              [_tx('t1', app.SalesPaymentTransactionType.refund, 'DH-002', 'o2')],
              refundedOffset: 500000,
            ),
          ),
        ),
        GoRoute(
          path: '/sales/orders/:id',
          builder: (_, s) {
            opened = s.pathParameters['id'];
            return const Scaffold(body: Text('order'));
          },
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('Đã cấn trừ'), findsOneWidget);
    expect(find.text('Cấn trừ · sang DH-002'), findsOneWidget);
    await tester.tap(find.byKey(const Key('wgt_sg09b_offset_tx_t1')));
    await tester.pumpAndSettle();
    expect(opened, 'o2');
  });

  testWidgets('debt page hides Đã cấn trừ when 0', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SalesOrderPaymentDebtPage(
          orderNumber: 'DH-001',
          customerName: 'A',
          payment: _vm(const []),
        ),
      ),
    );
    expect(find.text('Đã cấn trừ'), findsNothing);
  });
}
