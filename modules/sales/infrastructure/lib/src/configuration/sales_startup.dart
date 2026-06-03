import 'package:supabase/supabase.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final class _SalesModuleStub implements ISalesModule {
  const _SalesModuleStub();

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnimplementedError('Sales module not implemented yet.');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    throw UnimplementedError('Sales module not implemented yet.');
  }
}

/// Composition root entry point for the sales module (skeleton).
final class SalesStartup {
  static ISalesModule initialize({required SupabaseClient supabase}) {
    // Skeleton: wire DataAccessModule and MediationModule when implementing.
    return const _SalesModuleStub();
  }
}
