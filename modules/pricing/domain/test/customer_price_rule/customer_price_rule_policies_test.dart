import 'package:test/test.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('CustomerPriceRuleOverlapPolicy', () {
    test('conflicts when same key and closed intervals touch at boundary', () {
      final existing = _rule(
        id: 'existing',
        from: DateTime.utc(2026, 7, 1),
        to: DateTime.utc(2026, 7, 10),
      );
      final candidate = _rule(
        id: 'candidate',
        from: DateTime.utc(2026, 7, 10),
        to: DateTime.utc(2026, 7, 20),
      );

      expect(
        CustomerPriceRuleOverlapPolicy.conflicts(
          candidate: candidate,
          existing: existing,
        ),
        isTrue,
      );
    });

    test('conflicts when candidate open-ended overlaps existing', () {
      final existing = _rule(
        id: 'existing',
        from: DateTime.utc(2026, 8, 1),
        to: DateTime.utc(2026, 8, 31),
      );
      final candidate = _rule(
        id: 'candidate',
        from: DateTime.utc(2026, 7, 1),
      );

      expect(
        CustomerPriceRuleOverlapPolicy.conflicts(
          candidate: candidate,
          existing: existing,
        ),
        isTrue,
      );
    });

    test('ignores different customer/product/unit keys', () {
      final existing = _rule(id: 'existing', productId: 'product-other');
      final candidate = _rule(id: 'candidate');

      expect(
        CustomerPriceRuleOverlapPolicy.conflicts(
          candidate: candidate,
          existing: existing,
        ),
        isFalse,
      );
    });

    test('ignores disabled and deleted existing rules', () {
      final disabled = _rule(
        id: 'disabled',
        status: CustomerPriceRuleStatus.disabled,
      );
      final deleted = _rule(
        id: 'deleted',
        status: CustomerPriceRuleStatus.deleted,
        deletedAt: DateTime.utc(2026, 7, 1),
      );
      final candidate = _rule(id: 'candidate');

      expect(
        CustomerPriceRuleOverlapPolicy.conflicts(
          candidate: candidate,
          existing: disabled,
        ),
        isFalse,
      );
      expect(
        CustomerPriceRuleOverlapPolicy.conflicts(
          candidate: candidate,
          existing: deleted,
        ),
        isFalse,
      );
    });

    test('excludes self when excludeRuleId matches', () {
      final existing = _rule(id: 'same-rule');
      final candidate = _rule(
        id: 'same-rule',
        from: DateTime.utc(2026, 7, 20),
      );

      expect(
        CustomerPriceRuleOverlapPolicy.conflicts(
          candidate: candidate,
          existing: existing,
          excludeRuleId: 'same-rule',
        ),
        isFalse,
      );
    });

    test('findConflicts returns only overlapping active peers', () {
      final peers = [
        _rule(
          id: 'peer-overlap',
          from: DateTime.utc(2026, 7, 1),
          to: DateTime.utc(2026, 7, 20),
        ),
        _rule(
          id: 'peer-other-product',
          productId: 'product-other',
        ),
        _rule(
          id: 'peer-disabled',
          status: CustomerPriceRuleStatus.disabled,
        ),
      ];
      final candidate = _rule(
        id: 'candidate',
        from: DateTime.utc(2026, 7, 15),
      );

      final conflicts = CustomerPriceRuleOverlapPolicy.findConflicts(
        candidate: candidate,
        existingRules: peers,
      );

      expect(conflicts.map((r) => r.id), ['peer-overlap']);
    });
  });

  group('CustomerPriceRuleEligibilityPolicy', () {
    final businessDate = DateTime.utc(2026, 7, 15);

    test('allows active clear rule in period including open-ended to', () {
      final rule = _rule(
        from: DateTime.utc(2026, 7, 1),
      );

      expect(
        CustomerPriceRuleEligibilityPolicy.isApplicable(rule, businessDate),
        isTrue,
      );
    });

    test('allows active warning below-floor when not blocked', () {
      final rule = _rule(
        validationOutcome: RuleValidationOutcome(
          outcome: RuleValidationState.warning,
          priceCheckStatus: PriceCheckStatus.overrideAllowed,
          warningCodes: const ['below_floor_price'],
        ),
      );

      expect(
        CustomerPriceRuleEligibilityPolicy.isApplicable(rule, businessDate),
        isTrue,
      );
    });

    test('rejects disabled deleted needsReview blocked expired not-yet', () {
      expect(
        CustomerPriceRuleEligibilityPolicy.isApplicable(
          _rule(status: CustomerPriceRuleStatus.disabled),
          businessDate,
        ),
        isFalse,
      );
      expect(
        CustomerPriceRuleEligibilityPolicy.isApplicable(
          _rule(
            status: CustomerPriceRuleStatus.deleted,
            deletedAt: DateTime.utc(2026, 7, 1),
          ),
          businessDate,
        ),
        isFalse,
      );
      expect(
        CustomerPriceRuleEligibilityPolicy.isApplicable(
          _rule(status: CustomerPriceRuleStatus.needsReview),
          businessDate,
        ),
        isFalse,
      );
      expect(
        CustomerPriceRuleEligibilityPolicy.isApplicable(
          _rule(
            validationOutcome: RuleValidationOutcome(
              outcome: RuleValidationState.blocked,
              priceCheckStatus: PriceCheckStatus.belowFloorBlocked,
              blockingCodes: const ['acknowledgement_required'],
            ),
          ),
          businessDate,
        ),
        isFalse,
      );
      expect(
        CustomerPriceRuleEligibilityPolicy.isApplicable(
          _rule(
            from: DateTime.utc(2026, 7, 1),
            to: DateTime.utc(2026, 7, 10),
          ),
          businessDate,
        ),
        isFalse,
      );
      expect(
        CustomerPriceRuleEligibilityPolicy.isApplicable(
          _rule(from: DateTime.utc(2026, 8, 1)),
          businessDate,
        ),
        isFalse,
      );
    });
  });

  group('CustomerPriceRule softDelete', () {
    for (final status in [
      CustomerPriceRuleStatus.active,
      CustomerPriceRuleStatus.needsReview,
    ]) {
      test('$status soft-deletes once with event and deletedAt', () {
        final rule = _rule(status: status, version: 3);
        final deletedAt = DateTime.utc(2026, 7, 22, 10);

        final changed = rule.softDelete(deletedAt: deletedAt);

        expect(changed, isTrue);
        expect(rule.status, CustomerPriceRuleStatus.deleted);
        expect(rule.deletedAt, deletedAt);
        expect(rule.version, 4);
        final event =
            rule.domainEvents!.single as CustomerPriceRuleDeletedDomainEvent;
        expect(event.ruleId, 'rule-1');
        expect(event.previousVersion, 3);
        expect(event.newVersion, 4);
      });
    }

    test('already deleted is idempotent', () {
      final deletedAt = DateTime.utc(2026, 7, 1);
      final rule = _rule(
        status: CustomerPriceRuleStatus.deleted,
        deletedAt: deletedAt,
        version: 5,
      );

      expect(rule.softDelete(deletedAt: DateTime.utc(2026, 7, 22)), isFalse);
      expect(rule.version, 5);
      expect(rule.deletedAt, deletedAt);
      expect(rule.domainEvents, isNull);
    });

    test('disabled cannot be soft-deleted', () {
      final rule = _rule(
        status: CustomerPriceRuleStatus.disabled,
        version: 3,
      );

      expect(
        () => rule.softDelete(deletedAt: DateTime.utc(2026, 7, 22)),
        throwsA(isA<BusinessRuleValidationException>()),
      );
      expect(rule.version, 3);
      expect(rule.deletedAt, isNull);
      expect(rule.domainEvents, isNull);
    });

    test('reconstitute enforces deleted status equals deletedAt presence', () {
      expect(
        () => _rule(status: CustomerPriceRuleStatus.deleted),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => _rule(
          status: CustomerPriceRuleStatus.active,
          deletedAt: DateTime.utc(2026, 7, 1),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

CustomerPriceRule _rule({
  String id = 'rule-1',
  String productId = 'product-1',
  DateTime? from,
  DateTime? to,
  CustomerPriceRuleStatus status = CustomerPriceRuleStatus.active,
  DateTime? deletedAt,
  int version = 1,
  RuleValidationOutcome? validationOutcome,
}) => CustomerPriceRule.reconstitute(
  id: id,
  key: CustomerPriceRuleKey(
    tenantId: 'tenant-1',
    customerId: 'customer-1',
    productId: productId,
    productUnitId: 'unit-1',
  ),
  price: Money(amountMinor: 90000, currencyCode: 'VND'),
  effectivePeriod: EffectivePeriod(
    effectiveFrom: from ?? DateTime.utc(2026, 7, 1),
    effectiveTo: to,
  ),
  actorId: 'user-1',
  validationOutcome: validationOutcome ?? RuleValidationOutcome.clear(),
  ruleType: CustomerPriceRuleType.specialPrice,
  sourceType: CustomerPriceRuleSourceType.manual,
  status: status,
  reviewStatus: CustomerPriceRuleReviewStatus.clear,
  version: version,
  deletedAt: deletedAt,
);
