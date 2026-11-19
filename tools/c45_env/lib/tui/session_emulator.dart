import 'dart:io';

import 'package:nocterm/src/third_party/xterm_pure.dart/xterm.dart' as xterm;

/// Per-session terminal emulator buffer (not shared across sessions).
class SessionEmulator {
  SessionEmulator({int maxLines = 10000})
      : terminal = xterm.Terminal(
          maxLines: maxLines,
          platform: _platform,
        ) {
    terminal.resize(80, 24);
  }

  final xterm.Terminal terminal;

  static xterm.TerminalTargetPlatform get _platform {
    if (Platform.isMacOS) return xterm.TerminalTargetPlatform.macos;
    if (Platform.isLinux) return xterm.TerminalTargetPlatform.linux;
    if (Platform.isWindows) return xterm.TerminalTargetPlatform.windows;
    return xterm.TerminalTargetPlatform.unknown;
  }

  void write(String data) => terminal.write(data);

  void resize(int columns, int rows) {
    final cols = columns.clamp(1, 500);
    final r = rows.clamp(1, 200);
    terminal.resize(cols, r);
  }
}
