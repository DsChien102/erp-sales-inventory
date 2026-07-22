import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/testing.dart';
import 'package:vet45_pricing_presentation/presentation.dart';

import '../../pricing_e2e_harness.dart';

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
        await tester.tap(find.text('Tạo thủ công'));
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
          (widget) => widget is VIcon && widget.icon == VIcons.arrowLeft,
        );
        expect(listBackButton, findsOneWidget);

        await tester.tap(listBackButton);
        await tester.pumpAndSettle();

        expect(find.text('Mở Pricing'), findsOneWidget);
      },
    );

    testWidgets(
      'e2e_e02_u04_fr01_04: cancel create returns to choose method',
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
        await tester.tap(find.text('Tạo thủ công'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hủy'));
        await tester.pumpAndSettle();

        expect(findByWgtKey('wgt_e02_u02_fr01_01'), findsOneWidget);
        expect(find.text('Tạo thủ công'), findsOneWidget);
        expect(find.text('Nhập từ Excel'), findsOneWidget);
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
}
