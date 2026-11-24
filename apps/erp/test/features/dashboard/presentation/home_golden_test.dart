import 'dart:async';

import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/session/models/tenant_context.dart';
import 'package:erp/features/dashboard/data/default_pair_repository.dart';
import 'package:erp/features/dashboard/data/models/home_summary.dart';
import 'package:erp/features/dashboard/presentation/erp_tab_scaffold.dart';
import 'package:erp/features/dashboard/presentation/home_tab_page.dart';
import 'package:erp/features/dashboard/presentation/store_shell.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/assistant/data.dart';
import 'package:erp/features/assistant/logic.dart';
import 'package:erp/features/assistant/presentation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../core/session/fake_session_repository.dart';
import '../../iam/support/fake_iam_backend.dart';
import '../../inventory/support/inventory_test_surface.dart';
import '../../receivable/presentation/receivable_test_harness.dart' show repoRoot;
import '../support/fake_home_repository.dart';
import 'fake_default_pair_repository.dart';

class _MockAssistant extends Mock implements AssistantRepository {}

/// Golden 10-8b: Trang chủ trong khung (như ảnh prototype) — so với `proto-APP01-*`.
String _goldenPath(String name) =>
    '${repoRoot()}/docs/refactor/plans/P10/img/10-8b/flutter-APP01-$name.png';

GoRouter _router(
  FakeSessionRepository session,
  FakeHomeRepository home,
  DateTime now,
  AssistantRepository assistant,
) {
  Widget placeholder(String title) =>
      Scaffold(appBar: VAppBar(title: title, showBackButton: false));
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => StoreShell(repository: session, child: child),
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => ErpTabScaffold(navigationShell: shell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (_, _) => HomeTabPage(
                      repository: home,
                      now: () => now,
                      askScope: (child) => BlocProvider(
                        create: (_) => AskAssistantCubit(
                          repository: assistant,
                          tenantId: () async => 'org-001',
                        ),
                        child: child,
                      ),
                      askPanel: (homeContext, {required wide, required onClose}) =>
                          BlocProvider.value(
                            value: homeContext.read<AskAssistantCubit>(),
                            child: AssistantChatPanel(wide: wide, onClose: onClose),
                          ),
                    ),
                  ),
                ],
              ),
              for (final (path, title) in [
                ('/orders', 'Đơn hàng'),
                ('/products/items', 'Sản phẩm'),
                ('/partner', 'Đối tác'),
                ('/more', 'Thêm'),
              ])
                StatefulShellBranch(
                  routes: [GoRoute(path: path, builder: (_, _) => placeholder(title))],
                ),
            ],
          ),
        ],
      ),
    ],
  );
}

FakeSessionRepository _session({String? name = 'Mosaic Retail Demo'}) {
  final r = FakeSessionRepository(scenario: FakeIamScenario.bootstrapValid);
  r.overrideContext = TenantContext(
    status: TenantContextStatus.valid,
    tenantId: 'org-001',
    tenantName: name,
    isOwner: true,
    permissions: const ['tenant.access'],
  );
  return r;
}

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
    getIt.registerSingleton<DefaultPairRepository>(FakeDefaultPairRepository());
  });
  tearDown(() async => getIt.reset());

  Future<void> capture(
    WidgetTester tester, {
    required String name,
    required Size size,
    FakeSessionRepository? session,
    FakeHomeRepository? home,
    DateTime? now,
    bool openAsk = false,
    bool answer = false,
  }) async {
    final assistant = _MockAssistant();
    when(
      () => assistant.ask(
        tenantId: any(named: 'tenantId'),
        question: any(named: 'question'),
        history: any(named: 'history'),
      ),
    ).thenAnswer(
      (_) async => const AssistantReply(
        status: AssistantStatus.ok,
        text: 'Hôm nay cửa hàng bán được 8.420.000 ₫ từ 12 đơn, tăng 18% so với hôm qua.',
        blocks: [],
      ),
    );
    useInventoryTestSurface(size);
    final key = GlobalKey();
    final router = _router(
      session ?? _session(),
      home ?? FakeHomeRepository(),
      now ?? DateTime(2026, 11, 23, 9),
      assistant,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: VTheme.lightTheme,
        routerConfig: router,
        builder: (context, child) => RepaintBoundary(key: key, child: child!),
      ),
    );
    // Khung xương nhấp nháy mãi → không pumpAndSettle ở ca đang tải.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    if (openAsk || answer) {
      await tester.tap(find.byTooltip('Hỏi Mosaic Retail'));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      if (answer) {
        await tester.tap(find.text('Hôm nay bán được bao nhiêu?'));
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
      }
    }
    await expectLater(find.byKey(key), matchesGoldenFile(_goldenPath(name)));
  }

  for (final (w, size) in [('1280', const Size(1280, 800)), ('390', const Size(390, 844))]) {
    testWidgets('owner-$w', (t) => capture(t, name: 'owner-$w', size: size));
    testWidgets(
      'long-name-$w',
      (t) => capture(
        t,
        name: 'long-name-$w',
        size: size,
        session: _session(name: 'Cửa hàng Phân bón Hưng Phát — Chi nhánh Quốc lộ 1A, Long An'),
      ),
    );
    testWidgets(
      'loading-name-$w',
      (t) => capture(t, name: 'loading-name-$w', size: size, session: _session(name: null)),
    );
    testWidgets(
      'evening-$w',
      (t) => capture(t, name: 'evening-$w', size: size, now: DateTime(2026, 11, 23, 20)),
    );
    testWidgets(
      'loading-$w',
      (t) => capture(
        t,
        name: 'loading-$w',
        size: size,
        home: FakeHomeRepository(gate: Completer<HomeSummary>()),
      ),
    );
    testWidgets(
      'error-$w',
      (t) => capture(
        t,
        name: 'error-$w',
        size: size,
        home: FakeHomeRepository(error: const AppException('NETWORK_ERROR')),
      ),
    );
    testWidgets('ask-open-$w', (t) => capture(t, name: 'ask-open-$w', size: size, openAsk: true));
    testWidgets('ask-answer-$w', (t) => capture(t, name: 'ask-answer-$w', size: size, answer: true));
    testWidgets(
      'no-einvoice-$w',
      (t) => capture(
        t,
        name: 'no-einvoice-$w',
        size: size,
        home: FakeHomeRepository(summary: sampleHomeSummary(ordersUninvoiced: null)),
      ),
    );
  }
}
