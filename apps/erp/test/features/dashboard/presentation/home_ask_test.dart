import 'dart:async';

import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/router/app_router.dart' show buildAskAssistantRoutePage;
import 'package:erp/core/session/models/tenant_context.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/features/assistant/data.dart';
import 'package:erp/features/assistant/logic.dart';
import 'package:erp/features/assistant/presentation.dart';
import 'package:erp/features/dashboard/data/default_pair_repository.dart';
import 'package:erp/features/dashboard/presentation/erp_tab_scaffold.dart';
import 'package:erp/features/dashboard/presentation/home_tab_page.dart';
import 'package:erp/features/dashboard/presentation/store_shell.dart';
import 'package:erp/features/dashboard/presentation/widgets/erp_bottom_navigation.dart';
import 'package:flutter/material.dart' hide TableRow;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../core/session/fake_session_repository.dart';
import '../../iam/support/fake_iam_backend.dart';
import '../../inventory/support/inventory_test_surface.dart';
import '../support/fake_home_repository.dart';
import 'fake_default_pair_repository.dart';

class _MockAssistant extends Mock implements AssistantRepository {}

const _reply = AssistantReply(
  status: AssistantStatus.ok,
  text: 'Hôm nay bán 8.420.000 ₫',
  blocks: [],
);

FakeSessionRepository _session() {
  final r = FakeSessionRepository(scenario: FakeIamScenario.bootstrapValid);
  r.overrideContext = const TenantContext(
    status: TenantContextStatus.valid,
    tenantId: 'org-001',
    tenantName: 'Mosaic Retail Demo',
    isOwner: true,
    permissions: ['tenant.access'],
  );
  return r;
}

