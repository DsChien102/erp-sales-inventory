import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/pricing/data/models.dart';
import 'package:erp/features/pricing/data/pricing_errors.dart';
import 'package:erp/features/pricing/logic/pricing_rules.dart';
import 'package:flutter_test/flutter_test.dart';

const _validUuid = '11111111-1111-4111-8111-111111111111';
const _validUuid2 = '22222222-2222-4222-8222-222222222222';
const _validUuid3 = '33333333-3333-4333-8333-333333333333';
const _validToken =
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

Matcher _throwsFieldError(
  String field,
  String errorCode, {
  String? serverMessage,
}) => throwsA(
  isA<AppException>()
      .having((e) => e.code, 'code', PricingErrorCodes.validationError)
      .having(
        (e) => serverMessage == null ? true : e.serverMessage == serverMessage,
        'serverMessage',
        isTrue,
      )
      .having(
        (e) => e.details?['fieldErrors'],
        'fieldErrors',
        {field: errorCode},
      ),
);

Matcher _throwsSalesValidation(String message) => throwsA(
  isA<AppException>()
      .having((e) => e.code, 'code', PricingErrorCodes.validationError)
      .having((e) => e.serverMessage, 'serverMessage', message)
      .having((e) => e.details, 'details', isNull),
);

void main() {
  group('checkCreateRule', () {
    test('accepts valid payload and same calendar day with different hours', () {
      expect(
        () => checkCreateRule(
          customerId: _validUuid,
          productId: _validUuid2,
          productUnitId: _validUuid3,
          idempotencyKey: 'idem-1',
          rulePriceMinor: 100000,
          currencyCode: ' vnd ',
          effectiveFrom: DateTime(2026, 11, 4, 23, 0),
          effectiveTo: DateTime(2026, 11, 4, 1, 0),
        ),
        returnsNormally,
      );
    });

    test('rejects empty customerId', () {
      expect(
        () => checkCreateRule(
          customerId: '   ',
          productId: _validUuid2,
          productUnitId: _validUuid3,
          idempotencyKey: 'idem-1',
          rulePriceMinor: 100000,
          currencyCode: 'VND',
          effectiveFrom: DateTime(2026, 11, 4),
        ),
        _throwsFieldError(
          'customerId',
          'required',
          serverMessage: 'Invalid customer price rule payload.',
        ),
      );
    });

    test('rejects empty productId', () {
      expect(
        () => checkCreateRule(
          customerId: _validUuid,
          productId: '',
          productUnitId: _validUuid3,
          idempotencyKey: 'idem-1',
          rulePriceMinor: 100000,
          currencyCode: 'VND',
          effectiveFrom: DateTime(2026, 11, 4),
        ),
        _throwsFieldError('productId', 'required'),
      );
    });

    test('rejects empty productUnitId', () {
      expect(
        () => checkCreateRule(
          customerId: _validUuid,
          productId: _validUuid2,
          productUnitId: ' ',
          idempotencyKey: 'idem-1',
          rulePriceMinor: 100000,
          currencyCode: 'VND',
          effectiveFrom: DateTime(2026, 11, 4),
        ),
        _throwsFieldError('productUnitId', 'required'),
      );
    });

    test('rejects empty idempotencyKey', () {
      expect(
        () => checkCreateRule(
          customerId: _validUuid,
          productId: _validUuid2,
          productUnitId: _validUuid3,
          idempotencyKey: ' ',
          rulePriceMinor: 100000,
          currencyCode: 'VND',
          effectiveFrom: DateTime(2026, 11, 4),
        ),
        _throwsFieldError('idempotencyKey', 'required'),
      );
    });

    test('rejects non-positive rulePriceMinor (0)', () {
      expect(
        () => checkCreateRule(
          customerId: _validUuid,
          productId: _validUuid2,
          productUnitId: _validUuid3,
          idempotencyKey: 'idem-1',
          rulePriceMinor: 0,
          currencyCode: 'VND',
          effectiveFrom: DateTime(2026, 11, 4),
        ),
        _throwsFieldError('rulePriceMinor', 'must_be_positive'),
      );
    });

    test('rejects invalid currencyCode', () {
      expect(
        () => checkCreateRule(
          customerId: _validUuid,
          productId: _validUuid2,
          productUnitId: _validUuid3,
          idempotencyKey: 'idem-1',
          rulePriceMinor: 100,
          currencyCode: 'VN1',
          effectiveFrom: DateTime(2026, 11, 4),
        ),
        _throwsFieldError('currencyCode', 'invalid_currency'),
      );
    });

    test('rejects effectiveTo on previous calendar day', () {
      expect(
        () => checkCreateRule(
          customerId: _validUuid,
          productId: _validUuid2,
          productUnitId: _validUuid3,
          idempotencyKey: 'idem-1',
          rulePriceMinor: 100,
          currencyCode: 'VND',
          effectiveFrom: DateTime(2026, 11, 4),
          effectiveTo: DateTime(2026, 11, 3, 23, 59),
        ),
        _throwsFieldError('effectiveTo', 'before_effective_from'),
      );
    });
  });

  group('checkUpdateRule', () {
    test('accepts valid payload', () {
      expect(
        () => checkUpdateRule(
          ruleId: _validUuid,
          expectedVersion: 1,
          rulePriceMinor: 90000,
          effectiveFrom: DateTime(2026, 11, 4),
          effectiveTo: DateTime(2026, 11, 4),
        ),
        returnsNormally,
      );
    });

    test('rejects empty ruleId', () {
      expect(
        () => checkUpdateRule(
          ruleId: ' ',
          expectedVersion: 1,
          rulePriceMinor: 90000,
          effectiveFrom: DateTime(2026, 11, 4),
        ),
        _throwsFieldError(
          'ruleId',
          'required',
          serverMessage: 'Invalid customer price rule update payload.',
        ),
      );
    });

    test('rejects non-UUID ruleId', () {
      expect(
        () => checkUpdateRule(
          ruleId: 'not-a-uuid',
          expectedVersion: 1,
          rulePriceMinor: 90000,
          effectiveFrom: DateTime(2026, 11, 4),
        ),
        _throwsFieldError('ruleId', 'invalid'),
      );
    });

    test('rejects non-positive expectedVersion', () {
      expect(
        () => checkUpdateRule(
          ruleId: _validUuid,
          expectedVersion: 0,
          rulePriceMinor: 90000,
          effectiveFrom: DateTime(2026, 11, 4),
        ),
        _throwsFieldError('expectedVersion', 'must_be_positive'),
      );
    });

    test('rejects non-positive rulePriceMinor', () {
      expect(
        () => checkUpdateRule(
          ruleId: _validUuid,
          expectedVersion: 1,
          rulePriceMinor: 0,
          effectiveFrom: DateTime(2026, 11, 4),
        ),
        _throwsFieldError('rulePriceMinor', 'must_be_positive'),
      );
    });

    test('rejects effectiveTo before effectiveFrom', () {
      expect(
        () => checkUpdateRule(
          ruleId: _validUuid,
          expectedVersion: 1,
          rulePriceMinor: 90000,
          effectiveFrom: DateTime(2026, 11, 4),
          effectiveTo: DateTime(2026, 11, 3),
        ),
        _throwsFieldError('effectiveTo', 'before_effective_from'),
      );
    });

    test('h5_reason_over_200_rejected', () {
      expect(
        () => checkUpdateRule(
          ruleId: _validUuid,
          expectedVersion: 1,
          rulePriceMinor: 90000,
          effectiveFrom: DateTime(2026, 11, 4),
          changeReason: 'a' * 201,
        ),
        _throwsFieldError(
          'reason',
          'too_long',
          serverMessage: 'Invalid customer price rule update payload.',
        ),
      );

      expect(
        () => checkUpdateRule(
          ruleId: _validUuid,
          expectedVersion: 1,
          rulePriceMinor: 90000,
          effectiveFrom: DateTime(2026, 11, 4),
          changeReason: 'a' * 200,
        ),
        returnsNormally,
      );
    });
  });

  group('checkDisableRule', () {
    test('accepts valid payload and 500-char reason', () {
      expect(
        () => checkDisableRule(
          ruleId: _validUuid,
          expectedVersion: 1,
          reason: 'a' * 500,
        ),
        returnsNormally,
      );
    });

    test('rejects empty ruleId', () {
      expect(
        () => checkDisableRule(ruleId: '', expectedVersion: 1),
        _throwsFieldError(
          'ruleId',
          'required',
          serverMessage: 'Invalid customer price rule disable payload.',
        ),
      );
    });

    test('rejects invalid UUID ruleId', () {
      expect(
        () => checkDisableRule(ruleId: 'bad', expectedVersion: 1),
        _throwsFieldError('ruleId', 'invalid'),
      );
    });

    test('rejects non-positive expectedVersion', () {
      expect(
        () => checkDisableRule(ruleId: _validUuid, expectedVersion: 0),
        _throwsFieldError('expectedVersion', 'must_be_positive'),
      );
    });

    test('rejects 501-char reason after trim', () {
      expect(
        () => checkDisableRule(
          ruleId: _validUuid,
          expectedVersion: 1,
          reason: 'a' * 501,
        ),
        _throwsFieldError('reason', 'too_long'),
      );
    });
  });

  group('checkReenableRule', () {
    test('accepts valid payload with or without precheckToken', () {
      expect(
        () => checkReenableRule(
          ruleId: _validUuid,
          expectedVersion: 1,
          precheckToken: _validToken,
        ),
        returnsNormally,
      );
      expect(
        () => checkReenableRule(ruleId: _validUuid, expectedVersion: 1),
        returnsNormally,
      );
    });

    test('rejects empty ruleId', () {
      expect(
        () => checkReenableRule(ruleId: ' ', expectedVersion: 1),
        _throwsFieldError(
          'ruleId',
          'required',
          serverMessage: 'Invalid customer price rule reenable payload.',
        ),
      );
    });

    test('rejects invalid UUID ruleId', () {
      expect(
        () => checkReenableRule(ruleId: 'bad', expectedVersion: 1),
        _throwsFieldError('ruleId', 'invalid'),
      );
    });

    test('rejects non-positive expectedVersion', () {
      expect(
        () => checkReenableRule(ruleId: _validUuid, expectedVersion: 0),
        _throwsFieldError('expectedVersion', 'must_be_positive'),
      );
    });

    test('rejects invalid precheckToken', () {
      expect(
        () => checkReenableRule(
          ruleId: _validUuid,
          expectedVersion: 1,
          precheckToken: 'not-64-hex',
        ),
        _throwsFieldError('precheckToken', 'invalid'),
      );
    });
  });

  group('checkPrecheckReenable', () {
    test('accepts valid payload', () {
      expect(
        () => checkPrecheckReenable(ruleId: _validUuid, expectedVersion: 2),
        returnsNormally,
      );
    });

    test('rejects empty ruleId', () {
      expect(
        () => checkPrecheckReenable(ruleId: '', expectedVersion: 2),
        _throwsFieldError(
          'ruleId',
          'required',
          serverMessage:
              'Invalid customer price rule reenable precheck payload.',
        ),
      );
    });

    test('rejects invalid UUID ruleId', () {
      expect(
        () => checkPrecheckReenable(ruleId: 'bad', expectedVersion: 2),
        _throwsFieldError('ruleId', 'invalid'),
      );
    });

    test('rejects non-positive expectedVersion', () {
      expect(
        () => checkPrecheckReenable(ruleId: _validUuid, expectedVersion: 0),
        _throwsFieldError('expectedVersion', 'must_be_positive'),
      );
    });
  });

  group('checkRuleId', () {
    test('accepts valid UUID', () {
      expect(() => checkRuleId(_validUuid), returnsNormally);
    });

    test('rejects empty ruleId', () {
      expect(
        () => checkRuleId('  '),
        _throwsFieldError(
          'ruleId',
          'required',
          serverMessage: 'Invalid customer price rule detail payload.',
        ),
      );
    });

    test('rejects invalid UUID', () {
      expect(
        () => checkRuleId('bad-id'),
        _throwsFieldError('ruleId', 'invalid'),
      );
    });
  });

  group('checkHistoryPage', () {
    test('accepts valid payload', () {
      expect(
        () => checkHistoryPage(
          ruleId: _validUuid,
          cursor: 'c' * 1024,
          limit: 100,
        ),
        returnsNormally,
      );
    });

    test('rejects empty and invalid ruleId', () {
      expect(
        () => checkHistoryPage(ruleId: '', limit: 50),
        _throwsFieldError(
          'ruleId',
          'required',
          serverMessage: 'Invalid customer price rule history payload.',
        ),
      );
      expect(
        () => checkHistoryPage(ruleId: 'bad', limit: 50),
        _throwsFieldError('ruleId', 'invalid'),
      );
    });

    test('rejects limit out of 1..100', () {
      expect(
        () => checkHistoryPage(ruleId: _validUuid, limit: 0),
        _throwsFieldError('limit', 'out_of_range'),
      );
      expect(
        () => checkHistoryPage(ruleId: _validUuid, limit: 101),
        _throwsFieldError('limit', 'out_of_range'),
      );
    });

    test('rejects cursor > 1024 chars', () {
      expect(
        () => checkHistoryPage(
          ruleId: _validUuid,
          cursor: 'c' * 1025,
          limit: 50,
        ),
        _throwsFieldError('cursor', 'too_long'),
      );
    });
  });

  group('checkSearch', () {
    test('accepts valid payload', () {
      expect(
        () => checkSearch(
          q: 'q' * 120,
          customerId: _validUuid,
          productId: _validUuid2,
          limit: 20,
        ),
        returnsNormally,
      );
    });

    test('rejects limit out of 1..100', () {
      expect(
        () => checkSearch(limit: 0),
        _throwsFieldError(
          'limit',
          'out_of_range',
          serverMessage: 'Invalid customer price rule search payload.',
        ),
      );
      expect(
        () => checkSearch(limit: 101),
        _throwsFieldError('limit', 'out_of_range'),
      );
    });

    test('rejects q > 120 chars after trim', () {
      expect(
        () => checkSearch(q: 'q' * 121, limit: 20),
        _throwsFieldError('q', 'too_long'),
      );
    });

    test('rejects blank customerId or productId when provided', () {
      expect(
        () => checkSearch(customerId: '  ', limit: 20),
        _throwsFieldError('customerId', 'blank'),
      );
      expect(
        () => checkSearch(productId: '  ', limit: 20),
        _throwsFieldError('productId', 'blank'),
      );
    });
  });

  group('checkResolve', () {
    test('accepts valid UUIDs', () {
      expect(
        () => checkResolve(
          customerId: _validUuid,
          productId: _validUuid2,
          productUnitId: _validUuid3,
        ),
        returnsNormally,
      );
    });

    test('rejects empty or invalid customerId, productId, productUnitId', () {
      expect(
        () => checkResolve(
          customerId: ' ',
          productId: _validUuid2,
          productUnitId: _validUuid3,
        ),
        _throwsFieldError(
          'customerId',
          'required',
          serverMessage:
              'Invalid resolve applicable customer price rule payload.',
        ),
      );
      expect(
        () => checkResolve(
          customerId: 'bad',
          productId: _validUuid2,
          productUnitId: _validUuid3,
        ),
        _throwsFieldError('customerId', 'invalid'),
      );
      expect(
        () => checkResolve(
          customerId: _validUuid,
          productId: '',
          productUnitId: _validUuid3,
        ),
        _throwsFieldError('productId', 'required'),
      );
      expect(
        () => checkResolve(
          customerId: _validUuid,
          productId: 'bad',
          productUnitId: _validUuid3,
        ),
        _throwsFieldError('productId', 'invalid'),
      );
      expect(
        () => checkResolve(
          customerId: _validUuid,
          productId: _validUuid2,
          productUnitId: '',
        ),
        _throwsFieldError('productUnitId', 'required'),
      );
      expect(
        () => checkResolve(
          customerId: _validUuid,
          productId: _validUuid2,
          productUnitId: 'bad',
        ),
        _throwsFieldError('productUnitId', 'invalid'),
      );
    });
  });

  group('checkSalesPreview', () {
    const validLine = SalesPricingLineInput(
      localLineId: 'line-1',
      productId: 'prod-1',
      productUnitId: 'unit-1',
      quantityMicros: 1000000,
    );

    test('accepts valid payload', () {
      expect(
        () => checkSalesPreview(
          storeId: 'store-1',
          customerId: 'cust-1',
          currencyCode: 'VND',
          effectiveAt: DateTime.utc(2026, 11, 4),
          contextVersion: 0,
          lines: const [validLine],
        ),
        returnsNormally,
      );
    });

    test('rejects blank storeId', () {
      expect(
        () => checkSalesPreview(
          storeId: ' ',
          currencyCode: 'VND',
          effectiveAt: DateTime.utc(2026, 11, 4),
          contextVersion: 1,
          lines: const [validLine],
        ),
        _throwsSalesValidation('Tenant and store are required.'),
      );
    });

    test('rejects blank customerId', () {
      expect(
        () => checkSalesPreview(
          storeId: 'store-1',
          customerId: '  ',
          currencyCode: 'VND',
          effectiveAt: DateTime.utc(2026, 11, 4),
          contextVersion: 1,
          lines: const [validLine],
        ),
        _throwsSalesValidation('Customer id cannot be blank.'),
      );
    });

    test('rejects non-VND currencyCode', () {
      expect(
        () => checkSalesPreview(
          storeId: 'store-1',
          currencyCode: 'USD',
          effectiveAt: DateTime.utc(2026, 11, 4),
          contextVersion: 1,
          lines: const [validLine],
        ),
        _throwsSalesValidation('Only VND pricing is supported.'),
      );
    });

    test('rejects non-UTC effectiveAt', () {
      expect(
        () => checkSalesPreview(
          storeId: 'store-1',
          currencyCode: 'VND',
          effectiveAt: DateTime(2026, 11, 4, 10),
          contextVersion: 1,
          lines: const [validLine],
        ),
        _throwsSalesValidation('Effective time must be UTC.'),
      );
    });

    test('rejects negative contextVersion', () {
      expect(
        () => checkSalesPreview(
          storeId: 'store-1',
          currencyCode: 'VND',
          effectiveAt: DateTime.utc(2026, 11, 4),
          contextVersion: -1,
          lines: const [validLine],
        ),
        _throwsSalesValidation('Context version cannot be negative.'),
      );
    });

    test('rejects empty lines', () {
      expect(
        () => checkSalesPreview(
          storeId: 'store-1',
          currencyCode: 'VND',
          effectiveAt: DateTime.utc(2026, 11, 4),
          contextVersion: 1,
          lines: const [],
        ),
        _throwsSalesValidation('At least one pricing line is required.'),
      );
    });

    test('rejects blank line identifiers', () {
      expect(
        () => checkSalesPreview(
          storeId: 'store-1',
          currencyCode: 'VND',
          effectiveAt: DateTime.utc(2026, 11, 4),
          contextVersion: 1,
          lines: const [
            SalesPricingLineInput(
              localLineId: ' ',
              productId: 'prod-1',
              productUnitId: 'unit-1',
              quantityMicros: 1000000,
            ),
          ],
        ),
        _throwsSalesValidation('Pricing line identifiers are required.'),
      );
    });

    test('rejects non-positive quantityMicros', () {
      expect(
        () => checkSalesPreview(
          storeId: 'store-1',
          currencyCode: 'VND',
          effectiveAt: DateTime.utc(2026, 11, 4),
          contextVersion: 1,
          lines: const [
            SalesPricingLineInput(
              localLineId: 'line-1',
              productId: 'prod-1',
              productUnitId: 'unit-1',
              quantityMicros: 0,
            ),
          ],
        ),
        _throwsSalesValidation('Quantity must be positive.'),
      );
    });

    test('rejects > 1 manual pricing intent on a line', () {
      expect(
        () => checkSalesPreview(
          storeId: 'store-1',
          currencyCode: 'VND',
          effectiveAt: DateTime.utc(2026, 11, 4),
          contextVersion: 1,
          lines: const [
            SalesPricingLineInput(
              localLineId: 'line-1',
              productId: 'prod-1',
              productUnitId: 'unit-1',
              quantityMicros: 1000000,
              manualUnitPriceMinor: 50000,
              manualDiscountMinor: 5000,
            ),
          ],
        ),
        _throwsSalesValidation('Only one manual pricing intent is allowed.'),
      );
    });

    test('rejects negative manual monetary values', () {
      expect(
        () => checkSalesPreview(
          storeId: 'store-1',
          currencyCode: 'VND',
          effectiveAt: DateTime.utc(2026, 11, 4),
          contextVersion: 1,
          lines: const [
            SalesPricingLineInput(
              localLineId: 'line-1',
              productId: 'prod-1',
              productUnitId: 'unit-1',
              quantityMicros: 1000000,
              manualUnitPriceMinor: -1,
            ),
          ],
        ),
        _throwsSalesValidation('Manual monetary values cannot be negative.'),
      );
    });

    test('rejects discount basis points outside 0..10000', () {
      expect(
        () => checkSalesPreview(
          storeId: 'store-1',
          currencyCode: 'VND',
          effectiveAt: DateTime.utc(2026, 11, 4),
          contextVersion: 1,
          lines: const [
            SalesPricingLineInput(
              localLineId: 'line-1',
              productId: 'prod-1',
              productUnitId: 'unit-1',
              quantityMicros: 1000000,
              manualDiscountBasisPoints: 10001,
            ),
          ],
        ),
        _throwsSalesValidation('Discount basis points must be in 0..10000.'),
      );
    });

    test('rejects duplicate localLineId', () {
      expect(
        () => checkSalesPreview(
          storeId: 'store-1',
          currencyCode: 'VND',
          effectiveAt: DateTime.utc(2026, 11, 4),
          contextVersion: 1,
          lines: const [validLine, validLine],
        ),
        _throwsSalesValidation('Local line ids must be unique.'),
      );
    });
  });

  group('checkSalesManualPrice', () {
    test('accepts valid payload with exactly one manual intent', () {
      expect(
        () => checkSalesManualPrice(
          storeId: 'store-1',
          customerId: 'cust-1',
          productId: 'prod-1',
          productUnitId: 'unit-1',
          quantityMicros: 1000000,
          currencyCode: 'VND',
          contextVersion: 0,
          manualUnitPriceMinor: 90000,
        ),
        returnsNormally,
      );
    });

    test('rejects blank storeId', () {
      expect(
        () => checkSalesManualPrice(
          storeId: ' ',
          productId: 'prod-1',
          productUnitId: 'unit-1',
          quantityMicros: 1000000,
          currencyCode: 'VND',
          contextVersion: 1,
          manualUnitPriceMinor: 90000,
        ),
        _throwsSalesValidation('Tenant and store are required.'),
      );
    });

    test('rejects blank customerId', () {
      expect(
        () => checkSalesManualPrice(
          storeId: 'store-1',
          customerId: ' ',
          productId: 'prod-1',
          productUnitId: 'unit-1',
          quantityMicros: 1000000,
          currencyCode: 'VND',
          contextVersion: 1,
          manualUnitPriceMinor: 90000,
        ),
        _throwsSalesValidation('Customer id cannot be blank.'),
      );
    });

    test('rejects blank productId or productUnitId', () {
      expect(
        () => checkSalesManualPrice(
          storeId: 'store-1',
          productId: ' ',
          productUnitId: 'unit-1',
          quantityMicros: 1000000,
          currencyCode: 'VND',
          contextVersion: 1,
          manualUnitPriceMinor: 90000,
        ),
        _throwsSalesValidation('Product and product unit are required.'),
      );
    });

    test('rejects non-positive quantityMicros', () {
      expect(
        () => checkSalesManualPrice(
          storeId: 'store-1',
          productId: 'prod-1',
          productUnitId: 'unit-1',
          quantityMicros: 0,
          currencyCode: 'VND',
          contextVersion: 1,
          manualUnitPriceMinor: 90000,
        ),
        _throwsSalesValidation('Quantity must be positive.'),
      );
    });

    test('rejects non-VND currencyCode', () {
      expect(
        () => checkSalesManualPrice(
          storeId: 'store-1',
          productId: 'prod-1',
          productUnitId: 'unit-1',
          quantityMicros: 1000000,
          currencyCode: 'USD',
          contextVersion: 1,
          manualUnitPriceMinor: 90000,
        ),
        _throwsSalesValidation('Only VND pricing is supported.'),
      );
    });

    test('rejects negative contextVersion', () {
      expect(
        () => checkSalesManualPrice(
          storeId: 'store-1',
          productId: 'prod-1',
          productUnitId: 'unit-1',
          quantityMicros: 1000000,
          currencyCode: 'VND',
          contextVersion: -1,
          manualUnitPriceMinor: 90000,
        ),
        _throwsSalesValidation('Context version cannot be negative.'),
      );
    });

    test('rejects 0 or 2 manual pricing intents', () {
      expect(
        () => checkSalesManualPrice(
          storeId: 'store-1',
          productId: 'prod-1',
          productUnitId: 'unit-1',
          quantityMicros: 1000000,
          currencyCode: 'VND',
          contextVersion: 1,
        ),
        _throwsSalesValidation('Exactly one manual pricing intent is required.'),
      );
      expect(
        () => checkSalesManualPrice(
          storeId: 'store-1',
          productId: 'prod-1',
          productUnitId: 'unit-1',
          quantityMicros: 1000000,
          currencyCode: 'VND',
          contextVersion: 1,
          manualUnitPriceMinor: 90000,
          manualDiscountMinor: 5000,
        ),
        _throwsSalesValidation('Exactly one manual pricing intent is required.'),
      );
    });

    test('rejects negative manual monetary values', () {
      expect(
        () => checkSalesManualPrice(
          storeId: 'store-1',
          productId: 'prod-1',
          productUnitId: 'unit-1',
          quantityMicros: 1000000,
          currencyCode: 'VND',
          contextVersion: 1,
          manualDiscountMinor: -1,
        ),
        _throwsSalesValidation('Manual monetary values cannot be negative.'),
      );
    });

    test('rejects discount basis points outside 0..10000', () {
      expect(
        () => checkSalesManualPrice(
          storeId: 'store-1',
          productId: 'prod-1',
          productUnitId: 'unit-1',
          quantityMicros: 1000000,
          currencyCode: 'VND',
          contextVersion: 1,
          manualDiscountBasisPoints: 10001,
        ),
        _throwsSalesValidation('Discount basis points must be in 0..10000.'),
      );
    });
  });

  group('normalizeRuleNote', () {
    test('trims non-empty note and maps blank/null to null', () {
      expect(normalizeRuleNote('  ghi chú  '), 'ghi chú');
      expect(normalizeRuleNote('  '), isNull);
      expect(normalizeRuleNote(null), isNull);
    });
  });
}

