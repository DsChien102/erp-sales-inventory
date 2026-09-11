import 'package:erp/features/pricing/presentation/pages/pricing_choose_method_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/testing.dart';
import 'package:erp/features/pricing/presentation.dart';

import '../../pricing_e2e_harness.dart';

void main() {
  tearDown(() async {
    await tearDownPricingE2E();
  });

  group('e2e_e02_u01 — list/search (S2)', () {
    testWidgets(
      'e2e_e02_u01_fr01_01: list loads cards from searchRulesDefault',
      (tester) async {
        await setUpPricingE2E();
        await tester.pumpWidget(buildPricingRouter());
        await tester.pumpAndSettle();

        expect(findByWgtKey('wgt_e02_u01_fr01_01'), findsOneWidget);
        expect(find.text('Giá riêng / Nhớ giá'), findsOneWidget);
        expect(find.byType(PriceRuleCard), findsWidgets);
        expect(find.text('Khách hàng mẫu'), findsWidgets);
      },
    );

    testWidgets(
      'e2e_e02_u01_fr01_02: empty tenant shows empty state',
      (tester) async {
        await setUpPricingE2E(
          searchScenario: FakePricingScenario.searchRulesEmpty,
        );
        await tester.pumpWidget(buildPricingRouter());
        await tester.pumpAndSettle();

        expect(find.text('Chưa có giá riêng nào'), findsOneWidget);
        expect(find.byType(VEmptyState), findsOneWidget);
      },
    );
  });

  group('e2e_e02_u03 — detail (S3)', () {
    testWidgets(
      'e2e_e02_u03_fr01_01: list opens detail with Thao tác CTA',
      (tester) async {
        await setUpPricingE2E();
        await tester.pumpWidget(buildPricingRouter());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Khách hàng mẫu').first);
        await tester.pumpAndSettle();

        expect(findByWgtKey('wgt_e02_u03_fr01_01'), findsOneWidget);
        expect(find.text('Thao tác'), findsOneWidget);
      },
    );

    testWidgets(
      'e2e_e02_u03_fr01_02: not-found detail shows empty state',
      (tester) async {
        await setUpPricingE2E(
          detailScenario: FakePricingScenario.ruleDetailNotFound,
        );
        await tester.pumpWidget(
          buildPricingRouter(initialLocation: '/pricing/missing-rule'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Không tìm thấy'), findsOneWidget);
      },
    );
  });

  group('e2e_e02_u02 — choose method (S4)', () {
    testWidgets(
      'e2e_e02_u02_fr01_01: choose method navigates to create and import',
      (tester) async {
        await setUpPricingE2E();
        await tester.pumpWidget(
          buildPricingRouter(initialLocation: '/pricing/choose-method'),
        );
        await tester.pumpAndSettle();

        expect(findByWgtKey('wgt_e02_u02_fr01_01'), findsOneWidget);
        expect(find.text('Tạo thủ công'), findsOneWidget);
        expect(find.text('Nhập từ Excel'), findsOneWidget);

        await tester.tap(find.text('Tạo thủ công'));
        await tester.pumpAndSettle();
        expect(findByWgtKey('wgt_e02_u04_fr01_01'), findsOneWidget);
      },
    );

    testWidgets(
      'e2e_e02_u02_fr01_01b: choose method navigates to import',
      (tester) async {
        await setUpPricingE2E();
        await tester.pumpWidget(
          buildPricingRouter(initialLocation: '/pricing/choose-method'),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Nhập từ Excel'));
        await tester.pumpAndSettle();
        expect(findByWgtKey('wgt_e02_u05_fr01_01'), findsOneWidget);
      },
    );

    testWidgets(
      'e2e_e02_u02_fr01_02: neither capability shows no-permission empty',
      (tester) async {
        await setUpPricingE2E();
        await tester.pumpWidget(
          MaterialApp(
            theme: VTheme.lightTheme,
            home: const PricingChooseMethodPage(
              canCreate: false,
              canImport: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Không có quyền'), findsOneWidget);
      },
    );
  });
}
