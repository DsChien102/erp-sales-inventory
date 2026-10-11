import 'package:erp/features/dashboard/presentation/dashboard_page.dart';
import 'package:erp/features/dashboard/presentation/models/dashboard_navigation.dart';
import 'package:erp/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:erp/features/sales/presentation/pages/sales_order_list_page.dart';
import 'package:erp/core/session/models/accessible_tenant.dart';
import 'package:erp/core/session/models/tenant_context.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/session/session_state.dart';
import 'package:erp/features/iam/logic/iam_role_label_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:erp/core/iam/iam_codes.dart';
import 'package:erp/core/session/session_store.dart';
import '../../iam/support/fake_iam_backend.dart';
import 'package:vet45_inventory_application/application.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

import '../../dashboard/presentation/ready_default_pair_inventory_module.dart';
import '../../../core/session/fake_session_repository.dart';

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
    getIt.registerSingleton<IInventoryModule>(
      const ReadyDefaultPairInventoryModule(),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  void registerModule(FakeIamBackend module) {
    getIt
      ..registerSingleton<IExecutionContext>(FakeExecutionContext())
      ..registerSingleton<FakeIamBackend>(module);
  }

  Widget wrapDashboard(FakeSessionRepository repository) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => DashboardPage(
            repository: repository,
            autoBootstrap: true,
          ),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  group('wgt_e05_u01_fr01_01 — list accessible tenants', () {
    test('owner may select their active tenant', () {
      const tenant = AccessibleTenant(
        id: 'org-active',
        name: 'Thú y Minh Phát',
        code: 'TEN-ACTIVE',
        roleCode: 'store_owner',
        status: TenantStatus.active,
        isOwner: true,
      );
      expect(tenant.isSelectable, isTrue);
      expect(IamRoleLabelMapper.toDisplayLabel(tenant.roleCode), 'Chủ cửa hàng');
    });

    test('suspended and closed tenants are not selectable', () {
      const suspended = AccessibleTenant(
        id: 'org-003',
        name: 'ASC Commerce',
        code: 'TEN-ORG003',
        roleCode: 'staff',
        status: TenantStatus.suspended,
      );
      expect(suspended.isSelectable, isFalse);

      const closed = AccessibleTenant(
        id: 'org-004',
        name: 'Đã đóng',
        code: 'TEN-ORG004',
        roleCode: 'store_owner',
        status: TenantStatus.closed,
        isOwner: true,
      );
      expect(closed.isSelectable, isFalse);
      expect(closed.code, startsWith('TEN-'));
    });

    testWidgets('selector: suspended not tappable', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = FakeSessionRepository(
        scenario: FakeIamScenario.tenantsSuspendedDisabled,
      );
      final cubit = SessionController(
        repository: repository,
        userDisplayName: 'Lan',
      );
      await cubit.loadAccessibleTenants();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cubit,
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showSelectOrganizationBottomSheet(
                        context: context,
                        organizations: cubit.state.tenants,
                      );
                    },
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Thú y Minh Phát'), findsOneWidget);
      expect(find.text('Phòng khám Minh Tâm'), findsOneWidget);
      expect(find.text('ASC Commerce'), findsOneWidget);
      expect(find.textContaining('Tạm ngừng'), findsOneWidget);

      await tester.tap(find.text('ASC Commerce'));
      await tester.pumpAndSettle();

      expect(find.text('Chọn tổ chức'), findsOneWidget);
      expect(find.textContaining('Chuyển sang'), findsNothing);

      await cubit.close();
    });

    testWidgets('selector: closed not tappable', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = SessionController(
        repository: FakeSessionRepository(),
        userDisplayName: 'Lan',
        initialState: SessionState(
          userDisplayName: 'Lan',
          status: TenantLoadStatus.ready,
          tenants: const [
            AccessibleTenant(
              id: 'org-closed',
              name: 'Org Closed',
              code: 'TEN-CLOSED',
              roleCode: 'Owner',
              status: TenantStatus.closed,
            ),
            AccessibleTenant(
              id: 'org-active',
              name: 'Thú y Minh Phát',
              code: 'TEN-ACTIVE',
              roleCode: 'Owner',
              status: TenantStatus.active,
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cubit,
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showSelectOrganizationBottomSheet(
                        context: context,
                        organizations: cubit.state.tenants,
                      );
                    },
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Đã đóng'), findsOneWidget);

      await tester.tap(find.text('Org Closed'));
      await tester.pumpAndSettle();
      expect(find.text('Chọn tổ chức'), findsOneWidget);
      expect(find.textContaining('Chuyển sang'), findsNothing);

      await cubit.close();
    });

    testWidgets(
      'selector load failure keeps ready context (isolated selectorFailure)',
      (tester) async {
        final repository = FakeSessionRepository(
          scenario: FakeIamScenario.bootstrapValid,
        );
        final cubit = SessionController(
          repository: repository,
          userDisplayName: 'Lan',
        );
        await cubit.bootstrap();
        expect(cubit.state.status, TenantLoadStatus.ready);
        expect(cubit.state.contextFailure, isNull);

        repository.failNextList = true;
        await cubit.loadAccessibleTenants();

        expect(cubit.state.status, TenantLoadStatus.ready);
        expect(cubit.state.selectorFailure, isNotNull);
        expect(cubit.state.tenants, isEmpty);
        expect(cubit.state.contextFailure, isNull);
        expect(cubit.state.branchDisplayName, isNotNull);
        expect(
          cubit.selectorEmptyStateType,
          OrganizationEmptyStateType.loadError,
        );

        await cubit.close();
      },
    );

    testWidgets('selector loadError retry reloads list in sheet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = FakeSessionRepository(
        scenario: FakeIamScenario.tenantsMulti,
      );
      final cubit = SessionController(
        repository: repository,
        userDisplayName: 'Lan',
      );
      repository.failNextList = true;
      await cubit.loadAccessibleTenants();
      expect(cubit.state.selectorFailure, isNotNull);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cubit,
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showSelectOrganizationBottomSheet(
                        context: context,
                        organizations: cubit.state.tenants,
                        emptyStateType: cubit.selectorEmptyStateType,
                        onRetryLoad: cubit.retryLoadAccessibleTenants,
                      );
                    },
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Không thể tải danh sách'), findsOneWidget);

      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(find.text('Không thể tải danh sách'), findsNothing);
      expect(find.text('Thú y Minh Phát'), findsOneWidget);
      expect(cubit.state.selectorFailure, isNull);

      await cubit.close();
    });

    test('switch success applies tenant permissions', () async {
      final repository = FakeSessionRepository(scenario: FakeIamScenario.switchOk);
      final session = SessionStore()..applyAuthenticatedUser('user-1');
      final cubit = SessionController(
        repository: repository,
        store: session,
        userDisplayName: 'Lan',
      );
      await cubit.bootstrap();

      final ok = await cubit.switchTo('org-002');
      expect(ok, isTrue);
      expect(session.permissions, isNotEmpty);
      expect(session.tenantId, 'org-002');

      await cubit.close();
    });
  });

  group('wgt_e05_u02_fr01_01 — switch tenant', () {
    testWidgets('confirm → switch success updates cubit', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = FakeSessionRepository(scenario: FakeIamScenario.switchOk);
      registerModule(FakeIamBackend(scenario: FakeIamScenario.switchOk));
      final cubit = SessionController(
        repository: repository,
        userDisplayName: 'Lan',
      );
      await cubit.bootstrap();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cubit,
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showSelectOrganizationBottomSheet(
                        context: context,
                        organizations: cubit.state.tenants,
                        onConfirmSwitch: (org) async {
                          await Future<void>.delayed(
                            const Duration(milliseconds: 20),
                          );
                          return cubit.switchTo(org.id);
                        },
                      );
                    },
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phòng khám Minh Tâm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chuyển tổ chức'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(cubit.state.branchDisplayName, 'Phòng khám Minh Tâm');
      expect(repository.switchCount, 1);
      expect(find.textContaining('Đã chuyển sang'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('switch denied keeps context and sets switchFailure', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = FakeSessionRepository(scenario: FakeIamScenario.switchDenied);
      registerModule(FakeIamBackend(scenario: FakeIamScenario.switchDenied));
      final cubit = SessionController(
        repository: repository,
        userDisplayName: 'Lan',
      );
      await cubit.bootstrap();
      final beforeBranch = cubit.state.branchDisplayName;

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cubit,
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showSelectOrganizationBottomSheet(
                        context: context,
                        organizations: cubit.state.tenants,
                        onConfirmSwitch: (org) async {
                          await Future<void>.delayed(
                            const Duration(milliseconds: 20),
                          );
                          final ok = await cubit.switchTo(org.id);
                          if (!ok) {
                            throw Exception(
                              cubit.state.switchFailure?.message ?? 'denied',
                            );
                          }
                          return ok;
                        },
                      );
                    },
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phòng khám Minh Tâm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chuyển tổ chức'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.textContaining('TENANT_ACCESS_DENIED'), findsOneWidget);
      expect(repository.switchCount, 0);
      expect(cubit.state.branchDisplayName, beforeBranch);
      expect(cubit.state.switchFailure, isNotNull);
      expect(cubit.state.isSwitching, isFalse);

      await cubit.close();
    });
  });

  group('wgt_e05_u03_fr01_01 — bootstrap + blocked', () {
    testWidgets('bootstrap valid → header shows tenant', (tester) async {
      final module = FakeIamBackend(scenario: FakeIamScenario.bootstrapValid);
      registerModule(module);

      await tester.pumpWidget(wrapDashboard(FakeSessionRepository(scenario: module.scenario)));
      await tester.pumpAndSettle();

      expect(find.byType(DashboardHeader), findsOneWidget);
      expect(find.textContaining('Thú y Minh Phát'), findsWidgets);
      expect(find.text('Tổng quan hôm nay'), findsOneWidget);
    });

    testWidgets('bootstrap without last selected adopts the first tenant', (tester) async {
      final module = FakeIamBackend(scenario: FakeIamScenario.contextNone);
      registerModule(module);

      final repository = FakeSessionRepository(scenario: module.scenario);
      await tester.pumpWidget(wrapDashboard(repository));
      await tester.pumpAndSettle();

      expect(find.textContaining('Thú y Minh Phát'), findsWidgets);
      expect(find.text('Tổng quan hôm nay'), findsOneWidget);
      expect(repository.lastSelectedTenantId, 'org-001');
    });

    testWidgets('bootstrap invalid → blocked empty state (OQ-07)', (
      tester,
    ) async {
      final module = FakeIamBackend(scenario: FakeIamScenario.bootstrapInvalid);
      registerModule(module);

      await tester.pumpWidget(wrapDashboard(FakeSessionRepository(scenario: module.scenario)));
      await tester.pumpAndSettle();

      expect(find.text('Chưa có tổ chức được cấp quyền'), findsOneWidget);
    });

    testWidgets('context invalidated → inaccessible empty state', (
      tester,
    ) async {
      const ctx = TenantContext(
        status: TenantContextStatus.invalidated,
        tenantId: 'org-001',
        tenantName: 'Thú y Minh Phát',
        invalidationReason: TenantContextInvalidationReason.tenantSuspended,
        blockedErrorCode: 'TENANT_SUSPENDED',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrganizationEmptyView(
              type: OrganizationEmptyStateType.inaccessible,
              suspendedOrgName: ctx.tenantName,
              onAction: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tổ chức không thể truy cập'), findsOneWidget);
      expect(ctx.status, TenantContextStatus.invalidated);
    });

    testWidgets('blocked state shows empty view on orders tab', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = FakeIamBackend();
      registerModule(module);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => DashboardPage(
              repository: FakeSessionRepository(),
              autoBootstrap: false,
              initialTab: DashboardTab.orders,
              initialState: const SessionState(
                userDisplayName: '',
                status: TenantLoadStatus.blocked,
                emptyStateType: OrganizationEmptyStateType.inaccessible,
                suspendedOrgName: 'Vua',
                blockedErrorCode: IamBlockedCodes.tenantSuspended,
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Tổ chức không thể truy cập'), findsOneWidget);
      expect(find.byType(SalesOrderListPage), findsNothing);
    });
  });
}
