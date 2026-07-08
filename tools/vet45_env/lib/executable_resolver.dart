import 'dart:io';

/// Resolves CLI names to concrete paths (Windows `.bat` / PATH).
String resolveExecutable(String name) {
  if (!Platform.isWindows) {
    return name;
  }

  if (_isExplicitPath(name)) {
    return name;
  }

  final fromPath = _lookupOnPath(name);
  if (fromPath != null) {
    return fromPath;
  }

  final fromEnv = _lookupFromKnownRoots(name);
  if (fromEnv != null) {
    return fromEnv;
  }

  return name;
}

/// Whether [executable] should run through cmd.exe on Windows.
bool useShellOnWindows(String executable) {
  if (!Platform.isWindows) {
    return false;
  }
  final lower = executable.toLowerCase();
  if (lower.endsWith('.exe')) {
    return false;
  }
  if (lower.endsWith('.bat') || lower.endsWith('.cmd')) {
    return true;
  }
  // Bare command name (flutter, dart, docker) — shell resolves PATH + .bat.
  return !_isExplicitPath(executable);
}

bool _isExplicitPath(String name) {
  return name.contains('/') || name.contains(r'\');
}

String? _lookupOnPath(String name) {
  try {
    final result = Process.runSync(
      'where',
      [name],
      runInShell: true,
    );
    if (result.exitCode != 0) {
      return null;
    }
    final lines = '${result.stdout}'
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);
    for (final line in lines) {
      if (File(line).existsSync()) {
        return line;
      }
    }
  } on Object {
    return null;
  }
  return null;
}

String? lookupExecutableFromKnownRoots(String name) =>
    _lookupFromKnownRoots(name);

String? _lookupFromKnownRoots(String name) {
  switch (name) {
    case 'flutter':
      return _firstExistingFile([
        _envPath('FLUTTER_ROOT', r'bin\flutter.bat'),
        _envPath('FLUTTER_HOME', r'bin\flutter.bat'),
      ]);
    case 'dart':
      return _firstExistingFile([
        _envPath('DART_SDK', r'bin\dart.exe'),
        _siblingDartSdk(),
      ]);
    case 'docker':
      return _firstExistingFile([
        r'C:\Program Files\Docker\Docker\resources\bin\docker.exe',
      ]);
    default:
      return null;
  }
}

String? _envPath(String envKey, String relative) {
  final root = Platform.environment[envKey]?.trim() ?? '';
  if (root.isEmpty) {
    return null;
  }
  return '$root\\$relative';
}

String? _siblingDartSdk() {
  final dartExe = Platform.resolvedExecutable;
  final sdkRoot = File(dartExe).parent.parent.path;
  final candidate = '$sdkRoot\\bin\\dart.exe';
  return File(candidate).existsSync() ? candidate : null;
}

String? _firstExistingFile(List<String?> candidates) {
  for (final path in candidates) {
    if (path != null && File(path).existsSync()) {
      return path;
    }
  }
  return null;
}
