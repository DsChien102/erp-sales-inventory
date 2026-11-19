import 'package:nocterm/nocterm.dart';

import '../session_manager.dart';
import '../widgets/adaptive_terminal_xterm.dart';
import '../widgets/panel_frame.dart';

/// Embedded PTY for the active session.
class SessionTerminalPanel extends StatelessComponent {
  const SessionTerminalPanel({
    super.key,
    required this.session,
    required this.focused,
    this.onDetach,
  });

  final TuiSession? session;
  final bool focused;
  final VoidCallback? onDetach;

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);
    final live = session != null;
    final running = live && session!.isRunning;
    // Only claim keyboard focus while the PTY is running; after exit, keys
    // must reach the shell (Tab / x / q / 1 / 2).
    final termFocused = focused && running;
    return PanelFrame(
      title: live ? 'Terminal — ${session!.label}' : 'Terminal',
      focused: focused,
      child: !live
          ? Text(
              ' (no session — press n to start)',
              style: TextStyle(color: theme.outline),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  // Key forces a fresh view State per session so scroll/start
                  // flags are not reused; the emulator buffer itself lives on
                  // [TuiSession] and keeps receiving output while hidden.
                  child: AdaptiveTerminalXterm(
                    key: ValueKey(session!.id),
                    controller: session!.controller,
                    emulator: session!.emulator,
                    focused: termFocused,
                    autoStart: true,
                    onKeyEvent: (event) {
                      if (event.logicalKey == LogicalKey.keyO &&
                          event.isControlPressed) {
                        onDetach?.call();
                        return true;
                      }
                      if (event.logicalKey == LogicalKey.keyC &&
                          event.isControlPressed &&
                          session!.controller.isRunning) {
                        session!.controller.write('\u0003');
                        return true;
                      }
                      return false;
                    },
                  ),
                ),
                if (!running)
                  Text(
                    ' (exited'
                    '${session!.exitCode != null ? ' ${session!.exitCode}' : ''}'
                    ' — x close, Tab leave)',
                    style: TextStyle(color: theme.outline),
                  ),
              ],
            ),
    );
  }
}
