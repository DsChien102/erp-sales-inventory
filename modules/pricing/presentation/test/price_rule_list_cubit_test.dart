import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  test('pending success is inert after cubit closes', () async {
    final module = _DelayedPricingModule();
    final cubit = _createCubit(module);

    final operation = cubit.fetchRules();
    await module.started.future;
    await cubit.close();
    module.completeSuccess();

    await expectLater(operation, completes);
  });

  test('pending failure is inert after cubit closes', () async {
    final module = _DelayedPricingModule();
    final cubit = _createCubit(module);

    final operation = cubit.fetchRules();
    await module.started.future;
    await cubit.close();
    module.completeError(
      const PricingBlockedException(PricingBlockedCodes.systemError),
    );

    await expectLater(operation, completes);
  });

  group('applyQuickFilter and applyAdvancedFilter sync', () {
    test('applyQuickFilter applying updates advancedFilter status and activeCount', () async {
      final module = _ImmediatePricingModule();
      final cubit = _createCubit(module);

      cubit.applyQuickFilter(CustomerPriceRuleQuickFilter.applying);
      await pumpEventQueue();

      expect(cubit.state.quickFilter, CustomerPriceRuleQuickFilter.applying);
      expect(
        cubit.state.advancedFilter.status,
        CustomerPriceRuleDerivedStatus.applying,
      );
      expect(cubit.state.advancedFilter.activeCount, 1);
    });

    test('applyQuickFilter belowFloor updates advancedFilter warning and activeCount', () async {
      final module = _ImmediatePricingModule();
      final cubit = _createCubit(module);

      cubit.applyQuickFilter(CustomerPriceRuleQuickFilter.belowFloor);
      await pumpEventQueue();

      expect(cubit.state.quickFilter, CustomerPriceRuleQuickFilter.belowFloor);
      expect(
        cubit.state.advancedFilter.warning,
        PriceRuleWarningFilter.belowFloor,
      );
      expect(cubit.state.advancedFilter.activeCount, 1);
    });

    test('applyQuickFilter all resets quick filter and activeCount', () async {
      final module = _ImmediatePricingModule();
      final cubit = _createCubit(module);

      cubit.applyQuickFilter(CustomerPriceRuleQuickFilter.applying);
      await pumpEventQueue();
      expect(cubit.state.advancedFilter.activeCount, 1);

      cubit.applyQuickFilter(CustomerPriceRuleQuickFilter.all);
      await pumpEventQueue();

      expect(cubit.state.quickFilter, CustomerPriceRuleQuickFilter.all);
      expect(cubit.state.advancedFilter.status, null);
      expect(cubit.state.advancedFilter.warning, null);
      expect(cubit.state.advancedFilter.activeCount, 0);
    });

    test('applyAdvancedFilter with applying status syncs quickFilter', () async {
      final module = _ImmediatePricingModule();
      final cubit = _createCubit(module);

      cubit.applyAdvancedFilter(
        const PriceRuleAdvancedFilter(
          status: CustomerPriceRuleDerivedStatus.applying,
        ),
      );
      await pumpEventQueue();

      expect(cubit.state.quickFilter, CustomerPriceRuleQuickFilter.applying);
      expect(cubit.state.advancedFilter.activeCount, 1);
    });

    test('applyAdvancedFilter with belowFloor warning syncs quickFilter', () async {
      final module = _ImmediatePricingModule();
      final cubit = _createCubit(module);

      cubit.applyAdvancedFilter(
        const PriceRuleAdvancedFilter(
          warning: PriceRuleWarningFilter.belowFloor,
        ),
      );
      await pumpEventQueue();

      expect(cubit.state.quickFilter, CustomerPriceRuleQuickFilter.belowFloor);
      expect(cubit.state.advancedFilter.activeCount, 1);
    });
  });
}

PriceRuleListCubit _createCubit(IPricingModule module) => PriceRuleListCubit(
  pricingModule: module,
  executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
);

final class _DelayedPricingModule implements IPricingModule {
  final started = Completer<void>();
  final _result = Completer<CustomerPriceRuleSearchResultDto>();

  void completeSuccess() {
    _result.complete(
      const CustomerPriceRuleSearchResultDto(
        page: CursorPageDto(items: [], hasMore: false),
        availableActions: [],
      ),
    );
  }

  void completeError(Object error) => _result.completeError(error);

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (!started.isCompleted) started.complete();
    return await _result.future as TResult;
  }

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError('Commands are not used by this test.');
  }
}

final class _ImmediatePricingModule implements IPricingModule {
  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    return const CustomerPriceRuleSearchResultDto(
      page: CursorPageDto(items: [], hasMore: false),
      availableActions: [],
    ) as TResult;
  }

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError('Commands are not used by this test.');
  }
}
