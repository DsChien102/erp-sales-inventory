import 'package:erp/core/session/session_controller.dart';
import 'package:erp/features/sales/data/return_exchange_repository.dart';
import 'package:erp/features/sales/data/sales_cancellation_repository.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/data/sales_payment_repository.dart';
import 'package:erp/features/sales/data/sales_receipt_repository.dart';
import '../iam/support/iam_test_session.dart';
import 'package:erp/features/sales/data/models/sales_cancellation_request.dart';
import 'package:erp/features/sales/data/models/sales_record_payment.dart';
import 'support/fake_return_exchange_repository.dart';
import 'support/fake_sales_cancellation_repository.dart';
import 'support/fake_sales_order_repository.dart';
import 'support/fake_sales_payment_repository.dart';
import 'support/fake_sales_receipt_repository.dart';
import 'support/sales_contract_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/sales/data/models.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:erp/features/sales/presentation.dart'
    hide SalesOrderLifecycleStatus, SalesSettlementStatus, SalesEInvoiceStatus;
import 'package:erp/features/sales/presentation/pages/sales_order_detail_page.dart';

final class TestExecutionContext implements IExecutionContext {
  const TestExecutionContext();

  @override
  String get correlationId => 'corr-1';

  @override
  Future<String> requireTenantId() async => 'tenant-demo';

  @override
  Future<String> requireUserId() async => 'user-demo';
}

