import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/third_party/xterm_pure.dart/xterm.dart' as xterm;

import '../session_emulator.dart';

/// Renders a [SessionEmulator] buffer and routes keyboard I/O to its PTY.
///
/// The emulator buffer is owned by [TuiSession] so each session keeps an
/// independent screen; this widget only views/resizes/focuses it.
class AdaptiveTerminalXterm extends StatefulComponent {
  const AdaptiveTerminalXterm({
    super.key,
    required this.controller,
    required this.emulator,
    this.focused = false,
    this.onKeyEvent,
    this.autoStart = true,
  });

  final PtyController controller;
  final SessionEmulator emulator;
  final bool focused;
  final bool Function(KeyboardEvent)? onKeyEvent;
  final bool autoStart;

  @override
  State<AdaptiveTerminalXterm> createState() => _AdaptiveTerminalXtermState();
}

class _AdaptiveTerminalXtermState extends State<AdaptiveTerminalXterm> {
  VoidCallback? _controllerListener;
  int _rows = 1;
  int _cols = 1;
  int _scrollOffset = 0;
  bool _started = false;

  xterm.Terminal get _terminal => component.emulator.terminal;

  @override
  void initState() {
    super.initState();
    _terminal.onOutput = (data) {
      if (component.controller.isRunning) {
        component.controller.write(data);
      }
    };
    _terminal.onResize = (width, height, _, __) {
      if (component.controller.isRunning) {
        component.controller.resize(width, height);
      }
    };
    _controllerListener = () {
      if (mounted) setState(() {});
    };
    component.controller.addListener(_controllerListener!);
  }

  Future<void> _start() async {
    try {
      await component.controller.start(columns: _cols, rows: _rows);
    } catch (e) {
      component.emulator.write('\r\nError starting terminal: $e\r\n');
      if (mounted) setState(() {});
    }
  }

  void _updateSize(int cols, int rows) {
    final c = cols.clamp(1, 500);
    final r = rows.clamp(1, 200);
    if (c == _cols && r == _rows) {
      return;
    }
    _cols = c;
    _rows = r;
    component.emulator.resize(_cols, _rows);
    if (!component.controller.isRunning) {
      return;
    }
    try {
      TerminalBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !component.controller.isRunning) {
          return;
        }
        component.controller.resize(_cols, _rows);
      });
    } on Object {
      component.controller.resize(_cols, _rows);
    }
  }

  bool _handleKeyEvent(KeyboardEvent event) {
    if (!component.controller.isRunning) {
      return false;
    }
    if (component.onKeyEvent != null && component.onKeyEvent!(event)) {
      return true;
    }

    if (event.logicalKey == LogicalKey.enter) {
      _terminal.keyInput(xterm.TerminalKey.enter);
    } else if (event.logicalKey == LogicalKey.backspace) {
      _terminal.keyInput(xterm.TerminalKey.backspace);
    } else if (event.logicalKey == LogicalKey.tab) {
      _terminal.keyInput(xterm.TerminalKey.tab);
    } else if (event.logicalKey == LogicalKey.escape) {
      _terminal.keyInput(xterm.TerminalKey.escape);
    } else if (event.logicalKey == LogicalKey.arrowUp) {
      _terminal.keyInput(xterm.TerminalKey.arrowUp);
    } else if (event.logicalKey == LogicalKey.arrowDown) {
      _terminal.keyInput(xterm.TerminalKey.arrowDown);
    } else if (event.logicalKey == LogicalKey.arrowRight) {
      _terminal.keyInput(xterm.TerminalKey.arrowRight);
    } else if (event.logicalKey == LogicalKey.arrowLeft) {
      _terminal.keyInput(xterm.TerminalKey.arrowLeft);
    } else if (event.logicalKey == LogicalKey.home) {
      _terminal.keyInput(xterm.TerminalKey.home);
    } else if (event.logicalKey == LogicalKey.end) {
      _terminal.keyInput(xterm.TerminalKey.end);
    } else if (event.logicalKey == LogicalKey.pageUp) {
      _scroll(-5);
    } else if (event.logicalKey == LogicalKey.pageDown) {
      _scroll(5);
    } else if (event.logicalKey == LogicalKey.delete) {
      _terminal.keyInput(xterm.TerminalKey.delete);
    } else if (event.logicalKey == LogicalKey.insert) {
      _terminal.keyInput(xterm.TerminalKey.insert);
    } else if (event.character != null && event.character!.isNotEmpty) {
      final charCode = event.character!.codeUnitAt(0);
      if (charCode >= 1 && charCode <= 26) {
        _terminal.charInput(charCode);
      } else {
        _terminal.textInput(event.character!);
      }
    }
    return true;
  }

  void _scroll(int delta) {
    final maxScroll = _terminal.buffer.lines.length - _terminal.viewHeight;
    setState(() {
      _scrollOffset = (_scrollOffset + delta).clamp(-maxScroll, 0);
    });
  }

  @override
  void dispose() {
    if (_controllerListener != null) {
      component.controller.removeListener(_controllerListener!);
    }
    super.dispose();
  }

  @override
  void didUpdateComponent(AdaptiveTerminalXterm oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.controller != component.controller) {
      if (_controllerListener != null) {
        oldComponent.controller.removeListener(_controllerListener!);
      }
      _controllerListener = () {
        if (mounted) setState(() {});
      };
      component.controller.addListener(_controllerListener!);
      _started = component.controller.isRunning ||
          component.controller.status != PtyStatus.notStarted;
      _scrollOffset = 0;
      _terminal.onOutput = (data) {
        if (component.controller.isRunning) {
          component.controller.write(data);
        }
      };
      _terminal.onResize = (width, height, _, __) {
        if (component.controller.isRunning) {
          component.controller.resize(width, height);
        }
      };
    }
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: component.focused && component.controller.isRunning,
      onKeyEvent: _handleKeyEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cols = constraints.maxWidth.isFinite
              ? constraints.maxWidth.floor().clamp(1, 500)
              : 80;
          final rows = constraints.maxHeight.isFinite
              ? constraints.maxHeight.floor().clamp(1, 200)
              : 24;
          _updateSize(cols, rows);
          if (!_started &&
              component.autoStart &&
              !component.controller.isRunning &&
              component.controller.status == PtyStatus.notStarted) {
            _started = true;
            _start();
          }
          return _BufferView(
            terminal: _terminal,
            cols: cols,
            rows: rows,
            scrollOffset: _scrollOffset,
          );
        },
      ),
    );
  }
}

