import 'package:nocterm/nocterm.dart';

/// Centered overlay: full resolved command + live extra-args cursor.
class ExtraArgsPopup extends StatelessComponent {
  const ExtraArgsPopup({
    super.key,
    required this.title,
    required this.commandLine,
  });

  final String title;

  /// Full command including typed extra args (caller appends cursor glyph).
  final String commandLine;

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);
    final scrim = Colors.black.withOpacity(0.55);
    return Stack(
      fit: StackFit.expand,
      children: [
        ModalBarrier(
          color: scrim,
          obscure: false,
          dismissible: false,
        ),
        Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth.isFinite
                  ? constraints.maxWidth.floor().clamp(48, 140)
                  : 90;
              final boxW = (maxW - 6).clamp(40, 120);
              final inner = boxW - 4;
              final line = _fitLine('$commandLine█', inner);
              return Container(
                width: boxW.toDouble(),
                decoration: BoxDecoration(
                  color: theme.surface,
                  border: BoxBorder.all(
                    color: theme.primary,
                    style: BoxBorderStyle.rounded,
                  ),
                  title: BorderTitle(
                    text: title,
                    style: TextStyle(
                      color: theme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Text(
                        line,
                        style: TextStyle(color: theme.onSurface),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Text(
                        'Enter run · Esc cancel',
                        style: TextStyle(color: theme.outline),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Keep the typing end visible when the command is longer than [width].
  static String _fitLine(String text, int width) {
    if (width <= 1) {
      return text;
    }
    if (text.length <= width) {
      return text;
    }
    return '…${text.substring(text.length - (width - 1))}';
  }
}
