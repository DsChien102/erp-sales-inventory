import 'package:supabase/supabase.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final class _CatalogModuleStub implements ICatalogModule {
  const _CatalogModuleStub();

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnimplementedError('Catalog module not implemented yet.');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    throw UnimplementedError('Catalog module not implemented yet.');
  }
}

/// Composition root entry point for the catalog module (skeleton).
final class CatalogStartup {
  static ICatalogModule initialize({required SupabaseClient supabase}) {
    // Skeleton: wire DataAccessModule and MediationModule when implementing.
    return const _CatalogModuleStub();
  }
}
