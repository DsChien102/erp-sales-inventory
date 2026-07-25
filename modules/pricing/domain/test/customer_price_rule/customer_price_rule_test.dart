import 'package:test/test.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('Money', () {
    test('uses positive integer minor units and normalizes currency', () {
      final money = Money(amountMinor: 125000, currencyCode: 'vnd');

      expect(money.amountMinor, 125000);
      expect(money.currencyCode, 'VND');
    });

    test('rejects zero or negative amount', () {
      expect(
        () => Money(amountMinor: 0, currencyCode: 'VND'),
        throwsA(isA<BusinessRuleValidationException>()),
      );
      expect(
        () => Money(amountMinor: -1, currencyCode: 'VND'),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });

  group('EffectivePeriod', () {
    test('uses closed interval overlap semantics', () {
      final first = EffectivePeriod(
        effectiveFrom: DateTime.utc(2026, 7, 1),
        effectiveTo: DateTime.utc(2026, 7, 10),
      );
      final touching = EffectivePeriod(
        effectiveFrom: DateTime.utc(2026, 7, 10),
        effectiveTo: DateTime.utc(2026, 7, 20),
      );

      expect(first.overlaps(touching), isTrue);
    });

    test('rejects a reversed date range', () {
      expect(
        () => EffectivePeriod(
          effectiveFrom: DateTime.utc(2026, 7, 2),
          effectiveTo: DateTime.utc(2026, 7, 1),
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });

  group('RuleValidationOutcome', () {
    final rulePrice = Money(amountMinor: 900, currencyCode: 'VND');
    final listPrice = Money(amountMinor: 1200, currencyCode: 'VND');
    final floorPrice = Money(amountMinor: 1000, currencyCode: 'VND');

    test('is not checked when catalog has no floor', () {
      final outcome = RuleValidationOutcome.evaluateFloor(
        rulePrice: rulePrice,
        listPrice: listPrice,
      );

      expect(outcome.outcome, RuleValidationState.valid);
      expect(outcome.priceCheckStatus, PriceCheckStatus.notChecked);
    });

    test('blocks below floor without acknowledgement', () {
      final outcome = RuleValidationOutcome.evaluateFloor(
        rulePrice: rulePrice,
        listPrice: listPrice,
        floorPrice: floorPrice,
        acknowledgeFloorWarning: false,
        canOverrideFloor: true,
      );

      expect(outcome.outcome, RuleValidationState.blocked);
      expect(outcome.blockingCodes, contains('acknowledgement_required'));
    });

    test('allows acknowledged below-floor price with override permission', () {
      final outcome = RuleValidationOutcome.evaluateFloor(
        rulePrice: rulePrice,
        listPrice: listPrice,
        floorPrice: floorPrice,
        acknowledgeFloorWarning: true,
        canOverrideFloor: true,
      );

      expect(outcome.outcome, RuleValidationState.warning);
      expect(outcome.priceCheckStatus, PriceCheckStatus.overrideAllowed);
      expect(outcome.warningCodes, contains('below_floor_price'));
    });
  });

  test('createManual creates an active version-one rule and domain event', () {
    final rule = CustomerPriceRule.createManual(
      id: 'rule-1',
      key: CustomerPriceRuleKey(
        tenantId: 'tenant-1',
        customerId: 'customer-1',
        productId: 'product-1',
        productUnitId: 'unit-1',
      ),
      price: Money(amountMinor: 125000, currencyCode: 'VND'),
      effectivePeriod: EffectivePeriod(
        effectiveFrom: DateTime.utc(2026, 7, 16),
      ),
      actorId: 'user-1',
      validationOutcome: RuleValidationOutcome.clear(),
      note: 'VIP',
    );

    expect(rule.status, CustomerPriceRuleStatus.active);
    expect(rule.ruleType, CustomerPriceRuleType.specialPrice);
    expect(rule.sourceType, CustomerPriceRuleSourceType.manual);
    expect(rule.version, 1);
    expect(rule.domainEvents, hasLength(1));
    expect(
      rule.domainEvents!.single,
      isA<CustomerPriceRuleCreatedDomainEvent>(),
    );
  });

  group('CustomerPriceRule update', () {
    test('reconstitution emits no event and preserves immutable identity', () {
      final rule = _reconstitutedRule();

      expect(rule.domainEvents, isNull);
      expect(rule.key.customerId, 'customer-1');
      expect(rule.sourceType, CustomerPriceRuleSourceType.manual);
      expect(rule.version, 3);
    });

    test(
      'meaningful update normalizes note increments version and emits event',
      () {
        final rule = _reconstitutedRule();
        final changed = rule.updateMutableFields(
          price: Money(amountMinor: 95000, currencyCode: 'VND'),
          effectivePeriod: EffectivePeriod(
            effectiveFrom: DateTime.utc(2026, 7, 17),
          ),
          validationOutcome: RuleValidationOutcome.clear(),
          note: ' Updated note ',
        );

        expect(changed, isTrue);
        expect(rule.price.amountMinor, 95000);
        expect(rule.note, 'Updated note');
        expect(rule.version, 4);
        expect(rule.key.customerId, 'customer-1');
        final event =
            rule.domainEvents!.single as CustomerPriceRuleUpdatedDomainEvent;
        expect(event.ruleId, 'rule-1');
        expect(event.previousVersion, 3);
        expect(event.newVersion, 4);
      },
    );

    test('normalized no-op does not change version or emit event', () {
      final rule = _reconstitutedRule(note: 'VIP');
      final changed = rule.updateMutableFields(
        price: Money(amountMinor: 90000, currencyCode: 'VND'),
        effectivePeriod: EffectivePeriod(
          effectiveFrom: DateTime.utc(2026, 7, 16, 22),
        ),
        validationOutcome: RuleValidationOutcome.clear(),
        note: ' VIP ',
      );

      expect(changed, isFalse);
      expect(rule.version, 3);
      expect(rule.domainEvents, isNull);
    });

    test('disabled rule stays disabled after mutable update', () {
      final rule = _reconstitutedRule(status: CustomerPriceRuleStatus.disabled);
      rule.updateMutableFields(
        price: Money(amountMinor: 95000, currencyCode: 'VND'),
        effectivePeriod: rule.effectivePeriod,
        validationOutcome: RuleValidationOutcome.clear(),
      );
      expect(rule.status, CustomerPriceRuleStatus.disabled);
    });

    test('fixed needs-review rule returns to active', () {
      final rule = _reconstitutedRule(
        status: CustomerPriceRuleStatus.needsReview,
        reviewStatus: CustomerPriceRuleReviewStatus.needsReview,
      );
      rule.updateMutableFields(
        price: Money(amountMinor: 95000, currencyCode: 'VND'),
        effectivePeriod: rule.effectivePeriod,
        validationOutcome: RuleValidationOutcome.clear(),
      );
      expect(rule.status, CustomerPriceRuleStatus.active);
      expect(rule.reviewStatus, CustomerPriceRuleReviewStatus.clear);
    });

    test(
      'rejects a currency change and leaves version and events unchanged',
      () {
        final rule = _reconstitutedRule();

        expect(
          () => rule.updateMutableFields(
            price: Money(amountMinor: 95000, currencyCode: 'USD'),
            effectivePeriod: rule.effectivePeriod,
            validationOutcome: RuleValidationOutcome.clear(),
          ),
          throwsA(isA<BusinessRuleValidationException>()),
        );
        expect(rule.price.currencyCode, 'VND');
        expect(rule.version, 3);
        expect(rule.domainEvents, isNull);
      },
    );
  });

  group('CustomerPriceRule disable', () {
    for (final status in [
      CustomerPriceRuleStatus.active,
      CustomerPriceRuleStatus.needsReview,
    ]) {
      test('$status becomes disabled once', () {
        final rule = _reconstitutedRule(status: status);
        final changed = rule.disable();

        expect(changed, isTrue);
        expect(rule.status, CustomerPriceRuleStatus.disabled);
        expect(rule.version, 4);
        final event =
            rule.domainEvents!.single as CustomerPriceRuleDisabledDomainEvent;
        expect(event.ruleId, 'rule-1');
        expect(event.previousVersion, 3);
        expect(event.newVersion, 4);
      });
    }

    test('already disabled is an idempotent no-op', () {
      final rule = _reconstitutedRule(status: CustomerPriceRuleStatus.disabled);
      expect(rule.disable(), isFalse);
      expect(rule.version, 3);
      expect(rule.domainEvents, isNull);
    });

    test('deleted cannot be disabled', () {
      final rule = _reconstitutedRule(
        status: CustomerPriceRuleStatus.deleted,
        deletedAt: DateTime.utc(2026, 7, 1),
      );
      expect(
        () => rule.disable(),
        throwsA(isA<BusinessRuleValidationException>()),
      );
      expect(rule.version, 3);
      expect(rule.domainEvents, isNull);
    });
  });

  group('CustomerPriceRule reenable', () {
    test('reenable activates disabled rule and emits one event', () {
      final rule = _disabledRule(version: 4);
      final changed = rule.reenable(RuleValidationOutcome.clear());

      expect(changed, isTrue);
      expect(rule.status, CustomerPriceRuleStatus.active);
      expect(rule.reviewStatus, CustomerPriceRuleReviewStatus.clear);
      expect(rule.version, 5);
      expect(rule.domainEvents, hasLength(1));
      expect(
        rule.domainEvents!.single,
        isA<CustomerPriceRuleReenabledDomainEvent>(),
      );
    });

    test('reenable accepts warning and preserves warning review', () {
      final rule = _disabledRule(version: 4);
      final warning = RuleValidationOutcome(
        outcome: RuleValidationState.warning,
        priceCheckStatus: PriceCheckStatus.overrideAllowed,
        warningCodes: const ['below_floor_price'],
      );

      rule.reenable(warning);
      expect(rule.status, CustomerPriceRuleStatus.active);
      expect(rule.reviewStatus, CustomerPriceRuleReviewStatus.warning);
      expect(rule.validationOutcome, warning);
    });

    test('blocked outcome leaves disabled rule unchanged', () {
      final rule = _disabledRule(version: 4);
      final blocked = RuleValidationOutcome(
        outcome: RuleValidationState.blocked,
        priceCheckStatus: PriceCheckStatus.belowFloorBlocked,
        blockingCodes: const ['override_permission_required'],
      );

      expect(
        () => rule.reenable(blocked),
        throwsA(isA<BusinessRuleValidationException>()),
      );
      expect(rule.status, CustomerPriceRuleStatus.disabled);
      expect(rule.version, 4);
      expect(rule.domainEvents, isNull);
    });

    for (final status in [
      CustomerPriceRuleStatus.active,
      CustomerPriceRuleStatus.needsReview,
    ]) {
      test('$status rejects reenable without mutation', () {
        final rule = _reconstitutedRule(status: status);
        expect(
          () => rule.reenable(RuleValidationOutcome.clear()),
          throwsA(isA<BusinessRuleValidationException>()),
        );
        expect(rule.version, 3);
        expect(rule.domainEvents, isNull);
      });
    }
  });
}

CustomerPriceRule _disabledRule({required int version}) =>
    CustomerPriceRule.reconstitute(
      id: 'rule-1',
      key: CustomerPriceRuleKey(
        tenantId: 'tenant-1',
        customerId: 'customer-1',
        productId: 'product-1',
        productUnitId: 'unit-1',
      ),
      price: Money(amountMinor: 90000, currencyCode: 'VND'),
      effectivePeriod: EffectivePeriod(
        effectiveFrom: DateTime.utc(2026, 7, 16),
      ),
      actorId: 'user-previous',
      validationOutcome: RuleValidationOutcome.clear(),
      ruleType: CustomerPriceRuleType.specialPrice,
      sourceType: CustomerPriceRuleSourceType.manual,
      status: CustomerPriceRuleStatus.disabled,
      reviewStatus: CustomerPriceRuleReviewStatus.clear,
      version: version,
    );

CustomerPriceRule _reconstitutedRule({
  String? note,
  CustomerPriceRuleStatus status = CustomerPriceRuleStatus.active,
  CustomerPriceRuleReviewStatus reviewStatus =
      CustomerPriceRuleReviewStatus.clear,
  DateTime? deletedAt,
}) => CustomerPriceRule.reconstitute(
  id: 'rule-1',
  key: CustomerPriceRuleKey(
    tenantId: 'tenant-1',
    customerId: 'customer-1',
    productId: 'product-1',
    productUnitId: 'unit-1',
  ),
  price: Money(amountMinor: 90000, currencyCode: 'VND'),
  effectivePeriod: EffectivePeriod(effectiveFrom: DateTime.utc(2026, 7, 16)),
  actorId: 'user-previous',
  validationOutcome: RuleValidationOutcome.clear(),
  note: note,
  ruleType: CustomerPriceRuleType.specialPrice,
  sourceType: CustomerPriceRuleSourceType.manual,
  status: status,
  reviewStatus: reviewStatus,
  version: 3,
  deletedAt: deletedAt,
);
