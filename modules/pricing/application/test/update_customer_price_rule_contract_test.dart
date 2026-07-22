import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_application/testing.dart';
import 'package:vet45_pricing_domain/domain.dart';

void main() {
  group('UpdateCustomerPriceRuleCommandValidator', () {
    final validator = UpdateCustomerPriceRuleCommandValidator();

    test('accepts a valid full mutable snapshot', () async {
      await validator.validate(_command());
    });

    test(
      'returns field errors for invalid id version money and period',
      () async {
        final command = _command(
          ruleId: 'not-a-uuid',
          expectedVersion: 0,
          rulePriceMinor: 0,
          effectiveFrom: DateTime.utc(2026, 7, 20),
          effectiveTo: DateTime.utc(2026, 7, 19),
        );

        await expectLater(
          validator.validate(command),
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
                  containsPair('expectedVersion', 'must_be_positive'),
                ),
          ),
        );
      },
    );
  });

  test('withExecutionContext replaces caller tenant and actor only', () {
    final original = _command(
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
    expect(bound.rulePriceMinor, original.rulePriceMinor);
    expect(bound.note, original.note);
  });

  test(
    'fake update success increments version and preserves identity',
    () async {
      final module = FakePricingModule(
        scenario: FakePricingScenario.updateRuleOk,
      );
      final result = await module.executeCommandAsync(_command());

      expect(result.id, _ruleId);
      expect(result.price.amountMinor, 95000);
      expect(result.price.currencyCode, 'VND');
      expect(result.version, 4);
      expect(
        result.customer.customerId,
        '00000000-0000-4000-8000-000000000002',
      );
    },
  );

  test('fake no-op keeps expected version', () async {
    final module = FakePricingModule(
      scenario: FakePricingScenario.updateRuleNoop,
    );
    final result = await module.executeCommandAsync(_command());
    expect(result.version, 3);
  });

  for (final entry in {
    FakePricingScenario.updateRuleStateChanged:
        PricingBlockedCodes.stateChanged,
    FakePricingScenario.updateRuleFloorBlocked:
        PricingBlockedCodes.belowFloorBlocked,
    FakePricingScenario.updateRuleReferenceInvalid:
        PricingBlockedCodes.referenceInvalid,
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

  group('UpdateCustomerPriceRuleCommandHandler', () {
    test(
      'updates through authoritative gateway with expected version',
      () async {
        final gateway = _UpdateGateway(_detail(version: 4));
        final handler = UpdateCustomerPriceRuleCommandHandler(
          updateContextPort: _UpdateContextPort(_context()),
          commandGateway: gateway,
        );

        final result = await handler.handle(_command());

        expect(result.version, 4);
        expect(gateway.expectedVersion, 3);
        expect(gateway.candidate!.price.amountMinor, 95000);
        expect(gateway.candidate!.key.customerId, 'customer-1');
      },
    );

    test('still calls authoritative gateway for normalized no-op', () async {
      final gateway = _UpdateGateway(_detail(version: 3));
      final handler = UpdateCustomerPriceRuleCommandHandler(
        updateContextPort: _UpdateContextPort(_context()),
        commandGateway: gateway,
      );

      await handler.handle(_command(rulePriceMinor: 90000, note: ' VIP '));

      expect(gateway.calls, 1);
      expect(gateway.candidate!.version, 3);
    });

    test('rejects stale advisory version before update call', () async {
      final gateway = _UpdateGateway(_detail(version: 4));
      final handler = UpdateCustomerPriceRuleCommandHandler(
        updateContextPort: _UpdateContextPort(_context(version: 4)),
        commandGateway: gateway,
      );
      await expectLater(
        handler.handle(_command(expectedVersion: 3)),
        _throwsCode(PricingBlockedCodes.stateChanged),
      );
      expect(gateway.calls, 0);
    });

    test('blocks invalid references for a meaningful update', () async {
      final context = _context(
        customer: const CustomerSnapshot(
          customerId: 'customer-1',
          displayName: 'Archived',
          status: 'inactive',
          exists: true,
          isCustomer: true,
        ),
      );
      final gateway = _UpdateGateway(_detail(version: 4));
      final handler = UpdateCustomerPriceRuleCommandHandler(
        updateContextPort: _UpdateContextPort(context),
        commandGateway: gateway,
      );
      await expectLater(
        handler.handle(_command()),
        _throwsCode(PricingBlockedCodes.referenceInvalid),
      );
      expect(gateway.calls, 0);
    });

    test('passes advisory duplicate through authoritative gateway', () async {
      final gateway = _UpdateGateway(_detail(version: 4));
      final handler = UpdateCustomerPriceRuleCommandHandler(
        updateContextPort: _UpdateContextPort(
          _context(hasConflictingRule: true, conflictingRuleId: 'rule-other'),
        ),
        commandGateway: gateway,
      );
      final result = await handler.handle(_command());
      expect(result.version, 4);
      expect(gateway.calls, 1);
    });

    test('allows acknowledged below-floor update with override', () async {
      final gateway = _UpdateGateway(_detail(version: 4, warning: true));
      final handler = UpdateCustomerPriceRuleCommandHandler(
        updateContextPort: _UpdateContextPort(
          _context(floorPriceMinor: 100000, canOverrideFloor: true),
        ),
        commandGateway: gateway,
      );
      final result = await handler.handle(
        _command(rulePriceMinor: 90000, acknowledgeFloorWarning: true),
      );
      expect(result.validationOutcome.warningCodes, ['below_floor_price']);
      expect(
        gateway.candidate!.validationOutcome.priceCheckStatus,
        PriceCheckStatus.overrideAllowed,
      );
    });

    test('blocks redacted below-floor update before gateway write', () async {
      final gateway = _UpdateGateway(_detail(version: 4));
      final handler = UpdateCustomerPriceRuleCommandHandler(
        updateContextPort: _UpdateContextPort(
          _context(floorPriceMinor: 100000, canOverrideFloor: false),
        ),
        commandGateway: gateway,
      );
      await expectLater(
        handler.handle(
          _command(rulePriceMinor: 90000, acknowledgeFloorWarning: true),
        ),
        _throwsCode(PricingBlockedCodes.belowFloorBlocked),
      );
      expect(gateway.calls, 0);
    });
  });
}

const _ruleId = '00000000-0000-4000-8000-000000000001';

UpdateCustomerPriceRuleCommand _command({
  String tenantId = 'tenant-1',
  String actorId = 'user-1',
  String ruleId = _ruleId,
  int expectedVersion = 3,
  int rulePriceMinor = 95000,
  DateTime? effectiveFrom,
  DateTime? effectiveTo,
  String? note = ' Updated note ',
  bool acknowledgeFloorWarning = false,
}) => UpdateCustomerPriceRuleCommand(
  tenantId: tenantId,
  actorId: actorId,
  ruleId: ruleId,
  expectedVersion: expectedVersion,
  rulePriceMinor: rulePriceMinor,
  effectiveFrom: effectiveFrom ?? DateTime.utc(2026, 7, 16, 15),
  effectiveTo: effectiveTo,
  note: note,
  acknowledgeFloorWarning: acknowledgeFloorWarning,
);

CustomerPriceRuleUpdateContext _context({
  int version = 3,
  CustomerSnapshot? customer,
  int? floorPriceMinor,
  bool canOverrideFloor = false,
  bool hasConflictingRule = false,
  String? conflictingRuleId,
}) => CustomerPriceRuleUpdateContext(
  currentRule: CustomerPriceRule.reconstitute(
    id: _ruleId,
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
    note: 'VIP',
    ruleType: CustomerPriceRuleType.specialPrice,
    sourceType: CustomerPriceRuleSourceType.manual,
    status: CustomerPriceRuleStatus.active,
    reviewStatus: CustomerPriceRuleReviewStatus.clear,
    version: version,
  ),
  customer:
      customer ??
      const CustomerSnapshot(
        customerId: 'customer-1',
        displayName: 'Clinic A',
        status: 'active',
        exists: true,
        isCustomer: true,
      ),
  productUnit: ProductPriceBandSnapshot(
    productId: 'product-1',
    productName: 'Vaccine',
    productUnitId: 'unit-1',
    unitName: 'Bottle',
    sellableStatus: 'active',
    currencyCode: 'VND',
    listPriceMinor: 150000,
    floorPriceMinor: floorPriceMinor,
    floorPriceHidden: floorPriceMinor != null && !canOverrideFloor,
    isBelowFloor: floorPriceMinor != null && 95000 < floorPriceMinor,
  ),
  canOverrideFloor: canOverrideFloor,
  hasConflictingRule: hasConflictingRule,
  conflictingRuleId: conflictingRuleId,
);

CustomerPriceRuleDetailDto _detail({
  required int version,
  bool warning = false,
}) => CustomerPriceRuleDetailDto(
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
  price: const MoneyDto(amountMinor: 95000, currencyCode: 'VND'),
  effectivePeriod: EffectivePeriodDto(effectiveFrom: DateTime.utc(2026, 7, 16)),
  ruleType: CustomerPriceRuleType.specialPrice,
  sourceType: CustomerPriceRuleSourceType.manual,
  persistedStatus: CustomerPriceRuleStatus.active,
  derivedStatus: CustomerPriceRuleDerivedStatus.applying,
  note: 'Updated note',
  validationOutcome: RuleValidationOutcomeDto(
    outcome: warning ? 'warning' : 'valid',
    warningCodes: warning ? const ['below_floor_price'] : const [],
    blockingCodes: const [],
    floorPriceHidden: !warning,
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
  createdAt: DateTime.utc(2026, 7, 1),
  updatedBy: 'user-1',
  updatedAt: DateTime.utc(2026, 7, 16),
  version: version,
  availableActions: const [],
);

Matcher _throwsCode(String code) =>
    throwsA(isA<PricingBlockedException>().having((e) => e.code, 'code', code));

final class _UpdateContextPort implements ICustomerPriceRuleUpdateContextPort {
  _UpdateContextPort(this.context);
  final CustomerPriceRuleUpdateContext context;

  @override
  Future<CustomerPriceRuleUpdateContext> load(
    UpdateCustomerPriceRuleCommand command,
  ) async => context;
}

final class _UpdateGateway implements ICustomerPriceRuleCommandGateway {
  _UpdateGateway(this.result);
  final CustomerPriceRuleDetailDto result;
  CustomerPriceRule? candidate;
  int? expectedVersion;
  int calls = 0;

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
  }) async {
    this.candidate = candidate;
    this.expectedVersion = expectedVersion;
    calls += 1;
    return result;
  }

  @override
  Future<CustomerPriceRuleDetailDto> disable({
    required String tenantId,
    required String ruleId,
    required int expectedVersion,
    required String? reason,
  }) => throw UnsupportedError('disable not used');


  @override
  Future<CustomerPriceRuleDetailDto> delete({
    required String tenantId,
    required String ruleId,
    required int expectedVersion,
  }) => throw UnsupportedError('delete not used');

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
