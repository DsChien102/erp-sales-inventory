import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/pricing/data/customer_price_rule_repository.dart';
import 'package:erp/features/pricing/data/models.dart';
import 'package:erp/features/pricing/data/pricing_errors.dart';
import 'package:erp/features/pricing/presentation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_customer_price_rule_repository.dart';

void main() {
  test('pending success is inert after cubit closes', () async {
    final repo = _DelayedPricingRepository();
    final cubit = _createCubit(repo);

    final operation = cubit.fetchRules();
    await repo.started.future;
    await cubit.close();
    repo.completeSuccess();

    await expectLater(operation, completes);
  });

  test('pending failure is inert after cubit closes', () async {
    final repo = _DelayedPricingRepository();
    final cubit = _createCubit(repo);

    final operation = cubit.fetchRules();
    await repo.started.future;
    await cubit.close();
    repo.completeError(
      const AppException(PricingErrorCodes.systemError),
    );

    await expectLater(operation, completes);
  });

  group('Quick filter and Advanced filter synchronization', () {
    test(
        'applyQuickFilter applying syncs advancedFilter.status and activeCount',
        () async {
      final repo = _ImmediatePricingRepository();
      final cubit = _createCubit(repo);

      cubit.applyQuickFilter(CustomerPriceRuleQuickFilter.applying);
      await pumpEventQueue();

      expect(cubit.state.quickFilter, CustomerPriceRuleQuickFilter.applying);
      expect(
        cubit.state.advancedFilter.status,
        CustomerPriceRuleDerivedStatus.applying,
      );
      expect(cubit.state.advancedFilter.activeCount, 1);
      expect(
        repo.lastCall?.args['quickFilter'],
        CustomerPriceRuleQuickFilter.applying,
      );
      expect(
        repo.lastCall?.args['statuses'],
        [CustomerPriceRuleDerivedStatus.applying],
      );

      await cubit.close();
    });

    test(
        'applyAdvancedFilter with applying status syncs quickFilter and activeCount',
        () async {
      final repo = _ImmediatePricingRepository();
      final cubit = _createCubit(repo);

      cubit.applyAdvancedFilter(
        const PriceRuleAdvancedFilter(
          status: CustomerPriceRuleDerivedStatus.applying,
        ),
      );
      await pumpEventQueue();

      expect(cubit.state.quickFilter, CustomerPriceRuleQuickFilter.applying);
      expect(
        cubit.state.advancedFilter.status,
        CustomerPriceRuleDerivedStatus.applying,
      );
      expect(cubit.state.advancedFilter.activeCount, 1);
      expect(
        repo.lastCall?.args['quickFilter'],
        CustomerPriceRuleQuickFilter.applying,
      );
      expect(
        repo.lastCall?.args['statuses'],
        [CustomerPriceRuleDerivedStatus.applying],
      );

      await cubit.close();
    });

    test('switching quick filter to all clears applying status in advancedFilter',
        () async {
      final repo = _ImmediatePricingRepository();
      final cubit = _createCubit(repo);

      cubit.applyQuickFilter(CustomerPriceRuleQuickFilter.applying);
      await pumpEventQueue();
      expect(cubit.state.advancedFilter.activeCount, 1);

      cubit.applyQuickFilter(CustomerPriceRuleQuickFilter.all);
      await pumpEventQueue();

      expect(cubit.state.quickFilter, CustomerPriceRuleQuickFilter.all);
      expect(cubit.state.advancedFilter.status, isNull);
      expect(cubit.state.advancedFilter.activeCount, 0);

      await cubit.close();
    });

    group('B1 — behavioral preservation tests', () {
      test('b1_quick_below_floor_params', () async {
        final repo = _ImmediatePricingRepository();
        final cubit = _createCubit(repo);

        cubit.applyQuickFilter(CustomerPriceRuleQuickFilter.belowFloor);
        await pumpEventQueue();

        expect(
          repo.lastCall?.args['quickFilter'],
          CustomerPriceRuleQuickFilter.belowFloor,
        );
        expect(
          cubit.state.advancedFilter.warning,
          PriceRuleWarningFilter.belowFloor,
        );

        await cubit.close();
      });

      test('b1_advanced_source_params', () async {
        final repo = _ImmediatePricingRepository();
        final cubit = _createCubit(repo);

        cubit.applyAdvancedFilter(
          const PriceRuleAdvancedFilter(
            source: CustomerPriceRuleSourceType.manual,
          ),
        );
        await pumpEventQueue();

        expect(repo.lastCall?.args['sources'], [
          CustomerPriceRuleSourceType.manual,
        ]);
        expect(repo.lastCall?.args['statuses'], isEmpty);

        await cubit.close();
      });

      test('b1_load_more_appends_with_cursor', () async {
        final repo = _ImmediatePricingRepository(
          pages: [
            CustomerPriceRuleSearchResultDto(
              page: CursorPageDto(
                items: [_sampleListItem(id: 'r1', warningCodes: const [])],
                nextCursor: 'c2',
                hasMore: true,
              ),
              availableActions: const [PricingAvailableActions.createManual],
              totalCount: 2,
            ),
            CustomerPriceRuleSearchResultDto(
              page: CursorPageDto(
                items: [_sampleListItem(id: 'r2', warningCodes: const [])],
                nextCursor: null,
                hasMore: false,
              ),
              availableActions: const [PricingAvailableActions.createManual],
              totalCount: 2,
            ),
          ],
        );
        final cubit = _createCubit(repo);

        await cubit.fetchRules(isRefresh: true);
        expect(cubit.state.items.map((i) => i.id).toList(), ['r1']);
        expect(cubit.state.hasReachedMax, isFalse);

        await cubit.fetchRules();
        expect(repo.calls, hasLength(2));
        expect(repo.calls[1].args['cursor'], 'c2');
        expect(cubit.state.items.map((i) => i.id).toList(), ['r1', 'r2']);
        expect(cubit.state.hasReachedMax, isTrue);

        await cubit.close();
      });

      test('h2_sort_sent_to_server', () async {
        final repo = _ImmediatePricingRepository(
          pages: [
            CustomerPriceRuleSearchResultDto(
              page: CursorPageDto(
                items: [
                  _sampleListItem(id: 'r1', warningCodes: const []),
                  _sampleListItem(id: 'r2', warningCodes: const []),
                ],
                hasMore: false,
              ),
              availableActions: const [PricingAvailableActions.createManual],
              totalCount: 2,
            ),
          ],
        );
        final cubit = _createCubit(repo);

        cubit.applySort(PriceRuleSortOption.priceDesc);
        await pumpEventQueue();

        expect(repo.calls, hasLength(1));
        expect(repo.lastCall?.args['sort'], PriceRuleSortOption.priceDesc);
        expect(cubit.state.items.map((i) => i.id).toList(), ['r1', 'r2']);

        await cubit.close();
      });

      test('h2_updated_within_sent', () async {
        final repo = _ImmediatePricingRepository();
        final cubit = _createCubit(repo);

        cubit.applyAdvancedFilter(
          const PriceRuleAdvancedFilter(
            updatedWithin: PriceRuleUpdatedWithin.last7Days,
          ),
        );
        await pumpEventQueue();

        expect(repo.calls, hasLength(1));
        expect(
          repo.lastCall?.args['updatedWithin'],
          PriceRuleUpdatedWithin.last7Days,
        );

        await cubit.close();
      });

      test('h2_sort_change_resets_cursor', () async {
        final repo = _ImmediatePricingRepository(
          pages: [
            CustomerPriceRuleSearchResultDto(
              page: CursorPageDto(
                items: [_sampleListItem(id: 'r1', warningCodes: const [])],
                nextCursor: 'c2',
                hasMore: true,
              ),
              availableActions: const [PricingAvailableActions.createManual],
              totalCount: 5,
            ),
          ],
        );
        final cubit = _createCubit(repo);

        await cubit.fetchRules(isRefresh: true);
        expect(cubit.state.items, hasLength(1));

        cubit.applySort(PriceRuleSortOption.customerNameAsc);
        await pumpEventQueue();

        expect(repo.calls, hasLength(2));
        expect(repo.calls[1].args['cursor'], isNull);
        expect(repo.calls[1].args['sort'], PriceRuleSortOption.customerNameAsc);

        await cubit.close();
      });

      test('h4_total_from_server', () async {
        final repo = _ImmediatePricingRepository(
          pages: [
            CustomerPriceRuleSearchResultDto(
              page: CursorPageDto(
                items: [_sampleListItem(id: 'r1', warningCodes: const [])],
                hasMore: false,
              ),
              availableActions: const [PricingAvailableActions.createManual],
              totalCount: 45,
            ),
          ],
        );
        final cubit = _createCubit(repo);

        await cubit.fetchRules(isRefresh: true);
        expect(cubit.state.totalCount, 45);

        await cubit.close();
      });
    });
  });
}

