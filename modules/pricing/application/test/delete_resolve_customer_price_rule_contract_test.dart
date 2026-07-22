import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_application/testing.dart';
import 'package:vet45_pricing_domain/domain.dart';

void main() {
  group('DeleteCustomerPriceRuleCommandValidator', () {
    final validator = DeleteCustomerPriceRuleCommandValidator();

    test('accepts valid payload', () async {
      await validator.validate(_deleteCommand());
    });

    test('rejects invalid rule id and version', () async {
      await expectLater(
        validator.validate(
          _deleteCommand(ruleId: 'not-a-uuid', expectedVersion: 0),
        ),
        throwsA(
          isA<PricingBlockedException>()
              .having(
                (e) => e.code,
                'code',
                PricingBlockedCodes.validationError,
              )
              .having(
                (e) => e.details['fieldErrors'],
                'fieldErrors',
                allOf(
                  containsPair('ruleId', 'invalid'),
                  containsPair('expectedVersion', 'must_be_positive'),
                ),
              ),
        ),
      );
    });
  });

  test('withExecutionContext replaces only tenant and actor', () {
    final original = _deleteCommand(
      tenantId: 'caller-tenant',
      actorId: 'caller-user',
    );
    final bound = original.withExecutionContext(
      tenantId: 'context-tenant',
      actorId: 'context-user',
    );

    expect(bound.tenantId, 'context-tenant');
    expect(bound.actorId, 'context-user');
    expect(bound.ruleId, original.ruleId);
    expect(bound.expectedVersion, original.expectedVersion);
  });

  test('deleteRuleOk returns deleted detail', () async {
    final result = await FakePricingModule(
      scenario: FakePricingScenario.deleteRuleOk,
    ).executeCommandAsync(_deleteCommand());

    expect(result.persistedStatus, CustomerPriceRuleStatus.deleted);
    expect(result.derivedStatus, CustomerPriceRuleDerivedStatus.deleted);
    expect(result.version, 4);
    expect(result.deletedAt, isNotNull);
    expect(result.availableActions, isEmpty);
  });

  test('deleteRuleAlreadyDeleted is idempotent replay', () async {
    final result = await FakePricingModule(
      scenario: FakePricingScenario.deleteRuleAlreadyDeleted,
    ).executeCommandAsync(_deleteCommand());

    expect(result.persistedStatus, CustomerPriceRuleStatus.deleted);
    expect(result.version, 4);
  });

  for (final entry in {
    FakePricingScenario.deleteRuleStateChanged:
        PricingBlockedCodes.stateChanged,
    FakePricingScenario.deleteRuleDenied: PricingBlockedCodes.noPermission,
    FakePricingScenario.deleteRuleNotFound: PricingBlockedCodes.notFound,
    FakePricingScenario.deleteRuleInvalidStatus:
        PricingBlockedCodes.invalidStatus,
  }.entries) {
    test('${entry.key.name} returns ${entry.value}', () async {
      final module = FakePricingModule(scenario: entry.key);
      await expectLater(
        module.executeCommandAsync(_deleteCommand()),
        throwsA(
          isA<PricingBlockedException>().having(
            (e) => e.code,
            'code',
            entry.value,
          ),
        ),
      );
    });
  }

  group('ResolveApplicableCustomerPriceRuleQueryValidator', () {
    final validator = ResolveApplicableCustomerPriceRuleQueryValidator();

    test('accepts valid payload', () async {
      await validator.validate(_resolveQuery());
    });

    test('rejects invalid ids', () async {
      await expectLater(
        validator.validate(
          _resolveQuery(
            customerId: 'bad',
            productId: '',
            productUnitId: 'also-bad',
          ),
        ),
        throwsA(
          isA<PricingBlockedException>().having(
            (e) => e.code,
            'code',
            PricingBlockedCodes.validationError,
          ),
        ),
      );
    });
  });

  test('resolveApplicableOk returns rule', () async {
    final result = await FakePricingModule(
      scenario: FakePricingScenario.resolveApplicableOk,
    ).executeQueryAsync(_resolveQuery());

    expect(result.rule, isNotNull);
    expect(result.rule!.price.amountMinor, 125000);
    expect(result.rule!.sourceType, CustomerPriceRuleSourceType.manual);
  });

  test('resolveApplicableNone returns null rule', () async {
    final result = await FakePricingModule(
      scenario: FakePricingScenario.resolveApplicableNone,
    ).executeQueryAsync(_resolveQuery());

    expect(result.rule, isNull);
  });
}

DeleteCustomerPriceRuleCommand _deleteCommand({
  String tenantId = '11111111-1111-4111-8111-111111111111',
  String actorId = '22222222-2222-4222-8222-222222222222',
  String ruleId = '33333333-3333-4333-8333-333333333333',
  int expectedVersion = 3,
}) => DeleteCustomerPriceRuleCommand(
  tenantId: tenantId,
  actorId: actorId,
  ruleId: ruleId,
  expectedVersion: expectedVersion,
);

ResolveApplicableCustomerPriceRuleQuery _resolveQuery({
  String tenantId = '11111111-1111-4111-8111-111111111111',
  String customerId = '44444444-4444-4444-8444-444444444444',
  String productId = '55555555-5555-4555-8555-555555555555',
  String productUnitId = '66666666-6666-4666-8666-666666666666',
}) => ResolveApplicableCustomerPriceRuleQuery(
  tenantId: tenantId,
  customerId: customerId,
  productId: productId,
  productUnitId: productUnitId,
  businessDate: DateTime.utc(2026, 7, 15),
);
