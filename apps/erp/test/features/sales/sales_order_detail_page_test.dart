import 'package:erp/features/sales/data/return_exchange_repository.dart';
import 'package:erp/features/sales/data/sales_cancellation_repository.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/data/sales_payment_repository.dart';
import 'package:erp/features/sales/data/sales_receipt_repository.dart';
import 'support/module_backed_sales_repositories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_sales_application/application.dart';
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
  late _DetailSalesModule salesModule;

  setUp(() async {
    await GetIt.instance.reset();
    salesModule = _DetailSalesModule(detail: _detail());
    GetIt.instance.registerSingleton<ISalesModule>(salesModule);
    GetIt.instance.registerSingleton<SalesOrderRepository>(
      ModuleBackedSalesOrderRepository(salesModule),
    );
    GetIt.instance.registerSingleton<SalesReceiptRepository>(
      ModuleBackedSalesReceiptRepository(salesModule),
    );
    GetIt.instance.registerSingleton<SalesPaymentRepository>(
      ModuleBackedSalesPaymentRepository(salesModule),
    );
    GetIt.instance.registerSingleton<SalesCancellationRepository>(
      ModuleBackedSalesCancellationRepository(salesModule),
    );
    GetIt.instance.registerSingleton<ReturnExchangeRepository>(
      ModuleBackedReturnExchangeRepository(salesModule),
    );
    GetIt.instance.registerSingleton<IExecutionContext>(
      const TestExecutionContext(),
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
    expect(find.text('Xem công nợ'), findsOneWidget);
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
    salesModule.actionsError = const SalesContractException(
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

    final command = salesModule.commands.single as ConfirmSalesOrderCancellationCommand;

    expect(command.reason.reasonText, 'Khách đổi ý sau khi đặt');
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
      salesModule.queries.whereType<PrecheckSalesOrderCancellationQuery>(),
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
    salesModule.getReceiptError = const SalesContractException('PERMISSION_DENIED');

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
    salesModule.error = const SalesContractException('PERMISSION_DENIED');
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
    salesModule.error = const SalesContractException('NOT_FOUND');
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
    salesModule.error = const SalesContractException('TRANSPORT_ERROR', message: 'network down');
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
    salesModule.error = const SalesContractException('PROJECTION_PENDING');
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
      orderRepository: ModuleBackedSalesOrderRepository(salesModule),
      receiptRepository: ModuleBackedSalesReceiptRepository(salesModule),
      paymentRepository: ModuleBackedSalesPaymentRepository(salesModule),
      cancellationRepository: ModuleBackedSalesCancellationRepository(salesModule),
      returnExchangeRepository: ModuleBackedReturnExchangeRepository(salesModule),
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

final class _DetailSalesModule implements ISalesModule {
  _DetailSalesModule({required this.detail});

  SalesOrderDetailDto detail;
  Object? error;
  Object? getReceiptError;
  Object? actionsError;
  Object? precheckError;
  int paidTotalMinor = 1000000;
  bool cancelAllowed = true;
  bool returnAllowed = true;
  List<ReturnExchangeSummaryDto> returns = const [];
  final List<Object> queries = <Object>[];
  final List<ICommand<Object?>> commands = <ICommand<Object?>>[];

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    commands.add(command as ICommand<Object?>);
    if (command is ConfirmSalesOrderCancellationCommand) {
      final cancellationCommand = command as ConfirmSalesOrderCancellationCommand;
      return SalesOrderCancellationResultDto(
            cancellationId: 'cancel-1',
            salesOrderId: cancellationCommand.salesOrderId,
            salesOrderVersion: detail.order.version + 1,
            status: SalesOrderCancellationStatus.confirmed,
          )
          as TResult;
    }
    throw UnsupportedError('unexpected command ${command.runtimeType}');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    final failure = error;
    if (failure != null) throw failure;
    if (query is GetSalesOrderDetailQuery) {
      return detail as TResult;
    }
    if (query is GetSalesOrderPaymentSummaryQuery) {
      final outstandingMinor = detail.order.total.amountMinor - paidTotalMinor;
      return SalesOrderPaymentSummaryDto(
            status: SalesSettlementStatus.partiallyPaid,
            orderTotal: detail.order.total,
            paidTotal: MoneyDto(amountMinor: paidTotalMinor, currencyCode: 'VND'),
            outstandingTotal: MoneyDto(
              amountMinor: outstandingMinor > 0 ? outstandingMinor : 0,
              currencyCode: 'VND',
            ),
            dueAt: DateTime.utc(2026, 8, 30),
          )
          as TResult;
    }
    if (query is GetSalesOrderSettlementQuery) {
      return SalesOrderSettlementDto(
            settlementId: 'settlement-1',
            salesOrderId: detail.order.salesOrderId,
            version: detail.order.version,
            status: SalesSettlementStatus.partiallyPaid,
            orderTotal: detail.order.total,
            paidTotal: const MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
            refundedTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
            outstanding: const MoneyDto(amountMinor: 250000, currencyCode: 'VND'),
          )
          as TResult;
    }
    if (query is GetSalesOrderPaymentTransactionsQuery) {
      return SalesPaymentTransactionsDto(
            page: OpaqueCursorPageDto<SalesPaymentTransactionDto>(
              items: [
                SalesPaymentTransactionDto(
                  transactionId: 'tx-cash',
                  method: SalesPaymentMethod.cash,
                  amount: const MoneyDto(amountMinor: 400000, currencyCode: 'VND'),
                  status: SalesPaymentStatus.confirmed,
                  recordedAt: detail.committedAt,
                ),
                SalesPaymentTransactionDto(
                  transactionId: 'tx-bank',
                  method: SalesPaymentMethod.manualBankTransfer,
                  amount: const MoneyDto(amountMinor: 600000, currencyCode: 'VND'),
                  status: SalesPaymentStatus.confirmed,
                  recordedAt: detail.committedAt,
                ),
              ],
              hasMore: false,
            ),
          )
          as TResult;
    }
    if (query is GetSalesOrderTimelineQuery) {
      return SalesOrderTimelineDto(
            salesOrderId: detail.order.salesOrderId,
            entries: [
              SalesOrderTimelineEntryDto(
                eventId: 'event-1',
                eventType: 'sales_order_confirmed',
                occurredAt: detail.committedAt,
                sourceVersion: detail.order.version,
                actor: detail.seller,
                description: 'Xác nhận đơn hàng',
                amount: detail.order.total,
              ),
            ],
          )
          as TResult;
    }
    if (query is GetSalesOrderReturnSummaryQuery) {
      return SalesOrderReturnSummaryDto(
            salesOrderId: detail.order.salesOrderId,
            returns: returns,
          )
          as TResult;
    }
    if (query is GetAvailablePostSaleActionsQuery) {
      final failure = actionsError;
      if (failure != null) throw failure;
      return AvailablePostSaleActionsDto(
            canCancel: detail.order.lifecycleStatus == SalesOrderLifecycleStatus.completed,
            canReturnExchange: detail.order.lifecycleStatus == SalesOrderLifecycleStatus.completed,
          )
          as TResult;
    }
    if (query is PrecheckSalesOrderCancellationQuery) {
      final failure = precheckError;
      if (failure != null) throw failure;
      return CancellationPrecheckDto(
            allowed: cancelAllowed,
            sourceVersion: detail.order.version,
            sourceSettlementVersion: 1,
            blockers: cancelAllowed
                ? const []
                : const [
                    SalesBlockerDto(
                      code: 'CANCELLATION_BLOCKED',
                      message: 'Đơn không cho phép hủy.',
                    ),
                  ],
          )
          as TResult;
    }
    if (query is PrecheckReturnExchangeQuery) {
      final failure = precheckError;
      if (failure != null) throw failure;
      return ReturnExchangePrecheckDto(
            allowed: returnAllowed,
            sourceVersion: detail.order.version,
            blockers: returnAllowed
                ? const []
                : const [
                    SalesBlockerDto(
                      code: 'RETURN_EXCHANGE_BLOCKED',
                      message: 'Đơn không cho phép đổi/trả.',
                    ),
                  ],
          )
          as TResult;
    }
    if (query is GetSalesReceiptQuery) {
      final receiptFailure = getReceiptError;
      if (receiptFailure != null) throw receiptFailure;
      return SalesReceiptDto(
            receiptId: detail.currentReceiptId ?? 'receipt-1',
            salesOrderId: detail.order.salesOrderId,
            version: 1,
            status: SalesReceiptStatus.generated,
            generatedAt: detail.committedAt,
            document: SalesReceiptDocumentDto(
              receiptNumber: 'PBH-20260812-0129',
              orderNumber: detail.order.orderNumber,
              soldAt: detail.committedAt,
              store: detail.store,
              seller: detail.seller,
              lines: const <SalesReceiptLineDto>[],
              subtotal: detail.order.total,
              discountTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
              orderTotal: detail.order.total,
              paidTotal: const MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
              outstandingTotal: const MoneyDto(amountMinor: 250000, currencyCode: 'VND'),
              payments: const <PaymentIntentSummaryDto>[],
            ),
          )
          as TResult;
    }
    throw UnsupportedError('unexpected query ${query.runtimeType}');
  }
}
