import 'package:envied/envied.dart';

import 'app_environment.dart';

part 'env.g.dart';

/// App configuration from `.env`, with optional `--dart-define` overrides.
///
/// Priority: `--dart-define=KEY=value` > `.env` (envied).
@Envied(path: '.env', obfuscate: true)
abstract class Env {
  static const _appEnvDefine = String.fromEnvironment('APP_ENV');
  static const _supabaseConnectionUrlDefine = String.fromEnvironment(
    'SUPABASE_CONNECTION_URL',
  );
  static const _supabaseAnonKeyDefine = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static const _logLevelDefine = String.fromEnvironment('LOG_LEVEL');
  static const _messagingClientPollEnabledDefine = String.fromEnvironment(
    'MESSAGING_CLIENT_POLL_ENABLED',
  );

  @EnviedField(varName: 'APP_ENV', defaultValue: 'development')
  static final String _appEnvEnv = _Env._appEnvEnv;

  @EnviedField(varName: 'SUPABASE_CONNECTION_URL')
  static final String _supabaseConnectionUrlEnv = _Env._supabaseConnectionUrlEnv;

  @EnviedField(varName: 'SUPABASE_ANON_KEY')
  static final String _supabaseAnonKeyEnv = _Env._supabaseAnonKeyEnv;

  @EnviedField(varName: 'LOG_LEVEL', defaultValue: '')
  static final String _logLevelEnv = _Env._logLevelEnv;

  @EnviedField(varName: 'MESSAGING_CLIENT_POLL_ENABLED', defaultValue: 'false')
  static final String _messagingClientPollEnabledEnv =
      _Env._messagingClientPollEnabledEnv;

  static AppEnvironment get appEnvironment =>
      AppEnvironment.fromString(_resolve(_appEnvDefine, _appEnvEnv));

  static bool get isDevelopment => appEnvironment.isDevelopment;
  static bool get isStaging => appEnvironment.isStaging;
  static bool get isProduction => appEnvironment.isProduction;

  static String get appTitle => appEnvironment.displayName;

  static String? get environmentBannerLabel => appEnvironment.bannerLabel;

  static String get supabaseConnectionUrl => _resolve(
        _supabaseConnectionUrlDefine,
        _supabaseConnectionUrlEnv,
      );

  static String get supabaseAnonKey =>
      _resolve(_supabaseAnonKeyDefine, _supabaseAnonKeyEnv);

  static String get logLevel => _resolve(_logLevelDefine, _logLevelEnv);

  static bool get messagingClientPollEnabled => _resolveBool(
        _messagingClientPollEnabledDefine,
        _messagingClientPollEnabledEnv,
        defaultValue: appEnvironment.isDevelopment,
      );

  static String _resolve(String fromDefine, String fromEnv) =>
      fromDefine.isNotEmpty ? fromDefine : fromEnv;

  static bool _resolveBool(
    String fromDefine,
    String fromEnv, {
    required bool defaultValue,
  }) {
    final raw = fromDefine.isNotEmpty ? fromDefine : fromEnv;
    if (raw.isEmpty) {
      return defaultValue;
    }
    return raw.toLowerCase() == 'true';
  }
}
