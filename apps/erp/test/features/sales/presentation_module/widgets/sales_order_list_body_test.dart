import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/sales/data/models.dart' as app;
import 'package:erp/features/sales/presentation.dart';

void main() {
  group('SalesOrderListBody', () {
    testWidgets('loading skeleton is not shorter than an order card', (tester) async {
      await tester.pumpWidget(_host(const SalesOrderListLoading(items: [])));
      await tester.pump();

      final skeletonHeight = tester
          .getSize(
            find.byKey(const Key('card_sales_order_skeleton_0')),
          )
          .height;

      await tester.pumpWidget(
        _host(
          SalesOrderListLoaded(
            items: [_order()],
            hasMore: false,
            requestGeneration: 1,
          ),
        ),
      );
      await tester.pump();

      final orderCardHeight = tester
          .getSize(
            find.byKey(const Key('card_sales_order_so-1')),
          )
          .height;

      expect(skeletonHeight, greaterThanOrEqualTo(orderCardHeight));
    });
  });
}

Widget _host(SalesOrderListState state) {
  return MaterialApp(
    theme: VTheme.lightTheme,
    home: Scaffold(
      body: SizedBox(
        width: 390,
        height: 800,
        child: SalesOrderListBody(
          state: state,
          onRefresh: () async {},
          onRetry: () async {},
          onLoadMore: () async {},
          onTapOrder: (_) {},
        ),
      ),
    ),
  );
}

SalesOrderListItemVm _order() {
  return SalesOrderListItemVm(
    salesOrderId: 'so-1',
    orderNumber: 'DH202608140001',
    sourceVersion: 1,
    completedAt: DateTime(2026, 8, 14, 9, 41),
    customerLabel: 'Nguyễn Văn An',
    customerPhone: '0981287110',
    storeLabel: 'Chi nhánh Quận 1',
    total: const app.MoneyDto(amountMinor: 50000, currencyCode: 'VND'),
    lifecycleStatus: app.SalesOrderLifecycleStatus.completed,
    lockStatus: app.SalesOrderLockStatus.unlocked,
    settlementStatus: app.SalesSettlementStatus.paid,
  );
}
