import '../../support/fake_sales_checkout_repository.dart';
import '../../support/fake_sales_order_repository.dart';
import '../../support/fake_sales_payment_repository.dart';
import '../../support/fake_sales_receipt_repository.dart';
import '../../support/sales_contract_error.dart';
import 'package:async_query/async_query.dart';
import 'package:async_query_flutter/async_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_presentation/presentation.dart'
    hide InvoiceDocumentsActionSheet, PostIssueEInvoiceActionSheet;
import 'package:erp/features/sales/data/models.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:erp/features/sales/logic/sales_transaction_result_cubit.dart';
import 'package:erp/features/sales/presentation/services/i_invoice_document_exporter.dart';
import 'package:erp/features/sales/presentation/support/order_invoice_delivery_copy.dart';
import 'package:erp/features/sales/presentation/widgets/einvoice/invoice_documents_action_sheet.dart';
import 'package:erp/features/sales/presentation/widgets/einvoice/post_issue_einvoice_action_sheet.dart';
import 'package:erp/features/sales/presentation/widgets/einvoice/resend_invoice_sheet.dart';
import 'package:erp/features/sales/presentation/widgets/sales_transaction_result_body.dart';

void main() {
  testWidgets('shows loading view at initial state', (tester) async {
    final cubit = _cubit(_Repos());
    addTearDown(cubit.close);

    await tester.pumpWidget(_host(cubit));

    expect(find.text('Đang tải kết quả bán hàng...'), findsOneWidget);
  });

  testWidgets('shows failure card when load fails', (tester) async {
    final cubit = _cubit(
      _Repos(attemptResponses: [salesContractError('PERMISSION_DENIED')]),
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
      _Repos(paymentError: salesContractError('PROJECTION_PENDING')),
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
    final cubit = _cubit(_Repos(generateError: Exception('offline')));
    addTearDown(cubit.close);

    await tester.pumpWidget(_host(cubit));
    await cubit.load();
    await cubit.ensureReceipt();
    await tester.pumpAndSettle();

    expect(find.textContaining('Chưa thể tạo phiếu bán hàng'), findsOneWidget);
  });

  testWidgets('result screen mounts the live invoice row without a tap', (
    tester,
  ) async {
    final salesCubit = _cubit(_Repos());
    final queryClient = QueryClient(
      options: const QueryClientOptions(
        queries: QueryOptionsDefaults(retry: 0, staleTime: Duration.zero),
      ),
    );
    final einvoice = _ProjectionEInvoiceMediator(
      const OrderInvoiceProjectionDto(
        salesOrderId: 'order-1',
        issuanceDisplayState: IssuanceDisplayState.processing,
        actions: [],
      ),
    );
    addTearDown(salesCubit.close);
    addTearDown(queryClient.dispose);

    await tester.pumpWidget(
      _host(
        salesCubit,
        queryClient: queryClient,
        eInvoiceMediator: einvoice,
        executionContext: const _ExecutionContext('tenant-1', 'actor-1'),
      ),
    );
    await salesCubit.load();
    await tester.pump();
    await tester.pump();

    expect(find.byType(OrderEInvoiceRow), findsOneWidget);
    expect(find.text(OrderEInvoiceCopy.badgeProcessing), findsOneWidget);
    expect(find.text('Chưa phát hành'), findsNothing);
  });

  testWidgets(
    'th08_e2e_e03_u02_sc01_01 sales result exports PDF from SG-06',
    (tester) async {
      final salesCubit = _cubit(_Repos());
      final queryClient = QueryClient(
        options: const QueryClientOptions(
          queries: QueryOptionsDefaults(retry: 0, staleTime: Duration.zero),
        ),
      );
      final module = FakeEInvoiceModule(
        scenario: FakeEInvoiceScenario.downloadPdfOk,
      );
      final einvoice = _RecordingEInvoiceMediator(module);
      final exporter = _RecordingExporter();
      addTearDown(salesCubit.close);
      addTearDown(queryClient.dispose);

      await tester.pumpWidget(
        _host(
          salesCubit,
          queryClient: queryClient,
          eInvoiceMediator: einvoice,
          executionContext: const _ExecutionContext('tenant-1', 'actor-1'),
          documentExporter: exporter,
        ),
      );
      await salesCubit.load();
      await tester.pump();
      await tester.pump();

      expect(find.byType(SalesTransactionResultBody), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.badgeIssued), findsOneWidget);

      await tester.ensureVisible(find.byType(OrderEInvoiceRow));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(OrderEInvoiceRow));
      await tester.pumpAndSettle();
      expect(find.byType(PostIssueEInvoiceActionSheet), findsOneWidget);

      await tester.tap(find.byKey(const Key('action_documents')));
      await tester.pumpAndSettle();
      expect(find.byType(InvoiceDocumentsActionSheet), findsOneWidget);

      await tester.tap(find.byKey(const Key('action_save_pdf')));
      await tester.pump();
      // Fake returns PENDING then documents AVAILABLE after pollDelay (1.5s).
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      final pdfCommands = einvoice.commands.whereType<RequestInvoiceDocumentCommand>().where(
        (c) => c.documentType == InvoiceDocumentType.pdf,
      );
      expect(pdfCommands, hasLength(1));
      expect(exporter.exported, hasLength(1));
      expect(
        exporter.exported.single.url,
        'https://download.fake/signed/pdf',
      );
      expect(exporter.exported.single.expectedSha256, 'pdf-checksum-1');
      expect(find.byType(SalesTransactionResultBody), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'th08_e2e_e04_u02_sc06_01 sales result resend opens history then returns',
    (tester) async {
      final salesCubit = _cubit(_Repos());
      final queryClient = QueryClient(
        options: const QueryClientOptions(
          queries: QueryOptionsDefaults(retry: 0, staleTime: Duration.zero),
        ),
      );
      final module = FakeEInvoiceModule(
        scenario: FakeEInvoiceScenario.sendSheetResend,
      );
      final einvoice = _Sg07ResultMediator(module);
      addTearDown(salesCubit.close);
      addTearDown(queryClient.dispose);

      await tester.pumpWidget(
        _host(
          salesCubit,
          queryClient: queryClient,
          eInvoiceMediator: einvoice,
          executionContext: const _ExecutionContext('tenant-1', 'actor-1'),
        ),
      );
      await salesCubit.load();
      await tester.pump();
      await tester.pump();

      expect(find.byType(SalesTransactionResultBody), findsOneWidget);
      await tester.ensureVisible(find.byType(OrderEInvoiceRow));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(OrderEInvoiceRow));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('action_send')));
      await tester.pumpAndSettle();

      expect(find.byType(OrderInvoiceResendSheet), findsOneWidget);
      expect(find.text(OrderInvoiceDeliveryCopy.viewHistory), findsOneWidget);

      await tester.tap(find.byKey(const Key('action_view_delivery_history')));
      await tester.pumpAndSettle();

      expect(
        einvoice.queries.whereType<GetInvoiceDeliveryHistoryQuery>(),
        hasLength(1),
      );
      expect(find.text(OrderInvoiceDeliveryCopy.historyPageTitle), findsOneWidget);
      expect(find.textContaining('newer@example.com'), findsOneWidget);
      expect(find.textContaining('older@example.com'), findsOneWidget);

      final texts = tester
          .widgetList<VText>(find.byType(VText))
          .map((w) => w.data)
          .whereType<String>()
          .toList();
      final newer = texts.indexWhere((t) => t.contains('newer@example.com'));
      final older = texts.indexWhere((t) => t.contains('older@example.com'));
      expect(newer, lessThan(older));

      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is VIcon &&
              (widget.icon == VIcons.chevronLeft || widget.icon == VIcons.arrowBack),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OrderInvoiceResendSheet), findsOneWidget);

      await tester.tap(find.byKey(const Key('action_cancel_send')));
      await tester.pumpAndSettle();
      expect(find.byType(SalesTransactionResultBody), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

Widget _host(
  SalesTransactionResultCubit cubit, {
  QueryClient? queryClient,
  IModuleMediator? eInvoiceMediator,
  IExecutionContext? executionContext,
  IInvoiceDocumentExporter? documentExporter,
}) {
  final app = MaterialApp(
    theme: VTheme.lightTheme,
    home: Scaffold(
      body: BlocProvider<SalesTransactionResultCubit>.value(
        value: cubit,
        child: SalesTransactionResultBody(
          onViewOrderDetail: _noop,
          eInvoiceMediator: eInvoiceMediator,
          executionContext: executionContext,
          documentExporter: documentExporter,
        ),
      ),
    ),
  );
  return queryClient == null ? app : QueryClientProvider(client: queryClient, child: app);
}

void _noop() {}

SalesTransactionResultCubit _cubit(_Repos repos) => SalesTransactionResultCubit(
  storeId: 'store-1',
  idempotencyKey: 'attempt-1',
  salesOrderId: 'order-1',
  checkoutRepository: repos.checkout,
  orderRepository: repos.orders,
  paymentRepository: repos.payments,
  receiptRepository: repos.receipts,
  recoveryBackoff: const [Duration.zero],
);

final class _RecordingEInvoiceMediator implements IModuleMediator {
  _RecordingEInvoiceMediator(this.module);

  final FakeEInvoiceModule module;
  final List<ICommand<dynamic>> commands = [];

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    commands.add(command);
    return module.executeCommandAsync(command);
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    return module.executeQueryAsync(query);
  }
}

