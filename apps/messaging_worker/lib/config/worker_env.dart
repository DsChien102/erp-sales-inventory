import 'dart:io' show Platform;

import 'package:logging/logging.dart';

import '../worker_tick_policy.dart';

/// Runtime configuration for the messaging worker process.
final class WorkerEnv {
  const WorkerEnv({
    required this.supabaseUrl,
    required this.supabaseServiceRoleKey,
    required this.tickSecret,
    required this.tenantBatchSize,
    required this.moduleBatchSize,
    required this.maxRoundsPerTick,
    required this.concurrency,
    required this.misaAppId,
    required this.misaBaseUrl,
    this.environment = 'unknown',
    this.tickActiveSeconds = 3,
    this.tickIdleSeconds = 15,
    this.tickMaxIdleSeconds = 30,
    this.logLevel = Level.WARNING,
    this.resendApiKey,
    this.resendFromDomain = 'resend.dev',
    this.appLinkBaseUrl,
  });

  final String supabaseUrl;
  final String supabaseServiceRoleKey;
  final String tickSecret;
  final int tenantBatchSize;
  final int moduleBatchSize;
  final int maxRoundsPerTick;
  final int concurrency;
  final String misaAppId;
  final String environment;
  final int tickActiveSeconds;
  final int tickIdleSeconds;
  final int tickMaxIdleSeconds;
  final Level logLevel;

  /// Optional. Missing key → Resend client soft-fails (outcome `failed`).
  final String? resendApiKey;

  /// Verified Resend sender domain (e.g. `mail.vet45.vn`).
  final String resendFromDomain;

  /// Optional HTTPS App Link origin (e.g. `https://app.vet45.example`).
  final String? appLinkBaseUrl;

  /// MISA meInvoice API base URL for e-invoice worker jobs.
  final String misaBaseUrl;

  String get resendFromEmail {
    final normalized = environment.trim().toLowerCase();
    final environmentLabel = switch (normalized) {
      'development' || 'develop' || 'dev' => 'dev',
      'staging' || 'stage' => 'staging',
      'production' || 'prod' => null,
      _ => normalized.isEmpty ? 'unknown' : normalized,
    };
    final displayName = environmentLabel == null
        ? 'VET45'
        : 'VET45 ($environmentLabel)';
    return '$displayName <noreply@$resendFromDomain>';
  }

  WorkerTickPolicy toTickPolicy() {
    return WorkerTickPolicy(
      activeInterval: Duration(seconds: tickActiveSeconds),
      idleInterval: Duration(seconds: tickIdleSeconds),
      maxIdleInterval: Duration(seconds: tickMaxIdleSeconds),
    );
  }

  factory WorkerEnv.fromPlatform() {
    final env = Platform.environment;
    return WorkerEnv(
      supabaseUrl: _require(env, 'SUPABASE_URL'),
      supabaseServiceRoleKey: _require(env, 'SUPABASE_SERVICE_ROLE_KEY'),
      tickSecret: _require(env, 'WORKER_TICK_SECRET'),
      environment: _resolveEnvironment(env),
      tenantBatchSize: _parsePositiveInt(
        env['WORKER_TENANT_BATCH_SIZE'],
        defaultValue: 20,
        maxValue: 500,
      ),
      moduleBatchSize: _parsePositiveInt(
        env['WORKER_MODULE_BATCH_SIZE'],
        defaultValue: 10,
        maxValue: 100,
      ),
      maxRoundsPerTick: _parsePositiveInt(
        env['WORKER_MAX_ROUNDS_PER_TICK'],
        defaultValue: 5,
        maxValue: 50,
      ),
      concurrency: _parsePositiveInt(
        env['WORKER_CONCURRENCY'],
        defaultValue: 4,
        maxValue: 16,
      ),
      tickActiveSeconds: _parsePositiveInt(
        env['WORKER_TICK_ACTIVE_SECONDS'],
        defaultValue: 3,
        maxValue: 300,
      ),
      tickIdleSeconds: _parsePositiveInt(
        env['WORKER_TICK_IDLE_SECONDS'],
        defaultValue: 15,
        maxValue: 300,
      ),
      tickMaxIdleSeconds: _parsePositiveInt(
        env['WORKER_TICK_MAX_IDLE_SECONDS'],
        defaultValue: 30,
        maxValue: 300,
      ),
      logLevel: _parseLogLevel(env['WORKER_LOG_LEVEL']),
      resendApiKey: _optional(env, 'RESEND_API_KEY'),
      resendFromDomain: _optional(env, 'RESEND_FROM_DOMAIN') ?? 'resend.dev',
      appLinkBaseUrl: _optional(env, 'APP_LINK_BASE_URL'),
      misaAppId: _require(env, 'MISA_MEINVOICE_APP_ID'),
      misaBaseUrl: _require(env, 'MISA_MEINVOICE_BASE_URL'),
    );
  }

  static String _resolveEnvironment(Map<String, String> env) {
    final explicit = env['WORKER_ENV']?.trim();
    if (explicit != null && explicit.isNotEmpty && explicit != 'unknown') {
      return explicit;
    }
    final railway = env['RAILWAY_ENVIRONMENT_NAME']?.trim();
    if (railway != null && railway.isNotEmpty) {
      return railway;
    }
    return explicit?.isNotEmpty == true ? explicit! : 'unknown';
  }

  static Level _parseLogLevel(String? raw) {
    if (raw == null || raw.isEmpty) {
      return Level.WARNING;
    }
    final normalized = raw.trim().toUpperCase();
    for (final level in Level.LEVELS) {
      if (level.name == normalized) {
        return level;
      }
    }
    throw FormatException(
      'Unknown WORKER_LOG_LEVEL "$raw". '
      'Use one of: ${Level.LEVELS.map((l) => l.name).join(', ')}',
    );
  }

  static String _require(Map<String, String> env, String key) {
    final value = env[key];
    if (value == null || value.isEmpty) {
      throw StateError('Missing required environment variable: $key');
    }
    return value;
  }

  static String? _optional(Map<String, String> env, String key) {
    final value = env[key];
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  static int _parsePositiveInt(
    String? raw, {
    required int defaultValue,
    required int maxValue,
  }) {
    if (raw == null || raw.isEmpty) {
      return defaultValue;
    }

    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 1) {
      throw FormatException('Expected positive integer, got "$raw".');
    }
    if (parsed > maxValue) {
      throw FormatException('Value $parsed exceeds maximum $maxValue.');
    }
    return parsed;
  }
}
