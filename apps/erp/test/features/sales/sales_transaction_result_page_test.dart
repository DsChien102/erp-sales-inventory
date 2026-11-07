import 'package:erp/features/sales/data/sales_checkout_repository.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/data/sales_payment_repository.dart';
import 'package:erp/features/sales/data/sales_receipt_repository.dart';
import 'support/fake_sales_checkout_repository.dart';
import 'support/fake_sales_order_repository.dart';
import 'support/fake_sales_payment_repository.dart';
import 'support/fake_sales_receipt_repository.dart';
import 'support/sales_contract_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart'
    hide SalesOrderLifecycleStatus, SalesSettlementStatus;
import 'package:vet45_shared_application/application.dart';

import 'package:erp/features/sales/presentation/pages/sales_result_invalid_entry_page.dart';
import 'package:erp/features/sales/presentation/pages/sales_transaction_result_page.dart';

void main() {
  late FakeSalesCheckoutRepository checkout;
  late FakeSalesOrderRepository orders;
  late FakeSalesPaymentRepository payments;

  setUp(() async {
    await GetIt.instance.reset();
    checkout = FakeSalesCheckoutRepository();
    orders = FakeSalesOrderRepository()..result = _orderResult('SO-000129');
    payments = FakeSalesPaymentRepository()..summaryResult = _paymentSummary();
    GetIt.instance
      ..registerSingleton<SalesCheckoutRepository>(checkout)
      ..registerSingleton<SalesOrderRepository>(orders)
      ..registerSingleton<SalesReceiptRepository>(FakeSalesReceiptRepository())
      ..registerSingleton<SalesPaymentRepository>(payments)
      ..registerSingleton<IExecutionContext>(const _TestExecutionContext());
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('loads authoritative result through repositories on init', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SalesTransactionResultPage(args: _successArgs()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      [
        if (checkout.getResultCalls.isNotEmpty) 'checkoutResult',
        if (orders.getCalls.isNotEmpty) 'order',
        if (payments.summaryCalls.isNotEmpty) 'paymentSummary',
      ],
      containsAll(['checkoutResult', 'order', 'paymentSummary']),
    );
    expect(find.byKey(const Key('wgt_sg06_result_page')), findsOneWidget);
    expect(find.text('Đã hoàn tất đơn'), findsOneWidget);
    expect(find.textContaining('SO-000129'), findsOneWidget);
    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(find.byKey(const Key('btn_sg06_new_order')), findsOneWidget);
  });

  testWidgets('shows failure action bar when authoritative load fails', (tester) async {
    checkout.getResultError = salesContractError('PERMISSION_DENIED');

    await tester.pumpWidget(
      MaterialApp(
        home: SalesTransactionResultPage(args: _successArgs()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không tải được chi tiết kết quả'), findsOneWidget);
    expect(find.text('Thử tải lại'), findsNWidgets(2));
  });

  testWidgets('route/path mismatch renders invalid entry page', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/sales/result/:orderId',
          builder: (context, state) {
            final orderId = state.pathParameters['orderId']!;
            final args = state.extra;
            if (args is! SalesCheckoutResultArgs || args.salesOrderId != orderId) {
              return const SalesResultInvalidEntryPage();
            }
            return SalesTransactionResultPage(args: args);
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go(
      '/sales/result/order-1',
      extra: SalesCheckoutResultArgs(
        storeId: 'store-1',
        result: CheckoutResultDto(
          idempotencyKey: 'attempt-1',
          salesOrderId: 'order-2',
          salesOrderVersion: 1,
          status: CheckoutResultStatus.succeeded,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_sg06_invalid_result_entry')), findsOneWidget);
  });

  testWidgets('displays custom order number from fake repository data', (tester) async {
    orders.result = _orderResult('SO-CUSTOM-777');

    await tester.pumpWidget(
      MaterialApp(
        home: SalesTransactionResultPage(args: _successArgs()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('SO-CUSTOM-777'), findsOneWidget);
    expect(find.textContaining('SO-000129'), findsNothing);
  });
}

SalesCheckoutResultArgs _successArgs() => SalesCheckoutResultArgs(
  storeId: 'store-1',
  result: CheckoutResultDto(
    idempotencyKey: 'attempt-1',
    salesOrderId: 'order-1',
    salesOrderVersion: 3,
    status: CheckoutResultStatus.succeeded,
  ),
);

final class _TestExecutionContext implements IExecutionContext {
  const _TestExecutionContext();

  @override
  String get correlationId => 'corr-test';

  @override
  Future<String> requireTenantId() async => 'tenant-1';

  @override
  Future<String> requireUserId() async => 'actor-1';
}

SalesOrderResultDto _orderResult(String orderNumber) {
  return SalesOrderResultDto(
    order: SalesOrderDto(
      salesOrderId: 'order-1',
      orderNumber: orderNumber,
      version: 3,
      lifecycleStatus: SalesOrderLifecycleStatus.completed,
      lockStatus: SalesOrderLockStatus.unlocked,
      total: const MoneyDto(amountMinor: 4445238, currencyCode: 'VND'),
    ),
    committedAt: DateTime.utc(2026, 8, 12, 2, 41),
    store: const StoreSnapshotDto(
      storeId: 'store-1',
      storeCode: 'HCM-01',
      displayName: 'Chi nhánh Quận 1',
    ),
    seller: const ActorSnapshotDto(actorId: 'actor-1', displayName: 'Minh Anh'),
    customer: const CustomerSnapshotDto(
      customerId: 'customer-1',
      displayName: 'Nguyễn Văn An',
      phoneNumber: '0903456789',
    ),
  );
}

SalesOrderPaymentSummaryDto _paymentSummary() {
  return SalesOrderPaymentSummaryDto(
    status: SalesSettlementStatus.paid,
    orderTotal: const MoneyDto(amountMinor: 4445238, currencyCode: 'VND'),
    paidTotal: const MoneyDto(amountMinor: 4445238, currencyCode: 'VND'),
    outstandingTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
  );
}
