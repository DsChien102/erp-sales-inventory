import 'package:nocterm/nocterm.dart';

import '../widgets/panel_frame.dart';

class LogPanel extends StatelessComponent {
  const LogPanel({
    super.key,
    required this.logs,
    required this.focused,
    this.scrollController,
  });

  final List<String> logs;
  final bool focused;
  final ScrollController? scrollController;

  @override
  Component build(BuildContext context) {
    return PanelFrame(
      title: 'Log',
      focused: focused,
      child: logs.isEmpty
          ? Text(
              ' (empty)',
              style: TextStyle(color: Colors.brightBlack),
            )
          : Scrollbar(
              controller: scrollController,
              thumbVisibility: focused,
              child: ListView.builder(
                controller: scrollController,
                itemCount: logs.length,
                itemBuilder: (context, i) {
                  final line = logs[i];
                  return Text(
                    ' $line',
                    style: TextStyle(
                      color: line.contains('FAIL') || line.contains('failed')
                          ? Colors.red
                          : Colors.white,
                    ),
                  );
                },
              ),
            ),
    );
  }
}
