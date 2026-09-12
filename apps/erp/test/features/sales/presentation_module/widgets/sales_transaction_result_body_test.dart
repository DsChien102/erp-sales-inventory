import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:erp/features/sales/presentation/bloc/sales_order/sales_transaction_result_cubit.dart';
import 'package:erp/features/sales/presentation/widgets/sales_transaction_result_body.dart';

void main() {
  testWidgets('shows loading view at initial state', (tester) async {
    final cubit = _cubit(module: _RecordingSalesModule());
    addTearDown(cubit.close);

    await tester.pumpWidget(_host(cubit));

    expect(find.text('Đang tải kết quả bán hàng...'), findsOneWidget);
  });

  testWidgets('shows failure card when load fails', (tester) async {
    final cubit = _cubit(
      module: _RecordingSalesModule(
        attemptResponses: [const _Failure(SalesContractException('PERMISSION_DENIED'))],
      ),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_host(cubit));
    await cubit.load();
    await tester.pumpAndSettle();

    expect(find.text('Không tải được chi tiết kết quả'), findsOneWidget);
    expect(find.byKey(const Key('btn_sales_result_retry_load')), findsOneWidget);
  });

  testWidgets('keeps success header on partial state', (tester) async {
    final cubit = _cubit(
      module: _RecordingSalesModule(
        paymentResponse: const _Failure(SalesContractException('PROJECTION_PENDING')),
      ),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_host(cubit));
    await cubit.load();
    await tester.pumpAndSettle();

    expect(find.text('Đã hoàn tất đơn'), findsOneWidget);
    expect(
      find.text('Một số dữ liệu liên quan đang chờ đồng bộ. Đơn hàng vẫn đã hoàn tất.'),
      findsOneWidget,
    );
  });

  testWidgets('shows receipt warning banner when receipt operation fails', (tester) async {
    final cubit = _cubit(
      module: _RecordingSalesModule(generateResponses: [_Failure(Exception('offline'))]),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_host(cubit));
    await cubit.load();
    await cubit.ensureReceipt();
    await tester.pumpAndSettle();

    expect(find.textContaining('Chưa thể tạo phiếu bán hàng'), findsOneWidget);
  });
}

Widget _host(SalesTransactionResultCubit cubit) => MaterialApp(
  home: Scaffold(
    body: BlocProvider<SalesTransactionResultCubit>.value(
      value: cubit,
      child: const SalesTransactionResultBody(onViewOrderDetail: _noop),
    ),
  ),
);

void _noop() {}

SalesTransactionResultCubit _cubit({
  required _RecordingSalesModule module,
}) => SalesTransactionResultCubit(
  storeId: 'store-1',
  idempotencyKey: 'attempt-1',
  salesOrderId: 'order-1',
  salesModule: module,
  executionContext: const _ExecutionContext('tenant-1', 'actor-1'),
  recoveryBackoff: const [Duration.zero],
);

final class _RecordingSalesModule implements ISalesModule {
  _RecordingSalesModule({
    List<Object>? attemptResponses,
    List<Object>? generateResponses,
    this.paymentResponse,
  }) : attemptResponses = attemptResponses ?? [_succeededCheckout()],
       generateResponses = generateResponses ?? <Object>[];

  final List<Object> attemptResponses;
  final List<Object> generateResponses;
  Object? orderResponse;
  Object? paymentResponse;

  final SalesOrderResultDto order = _order();
  final SalesOrderPaymentSummaryDto payment = _payment();

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    if (command is GenerateSalesReceiptCommand) {
      final response = generateResponses.isEmpty ? _receipt() : generateResponses.removeAt(0);
      if (response is _Failure) throw response.error;
      return response as TResult;
    }
    if (command is RecordSalesReceiptPrintedCommand || command is RecordSalesReceiptSharedCommand) {
      return _receipt() as TResult;
    }
    throw UnsupportedError('Unexpected command $command');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    final Object response;
    if (query is GetCheckoutResultQuery) {
      response = attemptResponses.removeAt(0);
    } else if (query is GetSalesOrderQuery) {
      response = orderResponse ?? order;
    } else if (query is GetSalesOrderPaymentSummaryQuery) {
      response = paymentResponse ?? payment;
    } else if (query is GetSalesReceiptQuery) {
      response = _receipt();
    } else {
      throw UnsupportedError('Unexpected query $query');
    }
    if (response is _Failure) throw response.error;
    return response as TResult;
  }
}

final class _Failure {
  const _Failure(this.error);
  final Object error;
}

final class _ExecutionContext implements IExecutionContext {
  const _ExecutionContext(this.tenantId, this.userId);
  final String tenantId;
  final String userId;
  @override
  String get correlationId => 'corr-test';
  @override
  Future<String> requireTenantId() async => tenantId;
  @override
  Future<String> requireUserId() async => userId;
}

CheckoutResultDto _succeededCheckout() => const CheckoutResultDto(
  idempotencyKey: 'attempt-1',
  salesOrderId: 'order-1',
  salesOrderVersion: 4,
  status: CheckoutResultStatus.succeeded,
);

SalesOrderResultDto _order() => SalesOrderResultDto(
  order: const SalesOrderDto(
    salesOrderId: 'order-1',
    orderNumber: 'SO-001',
    version: 4,
    lifecycleStatus: SalesOrderLifecycleStatus.completed,
    lockStatus: SalesOrderLockStatus.unlocked,
    total: MoneyDto(amountMinor: 150000, currencyCode: 'VND'),
  ),
  committedAt: DateTime.utc(2026, 8, 12, 8),
  store: const StoreSnapshotDto(storeId: 'store-1', storeCode: 'S1', displayName: 'Store 1'),
  seller: const ActorSnapshotDto(actorId: 'actor-1', displayName: 'Seller 1'),
  customer: const CustomerSnapshotDto(customerId: 'customer-1', displayName: 'Customer 1'),
);

SalesOrderPaymentSummaryDto _payment() => const SalesOrderPaymentSummaryDto(
  status: SalesSettlementStatus.paid,
  orderTotal: MoneyDto(amountMinor: 150000, currencyCode: 'VND'),
  paidTotal: MoneyDto(amountMinor: 150000, currencyCode: 'VND'),
  outstandingTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
);

SalesReceiptDto _receipt() => SalesReceiptDto(
  receiptId: 'receipt-1',
  salesOrderId: 'order-1',
  version: 4,
  status: SalesReceiptStatus.generated,
  generatedAt: DateTime.utc(2026, 8, 12, 8),
  document: SalesReceiptDocumentDto(
    receiptNumber: 'PBH-20260812-0129',
    orderNumber: 'SO-001',
    soldAt: DateTime.utc(2026, 8, 12, 8),
    store: const StoreSnapshotDto(storeId: 'store-1', storeCode: 'S1', displayName: 'Store 1'),
    seller: const ActorSnapshotDto(actorId: 'actor-1', displayName: 'Seller 1'),
    lines: const <SalesReceiptLineDto>[],
    subtotal: const MoneyDto(amountMinor: 150000, currencyCode: 'VND'),
    discountTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    orderTotal: const MoneyDto(amountMinor: 150000, currencyCode: 'VND'),
    paidTotal: const MoneyDto(amountMinor: 150000, currencyCode: 'VND'),
    outstandingTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    payments: const <PaymentIntentSummaryDto>[],
  ),
);
