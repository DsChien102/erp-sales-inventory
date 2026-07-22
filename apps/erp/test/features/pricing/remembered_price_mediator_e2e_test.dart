import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_application/testing.dart';

import 'pricing_e2e_harness.dart';

void main() {
  tearDown(() async {
    await tearDownPricingE2E();
  });

  group('S9 remembered price mediator smoke', () {
    test('memoryCreateOk returns created outcome via IPricingModule', () async {
      await setUpPricingE2E(
        memoryScenario: FakePricingScenario.memoryCreateOk,
      );

      final module = GetIt.instance<IPricingModule>();
      final result = await module.executeCommandAsync(
        SaveRememberedPriceFromOrderCommand(
          sourceOrderId: '00000000-0000-4000-8000-000000000201',
          sourceOrderLineId: '00000000-0000-4000-8000-000000000202',
          customerId: '00000000-0000-4000-8000-000000000002',
          productId: '00000000-0000-4000-8000-000000000003',
          productUnitId: '00000000-0000-4000-8000-000000000004',
          soldPriceMinor: 125000,
          currencyCode: 'VND',
          soldAt: DateTime.utc(2026, 7, 16, 9),
          idempotencyKey: 'memory-key-1',
        ),
      );

      expect(result.resultType.name, 'created');
      expect(result.ruleId, isNotNull);
      expect(result.isReplay, isFalse);
    });

    test(
      'memoryManualConflict returns skipped MANUAL_RULE_PROTECTED',
      () async {
        await setUpPricingE2E(
          memoryScenario: FakePricingScenario.memoryManualConflict,
        );

        final module = GetIt.instance<IPricingModule>();
        final result = await module.executeCommandAsync(
          SaveRememberedPriceFromOrderCommand(
            sourceOrderId: '00000000-0000-4000-8000-000000000201',
            sourceOrderLineId: '00000000-0000-4000-8000-000000000202',
            customerId: '00000000-0000-4000-8000-000000000002',
            productId: '00000000-0000-4000-8000-000000000003',
            productUnitId: '00000000-0000-4000-8000-000000000004',
            soldPriceMinor: 125000,
            currencyCode: 'VND',
            soldAt: DateTime.utc(2026, 7, 16, 9),
            idempotencyKey: 'memory-key-2',
          ),
        );

        expect(result.resultType.name, 'skipped');
        expect(result.reasonCode, 'MANUAL_RULE_PROTECTED');
      },
    );

    test(
      'memoryAnonymousCustomer returns skipped ANONYMOUS_CUSTOMER',
      () async {
        await setUpPricingE2E(
          memoryScenario: FakePricingScenario.memoryAnonymousCustomer,
        );

        final module = GetIt.instance<IPricingModule>();
        final result = await module.executeCommandAsync(
          SaveRememberedPriceFromOrderCommand(
            sourceOrderId: '00000000-0000-4000-8000-000000000201',
            sourceOrderLineId: '00000000-0000-4000-8000-000000000202',
            customerId: null,
            productId: '00000000-0000-4000-8000-000000000003',
            productUnitId: '00000000-0000-4000-8000-000000000004',
            soldPriceMinor: 125000,
            currencyCode: 'VND',
            soldAt: DateTime.utc(2026, 7, 16, 9),
            idempotencyKey: 'memory-key-3',
          ),
        );

        expect(result.resultType.name, 'skipped');
        expect(result.reasonCode, 'ANONYMOUS_CUSTOMER');
      },
    );
  });
}
