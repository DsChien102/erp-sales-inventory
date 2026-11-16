import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/assistant/data.dart';
import 'package:erp/features/assistant/logic.dart';
import 'package:erp/features/assistant/presentation.dart';
import 'package:flutter/material.dart' hide TableRow;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vet45_design_system/design_system.dart';

class _MockRepo extends Mock implements AssistantRepository {}

const _cols = [
  TableColumn(key: 'ten', name: 'Sản phẩm', kind: ColumnKind.chu),
  TableColumn(key: 'ton', name: 'Tồn', kind: ColumnKind.so),
  TableColumn(key: 'lai', name: 'Lãi', kind: ColumnKind.tien),
];

AssistantReply _reply({
  String text = 'Kết quả',
  AssistantStatus status = AssistantStatus.ok,
  List<TableBlock> blocks = const [],
  int? remaining,
}) => AssistantReply(status: status, text: text, blocks: blocks, remaining: remaining);

TableBlock _block(List<TableRow> rows) =>
    TableBlock(title: 'Hàng sắp hết', columns: _cols, rows: rows);

void main() {
  late _MockRepo repo;
  late AskAssistantCubit cubit;
  late List<String> pushed;

  When<Future<AssistantReply>> stubAsk() => when(
    () => repo.ask(
      tenantId: any(named: 'tenantId'),
      question: any(named: 'question'),
      history: any(named: 'history'),
    ),
  );

  setUp(() {
    repo = _MockRepo();
    pushed = [];
    cubit = AskAssistantCubit(repository: repo, tenantId: () async => 'T');
  });
  tearDown(() => cubit.close());

  Future<void> pump(WidgetTester tester, {double width = 390}) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => BlocProvider.value(value: cubit, child: const AskAssistantPage()),
        ),
        GoRoute(
          path: '/products/items/:id/view',
          builder: (_, s) {
            pushed.add(s.uri.path);
            return const Scaffold(body: Text('product'));
          },
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(theme: VTheme.lightTheme, routerConfig: router));
    await tester.pump();
  }

  Future<void> ask(WidgetTester tester, [String q = 'hỏi']) async {
    await tester.enterText(find.byType(EditableText), q);
    await tester.tap(find.bySemanticsLabel('Gửi'));
    await tester.pumpAndSettle();
  }

  testWidgets('màn trống hiện lời chào + 4 gợi ý; bấm gợi ý gọi send', (tester) async {
    stubAsk().thenAnswer((_) async => _reply());
    await pump(tester);
    expect(find.text('Chào bạn! Mình giúp bạn xem nhanh số liệu cửa hàng. Thử hỏi:'), findsOneWidget);
    expect(find.text('Hôm nay bán được bao nhiêu?'), findsOneWidget);
    expect(find.text('Khách nào đang nợ?'), findsOneWidget);
    await tester.tap(find.text('Khách nào đang nợ?'));
    await tester.pumpAndSettle();
    verify(() => repo.ask(tenantId: 'T', question: 'Khách nào đang nợ?', history: const [])).called(1);
  });

  testWidgets('mỗi trạng thái hiện reply.text', (tester) async {
    for (final s in AssistantStatus.values) {
      cubit = AskAssistantCubit(repository: repo, tenantId: () async => 'T');
      stubAsk().thenAnswer((_) async => _reply(text: 'tt-${s.name}', status: s));
      await pump(tester);
      await ask(tester);
      expect(find.text('tt-${s.name}'), findsOneWidget);
    }
  });

  testWidgets('hết lượt khoá ô nhập; lỗi có Thử lại', (tester) async {
    stubAsk().thenAnswer((_) async => _reply(text: 'hết', status: AssistantStatus.hetLuot));
    await pump(tester);
    await ask(tester);
    expect(tester.widget<EditableText>(find.byType(EditableText)).readOnly, isTrue);
    expect(find.text('Đã hết lượt hôm nay'), findsOneWidget);

    cubit = AskAssistantCubit(repository: repo, tenantId: () async => 'T');
    stubAsk().thenThrow(const AppException(AppErrorCode.network));
    await pump(tester);
    await ask(tester);
    expect(find.text('Không có kết nối mạng.'), findsOneWidget);
    stubAsk().thenAnswer((_) async => _reply(text: 'ổn'));
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('ổn'), findsOneWidget);
  });

  testWidgets('đang chờ hiện "Đang xem số liệu…" và vô hiệu nút Gửi', (tester) async {
    final completer = Completer<AssistantReply>();
    stubAsk().thenAnswer((_) => completer.future);
    await pump(tester);
    await tester.enterText(find.byType(EditableText), 'a');
    await tester.tap(find.bySemanticsLabel('Gửi'));
    await tester.pump();
    expect(find.text('Đang xem số liệu…'), findsOneWidget);
    expect(tester.widget<VButton>(find.byType(VButton)).onPressed, isNull);
    completer.complete(_reply());
    await tester.pumpAndSettle();
  });

  testWidgets('ô nhập giới hạn 500 ký tự', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(EditableText), 'a' * 600);
    expect(tester.widget<EditableText>(find.byType(EditableText)).controller.text.length, 500);
  });

  testWidgets('rộng 1280: VTable; hẹp 390: thẻ; bấm dòng mở sản phẩm', (tester) async {
    final block = _block([
      const TableRow(
        cells: {'ten': 'Áo', 'ton': 12.5, 'lai': -990000},
        open: OpenTarget(loai: 'san_pham', id: 'p1'),
      ),
      const TableRow(cells: {'ten': 'Quần', 'ton': null, 'lai': 'abc'}),
    ]);
    stubAsk().thenAnswer((_) async => _reply(blocks: [block]));
    await pump(tester, width: 1280);
    await ask(tester);
    expect(find.byType(VTable), findsOneWidget);
    expect(find.text('-990.000đ'), findsOneWidget);
    expect(find.text('12,5'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    await tester.tap(find.text('Áo'));
    await tester.pumpAndSettle();
    expect(pushed, ['/products/items/p1/view']);

    cubit = AskAssistantCubit(repository: repo, tenantId: () async => 'T');
    await pump(tester, width: 390);
    await ask(tester);
    expect(find.byType(VTable), findsNothing);
    expect(find.text('Tồn'), findsNWidgets(2));
    pushed.clear();
    await tester.tap(find.text('Quần'));
    await tester.pumpAndSettle();
    expect(pushed, isEmpty);
    await tester.tap(find.text('Áo'));
    await tester.pumpAndSettle();
    expect(pushed, ['/products/items/p1/view']);
  });

  testWidgets('khoi rỗng hoặc dong rỗng → không vẽ bảng', (tester) async {
    stubAsk().thenAnswer((_) async => _reply(blocks: [_block(const [])]));
    await pump(tester, width: 1280);
    await ask(tester);
    expect(find.byType(VTable), findsNothing);
    expect(find.text('Hàng sắp hết'), findsNothing);
    expect(find.text('Kết quả'), findsOneWidget);
  });

  testWidgets('tên 120 ký tự ở rộng 320 không overflow', (tester) async {
    final block = _block([
      TableRow(cells: {'ten': 'Áo ' * 40, 'ton': 1, 'lai': 2}),
    ]);
    stubAsk().thenAnswer((_) async => _reply(blocks: [block]));
    await pump(tester, width: 320);
    await ask(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('remaining ≤ 10 hiện số lượt, lớn hơn thì ẩn', (tester) async {
    stubAsk().thenAnswer((_) async => _reply(remaining: 11));
    await pump(tester);
    await ask(tester);
    expect(find.textContaining('Còn 11'), findsNothing);
    cubit = AskAssistantCubit(repository: repo, tenantId: () async => 'T');
    stubAsk().thenAnswer((_) async => _reply(remaining: 7));
    await pump(tester);
    await ask(tester);
    expect(find.textContaining('Còn 7'), findsOneWidget);
    expect(find.textContaining('Trợ lý AI có thể hiểu nhầm'), findsOneWidget);
  });
}
