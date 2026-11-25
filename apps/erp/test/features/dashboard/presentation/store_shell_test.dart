import 'package:erp/core/session/models/tenant_context.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/session/session_state.dart';
import 'package:erp/features/dashboard/presentation/erp_tab_scaffold.dart';
import 'package:erp/features/dashboard/presentation/home_tab_page.dart';
import 'package:erp/features/dashboard/presentation/store_shell.dart';
import 'package:erp/features/dashboard/presentation/widgets/erp_bottom_navigation.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:erp/features/more/presentation/pages/more_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/dashboard/data/default_pair_repository.dart';

import '../../../core/session/fake_session_repository.dart';
import '../../iam/support/fake_iam_backend.dart';
import 'fake_default_pair_repository.dart';
import '../support/fake_home_repository.dart';

class _CounterPage extends StatefulWidget {
  const _CounterPage();

  @override
  State<_CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<_CounterPage> {
  int n = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SizedBox.expand(
      key: const ValueKey('page-/more/users-and-roles'),
      child: Column(
        children: [
          Text('count $n'),
          TextButton(onPressed: () => setState(() => n++), child: const Text('inc')),
        ],
      ),
    ),
  );
}

void main() {
  test('shellRouteIsUnbounded', () {
    for (final p in [
      '/',
      '/more/organization-profile',
      '/more/organization-profile/legal',
      '/more/users',
      '/more/users/invite',
      '/more/users/members/m1',
      '/more/roles',
      '/more/roles/staff',
      '/more/audit-logs',
      '/more/audit-logs/a1',
      '/more/my-account',
      '/more/my-account/edit',
    ]) {
      expect(shellRouteIsUnbounded(p), isTrue, reason: p);
    }
    for (final p in [
      '/orders',
      '/more',
      '/more/users-and-roles',
      '/more/settings',
      '/more/receivables',
      '/warehouse',
    ]) {
      expect(shellRouteIsUnbounded(p), isFalse, reason: p);
    }
  });

  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
    getIt
      ..registerSingleton<DefaultPairRepository>(FakeDefaultPairRepository())
      ..registerSingleton<FakeIamBackend>(FakeIamBackend());
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('ErpTab.fromLocation unit tests', () {
    test('maps root and subpaths correctly', () {
      expect(ErpTab.fromLocation('/'), ErpTab.home);
      expect(ErpTab.fromLocation('/unknown'), ErpTab.home);

      expect(ErpTab.fromLocation('/orders'), ErpTab.orders);
      expect(ErpTab.fromLocation('/orders/create'), ErpTab.orders);
      expect(ErpTab.fromLocation('/orders/123/edit'), ErpTab.orders);

      expect(ErpTab.fromLocation('/products/items'), ErpTab.products);
      expect(ErpTab.fromLocation('/products/items/456'), ErpTab.products);

      expect(ErpTab.fromLocation('/partner'), ErpTab.partners);
      expect(ErpTab.fromLocation('/partner/789'), ErpTab.partners);

      expect(ErpTab.fromLocation('/more'), ErpTab.more);
      expect(ErpTab.fromLocation('/more/my-account'), ErpTab.more);
      expect(ErpTab.fromLocation('/more/users/invite'), ErpTab.more);
      expect(ErpTab.fromLocation('/inventory/warehouse'), ErpTab.more);
      expect(ErpTab.fromLocation('/warehouse/receipts/quick/header'), ErpTab.more);
      expect(ErpTab.fromLocation('/pricing/customer'), ErpTab.more);
    });
  });

  GoRouter createTestRouter({
    required FakeSessionRepository repository,
    String initialLocation = '/',
  }) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        ShellRoute(
          builder: (context, state, child) => StoreShell(
            repository: repository,
            autoBootstrap: true,
            child: child,
          ),
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (context, state, navigationShell) =>
                  ErpTabScaffold(navigationShell: navigationShell),
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/',
                      builder: (context, state) => HomeTabPage(repository: FakeHomeRepository()),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/orders',
                      builder: (context, state) => const Scaffold(
                        body: SizedBox.expand(
                          key: ValueKey('page-/orders'),
                          child: Center(child: Text('ORDERS_PAGE')),
                        ),
                      ),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/products/items',
                      builder: (context, state) => const Scaffold(
                        body: Center(child: Text('PRODUCTS_PAGE')),
                      ),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/partner',
                      builder: (context, state) => const Scaffold(
                        body: Center(child: Text('PARTNERS_PAGE')),
                      ),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/more',
                      builder: (context, state) => BlocBuilder<SessionController, SessionState>(
                        builder: (context, session) => Scaffold(
                          appBar: const VAppBar(title: 'Thêm', showBackButton: false),
                          body: MorePage(tenantBlocked: session.isBlocked),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: '/more/my-account',
              builder: (context, state) => const Scaffold(
                body: SizedBox.expand(
                  key: ValueKey('page-/more/my-account'),
                  child: Center(child: Text('MY_ACCOUNT_PAGE')),
                ),
              ),
            ),
            GoRoute(
              path: '/warehouse',
              builder: (context, state) => const Scaffold(
                body: SizedBox.expand(
                  key: ValueKey('page-/warehouse'),
                  child: Center(child: Text('WAREHOUSE_PAGE')),
                ),
              ),
            ),
            GoRoute(
              path: '/more/users-and-roles',
              builder: (context, state) => const _CounterPage(),
            ),
            ShellRoute(
              builder: (_, _, child) => child,
              routes: [
                GoRoute(
                  path: '/more/users',
                  builder: (context, state) => const Scaffold(
                    body: SizedBox.expand(
                      key: ValueKey('page-/more/users'),
                      child: Center(child: Text('USERS_PAGE')),
                    ),
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/more/users/invite',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('USERS_INVITE_PAGE')),
              ),
            ),
            GoRoute(
              path: '/warehouse/receipts/quick/header',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('QUICK_RECEIPT_PAGE')),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('LOGIN_PAGE')),
          ),
        ),
      ],
    );
  }

  Future<void> pumpWide(
    WidgetTester tester,
    GoRouter router, {
    double width = 1280,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  FakeSessionRepository ownerRepo({bool isOwner = true, String tenantName = 'Thú y Minh Phát'}) {
    final repository = FakeSessionRepository(scenario: FakeIamScenario.bootstrapValid);
    repository.overrideContext = TenantContext(
      status: TenantContextStatus.valid,
      tenantId: 'org-001',
      tenantName: tenantName,
      isOwner: isOwner,
      permissions: const ['tenant.access'],
    );
    return repository;
  }

  Finder semanticsLabel(String label) => find.byWidgetPredicate(
    (w) => w is Semantics && w.properties.label == label,
  );

  Finder enabledAncestor(Finder of, {required bool enabled}) => find.ancestor(
    of: of,
    matching: find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.enabled == enabled,
    ),
  );

  Finder inNav(Finder f) => find.descendant(of: find.byType(VSideNavigation), matching: f);

  Future<void> openManageMenu(WidgetTester tester) async {
    await tester.tap(inNav(find.text('Quản lý')));
    await tester.pumpAndSettle();
  }

  testWidgets('wide 1280: VSideNavigation present, bottom bar absent, tab navigation works', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = FakeSessionRepository(scenario: FakeIamScenario.bootstrapValid);
    repository.overrideContext = const TenantContext(
      status: TenantContextStatus.valid,
      tenantId: 'org-001',
      tenantName: 'Thú y Minh Phát',
      isOwner: true,
      permissions: ['tenant.access'],
    );
    final router = createTestRouter(repository: repository, initialLocation: '/');

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    // VSideNavigation is present, VBottomNavigationBar is absent
    expect(find.byType(VSideNavigation), findsOneWidget);
    expect(find.byType(ErpBottomNavigation), findsNothing);
    expect(find.byType(VBottomNavigationBar), findsNothing);

    // Tap "Sản phẩm" in side navigation -> navigates to /products/items
    await tester.tap(find.text('Sản phẩm'));
    await tester.pumpAndSettle();

    expect(find.text('PRODUCTS_PAGE'), findsOneWidget);
    expect(find.byType(VSideNavigation), findsOneWidget);

    // Navigate to /more/my-account
    router.go('/more/my-account');
    await tester.pumpAndSettle();

    expect(find.text('MY_ACCOUNT_PAGE'), findsOneWidget);
    expect(find.byType(VSideNavigation), findsOneWidget);

    // 'Thêm' is selected (index 4, child 4 for my-account)
    final sideNav = tester.widget<VSideNavigation>(find.byType(VSideNavigation));
    expect(sideNav.selected.$1, equals(4));
    expect(sideNav.selected.$2, equals(4));
  });

  testWidgets('narrow 390: bottom bar present at root, absent when pushed to sub-route', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = FakeSessionRepository(scenario: FakeIamScenario.bootstrapValid);
    final router = createTestRouter(repository: repository, initialLocation: '/');

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    // At root '/': ErpBottomNavigation is present, VSideNavigation is absent
    expect(find.byType(ErpBottomNavigation), findsOneWidget);
    expect(find.byType(VSideNavigation), findsNothing);

    // Push /more/my-account (sibling of StatefulShellRoute in StoreShell)
    router.go('/more/my-account');
    await tester.pumpAndSettle();

    expect(find.text('MY_ACCOUNT_PAGE'), findsOneWidget);
    expect(find.byType(ErpBottomNavigation), findsNothing);
    expect(find.byType(VSideNavigation), findsNothing);
  });

  testWidgets('tab switching does not re-trigger bootstrap', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = FakeSessionRepository(scenario: FakeIamScenario.bootstrapValid);
    final router = createTestRouter(repository: repository, initialLocation: '/');

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final initialTenantReads = repository.tenantContextReads;
    expect(initialTenantReads, greaterThan(0));

    // Tap "Đơn hàng"
    await tester.tap(find.text('Đơn hàng'));
    await tester.pumpAndSettle();
    expect(find.text('ORDERS_PAGE'), findsOneWidget);

    // Tap "Sản phẩm"
    await tester.tap(find.text('Sản phẩm'));
    await tester.pumpAndSettle();
    expect(find.text('PRODUCTS_PAGE'), findsOneWidget);

    // Bootstrap should NOT have been re-run
    expect(repository.tenantContextReads, equals(initialTenantReads));
  });

  testWidgets('wide 1280 on /more/users/invite: sub-entry "Người dùng & vai trò" is selected', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = FakeSessionRepository(scenario: FakeIamScenario.bootstrapValid);
    repository.overrideContext = const TenantContext(
      status: TenantContextStatus.valid,
      tenantId: 'org-001',
      tenantName: 'Thú y Minh Phát',
      isOwner: true,
      permissions: ['tenant.access'],
    );
    final router = createTestRouter(
      repository: repository,
      initialLocation: '/more/users/invite',
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('USERS_INVITE_PAGE'), findsOneWidget);
    expect(find.byType(VSideNavigation), findsOneWidget);

    // Sub-item 'Người dùng & vai trò' is selected
    final sideNav = tester.widget<VSideNavigation>(find.byType(VSideNavigation));
    expect(sideNav.selected.$1, equals(4));
    expect(sideNav.selected.$2, equals(3));

    // Semantics selected property is true for this item
    expect(
      find.descendant(
        of: find.byType(VSideNavigation),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.selected == true,
        ),
      ),
      findsWidgets,
    );
  });

  testWidgets(
    'nested flow route /warehouse/receipts/quick/header at 1280 renders in shell without provider errors',
    (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = FakeSessionRepository(scenario: FakeIamScenario.bootstrapValid);
      final router = createTestRouter(
        repository: repository,
        initialLocation: '/warehouse/receipts/quick/header',
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('QUICK_RECEIPT_PAGE'), findsOneWidget);
      expect(find.byType(VSideNavigation), findsOneWidget);
    },
  );

  testWidgets('blocked session on /orders: displays OrganizationEmptyView and not ORDERS_PAGE', (
    tester,
  ) async {
    final repository = FakeSessionRepository(noTenants: true);
    final router = createTestRouter(
      repository: repository,
      initialLocation: '/orders',
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byType(OrganizationEmptyView), findsOneWidget);
    expect(find.text('ORDERS_PAGE'), findsNothing);
  });

  testWidgets('loading session on /orders: displays VLoading', (
    tester,
  ) async {
    final repository = FakeSessionRepository(scenario: FakeIamScenario.bootstrapValid);
    final router = createTestRouter(
      repository: repository,
      initialLocation: '/orders',
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.byType(VLoading), findsWidgets);
    expect(find.text('ORDERS_PAGE'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('ORDERS_PAGE'), findsOneWidget);
  });

  testWidgets('blocked session on /more: renders MorePage with tenantBlocked true', (
    tester,
  ) async {
    final repository = FakeSessionRepository(noTenants: true);
    final router = createTestRouter(
      repository: repository,
      initialLocation: '/more',
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byType(MorePage), findsOneWidget);
    final morePage = tester.widget<MorePage>(find.byType(MorePage));
    expect(morePage.tenantBlocked, isTrue);

    // Finding 'Kho' item in MorePage; tapping should not navigate because disabled
    final khoFinder = find.widgetWithText(VCard, 'Kho');
    expect(khoFinder, findsOneWidget);
    await tester.tap(khoFinder);
    await tester.pumpAndSettle();
    expect(find.byType(MorePage), findsOneWidget);
  });

  group('side navigation behaviours (10-8a T0)', () {
    testWidgets('blocked session at 1280: org header label "Đổi tổ chức, Chưa chọn tổ chức"', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final router = createTestRouter(
        repository: FakeSessionRepository(noTenants: true),
        initialLocation: '/orders',
      );
      await pumpWide(tester, router);
      expect(semanticsLabel('Đổi tổ chức, Chưa chọn tổ chức'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('staff at 1280: no "Người dùng & vai trò" sub-entry', (tester) async {
      final router = createTestRouter(
        repository: ownerRepo(isOwner: false),
        initialLocation: '/orders',
      );
      await pumpWide(tester, router);
      await openManageMenu(tester);
      expect(find.text('Quản lý cửa hàng'), findsOneWidget);
      expect(find.text('Tài khoản của tôi'), findsOneWidget);
      expect(find.text('Người dùng & vai trò'), findsNothing);
    });

    testWidgets('blocked at 1280: "Kho" disabled, "Tài khoản của tôi" enabled', (tester) async {
      final handle = tester.ensureSemantics();
      final router = createTestRouter(
        repository: FakeSessionRepository(noTenants: true),
        initialLocation: '/orders',
      );
      await pumpWide(tester, router);
      await openManageMenu(tester);
      expect(enabledAncestor(find.text('Kho'), enabled: false), findsWidgets);
      expect(enabledAncestor(find.text('Tài khoản của tôi'), enabled: true), findsWidgets);
      handle.dispose();
    });

    testWidgets('tap org header opens tenant selector', (tester) async {
      final handle = tester.ensureSemantics();
      final router = createTestRouter(repository: ownerRepo(), initialLocation: '/orders');
      await pumpWide(tester, router);
      await tester.tap(semanticsLabel('Đổi tổ chức, Thú y Minh Phát'));
      await tester.pumpAndSettle();
      expect(find.text('Chọn tổ chức'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('org tile focus ring is drawn outside the tile in primary', (tester) async {
      final router = createTestRouter(repository: ownerRepo(), initialLocation: '/orders');
      await pumpWide(tester, router);
      final ring = find.byKey(const ValueKey('org-tile-focus-ring'));
      BoxDecoration deco() => tester.widget<DecoratedBox>(ring).decoration as BoxDecoration;
      expect((deco().border! as Border).top.color, Colors.transparent);

      // Đưa focus bàn phím vào ô tổ chức (điểm focus đầu tiên của thanh).
      final scope = FocusScope.of(tester.element(ring));
      for (var i = 0; i < 10 && (deco().border! as Border).top.color == Colors.transparent; i++) {
        scope.nextFocus();
        await tester.pumpAndSettle();
      }
      expect((deco().border! as Border).top.color, VColorScheme.light.primary);
      // Viền lớn hơn ô 40×40 mỗi phía 4 (khe 2 + viền 2).
      expect(tester.getSize(ring), const Size(48, 48));
    });

    testWidgets('tap "Đăng xuất" signs out', (tester) async {
      final repository = ownerRepo();
      final controller = SessionController(
        repository: repository,
        initialState: const SessionState(authStatus: AuthStatus.signedIn),
      );
      getIt.registerSingleton<SessionController>(controller);
      final router = createTestRouter(repository: repository, initialLocation: '/orders');
      await pumpWide(tester, router);
      await tester.tap(inNav(find.text('Đăng xuất')));
      await tester.pumpAndSettle();
      expect(controller.state.authStatus, AuthStatus.signedOut);
      expect(find.text('LOGIN_PAGE'), findsOneWidget);
    });

    testWidgets('tap sub-entry "Kho" goes to /warehouse', (tester) async {
      final router = createTestRouter(repository: ownerRepo(), initialLocation: '/orders');
      await pumpWide(tester, router);
      await openManageMenu(tester);
      await tester.tap(find.text('Kho'));
      await tester.pumpAndSettle();
      expect(find.text('WAREHOUSE_PAGE'), findsOneWidget);
    });

    testWidgets('1280 on /orders: content width ≤ 1120', (tester) async {
      final router = createTestRouter(repository: ownerRepo(), initialLocation: '/orders');
      await pumpWide(tester, router);
      expect(
        tester.getSize(find.byKey(const ValueKey('page-/orders'))).width,
        lessThanOrEqualTo(1120),
      );
    });

    testWidgets('1280 on /more/my-account: content width 1196', (tester) async {
      final router = createTestRouter(repository: ownerRepo(), initialLocation: '/more/my-account');
      await pumpWide(tester, router);
      expect(tester.getSize(find.byKey(const ValueKey('page-/more/my-account'))).width, 1196);
    });

    testWidgets('1280 on /more/users-and-roles: content width ≤ 1120', (tester) async {
      final router = createTestRouter(
        repository: ownerRepo(),
        initialLocation: '/more/users-and-roles',
      );
      await pumpWide(tester, router);
      expect(
        tester.getSize(find.byKey(const ValueKey('page-/more/users-and-roles'))).width,
        lessThanOrEqualTo(1120),
      );
    });

    testWidgets('1280: /more/users pushed from /more/users-and-roles is not boxed', (tester) async {
      final router = createTestRouter(
        repository: ownerRepo(),
        initialLocation: '/more/users-and-roles',
      );
      await pumpWide(tester, router);
      await tester.tap(find.text('inc'));
      await tester.pump();
      expect(find.text('count 1'), findsOneWidget);

      router.push('/more/users');
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(const ValueKey('page-/more/users'))).width, 1196);

      router.pop();
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const ValueKey('page-/more/users-and-roles'))).width,
        lessThanOrEqualTo(1120),
      );
      expect(find.text('count 1'), findsOneWidget); // State không bị dựng lại
    });

    testWidgets('1280: /warehouse pushed from / is boxed', (tester) async {
      final router = createTestRouter(repository: ownerRepo(), initialLocation: '/');
      await pumpWide(tester, router);
      router.push('/warehouse');
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const ValueKey('page-/warehouse'))).width,
        lessThanOrEqualTo(1120),
      );
    });

    testWidgets('1280: rail has no "Thêm", has "Quản lý" and "Đăng xuất"', (tester) async {
      final router = createTestRouter(repository: ownerRepo(), initialLocation: '/orders');
      await pumpWide(tester, router);
      expect(inNav(find.text('Thêm')), findsNothing);
      expect(inNav(find.text('Quản lý')), findsOneWidget);
      expect(inNav(find.text('Đăng xuất')), findsOneWidget);
      for (final l in ['Trang chủ', 'Đơn hàng', 'Sản phẩm', 'Đối tác']) {
        expect(inNav(find.text(l)), findsOneWidget, reason: l);
      }
    });

    testWidgets('1280 on /: content width 1196 (không bó)', (tester) async {
      final router = createTestRouter(repository: ownerRepo(), initialLocation: '/');
      await pumpWide(tester, router);
      expect(tester.getSize(find.byType(ErpTabScaffold)).width, 1280 - 84);
    });

    testWidgets('1280 blocked on /: notice spans full content width', (tester) async {
      final router = createTestRouter(
        repository: FakeSessionRepository(noTenants: true),
        initialLocation: '/',
      );
      await pumpWide(tester, router);
      expect(tester.getSize(find.byType(OrganizationEmptyView)).width, greaterThan(1120));
    });

    testWidgets('org tile initial: " đại lý Minh Tâm" → "Đ"', (tester) async {
      final router = createTestRouter(
        repository: ownerRepo(tenantName: ' đại lý Minh Tâm'),
        initialLocation: '/orders',
      );
      await pumpWide(tester, router);
      expect(inNav(find.text('Đ')), findsOneWidget);
    });

    testWidgets('menu closes when tenant changes', (tester) async {
      final repository = FakeSessionRepository(scenario: FakeIamScenario.bootstrapValid);
      final router = createTestRouter(repository: repository, initialLocation: '/orders');
      await pumpWide(tester, router);
      await openManageMenu(tester);
      expect(find.text('Quản lý cửa hàng'), findsOneWidget);

      final controller = tester.element(find.byType(VSideNavigation)).read<SessionController>();
      await controller.switchTo('org-002');
      await tester.pumpAndSettle();
      expect(controller.state.current?.tenantId, 'org-002');
      expect(find.text('Quản lý cửa hàng'), findsNothing);
    });

    testWidgets('900 wide: bottom bar 5 tabs incl. "Thêm", no rail', (tester) async {
      final router = createTestRouter(repository: ownerRepo(), initialLocation: '/');
      await pumpWide(tester, router, width: 900);
      expect(find.byType(VSideNavigation), findsNothing);
      expect(find.byType(ErpBottomNavigation), findsOneWidget);
      for (final l in ['Trang chủ', 'Đơn hàng', 'Sản phẩm', 'Đối tác', 'Thêm']) {
        expect(
          find.descendant(of: find.byType(ErpBottomNavigation), matching: find.text(l)),
          findsOneWidget,
          reason: l,
        );
      }
    });
  });
}
