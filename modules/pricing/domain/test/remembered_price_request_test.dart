import 'package:test/test.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  final soldPrice = Money(amountMinor: 90000, currencyCode: 'vnd');
  final soldAt = DateTime.parse('2026-07-16T08:30:00+07:00');

  RememberedPriceRequest receive({
    String? customerId = '00000000-0000-4000-8000-000000000103',
  }) => RememberedPriceRequest.receive(
    id: 'request-1',
    tenantId: 'tenant-1',
    actorId: 'actor-1',
    sourceOrderId: '00000000-0000-4000-8000-000000000101',
    sourceOrderLineId: '00000000-0000-4000-8000-000000000102',
    customerId: customerId,
    productId: '00000000-0000-4000-8000-000000000104',
    productUnitId: '00000000-0000-4000-8000-000000000105',
    soldPrice: soldPrice,
    soldAt: soldAt,
    idempotencyKey: 'order-line-102',
  );

  group('RememberedPriceRequest.receive', () {
    test('starts in received status with normalized fields', () {
      final request = receive();

      expect(request.status, RememberedPriceRequestStatus.received);
      expect(request.soldPrice.currencyCode, 'VND');
      expect(request.soldAt, DateTime.utc(2026, 7, 16, 1, 30));
      expect(request.idempotencyKey, 'order-line-102');
    });

    test('allows anonymous customer', () {
      final request = receive(customerId: null);

      expect(request.customerId, isNull);
    });

    test('rejects blank source, product, unit, actor, or idempotency key', () {
      expect(
        () => receive().recordOutcome(
          resultType: RememberedPriceResultType.created,
          ruleId: 'rule-1',
          ruleVersion: 1,
          reasonCode: null,
        ),
        returnsNormally,
      );
      expect(
        () => RememberedPriceRequest.receive(
          id: 'request-1',
          tenantId: 'tenant-1',
          actorId: '',
          sourceOrderId: '00000000-0000-4000-8000-000000000101',
          sourceOrderLineId: '00000000-0000-4000-8000-000000000102',
          customerId: 'customer-1',
          productId: '00000000-0000-4000-8000-000000000104',
          productUnitId: '00000000-0000-4000-8000-000000000105',
          soldPrice: soldPrice,
          soldAt: soldAt,
          idempotencyKey: 'order-line-102',
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });

  group('RememberedPriceRequest.recordOutcome', () {
    test('maps created and updated to processed with saved event', () {
      for (final resultType in [
        RememberedPriceResultType.created,
        RememberedPriceResultType.updated,
      ]) {
        final request = receive();
        request.recordOutcome(
          resultType: resultType,
          ruleId: 'rule-1',
          ruleVersion: 2,
          reasonCode: null,
        );

        expect(request.status, RememberedPriceRequestStatus.processed);
        expect(request.domainEvents, hasLength(1));
        final event = request.domainEvents!.single
            as RememberedPriceSavedDomainEvent;
        expect(event.requestId, 'request-1');
        expect(event.ruleId, 'rule-1');
        expect(event.ruleVersion, 2);
        expect(event.resultType, resultType);
      }
    });

    test('maps skipped and blocked with required reason code', () {
      final skipped = receive();
      skipped.recordOutcome(
        resultType: RememberedPriceResultType.skipped,
        ruleId: null,
        ruleVersion: null,
        reasonCode: 'ANONYMOUS_CUSTOMER',
      );
      expect(skipped.status, RememberedPriceRequestStatus.skipped);
      expect(skipped.domainEvents, isNull);

      final blocked = receive();
      blocked.recordOutcome(
        resultType: RememberedPriceResultType.blocked,
        ruleId: null,
        ruleVersion: null,
        reasonCode: 'BELOW_FLOOR_BLOCKED',
      );
      expect(blocked.status, RememberedPriceRequestStatus.blocked);
      expect(blocked.domainEvents, isNull);
    });

    test('requires rule identity for created and updated outcomes', () {
      final request = receive();

      expect(
        () => request.recordOutcome(
          resultType: RememberedPriceResultType.created,
          ruleId: null,
          ruleVersion: 1,
          reasonCode: null,
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
      expect(
        () => request.recordOutcome(
          resultType: RememberedPriceResultType.updated,
          ruleId: 'rule-1',
          ruleVersion: 0,
          reasonCode: null,
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('requires reason code for skipped and blocked outcomes', () {
      final request = receive();

      expect(
        () => request.recordOutcome(
          resultType: RememberedPriceResultType.skipped,
          ruleId: null,
          ruleVersion: null,
          reasonCode: null,
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('rejects every second transition after terminal status', () {
      final request = receive();
      request.recordOutcome(
        resultType: RememberedPriceResultType.created,
        ruleId: 'rule-1',
        ruleVersion: 1,
        reasonCode: null,
      );

      expect(
        () => request.recordOutcome(
          resultType: RememberedPriceResultType.updated,
          ruleId: 'rule-1',
          ruleVersion: 2,
          reasonCode: null,
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });
}
