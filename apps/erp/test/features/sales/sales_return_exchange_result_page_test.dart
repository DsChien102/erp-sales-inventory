import 'package:erp/features/sales/data/return_exchange_repository.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:erp/features/sales/data/models.dart';
import 'package:vet45_shared_application/application.dart';

import 'support/fake_return_exchange_repository.dart';
import 'support/fake_sales_order_repository.dart';
import 'support/sales_contract_error.dart';
import 'package:erp/features/sales/presentation/pages/sales_return_exchange_result_page.dart';

void main() {
  late FakeReturnExchangeRepository returnExchange;

  setUp(() async {
    await GetIt.instance.reset();
    returnExchange = FakeReturnExchangeRepository()..detailResult = _detail();
    final orders = FakeSalesOrderRepository()
      ..detailResult = _orderDetail()
      ..returnSummaryResult = SalesOrderReturnSummaryDto(
        salesOrderId: 'order-1',
        returns: const [],
      );
    GetIt.instance.registerSingleton<ReturnExchangeRepository>(returnExchange);
    GetIt.instance.registerSingleton<SalesOrderRepository>(orders);
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
    expect(returnExchange.detailCalls, hasLength(1));
  });

  testWidgets('shows failure state without fabricated slip number', (tester) async {
    returnExchange.detailError = salesContractError(
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

  testWidgets('result_body_has_no_complete_button', (tester) async {
    returnExchange.detailResult = _detail(completionReady: true);
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
    expect(find.text('Hoàn tất phiếu'), findsNothing);
    expect(find.byKey(const Key('btn_sg13_complete')), findsNothing);
  });
}

SalesOrderDetailDto _orderDetail() {
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
  );
}

ReturnExchangeDetailDto _detail({bool completionReady = false}) {
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
    completionReady: completionReady,
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
