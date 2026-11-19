import 'dart:io';

import 'package:c45_env/aot_binary.dart';
import 'package:c45_env/repo_root.dart';

import 'c45_env.dart' as cli;

/// Melos/cross-platform entry: prefer AOT binary, else run CLI in-process.
Future<void> main(List<String> args) async {
  final repoRoot = Directory(findRepoRoot());
  final binary = AotBinary.resolve(repoRoot);
  if (binary.exists) {
    final process = await Process.start(
      binary.path,
      args,
      mode: ProcessStartMode.inheritStdio,
      workingDirectory: repoRoot.path,
    );
    exit(await process.exitCode);
  }

  stderr.writeln(
    'tip: run `melos run env:build` once for a faster AOT binary '
    '(falling back to dart run)',
  );
  await cli.main(args);
}
