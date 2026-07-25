import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_application/testing.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  const ruleId = '00000000-0000-4000-8000-000000000001';

  group('GetCustomerPriceRuleHistoryQuery', () {
    test('exposes view_history permission and tenant scoping', () {
      expect(
        PricingPermissions.viewCustomerPriceRuleHistory,
        'pricing.customer_price_rule.view_history',
      );
      final query = GetCustomerPriceRuleHistoryQuery(ruleId: ruleId);
      expect(query, isA<ITenantScopedCommand>());
      expect(query.limit, 50);
      expect(query.cursor, isNull);
    });

    test('normalizes blank cursor to null and keeps opaque cursor', () {
      final blank = GetCustomerPriceRuleHistoryQuery(
        ruleId: ruleId,
        cursor: '   ',
      );
      final kept = GetCustomerPriceRuleHistoryQuery(
        ruleId: ruleId,
        cursor: ' opaque-cursor ',
      );

      expect(blank.cursor, isNull);
      expect(kept.cursor, 'opaque-cursor');
    });

    test(
      'withExecutionContext replaces caller tenant and preserves payload',
      () {
        final query = GetCustomerPriceRuleHistoryQuery(
          id: 'query-1',
          tenantId: 'caller-tenant',
          ruleId: ruleId,
          cursor: 'cursor-1',
          limit: 25,
        );

        final bound = query.withExecutionContext(tenantId: 'context-tenant');

        expect(bound.id, 'query-1');
        expect(bound.tenantId, 'context-tenant');
        expect(bound.ruleId, ruleId);
        expect(bound.cursor, 'cursor-1');
        expect(bound.limit, 25);
      },
    );
  });

  group('GetCustomerPriceRuleHistoryQueryValidator', () {
    final validator = GetCustomerPriceRuleHistoryQueryValidator();

    test('accepts a valid shape', () async {
      await validator.validate(_historyQuery());
    });

    test('rejects blank tenantId', () async {
      await expectLater(
        validator.validate(_historyQuery(tenantId: '  ')),
        _throwsValidationField('tenantId'),
      );
    });

    test('rejects blank ruleId', () async {
      await expectLater(
        validator.validate(_historyQuery(ruleId: '   ')),
        _throwsValidationField('ruleId'),
      );
    });

    test('rejects malformed ruleId', () async {
      await expectLater(
        validator.validate(_historyQuery(ruleId: 'not-a-uuid')),
        _throwsValidationField('ruleId'),
      );
    });

    for (final limit in [0, 101]) {
      test('rejects limit $limit', () async {
        await expectLater(
          validator.validate(_historyQuery(limit: limit)),
          _throwsValidationField('limit'),
        );
      });
    }

    test('rejects cursor longer than 1024 characters', () async {
      await expectLater(
        validator.validate(_historyQuery(cursor: 'x' * 1025)),
        _throwsValidationField('cursor'),
      );
    });
  });

  group('CustomerPriceRuleActivityDto contract', () {
    test('exposes all V1 activity types', () {
      expect(CustomerPriceRuleActivityType.values, [
        CustomerPriceRuleActivityType.created,
        CustomerPriceRuleActivityType.updated,
        CustomerPriceRuleActivityType.disabled,
        CustomerPriceRuleActivityType.reenabled,
        CustomerPriceRuleActivityType.deleted,
        CustomerPriceRuleActivityType.importCreated,
        CustomerPriceRuleActivityType.importUpdated,
        CustomerPriceRuleActivityType.memoryCreated,
        CustomerPriceRuleActivityType.memoryUpdated,
      ]);
    });

    test('keeps snapshot maps and nested collections immutable', () {
      final oldValue = <String, Object?>{
        'version': 1,
        'nested': <String, Object?>{'floor_price_minor': 100},
      };
      final newValue = <String, Object?>{
        'version': 2,
        'tags': <Object?>['a'],
      };
      final activity = CustomerPriceRuleActivityDto(
        id: '00000000-0000-4000-8000-000000000010',
        activityType: CustomerPriceRuleActivityType.updated,
        actor: const CustomerPriceRuleActivityActorDto(
          actorId: '00000000-0000-4000-8000-000000000099',
          displayName: '5ef27a1c',
          isSystemActor: false,
        ),
        sourceType: CustomerPriceRuleSourceType.manual,
        oldValue: Map.unmodifiable(oldValue),
        newValue: Map.unmodifiable(newValue),
        reason: null,
        sourceTrace: const CustomerPriceRuleActivitySourceTraceDto(),
        sensitiveValuesHidden: true,
        createdAt: DateTime.utc(2026, 7, 16, 9, 30),
      );

      expect(activity.oldValue, isNotNull);
      expect(
        () => (activity.oldValue as Map<String, Object?>)['version'] = 9,
        throwsUnsupportedError,
      );
      expect(() => (activity.newValue)['version'] = 9, throwsUnsupportedError);
      expect(activity.sourceTrace.importId, isNull);
      expect(activity.sourceTrace.orderId, isNull);
      expect(activity.sourceTrace.memoryRequestId, isNull);
    });

    test('allows null oldValue for create rows and required newValue', () {
      final activity = CustomerPriceRuleActivityDto(
        id: '00000000-0000-4000-8000-000000000011',
        activityType: CustomerPriceRuleActivityType.created,
        actor: const CustomerPriceRuleActivityActorDto(
          displayName: 'System/Migration',
          isSystemActor: true,
        ),
        sourceType: CustomerPriceRuleSourceType.migration,
        oldValue: null,
        newValue: const {'version': 1},
        reason: null,
        sourceTrace: const CustomerPriceRuleActivitySourceTraceDto(),
        sensitiveValuesHidden: false,
        createdAt: DateTime.utc(2026, 7, 16, 8),
      );

      expect(activity.oldValue, isNull);
      expect(activity.newValue['version'], 1);
      expect(activity.actor.actorId, isNull);
      expect(activity.actor.displayName, 'System/Migration');
      expect(activity.actor.isSystemActor, isTrue);
    });
  });

  group('FakePricingModule S10 scenarios', () {
    test(
      'historyMixedSources returns desc page with manual/import/memory traces',
      () async {
        final module = FakePricingModule(
          scenario: FakePricingScenario.historyMixedSources,
        );

        final page = await module.executeQueryAsync(_historyQuery());

        expect(page.items, hasLength(greaterThanOrEqualTo(3)));
        expect(
          page.items.map((item) => item.sourceType),
          containsAll([
            CustomerPriceRuleSourceType.manual,
            CustomerPriceRuleSourceType.excelImport,
            CustomerPriceRuleSourceType.salesOrder,
          ]),
        );
        final importItem = page.items.firstWhere(
          (item) => item.sourceType == CustomerPriceRuleSourceType.excelImport,
        );
        expect(importItem.sourceTrace.importId, isNotNull);
        expect(importItem.sourceTrace.importRowId, isNotNull);
        final memoryItem = page.items.firstWhere(
          (item) => item.sourceType == CustomerPriceRuleSourceType.salesOrder,
        );
        expect(memoryItem.sourceTrace.orderId, isNotNull);
        expect(memoryItem.sourceTrace.orderLineId, isNotNull);
        expect(memoryItem.sourceTrace.memoryRequestId, isNotNull);
        expect(memoryItem.sourceTrace.soldAt, isNotNull);
        for (var i = 0; i < page.items.length - 1; i++) {
          final current = page.items[i];
          final next = page.items[i + 1];
          final ordered =
              current.createdAt.isAfter(next.createdAt) ||
              (current.createdAt.isAtSameMomentAs(next.createdAt) &&
                  current.id.compareTo(next.id) > 0);
          expect(ordered, isTrue);
        }
        expect(
          () => page.items.add(
            CustomerPriceRuleActivityDto(
              id: 'x',
              activityType: CustomerPriceRuleActivityType.updated,
              actor: const CustomerPriceRuleActivityActorDto(
                displayName: 'x',
                isSystemActor: false,
              ),
              sourceType: CustomerPriceRuleSourceType.manual,
              oldValue: null,
              newValue: const {},
              reason: null,
              sourceTrace: const CustomerPriceRuleActivitySourceTraceDto(),
              sensitiveValuesHidden: false,
              createdAt: DateTime.utc(2026, 7, 16),
            ),
          ),
          throwsUnsupportedError,
        );
      },
    );

    test('historySecondPage returns older page without more', () async {
      final module = FakePricingModule(
        scenario: FakePricingScenario.historySecondPage,
      );

      final page = await module.executeQueryAsync(
        _historyQuery(cursor: 'page-1-cursor'),
      );

      expect(page.items, isNotEmpty);
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNull);
    });

    test('historyEmptyLegacy returns empty page', () async {
      final module = FakePricingModule(
        scenario: FakePricingScenario.historyEmptyLegacy,
      );

      final page = await module.executeQueryAsync(_historyQuery());

      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNull);
    });

    test('historySystemActor uses System/Migration label', () async {
      final module = FakePricingModule(
        scenario: FakePricingScenario.historySystemActor,
      );

      final page = await module.executeQueryAsync(_historyQuery());

      expect(page.items, isNotEmpty);
      expect(page.items.first.actor.actorId, isNull);
      expect(page.items.first.actor.displayName, 'System/Migration');
      expect(page.items.first.actor.isSystemActor, isTrue);
    });

    for (final entry in {
      FakePricingScenario.historyNotFound: PricingBlockedCodes.notFound,
      FakePricingScenario.historyMalformedCursor:
          PricingBlockedCodes.validationError,
      FakePricingScenario.historyDenied: PricingBlockedCodes.noPermission,
      FakePricingScenario.historySystemError: PricingBlockedCodes.systemError,
    }.entries) {
      test('${entry.key.name} throws ${entry.value}', () async {
        final module = FakePricingModule(scenario: entry.key);

        await expectLater(
          module.executeQueryAsync(
            _historyQuery(
              cursor: entry.key == FakePricingScenario.historyMalformedCursor
                  ? 'bad-cursor'
                  : null,
            ),
          ),
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
  });
}

GetCustomerPriceRuleHistoryQuery _historyQuery({
  String tenantId = 'tenant-1',
  String ruleId = '00000000-0000-4000-8000-000000000001',
  String? cursor,
  int limit = 50,
}) => GetCustomerPriceRuleHistoryQuery(
  tenantId: tenantId,
  ruleId: ruleId,
  cursor: cursor,
  limit: limit,
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
