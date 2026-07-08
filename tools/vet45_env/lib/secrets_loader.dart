import 'dart:io';
import 'dart:math';

/// Parse simple KEY=VALUE dotenv files (no export prefix, # comments).
Map<String, String> loadDotEnv(File file) {
  if (!file.existsSync()) {
    return {};
  }
  final result = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      continue;
    }
    final eq = trimmed.indexOf('=');
    if (eq <= 0) {
      continue;
    }
    final key = trimmed.substring(0, eq).trim();
    var value = trimmed.substring(eq + 1).trim();
    if (value.endsWith('\r')) {
      value = value.substring(0, value.length - 1);
    }
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }
    result[key] = value;
  }
  return result;
}

void writeDotEnv(File file, Map<String, String> values, {String? header}) {
  final parent = file.parent;
  if (!parent.existsSync()) {
    parent.createSync(recursive: true);
  }
  final buffer = StringBuffer();
  if (header != null) {
    buffer.writeln(header);
  }
  for (final entry in values.entries) {
    buffer.writeln('${entry.key}=${entry.value}');
  }
  file.writeAsStringSync(buffer.toString());
}

String requireKey(Map<String, String> values, String key) {
  final value = values[key]?.trim() ?? '';
  if (value.isEmpty) {
    throw StateError('Missing required key: $key');
  }
  return value;
}

String optionalKey(Map<String, String> values, String key, String fallback) {
  final value = values[key]?.trim() ?? '';
  return value.isEmpty ? fallback : value;
}

String generateTickSecret() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
