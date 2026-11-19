import '../../support/fake_sales_checkout_repository.dart';
import '../../support/fake_sales_order_repository.dart';
import '../../support/fake_sales_payment_repository.dart';
import '../../support/fake_sales_receipt_repository.dart';
import '../../support/sales_contract_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/einvoice/data/einvoice_configuration_repository.dart';
import 'package:erp/features/einvoice/data/einvoice_repository.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/presentation/support/order_einvoice_copy.dart';
import 'package:erp/features/einvoice/presentation/widgets/order_einvoice_row.dart';
import 'package:erp/features/sales/data/models.dart';
import 'package:erp/features/sales/presentation/widgets/sales_einvoice_entry_card.dart';

import '../../../einvoice/support/fake_einvoice_configuration_repository.dart';
import '../../../einvoice/support/fake_einvoice_repository.dart';

import 'package:erp/features/sales/logic/sales_transaction_result_cubit.dart';
import 'package:erp/features/einvoice/presentation/support/order_invoice_delivery_copy.dart';
import 'package:erp/features/einvoice/presentation/widgets/invoice_documents_action_sheet.dart';
import 'package:erp/features/einvoice/presentation/widgets/post_issue_einvoice_action_sheet.dart';
import 'package:erp/features/einvoice/presentation/widgets/resend_invoice_sheet.dart';
import 'package:erp/features/sales/presentation/widgets/sales_transaction_result_body.dart';
import 'package:erp/features/einvoice/data/i_invoice_document_exporter.dart';

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
    final einvoice = FakeEInvoiceRepository();
    einvoice.projection = const OrderInvoiceProjectionDto(
      salesOrderId: 'order-1',
      issuanceDisplayState: IssuanceDisplayState.processing,
      actions: [],
    );
    final einvoiceConfig = FakeEInvoiceConfigurationRepository();
    addTearDown(salesCubit.close);

    await tester.pumpWidget(
      _host(
        salesCubit,
        eInvoiceRepository: einvoice,
        eInvoiceConfigurationRepository: einvoiceConfig,
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
      final einvoice = FakeEInvoiceRepository.forScenario(
        FakeEInvoiceScenario.downloadPdfOk,
      );
      final einvoiceConfig = FakeEInvoiceConfigurationRepository();
      final exporter = _RecordingExporter();
      addTearDown(salesCubit.close);

      await tester.pumpWidget(
        _host(
          salesCubit,
          eInvoiceRepository: einvoice,
          eInvoiceConfigurationRepository: einvoiceConfig,
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

      expect(
        einvoice.calls.where((c) => c == 'requestDocument'),
        hasLength(1),
      );
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
      final einvoice = FakeEInvoiceRepository.forScenario(
        FakeEInvoiceScenario.sendSheetResend,
      );
      final older = DateTime.utc(2026, 8, 1, 9);
      final newer = DateTime.utc(2026, 8, 5, 16, 20);
      einvoice.history = InvoiceDeliveryHistoryDto(
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
      );
      final einvoiceConfig = FakeEInvoiceConfigurationRepository();
      addTearDown(salesCubit.close);

      await tester.pumpWidget(
        _host(
          salesCubit,
          eInvoiceRepository: einvoice,
          eInvoiceConfigurationRepository: einvoiceConfig,
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
        einvoice.calls.where((c) => c == 'getDeliveryHistory'),
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
      final newerIndex = texts.indexWhere((t) => t.contains('newer@example.com'));
      final olderIndex = texts.indexWhere((t) => t.contains('older@example.com'));
      expect(newerIndex, lessThan(olderIndex));

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

  testWidgets('result section falls back when repository missing', (tester) async {
    final salesCubit = _cubit(_Repos());
    addTearDown(salesCubit.close);

    await tester.pumpWidget(
      _host(
        salesCubit,
        eInvoiceRepository: null,
        eInvoiceConfigurationRepository: null,
      ),
    );
    await salesCubit.load();
    await tester.pump();
    await tester.pump();

    expect(find.byType(SalesEInvoiceEntryCard), findsOneWidget);
    expect(find.text('Chưa tải được'), findsOneWidget);
  });
}

Widget _host(
  SalesTransactionResultCubit cubit, {
  EInvoiceRepository? eInvoiceRepository,
  EInvoiceConfigurationRepository? eInvoiceConfigurationRepository,
  IInvoiceDocumentExporter? documentExporter,
}) {
  return MaterialApp(
    theme: VTheme.lightTheme,
    home: Scaffold(
      body: BlocProvider<SalesTransactionResultCubit>.value(
        value: cubit,
        child: SalesTransactionResultBody(
          onViewOrderDetail: _noop,
          eInvoiceRepository: eInvoiceRepository,
          eInvoiceConfigurationRepository: eInvoiceConfigurationRepository,
          documentExporter: documentExporter,
        ),
      ),
    ),
  );
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
