import 'dart:async';

import 'package:erp/features/sales/presentation/orchestration/sales_draft_list_scope.dart';
import 'package:erp/features/sales/presentation/pages/sales_checkout_invalid_entry_page.dart';
import 'package:erp/features/sales/presentation/pages/sales_checkout_page.dart';
import 'package:erp/features/sales/presentation/pages/sales_order_compose_page.dart';
import 'package:flutter/material.dart';
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
import 'package:erp/features/sales/presentation.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  late _RecordingSalesModule salesModule;
  late _SalesFlowCatalogModule catalogModule;
  late _RecordingPricingModule pricingModule;
  late _RecordingIamModule iamModule;
  late Object? capturedExtra;
  late GoRouter router;

  setUp(() async {
    await GetIt.instance.reset();
    salesModule = _RecordingSalesModule();
    catalogModule = _SalesFlowCatalogModule();
    pricingModule = _RecordingPricingModule();
    iamModule = _RecordingIamModule();
    pricingModule.previewFor = _pricingPreviewFor;
    capturedExtra = null;

    GetIt.instance.registerSingleton<ISalesModule>(salesModule);
    GetIt.instance.registerSingleton<IIamModule>(iamModule);
    GetIt.instance.registerSingleton<IExecutionContext>(
      const _TestExecutionContext(),
    );
    GetIt.instance.registerSingleton<IActiveStoreContext>(
      const _TestActiveStoreContext(),
    );
    GetIt.instance.registerSingleton<IPartnerModule>(_SalesFlowPartnerModule());
    GetIt.instance.registerSingleton<ICatalogModule>(catalogModule);
    GetIt.instance.registerSingleton<pricing.IPricingModule>(pricingModule);

    router = GoRouter(
      initialLocation: '/sales/compose',
      routes: [
        GoRoute(
          path: '/sales/compose',
          builder: (context, state) => const SalesDraftListScope(
            child: SalesOrderComposePage(),
          ),
        ),
        GoRoute(
          path: '/sales/checkout',
          builder: (context, state) {
            capturedExtra = state.extra;
            final args = state.extra;
            if (args is! SalesCheckoutDraftArgs) {
              return const SalesCheckoutInvalidEntryPage();
            }
            return SalesCheckoutPage(args: args);
          },
        ),
      ],
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets(
    'compose checkout route carries typed snapshot and no business query params',
    (tester) async {
      await pumpCheckoutCapableCompose(tester, router: router);
      await tester.ensureVisible(find.byKey(const Key('btn_compose_checkout')));
      await tester.tap(find.byKey(const Key('btn_compose_checkout')));
      await tester.pumpAndSettle();

      final location = router.state.uri;
      expect(location.path, '/sales/checkout');
      expect(location.queryParameters, isEmpty);
      expect(capturedExtra, isA<SalesCheckoutDraftArgs>());
      final args = capturedExtra! as SalesCheckoutDraftArgs;
      expect(args.commercialSnapshot.store.storeId, 'store-demo');
      expect(args.commercialSnapshot.store.storeCode, 'HCM-01');
      expect(
        args.commercialSnapshot.store.displayName,
        'Chi nhánh Hồ Chí Minh',
      );
      expect(args.commercialSnapshot.seller.actorId, 'user-demo');
      expect(args.commercialSnapshot.seller.displayName, 'An Nguyễn');
      expect(args.commercialSnapshot.lines.single.product.productId, 'product-live');
      expect(args.commercialSnapshot.lines.single.product.displayName, 'Thuoc live');
      expect(args.commercialSnapshot.lines.single.unit.productUnitId, 'unit-live');
      expect(args.commercialSnapshot.lines.single.unit.unitName, 'Hop');
      final precheck = salesModule.queries.whereType<PrecheckSalesOrderCheckoutQuery>().single;
      expect(precheck.tenantId, 'tenant-demo');
      expect(precheck.actorId, 'user-demo');
      expect(precheck.storeId, 'store-demo');
      expect(precheck.paymentIntents.single.method, SalesPaymentMethod.cash);
      expect(
        precheck.paymentIntents.single.amount.amountMinor,
        args.provisionalTotalAmountMinor,
      );
    },
  );

  testWidgets('compose checkout falls back to seller email when profile name is blank', (
    tester,
  ) async {
    iamModule.identityProfile = const MyIdentityProfileDto(
      userId: 'user-demo',
      firstName: '',
      lastName: '',
      email: 'seller@example.com',
      emailVerified: true,
    );

    await pumpCheckoutCapableCompose(tester, router: router);
    await tester.ensureVisible(find.byKey(const Key('btn_compose_checkout')));
    await tester.tap(find.byKey(const Key('btn_compose_checkout')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/sales/checkout');
    expect(capturedExtra, isA<SalesCheckoutDraftArgs>());
    final args = capturedExtra! as SalesCheckoutDraftArgs;
    expect(args.commercialSnapshot.seller.actorId, 'user-demo');
    expect(args.commercialSnapshot.seller.displayName, 'seller@example.com');
  });

  testWidgets('store context mismatch fails closed without navigation', (
    tester,
  ) async {
    iamModule.storeContext = const ActiveStoreContextDto(
      userId: 'user-demo',
      tenantId: 'tenant-demo',
      storeId: 'different-store',
      storeCode: 'HN-01',
      displayName: 'Chi nhánh Hà Nội',
    );

    await pumpCheckoutCapableCompose(tester, router: router);
    await tester.ensureVisible(find.byKey(const Key('btn_compose_checkout')));
    await tester.tap(find.byKey(const Key('btn_compose_checkout')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/sales/compose');
    expect(capturedExtra, isNull);
  });

  testWidgets('IAM context failure does not navigate to checkout', (
    tester,
  ) async {
    iamModule.error = StateError('IAM unavailable');

    await pumpCheckoutCapableCompose(tester, router: router);
    await tester.ensureVisible(find.byKey(const Key('btn_compose_checkout')));
    await tester.tap(find.byKey(const Key('btn_compose_checkout')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/sales/compose');
    expect(capturedExtra, isNull);
  });

  testWidgets('missing checkout route extra renders invalid entry', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/sales/checkout');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wgt_sg05_invalid_entry')), findsOneWidget);
    expect(find.text('Quay lại tạo đơn'), findsOneWidget);
  });

  testWidgets('renders provisional totals before explicit checkout checks', (tester) async {
    await pumpCheckout(tester, result: _readyResult(grandTotal: 950000, outstanding: 550000));
    expect(salesModule.queries, isEmpty);
    await tester.ensureVisible(find.byKey(const Key('txt_sg05_receivable_amount')));
    final receivable = tester.widget<VText>(
      find.byKey(const Key('txt_sg05_receivable_amount')),
    );
    expect(receivable.data, '0đ');
  });

  testWidgets('shows payment due date field when checkout has receivable', (tester) async {
    await pumpCheckout(tester);

    await _tapVisible(tester, find.text('50%'));
    await tester.pumpAndSettle();

    expect(find.text('Công nợ phát sinh'), findsOneWidget);
    expect(find.text('500.000đ'), findsWidgets);
    expect(find.byKey(const Key('input_sg05_receivable_due_date')), findsOneWidget);
    expect(find.text('Ngày hẹn thanh toán'), findsOneWidget);
    expect(find.text('Bắt buộc khi phát sinh công nợ.'), findsOneWidget);
  });

  testWidgets('shows every backend blocker in a toast', (tester) async {
    await pumpCheckout(
      tester,
      result: _blockedResult(
        blockers: const [
          SalesBlockerDto(
            code: 'PRODUCT_NOT_SELLABLE',
            message: 'Product is no longer sellable.',
            field: 'lines[0]',
          ),
          SalesBlockerDto(
            code: 'INVENTORY_INSUFFICIENT',
            message: 'Không đủ tồn kho.',
            field: 'lines[0]',
          ),
        ],
      ),
    );
    await _confirmFinalize(tester);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.textContaining('Sản phẩm đã ngừng bán. Vui lòng quay lại đơn.'),
      findsOneWidget,
    );
    expect(find.textContaining('Product is no longer sellable.'), findsNothing);
    expect(find.textContaining('Không đủ tồn kho.'), findsOneWidget);
    expect(find.byKey(const Key('btn_sg05_retry_precheck')), findsNothing);
  });

  testWidgets('does not start checkout precheck on page load', (tester) async {
    await pumpCheckout(tester, settle: false);
    await tester.pump();

    expect(salesModule.queries, isEmpty);
    expect(find.byKey(const Key('wgt_sg05_precheck_panel')), findsNothing);
    expect(find.byKey(const Key('wgt_sg05_precheck_spinner')), findsNothing);
    expect(find.text('Phương thức'), findsOneWidget);
    final finalize = tester.widget<VButton>(
      find.byKey(const Key('btn_sg05_finalize')),
    );
    expect(finalize.enabled, true);
  });

  testWidgets('DEPENDENCY_UNAVAILABLE failure shows a toast and keeps finalize', (tester) async {
    salesModule.error = const SalesContractException(
      'DEPENDENCY_UNAVAILABLE',
      message: 'Pricing dependency unavailable.',
    );
    await pumpCheckout(tester);
    await _confirmFinalize(tester);

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text('Chưa thể kiểm tra điều kiện thanh toán. Vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('wgt_sg05_precheck_panel')), findsNothing);
    expect(find.byKey(const Key('btn_sg05_finalize')), findsOneWidget);
  });

  testWidgets('ready status enables finalize', (
    tester,
  ) async {
    await pumpCheckout(tester, result: _readyResult());

    expect(find.byKey(const Key('wgt_sg05_precheck_panel')), findsNothing);
    final finalize = tester.widget<VButton>(
      find.byKey(const Key('btn_sg05_finalize')),
    );
    expect(finalize.onPressed, isNotNull);
    expect(finalize.enabled, true);
    expect(finalize.label, 'Tiếp tục');
  });

  testWidgets(
    'RECEIVABLE_DUE_DATE_REQUIRED renders backend blocker message',
    (tester) async {
      await pumpCheckout(
        tester,
        result: _blockedResult(
          blockers: const [
            SalesBlockerDto(
              code: CheckoutBlockerCodes.receivableDueDateRequired,
              message: 'Due date required.',
              field: 'dueDate',
            ),
          ],
        ),
      );
      await _confirmFinalize(tester);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Due date required.'), findsOneWidget);
      expect(find.byKey(const Key('wgt_sg05_precheck_panel')), findsNothing);
      expect(find.textContaining('Contract Group C hiện chưa hỗ trợ'), findsNothing);
    },
  );

  testWidgets(
    'DUE_DATE_REQUIRED alias renders backend blocker message',
    (tester) async {
      await pumpCheckout(
        tester,
        result: _blockedResult(
          blockers: const [
            SalesBlockerDto(
              code: 'DUE_DATE_REQUIRED',
              message: 'Due date required.',
              field: 'dueDate',
            ),
          ],
        ),
      );
      await _confirmFinalize(tester);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Due date required.'), findsOneWidget);
      expect(find.byKey(const Key('wgt_sg05_precheck_panel')), findsNothing);
      expect(find.textContaining('Contract Group C hiện chưa hỗ trợ'), findsNothing);
    },
  );

  testWidgets(
    'payment edits do not finalize without confirmation',
    (tester) async {
      salesModule.result = _readyResult();
      final checkoutRouter = GoRouter(
        initialLocation: '/sales/checkout',
        routes: [
          GoRoute(
            path: '/sales/compose',
            builder: (context, state) => const SalesDraftListScope(
              child: SalesOrderComposePage(),
            ),
          ),
          GoRoute(
            path: '/sales/checkout',
            builder: (context, state) => SalesCheckoutPage(args: _draftArgs()),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: checkoutRouter));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_sg05_checkout_page')), findsOneWidget);
      expect(find.byKey(const Key('txt_sg05_precheck_ready')), findsNothing);
      expect(find.text('Sẵn sàng hoàn tất'), findsNothing);

      // Enabled Group C payment actions only — finalize stays disabled.
      await _tapVisible(tester, find.text('Chuyển khoản'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('input_sg05_transaction_code')),
        'TX-REGRESSION',
      );
      await tester.pump();
      await _tapVisible(tester, find.text('Kết hợp'));
      await tester.pumpAndSettle();
      await _tapVisible(
        tester,
        find.descendant(
          of: find.byType(SalesCheckoutPaymentMethodSelector),
          matching: find.text('Tiền mặt'),
        ),
      );
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('50%'));
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('0%'));
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('100%'));
      await tester.pumpAndSettle();

      await tester.pumpAndSettle();

      expect(salesModule.queries, isEmpty);
      expect(salesModule.commands, isEmpty);
      expect(
        checkoutRouter.routeInformationProvider.value.uri.path,
        '/sales/checkout',
      );
      expect(find.byKey(const Key('btn_sg05_finalize')), findsOneWidget);

      final finalize = tester.widget<VButton>(
        find.byKey(const Key('btn_sg05_finalize')),
      );
      expect(finalize.onPressed, isNotNull);
      expect(finalize.enabled, true);
    },
  );

  testWidgets('walk-in cash amount field is locked and does not open keypad', (
    tester,
  ) async {
    await pumpCheckout(tester, args: _draftArgs(isWalkIn: true));

    await _tapVisible(tester, find.byKey(const Key('input_sg05_cash_amount')));
    await tester.pumpAndSettle();

    expect(find.text('Nhập số tiền mặt'), findsNothing);
    expect(find.text('1.000.000đ'), findsWidgets);
  });

  testWidgets('walk-in bank transfer amount field is locked and does not open keypad', (
    tester,
  ) async {
    await pumpCheckout(tester, args: _draftArgs(isWalkIn: true));
    await _tapVisible(tester, find.text('Chuyển khoản'));
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.byKey(const Key('input_sg05_bank_amount')));
    await tester.pumpAndSettle();

    expect(find.text('Nhập số tiền chuyển khoản'), findsNothing);
    expect(find.text('1.000.000đ'), findsWidgets);
  });

  group('SG-05 checkout feedback (toast + loading)', () {
    testWidgets('blocked precheck shows a toast, not the precheck card', (tester) async {
      await pumpCheckout(
        tester,
        result: _blockedResult(
          blockers: const [
            SalesBlockerDto(
              code: CheckoutBlockerCodes.receivableDueDateRequired,
              message: 'Ngày hẹn thanh toán là bắt buộc khi phát sinh công nợ.',
              field: 'dueDate',
            ),
          ],
        ),
      );
      await _confirmFinalize(tester);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Ngày hẹn thanh toán là bắt buộc khi phát sinh công nợ.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('wgt_sg05_precheck_panel')), findsNothing);
      expect(find.byKey(const Key('btn_sg05_retry_precheck')), findsNothing);
    });

    testWidgets('precheck failure shows a toast, not the failure card', (tester) async {
      GetIt.instance;
      final module = GetIt.instance<ISalesModule>() as _RecordingSalesModule;
      module.error = const SalesContractException(
        'DEPENDENCY_UNAVAILABLE',
        message: 'Pricing dependency unavailable.',
      );
      await pumpCheckout(tester);
      await _confirmFinalize(tester);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Chưa thể kiểm tra điều kiện thanh toán. Vui lòng thử lại.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('wgt_sg05_precheck_panel')), findsNothing);
    });

    testWidgets('finalize button shows loading while precheck is in flight', (tester) async {
      final completer = Completer<CheckoutPrecheckDto>();
      final module = GetIt.instance<ISalesModule>() as _RecordingSalesModule;
      module.resultFuture = completer.future;
      await pumpCheckout(tester);

      await tester.tap(find.byKey(const Key('btn_sg05_finalize')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_sg05_finalize_confirm')));
      await tester.pump();
      await tester.pump();

      final finalize = tester.widget<VButton>(
        find.byKey(const Key('btn_sg05_finalize')),
      );
      expect(finalize.isLoading, true);
      expect(finalize.onPressed, isNull);

      // Complete with a blocker so finalize stops after precheck (no command).
      completer.complete(
        _blockedResult(
          blockers: const [
            SalesBlockerDto(code: 'X', message: 'Chặn', field: null),
          ],
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('idempotency conflict shows a toast', (tester) async {
      final module = GetIt.instance<ISalesModule>() as _RecordingSalesModule;
      module.result = _readyResult();
      module.commandError = const SalesContractException(
        'IDEMPOTENCY_CONFLICT',
        message: 'Conflict.',
      );
      await pumpCheckout(tester);
      await _confirmFinalize(tester);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('xung đột'), findsWidgets);
      expect(find.byKey(const Key('wgt_sg05_attempt_panel')), findsNothing);
    });
  });
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

Future<void> _confirmFinalize(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('btn_sg05_finalize')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('btn_sg05_finalize')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('btn_sg05_finalize_confirm')));
  await tester.pumpAndSettle();
}

Future<void> pumpCheckoutCapableCompose(
  WidgetTester tester, {
  required GoRouter router,
}) async {
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('btn_compose_select_customer')));
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
  await tester.pump(const Duration(seconds: 1));
  await tester.tap(find.text('Backend Customer'));
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byKey(const Key('input_compose_product_search')),
    'thuoc',
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
  await tester.tap(find.byKey(const Key('card_compose_suggest_product-live')));
  await tester.pumpAndSettle();

  final checkoutBtn = tester.widget<VButton>(
    find.byKey(const Key('btn_compose_checkout')),
  );
  expect(checkoutBtn.onPressed, isNotNull);
}

