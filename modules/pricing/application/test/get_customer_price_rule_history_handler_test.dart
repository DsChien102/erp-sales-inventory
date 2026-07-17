import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';

void main() {
  group('GetCustomerPriceRuleHistoryQueryHandler', () {
    test('validates then delegates the complete query', () async {
      final expected = const CursorPageDto<CustomerPriceRuleActivityDto>(
        items: [],
        hasMore: false,
      );
      final gateway = _ReadGateway(expected);
      final handler = GetCustomerPriceRuleHistoryQueryHandler(
        readGateway: gateway,
        validator: GetCustomerPriceRuleHistoryQueryValidator(),
      );
      final query = GetCustomerPriceRuleHistoryQuery(
        tenantId: 'tenant-1',
        ruleId: '00000000-0000-4000-8000-000000000001',
        cursor: 'cursor-1',
        limit: 25,
      );

      final result = await handler.handle(query);

      expect(result, same(expected));
      expect(gateway.lastQuery, same(query));
      expect(gateway.callCount, 1);
    });

    test('does not call gateway after validation failure', () async {
      final gateway = _ReadGateway(
        const CursorPageDto(items: [], hasMore: false),
      );
      final handler = GetCustomerPriceRuleHistoryQueryHandler(
        readGateway: gateway,
        validator: GetCustomerPriceRuleHistoryQueryValidator(),
      );

      await expectLater(
        handler.handle(
          GetCustomerPriceRuleHistoryQuery(tenantId: 'tenant-1', ruleId: 'bad'),
        ),
        throwsA(
          isA<PricingBlockedException>()
              .having(
                (error) => error.code,
                'code',
                PricingBlockedCodes.validationError,
              )
              .having(
                (error) => (error.details['fieldErrors'] as Map?)?.containsKey(
                  'ruleId',
                ),
                'fieldErrors contains ruleId',
                isTrue,
              ),
        ),
      );
      expect(gateway.callCount, 0);
    });

    test('propagates typed gateway failures', () async {
      final gateway = _ReadGateway(
        const CursorPageDto(items: [], hasMore: false),
        error: const PricingBlockedException(PricingBlockedCodes.notFound),
      );
      final handler = GetCustomerPriceRuleHistoryQueryHandler(
        readGateway: gateway,
        validator: GetCustomerPriceRuleHistoryQueryValidator(),
      );

      await expectLater(
        handler.handle(
          GetCustomerPriceRuleHistoryQuery(
            tenantId: 'tenant-1',
            ruleId: '00000000-0000-4000-8000-000000000001',
          ),
        ),
        throwsA(
          isA<PricingBlockedException>().having(
            (error) => error.code,
            'code',
            PricingBlockedCodes.notFound,
          ),
        ),
      );
    });
  });
}

final class _ReadGateway implements IPricingReadGateway {
  _ReadGateway(this.result, {this.error});

  final CursorPageDto<CustomerPriceRuleActivityDto> result;
  final PricingBlockedException? error;
  GetCustomerPriceRuleHistoryQuery? lastQuery;
  int callCount = 0;

  @override
  Future<CustomerPriceRuleSearchResultDto> searchCustomerPriceRules(
    SearchCustomerPriceRulesQuery query,
  ) async => throw UnsupportedError('search not used');

  @override
  Future<CustomerPriceRuleDetailDto> getCustomerPriceRuleDetail(
    GetCustomerPriceRuleDetailQuery query,
  ) async => throw UnsupportedError('detail not used');

  @override
  Future<CursorPageDto<CustomerPriceRuleActivityDto>>
  getCustomerPriceRuleHistory(GetCustomerPriceRuleHistoryQuery query) async {
    callCount += 1;
    lastQuery = query;
    if (error != null) {
      throw error!;
    }
    return result;
  }
}
