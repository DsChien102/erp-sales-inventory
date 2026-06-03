import 'package:supabase/supabase.dart';
import 'package:vet45_accounting_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final class _AccountingModuleStub implements IAccountingModule {
  const _AccountingModuleStub();

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnimplementedError('Accounting module not implemented yet.');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    throw UnimplementedError('Accounting module not implemented yet.');
  }
}

/// Composition root entry point for the accounting module (skeleton).
final class AccountingStartup {
  static IAccountingModule initialize({required SupabaseClient supabase}) {
    // Skeleton: wire DataAccessModule and MediationModule when implementing.
    return const _AccountingModuleStub();
  }
}
