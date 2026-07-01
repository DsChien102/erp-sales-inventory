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

  static const String _messagingClientPollEnabled = String.fromEnvironment(
    'MESSAGING_CLIENT_POLL_ENABLED',
    defaultValue: 'false',
  );

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

  static bool get messagingClientPollEnabled => _parseBool(
        _messagingClientPollEnabled,
        defaultValue: appEnvironment.isDevelopment,
      );

  static bool _parseBool(String raw, {required bool defaultValue}) {
    if (raw.isEmpty) {
      return defaultValue;
    }
    return raw.toLowerCase() == 'true';
  }
}
