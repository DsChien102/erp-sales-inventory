import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_application/testing.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:erp/features/sales/presentation/pages/sales_return_exchange_result_page.dart';

void main() {
  late _RecordingSalesModule salesModule;

  setUp(() async {
    await GetIt.instance.reset();
    salesModule = _RecordingSalesModule();
    GetIt.instance.registerSingleton<ISalesModule>(salesModule);
    GetIt.instance.registerSingleton<IExecutionContext>(
      const _ExecutionContext(),
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('loads authoritative result without demo customer defaults', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesReturnExchangeResultPage(
          orderId: 'order-1',
          returnExchangeId: 'return-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_sg13_return_result_page')), findsOneWidget);
    expect(find.text('Kết quả đổi/trả'), findsOneWidget);
    expect(find.text('Đã ghi nhận đổi/trả'), findsOneWidget);
    expect(find.textContaining('RE-1'), findsOneWidget);
    expect(find.text('Khách A'), findsOneWidget);
    expect(find.textContaining('Nguyễn Văn An'), findsNothing);
    expect(find.text('0903 456 789'), findsNothing);
    expect(
      salesModule.queries.whereType<GetReturnExchangeDetailQuery>(),
      hasLength(1),
    );
  });

  testWidgets('shows failure state without fabricated slip number', (tester) async {
    salesModule.detailError = const SalesContractException(
      'DEPENDENCY_UNAVAILABLE',
      message: 'Không tải được kết quả.',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: SalesReturnExchangeResultPage(
          orderId: 'order-1',
          returnExchangeId: 'return-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_sg13_failure')), findsOneWidget);
    expect(find.text('Không tải được kết quả đổi/trả'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.textContaining('DT-00018'), findsNothing);
  });
}

final class _RecordingSalesModule implements ISalesModule {
  Object? detailError;

  final List<Object> queries = <Object>[];

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    if (query is GetReturnExchangeDetailQuery) {
      final error = detailError;
      if (error != null) throw error;
      return _detail() as TResult;
    }
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
        if (SalesFakeContractFixtureFactory.supports(query.runtimeType.toString())) {
      return SalesFakeContractFixtureFactory.create(query.runtimeType.toString()) as TResult;
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
    netDifferenceMinor: 0,
    collectAmountMinor: 0,
    refundAmountMinor: 0,
    receivableCreateAmountMinor: 0,
    receivableReverseAmountMinor: 0,
    processedCollectMinor: 0,
    processedRefundMinor: 0,
    pendingReceivableCreateMinor: 0,
    pendingReceivableReverseMinor: 0,
    remainderCollectMinor: 0,
    remainderRefundMinor: 0,
    sourceOrderVersion: 7,
    sourceSettlementVersion: 3,
  );
  const valuation = ReturnExchangeValuationDto(
    returnValue: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
    exchangeValue: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
    settlementDifference: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    settlementPlan: plan,
    sourceOrderVersion: 7,
  );
  return ReturnExchangeDetailDto(
    result: const ReturnExchangeResultDto(
      returnExchangeId: 'return-1',
      salesOrderId: 'order-1',
      version: 2,
      status: ReturnExchangeStatus.confirmed,
    ),
    referenceNumber: 'RE-1',
    entrySource: ReturnExchangeEntrySource.standard,
    createdAt: DateTime.utc(2026, 8, 13),
    confirmedByActorId: 'actor-1',
    confirmedAt: DateTime.utc(2026, 8, 13, 10),
    completedAt: null,
    lines: const [],
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
