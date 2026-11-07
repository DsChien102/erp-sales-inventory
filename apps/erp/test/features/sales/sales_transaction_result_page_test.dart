import 'package:erp/features/sales/data/sales_checkout_repository.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/data/sales_payment_repository.dart';
import 'support/module_backed_sales_repositories.dart';
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
  late _GroupEResultSalesModule salesModule;

  setUp(() async {
    await GetIt.instance.reset();
    salesModule = _GroupEResultSalesModule();
    GetIt.instance
      ..registerSingleton<ISalesModule>(salesModule)
      ..registerSingleton<SalesCheckoutRepository>(
        ModuleBackedSalesCheckoutRepository(salesModule),
      )
      ..registerSingleton<SalesOrderRepository>(ModuleBackedSalesOrderRepository(salesModule))
      ..registerSingleton<SalesPaymentRepository>(ModuleBackedSalesPaymentRepository(salesModule))
      ..registerSingleton<IExecutionContext>(const _TestExecutionContext());
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('loads authoritative result through ISalesModule on init', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SalesTransactionResultPage(args: _successArgs()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      salesModule.queries.map((query) => query.runtimeType),
      containsAll([
        GetCheckoutResultQuery,
        GetSalesOrderQuery,
        GetSalesOrderPaymentSummaryQuery,
      ]),
    );
    expect(find.byKey(const Key('wgt_sg06_result_page')), findsOneWidget);
    expect(find.text('Đã hoàn tất đơn'), findsOneWidget);
    expect(find.textContaining('SO-000129'), findsOneWidget);
    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(find.byKey(const Key('btn_sg06_new_order')), findsOneWidget);
  });

  testWidgets('shows failure action bar when authoritative load fails', (tester) async {
    salesModule.attemptError = const SalesContractException('PERMISSION_DENIED');

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

  testWidgets('displays custom order number from fake module data', (tester) async {
    salesModule.orderNumber = 'SO-CUSTOM-777';

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

final class _GroupEResultSalesModule implements ISalesModule {
  final List<Object> queries = [];
  Object? attemptError;
  String orderNumber = 'SO-000129';

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError('Unexpected command $command');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    final raw = query as Object;
    if (raw is GetCheckoutResultQuery) {
      final error = attemptError;
      if (error != null) throw error;
      return CheckoutResultDto(
            idempotencyKey: raw.idempotencyKey,
            salesOrderId: 'order-1',
            salesOrderVersion: 3,
            status: CheckoutResultStatus.succeeded,
          )
          as TResult;
    }
    if (raw is GetSalesOrderQuery) {
      return SalesOrderResultDto(
            order: SalesOrderDto(
              salesOrderId: raw.salesOrderId,
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
          )
          as TResult;
    }
    if (raw is GetSalesOrderPaymentSummaryQuery) {
      return SalesOrderPaymentSummaryDto(
            status: SalesSettlementStatus.paid,
            orderTotal: const MoneyDto(amountMinor: 4445238, currencyCode: 'VND'),
            paidTotal: const MoneyDto(amountMinor: 4445238, currencyCode: 'VND'),
            outstandingTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
          )
          as TResult;
    }
        throw StateError('Unexpected query $query');
  }
}
