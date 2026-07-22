import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';

void main() {
  group('CreateCustomerPriceRuleCommandValidator', () {
    final validator = CreateCustomerPriceRuleCommandValidator();

    test('accepts a valid minor-unit payload', () async {
      await validator.validate(_command());
    });

    test('returns stable validation code for invalid fields', () async {
      final command = _command(
        rulePriceMinor: 0,
        effectiveFrom: DateTime.utc(2026, 7, 20),
        effectiveTo: DateTime.utc(2026, 7, 19),
      );

      await expectLater(
        validator.validate(command),
        throwsA(
          isA<PricingBlockedException>().having(
            (error) => error.code,
            'code',
            PricingBlockedCodes.validationError,
          ),
        ),
      );
    });
  });

  group('CreateCustomerPriceRuleCommandHandler', () {
    test('creates and persists an authoritative manual rule result', () async {
      final contextPort = _ContextPort(_validContext());
      final gateway = _CommandGateway(_result());
      final handler = CreateCustomerPriceRuleCommandHandler(
        createContextPort: contextPort,
        commandGateway: gateway,
      );

      final result = await handler.handle(_command());

      expect(result.rule.id, 'rule-1');
      expect(
        gateway.lastCandidate?.sourceType,
        CustomerPriceRuleSourceType.manual,
      );
      expect(gateway.lastCandidate?.id, isNot('request-1'));
      expect(gateway.lastIdempotencyKey, 'idem-1');
    });

    test('rejects an invalid customer snapshot', () async {
      final context = _validContext().copyWith(
        customer: const CustomerSnapshot(
          customerId: 'customer-1',
          displayName: 'Removed customer',
          status: 'deleted',
          exists: true,
          isCustomer: true,
        ),
      );
      final handler = CreateCustomerPriceRuleCommandHandler(
        createContextPort: _ContextPort(context),
        commandGateway: _CommandGateway(
          _result(),
          error: const PricingBlockedException(
            PricingBlockedCodes.referenceInvalid,
          ),
        ),
      );

      await expectLater(
        handler.handle(_command()),
        _throwsCode(PricingBlockedCodes.referenceInvalid),
      );
    });

    test('blocks an overlapping active interval before create', () async {
      final gateway = _CommandGateway(_result());
      final handler = CreateCustomerPriceRuleCommandHandler(
        createContextPort: _ContextPort(
          _validContext().copyWith(conflictingRuleId: 'rule-existing'),
        ),
        commandGateway: gateway,
      );

      await expectLater(
        handler.handle(_command()),
        _throwsCode(PricingBlockedCodes.duplicateActiveRule),
      );
      expect(gateway.lastCandidate, isNull);
    });

    test('blocks below-floor price without acknowledgement', () async {
      final gateway = _CommandGateway(
        _result(),
        error: const PricingBlockedException(
          PricingBlockedCodes.belowFloorBlocked,
          details: {'reason': 'acknowledgementRequired'},
        ),
      );
      final handler = CreateCustomerPriceRuleCommandHandler(
        createContextPort: _ContextPort(_validContext(floorPriceMinor: 100000)),
        commandGateway: gateway,
      );

      await expectLater(
        handler.handle(_command(rulePriceMinor: 90000)),
        _throwsCodeWithReason(
          PricingBlockedCodes.belowFloorBlocked,
          'acknowledgementRequired',
        ),
      );
      expect(gateway.lastCandidate, isNull);
    });

    test(
      'allows below-floor price with acknowledgement and override',
      () async {
        final gateway = _CommandGateway(_result(warning: true));
        final handler = CreateCustomerPriceRuleCommandHandler(
          createContextPort: _ContextPort(
            _validContext(floorPriceMinor: 100000, canOverrideFloor: true),
          ),
          commandGateway: gateway,
        );

        final result = await handler.handle(
          _command(rulePriceMinor: 90000, acknowledgeFloorWarning: true),
        );

        expect(result.warnings.single.code, 'below_floor_price');
        expect(
          gateway.lastCandidate?.validationOutcome.priceCheckStatus,
          PriceCheckStatus.overrideAllowed,
        );
      },
    );

    test(
      'blocks acknowledged below-floor price without override permission',
      () async {
        final gateway = _CommandGateway(
          _result(),
          error: const PricingBlockedException(
            PricingBlockedCodes.belowFloorBlocked,
            details: {'reason': 'overridePermissionRequired'},
          ),
        );
        final handler = CreateCustomerPriceRuleCommandHandler(
          createContextPort: _ContextPort(
            _validContext(floorPriceMinor: 100000, canOverrideFloor: false),
          ),
          commandGateway: gateway,
        );

        await expectLater(
          handler.handle(
            _command(rulePriceMinor: 90000, acknowledgeFloorWarning: true),
          ),
          _throwsCodeWithReason(
            PricingBlockedCodes.belowFloorBlocked,
            'overridePermissionRequired',
          ),
        );
        expect(gateway.lastCandidate, isNull);
      },
    );

    test(
      'blocks redacted below-floor context without exposing floor amount',
      () async {
        final hiddenFloorContext = _validContext().copyWith(
          productUnit: const ProductPriceBandSnapshot(
            productId: 'product-1',
            productName: 'Vaccine',
            productUnitId: 'unit-1',
            unitName: 'Bottle',
            sellableStatus: 'active',
            currencyCode: 'VND',
            listPriceMinor: 150000,
            floorPriceHidden: true,
            isBelowFloor: true,
          ),
        );
        final gateway = _CommandGateway(
          _result(),
          error: const PricingBlockedException(
            PricingBlockedCodes.belowFloorBlocked,
            details: {'reason': 'overridePermissionRequired'},
          ),
        );
        final handler = CreateCustomerPriceRuleCommandHandler(
          createContextPort: _ContextPort(hiddenFloorContext),
          commandGateway: gateway,
        );

        await expectLater(
          handler.handle(
            _command(rulePriceMinor: 90000, acknowledgeFloorWarning: true),
          ),
          _throwsCode(PricingBlockedCodes.belowFloorBlocked),
        );
        expect(gateway.lastCandidate, isNull);
      },
    );

    test('idempotent retry bypasses stale advisory blockers', () async {
      final staleContext = _validContext().copyWith(
        customer: const CustomerSnapshot(
          customerId: 'customer-1',
          displayName: 'Disabled customer',
          status: 'disabled',
          exists: true,
          isCustomer: true,
        ),
        hasConflictingRule: true,
        conflictingRuleId: 'rule-1',
        idempotencyKeyExists: true,
      );
      final gateway = _CommandGateway(_result());
      final handler = CreateCustomerPriceRuleCommandHandler(
        createContextPort: _ContextPort(staleContext),
        commandGateway: gateway,
      );

      final result = await handler.handle(_command());

      expect(result.rule.id, 'rule-1');
      expect(gateway.lastCandidate, isNotNull);
    });
  });
}

