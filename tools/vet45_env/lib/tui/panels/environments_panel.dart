import 'package:nocterm/nocterm.dart';

import '../widgets/panel_frame.dart';

class EnvironmentsPanel extends StatelessComponent {
  const EnvironmentsPanel({
    super.key,
    required this.environments,
    required this.activeEnvironment,
    required this.cursor,
    required this.focused,
    this.scrollController,
  });

  final List<String> environments;
  final String activeEnvironment;
  final int cursor;
  final bool focused;
  final ScrollController? scrollController;

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);
    return PanelFrame(
      title: 'Environments',
      focused: focused,
      child: environments.isEmpty
          ? Text(
              ' (no <env>.env for profile)',
              style: TextStyle(color: theme.outline),
            )
          : Scrollbar(
              controller: scrollController,
              thumbVisibility: focused,
              child: ListView.builder(
                controller: scrollController,
                itemCount: environments.length,
                itemBuilder: (context, i) => _line(
                  context: context,
                  id: environments[i],
                  active: environments[i] == activeEnvironment,
                  selected: i == cursor,
                ),
              ),
            ),
    );
  }

  Component _line({
    required BuildContext context,
    required String id,
    required bool active,
    required bool selected,
  }) {
    final theme = TuiTheme.of(context);
    final marker = active ? '<' : ' ';
    final prefix = selected ? '>' : ' ';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      decoration: selected && focused
          ? BoxDecoration(color: theme.selectionColor)
          : null,
      child: Text(
        '$prefix $id $marker',
        style: TextStyle(
          color: selected && focused
              ? theme.primary
              : active
                  ? theme.success
                  : theme.onSurface,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
