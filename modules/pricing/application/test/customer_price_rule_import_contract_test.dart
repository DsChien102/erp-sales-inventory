import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_application/testing.dart';

void main() {
  group('S8 import contracts', () {
    test('publishes the canonical V1 template identifiers', () {
      expect(
        CustomerPriceRuleImportTemplateDto.versionV1,
        'customer_price_rules_v1',
      );
      expect(
        CustomerPriceRuleImportTemplateDto.fileNameV1,
        'customer_price_rules_v1.xlsx',
      );
    });

    test('normalizes business date and optional cursor', () {
      final confirm = ConfirmCustomerPriceRuleImportCommand(
        tenantId: 'tenant-1',
        actorId: 'user-1',
        importId: 'import-1',
        expectedVersion: 1,
        businessDate: DateTime(2026, 7, 16, 19, 45),
        acknowledgeWarningRows: true,
      );
      final get = GetCustomerPriceRuleImportQuery(
        tenantId: 'tenant-1',
        importId: 'import-1',
        cursor: '   ',
      );

      expect(confirm.businessDate, DateTime.utc(2026, 7, 16));
      expect(get.cursor, isNull);
    });

    test('rejects invalid start payload', () async {
      final validator = StartCustomerPriceRuleImportCommandValidator();
      final command = StartCustomerPriceRuleImportCommand(
        tenantId: 'tenant-1',
        actorId: 'user-1',
        templateVersion: 'customer_price_rules_v1',
        originalFileName: 'rules.csv',
        fileBytes: Uint8List(0),
        importMode: CustomerPriceRuleImportMode.upsert,
      );

      await expectLater(
        validator.validate(command),
        _throwsValidationField('originalFileName'),
      );
    });

    test('enforces size boundary 5 MiB', () async {
      final validator = StartCustomerPriceRuleImportCommandValidator();
      final valid = _startCommand(Uint8List(5 * 1024 * 1024));
      final invalid = _startCommand(Uint8List(5 * 1024 * 1024 + 1));

      await validator.validate(valid);
      await expectLater(
        validator.validate(invalid),
        _throwsValidationField('fileBytes'),
      );
    });

    test('expected version must be positive for confirm/cancel', () async {
      final confirmValidator = ConfirmCustomerPriceRuleImportCommandValidator();
      final cancelValidator = CancelCustomerPriceRuleImportCommandValidator();
      await expectLater(
        confirmValidator.validate(
          ConfirmCustomerPriceRuleImportCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            importId: 'import-1',
            expectedVersion: 0,
            businessDate: DateTime.utc(2026, 7, 16),
            acknowledgeWarningRows: true,
          ),
        ),
        _throwsValidationField('expectedVersion'),
      );
      await expectLater(
        cancelValidator.validate(
          CancelCustomerPriceRuleImportCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            importId: 'import-1',
            expectedVersion: 0,
          ),
        ),
        _throwsValidationField('expectedVersion'),
      );
    });

    test('validates opaque cursor base64url json shape', () async {
      final validator = GetCustomerPriceRuleImportQueryValidator();
      final goodCursor = base64Url.encode(
        utf8.encode(jsonEncode({'rowNumber': 12, 'id': 'row-uuid'})),
      );
      await validator.validate(
        GetCustomerPriceRuleImportQuery(
          tenantId: 'tenant-1',
          importId: 'import-1',
          cursor: goodCursor,
        ),
      );
      await expectLater(
        validator.validate(
          GetCustomerPriceRuleImportQuery(
            tenantId: 'tenant-1',
            importId: 'import-1',
            cursor: 'not-base64',
          ),
        ),
        _throwsValidationField('cursor'),
      );
    });

    test('exported enum values keep frozen snake-case mapping', () {
      expect(CustomerPriceRuleImportMode.values.map((e) => e.name), [
        'createOnly',
        'updateOnly',
        'upsert',
      ]);
      expect(CustomerPriceRuleImportStatus.values.map((e) => e.name), [
        'failed',
        'readyToImport',
        'completed',
        'completedWithErrors',
        'canceled',
      ]);
    });

    test('V1 parsed and preview rows expose explicit product-unit identity', () {
      const parsed = CustomerPriceRuleImportParsedRow(
        rowNumber: 2,
        customerId: '00000000-0000-4000-8000-000000000001',
        productId: '00000000-0000-4000-8000-000000000101',
        productUnitId: '00000000-0000-4000-8000-000000000201',
        price: '100000',
      );
      const preview = CustomerPriceRuleImportRowPreviewDto(
        id: 'row-1',
        rowNumber: 2,
        ruleId: null,
        customerId: '00000000-0000-4000-8000-000000000001',
        productId: '00000000-0000-4000-8000-000000000101',
        productUnitId: '00000000-0000-4000-8000-000000000201',
        price: '100000',
        effectiveFrom: null,
        effectiveTo: null,
        note: null,
        status: CustomerPriceRuleImportRowStatus.valid,
        action: CustomerPriceRuleImportAction.create,
        errorCodes: [],
        warningCodes: [],
        unitResolutionStrategy: ProductUnitResolutionStrategy.explicitSelection,
      );

      expect(parsed.productId, preview.productId);
      expect(parsed.productUnitId, preview.productUnitId);
      expect(
        preview.unitResolutionStrategy,
        ProductUnitResolutionStrategy.explicitSelection,
      );
    });

    test('fake scenario matrix for S8 is exhaustive', () {
      final importScenarios = FakePricingScenario.values
          .map((scenario) => scenario.name)
          .where((name) => name.startsWith('import'))
          .toSet();
      expect(importScenarios, {
        'importTemplateV1',
        'importReadyMixed',
        'importFailedBadFile',
        'importProductUnitMismatch',
        'importModeMismatch',
        'importGetNotFound',
        'importConfirmNeedsAcknowledgement',
        'importConfirmPartial',
        'importConfirmRetry',
        'importConfirmStateChanged',
        'importConfirmDenied',
        'importCancelOk',
        'importCancelStateChanged',
        'importCancelInvalidStatus',
      });
    });
  });

  group('fake import scenarios', () {
    test('importConfirmRetry returns deterministic replay result', () async {
      final module = FakePricingModule(
        scenario: FakePricingScenario.importConfirmRetry,
      );

      final result = await module.executeCommandAsync(
        ConfirmCustomerPriceRuleImportCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          importId: 'import-1',
          expectedVersion: 1,
          businessDate: DateTime.utc(2026, 7, 16),
          acknowledgeWarningRows: true,
        ),
      );

      expect(result.isReplay, isTrue);
      expect(result.batch.id, 'import-1');
      expect(result.batch.status, CustomerPriceRuleImportStatus.completed);
    });
  });
}

StartCustomerPriceRuleImportCommand _startCommand(Uint8List bytes) =>
    StartCustomerPriceRuleImportCommand(
      tenantId: 'tenant-1',
      actorId: 'user-1',
      templateVersion: 'customer_price_rules_v1',
      originalFileName: 'customer_price_rules_v1.xlsx',
      fileBytes: bytes,
      importMode: CustomerPriceRuleImportMode.upsert,
    );

Matcher _throwsValidationField(String field) => throwsA(
  isA<PricingBlockedException>()
      .having(
        (error) => error.code,
        'code',
        PricingBlockedCodes.validationError,
      )
      .having(
        (error) => (error.details['fieldErrors'] as Map?)?.containsKey(field),
        'fieldErrors contains $field',
        isTrue,
      ),
);
