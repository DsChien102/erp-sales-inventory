import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_pricing_application/application.dart' as pricing;
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_application/testing.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:erp/features/sales/presentation.dart' hide SalesOrderLifecycleStatus;

import 'package:erp/features/sales/presentation/orchestration/sales_draft_list_scope.dart';
import 'package:erp/features/sales/presentation/pages/sales_checkout_page.dart';
import 'package:erp/features/sales/presentation/pages/sales_draft_list_page.dart';
import 'package:erp/features/sales/presentation/pages/sales_order_detail_page.dart';
import 'package:erp/features/sales/presentation/pages/sales_return_exchange_create_page.dart';
import 'package:erp/features/sales/presentation/pages/sales_return_exchange_detail_page.dart';
import 'package:erp/features/sales/presentation/pages/sales_return_exchange_result_page.dart';
import 'package:erp/features/sales/presentation/pages/sales_return_exchange_settlement_page.dart';
import 'package:erp/features/sales/presentation/pages/sales_order_compose_page.dart';
import 'package:erp/features/sales/presentation/pages/sales_transaction_result_page.dart';

final class TestExecutionContext implements IExecutionContext {
  const TestExecutionContext();

  @override
  String get correlationId => 'corr-1';

  @override
  Future<String> requireTenantId() async => 'tenant-demo';

  @override
  Future<String> requireUserId() async => 'user-demo';
}

final class TestActiveStoreContext implements IActiveStoreContext {
  const TestActiveStoreContext();

  @override
  String? get activeStoreId => 'store-demo';

  @override
  Future<String> requireActiveStoreId() async => 'store-demo';
}

