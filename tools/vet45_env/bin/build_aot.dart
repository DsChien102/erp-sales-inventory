import 'dart:convert';
import 'dart:io';

import 'package:vet45_env/aot_binary.dart';
import 'package:vet45_env/repo_root.dart';

/// Compiles the `vet45` AOT binary under `.vet45/bin/`.
///
/// Usage:
///   dart run tools/vet45_env/bin/build_aot.dart [--force]
Future<void> main(List<String> args) async {
  final force = args.contains('--force');
  final repoRoot = Directory(findRepoRoot());
  final packageRoot = Directory('${repoRoot.path}/tools/vet45_env');
  final entry = File('${packageRoot.path}/bin/vet45_env.dart');
  if (!entry.existsSync()) {
    stderr.writeln('Missing entrypoint: ${entry.path}');
    exit(1);
  }

  final binDir = AotBinary.binDir(repoRoot);
  binDir.createSync(recursive: true);

  final binary = AotBinary.resolve(repoRoot);
  final stampFile = AotBinary.stampFile(repoRoot);
  final stamp = _sourceStamp(packageRoot);

  if (!force &&
      binary.exists &&
      stampFile.existsSync() &&
      stampFile.readAsStringSync().trim() == stamp) {
    stdout.writeln('AOT up to date: ${binary.path}');
    _removeLegacyBinaries(repoRoot);
    return;
  }

  stdout.writeln('Compiling AOT → ${binary.path}');
  final result = await Process.run(
    Platform.resolvedExecutable,
    [
      'compile',
      'exe',
      entry.path,
      '-o',
      binary.path,
    ],
    workingDirectory: packageRoot.path,
  );
  if (result.exitCode != 0) {
    stderr.write('${result.stdout}');
    stderr.write('${result.stderr}');
    exit(result.exitCode);
  }

  stampFile.writeAsStringSync('$stamp\n');
  if (!Platform.isWindows) {
    await Process.run('chmod', ['+x', binary.path]);
  }
  _removeLegacyBinaries(repoRoot);
  stdout.writeln('Built ${binary.path}');
}

void _removeLegacyBinaries(Directory repoRoot) {
  for (final file in [
    AotBinary.legacyFile(repoRoot),
    AotBinary.legacyStampFile(repoRoot),
  ]) {
    if (file.existsSync()) {
      file.deleteSync();
    }
  }
}

String _sourceStamp(Directory packageRoot) {
  final files = <File>[
    File('${packageRoot.path}/bin/vet45_env.dart'),
    File('${packageRoot.path}/pubspec.yaml'),
    ..._dartFilesUnder(Directory('${packageRoot.path}/lib')),
  ]..sort((a, b) => a.path.compareTo(b.path));

  final buffer = StringBuffer();
  for (final file in files) {
    if (!file.existsSync()) {
      continue;
    }
    final relative = file.path.substring(packageRoot.path.length + 1);
    buffer.writeln('$relative:${file.lengthSync()}:${_fnv1a(file.readAsBytesSync())}');
  }
  return _fnv1a(utf8.encode(buffer.toString())).toRadixString(16);
}

List<File> _dartFilesUnder(Directory dir) {
  if (!dir.existsSync()) {
    return const [];
  }
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();
}

int _fnv1a(List<int> bytes) {
  var hash = 0xcbf29ce484222325;
  for (final b in bytes) {
    hash ^= b;
    hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
  }
  return hash;
}
