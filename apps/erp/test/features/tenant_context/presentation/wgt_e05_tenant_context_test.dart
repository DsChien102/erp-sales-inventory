import 'package:erp/features/dashboard/presentation/dashboard_page.dart';
import 'package:erp/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:erp/features/tenant_context/presentation/bloc/tenant_context_cubit.dart';
import 'package:erp/features/tenant_context/presentation/bloc/tenant_context_state.dart';
import 'package:erp/features/tenant_context/presentation/mappers/accessible_tenant_ui_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_iam_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  void registerModule(IIamModule module) {
    getIt
      ..registerSingleton<IExecutionContext>(FakeExecutionContext())
      ..registerSingleton<IIamModule>(module);
  }

  Widget wrapDashboard(IIamModule module) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => DashboardPage(
            iamModule: module,
            autoBootstrap: true,
          ),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  group('wgt_e05_u01_fr01_01 — list accessible tenants', () {
    test('mapper: owner may select their provisioning tenant (self-onboard)', () {
      const dto = AccessibleTenantDto(
        tenantId: 'org-provisioning',
        name: 'Đang thiết lập',
        roleLabel: 'Chủ cửa hàng',
        status: TenantLifecycleStatus.provisioning,
        isOwner: true,
      );
      // The DTO's canonical flag stays active-only …
      expect(dto.isSelectable, isFalse);
      // … but the ERP selector lets an owner enter to complete activation.
      final ui = AccessibleTenantUiMapper.fromDto(dto);
      expect(ui.isSelectable, isTrue);
      expect(ui.status, TenantLifecycleStatus.provisioning);
    });

    test('mapper: non-owner cannot select a provisioning tenant', () {
      const dto = AccessibleTenantDto(
        tenantId: 'org-provisioning-staff',
        name: 'Đang thiết lập',
        roleLabel: 'Staff',
        status: TenantLifecycleStatus.provisioning,
      );
      final ui = AccessibleTenantUiMapper.fromDto(dto);
      expect(ui.isSelectable, isFalse);
    });

    test('mapper marks suspended/closed as not selectable', () {
      const suspended = AccessibleTenantDto(
        tenantId: 'org-003',
        name: 'ASC Commerce',
        roleLabel: 'Staff',
        status: TenantLifecycleStatus.suspended,
      );
      final suspendedUi = AccessibleTenantUiMapper.fromDto(suspended);
      expect(suspendedUi.isSelectable, isFalse);
      expect(suspendedUi.status, TenantLifecycleStatus.suspended);

      const closed = AccessibleTenantDto(
        tenantId: 'org-004',
        name: 'Đã đóng',
        roleLabel: 'Chủ cửa hàng',
        status: TenantLifecycleStatus.closed,
        isOwner: true,
      );
      final closedUi = AccessibleTenantUiMapper.fromDto(closed);
      expect(closedUi.isSelectable, isFalse);
      expect(closedUi.status, TenantLifecycleStatus.closed);
      expect(closedUi.code, startsWith('TEN-'));
    });

    test('mapper: maps technical roleCode store_owner to Chủ cửa hàng', () {
      const dto = AccessibleTenantDto(
        tenantId: 'org-store-owner',
        name: 'Sỹ Chiến',
        roleLabel: 'store_owner',
        status: TenantLifecycleStatus.provisioning,
        isOwner: true,
      );
      final ui = AccessibleTenantUiMapper.fromDto(dto);
      expect(ui.roleLabel, 'Chủ cửa hàng');
    });

    testWidgets('selector: suspended not tappable', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = FakeIamModule(
        scenario: FakeIamScenario.tenantsSuspendedDisabled,
      );
      registerModule(module);

      final cubit = TenantContextCubit(
        iamModule: module,
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

    testWidgets('selector: provisioning not tappable', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = TenantContextCubit(
        iamModule: FakeIamModule(),
        userDisplayName: 'Lan',
        initialState: TenantContextState(
          userDisplayName: 'Lan',
          status: TenantContextLoadStatus.ready,
          tenants: const [
            SelectOrganizationItemUiModel(
              id: 'org-provisioning',
              name: 'Đang thiết lập',
              code: 'TEN-PROV',
              roleLabel: 'Owner',
              status: TenantLifecycleStatus.provisioning,
              isSelectable: false,
            ),
            SelectOrganizationItemUiModel(
              id: 'org-active',
              name: 'Thú y Minh Phát',
              code: 'TEN-ACTIVE',
              roleLabel: 'Owner',
              status: TenantLifecycleStatus.active,
              isSelectable: true,
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

      await tester.tap(find.text('Đang thiết lập'));
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

      final cubit = TenantContextCubit(
        iamModule: FakeIamModule(),
        userDisplayName: 'Lan',
        initialState: TenantContextState(
          userDisplayName: 'Lan',
          status: TenantContextLoadStatus.ready,
          tenants: const [
            SelectOrganizationItemUiModel(
              id: 'org-closed',
              name: 'Org Closed',
              code: 'TEN-CLOSED',
              roleLabel: 'Owner',
              status: TenantLifecycleStatus.closed,
              isSelectable: false,
            ),
            SelectOrganizationItemUiModel(
              id: 'org-active',
              name: 'Thú y Minh Phát',
              code: 'TEN-ACTIVE',
              roleLabel: 'Owner',
              status: TenantLifecycleStatus.active,
              isSelectable: true,
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
        final module = _SelectorFailModule(
          FakeIamModule(scenario: FakeIamScenario.bootstrapValid),
        );
        registerModule(module);

        final cubit = TenantContextCubit(
          iamModule: module,
          userDisplayName: 'Lan',
        );
        await cubit.bootstrap();
        expect(cubit.state.status, TenantContextLoadStatus.ready);
        expect(cubit.state.contextFailure, isNull);

        module.failNextList = true;
        await cubit.loadAccessibleTenants();

        expect(cubit.state.status, TenantContextLoadStatus.ready);
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

      final module = _SelectorFailModule(
        FakeIamModule(scenario: FakeIamScenario.tenantsMulti),
      );
      registerModule(module);
      final cubit = TenantContextCubit(
        iamModule: module,
        userDisplayName: 'Lan',
      );
      module.failNextList = true;
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

    test('switch success applies TenantContextDto.permissions', () async {
      final applied = <TenantContextDto>[];
      final module = FakeIamModule(scenario: FakeIamScenario.switchOk);
      final cubit = TenantContextCubit(
        iamModule: module,
        userDisplayName: 'Lan',
        applyPermissions: applied.add,
      );
      await cubit.bootstrap();
      applied.clear();

      final ok = await cubit.switchTo('org-002');
      expect(ok, isTrue);
      expect(applied, hasLength(1));
      expect(applied.single.permissions, isNotEmpty);
      expect(applied.single.tenantId, 'org-002');

      await cubit.close();
    });
  });

  group('wgt_e05_u02_fr01_01 — switch tenant', () {
    testWidgets('confirm → switch success updates cubit', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = FakeIamModule(scenario: FakeIamScenario.switchOk);
      registerModule(module);
      final cubit = TenantContextCubit(
        iamModule: module,
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
      expect(module.switchTenantCount, 1);
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

      final module = FakeIamModule(scenario: FakeIamScenario.switchDenied);
      registerModule(module);
      final cubit = TenantContextCubit(
        iamModule: module,
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
      expect(module.switchTenantCount, 0);
      expect(cubit.state.branchDisplayName, beforeBranch);
      expect(cubit.state.switchFailure, isNotNull);
      expect(cubit.state.isSwitching, isFalse);

      await cubit.close();
    });
  });

  group('wgt_e05_u03_fr01_01 — bootstrap + blocked', () {
    testWidgets('bootstrap valid → header shows tenant', (tester) async {
      final module = FakeIamModule(scenario: FakeIamScenario.bootstrapValid);
      registerModule(module);

      await tester.pumpWidget(wrapDashboard(module));
      await tester.pumpAndSettle();

      expect(find.byType(DashboardHeader), findsOneWidget);
      expect(find.textContaining('Thú y Minh Phát'), findsWidgets);
      expect(find.text('Tổng quan hôm nay'), findsOneWidget);
    });

    testWidgets('bootstrap none → blocked empty state', (tester) async {
      final module = FakeIamModule(scenario: FakeIamScenario.contextNone);
      registerModule(module);

      await tester.pumpWidget(wrapDashboard(module));
      await tester.pumpAndSettle();

      expect(find.text('Chưa có tổ chức được cấp quyền'), findsOneWidget);
      expect(find.text('Tổng quan hôm nay'), findsNothing);
    });

    testWidgets('bootstrap invalid → blocked empty state (OQ-07)', (
      tester,
    ) async {
      final module = FakeIamModule(scenario: FakeIamScenario.bootstrapInvalid);
      registerModule(module);

      await tester.pumpWidget(wrapDashboard(module));
      await tester.pumpAndSettle();

      expect(find.text('Chưa có tổ chức được cấp quyền'), findsOneWidget);
    });

    testWidgets('context invalidated → inaccessible empty state', (
      tester,
    ) async {
      final module = FakeIamModule(
        scenario: FakeIamScenario.contextInvalidated,
      );
      registerModule(module);

      final ctx = await module.executeQueryAsync<TenantContextDto>(
        GetTenantContextQuery(),
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
  });
}

final class _SelectorFailModule implements IIamModule {
  _SelectorFailModule(this.delegate);

  final FakeIamModule delegate;
  bool failNextList = false;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    return delegate.executeCommandAsync(command);
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    if (failNextList && query is ListAccessibleTenantsQuery) {
      failNextList = false;
      throw const IamBlockedException(IamBlockedCodes.systemError);
    }
    return delegate.executeQueryAsync(query);
  }
}
