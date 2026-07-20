import 'app_environment.dart';

/// App configuration from `--dart-define` / `--dart-define-from-file`.
abstract final class Env {
  static const String _appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const String _supabaseConnectionUrl = String.fromEnvironment(
    'SUPABASE_CONNECTION_URL',
  );

  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static const String _logLevel = String.fromEnvironment('LOG_LEVEL');

  static AppEnvironment get appEnvironment =>
      AppEnvironment.fromString(_appEnv);

  static bool get isDevelopment => appEnvironment.isDevelopment;
  static bool get isStaging => appEnvironment.isStaging;
  static bool get isProduction => appEnvironment.isProduction;

  static String get appTitle => appEnvironment.displayName;

  static String? get environmentBannerLabel => appEnvironment.bannerLabel;

  static String get supabaseConnectionUrl => _supabaseConnectionUrl;

  static String get supabaseAnonKey => _supabaseAnonKey;

  static String get logLevel => _logLevel;
}
