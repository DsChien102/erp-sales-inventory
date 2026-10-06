import 'dart:async';

import 'package:erp/features/dashboard/presentation/dashboard_page.dart';
import 'package:erp/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:erp/features/dashboard/presentation/widgets/erp_bottom_navigation.dart';
import 'package:erp/features/tenant_context/presentation/bloc/tenant_context_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_inventory_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  testWidgets('scn_dashboard_gate_success', (tester) async {
    await _setPhone(tester);
    final port = FakeDefaultStoreWarehousePairPort(tenantDisplayName: 'Mậu Hiên');
    final inner = _HandlerInventoryModule(port);
    final gate = Completer<void>();
    var opened = false;
    final module = _PausingInventoryModule(
      inner,
      pause: () async {
        if (opened) return;
        await gate.future;
        opened = true;
      },
    );

    await tester.pumpWidget(_app(module));
    expect(find.byType(VLoading), findsOneWidget);
    expect(find.byType(DashboardHeader), findsNothing);
    expect(find.byType(ErpBottomNavigation), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Tổng quan hôm nay'), findsOneWidget);
    expect(find.byType(DashboardHeader), findsOneWidget);
    expect(find.byType(ErpBottomNavigation), findsOneWidget);
    expect(port.warehouses, hasLength(1));
    expect(port.assignments, hasLength(1));
  });

  testWidgets('scn_dashboard_gate_error', (tester) async {
    await _setPhone(tester);
    final port = FakeDefaultStoreWarehousePairPort(tenantDisplayName: 'Mậu Hiên');
    port
      ..seedActiveWarehouse(tenantId: 'tenant-test', id: 'wh-1')
      ..seedActiveWarehouse(tenantId: 'tenant-test', id: 'wh-2');
    final inner = _HandlerInventoryModule(port);
    final gate = Completer<void>();
    var opened = false;
    final module = _PausingInventoryModule(
      inner,
      pause: () async {
        if (opened) return;
        await gate.future;
        opened = true;
      },
    );

    await tester.pumpWidget(_app(module));
    expect(find.byType(DashboardHeader), findsNothing);
    expect(find.byType(ErpBottomNavigation), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Không thiết lập được kho mặc định'), findsOneWidget);
    expect(find.text('Tổng quan hôm nay'), findsNothing);
    expect(find.byType(DashboardHeader), findsNothing);
    expect(find.text('Không thể tải danh sách'), findsNothing);
    expect(inner.ensureCount, 1);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('Không thiết lập được kho mặc định'), findsOneWidget);
    expect(find.text('Tổng quan hôm nay'), findsNothing);
    expect(inner.ensureCount, 2);

    await tester.tap(find.text('Chọn tổ chức khác'));
    await tester.pumpAndSettle();

    expect(find.text('Chọn tổ chức'), findsOneWidget);
    expect(find.text('Tổng quan hôm nay'), findsNothing);
  });
}

Future<void> _setPhone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(IInventoryModule inventoryModule) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'dashboard',
        builder: (context, state) => DashboardPage(
          autoBootstrap: false,
          iamModule: FakeIamModule(scenario: FakeIamScenario.tenantsMulti),
          inventoryModule: inventoryModule,
          initialState: const TenantContextState(
            status: TenantContextLoadStatus.ready,
            userDisplayName: 'Lan',
            current: TenantContextDto(
              status: TenantContextStatus.valid,
              tenantId: 'tenant-test',
              tenantName: 'Thú y Minh Phát',
            ),
          ),
        ),
      ),
    ],
  );
  return MaterialApp.router(
    theme: VTheme.lightTheme,
    routerConfig: router,
  );
}

final class _HandlerInventoryModule implements IInventoryModule {
  _HandlerInventoryModule(this.port)
    : _ensure = EnsureDefaultStoreWarehousePairCommandHandler(
        executionContext: FakeExecutionContext(tenantId: 'tenant-test'),
        defaultStoreWarehousePairPort: port,
      ),
      _get = GetDefaultStoreWarehousePairQueryHandler(
        permissionChecker: FakePermissionChecker(),
        executionContext: FakeExecutionContext(tenantId: 'tenant-test'),
        defaultStoreWarehousePairPort: port,
      );

  final FakeDefaultStoreWarehousePairPort port;
  final EnsureDefaultStoreWarehousePairCommandHandler _ensure;
  final GetDefaultStoreWarehousePairQueryHandler _get;
  int ensureCount = 0;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    ensureCount += 1;
    final result = await _ensure.handle(
      command as EnsureDefaultStoreWarehousePairCommand,
    );
    return result as TResult;
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    final result = await _get.handle(query as GetDefaultStoreWarehousePairQuery);
    return result as TResult;
  }
}

final class _PausingInventoryModule implements IInventoryModule {
  _PausingInventoryModule(this._inner, {required this.pause});

  final IInventoryModule _inner;
  final Future<void> Function() pause;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    await pause();
    return _inner.executeCommandAsync(command);
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    await pause();
    return _inner.executeQueryAsync(query);
  }
}
