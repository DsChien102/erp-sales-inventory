import 'dart:io';

/// Loads KEY=VALUE lines into [Platform.environment]-style map.
/// Does not override keys already present in [existing].
Map<String, String> loadDotEnvFile(String path, {Map<String, String>? existing}) {
  final out = Map<String, String>.from(existing ?? Platform.environment);
  final file = File(path);
  if (!file.existsSync()) {
    return out;
  }
  for (final raw in file.readAsLinesSync()) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }
    final eq = line.indexOf('=');
    if (eq <= 0) {
      continue;
    }
    final key = line.substring(0, eq).trim();
    var value = line.substring(eq + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }
    out.putIfAbsent(key, () => value);
  }
  return out;
}

/// Resolves env file path: --env-file, else .env.misa.local in cwd / package root.
String? resolveEnvFilePath(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a.startsWith('--env-file=')) {
      return a.substring('--env-file='.length);
    }
    if (a == '--env-file' && i + 1 < args.length) {
      return args[i + 1];
    }
  }
  for (final candidate in <String>[
    '.env.misa.local',
    'packages/vet45_misa/.env.misa.local',
  ]) {
    if (File(candidate).existsSync()) {
      return candidate;
    }
  }
  return null;
}

String? envGet(Map<String, String> env, String key) {
  final v = env[key];
  if (v == null || v.isEmpty) {
    return null;
  }
  return v;
}

bool envFlag(Map<String, String> env, String key, {bool defaultValue = false}) {
  final v = envGet(env, key)?.toLowerCase();
  if (v == null) {
    return defaultValue;
  }
  return v == '1' || v == 'true' || v == 'yes';
}

String? argValue(List<String> args, String name) {
  final prefix = '--$name=';
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a.startsWith(prefix)) {
      return a.substring(prefix.length);
    }
    if (a == '--$name' && i + 1 < args.length) {
      return args[i + 1];
    }
  }
  return null;
}

bool hasFlag(List<String> args, String name) =>
    args.contains('--$name') || args.contains('-$name');

Future<String?> readPasswordFromStdin() async {
  stdout.write('MISA_MEINVOICE_PASSWORD (hidden if terminal supports): ');
  try {
    stdin.echoMode = false;
  } on StdinException {
    // non-TTY
  }
  try {
    final line = stdin.readLineSync();
    stdout.writeln();
    return line;
  } finally {
    try {
      stdin.echoMode = true;
    } on StdinException {
      // ignore
    }
  }
}