Matcher _throwsCode(String code) => throwsA(
  isA<PricingBlockedException>().having((error) => error.code, 'code', code),
);

Matcher _throwsCodeWithReason(String code, String reason) => throwsA(
  isA<PricingBlockedException>()
      .having((error) => error.code, 'code', code)
      .having((error) => error.details['reason'], 'reason', reason),
);

CreateCustomerPriceRuleCommand _command({
  String? id = 'request-1',
  int rulePriceMinor = 125000,
  DateTime? effectiveFrom,
  DateTime? effectiveTo,
  bool acknowledgeFloorWarning = false,
}) => CreateCustomerPriceRuleCommand(
  id: id,
  tenantId: 'tenant-1',
  actorId: 'user-1',
  customerId: 'customer-1',
  productId: 'product-1',
  productUnitId: 'unit-1',
  rulePriceMinor: rulePriceMinor,
  currencyCode: 'VND',
  effectiveFrom: effectiveFrom ?? DateTime.utc(2026, 7, 16),
  effectiveTo: effectiveTo,
  note: 'VIP',
  acknowledgeFloorWarning: acknowledgeFloorWarning,
  idempotencyKey: 'idem-1',
);

CustomerPriceRuleCreateContext _validContext({
  int? floorPriceMinor,
  bool canOverrideFloor = false,
}) => CustomerPriceRuleCreateContext(
  customer: const CustomerSnapshot(
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
    floorPriceHidden: !canOverrideFloor && floorPriceMinor != null,
    isBelowFloor: floorPriceMinor != null && 125000 < floorPriceMinor,
  ),
  canOverrideFloor: canOverrideFloor,
);

CreateCustomerPriceRuleResult _result({bool warning = false}) {
  final warningItems = warning
      ? const [RuleIssueDto(code: 'below_floor_price')]
      : const <RuleIssueDto>[];
  return CreateCustomerPriceRuleResult(
    rule: CustomerPriceRuleDetailDto(
      id: 'rule-1',
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
      price: const MoneyDto(amountMinor: 125000, currencyCode: 'VND'),
      effectivePeriod: EffectivePeriodDto(
        effectiveFrom: DateTime.utc(2026, 7, 16),
      ),
      ruleType: CustomerPriceRuleType.specialPrice,
      sourceType: CustomerPriceRuleSourceType.manual,
      persistedStatus: CustomerPriceRuleStatus.active,
      derivedStatus: CustomerPriceRuleDerivedStatus.applying,
      validationOutcome: RuleValidationOutcomeDto(
        outcome: warning ? 'warning' : 'notChecked',
        warningCodes: warning ? const ['below_floor_price'] : const [],
        blockingCodes: const [],
        floorPriceHidden: false,
      ),
      referenceHealth: const CustomerPriceRuleReferenceHealthDto(
        customerState: CustomerPriceRuleReferenceState.valid,
        productUnitState: CustomerPriceRuleReferenceState.valid,
        priceBandState: CustomerPriceRulePriceBandState.current,
        issueCodes: [],
        usedStoredPriceBandSnapshot: false,
      ),
      sourceTrace: const CustomerPriceRuleSourceTraceDto(hidden: false),
      createdBy: 'user-1',
      createdAt: DateTime.utc(2026, 7, 16),
      updatedBy: 'user-1',
      updatedAt: DateTime.utc(2026, 7, 16),
      version: 1,
      availableActions: const [],
    ),
    warnings: warningItems,
  );
}

final class _ContextPort implements ICustomerPriceRuleCreateContextPort {
  _ContextPort(this.context);

  final CustomerPriceRuleCreateContext context;

  @override
  Future<CustomerPriceRuleCreateContext> load(
    CreateCustomerPriceRuleCommand command,
  ) async => context;
}

final class _CommandGateway implements ICustomerPriceRuleCommandGateway {
  _CommandGateway(this.result, {this.error});

  final CreateCustomerPriceRuleResult result;
  final PricingBlockedException? error;
  CustomerPriceRule? lastCandidate;
  String? lastIdempotencyKey;

  @override
  Future<CreateCustomerPriceRuleResult> create({
    required CustomerPriceRule candidate,
    required String idempotencyKey,
    required bool acknowledgeFloorWarning,
  }) async {
    lastCandidate = candidate;
    lastIdempotencyKey = idempotencyKey;
    if (error != null) throw error!;
    return result;
  }

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
