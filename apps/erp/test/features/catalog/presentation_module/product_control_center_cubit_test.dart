import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:erp/features/catalog/presentation.dart';
import 'package:vet45_shared_application/application.dart';

final class _ExecutionContext implements IExecutionContext {
  @override
  String get correlationId => 'test-correlation';

  @override
  Future<String> requireTenantId() async => 'tenant-1';

  @override
  Future<String> requireUserId() async => 'user-1';
}

final class _DelayedCatalogModule implements ICatalogModule {
  final queryCompleter = Completer<Object?>();
  final commandCompleter = Completer<Object?>();

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    return await commandCompleter.future as TResult;
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    return await queryCompleter.future as TResult;
  }
}

void main() {
  ProductControlCenterCubit buildCubit(_DelayedCatalogModule module) {
    return ProductControlCenterCubit(
      catalogModule: module,
      executionContext: _ExecutionContext(),
    );
  }

  test('ignores a failed control-center query after the cubit is closed', () async {
    final module = _DelayedCatalogModule();
    final cubit = buildCubit(module);

    final load = cubit.loadControlCenter('product-1');
    await Future<void>.delayed(Duration.zero);
    await cubit.close();
    module.queryCompleter.completeError(StateError('RPC failed'));

    await expectLater(load, completes);
  });

  test('ignores a failed lifecycle command after the cubit is closed', () async {
    final module = _DelayedCatalogModule();
    final cubit = buildCubit(module);

    final deactivate = cubit.deactivateProduct('product-1');
    await Future<void>.delayed(Duration.zero);
    await cubit.close();
    module.commandCompleter.completeError(StateError('RPC failed'));

    await expectLater(deactivate, completes);
  });
}