void main() {
  late _DetailRepos salesModule;

  setUp(() async {
    await GetIt.instance.reset();
    salesModule = _DetailRepos(detail: _detail());
    GetIt.instance.registerSingleton<SalesOrderRepository>(salesModule.orders);
    GetIt.instance.registerSingleton<SalesReceiptRepository>(salesModule.receipts);
    GetIt.instance.registerSingleton<SalesPaymentRepository>(salesModule.payments);
    GetIt.instance.registerSingleton<SalesCancellationRepository>(salesModule.cancellations);
    GetIt.instance.registerSingleton<ReturnExchangeRepository>(salesModule.returnExchange);
    GetIt.instance.registerSingleton<IExecutionContext>(
      const TestExecutionContext(),
    );
    GetIt.instance.registerSingleton<SessionController>(
      testSessionController(
        tenantId: 'tenant-demo',
        userId: 'user-demo',
        activeStoreId: 'store-1',
      ),
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('SG-08 renders core detail from dto without demo id heuristics', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesOrderDetailPage(orderId: 'so-demo-006'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_sg08_order_detail_page')), findsOneWidget);
    // No return/exchange on this order → tab bar is hidden (ADR-9 P3b).
    expect(find.byKey(const Key('wgt_sg08_order_detail_tabs')), findsNothing);
    expect(find.text('Đại lý An Bình'), findsOneWidget);
    expect(find.text('Thanh toán & công nợ'), findsOneWidget);
    expect(find.text('Sản phẩm'), findsOneWidget);
    expect(find.text('Vaccine A'), findsOneWidget);
    expect(find.text('Chứng từ & hóa đơn'), findsOneWidget);
    expect(find.text('Trạng thái tích hợp'), findsNothing);
    expect(find.text('Phiếu đổi/trả'), findsNothing);
    expect(find.byKey(const Key('btn_sg08_actions')), findsOneWidget);
    expect(find.byKey(const Key('wgt_sg08_loading')), findsNothing);
  });

  testWidgets('SG-08 renders documents section (receipt + e-invoice) and no integration section', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesOrderDetailPage(orderId: 'order-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chứng từ & hóa đơn'), findsOneWidget);
    expect(find.byKey(const Key('btn_sg08_receipt')), findsOneWidget);
    expect(find.byKey(const Key('btn_sg08_einvoice')), findsOneWidget);
    expect(find.text('Chưa phát hành'), findsOneWidget);
    expect(find.byKey(const Key('wgt_sg08_integration_section')), findsNothing);
  });

  testWidgets('SG-08 D-02 navigates to Payment & Debt page', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesOrderDetailPage(orderId: 'order-1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thanh toán & công nợ').first);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_sg08_payment_debt_page')), findsOneWidget);
    expect(find.byKey(const Key('wgt_sg08_payment_debt_context')), findsOneWidget);
    expect(find.text('Tình trạng hiện tại'), findsOneWidget);
    expect(find.text('Xem công nợ'), findsNothing);
    expect(find.byKey(const Key('btn_sg08_history_entry')), findsNothing);
  });

  testWidgets('SG-08 history entry on main page opens D-03 directly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesOrderDetailPage(orderId: 'order-1', showHistory: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_sg08_history_entry')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('btn_sg08_history_entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_sg08_history_entry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_sg08_history_page')), findsOneWidget);
  });

  testWidgets('SG-08 grouped sections render on loaded detail', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesOrderDetailPage(orderId: 'order-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_sg08_products_grouped')), findsOneWidget);
    expect(find.byKey(const Key('wgt_sg08_documents_grouped')), findsOneWidget);
    expect(find.byKey(const Key('wgt_sg08_payment')), findsOneWidget);
  });

  testWidgets('SG-08 cancelled lifecycle hides actions and does not invent cancel reason', (
    tester,
  ) async {
    salesModule.detail = _detail(lifecycleStatus: SalesOrderLifecycleStatus.cancelled);
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesOrderDetailPage(orderId: 'order-cancelled'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_sg08_order_detail_page')), findsOneWidget);
    expect(find.text('Khách không nhận hàng'), findsNothing);
    expect(find.byKey(const Key('btn_sg08_actions')), findsNothing);
    expect(find.text('Chứng từ & hóa đơn'), findsOneWidget);
    expect(find.byKey(const Key('btn_sg08_receipt')), findsNothing);
    expect(find.byKey(const Key('btn_sg08_einvoice')), findsNothing);
    expect(find.byKey(const Key('btn_sg08_history_entry')), findsOneWidget);
    expect(find.byKey(const Key('wgt_sg08_payment')), findsOneWidget);
  });

  testWidgets('SG-08 O-03 opens Thao tác bottom sheet', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesOrderDetailPage(orderId: 'order-1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_sg08_actions')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_order_action_receipt')), findsNothing);
    expect(find.byKey(const Key('btn_order_action_adjust')), findsNothing);
    expect(find.byKey(const Key('btn_order_action_return')), findsOneWidget);
    expect(find.byKey(const Key('btn_order_action_cancel')), findsOneWidget);
    // Receipt moved to the documents section and adjust was removed from the sheet.
    expect(find.text('Phiếu bán hàng'), findsOneWidget);
    expect(find.text('Điều chỉnh đơn'), findsNothing);
    expect(find.text('Đổi/trả hàng'), findsOneWidget);
    expect(find.text('Hủy đơn'), findsOneWidget);
  });

  testWidgets('SG-08 actions section error surfaces feedback instead of locked sheet', (
    tester,
  ) async {
    salesModule.actionsError = salesContractError(
      'DATA_SCOPE_DENIED',
      message: 'Store scope denied.',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: SalesOrderDetailPage(orderId: 'order-1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_sg08_actions')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_order_action_adjust')), findsNothing);
    expect(find.byKey(const Key('btn_order_action_return')), findsNothing);
    expect(find.byKey(const Key('btn_order_action_cancel')), findsNothing);
    expect(find.byType(VToast), findsOneWidget);
    final toast = tester.widget<VToast>(find.byType(VToast));
    expect(toast.title, 'Không thể tải thao tác');
    expect(toast.message, 'Vui lòng thử lại sau.');
    expect(toast.type, VToastType.warning);
  });

  testWidgets('SG-08 S21 navigates to return and opens cancel sheet directly', (
    tester,
  ) async {
    salesModule.paidTotalMinor = 0;
    final router = GoRouter(
      initialLocation: '/sales/orders/order-1',
      routes: [
        GoRoute(
          path: '/sales/orders/:orderId',
          builder: (context, state) =>
              SalesOrderDetailPage(orderId: state.pathParameters['orderId']!),
          routes: [
            GoRoute(
              path: 'returns/new',
              builder: (context, state) => const Scaffold(body: Text('return-route')),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    Future<void> openAndTap(Key actionKey) async {
      await tester.tap(find.byKey(const Key('btn_sg08_actions')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(actionKey));
      await tester.pumpAndSettle();
    }

    await openAndTap(const Key('btn_order_action_cancel'));
    expect(find.text('Hủy đơn hàng?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('btn_cancel_sheet_back')));
    await tester.pumpAndSettle();

    await openAndTap(const Key('btn_order_action_return'));
    expect(find.text('return-route'), findsOneWidget);
    expect(router.state.uri.path, '/sales/orders/order-1/returns/new');
  });

  testWidgets('SG-10 cancel sheet submits the typed reason note to backend command', (
    tester,
  ) async {
    salesModule.paidTotalMinor = 0;

    await tester.pumpWidget(
      const MaterialApp(
        home: SalesOrderDetailPage(orderId: 'order-1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_sg08_actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_order_action_cancel')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('input_cancel_reason')),
      'Khách đổi ý sau khi đặt',
    );
    await tester.tap(find.byKey(const Key('btn_cancel_sheet_confirm')));
    await tester.pumpAndSettle();

    expect(salesModule.cancellations.confirmCalls, hasLength(1));
    expect(
      [
        ...salesModule.payments.recordCalls,
        ...salesModule.receipts.generateCalls,
        ...salesModule.receipts.printedCalls,
        ...salesModule.receipts.sharedCalls,
        ...salesModule.returnExchange.startCalls,
        ...salesModule.returnExchange.updateCalls,
        ...salesModule.returnExchange.cancelCalls,
        ...salesModule.returnExchange.confirmCalls,
      ],
      isEmpty,
    );
    final command = salesModule.cancellations.confirmCalls.single;

    expect(command.reasonText, 'Khách đổi ý sau khi đặt');
  });

  testWidgets('SG-08 disables cancel action when order has collected payment', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/sales/orders/order-1',
      routes: [
        GoRoute(
          path: '/sales/orders/:orderId',
          builder: (context, state) =>
              SalesOrderDetailPage(orderId: state.pathParameters['orderId']!),
          routes: [
            GoRoute(
              path: 'cancel',
              builder: (context, state) => const Scaffold(body: Text('cancel-route')),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_sg08_actions')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_order_action_cancel')), findsOneWidget);
    expect(find.text('Đơn đã có thanh toán, vui lòng đổi/trả'), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_order_action_cancel')));
    await tester.pumpAndSettle();

    expect(find.text('cancel-route'), findsNothing);
    expect(router.state.uri.path, '/sales/orders/order-1');
    expect(
      salesModule.cancellations.precheckCalls,
      isEmpty,
    );
  });

  testWidgets('SG-08 S21 blocked precheck stays on detail route', (tester) async {
    salesModule.paidTotalMinor = 0;
    salesModule.cancelAllowed = false;
    final router = GoRouter(
      initialLocation: '/sales/orders/order-1',
      routes: [
        GoRoute(
          path: '/sales/orders/:orderId',
          builder: (context, state) =>
              SalesOrderDetailPage(orderId: state.pathParameters['orderId']!),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_sg08_actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_order_action_cancel')));
    await tester.pumpAndSettle();

    expect(find.text('Hủy đơn hàng?'), findsNothing);
    expect(find.byKey(const Key('wgt_sg08_order_detail_page')), findsOneWidget);
    expect(find.byType(VToast), findsOneWidget);
  });

  testWidgets('SG-08 receipt action opens receipt sheet', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesOrderDetailPage(orderId: 'order-1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('btn_sg08_receipt')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_sg08_receipt')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_receipt_action_view')), findsOneWidget);
    expect(find.byKey(const Key('btn_receipt_action_print')), findsOneWidget);
    expect(find.byKey(const Key('btn_receipt_action_share')), findsOneWidget);
  });

  testWidgets('SG-08 receipt view failure surfaces VToast and keeps core loaded', (
    tester,
  ) async {
    salesModule.getReceiptError = salesContractError('PERMISSION_DENIED');

    await tester.pumpWidget(
      const MaterialApp(
        home: SalesOrderDetailPage(orderId: 'order-1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('btn_sg08_receipt')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_sg08_receipt')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_receipt_action_view')));
    await tester.pumpAndSettle();

    expect(find.byType(VToast), findsOneWidget);
    final toast = tester.widget<VToast>(find.byType(VToast));
    expect(toast.type, VToastType.danger);
    expect(toast.title, 'Thao tác phiếu thất bại');
    expect(toast.message, 'Bạn không có quyền thao tác phiếu bán hàng.');
    expect(find.text('Bạn không có quyền thao tác phiếu bán hàng.'), findsOneWidget);
    expect(find.byKey(const Key('wgt_sg08_order_detail_page')), findsOneWidget);
    expect(find.text('Đại lý An Bình'), findsOneWidget);
  });

  testWidgets('SG-08 blocked status renders blocked instead of spinner', (tester) async {
    salesModule.error = salesContractError('PERMISSION_DENIED');
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesOrderDetailPage(orderId: 'order-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_sg08_loading')), findsNothing);
    expect(find.byKey(const Key('wgt_sg08_blocked')), findsOneWidget);
    expect(find.byKey(const Key('wgt_sg08_order_detail_page')), findsNothing);
    expect(find.text('PERMISSION_DENIED'), findsNothing);
    expect(
      find.text('Tài khoản của bạn không có quyền xem đơn hàng này.'),
      findsOneWidget,
    );
  });

  testWidgets('SG-08 not found status renders not-found instead of spinner', (tester) async {
    salesModule.error = salesContractError('NOT_FOUND');
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesOrderDetailPage(orderId: 'missing-order'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_sg08_loading')), findsNothing);
    expect(find.byKey(const Key('wgt_sg08_not_found')), findsOneWidget);
  });

  testWidgets('SG-08 error status renders error instead of spinner', (tester) async {
    salesModule.error = salesContractError('TRANSPORT_ERROR', message: 'network down');
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesOrderDetailPage(orderId: 'order-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_sg08_loading')), findsNothing);
    expect(find.byKey(const Key('wgt_sg08_error')), findsOneWidget);
  });

  testWidgets('SG-08 projection pending renders retryable pending instead of spinner', (
    tester,
  ) async {
    salesModule.error = salesContractError('PROJECTION_PENDING');
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesOrderDetailPage(orderId: 'order-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_sg08_loading')), findsNothing);
    expect(find.byKey(const Key('wgt_sg08_projection_pending')), findsOneWidget);
  });

  testWidgets('SG-08 return detail push includes returnExchangeId in path', (
    tester,
  ) async {
    String? capturedPath;
    salesModule.returns = [
      ReturnExchangeSummaryDto(
        returnExchangeId: 're-42',
        referenceNumber: 'DT-2026-00042',
        status: ReturnExchangeStatus.completed,
        completedAt: DateTime.utc(2026, 8, 14, 9, 30),
        settlementDifference: const MoneyDto(amountMinor: 150000, currencyCode: 'VND'),
      ),
    ];

    final router = GoRouter(
      initialLocation: '/sales/orders/order-1',
      routes: [
        GoRoute(
          path: '/sales/orders/:orderId',
          builder: (context, state) =>
              SalesOrderDetailPage(orderId: state.pathParameters['orderId']!),
        ),
        GoRoute(
          path: '/sales/orders/:orderId/returns/:returnExchangeId/detail',
          builder: (context, state) {
            capturedPath = state.uri.path;
            return const Scaffold(body: Text('return-detail-route'));
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final returnsCard = find.textContaining('1 phiếu');
    await tester.ensureVisible(returnsCard);
    await tester.pumpAndSettle();
    await tester.tap(returnsCard);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_sg08_return_list_page')), findsOneWidget);
    await tester.tap(find.textContaining('DT-2026-00042'));
    await tester.pumpAndSettle();

    expect(find.text('return-detail-route'), findsOneWidget);
    expect(capturedPath, '/sales/orders/order-1/returns/re-42/detail');
  });

  testWidgets('SG-10 showSalesOrderCancelSheet renders VBottomSheet cancel dialog', (tester) async {
    final cubit = SalesOrderDetailCubit(
      orderId: 'order-1',
      orderRepository: salesModule.orders,
      receiptRepository: salesModule.receipts,
      paymentRepository: salesModule.payments,
      cancellationRepository: salesModule.cancellations,
      returnExchangeRepository: salesModule.returnExchange,
      executionContext: const TestExecutionContext(),
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showSalesOrderCancelSheet(context, vm: cubit.state.core!);
                },
                child: const Text('Open Cancel Sheet'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Cancel Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Hủy đơn hàng?'), findsOneWidget);
    expect(find.byKey(const Key('input_cancel_reason')), findsOneWidget);
    expect(find.text('Điều chỉnh dự kiến'), findsOneWidget);
    expect(find.byKey(const Key('btn_cancel_sheet_back')), findsOneWidget);
    expect(find.byKey(const Key('btn_cancel_sheet_confirm')), findsOneWidget);
  });

  testWidgets('SG-08 P3b hides Đơn gốc/Sau đổi/trả tabs when order has no return/exchange', (
    tester,
  ) async {
    salesModule.detail = _detail();
    salesModule.returns = const [];

    await tester.pumpWidget(
      const MaterialApp(
        home: SalesOrderDetailPage(orderId: 'order-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_sg08_order_detail_tabs')), findsNothing);
    expect(find.text('Đơn gốc'), findsNothing);
    expect(find.text('Sau đổi/trả'), findsNothing);
    expect(find.text('Tổng đơn'), findsOneWidget);
    expect(find.text('Vaccine A'), findsOneWidget);
  });

  testWidgets(
    'SG-08 P3b shows tabs and current holdings with Tổng đơn on Sau đổi/trả tab',
    (tester) async {
      salesModule.returns = [
        ReturnExchangeSummaryDto(
          returnExchangeId: 're-42',
          referenceNumber: 'DT-2026-00042',
          status: ReturnExchangeStatus.completed,
          completedAt: DateTime.utc(2026, 8, 14, 9, 30),
          settlementDifference: const MoneyDto(amountMinor: 150000, currencyCode: 'VND'),
        ),
      ];
      salesModule.detail = _detail(
        currentLines: const [
          SalesOrderCurrentLineDto(
            product: ProductSnapshotDto(
              productId: 'product-2',
              sku: 'SKU-2',
              displayName: 'Vaccine B',
            ),
            unit: ProductUnitSnapshotDto(
              productUnitId: 'unit-2',
              unitCode: 'VIAL',
              unitName: 'Lọ',
            ),
            heldQuantity: QuantityDto(quantityMicros: QuantityDto.scale),
            unitPrice: MoneyDto(amountMinor: 900000, currencyCode: 'VND'),
            source: SalesOrderLineSource.exchange,
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: SalesOrderDetailPage(orderId: 'order-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_sg08_order_detail_tabs')), findsOneWidget);
      // Default tab selection lands on "Sau đổi/trả" (index 1).
      expect(find.text('Vaccine B'), findsOneWidget);
      expect(find.text('Vaccine A'), findsNothing);
      expect(find.text('Tổng đơn'), findsOneWidget);

      await tester.tap(find.text('Đơn gốc'));
      await tester.pumpAndSettle();

      expect(find.text('Vaccine A'), findsOneWidget);
      expect(find.text('Vaccine B'), findsNothing);
      expect(find.text('Tổng đơn'), findsOneWidget);
    },
  );

  testWidgets('SG-08 collect_payment_shown_when_outstanding', (tester) async {
    salesModule.paidTotalMinor = 650000; // Total 1250000 -> outstanding 600000
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesOrderDetailPage(orderId: 'order-1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_sg08_actions')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_order_action_collect_payment')), findsOneWidget);
    expect(find.text('Thu tiền'), findsOneWidget);
    expect(find.text('Ghi nhận khoản khách trả thêm cho đơn'), findsOneWidget);
  });

  testWidgets('SG-08 collect_payment_hidden_when_paid (AC-04)', (tester) async {
    salesModule.paidTotalMinor = 1250000; // Outstanding 0
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesOrderDetailPage(orderId: 'order-1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_sg08_actions')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_order_action_collect_payment')), findsNothing);
  });

  testWidgets('SG-08 collect_payment_hidden_when_cancelled', (tester) async {
    salesModule.detail = _detail(
      lifecycleStatus: SalesOrderLifecycleStatus.cancelled,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesOrderDetailPage(orderId: 'order-1'),
      ),
    );
    await tester.pumpAndSettle();

    // Cancelled order hides action bar
    expect(find.byKey(const Key('btn_sg08_actions')), findsNothing);
  });

  testWidgets('SG-08 collect_payment_hidden_when_payment_section_failed', (tester) async {
    salesModule.paymentError = Exception('Payment section network error');
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesOrderDetailPage(orderId: 'order-1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_sg08_actions')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_order_action_collect_payment')), findsNothing);
  });

  testWidgets('SG-08 success_toasts_and_refreshes', (tester) async {
    salesModule.paidTotalMinor = 650000; // Outstanding 600000
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesOrderDetailPage(orderId: 'order-1'),
      ),
    );
    await tester.pumpAndSettle();

    final queryCountBefore = salesModule.queryCount;

    await tester.tap(find.byKey(const Key('btn_sg08_actions')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_order_action_collect_payment')));
    await tester.pumpAndSettle();

    expect(find.text('Xác nhận thu tiền'), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_sg11_confirm')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Đã ghi nhận 600.000đ'), findsOneWidget);
    expect(salesModule.queryCount, greaterThan(queryCountBefore));
  });

  testWidgets('SG-08 closed_without_payment_still_refreshes', (tester) async {
    salesModule.paidTotalMinor = 650000;
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesOrderDetailPage(orderId: 'order-1'),
      ),
    );
    await tester.pumpAndSettle();

    final queryCountBefore = salesModule.queryCount;

    await tester.tap(find.byKey(const Key('btn_sg08_actions')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_order_action_collect_payment')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quay lại'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Đã ghi nhận'), findsNothing);
    expect(salesModule.queryCount, greaterThan(queryCountBefore));
  });
}

SalesOrderDetailDto _detail({
  SalesOrderLifecycleStatus lifecycleStatus = SalesOrderLifecycleStatus.completed,
  int version = 7,
  String? orderNote = 'Giao giờ hành chính',
  List<SalesOrderCurrentLineDto> currentLines = const [],
}) {
  return SalesOrderDetailDto(
    order: SalesOrderDto(
      salesOrderId: 'order-1',
      orderNumber: 'SO-2026-00125',
      version: version,
      lifecycleStatus: lifecycleStatus,
      lockStatus: SalesOrderLockStatus.unlocked,
      total: const MoneyDto(amountMinor: 1250000, currencyCode: 'VND'),
    ),
    committedAt: DateTime.utc(2026, 8, 12, 3, 15),
    store: const StoreSnapshotDto(
      storeId: 'store-1',
      storeCode: 'HCM-01',
      displayName: 'Chi nhánh Quận 1',
    ),
    seller: const ActorSnapshotDto(actorId: 'seller-1', displayName: 'Minh Anh'),
    customer: const CustomerSnapshotDto(
      customerId: 'customer-1',
      displayName: 'Đại lý An Bình',
      phoneNumber: '0903456789',
    ),
    lines: const [
      SalesOrderLineDto(
        lineId: 'line-1',
        product: ProductSnapshotDto(
          productId: 'product-1',
          sku: 'SKU-1',
          displayName: 'Vaccine A',
        ),
        unit: ProductUnitSnapshotDto(
          productUnitId: 'unit-1',
          unitCode: 'VIAL',
          unitName: 'Lọ',
        ),
        quantity: QuantityDto(quantityMicros: QuantityDto.scale),
        unitPrice: MoneyDto(amountMinor: 1250000, currencyCode: 'VND'),
        lineTotal: MoneyDto(amountMinor: 1250000, currencyCode: 'VND'),
      ),
    ],
    orderNote: orderNote,
    currentReceiptId: 'receipt-1',
    currentLines: currentLines,
  );
}

/// Dữ liệu đơn thay đổi theo từng test; mỗi fake repository đọc lại trạng thái này khi được gọi.
final class _DetailRepos {
  _DetailRepos({required this.detail}) {
    orders = _OrderRepo(this);
    payments = _PaymentRepo(this);
    receipts = _ReceiptRepo(this);
    cancellations = _CancellationRepo(this);
    returnExchange = _ReturnExchangeRepo(this);
  }

  SalesOrderDetailDto detail;
  Object? error;
  Object? getReceiptError;
  Object? actionsError;
  Object? precheckError;
  Object? paymentError;
  int paidTotalMinor = 1000000;
  bool cancelAllowed = true;
  bool returnAllowed = true;
  List<ReturnExchangeSummaryDto> returns = const [];

  late final _OrderRepo orders;
  late final _PaymentRepo payments;
  late final _ReceiptRepo receipts;
  late final _CancellationRepo cancellations;
  late final _ReturnExchangeRepo returnExchange;

  /// Tổng số lần đọc (query) đã gọi qua mọi repository.
  int get queryCount =>
      orders.detailCalls.length +
      orders.timelineCalls.length +
      orders.returnSummaryCalls.length +
      orders.actionsCalls.length +
      orders.cancellationCalls.length +
      receipts.originalCalls.length +
      payments.summaryCalls.length +
      payments.settlementCalls.length +
      payments.transactionsCalls.length +
      receipts.getCalls.length +
      cancellations.precheckCalls.length +
      returnExchange.precheckCalls.length;
}

final class _OrderRepo extends FakeSalesOrderRepository {
  _OrderRepo(this.s);
  final _DetailRepos s;

  @override
  SalesOrderDetailDto? get detailResult => s.detail;
  @override
  Object? get detailError => s.error;

  @override
  SalesOrderTimelineDto? get timelineResult => SalesOrderTimelineDto(
    salesOrderId: s.detail.order.salesOrderId,
    entries: [
      SalesOrderTimelineEntryDto(
        eventId: 'event-1',
        eventType: 'sales_order_confirmed',
        occurredAt: s.detail.committedAt,
        sourceVersion: s.detail.order.version,
        actor: s.detail.seller,
        description: 'Xác nhận đơn hàng',
        amount: s.detail.order.total,
      ),
    ],
  );
  @override
  Object? get timelineError => s.error;

  @override
  SalesOrderReturnSummaryDto? get returnSummaryResult => SalesOrderReturnSummaryDto(
    salesOrderId: s.detail.order.salesOrderId,
    returns: s.returns,
  );
  @override
  Object? get returnSummaryError => s.error;

  @override
  AvailablePostSaleActionsDto? get actionsResult => AvailablePostSaleActionsDto(
    canCancel: s.detail.order.lifecycleStatus == SalesOrderLifecycleStatus.completed,
    canReturnExchange: s.detail.order.lifecycleStatus == SalesOrderLifecycleStatus.completed,
  );
  @override
  Object? get actionsError => s.error ?? s.actionsError;
}

final class _PaymentRepo extends FakeSalesPaymentRepository {
  _PaymentRepo(this.s) {
    recordResult = const SalesRecordPaymentResult(
      transactionId: 'tx-recorded',
      outstandingMinor: 0,
      paymentStatus: 'paid',
      version: 2,
    );
  }
  final _DetailRepos s;

  @override
  SalesOrderPaymentSummaryDto? get summaryResult {
    final outstandingMinor = s.detail.order.total.amountMinor - s.paidTotalMinor;
    return SalesOrderPaymentSummaryDto(
      status: SalesSettlementStatus.partiallyPaid,
      orderTotal: s.detail.order.total,
      paidTotal: MoneyDto(amountMinor: s.paidTotalMinor, currencyCode: 'VND'),
      outstandingTotal: MoneyDto(
        amountMinor: outstandingMinor > 0 ? outstandingMinor : 0,
        currencyCode: 'VND',
      ),
      dueAt: DateTime.utc(2026, 8, 30),
    );
  }
  @override
  Object? get summaryError => s.error ?? s.paymentError;

  @override
  SalesOrderSettlementDto? get settlementResult => SalesOrderSettlementDto(
    settlementId: 'settlement-1',
    salesOrderId: s.detail.order.salesOrderId,
    version: s.detail.order.version,
    status: SalesSettlementStatus.partiallyPaid,
    orderTotal: s.detail.order.total,
    paidTotal: const MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
    refundedTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    outstanding: const MoneyDto(amountMinor: 250000, currencyCode: 'VND'),
  );
  @override
  Object? get settlementError => s.error;

  @override
  SalesPaymentTransactionsDto? get transactionsResult => SalesPaymentTransactionsDto(
    page: OpaqueCursorPageDto<SalesPaymentTransactionDto>(
      items: [
        SalesPaymentTransactionDto(
          transactionId: 'tx-cash',
          method: SalesPaymentMethod.cash,
          amount: const MoneyDto(amountMinor: 400000, currencyCode: 'VND'),
          status: SalesPaymentStatus.confirmed,
          recordedAt: s.detail.committedAt,
        ),
        SalesPaymentTransactionDto(
          transactionId: 'tx-bank',
          method: SalesPaymentMethod.manualBankTransfer,
          amount: const MoneyDto(amountMinor: 600000, currencyCode: 'VND'),
          status: SalesPaymentStatus.confirmed,
          recordedAt: s.detail.committedAt,
        ),
      ],
      hasMore: false,
    ),
  );
  @override
  Object? get transactionsError => s.error;
}

final class _ReceiptRepo extends FakeSalesReceiptRepository {
  _ReceiptRepo(this.s);
  final _DetailRepos s;

  @override
  SalesReceiptDto? get getResult => SalesReceiptDto(
    receiptId: s.detail.currentReceiptId ?? 'receipt-1',
    salesOrderId: s.detail.order.salesOrderId,
    version: 1,
    status: SalesReceiptStatus.generated,
    generatedAt: s.detail.committedAt,
    document: SalesReceiptDocumentDto(
      receiptNumber: 'PBH-20260812-0129',
      orderNumber: s.detail.order.orderNumber,
      soldAt: s.detail.committedAt,
      store: s.detail.store,
      seller: s.detail.seller,
      lines: const <SalesReceiptLineDto>[],
      subtotal: s.detail.order.total,
      discountTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
      orderTotal: s.detail.order.total,
      paidTotal: const MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
      outstandingTotal: const MoneyDto(amountMinor: 250000, currencyCode: 'VND'),
      payments: const <PaymentIntentSummaryDto>[],
    ),
  );
  @override
  Object? get getError => s.error ?? s.getReceiptError;
}

final class _CancellationRepo extends FakeSalesCancellationRepository {
  _CancellationRepo(this.s);
  final _DetailRepos s;

  @override
  CancellationPrecheckDto? get precheckResult => CancellationPrecheckDto(
    allowed: s.cancelAllowed,
    sourceVersion: s.detail.order.version,
    sourceSettlementVersion: 1,
    blockers: s.cancelAllowed
        ? const []
        : const [
            SalesBlockerDto(
              code: 'CANCELLATION_BLOCKED',
              message: 'Đơn không cho phép hủy.',
            ),
          ],
  );
  @override
  Object? get precheckError => s.error ?? s.precheckError;

  @override
  SalesOrderCancellationResultDto? get confirmResult {
    final SalesOrderCancellationRequest request = confirmCalls.last;
    return SalesOrderCancellationResultDto(
      cancellationId: 'cancel-1',
      salesOrderId: request.salesOrderId,
      salesOrderVersion: s.detail.order.version + 1,
      status: SalesOrderCancellationStatus.confirmed,
    );
  }
}

final class _ReturnExchangeRepo extends FakeReturnExchangeRepository {
  _ReturnExchangeRepo(this.s);
  final _DetailRepos s;

  @override
  ReturnExchangePrecheckDto? get precheckResult => ReturnExchangePrecheckDto(
    allowed: s.returnAllowed,
    sourceVersion: s.detail.order.version,
    blockers: s.returnAllowed
        ? const []
        : const [
            SalesBlockerDto(
              code: 'RETURN_EXCHANGE_BLOCKED',
              message: 'Đơn không cho phép đổi/trả.',
            ),
          ],
  );
  @override
  Object? get precheckError => s.error ?? s.precheckError;
}
