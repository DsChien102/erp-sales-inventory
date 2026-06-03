import 'package:supabase/supabase.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final class _IamModuleStub implements IIamModule {
  const _IamModuleStub();

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnimplementedError('Iam module not implemented yet.');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    throw UnimplementedError('Iam module not implemented yet.');
  }
}

/// Composition root entry point for the iam module (skeleton).
final class IamStartup {
  static IIamModule initialize({required SupabaseClient supabase}) {
    // Skeleton: wire DataAccessModule and MediationModule when implementing.
    return const _IamModuleStub();
  }
}
