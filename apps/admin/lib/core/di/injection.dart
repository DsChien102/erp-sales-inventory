import 'package:get_it/get_it.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../supabase/supabase_module.dart';

final getIt = GetIt.instance;

Future<void> initDependencies({required SupabaseModule supabaseModule}) async {
  if (getIt.isRegistered<SupabaseModule>()) {
    return;
  }

  getIt.registerSingleton<SupabaseModule>(supabaseModule);

  getIt.registerLazySingleton<ILoggerFactory>(
    () => const LoggingLoggerFactory(),
  );

  getIt.registerLazySingleton<IEventsBus>(() => InMemoryEventBusClient());
}
