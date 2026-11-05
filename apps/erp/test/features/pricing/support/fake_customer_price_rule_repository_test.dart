import 'package:erp/core/errors/app_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_pricing_application/application.dart' as old_app;
import 'package:vet45_pricing_application/testing.dart' as old_test;

import 'fake_customer_price_rule_repository.dart';
import 'fake_pricing_backend.dart';

void main() {
  final businessDate = DateTime.utc(2026, 7, 16);

  group('FakeCustomerPriceRuleRepository parity with FakePricingModule', () {
    test('search scenarios: searchRulesDefault, searchRulesEmpty', () async {
      for (final pair in [
        (
          old_test.FakePricingScenario.searchRulesDefault,
          FakePricingScenario.searchRulesDefault,
        ),
        (
          old_test.FakePricingScenario.searchRulesEmpty,
          FakePricingScenario.searchRulesEmpty,
        ),
      ]) {
        final oldRes = await old_test.FakePricingModule(scenario: pair.$1)
            .executeQueryAsync(
              old_app.SearchCustomerPriceRulesQuery(
                tenantId: 'tenant-test',
                businessDate: businessDate,
              ),
            );
        final newRes = await FakeCustomerPriceRuleRepository(
          searchScenario: pair.$2,
        ).search(businessDate: businessDate);

        expect(newRes.availableActions, oldRes.availableActions);
        expect(newRes.page.hasMore, oldRes.page.hasMore);
        expect(newRes.page.items.length, oldRes.page.items.length);
        for (var i = 0; i < newRes.page.items.length; i++) {
          expect(newRes.page.items[i].id, oldRes.page.items[i].id);
          expect(
            newRes.page.items[i].persistedStatus.name,
            oldRes.page.items[i].persistedStatus.name,
          );
          expect(
            newRes.page.items[i].price.amountMinor,
            oldRes.page.items[i].price.amountMinor,
          );
        }
      }
    });

    test(
      'detail scenarios: ruleDetailActive, ruleDetailDisabled, ruleDetailNotFound',
      () async {
        for (final pair in [
          (
            old_test.FakePricingScenario.ruleDetailActive,
            FakePricingScenario.ruleDetailActive,
          ),
          (
            old_test.FakePricingScenario.ruleDetailDisabled,
            FakePricingScenario.ruleDetailDisabled,
          ),
        ]) {
          final oldRes = await old_test.FakePricingModule(scenario: pair.$1)
              .executeQueryAsync(
                old_app.GetCustomerPriceRuleDetailQuery(
                  tenantId: 'tenant-test',
                  ruleId: 'fake-rule-1',
                  businessDate: businessDate,
                ),
              );
          final newRes = await FakeCustomerPriceRuleRepository(
            detailScenario: pair.$2,
          ).getDetail(ruleId: 'fake-rule-1', businessDate: businessDate);

          expect(newRes.id, oldRes.id);
          expect(newRes.version, oldRes.version);
          expect(newRes.persistedStatus.name, oldRes.persistedStatus.name);
          expect(newRes.price.amountMinor, oldRes.price.amountMinor);
        }

        await _expectSameBlockedError(
          () => old_test.FakePricingModule(
            scenario: old_test.FakePricingScenario.ruleDetailNotFound,
          ).executeQueryAsync(
            old_app.GetCustomerPriceRuleDetailQuery(
              tenantId: 'tenant-test',
              ruleId: 'fake-rule-1',
              businessDate: businessDate,
            ),
          ),
          () => FakeCustomerPriceRuleRepository(
            detailScenario: FakePricingScenario.ruleDetailNotFound,
          ).getDetail(ruleId: 'fake-rule-1', businessDate: businessDate),
        );
      },
    );

    test(
      'history scenarios: historyMixedSources, historyEmptyLegacy, historyDenied, historyNotFound, historySystemError',
      () async {
        for (final pair in [
          (
            old_test.FakePricingScenario.historyMixedSources,
            FakePricingScenario.historyMixedSources,
          ),
          (
            old_test.FakePricingScenario.historyEmptyLegacy,
            FakePricingScenario.historyEmptyLegacy,
          ),
        ]) {
          final oldRes = await old_test.FakePricingModule(scenario: pair.$1)
              .executeQueryAsync(
                old_app.GetCustomerPriceRuleHistoryQuery(
                  tenantId: 'tenant-test',
                  ruleId: 'fake-rule-1',
                ),
              );
          final newRes = await FakeCustomerPriceRuleRepository(
            historyScenario: pair.$2,
          ).getHistory(ruleId: 'fake-rule-1');

          expect(newRes.hasMore, oldRes.hasMore);
          expect(newRes.nextCursor, oldRes.nextCursor);
          expect(
            newRes.items.map((e) => e.id).toList(),
            oldRes.items.map((e) => e.id).toList(),
          );
        }

        for (final pair in [
          (
            old_test.FakePricingScenario.historyDenied,
            FakePricingScenario.historyDenied,
          ),
          (
            old_test.FakePricingScenario.historyNotFound,
            FakePricingScenario.historyNotFound,
          ),
          (
            old_test.FakePricingScenario.historySystemError,
            FakePricingScenario.historySystemError,
          ),
        ]) {
          await _expectSameBlockedError(
            () => old_test.FakePricingModule(scenario: pair.$1)
                .executeQueryAsync(
                  old_app.GetCustomerPriceRuleHistoryQuery(
                    tenantId: 'tenant-test',
                    ruleId: 'fake-rule-1',
                  ),
                ),
            () => FakeCustomerPriceRuleRepository(
              historyScenario: pair.$2,
            ).getHistory(ruleId: 'fake-rule-1'),
          );
        }
      },
    );

    test(
      'create scenarios: createRuleOk, createRuleDuplicate, createRuleFloorBlocked',
      () async {
        final oldRes = await old_test.FakePricingModule(
          scenario: old_test.FakePricingScenario.createRuleOk,
        ).executeCommandAsync(
          old_app.CreateCustomerPriceRuleCommand(
            tenantId: 'tenant-test',
            customerId: 'customer-1',
            productId: 'product-1',
            productUnitId: 'unit-1',
            rulePriceMinor: 150000,
            currencyCode: 'VND',
            effectiveFrom: businessDate,
            acknowledgeFloorWarning: false,
            idempotencyKey: 'idem-1',
          ),
        );
        final newRes = await FakeCustomerPriceRuleRepository(
          createScenario: FakePricingScenario.createRuleOk,
        ).create(
          customerId: 'customer-1',
          productId: 'product-1',
          productUnitId: 'unit-1',
          rulePriceMinor: 150000,
          currencyCode: 'VND',
          effectiveFrom: businessDate,
          acknowledgeFloorWarning: false,
          idempotencyKey: 'idem-1',
        );

        expect(newRes.rule.id, oldRes.rule.id);
        expect(newRes.rule.version, oldRes.rule.version);
        expect(
          newRes.rule.persistedStatus.name,
          oldRes.rule.persistedStatus.name,
        );
        expect(newRes.rule.price.amountMinor, oldRes.rule.price.amountMinor);

        for (final pair in [
          (
            old_test.FakePricingScenario.createRuleDuplicate,
            FakePricingScenario.createRuleDuplicate,
          ),
          (
            old_test.FakePricingScenario.createRuleFloorBlocked,
            FakePricingScenario.createRuleFloorBlocked,
          ),
        ]) {
          await _expectSameBlockedError(
            () => old_test.FakePricingModule(scenario: pair.$1)
                .executeCommandAsync(
                  old_app.CreateCustomerPriceRuleCommand(
                    tenantId: 'tenant-test',
                    customerId: 'customer-1',
                    productId: 'product-1',
                    productUnitId: 'unit-1',
                    rulePriceMinor: 150000,
                    currencyCode: 'VND',
                    effectiveFrom: businessDate,
                    acknowledgeFloorWarning: false,
                    idempotencyKey: 'idem-1',
                  ),
                ),
            () => FakeCustomerPriceRuleRepository(
              createScenario: pair.$2,
            ).create(
              customerId: 'customer-1',
              productId: 'product-1',
              productUnitId: 'unit-1',
              rulePriceMinor: 150000,
              currencyCode: 'VND',
              effectiveFrom: businessDate,
              acknowledgeFloorWarning: false,
              idempotencyKey: 'idem-1',
            ),
          );
        }
      },
    );

    test('update scenarios: updateRuleOk, updateRuleStateChanged', () async {
      final oldRes = await old_test.FakePricingModule(
        scenario: old_test.FakePricingScenario.updateRuleOk,
      ).executeCommandAsync(
        old_app.UpdateCustomerPriceRuleCommand(
          tenantId: 'tenant-test',
          ruleId: 'fake-rule-1',
          expectedVersion: 1,
          rulePriceMinor: 160000,
          effectiveFrom: businessDate,
          acknowledgeFloorWarning: false,
        ),
      );
      final newRes = await FakeCustomerPriceRuleRepository(
        updateScenario: FakePricingScenario.updateRuleOk,
      ).update(
        ruleId: 'fake-rule-1',
        expectedVersion: 1,
        rulePriceMinor: 160000,
        effectiveFrom: businessDate,
        acknowledgeFloorWarning: false,
      );

      expect(newRes.id, oldRes.id);
      expect(newRes.version, oldRes.version);
      expect(newRes.persistedStatus.name, oldRes.persistedStatus.name);
      expect(newRes.price.amountMinor, oldRes.price.amountMinor);

      await _expectSameBlockedError(
        () => old_test.FakePricingModule(
          scenario: old_test.FakePricingScenario.updateRuleStateChanged,
        ).executeCommandAsync(
          old_app.UpdateCustomerPriceRuleCommand(
            tenantId: 'tenant-test',
            ruleId: 'fake-rule-1',
            expectedVersion: 1,
            rulePriceMinor: 160000,
            effectiveFrom: businessDate,
            acknowledgeFloorWarning: false,
          ),
        ),
        () => FakeCustomerPriceRuleRepository(
          updateScenario: FakePricingScenario.updateRuleStateChanged,
        ).update(
          ruleId: 'fake-rule-1',
          expectedVersion: 1,
          rulePriceMinor: 160000,
          effectiveFrom: businessDate,
          acknowledgeFloorWarning: false,
        ),
      );
    });

    test('disable scenarios: disableRuleOk, disableRuleStateChanged', () async {
      final oldRes = await old_test.FakePricingModule(
        scenario: old_test.FakePricingScenario.disableRuleOk,
      ).executeCommandAsync(
        old_app.DisableCustomerPriceRuleCommand(
          ruleId: 'fake-rule-1',
          expectedVersion: 1,
          reason: 'ngừng bán',
        ),
      );
      final newRes = await FakeCustomerPriceRuleRepository(
        disableScenario: FakePricingScenario.disableRuleOk,
      ).disable(ruleId: 'fake-rule-1', expectedVersion: 1, reason: 'ngừng bán');

      expect(newRes.id, oldRes.id);
      expect(newRes.version, oldRes.version);
      expect(newRes.persistedStatus.name, oldRes.persistedStatus.name);
      expect(newRes.price.amountMinor, oldRes.price.amountMinor);

      await _expectSameBlockedError(
        () => old_test.FakePricingModule(
          scenario: old_test.FakePricingScenario.disableRuleStateChanged,
        ).executeCommandAsync(
          old_app.DisableCustomerPriceRuleCommand(
            ruleId: 'fake-rule-1',
            expectedVersion: 1,
          ),
        ),
        () => FakeCustomerPriceRuleRepository(
          disableScenario: FakePricingScenario.disableRuleStateChanged,
        ).disable(ruleId: 'fake-rule-1', expectedVersion: 1),
      );
    });

    test('reenable scenarios: reenablePrecheckValid, reenableOk', () async {
      final oldPrecheck = await old_test.FakePricingModule(
        scenario: old_test.FakePricingScenario.reenablePrecheckValid,
      ).executeQueryAsync(
        old_app.PrecheckCustomerPriceRuleReenableQuery(
          tenantId: 'tenant-test',
          ruleId: 'fake-rule-1',
          expectedVersion: 2,
          businessDate: businessDate,
        ),
      );
      final newPrecheck = await FakeCustomerPriceRuleRepository(
        reenablePrecheckScenario: FakePricingScenario.reenablePrecheckValid,
      ).precheckReenable(
        ruleId: 'fake-rule-1',
        expectedVersion: 2,
        businessDate: businessDate,
      );

      expect(newPrecheck.precheckToken, oldPrecheck.precheckToken);
      expect(newPrecheck.ruleVersion, oldPrecheck.ruleVersion);
      expect(
        newPrecheck.validationOutcome.outcome,
        oldPrecheck.validationOutcome.outcome,
      );

      final oldReenable = await old_test.FakePricingModule(
        scenario: old_test.FakePricingScenario.reenableOk,
      ).executeCommandAsync(
        old_app.ReenableCustomerPriceRuleCommand(
          ruleId: 'fake-rule-1',
          expectedVersion: 2,
          businessDate: businessDate,
          acknowledgeFloorWarning: false,
        ),
      );
      final newReenable = await FakeCustomerPriceRuleRepository(
        reenableScenario: FakePricingScenario.reenableOk,
      ).reenable(
        ruleId: 'fake-rule-1',
        expectedVersion: 2,
        businessDate: businessDate,
        acknowledgeFloorWarning: false,
      );

      expect(newReenable.id, oldReenable.id);
      expect(newReenable.version, oldReenable.version);
      expect(
        newReenable.persistedStatus.name,
        oldReenable.persistedStatus.name,
      );
      expect(newReenable.price.amountMinor, oldReenable.price.amountMinor);
    });
  });
}

Future<void> _expectSameBlockedError(
  Future<Object?> Function() oldCall,
  Future<Object?> Function() newCall,
) async {
  old_app.PricingBlockedException? oldErr;
  try {
    await oldCall();
  } on old_app.PricingBlockedException catch (e) {
    oldErr = e;
  }
  AppException? newErr;
  try {
    await newCall();
  } on AppException catch (e) {
    newErr = e;
  }
  expect(oldErr, isNotNull);
  expect(newErr, isNotNull);
  expect(newErr!.code, oldErr!.code);
  expect(newErr.details ?? const <String, Object?>{}, oldErr.details);
}
