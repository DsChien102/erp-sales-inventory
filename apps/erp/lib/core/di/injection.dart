import 'package:get_it/get_it.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../features/auth/data/repositories/supabase_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_auth_state_use_case.dart';
import '../../features/auth/domain/usecases/sign_in_use_case.dart';
import '../../features/auth/domain/usecases/sign_out_use_case.dart';
import '../supabase/supabase_module.dart';

final getIt = GetIt.instance;

Future<void> initDependencies({required SupabaseModule supabaseModule}) async {
  if (getIt.isRegistered<SupabaseModule>()) {
    return;
  }

  getIt.registerSingleton<SupabaseModule>(supabaseModule);

  getIt.registerLazySingleton<AuthRepository>(
    () => SupabaseAuthRepository(getIt()),
  );
  getIt.registerLazySingleton(() => SignInUseCase(getIt()));
  getIt.registerLazySingleton(() => SignOutUseCase(getIt()));
  getIt.registerLazySingleton(() => GetAuthStateUseCase(getIt()));

  getIt.registerLazySingleton<ILoggerFactory>(
    () => const LoggingLoggerFactory(),
  );

  getIt.registerLazySingleton<IEventsBus>(() => InMemoryEventBusClient());
}
