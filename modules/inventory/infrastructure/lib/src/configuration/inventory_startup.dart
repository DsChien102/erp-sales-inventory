import 'package:supabase/supabase.dart';
import 'package:vet45_inventory_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final class _InventoryModuleStub implements IInventoryModule {
  const _InventoryModuleStub();

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnimplementedError('Inventory module not implemented yet.');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    throw UnimplementedError('Inventory module not implemented yet.');
  }
}

/// Composition root entry point for the inventory module (skeleton).
final class InventoryStartup {
  static IInventoryModule initialize({required SupabaseClient supabase}) {
    // Skeleton: wire DataAccessModule and MediationModule when implementing.
    return const _InventoryModuleStub();
  }
}
