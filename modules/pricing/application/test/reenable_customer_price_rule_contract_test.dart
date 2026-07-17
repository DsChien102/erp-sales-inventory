import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_application/testing.dart';
import 'package:vet45_pricing_domain/domain.dart';

void main() {
  group('PrecheckCustomerPriceRuleReenableQueryValidator', () {
    final validator = PrecheckCustomerPriceRuleReenableQueryValidator();

    test('accepts valid payload', () async {
      await validator.validate(_precheckQuery());
    });

    test('rejects invalid rule id and non-positive version', () async {
      await expectLater(
        validator.validate(
          _precheckQuery(ruleId: 'not-a-uuid', expectedVersion: 0),
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

  group('ReenableCustomerPriceRuleCommandValidator', () {
    final validator = ReenableCustomerPriceRuleCommandValidator();

    test('accepts valid payload with optional token', () async {
      await validator.validate(_reenableCommand(precheckToken: _token));
    });

    test('rejects empty context and invalid token formats', () async {
      for (final token in ['abc', 'a' * 63, 'A' * 64, 'a' * 65]) {
        await expectLater(
          validator.validate(
            ReenableCustomerPriceRuleCommand(
              tenantId: '',
              actorId: '',
              ruleId: _ruleId,
              expectedVersion: 4,
              businessDate: DateTime.utc(2026, 7, 16),
              precheckToken: token,
              acknowledgeFloorWarning: false,
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
                    containsPair('tenantId', 'required'),
                    containsPair('actorId', 'required'),
                    containsPair('precheckToken', 'invalid'),
                  ),
                ),
          ),
        );
      }
    });
  });

  test('precheck normalizes business date and binds tenant only', () {
    final original = PrecheckCustomerPriceRuleReenableQuery(
      tenantId: 'caller-tenant',
      ruleId: _ruleId,
      expectedVersion: 4,
      businessDate: DateTime(2026, 7, 16, 22, 30),
    );
    final bound = original.withExecutionContext(tenantId: 'context-tenant');

    expect(original.businessDate, DateTime.utc(2026, 7, 16));
    expect(bound.tenantId, 'context-tenant');
    expect(bound.ruleId, _ruleId);
    expect(bound.expectedVersion, 4);
    expect(bound.businessDate, DateTime.utc(2026, 7, 16));
  });

  test('reenable binds tenant and actor while preserving confirmation', () {
    final original = ReenableCustomerPriceRuleCommand(
      tenantId: 'caller-tenant',
      actorId: 'caller-user',
      ruleId: _ruleId,
      expectedVersion: 4,
      businessDate: DateTime(2026, 7, 16, 22),
      precheckToken: _token,
      acknowledgeFloorWarning: true,
    );
    final bound = original.withExecutionContext(
      tenantId: 'context-tenant',
      actorId: 'context-user',
    );

    expect(bound.tenantId, 'context-tenant');
    expect(bound.actorId, 'context-user');
    expect(bound.ruleId, _ruleId);
    expect(bound.expectedVersion, 4);
    expect(bound.businessDate, DateTime.utc(2026, 7, 16));
    expect(bound.precheckToken, _token);
    expect(bound.acknowledgeFloorWarning, isTrue);
  });

  test('reenablePrecheckValid returns valid outcome and token', () async {
    final valid = await FakePricingModule(
      scenario: FakePricingScenario.reenablePrecheckValid,
    ).executeQueryAsync(_precheckQuery());

    expect(valid.validationOutcome.outcome, 'valid');
    expect(valid.precheckToken, hasLength(64));
    expect(valid.ruleVersion, 4);
  });

  test('reenablePrecheckWarning returns below-floor warning', () async {
    final warning = await FakePricingModule(
      scenario: FakePricingScenario.reenablePrecheckWarning,
    ).executeQueryAsync(_precheckQuery());

    expect(warning.validationOutcome.outcome, 'warning');
    expect(warning.validationOutcome.warningCodes, ['below_floor_price']);
  });

  test('reenableOk returns active detail without reenable action', () async {
    final result = await FakePricingModule(
      scenario: FakePricingScenario.reenableOk,
    ).executeCommandAsync(_reenableCommand());

    expect(result.persistedStatus, CustomerPriceRuleStatus.active);
    expect(result.version, 5);
    expect(result.disabledAt, isNull);
    expect(result.disabledBy, isNull);
    expect(result.disabledReason, isNull);
    expect(
      result.availableActions,
      isNot(contains(CustomerPriceRuleAvailableActions.reenable)),
    );
  });

  for (final entry in {
    FakePricingScenario.reenablePrecheckBlockedDuplicate:
        'duplicate_active_rule',
    FakePricingScenario.reenablePrecheckBlockedExpired:
        'effective_period_expired',
    FakePricingScenario.reenablePrecheckBlockedReference:
        'customer_reference_invalid',
  }.entries) {
    test('${entry.key.name} returns blocked ${entry.value}', () async {
      final result = await FakePricingModule(
        scenario: entry.key,
      ).executeQueryAsync(_precheckQuery());

      expect(result.validationOutcome.outcome, 'blocked');
      expect(result.validationOutcome.blockingCodes, [entry.value]);
    });
  }

  for (final entry in {
    FakePricingScenario.reenablePrecheckDenied:
        PricingBlockedCodes.noPermission,
    FakePricingScenario.reenablePrecheckNotFound: PricingBlockedCodes.notFound,
    FakePricingScenario.reenablePrecheckInvalidStatus:
        PricingBlockedCodes.invalidStatus,
  }.entries) {
    test('${entry.key.name} throws ${entry.value}', () async {
      await expectLater(
        FakePricingModule(
          scenario: entry.key,
        ).executeQueryAsync(_precheckQuery()),
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

  for (final entry in {
    FakePricingScenario.reenableStateChanged: PricingBlockedCodes.stateChanged,
    FakePricingScenario.reenableDuplicate:
        PricingBlockedCodes.duplicateActiveRule,
    FakePricingScenario.reenableFloorBlocked:
        PricingBlockedCodes.belowFloorBlocked,
    FakePricingScenario.reenableReferenceInvalid:
        PricingBlockedCodes.referenceInvalid,
    FakePricingScenario.reenableExpired: PricingBlockedCodes.invalidStatus,
    FakePricingScenario.reenableInvalidStatus:
        PricingBlockedCodes.invalidStatus,
  }.entries) {
    test('${entry.key.name} throws ${entry.value}', () async {
      await expectLater(
        FakePricingModule(
          scenario: entry.key,
        ).executeCommandAsync(_reenableCommand()),
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

  test('reenableFloorOverrideOk returns active detail with warning', () async {
    final result =
        await FakePricingModule(
          scenario: FakePricingScenario.reenableFloorOverrideOk,
        ).executeCommandAsync(
          _reenableCommand(
            acknowledgeFloorWarning: true,
            precheckToken: _token,
          ),
        );

    expect(result.persistedStatus, CustomerPriceRuleStatus.active);
    expect(result.validationOutcome.outcome, 'warning');
    expect(result.validationOutcome.warningCodes, ['below_floor_price']);
  });

  test('precheck handler delegates to precheck port', () async {
    final expectedResult = CustomerPriceRuleReenablePrecheckDto(
      validationOutcome: const RuleValidationOutcomeDto(
        outcome: 'valid',
        warningCodes: [],
        blockingCodes: [],
        floorPriceHidden: true,
      ),
      precheckToken: _token,
      ruleVersion: 4,
      businessDate: _businessDate,
    );
    final precheckPort = _ReenablePrecheckPort(expectedResult);
    final queryHandler = PrecheckCustomerPriceRuleReenableQueryHandler(
      precheckPort: precheckPort,
      validator: PrecheckCustomerPriceRuleReenableQueryValidator(),
    );

    final result = await queryHandler.handle(_precheckQuery());

    expect(result, same(expectedResult));
    expect(precheckPort.calls, 1);
  });

  test('reenable handler delegates to command gateway', () async {
    final expectedDetail = _activeDetail();
    final commandGateway = _ReenableCommandGateway(expectedDetail);
    final commandHandler = ReenableCustomerPriceRuleCommandHandler(
      commandGateway: commandGateway,
    );

    final detail = await commandHandler.handle(
      _reenableCommand(precheckToken: _token, acknowledgeFloorWarning: true),
    );

    expect(detail, same(expectedDetail));
    expect(commandGateway.calls, 1);
    expect(commandGateway.lastPrecheckToken, _token);
    expect(commandGateway.lastBusinessDate, _businessDate);
  });
}

const _ruleId = '00000000-0000-4000-8000-000000000001';
const _token =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
final _businessDate = DateTime.utc(2026, 7, 16);

PrecheckCustomerPriceRuleReenableQuery _precheckQuery({
  String tenantId = 'tenant-1',
  String ruleId = _ruleId,
  int expectedVersion = 4,
  DateTime? businessDate,
}) => PrecheckCustomerPriceRuleReenableQuery(
  tenantId: tenantId,
  ruleId: ruleId,
  expectedVersion: expectedVersion,
  businessDate: businessDate ?? _businessDate,
);

ReenableCustomerPriceRuleCommand _reenableCommand({
  String tenantId = 'tenant-1',
  String actorId = 'user-1',
  String ruleId = _ruleId,
  int expectedVersion = 4,
  DateTime? businessDate,
  String? precheckToken,
  bool acknowledgeFloorWarning = false,
}) => ReenableCustomerPriceRuleCommand(
  tenantId: tenantId,
  actorId: actorId,
  ruleId: ruleId,
  expectedVersion: expectedVersion,
  businessDate: businessDate ?? _businessDate,
  precheckToken: precheckToken,
  acknowledgeFloorWarning: acknowledgeFloorWarning,
);

CustomerPriceRuleDetailDto _activeDetail() {
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
    persistedStatus: CustomerPriceRuleStatus.active,
    derivedStatus: CustomerPriceRuleDerivedStatus.applying,
    validationOutcome: const RuleValidationOutcomeDto(
      outcome: 'valid',
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
    version: 5,
    availableActions: const [CustomerPriceRuleAvailableActions.disable],
  );
}

final class _ReenablePrecheckPort
    implements ICustomerPriceRuleReenablePrecheckPort {
  _ReenablePrecheckPort(this.result);

  final CustomerPriceRuleReenablePrecheckDto result;
  int calls = 0;

  @override
  Future<CustomerPriceRuleReenablePrecheckDto> precheck(
    PrecheckCustomerPriceRuleReenableQuery query,
  ) async {
    calls += 1;
    return result;
  }
}

final class _ReenableCommandGateway
    implements ICustomerPriceRuleCommandGateway {
  _ReenableCommandGateway(this.result);

  final CustomerPriceRuleDetailDto result;
  int calls = 0;
  String? lastPrecheckToken;
  DateTime? lastBusinessDate;

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
  }) => throw UnsupportedError('disable not used');

  @override
  Future<CustomerPriceRuleDetailDto> reenable({
    required String tenantId,
    required String ruleId,
    required int expectedVersion,
    required DateTime businessDate,
    required String? precheckToken,
    required bool acknowledgeFloorWarning,
  }) async {
    calls += 1;
    lastPrecheckToken = precheckToken;
    lastBusinessDate = businessDate;
    return result;
  }
}
