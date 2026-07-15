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
    return PanelFrame(
      title: 'Environments',
      focused: focused,
      child: environments.isEmpty
          ? Text(
              ' (no <env>.env for profile)',
              style: TextStyle(color: Colors.brightBlack),
            )
          : Scrollbar(
              controller: scrollController,
              thumbVisibility: focused,
              child: ListView.builder(
                controller: scrollController,
                itemCount: environments.length,
                itemBuilder: (context, i) => _line(
                  id: environments[i],
                  active: environments[i] == activeEnvironment,
                  selected: i == cursor,
                ),
              ),
            ),
    );
  }

  Component _line({
    required String id,
    required bool active,
    required bool selected,
  }) {
    final marker = active ? '<' : ' ';
    final prefix = selected ? '>' : ' ';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      decoration: selected && focused
          ? BoxDecoration(color: Color.fromRGB(30, 40, 50))
          : null,
      child: Text(
        '$prefix $id $marker',
        style: TextStyle(
          color: selected && focused
              ? Colors.brightCyan
              : active
                  ? Colors.brightGreen
                  : Colors.white,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