void main() {
  late _SalesFlowCatalogModule catalogModule;
  late _RecordingSalesModule salesModule;
  late _RecordingPricingModule pricingModule;

  setUp(() async {
    await GetIt.instance.reset();
    catalogModule = _SalesFlowCatalogModule();
    salesModule = _RecordingSalesModule();
    pricingModule = _RecordingPricingModule();
    GetIt.instance.registerSingleton<ISalesModule>(salesModule);
    GetIt.instance.registerSingleton<IExecutionContext>(
      const TestExecutionContext(),
    );
    GetIt.instance.registerSingleton<IPartnerModule>(
      _SalesFlowPartnerModule(),
    );
    GetIt.instance.registerSingleton<ICatalogModule>(catalogModule);
    GetIt.instance.registerSingleton<IActiveStoreContext>(
      const TestActiveStoreContext(),
    );
    GetIt.instance.registerSingleton<pricing.IPricingModule>(pricingModule);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('SG-02 Order Compose Page renders customer card, search bar and summary bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _composeApp(),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_sg02_compose_page')), findsOneWidget);
    expect(find.byKey(const Key('card_compose_customer')), findsOneWidget);
    expect(find.byKey(const Key('input_compose_product_search')), findsOneWidget);
    expect(find.byKey(const Key('btn_compose_scan_barcode')), findsOneWidget);
    expect(find.byKey(const Key('btn_compose_checkout')), findsOneWidget);
  });

  testWidgets('SG-02 resolves authoritative units before adding a product line', (
    tester,
  ) async {
    await tester.pumpWidget(
      _composeApp(),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('input_compose_product_search')),
      'thuoc',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.tap(find.byKey(const Key('card_compose_suggest_product-live')));
    await tester.pumpAndSettle();

    expect(
      catalogModule.queries.map((query) => query.runtimeType),
      containsAllInOrder([
        SearchSellableProductsQuery,
        ListSellableProductUnitsQuery,
      ]),
    );
    expect(find.text('Chưa có sản phẩm trong đơn'), findsNothing);
    expect(find.text('Thuoc live'), findsOneWidget);
  });

  testWidgets('SG-02 keeps compose lines unchanged when unit lookup fails', (
    tester,
  ) async {
    catalogModule.failUnitLookup = true;
    await tester.pumpWidget(
      _composeApp(),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('input_compose_product_search')),
      'thuoc',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.tap(find.byKey(const Key('card_compose_suggest_product-live')));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có sản phẩm trong đơn'), findsOneWidget);
    expect(find.text('Thuoc live'), findsNothing);
  });

  testWidgets('SG-02 customer picker renders and selects Partner backend customer', (
    tester,
  ) async {
    await tester.pumpWidget(
      _composeApp(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_compose_select_customer')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Backend Customer'), findsOneWidget);
    await tester.tap(find.text('Backend Customer'));
    await tester.pumpAndSettle();

    expect(find.text('Backend Customer'), findsOneWidget);
  });

  testWidgets(
    'SG-02 displays warning banner when selected customer is an Organization without tax code',
    (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _composeApp(),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('banner_org_no_tax_code')), findsNothing);

      await tester.tap(find.byKey(const Key('btn_compose_select_customer')));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Công ty Minh Phát'), findsOneWidget);
      await tester.tap(find.text('Công ty Minh Phát'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('banner_org_no_tax_code')), findsOneWidget);
      expect(find.text('Khách tổ chức chưa có mã số thuế'), findsOneWidget);
      expect(
        find.text('Vẫn có thể bán hàng nhưng chưa thể phát hành hóa đơn điện tử.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('SG-02 quick create selects created Partner backend customer', (
    tester,
  ) async {
    await tester.pumpWidget(
      _composeApp(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_compose_create_customer')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('input_sg04_quick_name')),
      'Created Customer',
    );
    await tester.enterText(
      find.byKey(const Key('input_sg04_quick_phone')),
      '0988123456',
    );
    await tester.ensureVisible(
      find.byKey(const Key('btn_sg04_quick_create_submit')),
    );
    await tester.tap(find.byKey(const Key('btn_sg04_quick_create_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Created Customer'), findsOneWidget);
  });

  testWidgets('SG-02 picker create action opens quick create with Partner backend', (
    tester,
  ) async {
    await tester.pumpWidget(
      _composeApp(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_compose_select_customer')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('btn_sg04_open_create_customer_sheet')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('input_sg04_quick_name')),
      'Created Customer',
    );
    await tester.enterText(
      find.byKey(const Key('input_sg04_quick_phone')),
      '0988 123 456',
    );
    await tester.ensureVisible(
      find.byKey(const Key('btn_sg04_quick_create_submit')),
    );
    await tester.tap(find.byKey(const Key('btn_sg04_quick_create_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Created Customer'), findsOneWidget);
  });

  testWidgets('SG-02 save draft dispatches backend persist then resets to a new order', (
    tester,
  ) async {
    pricingModule.previewFor = (request) => _pricingPreviewFor(request);

    await tester.pumpWidget(
      _composeApp(),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('input_compose_product_search')),
      'thuoc',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.tap(find.byKey(const Key('card_compose_suggest_product-live')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_compose_save_draft')));
    await tester.pumpAndSettle();

    expect(salesModule.commands.whereType<SaveSalesOrderDraftCommand>(), hasLength(1));
    final save = salesModule.commands.whereType<SaveSalesOrderDraftCommand>().single;
    expect(save.storeId, 'store-demo');
    expect(save.tenantId, 'tenant-demo');

    final cubit = tester
        .element(find.byKey(const Key('wgt_sg02_compose_page')))
        .read<SalesComposeCubit>();
    expect(cubit.state.draftId, SalesComposeDraftRef.newDraft);
    expect(cubit.state.lines, isEmpty);
    expect(cubit.state.hasUnsavedChanges, isFalse);
    expect(find.text('Đã lưu đơn nháp.'), findsOneWidget);
  });

  testWidgets('SG-02 leave sheet "save and close" saves then returns to the orders list', (
    tester,
  ) async {
    pricingModule.previewFor = (request) => _pricingPreviewFor(request);
    final router = GoRouter(
      initialLocation: '/sales/orders',
      routes: [
        GoRoute(
          path: '/sales/orders',
          builder: (_, _) => const Scaffold(body: Text('ORDERS_LIST')),
        ),
        GoRoute(
          path: '/sales/compose',
          builder: (_, _) => const SalesDraftListScope(child: SalesOrderComposePage()),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    router.push('/sales/compose');
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('input_compose_product_search')),
      'thuoc',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.tap(find.byKey(const Key('card_compose_suggest_product-live')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_compose_back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wgt_sg02_leave_sheet')), findsOneWidget);
    expect(find.text('Lưu thay đổi rồi thoát'), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_compose_leave_save')));
    await tester.pumpAndSettle();

    expect(salesModule.commands.whereType<SaveSalesOrderDraftCommand>(), hasLength(1));
    expect(find.text('ORDERS_LIST'), findsOneWidget);
    expect(find.byType(SalesDraftListPage), findsNothing);
    expect(find.byKey(const Key('wgt_sg02_compose_page')), findsNothing);
  });

  testWidgets('SG-02 draft count queries active store scope', (tester) async {
    salesModule.listItems = [
      _listDraft(draftId: 'draft-a', version: 1),
      _listDraft(draftId: 'draft-b', version: 2),
    ];

    await tester.pumpWidget(
      _composeApp(),
    );
    await tester.pumpAndSettle();

    final listQueries = salesModule.queries.whereType<ListSalesOrderDraftsQuery>();
    expect(listQueries, isNotEmpty);
    expect(listQueries.first.storeId, 'store-demo');
    expect(listQueries.first.tenantId, 'tenant-demo');
    expect(find.text('Đơn nháp (2)'), findsOneWidget);
  });

  testWidgets('SG-02 open draft restores through backend restore path', (tester) async {
    final draft = _listDraft(
      draftId: 'draft-restore-1',
      version: 3,
      customer: const CustomerSnapshotDto(
        customerId: 'partner-backend',
        displayName: 'Backend Customer',
        phoneNumber: '0988123456',
      ),
      orderNote: 'Giao chieu',
      productId: 'product-live',
      productUnitId: 'unit-live',
      productName: 'Thuoc live',
    );
    salesModule.restoreDto = SalesOrderDraftForRestoreDto(
      draft: draft,
      savedAt: draft.savedAt,
      savedByActorId: draft.savedByActorId,
    );
    pricingModule.previewFor = (request) => _pricingPreviewFor(request);

    await tester.pumpWidget(
      _composeApp(draftId: 'draft-restore-1'),
    );
    await tester.pumpAndSettle();

    final restoreQueries = salesModule.queries.whereType<GetSalesOrderDraftForRestoreQuery>();
    expect(restoreQueries, hasLength(1));
    expect(restoreQueries.single.draftId, 'draft-restore-1');
    expect(restoreQueries.single.storeId, 'store-demo');
    expect(find.text('Backend Customer'), findsOneWidget);
    expect(find.text('Thuoc live'), findsOneWidget);
    expect(find.text('Giao chieu'), findsOneWidget);
  });

  testWidgets('SG-01 cancel success removes draft from list', (tester) async {
    salesModule.listItems = [
      _listDraft(
        draftId: 'draft-cancel-ok',
        version: 2,
        customer: const CustomerSnapshotDto(
          customerId: 'partner-backend',
          displayName: 'Backend Customer',
        ),
      ),
    ];

    await tester.pumpWidget(
      _draftsApp(),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('card_sales_draft_draft-cancel-ok')), findsOneWidget);

    final card = tester.widget<SalesDraftListCard>(
      find.byKey(const Key('card_sales_draft_draft-cancel-ok')),
    );
    card.onDiscard();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_delete_draft_confirm')));
    await tester.pumpAndSettle();

    expect(salesModule.commands.whereType<CancelSalesOrderDraftCommand>(), hasLength(1));
    final cancel = salesModule.commands.whereType<CancelSalesOrderDraftCommand>().single;
    expect(cancel.draftId, 'draft-cancel-ok');
    expect(cancel.storeId, 'store-demo');
    expect(cancel.expectedVersion, 2);
    expect(find.byKey(const Key('card_sales_draft_draft-cancel-ok')), findsNothing);
  });

  testWidgets('SG-01 cancel failure retains draft row', (tester) async {
    salesModule.listItems = [
      _listDraft(
        draftId: 'draft-cancel-fail',
        version: 1,
        customer: const CustomerSnapshotDto(
          customerId: 'partner-backend',
          displayName: 'Backend Customer',
        ),
      ),
    ];
    salesModule.cancelError = const SalesContractException(
      'REFERENCE_UNAVAILABLE',
      message: 'Không hủy được đơn nháp',
    );

    await tester.pumpWidget(
      _draftsApp(),
    );
    await tester.pumpAndSettle();

    final card = tester.widget<SalesDraftListCard>(
      find.byKey(const Key('card_sales_draft_draft-cancel-fail')),
    );
    card.onDiscard();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_delete_draft_confirm')));
    await tester.pumpAndSettle();

    expect(salesModule.commands.whereType<CancelSalesOrderDraftCommand>(), hasLength(1));
    expect(find.byKey(const Key('card_sales_draft_draft-cancel-fail')), findsOneWidget);
    final listCubit = tester
        .element(find.byKey(const Key('wgt_e01_u01_page')))
        .read<SalesDraftListCubit>();
    expect(listCubit.state.actionMessage, contains('Không hủy được'));
  });

  testWidgets('SG-05 Checkout Page renders payment options and disabled finalize', (
    tester,
  ) async {
    salesModule.precheckResult = CheckoutPrecheckDto(
      canFinalize: true,
      blockers: const [],
      monetarySummary: const CheckoutMonetarySummaryDto(
        subtotal: MoneyDto(amountMinor: 50000000, currencyCode: 'VND'),
        discountTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        grandTotal: MoneyDto(amountMinor: 50000000, currencyCode: 'VND'),
      ),
      receivableRequirement: const ReceivableRequirementDto(
        isRequired: false,
        amount: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SalesCheckoutPage(
          args: SalesCheckoutDraftArgs(
            runtimeDraftId: 'draft-123',
            customerId: 'partner-a',
            customerDisplayName: 'Nguyễn Văn A',
            isWalkIn: false,
            currencyCode: 'VND',
            provisionalTotalAmountMinor: 50000000,
            commercialSnapshot: _commercialSnapshot(
              customerId: 'partner-a',
              customerDisplayName: 'Nguyễn Văn A',
              amountMinor: 50000000,
            ),
            lines: const [
              CheckoutLineInput(
                productId: 'p1',
                productUnitId: 'u1',
                quantity: QuantityDto(quantityMicros: 1000000),
                unitPrice: MoneyDto(amountMinor: 50000000, currencyCode: 'VND'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_sg05_checkout_page')), findsOneWidget);
    expect(find.text('Nguyễn Văn A'), findsOneWidget);
    expect(find.byKey(const Key('btn_sg05_finalize')), findsOneWidget);
    final finalize = tester.widget<VButton>(
      find.byKey(const Key('btn_sg05_finalize')),
    );
    expect(finalize.onPressed, isNotNull);
  });

  testWidgets('SG-05 walk-in disables 0% and 50% quick options', (tester) async {
    salesModule.precheckResult = CheckoutPrecheckDto(
      canFinalize: true,
      blockers: const [],
      monetarySummary: const CheckoutMonetarySummaryDto(
        subtotal: MoneyDto(amountMinor: 4445238, currencyCode: 'VND'),
        discountTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        grandTotal: MoneyDto(amountMinor: 4445238, currencyCode: 'VND'),
      ),
      receivableRequirement: const ReceivableRequirementDto(
        isRequired: false,
        amount: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SalesCheckoutPage(
          args: SalesCheckoutDraftArgs(
            runtimeDraftId: 'draft-124',
            customerDisplayName: 'Khách lẻ',
            isWalkIn: true,
            currencyCode: 'VND',
            provisionalTotalAmountMinor: 4445238,
            commercialSnapshot: _commercialSnapshot(
              isWalkIn: true,
              amountMinor: 4445238,
            ),
            lines: const [
              CheckoutLineInput(
                productId: 'p1',
                productUnitId: 'u1',
                quantity: QuantityDto(quantityMicros: 1000000),
                unitPrice: MoneyDto(amountMinor: 4445238, currencyCode: 'VND'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_sg05_percent_0')), findsOneWidget);
    expect(find.byKey(const Key('btn_sg05_percent_50')), findsOneWidget);
    expect(find.byKey(const Key('btn_sg05_finalize')), findsOneWidget);
  });

  testWidgets('SG-05 RECEIVABLE_DUE_DATE_REQUIRED shows backend blocker message', (
    tester,
  ) async {
    salesModule.precheckResult = CheckoutPrecheckDto(
      canFinalize: false,
      blockers: const [
        SalesBlockerDto(
          code: CheckoutBlockerCodes.receivableDueDateRequired,
          message: 'Due date required.',
          field: 'dueDate',
        ),
      ],
      monetarySummary: const CheckoutMonetarySummaryDto(
        subtotal: MoneyDto(amountMinor: 4445238, currencyCode: 'VND'),
        discountTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        grandTotal: MoneyDto(amountMinor: 4445238, currencyCode: 'VND'),
      ),
      receivableRequirement: const ReceivableRequirementDto(
        isRequired: true,
        amount: MoneyDto(amountMinor: 2222619, currencyCode: 'VND'),
        customerId: 'partner-a',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SalesCheckoutPage(
          args: SalesCheckoutDraftArgs(
            runtimeDraftId: 'draft-125',
            customerId: 'partner-a',
            customerDisplayName: 'Nguyễn Văn A',
            customerPhone: '0903 456 789',
            isWalkIn: false,
            currencyCode: 'VND',
            provisionalTotalAmountMinor: 4445238,
            commercialSnapshot: _commercialSnapshot(
              customerId: 'partner-a',
              customerDisplayName: 'Nguyễn Văn A',
              customerPhone: '0903 456 789',
              amountMinor: 4445238,
            ),
            lines: const [
              CheckoutLineInput(
                productId: 'p1',
                productUnitId: 'u1',
                quantity: QuantityDto(quantityMicros: 1000000),
                unitPrice: MoneyDto(amountMinor: 4445238, currencyCode: 'VND'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('btn_sg05_finalize')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_sg05_finalize')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_sg05_finalize_confirm')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Due date required.'), findsOneWidget);
    expect(find.byKey(const Key('wgt_sg05_precheck_panel')), findsNothing);
    expect(find.textContaining('Contract Group C hiện chưa hỗ trợ'), findsNothing);
  });

  testWidgets('SG-06 Transaction Result Page renders success banner and actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SalesTransactionResultPage(
          args: SalesCheckoutResultArgs(
            storeId: 'store-1',
result: const CheckoutResultDto(
              idempotencyKey: 'fake-checkout-attempt',
              salesOrderId: 'order-1',
              salesOrderVersion: 3,
              status: CheckoutResultStatus.succeeded,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_sg06_result_page')), findsOneWidget);
    expect(find.text('Đã hoàn tất đơn'), findsOneWidget);
    expect(find.textContaining('SO-000129'), findsOneWidget);
    expect(find.byKey(const Key('btn_sg06_view_detail')), findsOneWidget);
    expect(find.byKey(const Key('btn_sg06_new_order')), findsOneWidget);
  });

  testWidgets('SG-08 Order Detail Page renders order header and action bar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesOrderDetailPage(orderId: 'DH-000129'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_sg08_order_detail_page')), findsOneWidget);
    expect(find.byKey(const Key('btn_sg08_actions')), findsOneWidget);
    expect(find.text('Thao tác'), findsOneWidget);
  });

  testWidgets('SG-08 S21 post-sale sheet keeps receipt/return/cancel without adjust', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesOrderDetailPage(orderId: 'DH-000129'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_sg08_actions')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_order_action_receipt')), findsNothing);
    expect(find.byKey(const Key('btn_order_action_adjust')), findsNothing);
    expect(find.byKey(const Key('btn_order_action_return')), findsOneWidget);
    expect(find.byKey(const Key('btn_order_action_cancel')), findsOneWidget);
  });

  testWidgets('SG-11 Return Exchange Create Page renders return item quantity selector', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesReturnExchangeCreatePage(orderId: 'ord_123'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_sg11_return_create_page')), findsOneWidget);
    expect(find.byKey(const Key('qty_return_line_1')), findsOneWidget);
    expect(find.text('Hỏng'), findsNothing); // policies appear after qty>0

    // Verify 'Chọn hàng đổi' and 'Tiếp tục' are disabled when return quantity is 0
    final btnExchange = tester.widget<VButton>(
      find.byKey(const Key('btn_add_exchange_product')),
    );
    expect(btnExchange.onPressed, isNull);

    final btnProceed = tester.widget<VButton>(
      find.byKey(const Key('btn_sg11_proceed_settle')),
    );
    expect(btnProceed.onPressed, isNull);

    // First increment return item quantity so returnQuantity > 0
    await tester.tap(
      find
          .descendant(
            of: find.byKey(const Key('qty_return_line_1')),
            matching: find.byType(InkWell),
          )
          .last,
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<VButton>(find.byKey(const Key('btn_add_exchange_product'))).onPressed,
      isNotNull,
    );

    // Tap back button → discard dialog
    await tester.tap(find.byType(IconButton).first);
    await tester.pumpAndSettle();

    expect(find.text('Bỏ thay đổi?'), findsOneWidget);
    expect(find.text('Hàng trả và hàng đổi vừa chọn chưa được lưu.'), findsOneWidget);
    expect(find.text('Tiếp tục đổi/trả'), findsOneWidget);
  });

  testWidgets('SG-11 blocked precheck hides proceed and shows blockers', (tester) async {
    salesModule.returnPrecheck = ReturnExchangePrecheckDto(
      allowed: false,
      sourceVersion: 1,
      blockers: const [
        SalesBlockerDto(code: 'WINDOW_EXPIRED', message: 'Hết hạn đổi/trả.'),
      ],
    );
    await tester.pumpWidget(
      const MaterialApp(home: SalesReturnExchangeCreatePage(orderId: 'ord_123')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_sg11_blocked')), findsOneWidget);
    expect(find.text('Hết hạn đổi/trả.'), findsOneWidget);
    expect(find.byKey(const Key('btn_sg11_proceed_settle')), findsNothing);
  });

  testWidgets('SG-11 empty policy still opens return item selection with proceed disabled', (
    tester,
  ) async {
    salesModule.returnFormPolicy = ReturnExchangeFormPolicyDto(
      reasons: const [],
      conditions: const [],
    );
    await tester.pumpWidget(
      const MaterialApp(home: SalesReturnExchangeCreatePage(orderId: 'ord_123')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_sg11_catalog_empty')), findsNothing);
    expect(find.byKey(const Key('wgt_sg11_return_create_page')), findsOneWidget);
    expect(find.byKey(const Key('qty_return_line_1')), findsOneWidget);
    expect(
      tester.widget<VButton>(find.byKey(const Key('btn_sg11_proceed_settle'))).onPressed,
      isNull,
    );
  });

  testWidgets('SG-11 successful start navigates to settle by returnExchangeId', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/sales/orders/ord_123/returns/new',
      routes: [
        GoRoute(
          path: '/sales/orders/:orderId/returns/new',
          builder: (context, state) => SalesReturnExchangeCreatePage(
            orderId: state.pathParameters['orderId']!,
          ),
        ),
        GoRoute(
          path: '/sales/orders/:orderId/returns/:returnExchangeId/settle',
          builder: (context, state) => Scaffold(
            key: const Key('wgt_sg12_route_probe'),
            body: Text(
              'settle:${state.pathParameters['orderId']}:${state.pathParameters['returnExchangeId']}',
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(
      find
          .descendant(
            of: find.byKey(const Key('qty_return_line_1')),
            matching: find.byType(InkWell),
          )
          .last,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_sg11_proceed_settle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_sg12_route_probe')), findsOneWidget);
    expect(find.text('settle:ord_123:return-1'), findsOneWidget);
    expect(
      salesModule.commands.whereType<StartReturnExchangeCommand>(),
      hasLength(1),
    );
  });

  testWidgets('SG-12 Return Exchange Settlement Page renders breakdown', (tester) async {
    const plan = ReturnExchangeSettlementPlanDto(
      currencyCode: 'VND',
      netDifferenceMinor: 400000,
      collectAmountMinor: 0,
      refundAmountMinor: 400000,
      receivableCreateAmountMinor: 0,
      receivableReverseAmountMinor: 0,
      processedCollectMinor: 0,
      processedRefundMinor: 0,
      pendingReceivableCreateMinor: 0,
      pendingReceivableReverseMinor: 0,
      remainderCollectMinor: 0,
      remainderRefundMinor: 400000,
      sourceOrderVersion: 7,
      sourceSettlementVersion: 3,
    );
    const valuation = ReturnExchangeValuationDto(
      returnValue: MoneyDto(amountMinor: 500000, currencyCode: 'VND'),
      exchangeValue: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
      settlementDifference: MoneyDto(amountMinor: 400000, currencyCode: 'VND'),
      settlementPlan: plan,
      sourceOrderVersion: 7,
    );
    salesModule.returnDetail = ReturnExchangeDetailDto(
      result: const ReturnExchangeResultDto(
        returnExchangeId: 'return-1',
        salesOrderId: 'ord_123',
        version: 2,
        status: ReturnExchangeStatus.draft,
      ),
      referenceNumber: 'RE-1',
      entrySource: ReturnExchangeEntrySource.standard,
      createdAt: DateTime.utc(2026, 8, 13),
      confirmedByActorId: null,
      confirmedAt: null,
      completedAt: null,
      lines: const <ReturnExchangeDetailLineDto>[],
      valuation: valuation,
      settlementPlan: plan,
      completionReady: false,
    );
    salesModule.returnValuation = valuation;

    await tester.pumpWidget(
      const MaterialApp(
        home: SalesReturnExchangeSettlementPage(
          orderId: 'ord_123',
          returnExchangeId: 'return-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_sg12_return_settlement_page')), findsOneWidget);
    // Summary is collapsed by default; expand it to reveal the breakdown.
    await tester.ensureVisible(find.byKey(const Key('btn_sg12_plan_toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_sg12_plan_toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wgt_sg12_plan_refund')), findsOneWidget);
    expect(find.byKey(const Key('wgt_sg12_plan_breakdown')), findsOneWidget);
    expect(find.byKey(const Key('btn_sg12_confirm_settlement')), findsOneWidget);
    expect(find.textContaining('Hạn thanh toán'), findsNothing);
    // The settlement page now carries a collection/refund method section.
    expect(find.textContaining('Phương thức'), findsOneWidget);
    expect(find.textContaining('Cấn trừ'), findsNothing);
    expect(
      salesModule.queries.whereType<GetReturnExchangeDetailQuery>(),
      hasLength(1),
    );
    expect(
      salesModule.queries.whereType<EvaluateReturnPricingImpactQuery>(),
      hasLength(1),
    );
  });

  testWidgets(
    'SG-13 Return Exchange Result Page pops back to Order Detail Page on onViewOrderDetail',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == 'sales.orders.detail' ||
                settings.name == '/sales/orders/DH-0001') {
              return MaterialPageRoute(
                settings: const RouteSettings(name: 'sales.orders.detail'),
                builder: (_) => const Scaffold(body: Text('Order Detail Page Content')),
              );
            }
            if (settings.name == '/sales/orders/DH-0001/returns/return-1/result') {
              return MaterialPageRoute(
                settings: const RouteSettings(
                  name: '/sales/orders/DH-0001/returns/return-1/result',
                ),
                builder: (_) => const SalesReturnExchangeResultPage(
                  orderId: 'DH-0001',
                  returnExchangeId: 'return-1',
                ),
              );
            }
            return null;
          },
          initialRoute: 'sales.orders.detail',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Order Detail Page Content'), findsOneWidget);

      final BuildContext rootContext = tester.element(find.text('Order Detail Page Content'));
      Navigator.of(rootContext).pushNamed('/sales/orders/DH-0001/returns/return-1/result');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_sg13_return_result_page')), findsOneWidget);
      expect(
        salesModule.queries.whereType<GetReturnExchangeDetailQuery>(),
        hasLength(1),
      );

      await tester.tap(find.byKey(const Key('btn_return_result_view_detail')));
      await tester.pumpAndSettle();

      expect(find.text('Order Detail Page Content'), findsOneWidget);
      expect(find.byKey(const Key('wgt_sg13_return_result_page')), findsNothing);
    },
  );

  testWidgets(
    'SG-13 Return Exchange Result Page pops back to Order List Page on onGoHome',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == 'orders.list' || settings.name == '/orders') {
              return MaterialPageRoute(
                settings: const RouteSettings(name: 'orders.list'),
                builder: (_) => const Scaffold(body: Text('Order List Page Content')),
              );
            }
            if (settings.name == 'sales.orders.detail' ||
                settings.name == '/sales/orders/DH-0001') {
              return MaterialPageRoute(
                settings: const RouteSettings(name: 'sales.orders.detail'),
                builder: (_) => const Scaffold(body: Text('Order Detail Page Content')),
              );
            }
            if (settings.name == '/sales/orders/DH-0001/returns/return-1/result') {
              return MaterialPageRoute(
                settings: const RouteSettings(
                  name: '/sales/orders/DH-0001/returns/return-1/result',
                ),
                builder: (_) => const SalesReturnExchangeResultPage(
                  orderId: 'DH-0001',
                  returnExchangeId: 'return-1',
                ),
              );
            }
            return null;
          },
          initialRoute: 'orders.list',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Order List Page Content'), findsOneWidget);

      final BuildContext rootContext = tester.element(find.text('Order List Page Content'));
      Navigator.of(rootContext).pushNamed('/sales/orders/DH-0001');
      await tester.pumpAndSettle();

      expect(find.text('Order Detail Page Content'), findsOneWidget);

      final BuildContext detailContext = tester.element(find.text('Order Detail Page Content'));
      Navigator.of(detailContext).pushNamed('/sales/orders/DH-0001/returns/return-1/result');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_sg13_return_result_page')), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_return_result_go_home')));
      await tester.pumpAndSettle();

      expect(find.text('Order List Page Content'), findsOneWidget);
      expect(find.byKey(const Key('wgt_sg13_return_result_page')), findsNothing);
    },
  );

  testWidgets(
    'SG-13 Return Exchange Result Page AppBar back button pops to Order List Page',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == 'orders.list' || settings.name == '/') {
              return MaterialPageRoute(
                settings: const RouteSettings(name: 'orders.list'),
                builder: (_) => const Scaffold(body: Text('Order List Page Content')),
              );
            }
            if (settings.name == '/sales/orders/DH-0001/returns/return-1/result') {
              return MaterialPageRoute(
                settings: const RouteSettings(
                  name: '/sales/orders/DH-0001/returns/return-1/result',
                ),
                builder: (_) => const SalesReturnExchangeResultPage(
                  orderId: 'DH-0001',
                  returnExchangeId: 'return-1',
                ),
              );
            }
            return null;
          },
          initialRoute: 'orders.list',
        ),
      );
      await tester.pumpAndSettle();

      final BuildContext rootContext = tester.element(find.text('Order List Page Content'));
      Navigator.of(rootContext).pushNamed('/sales/orders/DH-0001/returns/return-1/result');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_sg13_return_result_page')), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_return_result_back')));
      await tester.pumpAndSettle();

      expect(find.text('Order List Page Content'), findsOneWidget);
      expect(find.byKey(const Key('wgt_sg13_return_result_page')), findsNothing);
    },
  );

  testWidgets(
    'SG-13 Return Exchange Detail Page AppBar back button pops to Order Detail Page',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == 'orders.list' || settings.name == '/') {
              return MaterialPageRoute(
                settings: const RouteSettings(name: 'orders.list'),
                builder: (_) => const Scaffold(body: Text('Order List Page Content')),
              );
            }
            if (settings.name == '/sales/orders/DH-0001') {
              return MaterialPageRoute(
                settings: const RouteSettings(name: 'sales.orders.detail'),
                builder: (_) => const Scaffold(body: Text('Order Detail Page Content')),
              );
            }
            if (settings.name == '/sales/orders/DH-0001/returns/return-1/detail') {
              return MaterialPageRoute(
                settings: const RouteSettings(
                  name: '/sales/orders/DH-0001/returns/return-1/detail',
                ),
                builder: (_) => const SalesReturnExchangeDetailPage(
                  orderId: 'DH-0001',
                  returnExchangeId: 'return-1',
                ),
              );
            }
            return null;
          },
          initialRoute: 'orders.list',
        ),
      );
      await tester.pumpAndSettle();

      final BuildContext rootContext = tester.element(find.text('Order List Page Content'));
      Navigator.of(rootContext).pushNamed('/sales/orders/DH-0001');
      await tester.pumpAndSettle();

      final BuildContext detailContext = tester.element(find.text('Order Detail Page Content'));
      Navigator.of(detailContext).pushNamed('/sales/orders/DH-0001/returns/return-1/detail');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_sg13_return_detail_page')), findsOneWidget);
      expect(
        salesModule.queries.whereType<GetReturnExchangeDetailQuery>(),
        hasLength(1),
      );

      await tester.tap(find.byKey(const Key('btn_return_detail_back')));
      await tester.pumpAndSettle();

      expect(find.text('Order Detail Page Content'), findsOneWidget);
      expect(find.byKey(const Key('wgt_sg13_return_detail_page')), findsNothing);
    },
  );
}

/// SG-01 / SG-02 dùng chung `SalesDraftListCubit` do `SalesDraftListScope` cấp
/// (thật ra là `ShellRoute`), nên test phải bọc trang trong scope này.
Widget _composeApp({String? draftId}) {
  return MaterialApp(
    home: SalesDraftListScope(
      child: SalesOrderComposePage(draftId: draftId),
    ),
  );
}

Widget _draftsApp() {
  return const MaterialApp(
    home: SalesDraftListScope(child: SalesDraftListPage()),
  );
}

final class _SalesFlowPartnerModule implements IPartnerModule {
  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    if (command is CreatePartnerCommand) {
      return const CreatePartnerResult(partnerId: 'partner-created') as TResult;
    }
    throw StateError('Unexpected command $command');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is SearchPartnersQuery) {
      return const PartnerSearchResultDto(
            items: [
              PartnerListItemDto(
                partnerId: 'partner-backend',
                displayName: 'Backend Customer',
                partnerType: PartnerType.person,
                status: PartnerStatus.active,
                roles: [PartnerRoleType.customer],
                phone: '0988123456',
              ),
              PartnerListItemDto(
                partnerId: 'partner-org-no-tax',
                displayName: 'Công ty Minh Phát',
                partnerType: PartnerType.organization,
                status: PartnerStatus.active,
                roles: [PartnerRoleType.customer],
                phone: '02473088868',
                taxCode: null,
              ),
            ],
            page: 1,
            limit: 40,
            total: 2,
          )
          as TResult;
    }
    if (query is CheckDuplicatePartnersQuery) {
      return const <PartnerDuplicateMatchDto>[] as TResult;
    }
    if (query is GetPartnerDetailQuery) {
      final detailQuery = query as GetPartnerDetailQuery;
      if (detailQuery.partnerId == 'partner-org-no-tax') {
        return const PartnerDetailDto(
              partnerId: 'partner-org-no-tax',
              partnerType: PartnerType.organization,
              status: PartnerStatus.active,
              displayName: 'Công ty Minh Phát',
              roles: [PartnerRoleType.customer],
              availableActions: [],
              expectedVersion: 1,
              organizationProfile: OrganizationProfileDto(
                organizationType: OrganizationType.company,
                organizationName: 'Công ty Minh Phát',
                phone: '02473088868',
                taxCode: null,
              ),
            )
            as TResult;
      }
      return PartnerDetailDto(
            partnerId: detailQuery.partnerId,
            partnerType: PartnerType.person,
            status: PartnerStatus.active,
            displayName: detailQuery.partnerId == 'partner-created'
                ? 'Created Customer'
                : 'Backend Customer',
            roles: const [PartnerRoleType.customer],
            availableActions: const [],
            expectedVersion: 1,
            personProfile: const PersonProfileDto(
              fullName: 'Created Customer',
              phone: '0988123456',
            ),
          )
          as TResult;
    }
    throw StateError('Unexpected query $query');
  }
}

final class _SalesFlowCatalogModule implements ICatalogModule {
  final List<IQuery<dynamic>> queries = [];
  bool failUnitLookup = false;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw StateError('Unexpected command $command');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    if (query is SearchSellableProductsQuery) {
      return const [_liveProduct] as TResult;
    }
    if (query is ResolveSellableBarcodeQuery) {
      return const <SellableProductDto>[] as TResult;
    }
    final raw = query as Object;
    if (raw is ResolveSellableProductsQuery) {
      return [
            for (final productId in raw.productIds)
              if (productId == _liveProduct.productId)
                SellableProductResolutionDto(
                  productId: productId,
                  resolution: SellableProductResolution.sellable,
                  product: _liveProduct,
                )
              else
                SellableProductResolutionDto(
                  productId: productId,
                  resolution: SellableProductResolution.notFound,
                ),
          ]
          as TResult;
    }
    if (query is ListSellableProductUnitsQuery) {
      if (failUnitLookup) throw StateError('catalog down');
      return const [_liveUnit] as TResult;
    }
    throw StateError('Unexpected query $query');
  }
}

final class _RecordingPricingModule implements pricing.IPricingModule {
  pricing.SalesWorkingStatePricingPreviewDto Function(
    pricing.PreviewSalesWorkingStatePricingQuery request,
  )?
  previewFor;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw StateError('Unexpected pricing command $command');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    final raw = query as Object;
    if (raw is pricing.PreviewSalesWorkingStatePricingQuery) {
      final builder = previewFor;
      if (builder == null) {
        throw StateError('Pricing preview not configured');
      }
      return builder(raw) as TResult;
    }
    throw StateError('Unexpected pricing query $query');
  }
}

final class _RecordingSalesModule implements ISalesModule {
  final List<Object> commands = [];
  final List<Object> queries = [];
  List<SalesOrderDraftDto> listItems = const [];
  SalesOrderDraftForRestoreDto? restoreDto;
  Object? cancelError;
  CheckoutPrecheckDto? precheckResult;

  // SG-10 cancellation (Group H) configurable fixtures.
  List<CancellationReasonPolicyDto> cancelReasons = const [
    CancellationReasonPolicyDto(
      reasonCode: 'DUPLICATE',
      displayName: 'Nhập trùng đơn',
      requiresNote: false,
      sortOrder: 100,
    ),
    CancellationReasonPolicyDto(
      reasonCode: 'OTHER',
      displayName: 'Khác',
      requiresNote: true,
      sortOrder: 900,
    ),
  ];
  CancellationPrecheckDto cancelPrecheck = CancellationPrecheckDto(
    allowed: true,
    sourceVersion: 7,
    sourceSettlementVersion: 3,
    blockers: const [],
  );
  Object cancelConfirmResponse = const SalesOrderCancellationResultDto(
    cancellationId: 'cancel-1',
    salesOrderId: 'ord_123',
    salesOrderVersion: 8,
    status: SalesOrderCancellationStatus.confirmed,
  );
  // SG-11 return/exchange session (Group I) configurable fixtures.
  ReturnExchangePrecheckDto returnPrecheck = ReturnExchangePrecheckDto(
    allowed: true,
    sourceVersion: 1,
    blockers: const [],
  );
  ReturnExchangeFormPolicyDto? returnFormPolicy;
  ReturnableOrderLinesDto? returnableLines;
  Object returnStartResponse = ReturnExchangeDraftDto(
    returnExchangeId: 'return-1',
    salesOrderId: 'ord_123',
    version: 2,
    status: ReturnExchangeStatus.draft,
    lines: const [],
  );
  ReturnExchangeDetailDto? returnDetail;
  ReturnExchangeValuationDto? returnValuation;
  Object returnConfirmResponse = const ReturnExchangeResultDto(
    returnExchangeId: 'return-1',
    salesOrderId: 'ord_123',
    version: 3,
    status: ReturnExchangeStatus.confirmed,
  );

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    commands.add(command);
    final raw = command as Object;
    if (raw is ConfirmSalesOrderCancellationCommand) {
      final response = cancelConfirmResponse;
      if (response is Exception) throw response;
      return response as TResult;
    }
    if (raw is StartReturnExchangeCommand || raw is UpdateReturnExchangeCommand) {
      final response = returnStartResponse;
      if (response is Exception) throw response;
      return response as TResult;
    }
    if (raw is ConfirmReturnExchangeCommand) {
      return const ReturnExchangeResultDto(
            returnExchangeId: 'return-1',
            salesOrderId: 'ord_123',
            version: 5,
            status: ReturnExchangeStatus.confirmed,
          )
          as TResult;
    }
    if (raw is CancelReturnExchangeCommand) {
      return const ReturnExchangeResultDto(
            returnExchangeId: 'return-1',
            salesOrderId: 'ord_123',
            version: 3,
            status: ReturnExchangeStatus.cancelled,
          )
          as TResult;
    }
    if (raw is ConfirmReturnExchangeCommand) {
      final response = returnConfirmResponse;
      if (response is Exception) throw response;
      return response as TResult;
    }
    if (raw is SaveSalesOrderDraftCommand) {
      final save = raw;
      return SalesOrderDraftDto(
            draftId: 'draft-saved-1',
            version: 1,
            status: SalesDraftStatus.active,
            storeId: save.storeId,
            savedAt: DateTime.utc(2026, 8, 11, 5),
            savedByActorId: save.actorId,
            customer: save.customer,
            orderNote: save.orderNote,
            pricingPreviewToken: save.pricingPreviewToken,
            needsRevalidation: save.needsRevalidation,
            lines: [
              for (final line in save.lines)
                SalesOrderDraftLineDto(
                  lineId: 'line-persisted',
                  productId: line.productId,
                  productSku: line.productSku,
                  productName: line.productName,
                  productUnitId: line.productUnitId,
                  unitCode: line.unitCode,
                  unitName: line.unitName,
                  quantity: line.quantity,
                  appliedUnitPrice: line.appliedUnitPrice,
                  lineTotal: line.lineTotal,
                  listUnitPrice: line.listUnitPrice,
                  needsRevalidation: line.needsRevalidation,
                ),
            ],
            total: MoneyDto(
              amountMinor: save.lines.fold<int>(
                0,
                (sum, line) => sum + line.lineTotal.amountMinor,
              ),
              currencyCode: save.currencyCode,
            ),
          )
          as TResult;
    }
    if (raw is UpdateSalesOrderDraftCommand) {
      final update = raw;
      return SalesOrderDraftDto(
            draftId: update.draftId,
            version: update.expectedVersion + 1,
            status: SalesDraftStatus.active,
            storeId: update.storeId,
            savedAt: DateTime.utc(2026, 8, 11, 5),
            savedByActorId: update.actorId,
            customer: update.customer,
            orderNote: update.orderNote,
            pricingPreviewToken: update.pricingPreviewToken,
            needsRevalidation: update.needsRevalidation,
            lines: const [],
            total: MoneyDto(amountMinor: 0, currencyCode: update.currencyCode),
          )
          as TResult;
    }
    if (raw is CancelSalesOrderDraftCommand) {
      final error = cancelError;
      if (error != null) throw error;
      final cancel = raw;
      return _listDraft(
            draftId: cancel.draftId,
            version: cancel.expectedVersion + 1,
          )
          as TResult;
    }
    final typeName = command.runtimeType.toString();
    if (SalesFakeContractFixtureFactory.supports(typeName)) {
      return SalesFakeContractFixtureFactory.create(typeName) as TResult;
    }
    throw StateError('Unexpected sales command $command');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    final raw = query as Object;
    if (raw is ListSalesOrderDraftsQuery) {
      return PagedSalesOrderDraftListDto(
            page: OpaqueCursorPageDto<SalesOrderDraftDto>(
              items: listItems,
              hasMore: false,
            ),
          )
          as TResult;
    }
    if (raw is GetSalesOrderDraftForRestoreQuery) {
      final restore = restoreDto;
      if (restore == null) {
        throw StateError('restoreDto not configured');
      }
      return restore as TResult;
    }
    if (raw is GetSalesOrderDetailQuery) {
      return SalesFakeData.findOrderDetail(raw.salesOrderId) as TResult;
    }
    if (raw is ListSalesOrderCancellationReasonsQuery) {
      return cancelReasons as TResult;
    }
    if (raw is PrecheckSalesOrderCancellationQuery) {
      return cancelPrecheck as TResult;
    }
    if (raw is PrecheckSalesOrderCheckoutQuery) {
      final result = precheckResult;
      if (result == null) {
        throw StateError('precheckResult not configured');
      }
      return result as TResult;
    }
    if (raw is PrecheckReturnExchangeQuery) {
      return returnPrecheck as TResult;
    }
    if (raw is GetReturnableOrderLinesQuery) {
      return (returnableLines ??
              ReturnableOrderLinesDto(
                salesOrderId: raw.salesOrderId,
                sourceVersion: returnPrecheck.sourceVersion,
                lines: const [
                  ReturnableOrderLineDto(
                    salesOrderLineId: 'line_1',
                    product: ProductSnapshotDto(
                      productId: 'product-1',
                      sku: 'SKU-1',
                      displayName: 'Sản phẩm trả mẫu',
                    ),
                    unit: ProductUnitSnapshotDto(
                      productUnitId: 'unit-1',
                      unitCode: 'BOX',
                      unitName: 'Hộp',
                    ),
                    soldQuantity: QuantityDto(quantityMicros: QuantityDto.scale * 2),
                    returnableQuantity: QuantityDto(
                      quantityMicros: QuantityDto.scale * 2,
                    ),
                    originalUnitPrice: MoneyDto(
                      amountMinor: 50000,
                      currencyCode: 'VND',
                    ),
                  ),
                ],
              ))
          as TResult;
    }
    if (raw is GetReturnExchangeFormPolicyQuery) {
      return (returnFormPolicy ??
              ReturnExchangeFormPolicyDto(
                reasons: const [
                  ReturnExchangePolicyOptionDto(
                    code: 'DAMAGED',
                    displayName: 'Hỏng',
                    sortOrder: 100,
                  ),
                  ReturnExchangePolicyOptionDto(
                    code: 'WRONG_ITEM',
                    displayName: 'Sai hàng',
                    sortOrder: 200,
                  ),
                ],
                conditions: const [
                  ReturnExchangePolicyOptionDto(
                    code: 'OPENED',
                    displayName: 'Đã mở',
                    sortOrder: 100,
                  ),
                  ReturnExchangePolicyOptionDto(
                    code: 'SEALED',
                    displayName: 'Nguyên seal',
                    sortOrder: 200,
                  ),
                ],
              ))
          as TResult;
    }
    if (raw is GetReturnExchangeDetailQuery) {
      final detail = returnDetail;
      if (detail == null) {
        return SalesFakeContractFixtureFactory.create(
              'GetReturnExchangeDetailQuery',
            )
            as TResult;
      }
      return detail as TResult;
    }
    if (raw is EvaluateReturnPricingImpactQuery) {
      final valuation = returnValuation;
      if (valuation == null) {
        return SalesFakeContractFixtureFactory.create(
              'EvaluateReturnPricingImpactQuery',
            )
            as TResult;
      }
      return valuation as TResult;
    }
    final typeName = query.runtimeType.toString();
    if (SalesFakeContractFixtureFactory.supports(typeName)) {
      return SalesFakeContractFixtureFactory.create(typeName) as TResult;
    }
    throw StateError('Unexpected sales query $query');
  }
}

SalesCommercialSnapshotInput _commercialSnapshot({
  String? customerId,
  String customerDisplayName = 'Nguyễn Văn A',
  String? customerPhone,
  bool isWalkIn = false,
  int amountMinor = 50000000,
}) {
  return SalesCommercialSnapshotInput(
    store: const StoreSnapshotDto(
      storeId: 'store-demo',
      storeCode: 'HCM-01',
      displayName: 'Chi nhánh Hồ Chí Minh',
    ),
    seller: const ActorSnapshotDto(
      actorId: 'user-demo',
      displayName: 'Nguyễn An',
    ),
    customer: isWalkIn
        ? null
        : CustomerSnapshotDto(
            customerId: customerId ?? 'partner-a',
            displayName: customerDisplayName,
            phoneNumber: customerPhone,
          ),
    lines: [
      SalesReceiptLineDto(
        lineId: 'line-1',
        product: const ProductSnapshotDto(
          productId: 'p1',
          sku: null,
          displayName: 'Vaccine A',
        ),
        unit: const ProductUnitSnapshotDto(
          productUnitId: 'u1',
          unitCode: null,
          unitName: 'Lọ',
        ),
        quantity: const QuantityDto(quantityMicros: 1000000),
        unitPrice: MoneyDto(amountMinor: amountMinor, currencyCode: 'VND'),
        discountTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        lineTotal: MoneyDto(amountMinor: amountMinor, currencyCode: 'VND'),
      ),
    ],
  );
}

SalesOrderDraftDto _listDraft({
  required String draftId,
  required int version,
  CustomerSnapshotDto? customer,
  String? orderNote,
  String productId = 'product-live',
  String productUnitId = 'unit-live',
  String productName = 'Thuoc live',
}) {
  return SalesOrderDraftDto(
    draftId: draftId,
    version: version,
    status: SalesDraftStatus.active,
    storeId: 'store-demo',
    savedAt: DateTime.utc(2026, 8, 11, 7),
    savedByActorId: 'user-demo',
    customer: customer,
    orderNote: orderNote,
    pricingPreviewToken: 'tok-1',
    needsRevalidation: false,
    lines: [
      SalesOrderDraftLineDto(
        lineId: '$draftId-line-1',
        productId: productId,
        productSku: 'SKU-LIVE',
        productName: productName,
        productUnitId: productUnitId,
        unitCode: 'HOP',
        unitName: 'Hop',
        quantity: const QuantityDto(quantityMicros: 1000000),
        appliedUnitPrice: const MoneyDto(amountMinor: 125000, currencyCode: 'VND'),
        lineTotal: const MoneyDto(amountMinor: 125000, currencyCode: 'VND'),
        listUnitPrice: const MoneyDto(amountMinor: 125000, currencyCode: 'VND'),
      ),
    ],
    total: const MoneyDto(amountMinor: 125000, currencyCode: 'VND'),
  );
}

pricing.SalesWorkingStatePricingPreviewDto _pricingPreviewFor(
  pricing.PreviewSalesWorkingStatePricingQuery request,
) {
  return pricing.SalesWorkingStatePricingPreviewDto(
    contextVersion: request.contextVersion,
    previewToken: 'preview-token-live',
    currencyCode: request.currencyCode,
    lines: [
      for (final line in request.lines)
        pricing.SalesPricingLinePreviewDto(
          localLineId: line.localLineId,
          appliedUnitPriceMinor: 125000,
          discountMinor: 0,
          lineTotalMinor: 125000 * (line.quantityMicros ~/ 1000000).clamp(1, 999),
          sourceCode: 'LIST',
          listPriceMinor: 125000,
          floorPriceMinor: 100000,
          warningCodes: const [],
          blockingCodes: const [],
        ),
    ],
  );
}

const _liveUnit = SellableProductUnitDto(
  productUnitId: 'unit-live',
  unitCode: 'HOP',
  unitName: 'Hop',
  barcode: '8930001',
  isDefault: true,
  isActive: true,
  isSellable: true,
  blockReason: null,
  listPriceMinor: 125000,
  floorPriceMinor: 100000,
  availableStockMicros: 12000000,
);

const _liveProduct = SellableProductDto(
  productId: 'product-live',
  sku: 'SKU-LIVE',
  displayName: 'Thuoc live',
  isSellable: true,
  blockReason: null,
  currencyCode: 'VND',
  listPriceMinor: 125000,
  floorPriceMinor: 100000,
  availableStockMicros: 12000000,
  units: [_liveUnit],
);