final class _Sg07ResultMediator implements IModuleMediator {
  _Sg07ResultMediator(this.module);

  final FakeEInvoiceModule module;
  final List<ICommand<dynamic>> commands = [];
  final List<IQuery<dynamic>> queries = [];

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    commands.add(command);
    return module.executeCommandAsync(command);
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    if (query is GetOrderInvoiceProjectionQuery) {
      return FakeEInvoiceFixtures.projection(
            issuance: IssuanceDisplayState.issued,
            delivery: DeliveryDisplayState.sent,
            actions: const [OrderInvoiceAction.view],
          )
          as TResult;
    }
    if (query is GetInvoiceDeliveryHistoryQuery) {
      final older = DateTime.utc(2026, 8, 1, 9);
      final newer = DateTime.utc(2026, 8, 5, 16, 20);
      return InvoiceDeliveryHistoryDto(
            deliveries: [
              InvoiceDeliveryItemDto(
                deliveryId: 'del-1',
                deliveryNo: 1,
                kind: DeliveryKind.initial,
                triggerType: DeliveryTriggerType.automatic,
                recipientEmail: 'older@example.com',
                status: DeliveryStatus.succeeded,
                initiatedByActorType: DeliveryActorType.system,
                initiatedByActorId: null,
                startedAt: older,
                completedAt: older,
                failureCode: null,
              ),
              InvoiceDeliveryItemDto(
                deliveryId: 'del-2',
                deliveryNo: 2,
                kind: DeliveryKind.resend,
                triggerType: DeliveryTriggerType.manual,
                recipientEmail: 'newer@example.com',
                status: DeliveryStatus.succeeded,
                initiatedByActorType: DeliveryActorType.user,
                initiatedByActorId: 'actor-1',
                startedAt: newer,
                completedAt: newer,
                failureCode: null,
              ),
            ],
            displayState: DeliveryDisplayState.sent,
            hasSecondaryAttention: false,
          )
          as TResult;
    }
    return module.executeQueryAsync(query);
  }
}

