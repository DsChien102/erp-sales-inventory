import 'package:supabase/supabase.dart';
import 'package:vet45_dashboard_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final class _DashboardModuleStub implements IDashboardModule {
  const _DashboardModuleStub();

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnimplementedError('Dashboard module not implemented yet.');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    throw UnimplementedError('Dashboard module not implemented yet.');
  }
}

/// Composition root entry point for the dashboard module (skeleton).
final class DashboardStartup {
  static IDashboardModule initialize({required SupabaseClient supabase}) {
    // Skeleton: wire DataAccessModule and MediationModule when implementing.
    return const _DashboardModuleStub();
  }
}