Future<void> pumpCheckout(
  WidgetTester tester, {
  CheckoutPrecheckDto? result,
  bool settle = true,
  SalesCheckoutDraftArgs? args,
}) async {
  if (result != null) {
    GetIt.instance<ISalesModule>();
    final module = GetIt.instance<ISalesModule>() as _RecordingSalesModule;
    module.result = result;
  }

  await tester.pumpWidget(
    MaterialApp(
      home: SalesCheckoutPage(args: args ?? _draftArgs()),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  }
}

SalesCheckoutDraftArgs _draftArgs({
  int provisionalTotal = 1000000,
  bool isWalkIn = false,
}) {
  return SalesCheckoutDraftArgs(
    runtimeDraftId: 'draft-1',
    customerId: isWalkIn ? null : 'partner-backend',
    customerDisplayName: isWalkIn ? 'Khách lẻ' : 'Backend Customer',
    customerPhone: isWalkIn ? null : '0988123456',
    isWalkIn: isWalkIn,
    currencyCode: 'VND',
    provisionalTotalAmountMinor: provisionalTotal,
    expectedSourceVersion: 1,
    commercialSnapshot: SalesCommercialSnapshotInput(
      store: const StoreSnapshotDto(
        storeId: 'store-demo',
        storeCode: 'HCM-01',
        displayName: 'Chi nhánh Hồ Chí Minh',
      ),
      seller: const ActorSnapshotDto(
        actorId: 'user-demo',
        displayName: 'Nguyễn An',
      ),
      customer: const CustomerSnapshotDto(
        customerId: 'partner-backend',
        displayName: 'Backend Customer',
        phoneNumber: '0988123456',
      ),
      lines: const [
        SalesReceiptLineDto(
          lineId: 'line-1',
          product: ProductSnapshotDto(
            productId: 'product-live',
            sku: 'SKU-LIVE',
            displayName: 'Thuoc live',
          ),
          unit: ProductUnitSnapshotDto(
            productUnitId: 'unit-live',
            unitCode: 'HOP',
            unitName: 'Hop',
          ),
          quantity: QuantityDto(quantityMicros: 1000000),
          unitPrice: MoneyDto(
            amountMinor: 1000000,
            currencyCode: 'VND',
          ),
          discountTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
          lineTotal: MoneyDto(
            amountMinor: 1000000,
            currencyCode: 'VND',
          ),
        ),
      ],
    ),
    lines: const [
      CheckoutLineInput(
        productId: 'product-live',
        productUnitId: 'unit-live',
        quantity: QuantityDto(quantityMicros: 1000000),
        unitPrice: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
      ),
    ],
  );
}

CheckoutPrecheckDto _readyResult({
  int grandTotal = 1000000,
  int outstanding = 0,
}) {
  return CheckoutPrecheckDto(
    canFinalize: true,
    blockers: const [],
    monetarySummary: CheckoutMonetarySummaryDto(
      subtotal: MoneyDto(amountMinor: grandTotal, currencyCode: 'VND'),
      discountTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
      grandTotal: MoneyDto(amountMinor: grandTotal, currencyCode: 'VND'),
    ),
    receivableRequirement: ReceivableRequirementDto(
      isRequired: outstanding > 0,
      amount: MoneyDto(amountMinor: outstanding, currencyCode: 'VND'),
      customerId: 'partner-backend',
    ),
  );
}

CheckoutPrecheckDto _blockedResult({
  required List<SalesBlockerDto> blockers,
  int grandTotal = 1000000,
}) {
  return CheckoutPrecheckDto(
    canFinalize: false,
    blockers: blockers,
    monetarySummary: CheckoutMonetarySummaryDto(
      subtotal: MoneyDto(amountMinor: grandTotal, currencyCode: 'VND'),
      discountTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
      grandTotal: MoneyDto(amountMinor: grandTotal, currencyCode: 'VND'),
    ),
    receivableRequirement: const ReceivableRequirementDto(
      isRequired: false,
      amount: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    ),
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

final class _TestExecutionContext implements IExecutionContext {
  const _TestExecutionContext();

  @override
  String get correlationId => 'corr-1';

  @override
  Future<String> requireTenantId() async => 'tenant-demo';

  @override
  Future<String> requireUserId() async => 'user-demo';
}

final class _TestActiveStoreContext implements IActiveStoreContext {
  const _TestActiveStoreContext();

  @override
  String? get activeStoreId => 'store-demo';

  @override
  Future<String> requireActiveStoreId() async => 'store-demo';
}

final class _RecordingSalesModule implements ISalesModule {
  CheckoutPrecheckDto result = _readyResult();
  Future<CheckoutPrecheckDto>? resultFuture;
  Object? error;
  Object? commandError;
  final List<Object> queries = [];
  final List<Object> commands = [];

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    commands.add(command);
    final thrown = commandError;
    if (thrown != null) throw thrown;
    throw UnsupportedError('Group C must not execute commands');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    if (query is! PrecheckSalesOrderCheckoutQuery) {
      throw StateError('Unexpected sales query $query');
    }
    final thrown = error;
    if (thrown != null) throw thrown;
    final pending = resultFuture;
    if (pending != null) {
      return await pending as TResult;
    }
    return result as TResult;
  }
}

final class _RecordingIamModule implements IIamModule {
  Object? error;
  ActiveStoreContextDto storeContext = const ActiveStoreContextDto(
    userId: 'user-demo',
    tenantId: 'tenant-demo',
    storeId: 'store-demo',
    storeCode: 'HCM-01',
    displayName: 'Chi nhánh Hồ Chí Minh',
  );
  MyIdentityProfileDto identityProfile = const MyIdentityProfileDto(
    userId: 'user-demo',
    firstName: 'Nguyễn',
    lastName: 'An',
    email: 'an@example.com',
    emailVerified: true,
  );

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw StateError('Unexpected IAM command $command');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    final thrown = error;
    if (thrown != null) throw thrown;
    if (query is GetActiveStoreContextQuery) {
      return storeContext as TResult;
    }
    if (query is GetMyIdentityProfileQuery) {
      return identityProfile as TResult;
    }
    throw StateError('Unexpected IAM query $query');
  }
}

final class _SalesFlowCatalogModule implements ICatalogModule {
  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw StateError('Unexpected command $command');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is SearchSellableProductsQuery) {
      return const [_liveProduct] as TResult;
    }
    if (query is ResolveSellableBarcodeQuery) {
      return const <SellableProductDto>[] as TResult;
    }
    if (query is ListSellableProductUnitsQuery) {
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

final class _SalesFlowPartnerModule implements IPartnerModule {
  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
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
            ],
            page: 1,
            limit: 40,
            total: 1,
          )
          as TResult;
    }
    if (query is GetPartnerDetailQuery) {
      return const PartnerDetailDto(
            partnerId: 'partner-backend',
            partnerType: PartnerType.person,
            status: PartnerStatus.active,
            displayName: 'Backend Customer',
            roles: [PartnerRoleType.customer],
            availableActions: [],
            expectedVersion: 1,
            personProfile: PersonProfileDto(
              fullName: 'Backend Customer',
              phone: '0988123456',
            ),
          )
          as TResult;
    }
    throw StateError('Unexpected query $query');
  }
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
