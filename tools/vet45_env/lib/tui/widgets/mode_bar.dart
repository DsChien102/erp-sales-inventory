import 'package:nocterm/nocterm.dart';

enum TuiMode { env, run }

/// Top bar: `[1] Env  [2] Run`
class ModeBar extends StatelessComponent {
  const ModeBar({super.key, required this.mode});

  final TuiMode mode;

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);
    return Row(
      children: [
        Text(
          '[1] Env',
          style: TextStyle(
            color: mode == TuiMode.env ? theme.primary : theme.outline,
            fontWeight:
                mode == TuiMode.env ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text('  ', style: TextStyle(color: theme.outline)),
        Text(
          '[2] Run',
          style: TextStyle(
            color: mode == TuiMode.run ? theme.primary : theme.outline,
            fontWeight:
                mode == TuiMode.run ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
