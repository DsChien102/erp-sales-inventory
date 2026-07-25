import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  group('SaveRememberedPriceFromOrderCommand', () {
    test('normalizes currency, soldAt, and idempotency key', () {
      final command = SaveRememberedPriceFromOrderCommand(
        id: 'command-1',
        sourceOrderId: '00000000-0000-4000-8000-000000000101',
        sourceOrderLineId: '00000000-0000-4000-8000-000000000102',
        customerId: '00000000-0000-4000-8000-000000000103',
        productId: '00000000-0000-4000-8000-000000000104',
        productUnitId: '00000000-0000-4000-8000-000000000105',
        soldPriceMinor: 90000,
        currencyCode: ' vnd ',
        soldAt: DateTime.parse('2026-07-16T08:30:00+07:00'),
        idempotencyKey: ' order-line-102 ',
      );

      expect(command.currencyCode, 'VND');
      expect(command.soldAt, DateTime.utc(2026, 7, 16, 1, 30));
      expect(command.idempotencyKey, 'order-line-102');
      expect(command, isA<ITenantScopedCommand>());
    });

    test('exposes stable save_memory permission code', () {
      expect(
        PricingPermissions.savePriceMemory,
        'pricing.customer_price_rule.save_memory',
      );
      expect(SaveRememberedPriceFromOrderCommand, isA<Type>());
    });

    test('withExecutionContext preserves snapshot fields', () {
      final command = _command();
      final bound = command.withExecutionContext(
        tenantId: 'tenant-bound',
        actorId: 'actor-bound',
      );

      expect(bound.id, command.id);
      expect(bound.tenantId, 'tenant-bound');
      expect(bound.actorId, 'actor-bound');
      expect(bound.sourceOrderId, command.sourceOrderId);
      expect(bound.sourceOrderLineId, command.sourceOrderLineId);
      expect(bound.customerId, command.customerId);
      expect(bound.productId, command.productId);
      expect(bound.productUnitId, command.productUnitId);
      expect(bound.soldPriceMinor, command.soldPriceMinor);
      expect(bound.currencyCode, command.currencyCode);
      expect(bound.soldAt, command.soldAt);
      expect(bound.idempotencyKey, command.idempotencyKey);
    });

    test('allows nullable anonymous customer', () {
      final command = _command(customerId: null);
      expect(command.customerId, isNull);
    });
  });

  group('RememberedPriceOutcomeDto', () {
    test('is immutable and carries replay flag', () {
      const outcome = RememberedPriceOutcomeDto(
        requestId: 'request-1',
        resultType: RememberedPriceResultType.created,
        ruleId: 'rule-1',
        ruleVersion: 1,
        reasonCode: null,
        warnings: [],
        isReplay: true,
      );

      expect(outcome.resultType, RememberedPriceResultType.created);
      expect(outcome.isReplay, isTrue);
      expect(outcome.warnings, isEmpty);
    });
  });

  group('SaveRememberedPriceFromOrderCommandValidator', () {
    final validator = SaveRememberedPriceFromOrderCommandValidator();

    test('accepts identified and anonymous requests', () async {
      await validator.validate(_command());
      await validator.validate(_command(customerId: null));
      await validator.validate(_command(customerId: '   '));
    });

    test('rejects malformed UUIDs and invalid scalar fields', () async {
      await expectLater(
        validator.validate(_command(sourceOrderId: 'bad')),
        _throwsValidationField('sourceOrderId'),
      );
      await expectLater(
        validator.validate(_command(customerId: 'bad-customer')),
        _throwsValidationField('customerId'),
      );
      await expectLater(
        validator.validate(_command(soldPriceMinor: 0)),
        _throwsValidationField('soldPriceMinor'),
      );
      await expectLater(
        validator.validate(_command(currencyCode: 'VN')),
        _throwsValidationField('currencyCode'),
      );
      await expectLater(
        validator.validate(_command(idempotencyKey: '')),
        _throwsValidationField('idempotencyKey'),
      );
      await expectLater(
        validator.validate(_command(idempotencyKey: 'x' * 201)),
        _throwsValidationField('idempotencyKey'),
      );
    });
  });
}

SaveRememberedPriceFromOrderCommand _command({
  String? customerId = '00000000-0000-4000-8000-000000000103',
  String sourceOrderId = '00000000-0000-4000-8000-000000000101',
  int soldPriceMinor = 90000,
  String currencyCode = 'VND',
  String idempotencyKey = 'order-line-102',
}) => SaveRememberedPriceFromOrderCommand(
  tenantId: '00000000-0000-4000-8000-000000000100',
  actorId: '00000000-0000-4000-8000-000000000099',
  sourceOrderId: sourceOrderId,
  sourceOrderLineId: '00000000-0000-4000-8000-000000000102',
  customerId: customerId,
  productId: '00000000-0000-4000-8000-000000000104',
  productUnitId: '00000000-0000-4000-8000-000000000105',
  soldPriceMinor: soldPriceMinor,
  currencyCode: currencyCode,
  soldAt: DateTime.utc(2026, 7, 16, 1, 30),
  idempotencyKey: idempotencyKey,
);

Matcher _throwsValidationField(String field) => throwsA(
  isA<PricingBlockedException>()
      .having((error) => error.code, 'code', PricingBlockedCodes.validationError)
      .having(
        (error) => (error.details['fieldErrors'] as Map)[field],
        'field',
        isNotNull,
      ),
);
