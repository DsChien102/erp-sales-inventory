import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_application/testing.dart';
import 'package:vet45_pricing_domain/domain.dart';

void main() {
  group('DisableCustomerPriceRuleCommandValidator', () {
    final validator = DisableCustomerPriceRuleCommandValidator();

    test('accepts valid payload and optional normalized reason', () async {
      await validator.validate(_command(reason: ' Kết thúc thỏa thuận '));
    });

    test('rejects invalid rule version and a 501-character reason', () async {
      await expectLater(
        validator.validate(
          _command(
            ruleId: 'not-a-uuid',
            expectedVersion: 0,
            reason: List.filled(501, 'x').join(),
          ),
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
                  containsPair('reason', 'too_long'),
                ),
              ),
        ),
      );
    });
  });

  test('withExecutionContext replaces only tenant and actor', () {
    final original = _command(
      tenantId: 'caller-tenant',
      actorId: 'caller-user',
      reason: ' keep ',
    );
    final bound = original.withExecutionContext(
      tenantId: 'context-tenant',
      actorId: 'context-user',
    );

    expect(bound.tenantId, 'context-tenant');
    expect(bound.actorId, 'context-user');
    expect(bound.ruleId, original.ruleId);
    expect(bound.expectedVersion, original.expectedVersion);
    expect(bound.reason, original.reason);
  });

  test('disableRuleOk returns disabled audit detail', () async {
    final result = await FakePricingModule(
      scenario: FakePricingScenario.disableRuleOk,
    ).executeCommandAsync(_command(reason: ' Kết thúc thỏa thuận '));

    expect(result.persistedStatus, CustomerPriceRuleStatus.disabled);
    expect(result.derivedStatus, CustomerPriceRuleDerivedStatus.disabled);
    expect(result.version, 4);
    expect(result.disabledAt, isNotNull);
    expect(result.disabledBy, 'fake-user-1');
    expect(result.disabledReason, 'Kết thúc thỏa thuận');
    expect(
      result.availableActions,
      contains(CustomerPriceRuleAvailableActions.reenable),
    );
  });

  test(
    'disableRuleAlreadyDisabled returns current state without replacing audit',
    () async {
      final result = await FakePricingModule(
        scenario: FakePricingScenario.disableRuleAlreadyDisabled,
      ).executeCommandAsync(_command(reason: 'new retry reason'));

      expect(result.version, 4);
      expect(result.disabledReason, 'Lý do ban đầu');
    },
  );

  for (final entry in {
    FakePricingScenario.disableRuleStateChanged:
        PricingBlockedCodes.stateChanged,
    FakePricingScenario.disableRuleDenied: PricingBlockedCodes.noPermission,
    FakePricingScenario.disableRuleNotFound: PricingBlockedCodes.notFound,
    FakePricingScenario.disableRuleInvalidStatus:
        PricingBlockedCodes.invalidStatus,
  }.entries) {
    test('${entry.key.name} returns ${entry.value}', () async {
      final module = FakePricingModule(scenario: entry.key);
      await expectLater(
        module.executeCommandAsync(_command()),
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

  test(
    'handler forwards normalized reason to the authoritative gateway',
    () async {
      final gateway = _DisableGateway(_disabledDetail());
      final handler = DisableCustomerPriceRuleCommandHandler(
        commandGateway: gateway,
      );

      final result = await handler.handle(
        _command(reason: '  Kết thúc thỏa thuận  '),
      );

      expect(result.persistedStatus, CustomerPriceRuleStatus.disabled);
      expect(gateway.calls, 1);
      expect(gateway.tenantId, 'tenant-1');
      expect(gateway.ruleId, _ruleId);
      expect(gateway.expectedVersion, 3);
      expect(gateway.reason, 'Kết thúc thỏa thuận');
    },
  );

  test('handler normalizes blank reason to null', () async {
    final gateway = _DisableGateway(_disabledDetail());
    await DisableCustomerPriceRuleCommandHandler(
      commandGateway: gateway,
    ).handle(_command(reason: '   '));
    expect(gateway.reason, isNull);
  });
}

const _ruleId = '00000000-0000-4000-8000-000000000001';

DisableCustomerPriceRuleCommand _command({
  String tenantId = 'tenant-1',
  String actorId = 'user-1',
  String ruleId = _ruleId,
  int expectedVersion = 3,
  String? reason,
}) => DisableCustomerPriceRuleCommand(
  tenantId: tenantId,
  actorId: actorId,
  ruleId: ruleId,
  expectedVersion: expectedVersion,
  reason: reason,
);

CustomerPriceRuleDetailDto _disabledDetail() {
  final at = DateTime.utc(2026, 7, 16);
  return CustomerPriceRuleDetailDto(
    id: _ruleId,
    customer: const CustomerRefDto(
      customerId: 'customer-1',
      displayName: 'Clinic A',
      status: 'active',
    ),
    productUnit: const ProductUnitRefDto(
      productId: 'product-1',
      productName: 'Vaccine',
      productUnitId: 'unit-1',
      unitName: 'Bottle',
      sellableStatus: 'active',
    ),
    price: const MoneyDto(amountMinor: 90000, currencyCode: 'VND'),
    effectivePeriod: EffectivePeriodDto(
      effectiveFrom: DateTime.utc(2026, 7, 1),
    ),
    ruleType: CustomerPriceRuleType.specialPrice,
    sourceType: CustomerPriceRuleSourceType.manual,
    persistedStatus: CustomerPriceRuleStatus.disabled,
    derivedStatus: CustomerPriceRuleDerivedStatus.disabled,
    validationOutcome: const RuleValidationOutcomeDto(
      outcome: 'notChecked',
      warningCodes: [],
      blockingCodes: [],
      floorPriceHidden: true,
    ),
    referenceHealth: const CustomerPriceRuleReferenceHealthDto(
      customerState: CustomerPriceRuleReferenceState.valid,
      productUnitState: CustomerPriceRuleReferenceState.valid,
      priceBandState: CustomerPriceRulePriceBandState.current,
      issueCodes: [],
      usedStoredPriceBandSnapshot: false,
    ),
    sourceTrace: const CustomerPriceRuleSourceTraceDto(hidden: false),
    createdBy: 'user-created',
    createdAt: at,
    updatedBy: 'user-1',
    updatedAt: at,
    version: 4,
    availableActions: const [CustomerPriceRuleAvailableActions.reenable],
    disabledAt: at,
    disabledBy: 'user-1',
    disabledReason: 'Kết thúc thỏa thuận',
  );
}

final class _DisableGateway implements ICustomerPriceRuleCommandGateway {
  _DisableGateway(this.result);

  final CustomerPriceRuleDetailDto result;
  int calls = 0;
  String? tenantId;
  String? ruleId;
  int? expectedVersion;
  String? reason;

  @override
  Future<CreateCustomerPriceRuleResult> create({
    required CustomerPriceRule candidate,
    required String idempotencyKey,
    required bool acknowledgeFloorWarning,
  }) => throw UnsupportedError('create not used');

  @override
  Future<CustomerPriceRuleDetailDto> update({
    required CustomerPriceRule candidate,
    required int expectedVersion,
    required bool acknowledgeFloorWarning,
  }) => throw UnsupportedError('update not used');

  @override
  Future<CustomerPriceRuleDetailDto> disable({
    required String tenantId,
    required String ruleId,
    required int expectedVersion,
    required String? reason,
  }) async {
    calls += 1;
    this.tenantId = tenantId;
    this.ruleId = ruleId;
    this.expectedVersion = expectedVersion;
    this.reason = reason;
    return result;
  }

  @override
  Future<CustomerPriceRuleDetailDto> reenable({
    required String tenantId,
    required String ruleId,
    required int expectedVersion,
    required DateTime businessDate,
    required String? precheckToken,
    required bool acknowledgeFloorWarning,
  }) => throw UnsupportedError('reenable not used');
}
