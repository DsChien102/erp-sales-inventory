import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/assistant/data.dart';
import 'package:erp/features/assistant/logic.dart';
import 'package:erp/features/assistant/presentation.dart';
import 'package:flutter/material.dart' hide TableRow;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AssistantRepository {}

void main() {
  late _MockRepo repo;
  late AskAssistantCubit cubit;
  late List<Object?> askExtras;
  late int closes;

  When<Future<AssistantReply>> stubAsk() => when(
    () => repo.ask(
      tenantId: any(named: 'tenantId'),
      question: any(named: 'question'),
      history: any(named: 'history'),
    ),
  );

  setUp(() {
    repo = _MockRepo();
    cubit = AskAssistantCubit(repository: repo, tenantId: () async => 'T');
    askExtras = [];
    closes = 0;
  });
  tearDown(() => cubit.close());

  Future<void> pump(WidgetTester tester, {required bool wide, double insetBottom = 0}) async {
    final size = wide ? const Size(1120, 700) : const Size(390, 844);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => BlocProvider.value(
            value: cubit,
            child: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  viewInsets: EdgeInsets.only(bottom: insetBottom),
                ),
                child: Scaffold(
                  resizeToAvoidBottomInset: false,
                  body: AssistantChatPanel(wide: wide, onClose: () => closes++),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/ask',
          builder: (_, s) {
            askExtras.add(s.extra);
            return const Scaffold(body: Text('ASK_PAGE'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(theme: VTheme.lightTheme, routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets('empty: greeting + 4 suggestions; wide uses 2-column grid', (tester) async {
    await pump(tester, wide: true);
    expect(find.text('Hỏi Mosaic Retail'), findsOneWidget);
    expect(find.text(assistantGreeting), findsOneWidget);
    for (final s in assistantSuggestions) {
      expect(find.text(s), findsOneWidget);
    }
    final a = tester.getTopLeft(find.text(assistantSuggestions[0]));
    final b = tester.getTopLeft(find.text(assistantSuggestions[1]));
    final c = tester.getTopLeft(find.text(assistantSuggestions[2]));
    expect(a.dy, b.dy, reason: 'gợi ý 1, 2 cùng hàng');
    expect(c.dy, greaterThan(a.dy));
  });

  testWidgets('narrow: suggestions stacked in one column', (tester) async {
    await pump(tester, wide: false);
    final a = tester.getTopLeft(find.text(assistantSuggestions[0]));
    final b = tester.getTopLeft(find.text(assistantSuggestions[1]));
    expect(b.dy, greaterThan(a.dy));
    expect(a.dx, b.dx);
  });

  testWidgets('tap suggestion sends question', (tester) async {
    stubAsk().thenAnswer(
      (_) async => const AssistantReply(status: AssistantStatus.ok, text: 'OK', blocks: []),
    );
    await pump(tester, wide: true);
    await tester.tap(find.text('Hôm nay bán được bao nhiêu?'));
    await tester.pumpAndSettle();
    verify(
      () => repo.ask(
        tenantId: 'T',
        question: 'Hôm nay bán được bao nhiêu?',
        history: any(named: 'history'),
      ),
    ).called(1);
  });

  testWidgets('answer shows inside panel', (tester) async {
    stubAsk().thenAnswer(
      (_) async => const AssistantReply(
        status: AssistantStatus.ok,
        text: 'Hôm nay bán 8.420.000 ₫',
        blocks: [],
      ),
    );
    await pump(tester, wide: false);
    await tester.enterText(find.byType(TextField), 'Doanh thu hôm nay?');
    await tester.tap(find.bySemanticsLabel('Gửi'));
    await tester.pumpAndSettle();
    expect(find.byType(AssistantMessageBubble), findsNWidgets(2));
    expect(find.text('Hôm nay bán 8.420.000 ₫'), findsOneWidget);
    expect(find.text(assistantGreeting), findsNothing);
  });

  testWidgets('expand pushes /ask with same cubit', (tester) async {
    await pump(tester, wide: true);
    await tester.tap(find.bySemanticsLabel('Mở toàn màn hình'));
    await tester.pumpAndSettle();
    expect(closes, 1);
    expect(find.text('ASK_PAGE'), findsOneWidget);
    expect(askExtras.single, same(cubit));
  });

  testWidgets('close button and Escape call onClose', (tester) async {
    await pump(tester, wide: true);
    await tester.tap(find.bySemanticsLabel('Đóng'));
    expect(closes, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(closes, 2);
  });

  testWidgets('composer stays visible with keyboard inset', (tester) async {
    await pump(tester, wide: false, insetBottom: 300);
    final field = tester.getRect(find.byType(TextField));
    expect(tester.takeException(), isNull);
    expect(field.bottom, lessThanOrEqualTo(844 - 300));
  });
}
