import 'package:erp/features/sales/data/return_exchange_repository.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'support/module_backed_sales_repositories.dart';
import 'package:erp/features/sales/presentation/pages/sales_return_exchange_detail_page.dart';

void main() {
  late _RecordingSalesModule salesModule;

  setUp(() async {
    await GetIt.instance.reset();
    salesModule = _RecordingSalesModule();
    GetIt.instance.registerSingleton<ISalesModule>(salesModule);
    GetIt.instance.registerSingleton<ReturnExchangeRepository>(
      ModuleBackedReturnExchangeRepository(salesModule),
    );
    GetIt.instance.registerSingleton<SalesOrderRepository>(
      ModuleBackedSalesOrderRepository(salesModule),
    );
    GetIt.instance.registerSingleton<IExecutionContext>(
      const _ExecutionContext(),
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('renders slip detail sections from authoritative detail', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesReturnExchangeDetailPage(
          orderId: 'order-1',
          returnExchangeId: 'return-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_sg13_return_detail_page')), findsOneWidget);
    expect(find.text('Chi tiết phiếu đổi/trả'), findsOneWidget);
    expect(find.byKey(const Key('wgt_sg13_detail_reference')), findsOneWidget);
    expect(find.textContaining('RE-1'), findsWidgets);
    expect(find.text('Hoàn tất'), findsOneWidget);
    expect(find.text('Khách A'), findsOneWidget);
    expect(find.text('Khách trả thêm'), findsOneWidget);
    expect(find.textContaining('Đơn hàng nguồn SO-1'), findsOneWidget);
    expect(find.text('Đã trả một phần'), findsOneWidget);
    expect(find.text('Hàng trả'), findsOneWidget);
    expect(find.text('AD3EC 5L'), findsOneWidget);
    expect(find.text('Hàng đổi'), findsOneWidget);
    expect(find.text('204 ND_IBD 300ml'), findsOneWidget);
    expect(find.text('Tóm tắt đổi/trả'), findsOneWidget);
    expect(find.text('Giá trị hàng trả'), findsOneWidget);
    expect(find.text('Giá trị hàng đổi'), findsOneWidget);
    expect(find.text('Chênh lệch'), findsOneWidget);
    expect(find.byKey(const Key('btn_return_detail_actions')), findsOneWidget);
    expect(find.text('DT-00018'), findsNothing);
    expect(find.text('0903 456 789'), findsNothing);
  });

  testWidgets('opens actions sheet when tapping Thao tác', (tester) async {
    final router = GoRouter(
      initialLocation: '/sales/orders/order-1/returns/return-1/detail',
      routes: [
        GoRoute(
          path: '/sales/orders/:orderId/returns/:returnExchangeId/detail',
          builder: (context, state) => SalesReturnExchangeDetailPage(
            orderId: state.pathParameters['orderId']!,
            returnExchangeId: state.pathParameters['returnExchangeId']!,
          ),
        ),
        GoRoute(
          path: '/sales/orders/:orderId/returns/:returnExchangeId/preview',
          builder: (context, state) => const Scaffold(
            body: Text('preview-route'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_return_detail_actions')));
    await tester.pumpAndSettle();

    expect(find.text('Phiếu đổi/trả'), findsOneWidget);
    expect(find.text('Xem trước phiếu'), findsOneWidget);
    await tester.tap(find.byKey(const Key('btn_return_action_view')));
    await tester.pumpAndSettle();
    expect(find.text('preview-route'), findsOneWidget);
  });
}

final class _RecordingSalesModule implements ISalesModule {
  final List<Object> queries = <Object>[];

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    if (query is GetReturnExchangeDetailQuery) return _detail() as TResult;
    if (query is GetSalesOrderDetailQuery) {
      return SalesOrderDetailDto(
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
            seller: const ActorSnapshotDto(
              actorId: 'actor-1',
              displayName: 'Minh',
            ),
            customer: const CustomerSnapshotDto(
              customerId: 'customer-1',
              displayName: 'Khách A',
            ),
            lines: const [],
          )
          as TResult;
    }
    if (query is GetSalesOrderReturnSummaryQuery) {
      return SalesOrderReturnSummaryDto(
            salesOrderId: 'order-1',
            returns: const [],
          )
          as TResult;
    }
    throw UnsupportedError('unexpected query ${query.runtimeType}');
  }

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError('unexpected command ${command.runtimeType}');
  }
}

ReturnExchangeDetailDto _detail() {
  const plan = ReturnExchangeSettlementPlanDto(
    currencyCode: 'VND',
    netDifferenceMinor: 25476200,
    collectAmountMinor: 25476200,
    refundAmountMinor: 0,
    receivableCreateAmountMinor: 0,
    receivableReverseAmountMinor: 0,
    processedCollectMinor: 0,
    processedRefundMinor: 0,
    pendingReceivableCreateMinor: 0,
    pendingReceivableReverseMinor: 0,
    remainderCollectMinor: 25476200,
    remainderRefundMinor: 0,
    sourceOrderVersion: 7,
    sourceSettlementVersion: 3,
  );
  const valuation = ReturnExchangeValuationDto(
    returnValue: MoneyDto(amountMinor: 235000000, currencyCode: 'VND'),
    exchangeValue: MoneyDto(amountMinor: 260476200, currencyCode: 'VND'),
    settlementDifference: MoneyDto(amountMinor: -25476200, currencyCode: 'VND'),
    settlementPlan: plan,
    sourceOrderVersion: 7,
  );
  return ReturnExchangeDetailDto(
    result: const ReturnExchangeResultDto(
      returnExchangeId: 'return-1',
      salesOrderId: 'order-1',
      version: 2,
      status: ReturnExchangeStatus.completed,
    ),
    referenceNumber: 'RE-1',
    entrySource: ReturnExchangeEntrySource.standard,
    createdAt: DateTime.utc(2026, 8, 13),
    confirmedByActorId: 'actor-1',
    confirmedAt: DateTime.utc(2026, 8, 13, 10),
    completedAt: DateTime.utc(2026, 8, 13, 11),
    lines: const [
      ReturnExchangeDetailLineDto(
        lineId: 'line-r1',
        kind: ReturnExchangeLineKind.returnLine,
        product: ProductSnapshotDto(
          productId: 'p1',
          sku: 'SKU-1',
          displayName: 'AD3EC 5L',
        ),
        unit: ProductUnitSnapshotDto(
          productUnitId: 'u1',
          unitCode: 'CAN',
          unitName: 'Can',
        ),
        quantity: QuantityDto(quantityMicros: QuantityDto.scale),
        unitPrice: MoneyDto(amountMinor: 235000000, currencyCode: 'VND'),
        lineTotal: MoneyDto(amountMinor: 235000000, currencyCode: 'VND'),
        originalSalesOrderLineId: 'sol-1',
        reasonCode: 'DAMAGED',
        conditionCode: 'OPENED',
      ),
      ReturnExchangeDetailLineDto(
        lineId: 'line-e1',
        kind: ReturnExchangeLineKind.exchangeLine,
        product: ProductSnapshotDto(
          productId: 'p2',
          sku: 'SKU-2',
          displayName: '204 ND_IBD 300ml',
        ),
        unit: ProductUnitSnapshotDto(
          productUnitId: 'u2',
          unitCode: 'BOTTLE',
          unitName: 'Chai',
        ),
        quantity: QuantityDto(quantityMicros: QuantityDto.scale),
        unitPrice: MoneyDto(amountMinor: 260476200, currencyCode: 'VND'),
        lineTotal: MoneyDto(amountMinor: 260476200, currencyCode: 'VND'),
      ),
    ],
    valuation: valuation,
    settlementPlan: plan,
    completionReady: false,
  );
}

final class _ExecutionContext implements IExecutionContext {
  const _ExecutionContext();

  @override
  String get correlationId => 'corr-1';

  @override
  Future<String> requireTenantId() async => 'tenant-1';

  @override
  Future<String> requireUserId() async => 'actor-1';
}
