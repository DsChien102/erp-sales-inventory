import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_application/testing.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:erp/features/pricing/presentation.dart';

import '../../pricing_e2e_harness.dart';

void main() {
  tearDown(() async {
    await tearDownPricingE2E();
  });

  group('e2e_e02_u07 — disable (S6)', () {
    testWidgets(
      'e2e_e02_u07_fr01_01: disable from detail updates to disabled',
      (tester) async {
        await setUpPricingE2E(
          detailScenario: FakePricingScenario.ruleDetailActive,
          disableScenario: FakePricingScenario.disableRuleOk,
          historyScenario: FakePricingScenario.historyEmptyLegacy,
        );

        await tester.pumpWidget(
          buildPricingRouter(initialLocation: '/pricing/fake-rule-1'),
        );
        await tester.pumpAndSettle();

        expect(findByWgtKey('wgt_e02_u03_fr01_01'), findsOneWidget);

        final cubit = tester
            .element(findByWgtKey('wgt_e02_u03_fr01_01'))
            .read<PriceRuleDetailCubit>();
        final loaded = cubit.state;
        expect(loaded, isA<PriceRuleDetailLoaded>());
        final rule = (loaded as PriceRuleDetailLoaded).rule;

        final result = await cubit.disableRule(
          ruleId: rule.id,
          expectedVersion: rule.version,
          reason: 'e2e disable',
        );
        await tester.pumpAndSettle();

        expect(result, isNotNull);
        expect(result!.persistedStatus, CustomerPriceRuleStatus.disabled);
        expect(
          result.availableActions,
          contains(CustomerPriceRuleAvailableActions.reenable),
        );
      },
    );
  });

  group('e2e_e02_u08 — reenable (S7)', () {
    testWidgets(
      'e2e_e02_u08_fr01_01: reenable from disabled detail succeeds',
      (tester) async {
        await setUpPricingE2E(
          detailScenario: FakePricingScenario.ruleDetailDisabled,
          reenableScenario: FakePricingScenario.reenableOk,
          historyScenario: FakePricingScenario.historyEmptyLegacy,
        );

        await tester.pumpWidget(
          buildPricingRouter(initialLocation: '/pricing/fake-rule-1'),
        );
        await tester.pumpAndSettle();

        final cubit = tester
            .element(findByWgtKey('wgt_e02_u03_fr01_01'))
            .read<PriceRuleDetailCubit>();
        final loaded = cubit.state;
        expect(loaded, isA<PriceRuleDetailLoaded>());
        final rule = (loaded as PriceRuleDetailLoaded).rule;

        final result = await cubit.reenableRule(
          ruleId: rule.id,
          expectedVersion: rule.version,
        );
        await tester.pumpAndSettle();

        expect(result, isNotNull);
        expect(result!.persistedStatus, CustomerPriceRuleStatus.active);
        expect(
          result.availableActions,
          isNot(contains(CustomerPriceRuleAvailableActions.reenable)),
        );
      },
    );
  });
}
