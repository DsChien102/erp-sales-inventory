import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_application/testing.dart';
import 'package:vet45_pricing_domain/domain.dart'
    hide
        CustomerPriceRuleImportMode,
        CustomerPriceRuleImportRowStatus,
        CustomerPriceRuleImportStatus;

void main() {
  test('importReadyMixed exposes duplicate as a skippable row error', () async {
    final module = FakePricingModule(
      scenario: FakePricingScenario.importReadyMixed,
    );

    final detail = await module
        .executeCommandAsync<CustomerPriceRuleImportDetailDto>(
          StartCustomerPriceRuleImportCommand(
            tenantId: 'tenant-1',
            templateVersion: CustomerPriceRuleImportTemplateDto.versionV1,
            originalFileName: 'mixed.xlsx',
            fileBytes: Uint8List.fromList(const [1, 2, 3]),
            importMode: CustomerPriceRuleImportMode.upsert,
          ),
        );

    expect(detail.batch.validRows, 1);
    expect(detail.batch.warningRows, 1);
    expect(detail.batch.errorRows, 1);
    final duplicate = detail.rows.items.singleWhere(
      (row) => row.errorCodes.contains('DUPLICATE_ACTIVE_RULE'),
    );
    expect(duplicate.status, CustomerPriceRuleImportRowStatus.error);
    expect(duplicate.action, CustomerPriceRuleImportAction.skip);
  });

  test('importReadyMixed retains selected conversion unit', () async {
    final module = FakePricingModule(
      scenario: FakePricingScenario.importReadyMixed,
    );

    final detail = await module
        .executeCommandAsync<CustomerPriceRuleImportDetailDto>(
          StartCustomerPriceRuleImportCommand(
            tenantId: 'tenant-1',
            templateVersion: CustomerPriceRuleImportTemplateDto.versionV1,
            originalFileName: 'mixed.xlsx',
            fileBytes: Uint8List.fromList(const [1, 2, 3]),
            importMode: CustomerPriceRuleImportMode.upsert,
          ),
        );

    final row = detail.rows.items.first;
    expect(row.productUnitId, row.unitSnapshot?['product_unit_id']);
    expect(row.unitSnapshot?['is_base_unit'], isFalse);
    expect(
      row.unitResolutionStrategy,
      ProductUnitResolutionStrategy.explicitSelection,
    );
  });

  test(
    'upsert auto-match one previews an update without input rule id',
    () async {
      final module = FakePricingModule(
        scenario: FakePricingScenario.importUpsertAutoMatchOne,
      );

      final detail = await module
          .executeCommandAsync<CustomerPriceRuleImportDetailDto>(
            StartCustomerPriceRuleImportCommand(
              tenantId: 'tenant-1',
              templateVersion: CustomerPriceRuleImportTemplateDto.versionV1,
              originalFileName: 'auto-match.xlsx',
              fileBytes: Uint8List.fromList(const [0x50, 0x4B, 0x03, 0x04]),
              importMode: CustomerPriceRuleImportMode.upsert,
            ),
          );

      final row = detail.rows.items.single;
      expect(row.ruleId, isNull);
      expect(row.action, CustomerPriceRuleImportAction.update);
      expect(row.status, CustomerPriceRuleImportRowStatus.valid);
      expect(row.matchedRuleId, '00000000-0000-4000-8000-000000000101');
      expect(row.matchedRuleVersion, 3);
      expect(row.errorCodes, isEmpty);
    },
  );

  test('upsert auto-match many previews an ambiguous blocking error', () async {
    final module = FakePricingModule(
      scenario: FakePricingScenario.importUpsertAutoMatchMany,
    );

    final detail = await module
        .executeCommandAsync<CustomerPriceRuleImportDetailDto>(
          StartCustomerPriceRuleImportCommand(
            tenantId: 'tenant-1',
            templateVersion: CustomerPriceRuleImportTemplateDto.versionV1,
            originalFileName: 'auto-match.xlsx',
            fileBytes: Uint8List.fromList(const [0x50, 0x4B, 0x03, 0x04]),
            importMode: CustomerPriceRuleImportMode.upsert,
          ),
        );

    final row = detail.rows.items.single;
    expect(row.ruleId, isNull);
    expect(row.action, CustomerPriceRuleImportAction.skip);
    expect(row.status, CustomerPriceRuleImportRowStatus.error);
    expect(row.matchedRuleId, isNull);
    expect(row.matchedRuleVersion, isNull);
    expect(row.errorCodes, ['AMBIGUOUS_OVERLAPPING_RULES']);
  });

  test('createRuleOk returns an active rule', () async {
    final module = FakePricingModule(
      scenario: FakePricingScenario.createRuleOk,
    );

    final result = await module.executeCommandAsync(_command());

    expect(result.rule.persistedStatus, CustomerPriceRuleStatus.active);
    expect(result.rule.derivedStatus, CustomerPriceRuleDerivedStatus.applying);
    expect(result.rule.validationOutcome.outcome, 'notChecked');
    expect(result.rule.validationOutcome.floorPriceHidden, isFalse);
    expect(
      result.rule.referenceHealth.customerState,
      CustomerPriceRuleReferenceState.valid,
    );
    expect(result.rule.sourceTrace.hidden, isFalse);
    expect(result.rule.createdBy, 'fake-user-1');
  });

  test('createRuleFloorWarning returns stable warning', () async {
    final module = FakePricingModule(
      scenario: FakePricingScenario.createRuleFloorWarning,
    );

    final result = await module.executeCommandAsync(_command());

    expect(result.warnings.single.code, 'below_floor_price');
  });

  test('createRuleDuplicate overwrites and creates rule successfully', () async {
    final module = FakePricingModule(
      scenario: FakePricingScenario.createRuleDuplicate,
    );

    final result = await module.executeCommandAsync(_command());

    expect(result.rule.id, isNotNull);
  });

  for (final entry in {
    FakePricingScenario.createRuleFloorBlocked:
        PricingBlockedCodes.belowFloorBlocked,
    FakePricingScenario.createRuleReferenceInvalid:
        PricingBlockedCodes.referenceInvalid,
    FakePricingScenario.createRuleIdempotencyConflict:
        PricingBlockedCodes.idempotencyConflict,
  }.entries) {
    test('${entry.key.name} returns ${entry.value}', () async {
      final module = FakePricingModule(scenario: entry.key);

      await expectLater(
        module.executeCommandAsync(_command()),
        throwsA(
          isA<PricingBlockedException>().having(
            (error) => error.code,
            'code',
            entry.value,
          ),
        ),
      );
    });
  }

  test('createRuleIdempotentRetry returns the same rule', () async {
    final module = FakePricingModule(
      scenario: FakePricingScenario.createRuleIdempotentRetry,
    );

    final first = await module.executeCommandAsync(_command());
    final second = await module.executeCommandAsync(_command());

    expect(first.rule.id, second.rule.id);
  });

  test('updateRuleFloorWarning returns stable warning snapshot', () async {
    final module = FakePricingModule(
      scenario: FakePricingScenario.updateRuleFloorWarning,
    );
    final result = await module.executeCommandAsync(_updateCommand());
    expect(result.validationOutcome.warningCodes, ['below_floor_price']);
  });

  test('updateRuleDisabled preserves disabled lifecycle', () async {
    final module = FakePricingModule(
      scenario: FakePricingScenario.updateRuleDisabled,
    );
    final result = await module.executeCommandAsync(_updateCommand());
    expect(result.persistedStatus, CustomerPriceRuleStatus.disabled);
    expect(result.derivedStatus, CustomerPriceRuleDerivedStatus.disabled);
  });

  test('memoryCreateOk returns created outcome with rule identity', () async {
    final module = FakePricingModule(
      scenario: FakePricingScenario.memoryCreateOk,
    );
    final result = await module.executeCommandAsync(_memoryCommand());

    expect(result.resultType, RememberedPriceResultType.created);
    expect(result.ruleId, isNotNull);
    expect(result.ruleVersion, 1);
    expect(result.isReplay, isFalse);
  });

  test('memoryUpdateOk returns updated outcome with rule version', () async {
    final module = FakePricingModule(
      scenario: FakePricingScenario.memoryUpdateOk,
    );
    final result = await module.executeCommandAsync(_memoryCommand());

    expect(result.resultType, RememberedPriceResultType.updated);
    expect(result.ruleVersion, 2);
  });

  test('memoryRetrySamePayload returns replayed original outcome', () async {
    final module = FakePricingModule(
      scenario: FakePricingScenario.memoryRetrySamePayload,
    );
    final result = await module.executeCommandAsync(_memoryCommand());

    expect(result.isReplay, isTrue);
    expect(result.requestId, '00000000-0000-4000-8000-000000000201');
  });

  for (final entry in {
    FakePricingScenario.memoryManualConflict: (
      RememberedPriceResultType.skipped,
      'MANUAL_RULE_PROTECTED',
    ),
    FakePricingScenario.memoryAnonymousCustomer: (
      RememberedPriceResultType.skipped,
      'ANONYMOUS_CUSTOMER',
    ),
    FakePricingScenario.memoryStaleSaleSkipped: (
      RememberedPriceResultType.skipped,
      'STALE_SALE_EVENT',
    ),
    FakePricingScenario.memoryDisabledRememberedSkipped: (
      RememberedPriceResultType.skipped,
      'REMEMBERED_RULE_DISABLED',
    ),
    FakePricingScenario.memoryReferenceInvalid: (
      RememberedPriceResultType.blocked,
      'REFERENCE_INVALID',
    ),
    FakePricingScenario.memoryBelowFloorBlocked: (
      RememberedPriceResultType.blocked,
      'BELOW_FLOOR_BLOCKED',
    ),
  }.entries) {
    test('${entry.key.name} returns stable stored outcome', () async {
      final module = FakePricingModule(scenario: entry.key);
      final result = await module.executeCommandAsync(_memoryCommand());

      expect(result.resultType, entry.value.$1);
      expect(result.reasonCode, entry.value.$2);
    });
  }

  test('memoryKeyConflict throws IDEMPOTENCY_CONFLICT', () async {
    final module = FakePricingModule(
      scenario: FakePricingScenario.memoryKeyConflict,
    );

    await expectLater(
      module.executeCommandAsync(_memoryCommand()),
      throwsA(
        isA<PricingBlockedException>().having(
          (error) => error.code,
          'code',
          PricingBlockedCodes.idempotencyConflict,
        ),
      ),
    );
  });

  test('memorySystemError throws SYSTEM_ERROR', () async {
    final module = FakePricingModule(
      scenario: FakePricingScenario.memorySystemError,
    );

    await expectLater(
      module.executeCommandAsync(_memoryCommand()),
      throwsA(
        isA<PricingBlockedException>().having(
          (error) => error.code,
          'code',
          PricingBlockedCodes.systemError,
        ),
      ),
    );
  });
}

