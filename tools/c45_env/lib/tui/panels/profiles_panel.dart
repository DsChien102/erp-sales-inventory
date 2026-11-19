import 'package:nocterm/nocterm.dart';

import '../widgets/panel_frame.dart';

class ProfilesPanel extends StatelessComponent {
  const ProfilesPanel({
    super.key,
    required this.profiles,
    required this.activeProfile,
    required this.cursor,
    required this.focused,
    this.scrollController,
  });

  final List<String> profiles;
  final String activeProfile;
  final int cursor;
  final bool focused;
  final ScrollController? scrollController;

  @override
  Component build(BuildContext context) {
    return PanelFrame(
      title: 'Profiles',
      focused: focused,
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: focused,
        child: ListView.builder(
          controller: scrollController,
          itemCount: profiles.length,
          itemBuilder: (context, i) => _line(
            context: context,
            id: profiles[i],
            active: profiles[i] == activeProfile,
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
