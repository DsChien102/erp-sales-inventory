import 'package:erp/features/sales/data/return_exchange_repository.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:printing/printing.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'support/fake_return_exchange_repository.dart';
import 'support/fake_sales_order_repository.dart';
import 'support/sales_contract_error.dart';
import 'package:erp/features/sales/presentation/pages/sales_return_exchange_slip_preview_page.dart';

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

  testWidgets('preview route loads detail by ID before rendering PDF', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesReturnExchangeSlipPreviewPage(
          orderId: 'order-1',
          returnExchangeId: 'return-1',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('wgt_sg13_slip_preview_page')), findsOneWidget);
    expect(find.byType(PdfPreview), findsOneWidget);
    expect(returnExchange.detailCalls, hasLength(1));
    expect(find.text('PDT-20260722-0018'), findsNothing);
    expect(find.text('Nguyễn Văn An'), findsNothing);
  });

  testWidgets('missing authoritative detail shows error without fallback PDF', (
    tester,
  ) async {
    returnExchange.detailError = salesContractError('NOT_FOUND');
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesReturnExchangeSlipPreviewPage(
          orderId: 'order-1',
          returnExchangeId: 'missing',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('wgt_sg13_slip_preview_error')), findsOneWidget);
    expect(find.byType(PdfPreview), findsNothing);
    expect(find.byKey(const Key('btn_sg13_slip_preview_retry')), findsOneWidget);
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

final class _ExecutionContext implements IExecutionContext {
  const _ExecutionContext();

  @override
  String get correlationId => 'corr-1';

  @override
  Future<String> requireTenantId() async => 'tenant-1';

  @override
  Future<String> requireUserId() async => 'actor-1';
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
      status: ReturnExchangeStatus.completed,
    ),
    referenceNumber: 'RE-1',
    entrySource: ReturnExchangeEntrySource.standard,
    createdAt: DateTime.utc(2026, 8, 13),
    confirmedByActorId: 'actor-1',
    confirmedAt: DateTime.utc(2026, 8, 13, 10),
    completedAt: DateTime.utc(2026, 8, 13, 11),
    lines: const [],
    valuation: valuation,
    settlementPlan: plan,
    completionReady: false,
  );
}
