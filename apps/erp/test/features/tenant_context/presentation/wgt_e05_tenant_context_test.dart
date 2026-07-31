import 'package:erp/features/dashboard/presentation/dashboard_page.dart';
import 'package:erp/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:erp/features/tenant_context/presentation/bloc/tenant_context_cubit.dart';
import 'package:erp/features/tenant_context/presentation/mappers/accessible_tenant_ui_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_iam_application/application.dart';
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

  void registerModule(FakeIamModule module) {
    getIt
      ..registerSingleton<IExecutionContext>(FakeExecutionContext())
      ..registerSingleton<IIamModule>(module);
  }

  Widget wrapDashboard(FakeIamModule module) {
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
    testWidgets('mapper marks suspended as disabled', (tester) async {
      const dto = AccessibleTenantDto(
        tenantId: 'org-003',
        name: 'ASC Commerce',
        roleLabel: 'Staff',
        status: TenantLifecycleStatus.suspended,
      );

      final ui = AccessibleTenantUiMapper.fromDto(dto);
      expect(ui.isSuspended, isTrue);
      expect(ui.code, startsWith('TEN-'));
    });

    testWidgets('selector lists FakeIam tenants; suspended not tappable', (
      tester,
    ) async {
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

    testWidgets('switch denied shows failure toast', (tester) async {
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
                        onConfirmSwitch: (org) async {
                          await Future<void>.delayed(
                            const Duration(milliseconds: 20),
                          );
                          final ok = await cubit.switchTo(org.id);
                          if (!ok) {
                            throw Exception(
                              cubit.state.errorMessage ?? 'denied',
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
