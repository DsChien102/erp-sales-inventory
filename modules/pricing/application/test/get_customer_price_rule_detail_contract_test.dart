import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_application/testing.dart';
import 'package:vet45_pricing_domain/domain.dart';

void main() {
  const ruleId = '00000000-0000-4000-8000-000000000001';

  group('GetCustomerPriceRuleDetailQuery', () {
    test('normalizes businessDate to UTC calendar date', () {
      final query = GetCustomerPriceRuleDetailQuery(
        tenantId: 'tenant-1',
        ruleId: ruleId,
        businessDate: DateTime(2026, 7, 16, 18, 45),
      );

      expect(query.businessDate, DateTime.utc(2026, 7, 16));
    });

    test(
      'withExecutionContext replaces caller tenant and preserves query id/payload',
      () {
        final query = GetCustomerPriceRuleDetailQuery(
          id: 'query-1',
          tenantId: 'caller-tenant',
          ruleId: ruleId,
          businessDate: DateTime.utc(2026, 7, 16),
        );

        final bound = query.withExecutionContext(tenantId: 'context-tenant');

        expect(bound.id, 'query-1');
        expect(bound.tenantId, 'context-tenant');
        expect(bound.ruleId, ruleId);
        expect(bound.businessDate, DateTime.utc(2026, 7, 16));
      },
    );
  });

  group('GetCustomerPriceRuleDetailQueryValidator', () {
    final validator = GetCustomerPriceRuleDetailQueryValidator();

    test('accepts a valid canonical UUID', () async {
      await validator.validate(_detailQuery());
    });

    test('rejects blank tenantId', () async {
      await expectLater(
        validator.validate(_detailQuery(tenantId: '  ')),
        _throwsValidationField('tenantId'),
      );
    });

    test('rejects blank ruleId', () async {
      await expectLater(
        validator.validate(_detailQuery(ruleId: '   ')),
        _throwsValidationField('ruleId'),
      );
    });

    test('rejects malformed ruleId', () async {
      await expectLater(
        validator.validate(_detailQuery(ruleId: 'not-a-uuid')),
        _throwsValidationField('ruleId'),
      );
    });
  });

  group('GetCustomerPriceRuleDetailQueryHandler', () {
    test('handler validates then delegates the complete query', () async {
      final expected = _detail();
      final gateway = _ReadGateway(expected);
      final handler = GetCustomerPriceRuleDetailQueryHandler(
        readGateway: gateway,
        validator: GetCustomerPriceRuleDetailQueryValidator(),
      );
      final query = _detailQuery();

      final result = await handler.handle(query);

      expect(result, same(expected));
      expect(gateway.lastQuery, same(query));
      expect(gateway.callCount, 1);
    });

    test('handler does not call gateway after validation failure', () async {
      final gateway = _ReadGateway(_detail());
      final handler = GetCustomerPriceRuleDetailQueryHandler(
        readGateway: gateway,
        validator: GetCustomerPriceRuleDetailQueryValidator(),
      );

      await expectLater(
        handler.handle(_detailQuery(ruleId: 'bad')),
        _throwsValidationField('ruleId'),
      );
      expect(gateway.callCount, 0);
    });
  });

  group('FakePricingModule S3 scenarios', () {
    test(
      'ruleDetailActive returns applying detail plus edit-disable-history',
      () async {
        final module = FakePricingModule(
          scenario: FakePricingScenario.ruleDetailActive,
        );

        final detail = await module.executeQueryAsync(_detailQuery());

        expect(detail.derivedStatus, CustomerPriceRuleDerivedStatus.applying);
        expect(detail.availableActions, [
          CustomerPriceRuleAvailableActions.edit,
          CustomerPriceRuleAvailableActions.disable,
          CustomerPriceRuleAvailableActions.history,
        ]);
      },
    );

    test(
      'ruleDetailDisabled returns disabled detail plus edit-reenable-history',
      () async {
        final module = FakePricingModule(
          scenario: FakePricingScenario.ruleDetailDisabled,
        );

        final detail = await module.executeQueryAsync(_detailQuery());

        expect(detail.derivedStatus, CustomerPriceRuleDerivedStatus.disabled);
        expect(detail.disabledAt, isNotNull);
        expect(detail.disabledBy, 'fake-user-1');
        expect(detail.availableActions, [
          CustomerPriceRuleAvailableActions.edit,
          CustomerPriceRuleAvailableActions.reenable,
          CustomerPriceRuleAvailableActions.history,
        ]);
      },
    );

    test('ruleDetailNotFound throws NOT_FOUND', () async {
      final module = FakePricingModule(
        scenario: FakePricingScenario.ruleDetailNotFound,
      );

      await expectLater(
        module.executeQueryAsync(_detailQuery()),
        throwsA(
          isA<PricingBlockedException>().having(
            (error) => error.code,
            'code',
            PricingBlockedCodes.notFound,
          ),
        ),
      );
    });

    test(
      'ruleDetailReferenceStale preserves stored labels and redacts floor amount',
      () async {
        final module = FakePricingModule(
          scenario: FakePricingScenario.ruleDetailReferenceStale,
        );

        final detail = await module.executeQueryAsync(_detailQuery());

        expect(detail.customer.displayName, 'Phòng khám đã lưu');
        expect(detail.productUnit.productName, 'Vaccine đã lưu');
        expect(
          detail.referenceHealth.customerState,
          CustomerPriceRuleReferenceState.inactive,
        );
        expect(
          detail.referenceHealth.productUnitState,
          CustomerPriceRuleReferenceState.missing,
        );
        expect(detail.referenceHealth.issueCodes, [
          'customer_reference_inactive',
          'product_unit_reference_missing',
        ]);
        expect(detail.referenceHealth.usedStoredPriceBandSnapshot, isTrue);
        expect(detail.validationOutcome.floorPriceHidden, isTrue);
        expect(detail.validationOutcome.floorPrice, isNull);
        expect(
          detail.validationOutcome.warningCodes,
          contains('below_floor_price'),
        );
      },
    );
  });

  test('detail contract exposes typed status, health, trace, and actions', () {
    final detail = _detail();

    expect(detail.derivedStatus, CustomerPriceRuleDerivedStatus.applying);
    expect(
      detail.referenceHealth.priceBandState,
      CustomerPriceRulePriceBandState.current,
    );
    expect(detail.sourceTrace.hidden, isFalse);
  });
}

