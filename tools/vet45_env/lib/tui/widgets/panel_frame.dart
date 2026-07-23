import 'package:nocterm/nocterm.dart';

/// Bordered titled panel with optional focus highlight.
class PanelFrame extends StatelessComponent {
  const PanelFrame({
    super.key,
    required this.title,
    required this.focused,
    required this.child,
  });

  final String title;
  final bool focused;
  final Component child;

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);
    final borderColor = focused ? theme.primary : theme.outline;
    return Container(
      decoration: BoxDecoration(
        border: BoxBorder.all(
          color: borderColor,
          style: BoxBorderStyle.rounded,
        ),
        title: BorderTitle(
          text: focused ? '* $title' : title,
          style: TextStyle(
            color: focused ? theme.primary : theme.onSurface,
            fontWeight: focused ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
      child: child,
    );
  }
}
