import 'package:nocterm/nocterm.dart';

import '../widgets/panel_frame.dart';

class StatusPanel extends StatelessComponent {
  const StatusPanel({
    super.key,
    required this.activeProfile,
    required this.activeEnvironment,
    required this.doctorLines,
    required this.focused,
    this.busy = false,
    this.scrollController,
  });

  final String activeProfile;
  final String activeEnvironment;
  final List<String> doctorLines;
  final bool focused;
  final bool busy;
  final ScrollController? scrollController;

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);
    final lines = <String>[
      'profile=$activeProfile  environment=$activeEnvironment',
      if (busy) 'status=busy',
      ...doctorLines,
    ];
    return PanelFrame(
      title: 'Status / Doctor',
      focused: focused,
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: focused,
        child: ListView.builder(
          controller: scrollController,
          itemCount: lines.length,
          itemBuilder: (context, i) {
            final line = lines[i];
            return Text(
              ' $line',
              style: TextStyle(
                color: line.contains('[FAIL]')
                    ? theme.error
                    : line.contains('[OK]')
                        ? theme.success
                        : theme.onSurface,
              ),
            );
          },
        ),
      ),
    );
  }
}