CreateCustomerPriceRuleCommand _command() => CreateCustomerPriceRuleCommand(
  customerId: 'customer-1',
  productId: 'product-1',
  productUnitId: 'unit-1',
  rulePriceMinor: 125000,
  currencyCode: 'VND',
  effectiveFrom: DateTime.utc(2026, 7, 16),
  acknowledgeFloorWarning: false,
  idempotencyKey: 'idem-1',
);

UpdateCustomerPriceRuleCommand _updateCommand() =>
    UpdateCustomerPriceRuleCommand(
      tenantId: 'tenant-1',
      actorId: 'user-1',
      ruleId: '00000000-0000-4000-8000-000000000001',
      expectedVersion: 3,
      rulePriceMinor: 95000,
      effectiveFrom: DateTime.utc(2026, 7, 16, 15),
      acknowledgeFloorWarning: false,
    );

SaveRememberedPriceFromOrderCommand _memoryCommand() =>
    SaveRememberedPriceFromOrderCommand(
      tenantId: 'tenant-1',
      actorId: 'user-1',
      sourceOrderId: '00000000-0000-4000-8000-000000000101',
      sourceOrderLineId: '00000000-0000-4000-8000-000000000102',
      customerId: '00000000-0000-4000-8000-000000000103',
      productId: '00000000-0000-4000-8000-000000000104',
      productUnitId: '00000000-0000-4000-8000-000000000105',
      soldPriceMinor: 90000,
      currencyCode: 'VND',
      soldAt: DateTime.utc(2026, 7, 16, 1, 30),
      idempotencyKey: 'order-line-102',
    );
