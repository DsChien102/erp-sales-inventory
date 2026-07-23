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
