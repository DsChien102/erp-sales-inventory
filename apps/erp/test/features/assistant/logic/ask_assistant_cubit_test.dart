import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/assistant/data.dart';
import 'package:erp/features/assistant/logic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AssistantRepository {}

AssistantReply reply(String text, {AssistantStatus status = AssistantStatus.ok, int? remaining}) =>
    AssistantReply(status: status, text: text, remaining: remaining);

void main() {
  late _MockRepo repo;
  late String tenant;
  late AskAssistantCubit cubit;

  When<Future<AssistantReply>> stubAsk() => when(
    () => repo.ask(
      tenantId: any(named: 'tenantId'),
      question: any(named: 'question'),
      history: any(named: 'history'),
    ),
  );

  setUp(() {
    repo = _MockRepo();
    tenant = 'T1';
    cubit = AskAssistantCubit(repository: repo, tenantId: () => tenant);
  });

  tearDown(() => cubit.close());

  test('send adds user message then assistant message', () async {
    stubAsk().thenAnswer((_) async => reply('ok!', remaining: 9));
    await cubit.send('  hello ');
    expect(cubit.state.messages.length, 2);
    expect((cubit.state.messages[0] as UserMessage).text, 'hello');
    expect((cubit.state.messages[1] as AssistantMessage).reply.text, 'ok!');
    expect(cubit.state.waiting, false);
    expect(cubit.state.remaining, 9);
  });

  test('ignores empty / whitespace / 501-char question', () async {
    await cubit.send('');
    await cubit.send('   ');
    await cubit.send('a' * 501);
    expect(cubit.state.messages, isEmpty);
    verifyNever(() => repo.ask(tenantId: any(named: 'tenantId'), question: any(named: 'question'), history: any(named: 'history')));
  });

  test('ignores second send while waiting', () async {
    final completer = Completer<AssistantReply>();
    stubAsk().thenAnswer((_) => completer.future);
    final first = cubit.send('a');
    await cubit.send('b');
    completer.complete(reply('x'));
    await first;
    verify(() => repo.ask(tenantId: any(named: 'tenantId'), question: any(named: 'question'), history: any(named: 'history'))).called(1);
  });

  test('history is last 6 text turns and excludes errors and current question', () async {
    stubAsk().thenAnswer((_) async => reply('r'));
    for (var i = 0; i < 5; i++) {
      await cubit.send('q$i');
    }
    stubAsk().thenThrow(const AppException(AppErrorCode.network));
    await cubit.send('bad');
    stubAsk().thenAnswer((_) async => reply('r'));
    await cubit.send('last');
    final captured = verify(
      () => repo.ask(tenantId: any(named: 'tenantId'), question: 'last', history: captureAny(named: 'history')),
    ).captured.single as List<AssistantTurn>;
    expect(captured.length, 6);
    expect(captured.map((t) => t.text), ['r', 'q3', 'r', 'q4', 'r', 'bad']);
    expect(captured.any((t) => t.text == 'last'), false);
  });

  test('tenantId read at each send', () async {
    stubAsk().thenAnswer((_) async => reply('r'));
    await cubit.send('a');
    tenant = 'T2';
    await cubit.send('b');
    verify(() => repo.ask(tenantId: 'T1', question: 'a', history: any(named: 'history'))).called(1);
    verify(() => repo.ask(tenantId: 'T2', question: 'b', history: any(named: 'history'))).called(1);
  });

  test('hetLuot locks further sends; khongQuyen does not', () async {
    stubAsk().thenAnswer((_) async => reply('x', status: AssistantStatus.khongQuyen));
    await cubit.send('a');
    expect(cubit.state.locked, false);
    stubAsk().thenAnswer((_) async => reply('x', status: AssistantStatus.hetLuot));
    await cubit.send('b');
    expect(cubit.state.locked, true);
    await cubit.send('c');
    expect(cubit.state.messages.length, 4);
  });

  test('network error → ErrorMessage offline; authRequired → ErrorMessage; retry reuses question', () async {
    stubAsk().thenThrow(const AppException(AppErrorCode.network));
    await cubit.send('a');
    expect((cubit.state.messages.last as ErrorMessage).offline, true);
    stubAsk().thenThrow(const AppException(AppErrorCode.authRequired));
    await cubit.retry();
    expect((cubit.state.messages.last as ErrorMessage).offline, false);
    expect(cubit.state.messages.whereType<UserMessage>().length, 1);
    stubAsk().thenAnswer((_) async => reply('ok'));
    await cubit.retry();
    expect(cubit.state.messages.length, 2);
    expect(cubit.state.messages.last, isA<AssistantMessage>());
    verify(() => repo.ask(tenantId: any(named: 'tenantId'), question: 'a', history: const [])).called(3);
  });

  test('close while waiting → no emit after close', () async {
    final completer = Completer<AssistantReply>();
    stubAsk().thenAnswer((_) => completer.future);
    final f = cubit.send('a');
    await cubit.close();
    completer.complete(reply('x'));
    await f;
  });
}
