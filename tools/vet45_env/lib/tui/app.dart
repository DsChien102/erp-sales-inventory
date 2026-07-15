import 'dart:io';

import 'package:nocterm/nocterm.dart';

import '../config_init_service.dart';
import '../manifest.dart';
import 'services_bridge.dart';
import 'shell.dart';

/// Launch the interactive nocterm TUI (lazygit-style).
Future<void> runVet45Tui({Directory? rootDir}) async {
  final root = rootDir ?? Directory(findRepoRoot());
  if (!stdin.hasTerminal || !stdout.hasTerminal) {
    stderr.writeln(
      'vet45 TUI requires an interactive terminal. '
      'Use CLI subcommands instead (e.g. vet45 list, vet45 switch).',
    );
    exit(64);
  }

  requireConfigInitialized(root);
  final manifest = EnvManifest.load(root);
  final bridge = TuiServicesBridge(manifest: manifest);

  await runApp(Vet45TuiShell(bridge: bridge));
}