CustomerPriceRuleListItemDto _sampleListItem({
  required String id,
  required List<String> warningCodes,
}) => CustomerPriceRuleListItemDto(
  id: id,
  customer: const CustomerRefDto(
    customerId: 'customer-1',
    displayName: 'Khách A',
    status: 'active',
  ),
  productUnit: const ProductUnitRefDto(
    productId: 'product-1',
    productName: 'Sản phẩm A',
    productUnitId: 'unit-1',
    unitName: 'Hộp',
    sellableStatus: 'active',
  ),
  price: const MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
  effectivePeriod: EffectivePeriodDto(effectiveFrom: DateTime.utc(2026, 7, 1)),
  ruleType: CustomerPriceRuleType.specialPrice,
  sourceType: CustomerPriceRuleSourceType.manual,
  persistedStatus: CustomerPriceRuleStatus.active,
  derivedStatus: CustomerPriceRuleDerivedStatus.applying,
  validationOutcome: RuleValidationOutcomeDto(
    outcome: warningCodes.isEmpty ? 'valid' : 'warning',
    warningCodes: warningCodes,
    blockingCodes: const [],
    floorPriceHidden: true,
  ),
  updatedAt: DateTime.utc(2026, 7, 20),
);

PriceRuleListCubit _createCubit(CustomerPriceRuleRepository repository) =>
    PriceRuleListCubit(repository: repository);

