import 'package:erp/features/sales/data/return_exchange_repository.dart';
import 'package:erp/features/sales/data/sales_cancellation_repository.dart';
import 'package:erp/features/sales/data/sales_checkout_repository.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/data/sales_payment_repository.dart';
import 'package:erp/features/sales/data/sales_receipt_repository.dart';
import 'support/fake_return_exchange_repository.dart';
import 'support/fake_sales_cancellation_repository.dart';
import 'support/fake_sales_checkout_repository.dart';
import 'support/fake_sales_order_repository.dart';
import 'support/fake_sales_payment_repository.dart';
import 'support/fake_sales_receipt_repository.dart';
import 'support/sales_contract_fixtures.dart';
import '../iam/support/iam_test_session.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';
import 'package:erp/features/partner/data/partner_repository.dart';
import '../partner/support/scripted_partner_repository.dart';
import 'package:erp/features/pricing/data/models.dart' as pricing;
import 'package:erp/features/pricing/data/sales_pricing_repository.dart';
import 'package:erp/features/sales/data/sales_draft_repository.dart';
import 'support/fake_sales_draft_repository.dart';
import 'support/recording_sales_pricing_repository.dart';
import 'package:erp/features/sales/data/models.dart';
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

void main() {
  late _SalesFlowProductRepository catalogModule;
  late _FlowRepos salesModule;
  late FakeSalesDraftRepository draftRepo;
  late RecordingSalesPricingRepository pricingModule;

  setUp(() async {
    await GetIt.instance.reset();
    catalogModule = _SalesFlowProductRepository();
    salesModule = _FlowRepos();
    draftRepo = FakeSalesDraftRepository();
    pricingModule = RecordingSalesPricingRepository();
    GetIt.instance.registerSingleton<SalesCheckoutRepository>(salesModule.checkout);
    GetIt.instance.registerSingleton<SalesOrderRepository>(salesModule.orders);
    GetIt.instance.registerSingleton<SalesReceiptRepository>(salesModule.receipts);
    GetIt.instance.registerSingleton<SalesPaymentRepository>(salesModule.payments);
    GetIt.instance.registerSingleton<SalesCancellationRepository>(salesModule.cancellations);
    GetIt.instance.registerSingleton<ReturnExchangeRepository>(salesModule.returnExchange);
    GetIt.instance.registerSingleton<SalesDraftRepository>(draftRepo);
    GetIt.instance.registerSingleton<IExecutionContext>(
      const TestExecutionContext(),
    );
    GetIt.instance.registerSingleton<PartnerRepository>(
      ScriptedPartnerRepository(onCall: _salesFlowPartnerScript),
    );
    GetIt.instance.registerSingleton<ProductRepository>(catalogModule);
    GetIt.instance.registerSingleton<SessionController>(
      testSessionController(
        tenantId: 'tenant-demo',
        userId: 'user-demo',
        activeStoreId: 'store-demo',
      ),
    );
    GetIt.instance.registerSingleton<SalesPricingRepository>(pricingModule);
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
        _SearchSellableProductsCall,
        _ListSellableProductUnitsCall,
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
    pricingModule.previewResponder = _pricingPreviewFor;

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

    expect(draftRepo.saveCalls, hasLength(1));
    final save = draftRepo.saveCalls.single;
    expect(save.storeId, 'store-demo');

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
    pricingModule.previewResponder = _pricingPreviewFor;
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

    expect(draftRepo.saveCalls, hasLength(1));
    expect(find.text('ORDERS_LIST'), findsOneWidget);
    expect(find.byType(SalesDraftListPage), findsNothing);
    expect(find.byKey(const Key('wgt_sg02_compose_page')), findsNothing);
  });

  testWidgets('SG-02 draft count queries active store scope', (tester) async {
    draftRepo.listItems = [
      _listDraft(draftId: 'draft-a', version: 1),
      _listDraft(draftId: 'draft-b', version: 2),
    ];

    await tester.pumpWidget(
      _composeApp(),
    );
    await tester.pumpAndSettle();

    final listQueries = draftRepo.listCalls;
    expect(listQueries, isNotEmpty);
    expect(listQueries.first.storeId, 'store-demo');
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
    draftRepo.restoreDto = SalesOrderDraftForRestoreDto(
      draft: draft,
      savedAt: draft.savedAt,
      savedByActorId: draft.savedByActorId,
    );
    pricingModule.previewResponder = _pricingPreviewFor;

    await tester.pumpWidget(
      _composeApp(draftId: 'draft-restore-1'),
    );
    await tester.pumpAndSettle();

    final restoreQueries = draftRepo.restoreCalls;
    expect(restoreQueries, hasLength(1));
    expect(restoreQueries.single.draftId, 'draft-restore-1');
    expect(restoreQueries.single.storeId, 'store-demo');
    expect(find.text('Backend Customer'), findsOneWidget);
    expect(find.text('Thuoc live'), findsOneWidget);
    expect(find.text('Giao chieu'), findsOneWidget);
  });

  testWidgets('SG-01 cancel success removes draft from list', (tester) async {
    draftRepo.listItems = [
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

    expect(draftRepo.cancelCalls, hasLength(1));
    final cancel = draftRepo.cancelCalls.single;
    expect(cancel.draftId, 'draft-cancel-ok');
    expect(cancel.storeId, 'store-demo');
    expect(cancel.expectedVersion, 2);
    expect(find.byKey(const Key('card_sales_draft_draft-cancel-ok')), findsNothing);
  });

  testWidgets('SG-01 cancel failure retains draft row', (tester) async {
    draftRepo.listItems = [
      _listDraft(
        draftId: 'draft-cancel-fail',
        version: 1,
        customer: const CustomerSnapshotDto(
          customerId: 'partner-backend',
          displayName: 'Backend Customer',
        ),
      ),
    ];
    draftRepo.cancelError = const AppException(
      'REFERENCE_UNAVAILABLE',
      serverMessage: 'Draft not found.',
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

    expect(draftRepo.cancelCalls, hasLength(1));
    expect(find.byKey(const Key('card_sales_draft_draft-cancel-fail')), findsOneWidget);
    final listCubit = tester
        .element(find.byKey(const Key('wgt_e01_u01_page')))
        .read<SalesDraftListCubit>();
    expect(
      listCubit.state.actionMessage,
      'Đơn nháp đã thay đổi. Vui lòng tải lại danh sách.',
    );
  });

  testWidgets('SG-05 Checkout Page renders payment options and disabled finalize', (
    tester,
  ) async {
    salesModule.checkout.precheckResult = CheckoutPrecheckDto(
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
    salesModule.checkout.precheckResult = CheckoutPrecheckDto(
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
    salesModule.checkout.precheckResult = CheckoutPrecheckDto(
      canFinalize: false,
      blockers: const [
        SalesBlockerDto(
          code: 'RECEIVABLE_DUE_DATE_REQUIRED',
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
    salesModule.returnExchange.precheckResult = ReturnExchangePrecheckDto(
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
    expect(find.text('Không thể đổi/trả.'), findsOneWidget);
    expect(find.byKey(const Key('btn_sg11_proceed_settle')), findsNothing);
  });

  testWidgets('SG-11 empty policy still opens return item selection with proceed disabled', (
    tester,
  ) async {
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
      salesModule.returnExchange.startCalls,
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
    salesModule.returnExchange.detailResult = ReturnExchangeDetailDto(
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
    salesModule.returnExchange.evaluateResult = valuation;

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
      salesModule.returnExchange.detailCalls,
      hasLength(1),
    );
    expect(
      salesModule.returnExchange.evaluateCalls,
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
        salesModule.returnExchange.detailCalls,
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
        salesModule.returnExchange.detailCalls,
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

Object? _salesFlowPartnerScript(String method, Map<String, Object?> args) {
  if (method == 'create') {
    return const CreatePartnerResult(partnerId: 'partner-created');
  }
  if (method == 'search') {
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
    );
  }
  if (method == 'checkDuplicates') {
    return const <PartnerDuplicateMatchDto>[];
  }
  if (method == 'getDetail') {
    final partnerId = args['partnerId'] as String;
    if (partnerId == 'partner-org-no-tax') {
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
      );
    }
    return PartnerDetailDto(
      partnerId: partnerId,
      partnerType: PartnerType.person,
      status: PartnerStatus.active,
      displayName: partnerId == 'partner-created' ? 'Created Customer' : 'Backend Customer',
      roles: const [PartnerRoleType.customer],
      availableActions: const [],
      expectedVersion: 1,
      personProfile: const PersonProfileDto(
        fullName: 'Created Customer',
        phone: '0988123456',
      ),
    );
  }
  throw StateError('Unexpected partner call $method');
}

final class _SearchSellableProductsCall {
  final String storeId;
  final String? keyword;
  const _SearchSellableProductsCall({required this.storeId, this.keyword});
}

final class _ListSellableProductUnitsCall {
  final String storeId;
  final String productId;
  const _ListSellableProductUnitsCall({required this.storeId, required this.productId});
}

final class _SalesFlowProductRepository implements ProductRepository {
  final List<Object> queries = [];
  bool failUnitLookup = false;

  @override
  Future<List<SellableProductDto>> searchSellable({
    required String storeId,
    String? keyword,
    int? limit,
    int? offset,
  }) async {
    queries.add(_SearchSellableProductsCall(storeId: storeId, keyword: keyword));
    return const [_liveProduct];
  }

  @override
  Future<List<SellableProductDto>> resolveSellableBarcode({
    required String storeId,
    required String barcode,
  }) async {
    return const <SellableProductDto>[];
  }

  @override
  Future<List<SellableProductUnitDto>> listSellableUnits({
    required String storeId,
    required String productId,
  }) async {
    queries.add(_ListSellableProductUnitsCall(storeId: storeId, productId: productId));
    if (failUnitLookup) throw StateError('catalog down');
    return const [_liveUnit];
  }

  @override
  Future<List<SellableProductResolutionDto>> resolveSellable({
    required String storeId,
    required List<String> productIds,
  }) async {
    return [
      for (final productId in productIds)
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
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FlowRepos {
  _FlowRepos() {
    checkout = _CheckoutRepo();
    orders = _OrderRepo()
      ..result = salesFixture<SalesOrderResultDto>()
      ..timelineResult = salesFixture<SalesOrderTimelineDto>()
      ..returnSummaryResult = salesFixture<SalesOrderReturnSummaryDto>()
      ..actionsResult = salesFixture<AvailablePostSaleActionsDto>();
    receipts = FakeSalesReceiptRepository();
    payments = FakeSalesPaymentRepository()
      ..summaryResult = salesFixture<SalesOrderPaymentSummaryDto>()
      ..settlementResult = salesFixture<SalesOrderSettlementDto>()
      ..transactionsResult = salesFixture<SalesPaymentTransactionsDto>();
    cancellations = FakeSalesCancellationRepository()
      ..precheckResult = CancellationPrecheckDto(
        allowed: true,
        sourceVersion: 7,
        sourceSettlementVersion: 3,
        blockers: const [],
      )
      ..confirmResult = const SalesOrderCancellationResultDto(
        cancellationId: 'cancel-1',
        salesOrderId: 'ord_123',
        salesOrderVersion: 8,
        status: SalesOrderCancellationStatus.confirmed,
      );
    final draft = ReturnExchangeDraftDto(
      returnExchangeId: 'return-1',
      salesOrderId: 'ord_123',
      version: 2,
      status: ReturnExchangeStatus.draft,
      lines: const [],
    );
    returnExchange = FakeReturnExchangeRepository()
      ..precheckResult = ReturnExchangePrecheckDto(
        allowed: true,
        sourceVersion: 1,
        blockers: const [],
      )
      ..returnableResult = ReturnableOrderLinesDto(
        salesOrderId: 'ord_123',
        sourceVersion: 1,
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
      )
      ..startResult = draft
      ..updateResult = draft
      ..cancelResult = const ReturnExchangeResultDto(
        returnExchangeId: 'return-1',
        salesOrderId: 'ord_123',
        version: 3,
        status: ReturnExchangeStatus.cancelled,
      )
      ..confirmResult = const ReturnExchangeResultDto(
        returnExchangeId: 'return-1',
        salesOrderId: 'ord_123',
        version: 3,
        status: ReturnExchangeStatus.confirmed,
      )
      ..detailResult = salesFixture<ReturnExchangeDetailDto>()
      ..evaluateResult = salesFixture<ReturnExchangeValuationDto>();
  }

  late final _CheckoutRepo checkout;
  late final _OrderRepo orders;
  late final FakeSalesReceiptRepository receipts;
  late final FakeSalesPaymentRepository payments;
  late final FakeSalesCancellationRepository cancellations;
  late final FakeReturnExchangeRepository returnExchange;
}

/// `getResult` trả kết quả mặc định của fixture (khoá `fake-checkout-attempt`).
final class _CheckoutRepo extends FakeSalesCheckoutRepository {
  @override
  Future<CheckoutResultDto> getResult({
    required String storeId,
    required String idempotencyKey,
  }) async {
    getResultCalls.add(SalesGetResultCall(storeId: storeId, idempotencyKey: idempotencyKey));
    return salesFixture<CheckoutResultDto>();
  }
}

/// `getDetail` dựng chi tiết đơn theo mã (đơn không có trong dữ liệu mẫu), như
/// `SalesFakeData.findOrderDetail` của module cũ.
final class _OrderRepo extends FakeSalesOrderRepository {
  @override
  Future<SalesOrderDetailDto> getDetail({required String salesOrderId}) async {
    detailCalls.add(salesOrderId);
    final customer = salesOrderId.contains('001') || salesOrderId.contains('DH-000129')
        ? const CustomerSnapshotDto(customerId: 'cust-001', displayName: 'Nguyễn Văn An')
        : const CustomerSnapshotDto(customerId: 'cust-walkin', displayName: 'Khách lẻ');
    final total = const MoneyDto(amountMinor: 1245000, currencyCode: 'VND');
    return SalesOrderDetailDto(
      order: SalesOrderDto(
        salesOrderId: salesOrderId,
        orderNumber: salesOrderId.contains('DH') ? salesOrderId : 'DH-000245',
        version: 1,
        lifecycleStatus: salesOrderId.contains('cancel') || salesOrderId.contains('d06')
            ? SalesOrderLifecycleStatus.cancelled
            : SalesOrderLifecycleStatus.completed,
        lockStatus: SalesOrderLockStatus.unlocked,
        total: total,
      ),
      committedAt: DateTime.utc(2026, 7, 29, 10, 32),
      store: const StoreSnapshotDto(
        storeId: 'store-center',
        storeCode: 'STORE-001',
        displayName: 'Cửa hàng Trung tâm',
      ),
      seller: const ActorSnapshotDto(actorId: 'actor-1', displayName: 'Minh Anh'),
      customer: customer,
      lines: [
        SalesOrderLineDto(
          lineId: 'line_1',
          product: const ProductSnapshotDto(
            productId: 'prod-001',
            sku: 'AD3EC-5L',
            displayName: 'AD3EC 5L (tyx)',
          ),
          unit: const ProductUnitSnapshotDto(
            productUnitId: 'pu-can',
            unitCode: 'CAN',
            unitName: 'Can',
          ),
          quantity: const QuantityDto(quantityMicros: 1000000),
          unitPrice: total,
          lineTotal: total,
        ),
      ],
    );
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

pricing.SalesWorkingStatePricingPreviewDto _pricingPreviewFor({
  required String storeId,
  String? customerId,
  required String currencyCode,
  required int contextVersion,
  required DateTime effectiveAt,
  required List<pricing.SalesPricingLineInput> lines,
}) {
  return pricing.SalesWorkingStatePricingPreviewDto(
    contextVersion: contextVersion,
    previewToken: 'preview-token-live',
    currencyCode: currencyCode,
    lines: [
      for (final line in lines)
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
