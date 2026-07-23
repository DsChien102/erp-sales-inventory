import 'package:nocterm/nocterm.dart';

import '../session_manager.dart';
import '../widgets/panel_frame.dart';

/// Session list (sidebar next to the terminal).
class SessionTabsPanel extends StatelessComponent {
  const SessionTabsPanel({
    super.key,
    required this.sessions,
    required this.activeIndex,
    required this.focused,
    this.scrollController,
  });

  final List<TuiSession> sessions;
  final int activeIndex;
  final bool focused;
  final ScrollController? scrollController;

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);
    return PanelFrame(
      title: 'Sessions',
      focused: focused,
      child: sessions.isEmpty
          ? Text(
              ' (n = new session)',
              style: TextStyle(color: theme.outline),
            )
          : Scrollbar(
              controller: scrollController,
              thumbVisibility: focused,
              child: ListView.builder(
                controller: scrollController,
                itemCount: sessions.length,
                itemBuilder: (context, i) {
                  final s = sessions[i];
                  final selected = i == activeIndex;
                  final done = s.exitCode != null ? ' ✓' : '';
                  final running = s.isRunning ? '' : (s.exitCode == null ? ' …' : '');
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: selected && focused
                        ? BoxDecoration(color: theme.selectionColor)
                        : null,
                    child: Text(
                      '${selected ? '>' : ' '} ${s.label}$done$running',
                      style: TextStyle(
                        color: selected && focused
                            ? theme.primary
                            : theme.onSurface,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