final class _DelayedPricingRepository extends FakeCustomerPriceRuleRepository {
  final started = Completer<void>();
  final _result = Completer<CustomerPriceRuleSearchResultDto>();

  void completeSuccess() {
    _result.complete(
      const CustomerPriceRuleSearchResultDto(
        page: CursorPageDto(items: [], hasMore: false),
        availableActions: [],
        totalCount: 0,
      ),
    );
  }

  void completeError(Object error) => _result.completeError(error);

  @override
  Future<CustomerPriceRuleSearchResultDto> search({
    required DateTime businessDate,
    String? q,
    CustomerPriceRuleQuickFilter quickFilter = CustomerPriceRuleQuickFilter.all,
    List<CustomerPriceRuleDerivedStatus> statuses = const [],
    List<CustomerPriceRuleSourceType> sources = const [],
    String? customerId,
    String? productId,
    String? cursor,
    int limit = 20,
    PriceRuleSortOption sort = PriceRuleSortOption.updatedAtDesc,
    PriceRuleUpdatedWithin? updatedWithin,
  }) async {
    if (!started.isCompleted) started.complete();
    return _result.future;
  }
}

final class _ImmediatePricingRepository extends FakeCustomerPriceRuleRepository {
  _ImmediatePricingRepository({List<CustomerPriceRuleSearchResultDto>? pages})
    : _pages = pages ?? const [];

  final List<CustomerPriceRuleSearchResultDto> _pages;
  FakePricingCall? get lastCall => calls.isEmpty ? null : calls.last;

  @override
  Future<CustomerPriceRuleSearchResultDto> search({
    required DateTime businessDate,
    String? q,
    CustomerPriceRuleQuickFilter quickFilter = CustomerPriceRuleQuickFilter.all,
    List<CustomerPriceRuleDerivedStatus> statuses = const [],
    List<CustomerPriceRuleSourceType> sources = const [],
    String? customerId,
    String? productId,
    String? cursor,
    int limit = 20,
    PriceRuleSortOption sort = PriceRuleSortOption.updatedAtDesc,
    PriceRuleUpdatedWithin? updatedWithin,
  }) async {
    final index = calls.length;
    calls.add(
      FakePricingCall('search', {
        'businessDate': businessDate,
        'q': q,
        'quickFilter': quickFilter,
        'statuses': statuses,
        'sources': sources,
        'customerId': customerId,
        'productId': productId,
        'cursor': cursor,
        'limit': limit,
        'sort': sort,
        'updatedWithin': updatedWithin,
      }),
    );
    if (index < _pages.length) {
      return _pages[index];
    }
    return const CustomerPriceRuleSearchResultDto(
      page: CursorPageDto(items: [], hasMore: false),
      availableActions: [],
      totalCount: 0,
    );
  }
}
