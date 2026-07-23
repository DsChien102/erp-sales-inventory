import 'dart:async';

import 'package:nocterm/nocterm.dart' hide isEmpty;
import 'package:nocterm/src/third_party/xterm_pure.dart/xterm.dart' as xterm;
import 'package:test/test.dart';
import 'package:vet45_env/action_runner.dart';
import 'package:vet45_env/tui/session_manager.dart';

void main() {
  ActionLaunchPlan plan(String label) {
    final parts = label.split('/');
    return ActionLaunchPlan(
      command: 'true',
      args: const [],
      workingDirectory: '.',
      environment: const {},
      targetId: parts[0],
      actionId: parts[1],
    );
  }

  PtyController fakeController(ActionLaunchPlan p) => PtyController(
        command: 'true',
        arguments: const [],
        workingDirectory: p.workingDirectory,
      );

  test('open close and active index', () async {
    final mgr = SessionManager(createController: fakeController);
    final a = mgr.open(plan('erp/debug'));
    expect(a.label, 'erp/debug');
    expect(mgr.sessions, hasLength(1));
    expect(mgr.activeIndex, 0);

    mgr.open(plan('worker/serve'));
    expect(mgr.sessions, hasLength(2));
    expect(mgr.activeIndex, 1);
    expect(mgr.activeSession?.label, 'worker/serve');

    mgr.selectPrevious();
    expect(mgr.activeSession?.label, 'erp/debug');
    mgr.selectNext();
    expect(mgr.activeSession?.label, 'worker/serve');

    await mgr.closeActive();
    expect(mgr.sessions, hasLength(1));
    expect(mgr.activeSession?.label, 'erp/debug');

    await mgr.closeAll();
    expect(mgr.sessions.length, 0);
  });

  test('cap at maxSessions', () {
    final mgr = SessionManager(
      maxSessions: 3,
      createController: fakeController,
    );
    mgr.open(plan('a/1'));
    mgr.open(plan('a/2'));
    mgr.open(plan('a/3'));
    expect(
      () => mgr.open(plan('a/4')),
      throwsA(isA<StateError>()),
    );
  });

  test('onSessionExit fires when process exits', () async {
    final done = Completer<TuiSession>();
    final mgr = SessionManager(
      onSessionExit: done.complete,
    );
    mgr.open(
      ActionLaunchPlan(
        command: 'true',
        args: const [],
        workingDirectory: '.',
        environment: const {},
        targetId: 't',
        actionId: 'a',
      ),
    );
    await mgr.activeSession!.controller.start(columns: 20, rows: 5);
    final session = await done.future.timeout(const Duration(seconds: 5));
    expect(session.exitCode, 0);
    expect(session.isRunning, isFalse);
    await mgr.closeAll();
  });

  test('each session keeps an independent emulator buffer', () {
    final mgr = SessionManager(createController: fakeController);
    final a = mgr.open(plan('erp/debug'));
    final b = mgr.open(plan('worker/serve'));

    a.emulator.write('AAA-only\r\n');
    b.emulator.write('BBB-only\r\n');

    expect(identical(a.emulator, b.emulator), isFalse);
    expect(identical(a.emulator.terminal, b.emulator.terminal), isFalse);

    final aText = _plainBufferText(a.emulator.terminal);
    final bText = _plainBufferText(b.emulator.terminal);
    expect(aText, contains('AAA-only'));
    expect(aText, isNot(contains('BBB-only')));
    expect(bText, contains('BBB-only'));
    expect(bText, isNot(contains('AAA-only')));
  });

  test('pty stdout is routed into that session emulator only', () async {
    final mgr = SessionManager();
    final a = mgr.open(
      ActionLaunchPlan(
        command: 'printf',
        args: const ['alpha-session'],
        workingDirectory: '.',
        environment: const {},
        targetId: 't',
        actionId: 'a',
      ),
    );
    final b = mgr.open(
      ActionLaunchPlan(
        command: 'printf',
        args: const ['beta-session'],
        workingDirectory: '.',
        environment: const {},
        targetId: 't',
        actionId: 'b',
      ),
    );

    await a.controller.start(columns: 40, rows: 8);
    await b.controller.start(columns: 40, rows: 8);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final aText = _plainBufferText(a.emulator.terminal);
    final bText = _plainBufferText(b.emulator.terminal);
    expect(aText, contains('alpha-session'));
    expect(aText, isNot(contains('beta-session')));
    expect(bText, contains('beta-session'));
    expect(bText, isNot(contains('alpha-session')));

    await mgr.closeAll();
  });
}

String _plainBufferText(xterm.Terminal terminal) {
  final buffer = terminal.buffer;
  final out = StringBuffer();
  final cell = xterm.CellData.empty();
  for (var y = 0; y < buffer.lines.length; y++) {
    final line = buffer.lines[y];
    for (var x = 0; x < line.length && x < 120; x++) {
      line.getCellData(x, cell);
      final cp = cell.content & xterm.CellContent.codepointMask;
      if (cp != 0) {
        out.writeCharCode(cp);
      }
    }
    out.writeln();
  }
  return out.toString();
}
