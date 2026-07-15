import 'package:nocterm/nocterm.dart';

class FooterHelp extends StatelessComponent {
  const FooterHelp({super.key, this.busy = false, this.confirmPending});

  final bool busy;
  final String? confirmPending;

  @override
  Component build(BuildContext context) {
    final text = confirmPending != null
        ? 'Confirm switch to $confirmPending? [y]es / [n]o'
        : busy
            ? 'Busy…'
            : 'q quit  Tab focus  ↑↓ select/scroll  Enter switch  s sync  d doctor  r refresh';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Text(
        text,
        style: TextStyle(
          color: confirmPending != null ? Colors.yellow : Colors.brightBlack,
        ),
      ),
    );
  }
}
