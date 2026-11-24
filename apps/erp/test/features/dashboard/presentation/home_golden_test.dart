import 'dart:async';

import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/session/models/tenant_context.dart';
import 'package:erp/features/dashboard/data/default_pair_repository.dart';
import 'package:erp/features/dashboard/data/models/home_summary.dart';
import 'package:erp/features/dashboard/presentation/erp_tab_scaffold.dart';
import 'package:erp/features/dashboard/presentation/home_tab_page.dart';
import 'package:erp/features/dashboard/presentation/store_shell.dart';
import 'package:erp/core/errors/app_exception.dart';
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

/// Golden 10-8b: Trang chủ trong khung (như ảnh prototype) — so với `proto-APP01-*`.
String _goldenPath(String name) =>
    '${repoRoot()}/docs/refactor/plans/P10/img/10-8b/flutter-APP01-$name.png';

GoRouter _router(FakeSessionRepository session, FakeHomeRepository home, DateTime now) {
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
                    builder: (_, _) => HomeTabPage(repository: home, now: () => now),
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
  }) async {
    useInventoryTestSurface(size);
    final key = GlobalKey();
    final router = _router(
      session ?? _session(),
      home ?? FakeHomeRepository(),
      now ?? DateTime(2026, 11, 23, 9),
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
