import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vet45_design_system/design_system.dart';

import 'configurations/app_logging.dart';
import 'configurations/env.dart';
import 'configurations/env_banner.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/supabase/supabase_module.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  configureAppLogging(logLevelName: Env.logLevel);

  await Supabase.initialize(
    url: Env.supabaseConnectionUrl,
    publishableKey: Env.supabaseAnonKey,
    headers: const {'X-Vet45-App': 'tenant_app'},
    debug: false,
  );

  await initDependencies(supabaseModule: SupabaseModule(Supabase.instance.client));

  runApp(const ErpApp());
}

class ErpApp extends StatelessWidget {
  const ErpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: Env.appTitle,
      debugShowCheckedModeBanner: false,
      theme: VTheme.lightTheme,
      darkTheme: VTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
      builder: (context, child) => EnvBanner(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
