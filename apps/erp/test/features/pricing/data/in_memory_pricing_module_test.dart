import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart'
    hide
        CustomerPriceRuleImportMode,
        CustomerPriceRuleImportStatus,
        CustomerPriceRuleImportRowStatus;

import 'package:erp/features/pricing/data/in_memory_pricing_module.dart';

void main() {
  late InMemoryPricingModule module;
  final businessDate = DateTime.now().toUtc();

  setUp(() {
    module = InMemoryPricingModule();
  });

  Future<CustomerPriceRuleSearchResultDto> search() =>
      module.executeQueryAsync(
        SearchCustomerPriceRulesQuery(
          tenantId: 't1',
          businessDate: businessDate,
        ),
      );

  group('InMemoryPricingModule', () {
    test('search trả về seed rules', () async {
      final result = await search();
      expect(result.page.items, isNotEmpty);
      expect(
        result.availableActions,
        containsAll([
          PricingAvailableActions.createManual,
          PricingAvailableActions.import,
        ]),
      );
    });

    test(
      'SG-03: tạo trùng → cảnh báo DUPLICATE_ACTIVE_RULE, acknowledge → ghi đè',
      () async {
        final existing = (await search()).page.items.firstWhere(
          (r) => r.persistedStatus == CustomerPriceRuleStatus.active,
        );

        CreateCustomerPriceRuleCommand buildCommand({required bool ack}) =>
            CreateCustomerPriceRuleCommand(
              tenantId: 't1',
              customerId: existing.customer.customerId,
              productId: existing.productUnit.productId,
              productUnitId: existing.productUnit.productUnitId,
              rulePriceMinor: 20000000,
              currencyCode: 'VND',
              effectiveFrom: businessDate,
              acknowledgeFloorWarning: ack,
              idempotencyKey: 'test-key',
            );

        // Lần 1: cảnh báo trùng.
        await expectLater(
          module.executeCommandAsync(buildCommand(ack: false)),
          throwsA(
            isA<PricingBlockedException>().having(
              (e) => e.code,
              'code',
              PricingBlockedCodes.duplicateActiveRule,
            ),
          ),
        );

        // Lần 2 (acknowledge): ghi đè — rule cũ bị tắt, rule mới active.
        final created = await module.executeCommandAsync(
          buildCommand(ack: true),
        );
        expect(created.rule.persistedStatus, CustomerPriceRuleStatus.active);

        final oldDetail = await module.executeQueryAsync(
          GetCustomerPriceRuleDetailQuery(
            tenantId: 't1',
            ruleId: existing.id,
            businessDate: businessDate,
          ),
        );
        expect(oldDetail.persistedStatus, CustomerPriceRuleStatus.disabled);
      },
    );

    test('SG-05: bật lại tự tắt rule trùng, không throw duplicate', () async {
      // Tạo rule A (active).
      final created = await module.executeCommandAsync(
        CreateCustomerPriceRuleCommand(
          tenantId: 't1',
          customerId: 'KH000123',
          productId: 'product-2',
          productUnitId: 'unit-2a',
          rulePriceMinor: 10000000,
          currencyCode: 'VND',
          effectiveFrom: businessDate,
          acknowledgeFloorWarning: false,
          idempotencyKey: 'k1',
        ),
      );
      final ruleA = created.rule;

      // Tắt rule A.
      final disabled = await module.executeCommandAsync(
        DisableCustomerPriceRuleCommand(
          tenantId: 't1',
          ruleId: ruleA.id,
          expectedVersion: ruleA.version,
        ),
      );

      // Tạo rule B trùng (đang active).
      final createdB = await module.executeCommandAsync(
        CreateCustomerPriceRuleCommand(
          tenantId: 't1',
          customerId: 'KH000123',
          productId: 'product-2',
          productUnitId: 'unit-2a',
          rulePriceMinor: 11000000,
          currencyCode: 'VND',
          effectiveFrom: businessDate,
          acknowledgeFloorWarning: false,
          idempotencyKey: 'k2',
        ),
      );

      // SG-05: bật lại rule A → rule B tự tắt, không exception.
      final reenabled = await module.executeCommandAsync(
        ReenableCustomerPriceRuleCommand(
          tenantId: 't1',
          ruleId: ruleA.id,
          expectedVersion: disabled.version,
          businessDate: businessDate,
          acknowledgeFloorWarning: false,
        ),
      );
      expect(reenabled.persistedStatus, CustomerPriceRuleStatus.active);

      final ruleBDetail = await module.executeQueryAsync(
        GetCustomerPriceRuleDetailQuery(
          tenantId: 't1',
          ruleId: createdB.rule.id,
          businessDate: businessDate,
        ),
      );
      expect(ruleBDetail.persistedStatus, CustomerPriceRuleStatus.disabled);
    });

    test('import: start → confirm tạo rule mới và ghi lịch sử', () async {
      final detail = await module.executeCommandAsync(
        StartCustomerPriceRuleImportCommand(
          tenantId: 't1',
          templateVersion: 'v1',
          originalFileName: 'test.xlsx',
          fileBytes: Uint8List.fromList(const [1, 2, 3]),
          importMode: CustomerPriceRuleImportMode.upsert,
        ),
      );
      expect(
        detail.batch.status,
        CustomerPriceRuleImportStatus.readyToImport,
      );

      final before = (await search()).page.items.length;
      final result = await module.executeCommandAsync(
        ConfirmCustomerPriceRuleImportCommand(
          tenantId: 't1',
          importId: detail.batch.id,
          expectedVersion: detail.batch.version,
          businessDate: businessDate,
          acknowledgeWarningRows: true,
        ),
      );
      expect(result.batch.importedRows, greaterThan(0));

      final after = (await search()).page.items.length;
      expect(after, greaterThan(before));
    });
  });
}
