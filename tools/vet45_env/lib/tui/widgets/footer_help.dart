import 'package:nocterm/nocterm.dart';

class FooterHelp extends StatelessComponent {
  const FooterHelp({
    super.key,
    this.busy = false,
    this.confirmPending,
    this.hintOverride,
  });

  final bool busy;
  final String? confirmPending;
  final String? hintOverride;

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);
    final text = hintOverride ??
        (confirmPending != null
            ? 'Confirm switch to $confirmPending? [y]es / [n]o'
            : busy
                ? 'Busy…'
                : 'q quit  1 Env  2 Run  Tab focus  Enter  s sync  d doctor');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Text(
        text,
        style: TextStyle(
          color: (confirmPending != null || hintOverride != null)
              ? theme.warning
              : theme.outline,
        ),
      ),
    );
  }
}
