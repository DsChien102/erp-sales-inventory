import 'dart:async';

import 'package:erp/core/session/models/tenant_context.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/session/session_state.dart';
import 'package:erp/features/dashboard/data/default_pair_repository.dart';
import 'package:erp/features/dashboard/presentation/erp_tab_scaffold.dart';
import 'package:erp/features/dashboard/presentation/home_tab_page.dart';
import 'package:erp/features/dashboard/presentation/store_shell.dart';
import 'package:erp/features/dashboard/presentation/widgets/erp_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

import '../../../core/session/fake_session_repository.dart';
import '../../iam/support/fake_iam_backend.dart';
import 'fake_default_pair_repository.dart';
import '../support/fake_home_repository.dart';

void main() {
  testWidgets('scn_dashboard_gate_success', (tester) async {
    await _setPhone(tester);
    final gate = Completer<void>();
    var opened = false;
    final repo = FakeDefaultPairRepository(
      mode: FakeDefaultPairMode.missingThenEnsure,
      pause: () async {
        if (opened) return;
        await gate.future;
        opened = true;
      },
    );

    await tester.pumpWidget(_app(repo));
    expect(find.byType(VLoading), findsOneWidget);
    expect(find.byKey(const Key('home_board')), findsNothing);
    expect(find.byType(ErpBottomNavigation), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_board')), findsOneWidget);
    expect(find.byType(ErpBottomNavigation), findsOneWidget);
    expect(repo.getCalls, 1);
    expect(repo.ensureCalls, 1);
  });

  testWidgets('scn_dashboard_gate_error', (tester) async {
    await _setPhone(tester);
    final gate = Completer<void>();
    var opened = false;
    final repo = FakeDefaultPairRepository(
      mode: FakeDefaultPairMode.ensureError,
      pause: () async {
        if (opened) return;
        await gate.future;
        opened = true;
      },
    );

    await tester.pumpWidget(_app(repo));
    expect(find.byKey(const Key('home_board')), findsNothing);
    expect(find.byType(ErpBottomNavigation), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Không thiết lập được kho mặc định'), findsOneWidget);
    expect(find.byKey(const Key('home_board')), findsNothing);
    expect(find.text('Không thể tải danh sách'), findsNothing);
    expect(repo.ensureCalls, 1);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('Không thiết lập được kho mặc định'), findsOneWidget);
    expect(find.byKey(const Key('home_board')), findsNothing);
    expect(repo.ensureCalls, 2);

    await tester.tap(find.text('Chọn tổ chức khác'));
    await tester.pumpAndSettle();

    expect(find.text('Chọn tổ chức'), findsOneWidget);
    expect(find.byKey(const Key('home_board')), findsNothing);
  });

  testWidgets('scn_dashboard_gate_reload_on_tenant_change', (tester) async {
    await _setPhone(tester);
    final repo = FakeDefaultPairRepository(mode: FakeDefaultPairMode.ready);

    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_board')), findsOneWidget);
    expect(repo.getCalls, 1);

    final ok = await tester
        .element(find.byType(HomeTabPage))
        .read<SessionController>()
        .switchTo('org-002');
    expect(ok, isTrue);

    await tester.pumpAndSettle();

    expect(repo.getCalls, 2);
    expect(find.byKey(const Key('home_board')), findsOneWidget);
  });

  // Sau đăng nhập: phiên đang nạp rồi đến cổng kho mặc định. Hai giai đoạn phải
  // dùng cùng một màn chờ toàn màn hình, không lồng loader trong khung tab.
  testWidgets('scn_dashboard_session_loading_uses_full_screen_hold', (tester) async {
    await _setPhone(tester);
    final repo = FakeDefaultPairRepository(mode: FakeDefaultPairMode.ready);

    await tester.pumpWidget(
      _app(repo, sessionState: const SessionState(status: TenantLoadStatus.loading)),
    );
    await tester.pump();

    expect(find.byType(VLoading), findsOneWidget);
    expect(find.byType(ErpBottomNavigation), findsNothing);
    expect(find.byKey(const Key('home_board')), findsNothing);
    expect(repo.getCalls, 0);
  });
}

Future<void> _setPhone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(DefaultPairRepository defaultPairRepository, {SessionState? sessionState}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => StoreShell(
          autoBootstrap: false,
          repository: FakeSessionRepository(scenario: FakeIamScenario.tenantsMulti),
          defaultPairRepository: defaultPairRepository,
          initialState: sessionState ??
              const SessionState(
                status: TenantLoadStatus.ready,
                userDisplayName: 'Lan',
                current: TenantContext(
                  status: TenantContextStatus.valid,
                  tenantId: 'tenant-test',
                  tenantName: 'Thú y Minh Phát',
                ),
              ),
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
                    name: 'dashboard',
                    builder: (context, state) => HomeTabPage(repository: FakeHomeRepository()),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  return MaterialApp.router(
    theme: VTheme.lightTheme,
    routerConfig: router,
  );
}
