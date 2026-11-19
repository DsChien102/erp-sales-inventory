import 'package:nocterm/nocterm.dart';

import '../services_bridge.dart';
import '../widgets/panel_frame.dart';

class TargetsPanel extends StatelessComponent {
  const TargetsPanel({
    super.key,
    required this.targets,
    required this.cursor,
    required this.focused,
    this.scrollController,
  });

  final List<RunnableTargetInfo> targets;
  final int cursor;
  final bool focused;
  final ScrollController? scrollController;

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);
    return PanelFrame(
      title: 'Targets',
      focused: focused,
      child: targets.isEmpty
          ? Text(
              ' (no targets with actions)',
              style: TextStyle(color: theme.outline),
            )
          : Scrollbar(
              controller: scrollController,
              thumbVisibility: focused,
              child: ListView.builder(
                controller: scrollController,
                itemCount: targets.length,
                itemBuilder: (context, i) {
                  final t = targets[i];
                  final selected = i == cursor;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: selected && focused
                        ? BoxDecoration(color: theme.selectionColor)
                        : null,
                    child: Text(
                      '${selected ? '>' : ' '} ${t.id}',
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
