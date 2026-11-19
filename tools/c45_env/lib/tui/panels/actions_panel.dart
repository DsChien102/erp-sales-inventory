import 'package:nocterm/nocterm.dart';

import '../services_bridge.dart';
import '../widgets/panel_frame.dart';

class ActionsPanel extends StatelessComponent {
  const ActionsPanel({
    super.key,
    required this.actions,
    required this.cursor,
    required this.focused,
    this.scrollController,
  });

  final List<ActionListItem> actions;
  final int cursor;
  final bool focused;
  final ScrollController? scrollController;

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);
    return PanelFrame(
      title: 'Actions',
      focused: focused,
      child: actions.isEmpty
          ? Text(
              ' (select a target)',
              style: TextStyle(color: theme.outline),
            )
          : Scrollbar(
              controller: scrollController,
              thumbVisibility: focused,
              child: ListView.builder(
                controller: scrollController,
                itemCount: actions.length,
                itemBuilder: (context, i) => _ActionRow(
                  action: actions[i],
                  selected: i == cursor,
                  focused: focused,
                ),
              ),
            ),
    );
  }
}

class _ActionRow extends StatelessComponent {
  const _ActionRow({
    required this.action,
    required this.selected,
    required this.focused,
  });

  final ActionListItem action;
  final bool selected;
  final bool focused;

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);
    final prefix = action.enabled ? (selected ? '>' : ' ') : '!';
    final titleColor = !action.enabled
        ? theme.outline
        : selected && focused
            ? theme.primary
            : theme.onSurface;
    final metaColor = selected && focused ? theme.secondary : theme.outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      decoration: selected && focused
          ? BoxDecoration(color: theme.selectionColor)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$prefix ${action.id}',
            style: TextStyle(
              color: titleColor,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '    ${action.description}',
            style: TextStyle(color: metaColor),
          ),
          if (!action.enabled && action.disabledReason != null)
            Text(
              '    ! ${action.disabledReason}',
              style: TextStyle(color: theme.warning),
            ),
        ],
      ),
    );
  }
}
