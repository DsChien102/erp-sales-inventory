import 'package:supabase/supabase.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final class _PartnerModuleStub implements IPartnerModule {
  const _PartnerModuleStub();

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnimplementedError('Partner module not implemented yet.');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    throw UnimplementedError('Partner module not implemented yet.');
  }
}

/// Composition root entry point for the partner module (skeleton).
final class PartnerStartup {
  static IPartnerModule initialize({required SupabaseClient supabase}) {
    // Skeleton: wire DataAccessModule and MediationModule when implementing.
    return const _PartnerModuleStub();
  }
}
