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
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/dashboard/data/default_pair_repository.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

import '../../../core/session/fake_session_repository.dart';
import '../../iam/support/fake_iam_backend.dart';
import 'fake_default_pair_repository.dart';

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
    getIt
      ..registerSingleton<IExecutionContext>(FakeExecutionContext(tenantId: 'tenant-test'))
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
                      builder: (context, state) => const HomeTabPage(),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/orders',
                      builder: (context, state) => const Scaffold(
                        body: Center(child: Text('ORDERS_PAGE')),
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
                body: Center(child: Text('MY_ACCOUNT_PAGE')),
              ),
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
      ],
    );
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

  testWidgets('nested flow route /warehouse/receipts/quick/header at 1280 renders in shell without provider errors', (
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
  });

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
}