GetCustomerPriceRuleDetailQuery _detailQuery({
  String tenantId = 'tenant-1',
  String ruleId = '00000000-0000-4000-8000-000000000001',
}) => GetCustomerPriceRuleDetailQuery(
  tenantId: tenantId,
  ruleId: ruleId,
  businessDate: DateTime.utc(2026, 7, 16),
);

CustomerPriceRuleDetailDto _detail() => CustomerPriceRuleDetailDto(
  id: '00000000-0000-4000-8000-000000000001',
  customer: const CustomerRefDto(
    customerId: '00000000-0000-4000-8000-000000000002',
    displayName: 'Phòng khám A',
    status: 'active',
  ),
  productUnit: const ProductUnitRefDto(
    productId: '00000000-0000-4000-8000-000000000003',
    productName: 'Vaccine A',
    productUnitId: '00000000-0000-4000-8000-000000000004',
    unitName: 'Lọ',
    sellableStatus: 'active',
  ),
  price: const MoneyDto(amountMinor: 90000, currencyCode: 'VND'),
  effectivePeriod: EffectivePeriodDto(effectiveFrom: DateTime.utc(2026, 7, 1)),
  ruleType: CustomerPriceRuleType.specialPrice,
  sourceType: CustomerPriceRuleSourceType.manual,
  persistedStatus: CustomerPriceRuleStatus.active,
  derivedStatus: CustomerPriceRuleDerivedStatus.applying,
  validationOutcome: const RuleValidationOutcomeDto(
    outcome: 'warning',
    warningCodes: ['below_floor_price'],
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
  createdBy: '00000000-0000-4000-8000-000000000005',
  createdAt: DateTime.utc(2026, 7, 16),
  updatedBy: '00000000-0000-4000-8000-000000000005',
  updatedAt: DateTime.utc(2026, 7, 16),
  version: 1,
  availableActions: const [
    CustomerPriceRuleAvailableActions.edit,
    CustomerPriceRuleAvailableActions.disable,
    CustomerPriceRuleAvailableActions.history,
  ],
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

final class _ReadGateway implements IPricingReadGateway {
  _ReadGateway(this.result);

  final CustomerPriceRuleDetailDto result;
  GetCustomerPriceRuleDetailQuery? lastQuery;
  int callCount = 0;

  @override
  Future<CustomerPriceRuleSearchResultDto> searchCustomerPriceRules(
    SearchCustomerPriceRulesQuery query,
  ) async => throw UnsupportedError('search not used');

  @override
  Future<CustomerPriceRuleDetailDto> getCustomerPriceRuleDetail(
    GetCustomerPriceRuleDetailQuery query,
  ) async {
    callCount += 1;
    lastQuery = query;
    return result;
  }

  @override
  Future<CursorPageDto<CustomerPriceRuleActivityDto>>
  getCustomerPriceRuleHistory(GetCustomerPriceRuleHistoryQuery query) async =>
      throw UnsupportedError('history not used');

  @override
  Future<ResolveApplicableCustomerPriceRuleResultDto>
  resolveApplicableCustomerPriceRule(
    ResolveApplicableCustomerPriceRuleQuery query,
  ) async => throw UnsupportedError('resolve not used');
}