final class _RecordingExporter implements IInvoiceDocumentExporter {
  final List<
    ({
      String filename,
      InvoiceDocumentType type,
      String? url,
      String? expectedSha256,
    })
  >
  exported = [];

  @override
  Future<bool> exportDocument({
    required String filename,
    required InvoiceDocumentType type,
    String? url,
    List<int>? bytes,
    String? expectedSha256,
  }) async {
    exported.add((
      filename: filename,
      type: type,
      url: url,
      expectedSha256: expectedSha256,
    ));
    return true;
  }
}

final class _ProjectionEInvoiceMediator implements IModuleMediator {
  _ProjectionEInvoiceMediator(this.projection);

  final OrderInvoiceProjectionDto projection;

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is GetOrderInvoiceProjectionQuery) return projection as TResult;
    if (query is GetIssuanceReadinessQuery) {
      return const IssuanceReadinessDto(
            level: IssuanceReadinessLevel.ready,
            blockers: [],
            warnings: [],
            buyerCompletionState: BuyerCompletionStatus.open,
          )
          as TResult;
    }
    throw UnsupportedError('Unexpected query $query');
  }

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError('Unexpected command $command');
  }
}

final class _Repos {
  _Repos({List<Object>? attemptResponses, Object? paymentError, Object? generateError})
    : checkout = FakeSalesCheckoutRepository()
        ..getResultResults.addAll(attemptResponses ?? [_succeededCheckout()]),
      orders = FakeSalesOrderRepository()..result = _order(),
      payments = FakeSalesPaymentRepository()
        ..summaryResult = _payment()
        ..summaryError = paymentError,
      receipts = FakeSalesReceiptRepository()
        ..generateResult = _receipt()
        ..generateError = generateError
        ..getResult = _receipt()
        ..printedResult = _receipt()
        ..sharedResult = _receipt();

  final FakeSalesCheckoutRepository checkout;
  final FakeSalesOrderRepository orders;
  final FakeSalesPaymentRepository payments;
  final FakeSalesReceiptRepository receipts;
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