void main() {
  final getIt = GetIt.instance;
  late _MockAssistant assistant;
  late List<AskAssistantCubit> created;
  late FakeHomeRepository homeRepo;

  setUp(() async {
    await getIt.reset();
    getIt.registerSingleton<DefaultPairRepository>(FakeDefaultPairRepository());
    assistant = _MockAssistant();
    created = [];
    homeRepo = FakeHomeRepository();
  });
  tearDown(() async => getIt.reset());

  When<Future<AssistantReply>> stubAsk() => when(
    () => assistant.ask(
      tenantId: any(named: 'tenantId'),
      question: any(named: 'question'),
      history: any(named: 'history'),
    ),
  );

  Widget home({bool withPanel = true}) => HomeTabPage(
    repository: homeRepo,
    now: () => DateTime(2026, 11, 23, 9),
    askScope: (child) => BlocProvider(
      create: (_) {
        final c = AskAssistantCubit(repository: assistant, tenantId: () async => 'org-001');
        created.add(c);
        return c;
      },
      child: child,
    ),
    askPanel: withPanel
        ? (homeContext, {required wide, required onClose}) => BlocProvider.value(
            value: homeContext.read<AskAssistantCubit>(),
            child: AssistantChatPanel(wide: wide, onClose: onClose),
          )
        : null,
  );

  Future<GoRouter> pump(WidgetTester tester, Size size, {bool withPanel = true}) async {
    useInventoryTestSurface(size);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/ask',
          builder: (_, state) => buildAskAssistantRoutePage(state, () {
            final c = AskAssistantCubit(repository: assistant, tenantId: () async => 'org-001');
            created.add(c);
            return c;
          }),
        ),
        ShellRoute(
          builder: (context, state, child) => StoreShell(repository: _session(), child: child),
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (context, state, shell) => ErpTabScaffold(navigationShell: shell),
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/',
                      builder: (_, _) => home(withPanel: withPanel),
                    ),
                  ],
                ),
                for (final path in ['/orders', '/products/items', '/partner', '/more'])
                  StatefulShellBranch(
                    routes: [GoRoute(path: path, builder: (_, _) => const Scaffold())],
                  ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(theme: VTheme.lightTheme, routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  Finder fab(String label) => find.bySemanticsLabel(label);

  testWidgets('1280: fab opens floating window, fab becomes close, Esc closes', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const Size(1280, 800));
    expect(find.byType(AssistantChatPanel), findsNothing);
    await tester.tap(fab('Hỏi Mosaic Retail').last);
    await tester.pumpAndSettle();
    expect(find.byType(AssistantChatPanel), findsOneWidget);
    expect(fab('Đóng Hỏi Mosaic Retail'), findsOneWidget);
    // cửa sổ nổi: trên 64, phải 32 so với vùng nội dung (thanh 84)
    final rect = tester.getRect(find.byType(AssistantChatPanel));
    expect(rect.top, 64);
    expect(rect.right, 1280 - 32);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(AssistantChatPanel), findsNothing);
    expect(fab('Hỏi Mosaic Retail'), findsWidgets);
    handle.dispose();
  });

  testWidgets('390: fab opens full-screen panel covering bottom bar', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const Size(390, 844));
    expect(find.byType(ErpBottomNavigation).hitTestable(), findsOneWidget);
    await tester.tap(fab('Hỏi Mosaic Retail').last);
    await tester.pumpAndSettle();
    expect(find.byType(AssistantChatPanel), findsOneWidget);
    expect(tester.getSize(find.byType(AssistantChatPanel)), const Size(390, 844));
    expect(find.byType(ErpBottomNavigation).hitTestable(), findsNothing);
    await tester.tap(find.bySemanticsLabel('Đóng').last);
    await tester.pumpAndSettle();
    expect(find.byType(AssistantChatPanel), findsNothing);
    handle.dispose();
  });

  testWidgets('reopen keeps conversation', (tester) async {
    stubAsk().thenAnswer((_) async => _reply);
    final handle = tester.ensureSemantics();
    await pump(tester, const Size(1280, 800));
    await tester.tap(fab('Hỏi Mosaic Retail').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hôm nay bán được bao nhiêu?'));
    await tester.pumpAndSettle();
    expect(find.text('Hôm nay bán 8.420.000 ₫'), findsOneWidget);
    await tester.tap(fab('Đóng Hỏi Mosaic Retail'));
    await tester.pumpAndSettle();
    expect(find.text('Hôm nay bán 8.420.000 ₫'), findsNothing);
    await tester.tap(fab('Hỏi Mosaic Retail').last);
    await tester.pumpAndSettle();
    expect(find.text('Hôm nay bán 8.420.000 ₫'), findsOneWidget);
    expect(created, hasLength(1));
    handle.dispose();
  });

  testWidgets('expand while waiting keeps conversation', (tester) async {
    final answer = Completer<AssistantReply>();
    stubAsk().thenAnswer((_) => answer.future);
    final handle = tester.ensureSemantics();
    final router = await pump(tester, const Size(1280, 800));
    await tester.tap(fab('Hỏi Mosaic Retail').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hôm nay bán được bao nhiêu?'));
    await tester.pump();
    expect(find.byType(AssistantWaitingBubble), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Mở toàn màn hình'));
    await tester.pumpAndSettle();
    expect(find.byType(AskAssistantPage), findsOneWidget);
    expect(find.byType(AssistantWaitingBubble), findsOneWidget);
    answer.complete(_reply);
    await tester.pumpAndSettle();
    expect(find.text('Hôm nay bán 8.420.000 ₫'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(fab('Hỏi Mosaic Retail').last);
    await tester.pumpAndSettle();
    expect(find.text('Hôm nay bán 8.420.000 ₫'), findsOneWidget);
    expect(created, hasLength(1));
    handle.dispose();
  });

  testWidgets('390: expand from full-screen panel opens /ask with same cubit', (tester) async {
    stubAsk().thenAnswer((_) async => _reply);
    final handle = tester.ensureSemantics();
    await pump(tester, const Size(390, 844));
    await tester.tap(fab('Hỏi Mosaic Retail').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Khách nào đang nợ?'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Mở toàn màn hình'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(AssistantChatPanel), findsNothing);
    expect(find.byType(AskAssistantPage), findsOneWidget);
    expect(find.text('Hôm nay bán 8.420.000 ₫'), findsOneWidget);
    expect(created, hasLength(1));
    handle.dispose();
  });

  testWidgets('/ask without extra still creates its own cubit', (tester) async {
    final router = await pump(tester, const Size(390, 844));
    router.push('/ask');
    await tester.pumpAndSettle();
    expect(find.byType(AskAssistantPage), findsOneWidget);
    // Cubit của Trang chủ tạo lười (chưa mở khung) → chỉ có cubit riêng của /ask.
    expect(created, hasLength(1));
    final pageCubit = tester.element(find.byType(AskAssistantPage)).read<AskAssistantCubit>();
    expect(pageCubit, same(created.single));
  });

  testWidgets('no askPanel → no fab', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const Size(1280, 800), withPanel: false);
    expect(fab('Hỏi Mosaic Retail'), findsNothing);
    handle.dispose();
  });

  testWidgets('R1-G2 390: tenant change closes full-screen panel (cubit of old tenant)', (
    tester,
  ) async {
    stubAsk().thenAnswer((_) async => _reply);
    final handle = tester.ensureSemantics();
    await pump(tester, const Size(390, 844));
    await tester.tap(fab('Hỏi Mosaic Retail').last);
    await tester.pumpAndSettle();
    expect(find.byType(AssistantChatPanel), findsOneWidget);
    final controller = tester
        .element(find.byType(HomeTabPage, skipOffstage: false))
        .read<SessionController>();
    await controller.switchTo('org-002');
    await tester.pumpAndSettle();
    expect(controller.state.current?.tenantId, 'org-002');
    expect(find.byType(AssistantChatPanel), findsNothing);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  testWidgets('R1-G3 returning to / reloads numbers', (tester) async {
    final router = await pump(tester, const Size(1280, 800));
    expect(homeRepo.calls, 1);
    router.go('/orders');
    await tester.pumpAndSettle();
    expect(homeRepo.calls, 1);
    router.go('/');
    await tester.pumpAndSettle();
    expect(homeRepo.calls, 2);
  });

  testWidgets('R1-G4 web window closes when window shrinks below 1024', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const Size(1280, 800));
    await tester.tap(fab('Hỏi Mosaic Retail').last);
    await tester.pumpAndSettle();
    expect(find.byType(AssistantChatPanel), findsOneWidget);
    useInventoryTestSurface(const Size(900, 800));
    await tester.pumpAndSettle();
    expect(find.byType(AssistantChatPanel), findsNothing);
    useInventoryTestSurface(const Size(1280, 800));
    await tester.pumpAndSettle();
    expect(find.byType(AssistantChatPanel), findsNothing);
    expect(fab('Hỏi Mosaic Retail'), findsWidgets);
    handle.dispose();
  });
}
