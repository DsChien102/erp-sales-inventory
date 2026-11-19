import 'dart:io';

import 'package:nocterm/nocterm.dart';

import '../config_init_service.dart';
import '../manifest.dart';
import 'services_bridge.dart';
import 'shell.dart';
import 'c45_tui_theme.dart';

/// Launch the interactive nocterm TUI (lazygit-style).
Future<void> runC45Tui({Directory? rootDir}) async {
  final root = rootDir ?? Directory(findRepoRoot());
  if (!stdin.hasTerminal || !stdout.hasTerminal) {
    stderr.writeln(
      'c45 TUI requires an interactive terminal. '
      'Use CLI subcommands instead (e.g. c45 list, c45 switch).',
    );
    exit(64);
  }

  requireConfigInitialized(root);
  final manifest = EnvManifest.load(root);
  final bridge = TuiServicesBridge(manifest: manifest);

  await runApp(
    NoctermApp(
      title: 'c45',
      theme: C45TuiTheme.dark,
      child: C45TuiShell(bridge: bridge),
    ),
  );
}
