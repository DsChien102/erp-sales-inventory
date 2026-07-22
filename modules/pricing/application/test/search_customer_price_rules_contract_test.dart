import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_application/testing.dart';
import 'package:vet45_pricing_domain/domain.dart';

void main() {
  group('SearchCustomerPriceRulesQuery', () {
    test('normalizes defaults, query text, cursor, and business date', () {
      final query = SearchCustomerPriceRulesQuery(
        tenantId: 'caller-tenant',
        q: '  vaccine  ',
        cursor: '   ',
        businessDate: DateTime(2026, 7, 20, 16, 30),
      );

      expect(query.q, 'vaccine');
      expect(query.cursor, isNull);
      expect(query.quickFilter, CustomerPriceRuleQuickFilter.all);
      expect(query.statuses, isEmpty);
      expect(query.sources, isEmpty);
      expect(query.limit, 20);
      expect(query.businessDate, DateTime.utc(2026, 7, 20));
    });

    test('retains typed filters and replaces caller tenant from context', () {
      final query = SearchCustomerPriceRulesQuery(
        tenantId: 'caller-tenant',
        businessDate: DateTime.utc(2026, 7, 20),
        quickFilter: CustomerPriceRuleQuickFilter.belowFloor,
        statuses: const [
          CustomerPriceRuleDerivedStatus.applying,
          CustomerPriceRuleDerivedStatus.notYetEffective,
        ],
        sources: const [
          CustomerPriceRuleSourceType.manual,
          CustomerPriceRuleSourceType.excelImport,
        ],
        customerId: 'customer-1',
        productId: 'product-1',
        cursor: 'opaque-cursor',
        limit: 40,
      );

      final bound = query.withExecutionContext(tenantId: 'context-tenant');

      expect(bound.tenantId, 'context-tenant');
      expect(bound.quickFilter, CustomerPriceRuleQuickFilter.belowFloor);
      expect(bound.statuses, query.statuses);
      expect(bound.sources, query.sources);
      expect(bound.customerId, 'customer-1');
      expect(bound.productId, 'product-1');
      expect(bound.cursor, 'opaque-cursor');
      expect(bound.limit, 40);
    });
  });

  group('SearchCustomerPriceRulesQueryValidator', () {
    final validator = SearchCustomerPriceRulesQueryValidator();

    test('accepts a valid shape', () async {
      await validator.validate(_query());
    });

    for (final limit in [0, 101]) {
      test('rejects limit $limit', () async {
        await expectLater(
          validator.validate(_query(limit: limit)),
          _throwsValidationField('limit'),
        );
      });
    }

    test('rejects query text longer than 120 characters', () async {
      await expectLater(
        validator.validate(_query(q: 'x' * 121)),
        _throwsValidationField('q'),
      );
    });

    for (final field in ['customerId', 'productId']) {
      test('rejects provided blank $field', () async {
        await expectLater(
          validator.validate(
            _query(
              customerId: field == 'customerId' ? '   ' : null,
              productId: field == 'productId' ? '   ' : null,
            ),
          ),
          _throwsValidationField(field),
        );
      });
    }
  });

  group('SearchCustomerPriceRulesQueryHandler', () {
    test(
      'validates then delegates the complete query to the read gateway',
      () async {
        final expected = _searchResult();
        final gateway = _ReadGateway(expected);
        final handler = SearchCustomerPriceRulesQueryHandler(
          readGateway: gateway,
          validator: SearchCustomerPriceRulesQueryValidator(),
        );
        final query = _query(q: 'vaccine');

        final result = await handler.handle(query);

        expect(result, same(expected));
        expect(gateway.lastQuery, same(query));
        expect(gateway.callCount, 1);
      },
    );

    test('does not call the gateway when shape validation fails', () async {
      final gateway = _ReadGateway(_searchResult());
      final handler = SearchCustomerPriceRulesQueryHandler(
        readGateway: gateway,
        validator: SearchCustomerPriceRulesQueryValidator(),
      );

      await expectLater(
        handler.handle(_query(limit: 0)),
        _throwsValidationField('limit'),
      );
      expect(gateway.callCount, 0);
    });
  });

  group('FakePricingModule S2 scenarios', () {
    test(
      'searchRulesDefault returns mixed typed rows and screen actions',
      () async {
        final module = FakePricingModule(
          scenario: FakePricingScenario.searchRulesDefault,
        );

        final result = await module.executeQueryAsync(_query());

        expect(result.page.items, hasLength(2));
        expect(
          result.page.items.map((item) => item.sourceType),
          containsAll([
            CustomerPriceRuleSourceType.manual,
            CustomerPriceRuleSourceType.excelImport,
          ]),
        );
        expect(
          result.page.items.map((item) => item.derivedStatus),
          contains(CustomerPriceRuleDerivedStatus.notYetEffective),
        );
        expect(
          result.page.items.any(
            (item) => item.validationOutcome.warningCodes.contains(
              'below_floor_price',
            ),
          ),
          isTrue,
        );
        expect(result.availableActions, [
          PricingAvailableActions.createManual,
          PricingAvailableActions.import,
        ]);
      },
    );

    for (final scenario in [
      FakePricingScenario.searchRulesEmpty,
      FakePricingScenario.searchRulesNoResult,
    ]) {
      test('${scenario.name} returns an empty page', () async {
        final module = FakePricingModule(scenario: scenario);

        final result = await module.executeQueryAsync(_query());

        expect(result.page.items, isEmpty);
        expect(result.page.hasMore, isFalse);
        expect(result.page.nextCursor, isNull);
        expect(result.availableActions, [
          PricingAvailableActions.createManual,
          PricingAvailableActions.import,
        ]);
      });
    }

    test('searchRulesError throws SYSTEM_ERROR', () async {
      final module = FakePricingModule(
        scenario: FakePricingScenario.searchRulesError,
      );

      await expectLater(
        module.executeQueryAsync(_query()),
        throwsA(
          isA<PricingBlockedException>().having(
            (error) => error.code,
            'code',
            PricingBlockedCodes.systemError,
          ),
        ),
      );
    });
  });
}

SearchCustomerPriceRulesQuery _query({
  String? q,
  String? customerId,
  String? productId,
  int limit = 20,
}) => SearchCustomerPriceRulesQuery(
  tenantId: 'tenant-1',
  q: q,
  customerId: customerId,
  productId: productId,
  businessDate: DateTime.utc(2026, 7, 20),
  limit: limit,
);

CustomerPriceRuleSearchResultDto _searchResult() =>
    const CustomerPriceRuleSearchResultDto(
      page: CursorPageDto(items: [], hasMore: false),
      availableActions: [],
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

  final CustomerPriceRuleSearchResultDto result;
  SearchCustomerPriceRulesQuery? lastQuery;
  int callCount = 0;

  @override
  Future<CustomerPriceRuleSearchResultDto> searchCustomerPriceRules(
    SearchCustomerPriceRulesQuery query,
  ) async {
    callCount += 1;
    lastQuery = query;
    return result;
  }

  @override
  Future<CustomerPriceRuleDetailDto> getCustomerPriceRuleDetail(
    GetCustomerPriceRuleDetailQuery query,
  ) async => throw UnsupportedError('detail not used');

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
