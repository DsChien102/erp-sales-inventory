import 'package:erp/core/session/models/tenant_context.dart';
import 'package:erp/features/dashboard/data/default_pair_repository.dart';
import 'package:erp/features/dashboard/presentation/erp_tab_scaffold.dart';
import 'package:erp/features/dashboard/presentation/store_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

import '../../../core/session/fake_session_repository.dart';
import '../../inventory/support/inventory_test_surface.dart';
import '../../iam/support/fake_iam_backend.dart';
import '../../receivable/presentation/receivable_test_harness.dart' show repoRoot;
import 'fake_default_pair_repository.dart';

String _goldenPath(String name) =>
    '${repoRoot()}/docs/refactor/plans/P10/img/10-8a/flutter-shell-$name.png';

Widget _placeholder(String title, String path) => Builder(
  builder: (context) => Scaffold(
    appBar: VAppBar(title: title, showBackButton: false),
    body: Padding(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: ColoredBox(
        color: context.vColors.surfaceAlt,
        child: Center(
          child: Text('Nội dung màn · $path', style: VTypography.bodyDefault),
        ),
      ),
    ),
  ),
);

GoRouter _router(FakeSessionRepository repository, String initial) {
  Widget branch(String path, String title) => _placeholder(title, path);
  return GoRouter(
    initialLocation: initial,
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            StoreShell(repository: repository, child: child),
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => ErpTabScaffold(navigationShell: shell),
            branches: [
              for (final (path, title) in [
                ('/', 'Trang chủ'),
                ('/orders', 'Đơn hàng'),
                ('/products/items', 'Sản phẩm'),
                ('/partner', 'Đối tác'),
                ('/more', 'Thêm'),
              ])
                StatefulShellBranch(
                  routes: [GoRoute(path: path, builder: (_, _) => branch(path, title))],
                ),
            ],
          ),
          GoRoute(path: '/warehouse', builder: (_, _) => branch('/warehouse', 'Kho')),
        ],
      ),
    ],
  );
}

FakeSessionRepository _repo({bool isOwner = true, String name = 'Minh Phát Pet Clinic'}) {
  final r = FakeSessionRepository(scenario: FakeIamScenario.bootstrapValid);
  r.overrideContext = TenantContext(
    status: TenantContextStatus.valid,
    tenantId: 'org-001',
    tenantName: name,
    isOwner: isOwner,
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
    required FakeSessionRepository repository,
    required String location,
    bool openMenu = false,
  }) async {
    useInventoryTestSurface(size);
    final key = GlobalKey();
    final router = _router(repository, location);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: VTheme.lightTheme,
        routerConfig: router,
        builder: (context, child) => RepaintBoundary(key: key, child: child!),
      ),
    );
    await tester.pumpAndSettle();
    if (openMenu) {
      await tester.tap(
        find.descendant(of: find.byType(VSideNavigation), matching: find.text('Quản lý')),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }
    await expectLater(find.byKey(key), matchesGoldenFile(_goldenPath(name)));
  }

  const wide = Size(1280, 800);

  testWidgets('tab-home-1280', (t) => capture(t, name: 'tab-home-1280', size: wide, repository: _repo(), location: '/'));
  testWidgets('tab-orders-1280', (t) => capture(t, name: 'tab-orders-1280', size: wide, repository: _repo(), location: '/orders'));
  testWidgets('sub-warehouse-1280', (t) => capture(t, name: 'sub-warehouse-1280', size: wide, repository: _repo(), location: '/warehouse'));
  testWidgets('menu-sub-warehouse-1280', (t) => capture(t, name: 'menu-sub-warehouse-1280', size: wide, repository: _repo(), location: '/warehouse', openMenu: true));
  testWidgets('menu-session-staff-1280', (t) => capture(t, name: 'menu-session-staff-1280', size: wide, repository: _repo(isOwner: false), location: '/orders', openMenu: true));
  testWidgets('menu-session-blocked-1280', (t) => capture(t, name: 'menu-session-blocked-1280', size: wide, repository: FakeSessionRepository(noTenants: true), location: '/', openMenu: true));
  testWidgets('session-blocked-1280', (t) => capture(t, name: 'session-blocked-1280', size: wide, repository: FakeSessionRepository(noTenants: true), location: '/'));
  testWidgets('session-long-org-1280', (t) => capture(t, name: 'session-long-org-1280', size: wide, repository: _repo(name: 'Công ty TNHH Thương mại Dịch vụ Thú y Phát Đạt Miền Nam'), location: '/'));
  testWidgets('session-narrow-900', (t) => capture(t, name: 'session-narrow-900', size: const Size(900, 800), repository: _repo(), location: '/'));
  testWidgets('tab-home-390', (t) => capture(t, name: 'tab-home-390', size: const Size(390, 844), repository: _repo(), location: '/'));
}
