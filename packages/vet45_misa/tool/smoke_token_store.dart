import 'dart:convert';
import 'dart:io';

import 'smoke_env.dart';

/// Persisted Bearer for smoke runs (avoid login-per-command; MISA IP risk).
final class SmokeTokenRecord {
  const SmokeTokenRecord({
    required this.accessToken,
    required this.expiresAt,
    required this.baseUrl,
    this.taxCode,
  });

  final String accessToken;
  final DateTime expiresAt;
  final String baseUrl;
  final String? taxCode;

  bool get isExpired => !DateTime.now().toUtc().isBefore(
        expiresAt.toUtc().subtract(const Duration(minutes: 1)),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'accessToken': accessToken,
        'expiresAt': expiresAt.toUtc().toIso8601String(),
        'baseUrl': baseUrl,
        if (taxCode != null) 'taxCode': taxCode,
      };

  static SmokeTokenRecord fromJson(Map<String, Object?> json) {
    return SmokeTokenRecord(
      accessToken: json['accessToken']! as String,
      expiresAt: DateTime.parse(json['expiresAt']! as String).toUtc(),
      baseUrl: json['baseUrl']! as String,
      taxCode: json['taxCode'] as String?,
    );
  }
}

const defaultSmokeTokenPath = '.meinvoice_token.local';

String resolveTokenFilePath(List<String> args) {
  final fromArg = argValue(args, 'token-file');
  if (fromArg != null && fromArg.isNotEmpty) {
    return fromArg;
  }
  for (final candidate in <String>[
    defaultSmokeTokenPath,
    'packages/vet45_misa/$defaultSmokeTokenPath',
  ]) {
    if (File(candidate).existsSync()) {
      return candidate;
    }
  }
  return defaultSmokeTokenPath;
}

SmokeTokenRecord? loadSmokeToken(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return null;
  }
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map) {
      return null;
    }
    return SmokeTokenRecord.fromJson(Map<String, Object?>.from(decoded));
  } on Object {
    return null;
  }
}

void saveSmokeToken(String path, SmokeTokenRecord record) {
  File(path).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(record.toJson()),
  );
}
