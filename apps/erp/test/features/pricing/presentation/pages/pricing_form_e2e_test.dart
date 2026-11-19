import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/pricing/data/customer_price_rule_repository.dart';
import 'package:erp/features/pricing/data/models.dart';
import 'package:erp/features/pricing/data/pricing_errors.dart';
import 'package:erp/features/pricing/presentation.dart';
import 'package:erp/features/pricing/presentation/pages/pricing_detail_page.dart';
import 'package:erp/features/pricing/presentation/pages/pricing_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:c45_design_system/design_system.dart';

import '../../pricing_e2e_harness.dart';
import '../../support/pricing_detail_dto_builder.dart';

void main() {
  tearDown(() async {
    await tearDownPricingE2E();
  });

  group('e2e_e02_u04 — create (S1)', () {
    testWidgets(
      'e2e_e02_u04_fr01_01: create submit happy navigates to detail',
      (tester) async {
        await setUpPricingE2E(
          createScenario: FakePricingScenario.createRuleOk,
          detailScenario: FakePricingScenario.ruleDetailActive,
        );
        await tester.pumpWidget(
          buildPricingRouter(initialLocation: '/pricing/new'),
        );
        await tester.pumpAndSettle();

        expect(findByWgtKey('wgt_e02_u04_fr01_01'), findsOneWidget);

        final cubit = tester
            .element(findByWgtKey('wgt_e02_u04_fr01_01'))
            .read<PriceRuleFormCubit>();

        cubit
          ..selectCustomer(
            customerId: 'customer-1',
            customerName: 'Khách hàng mẫu',
          )
          ..selectProduct(productId: 'product-1', productName: 'Vaccine mẫu')
          ..selectProductUnit(productUnitId: 'unit-1', productUnitName: 'Lọ')
          ..updatePrice(150000)
          ..updateDates(effectiveFrom: DateTime.utc(2026, 7, 16));

        await tester.pump();
        await cubit.submit();
        await tester.pumpAndSettle();

        expect(findByWgtKey('wgt_e02_u03_fr01_01'), findsOneWidget);
      },
    );

    testWidgets(
      'e2e_e02_u04_fr01_02: floor blocked shows toast message',
      (tester) async {
        await setUpPricingE2E(
          createScenario: FakePricingScenario.createRuleFloorBlocked,
        );
        await tester.pumpWidget(
          buildPricingRouter(initialLocation: '/pricing/new'),
        );
        await tester.pumpAndSettle();

        final cubit = tester
            .element(findByWgtKey('wgt_e02_u04_fr01_01'))
            .read<PriceRuleFormCubit>();

        cubit
          ..selectCustomer(
            customerId: 'customer-1',
            customerName: 'Khách hàng mẫu',
          )
          ..selectProduct(productId: 'product-1', productName: 'Vaccine mẫu')
          ..selectProductUnit(productUnitId: 'unit-1', productUnitName: 'Lọ')
          ..updatePrice(1000)
          ..updateDates(effectiveFrom: DateTime.utc(2026, 7, 16));

        await tester.pump();
        await cubit.submit();
        await tester.pumpAndSettle();

        expect(
          find.text('Giá nhập thấp hơn giá sàn quy định.'),
          findsOneWidget,
        );
        expect(findByWgtKey('wgt_e02_u04_fr01_01'), findsOneWidget);
      },
    );

    testWidgets(
      'e2e_e02_u04_fr01_04: duplicate is blocked and preserves form',
      (tester) async {
        await setUpPricingE2E(
          createScenario: FakePricingScenario.createRuleDuplicate,
        );
        await tester.pumpWidget(
          buildPricingRouter(initialLocation: '/pricing/new'),
        );
        await tester.pumpAndSettle();

        final cubit = tester
            .element(findByWgtKey('wgt_e02_u04_fr01_01'))
            .read<PriceRuleFormCubit>();

        cubit
          ..selectCustomer(
            customerId: 'customer-1',
            customerName: 'Khách hàng mẫu',
          )
          ..selectProduct(productId: 'product-1', productName: 'Vaccine mẫu')
          ..selectProductUnit(productUnitId: 'unit-1', productUnitName: 'Lọ')
          ..updatePrice(150000)
          ..updateDates(effectiveFrom: DateTime.utc(2026, 7, 16));

        await tester.pump();
        await cubit.submit();
        await tester.pumpAndSettle();

        expect(find.text('Tự động ghi đè giá trùng?'), findsOneWidget);
        await tester.tap(find.widgetWithText(VButton, 'Hủy').last);
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Đã tồn tại giá riêng đang hoạt động trùng thời gian. '
            'Vui lòng điều chỉnh khoảng hiệu lực hoặc chọn đối tượng khác.',
          ),
          findsNothing,
        );
        expect(find.text('Lưu ý tự động ghi đè giá trùng'), findsNothing);
        expect(findByWgtKey('wgt_e02_u04_fr01_01'), findsOneWidget);
        final state = cubit.state as PriceRuleFormEditing;
        expect(state.customerId, 'customer-1');
        expect(state.productUnitId, 'unit-1');
        expect(state.rulePriceMinor, 150000);
      },
    );

    testWidgets(
      'form_duplicate_then_confirm_overwrite',
      (tester) async {
        final repo = await setUpPricingE2E(
          createScenario: FakePricingScenario.createRuleDuplicate,
          detailScenario: FakePricingScenario.ruleDetailActive,
        );
        await tester.pumpWidget(
          buildPricingRouter(initialLocation: '/pricing/new'),
        );
        await tester.pumpAndSettle();

        final cubit = tester
            .element(findByWgtKey('wgt_e02_u04_fr01_01'))
            .read<PriceRuleFormCubit>();

        cubit
          ..selectCustomer(
            customerId: 'customer-1',
            customerName: 'Khách hàng mẫu',
          )
          ..selectProduct(productId: 'product-1', productName: 'Vaccine mẫu')
          ..selectProductUnit(productUnitId: 'unit-1', productUnitName: 'Lọ')
          ..updatePrice(150000)
          ..updateDates(effectiveFrom: DateTime.utc(2026, 7, 16));

        await tester.pump();
        await cubit.submit();
        await tester.pumpAndSettle();

        expect(find.text('Tự động ghi đè giá trùng?'), findsOneWidget);
        repo.createScenario = FakePricingScenario.createRuleOk;
        await tester.tap(find.widgetWithText(VButton, 'Ghi đè & Lưu'));
        await tester.pumpAndSettle();

        final creates = repo.calls.where((c) => c.method == 'create').toList();
        expect(creates, hasLength(2));
        expect(creates[0].args['acknowledgeOverwrite'], isFalse);
        expect(creates[1].args['acknowledgeOverwrite'], isTrue);
        expect(
          creates[1].args['idempotencyKey'],
          creates[0].args['idempotencyKey'],
        );
        expect(findByWgtKey('wgt_e02_u03_fr01_01'), findsOneWidget);
      },
    );

    testWidgets(
      'e2e_e02_u04_fr01_03: create preserves list and parent back stack',
      (tester) async {
        await setUpPricingE2E(
          createScenario: FakePricingScenario.createRuleOk,
          detailScenario: FakePricingScenario.ruleDetailActive,
        );
        await tester.pumpWidget(
          buildPricingRouter(initialLocation: '/pricing-test-origin'),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Mở Pricing'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(VFloatingActionButton));
        await tester.pumpAndSettle();

        final cubit = tester
            .element(findByWgtKey('wgt_e02_u04_fr01_01'))
            .read<PriceRuleFormCubit>();
        cubit
          ..selectCustomer(
            customerId: 'customer-1',
            customerName: 'Khách hàng mẫu',
          )
          ..selectProduct(
            productId: 'product-1',
            productName: 'Vaccine mẫu',
          )
          ..selectProductUnit(
            productUnitId: 'unit-1',
            productUnitName: 'Lọ',
          )
          ..updatePrice(150000)
          ..updateDates(effectiveFrom: DateTime.utc(2026, 7, 16));

        await tester.pump();
        await cubit.submit();
        await tester.pumpAndSettle();

        expect(findByWgtKey('wgt_e02_u03_fr01_01'), findsOneWidget);

        await tester.tap(
          find.byWidgetPredicate(
            (widget) => widget is VIcon && widget.icon == VIcons.arrowBack,
          ),
        );
        await tester.pumpAndSettle();

        expect(findByWgtKey('wgt_e02_u01_fr01_01'), findsOneWidget);
        final listBackButton = find.byWidgetPredicate(
          (widget) => widget is VIcon && widget.icon == VIcons.chevronLeft,
        );
        expect(listBackButton, findsOneWidget);

        await tester.tap(listBackButton);
        await tester.pumpAndSettle();

        expect(find.text('Mở Pricing'), findsOneWidget);
      },
    );

    testWidgets(
      'e2e_e02_u04_fr01_04: cancel create returns to list',
      (tester) async {
        await setUpPricingE2E();
        await tester.pumpWidget(
          buildPricingRouter(initialLocation: '/pricing-test-origin'),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Mở Pricing'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(VFloatingActionButton));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hủy'));
        await tester.pumpAndSettle();

        expect(findByWgtKey('wgt_e02_u01_fr01_01'), findsOneWidget);
      },
    );

    testWidgets(
      'e2e_e02_u04_fr01_05: dirty back shows leave confirmation then stay',
      (tester) async {
        await setUpPricingE2E();
        await tester.pumpWidget(
          buildPricingRouter(initialLocation: '/pricing/new'),
        );
        await tester.pumpAndSettle();

        tester
            .element(findByWgtKey('wgt_e02_u04_fr01_01'))
            .read<PriceRuleFormCubit>()
            .updatePrice(150000);
        await tester.pump();

        await tester.tap(find.byKey(const Key('btn_price_rule_form_back')));
        await tester.pumpAndSettle();

        expect(find.text('Rời khỏi màn hình?'), findsOneWidget);
        expect(find.byType(VConfirmDialog), findsOneWidget);

        await tester.tap(find.text('Ở lại chỉnh sửa'));
        await tester.pumpAndSettle();

        expect(findByWgtKey('wgt_e02_u04_fr01_01'), findsOneWidget);
        expect(find.text('Rời khỏi màn hình?'), findsNothing);
      },
    );
  });

  group('e2e_e02_u06 — edit (S5)', () {
    testWidgets(
      'e2e_e02_u06_fr01_01: edit submit success shows toast',
      (tester) async {
        await setUpPricingE2E(
          updateScenario: FakePricingScenario.updateRuleOk,
          detailScenario: FakePricingScenario.ruleDetailActive,
        );

        await tester.pumpWidget(
          buildPricingRouter(initialLocation: '/pricing/fake-rule-1'),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Thao tác'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sửa giá riêng'));
        await tester.pumpAndSettle();

        expect(findByWgtKey('wgt_e02_u06_fr01_01'), findsOneWidget);

        final cubit = tester
            .element(findByWgtKey('wgt_e02_u06_fr01_01'))
            .read<PriceRuleFormCubit>();
        cubit.updatePrice(160000);
        await cubit.submit();
        await tester.pumpAndSettle();

        expect(find.text('Đã cập nhật giá riêng'), findsOneWidget);
      },
    );

    testWidgets(
      'e2e_e02_u06_fr01_02: STATE_CHANGED shows reload state',
      (tester) async {
        await setUpPricingE2E(
          updateScenario: FakePricingScenario.updateRuleStateChanged,
          detailScenario: FakePricingScenario.ruleDetailActive,
        );

        await tester.pumpWidget(
          buildPricingRouter(initialLocation: '/pricing/fake-rule-1'),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Thao tác'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sửa giá riêng'));
        await tester.pumpAndSettle();

        final cubit = tester
            .element(findByWgtKey('wgt_e02_u06_fr01_01'))
            .read<PriceRuleFormCubit>();
        cubit.updatePrice(170000);
        await cubit.submit();
        await tester.pumpAndSettle();

        expect(find.byType(PriceRuleFormStateChangedState), findsOneWidget);
        expect(find.text('Tải lại'), findsWidgets);
      },
    );
  });

  group('H6 & H9 — form header & duplicate banner link', () {
    testWidgets('h6_edit_header_shows_name', (tester) async {
      await setUpPricingE2E();
      final initial = buildPricingDetailDto(updatedByName: 'Nguyễn Lan');
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: PricingFormPage(initialRule: initial),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cập nhật bởi: Nguyễn Lan'), findsOneWidget);
    });

    testWidgets('h9_duplicate_banner_link', (tester) async {
      await setUpPricingE2E();
      GetIt.instance.unregister<CustomerPriceRuleRepository>();
      GetIt.instance.registerSingleton<CustomerPriceRuleRepository>(
        _DuplicateWithIdRepository(),
      );

      await tester.pumpWidget(
        buildPricingRouter(initialLocation: '/pricing/new'),
      );
      await tester.pumpAndSettle();

      final cubit = tester
          .element(findByWgtKey('wgt_e02_u04_fr01_01'))
          .read<PriceRuleFormCubit>();

      cubit
        ..selectCustomer(
          customerId: 'customer-1',
          customerName: 'Khách hàng mẫu',
        )
        ..selectProduct(productId: 'product-1', productName: 'Vaccine mẫu')
        ..selectProductUnit(productUnitId: 'unit-1', productUnitName: 'Lọ')
        ..updatePrice(150000)
        ..updateDates(effectiveFrom: DateTime.utc(2026, 7, 16));

      await tester.pump();
      await cubit.submit();
      await tester.pumpAndSettle();

      expect(find.text('Tự động ghi đè giá trùng?'), findsOneWidget);
      await tester.tap(find.widgetWithText(VButton, 'Hủy').last);
      await tester.pumpAndSettle();

      expect(find.text('Lưu ý tự động ghi đè giá trùng'), findsOneWidget);
      expect(find.text('Xem giá riêng hiện có >'), findsOneWidget);

      await tester.tap(find.text('Xem giá riêng hiện có >'));
      await tester.pumpAndSettle();

      expect(find.byType(PricingDetailPage), findsOneWidget);
    });

    testWidgets('h9_no_link_without_id', (tester) async {
      await setUpPricingE2E();
      final initial = buildPricingDetailDto();
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: PricingFormPage(initialRule: initial),
        ),
      );
      await tester.pumpAndSettle();

      final cubit = tester
          .element(findByWgtKey('wgt_e02_u06_fr01_01'))
          .read<PriceRuleFormCubit>();
      cubit.updateDates(effectiveFrom: DateTime.utc(2026, 8, 1));
      await tester.pumpAndSettle();

      expect(find.text('Lưu ý tự động ghi đè giá trùng'), findsOneWidget);
      expect(find.text('Xem giá riêng hiện có >'), findsNothing);
    });

    testWidgets('t93_form_below_floor_banner', (tester) async {
      await setUpPricingE2E();
      await tester.pumpWidget(
        buildPricingRouter(initialLocation: '/pricing/new'),
      );
      await tester.pumpAndSettle();

      final cubit = tester
          .element(findByWgtKey('wgt_e02_u04_fr01_01'))
          .read<PriceRuleFormCubit>();

      cubit
        ..selectProduct(
          productId: 'product-1',
          productName: 'Vaccine mẫu',
          listPriceMinor: 200000,
          floorPriceMinor: 100000,
        )
        ..updatePrice(80000);

      await tester.pumpAndSettle();

      expect(find.byType(PriceRuleBelowFloorBanner), findsOneWidget);
      expect(find.text('Giá riêng thấp hơn giá sàn'), findsOneWidget);
    });
  });
}

final class _DuplicateWithIdRepository extends FakeCustomerPriceRuleRepository {
  @override
  Future<CreateCustomerPriceRuleResult> create({
    required String customerId,
    required String productId,
    required String productUnitId,
    required int rulePriceMinor,
    required String currencyCode,
    required DateTime effectiveFrom,
    DateTime? effectiveTo,
    String? note,
    required bool acknowledgeFloorWarning,
    bool acknowledgeOverwrite = false,
    required String idempotencyKey,
  }) async {
    calls.add(
      FakePricingCall('create', {
        'customerId': customerId,
        'productId': productId,
        'productUnitId': productUnitId,
        'rulePriceMinor': rulePriceMinor,
        'currencyCode': currencyCode,
        'effectiveFrom': effectiveFrom,
        'effectiveTo': effectiveTo,
        'note': note,
        'acknowledgeFloorWarning': acknowledgeFloorWarning,
        'acknowledgeOverwrite': acknowledgeOverwrite,
        'idempotencyKey': idempotencyKey,
      }),
    );
    throw const AppException(
      PricingErrorCodes.duplicateActiveRule,
      details: {
        'conflictingRuleId': 'rule-x',
        'reason': 'overwriteRequired',
      },
    );
  }
}