class _BufferView extends StatelessComponent {
  const _BufferView({
    required this.terminal,
    required this.cols,
    required this.rows,
    required this.scrollOffset,
  });

  final xterm.Terminal terminal;
  final int cols;
  final int rows;
  final int scrollOffset;

  @override
  Component build(BuildContext context) {
    final buffer = terminal.buffer;
    final totalLines = buffer.lines.length;
    final startLine =
        totalLines < rows ? 0 : (totalLines - rows + scrollOffset).clamp(0, totalLines);
    final lines = <Component>[];

    for (var y = 0; y < rows; y++) {
      final lineIndex = startLine + y;
      if (lineIndex >= 0 && lineIndex < totalLines) {
        final line = buffer.lines[lineIndex];
        final hasCursor = lineIndex == buffer.cursorY && scrollOffset == 0;
        lines.add(_renderLine(line, hasCursor, buffer.cursorX));
      } else {
        lines.add(Text(' ' * cols));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines,
    );
  }

  Component _renderLine(xterm.BufferLine line, bool hasCursor, int cursorX) {
    final buf = StringBuffer();
    final cellData = xterm.CellData.empty();
    final lineLength = line.length;
    TextStyle? style;

    for (var x = 0; x < cols; x++) {
      if (x < lineLength) {
        line.getCellData(x, cellData);
        final codePoint = cellData.content & xterm.CellContent.codepointMask;
        buf.write(codePoint != 0 ? String.fromCharCode(codePoint) : ' ');
        style ??= _cellStyle(cellData, hasCursor && x == cursorX);
      } else {
        buf.write(' ');
      }
    }

    return Text(buf.toString(), style: style);
  }

  TextStyle _cellStyle(xterm.CellData cell, bool isCursor) {
    final flags = cell.flags;
    var reverse = flags & xterm.CellAttr.inverse != 0;
    if (isCursor) reverse = !reverse;
    return TextStyle(
      color: _color(cell.foreground),
      backgroundColor: _color(cell.background),
      fontWeight: flags & xterm.CellAttr.bold != 0
          ? FontWeight.bold
          : (flags & xterm.CellAttr.faint != 0 ? FontWeight.dim : null),
      fontStyle:
          flags & xterm.CellAttr.italic != 0 ? FontStyle.italic : null,
      decoration: flags & xterm.CellAttr.underline != 0
          ? TextDecoration.underline
          : null,
    );
  }

  Color? _color(int color) {
    if (color == 0) return null;
    final colorType = color & xterm.CellColor.typeMask;
    final colorValue = color & xterm.CellColor.valueMask;
    if (colorType == xterm.CellColor.rgb) {
      return Color.fromRGB(
        (colorValue >> 16) & 0xFF,
        (colorValue >> 8) & 0xFF,
        colorValue & 0xFF,
      );
    }
    if (colorType == xterm.CellColor.palette ||
        colorType == xterm.CellColor.named) {
      return _palette(colorValue);
    }
    return null;
  }

  Color _palette(int index) {
    const basic = [
      Colors.black,
      Colors.red,
      Colors.green,
      Colors.yellow,
      Colors.blue,
      Colors.magenta,
      Colors.cyan,
      Colors.white,
      Colors.brightBlack,
      Colors.brightRed,
      Colors.brightGreen,
      Colors.brightYellow,
      Colors.brightBlue,
      Colors.brightMagenta,
      Colors.brightCyan,
      Colors.brightWhite,
    ];
    if (index < basic.length) return basic[index];
    if (index < 232) {
      final i = index - 16;
      return Color.fromRGB((i ~/ 36) * 51, ((i ~/ 6) % 6) * 51, (i % 6) * 51);
    }
    final gray = 8 + (index - 232) * 10;
    return Color.fromRGB(gray, gray, gray);
  }
}
