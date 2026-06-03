import 'package:supabase/supabase.dart';
import 'package:vet45_costing_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final class _CostingModuleStub implements ICostingModule {
  const _CostingModuleStub();

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnimplementedError('Costing module not implemented yet.');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    throw UnimplementedError('Costing module not implemented yet.');
  }
}

/// Composition root entry point for the costing module (skeleton).
final class CostingStartup {
  static ICostingModule initialize({required SupabaseClient supabase}) {
    // Skeleton: wire DataAccessModule and MediationModule when implementing.
    return const _CostingModuleStub();
  }
}
