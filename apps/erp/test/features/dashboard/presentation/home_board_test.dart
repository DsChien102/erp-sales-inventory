import 'dart:async';

import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/session/models/tenant_context.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/session/session_state.dart';
import 'package:erp/features/dashboard/data/models/home_summary.dart';
import 'package:erp/features/dashboard/presentation/home_tab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/session/fake_session_repository.dart';
import '../../iam/support/fake_iam_backend.dart';
import '../../inventory/support/inventory_test_surface.dart';
import '../support/fake_home_repository.dart';

const _phone = Size(390, 844);
const _web = Size(1280, 900);

const _ready = SessionState(
  status: TenantLoadStatus.ready,
  branchDisplayName: 'Thú y Minh Phát',
  current: TenantContext(
    status: TenantContextStatus.valid,
    tenantId: 'org-001',
    tenantName: 'Thú y Minh Phát',
    isOwner: true,
  ),
);

Future<SessionController> pumpHome(
  WidgetTester tester, {
  required Size size,
  required FakeHomeRepository repository,
  bool reduceMotion = false,
  bool settle = true,
  DateTime? now,
}) async {
  useInventoryTestSurface(size);
  final controller = SessionController(
    repository: FakeSessionRepository(scenario: FakeIamScenario.bootstrapValid),
    initialState: _ready,
  );
  addTearDown(controller.close);
  await tester.pumpWidget(
    MaterialApp(
      theme: VTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: BlocProvider<SessionController>.value(
        value: controller,
        child: HomeTabPage(repository: repository, now: () => now ?? DateTime(2026, 11, 23, 9)),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return controller;
}

void main() {
  testWidgets('390: order of boxes is Đơn → Công nợ → Tiền đã thu', (tester) async {
    await pumpHome(tester, size: _phone, repository: FakeHomeRepository());
    double dy(String t) => tester.getTopLeft(find.text(t, skipOffstage: false)).dy;
    expect(dy('ĐƠN HÔM NAY'), lessThan(dy('CÔNG NỢ PHẢI THU')));
    expect(dy('CÔNG NỢ PHẢI THU'), lessThan(dy('TIỀN ĐÃ THU HÔM NAY')));
  });

  testWidgets('1280: boxes in one row Đơn → Tiền đã thu → Công nợ', (tester) async {
    await pumpHome(tester, size: _web, repository: FakeHomeRepository());
    final a = tester.getTopLeft(find.text('ĐƠN HÔM NAY'));
    final b = tester.getTopLeft(find.text('TIỀN ĐÃ THU HÔM NAY'));
    final c = tester.getTopLeft(find.text('CÔNG NỢ PHẢI THU'));
    expect(a.dy, b.dy);
    expect(b.dy, c.dy);
    expect(a.dx, lessThan(b.dx));
    expect(b.dx, lessThan(c.dx));
  });

  testWidgets('shows real numbers from summary', (tester) async {
    await pumpHome(tester, size: _web, repository: FakeHomeRepository());
    expect(find.text('Chào buổi sáng · Thứ Hai · 23/11'), findsNothing);
    for (final t in [
      '8.420.000',
      '▲ 18%',
      'so với hôm qua',
      '52,7 triệu',
      '12',
      '▲ 3',
      'Tiền mặt 7',
      'Chuyển khoản 4',
      'Ghi nợ 1',
      'CHƯA XUẤT HOÁ ĐƠN',
      '2',
      '9.560.000',
      'Tiền mặt 4.150.000',
      'Chuyển khoản 5.410.000',
      '24.600.000',
      '3 khoản quá hạn',
      'NAY',
      '8,42',
    ]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
  });

  testWidgets('uninvoiced null hides "CHƯA XUẤT HOÁ ĐƠN"', (tester) async {
    await pumpHome(
      tester,
      size: _web,
      repository: FakeHomeRepository(summary: sampleHomeSummary(ordersUninvoiced: null)),
    );
    expect(find.text('ĐƠN HÔM NAY'), findsOneWidget);
    expect(find.text('CHƯA XUẤT HOÁ ĐƠN'), findsNothing);
  });

  testWidgets('yesterday 0 hides delta and "so với hôm qua"', (tester) async {
    await pumpHome(
      tester,
      size: _phone,
      repository: FakeHomeRepository(summary: sampleHomeSummary(revenueYesterday: 0)),
    );
    expect(find.text('8.420.000'), findsOneWidget);
    expect(find.text('so với hôm qua'), findsNothing);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('empty store renders zeros without delta', (tester) async {
    await pumpHome(
      tester,
      size: _phone,
      repository: FakeHomeRepository(summary: emptyHomeSummary()),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('0', skipOffstage: false), findsWidgets);
    expect(find.textContaining('▲', skipOffstage: false), findsNothing);
    expect(find.textContaining('▼', skipOffstage: false), findsNothing);
    expect(find.text('0 triệu'), findsOneWidget);
    expect(find.text('Không có khoản quá hạn', skipOffstage: false), findsOneWidget);
  });

  testWidgets('huge amounts do not overflow at 390', (tester) async {
    await pumpHome(
      tester,
      size: _phone,
      repository: FakeHomeRepository(
        summary: sampleHomeSummary(
          revenueToday: 1262567890,
          receivableTotal: 12345678900,
          cashInTotal: 12345678900,
          cashInCash: 6172839450,
          cashInBank: 6172839450,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('1.262.567.890'), findsOneWidget);
  });

  testWidgets('loading shows skeleton, no numbers', (tester) async {
    final repo = FakeHomeRepository(gate: Completer<HomeSummary>());
    await pumpHome(tester, size: _phone, repository: repo, settle: false);
    expect(find.byType(VSkeleton), findsWidgets);
    expect(find.text('8.420.000'), findsNothing);
    expect(find.text('Thú y Minh Phát'), findsOneWidget);
    repo.gate!.complete(sampleHomeSummary());
    await tester.pumpAndSettle();
    expect(find.byType(VSkeleton), findsNothing);
  });

  testWidgets('error shows "Thử lại" and retry reloads', (tester) async {
    final repo = FakeHomeRepository(error: const AppException('NETWORK_ERROR'));
    await pumpHome(tester, size: _phone, repository: repo);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('8.420.000'), findsNothing);
    repo.error = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(repo.calls, 2);
    expect(find.text('8.420.000'), findsOneWidget);
    expect(find.text('Thử lại'), findsNothing);
  });

  testWidgets('refresh error keeps numbers and shows toast', (tester) async {
    final repo = FakeHomeRepository();
    await pumpHome(tester, size: _phone, repository: repo);
    repo.error = const AppException('NETWORK_ERROR');
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(repo.calls, 2);
    expect(find.text('8.420.000'), findsOneWidget);
    expect(find.textContaining('Chưa tải lại được số liệu'), findsOneWidget);
  });

  testWidgets('home has no legal profile banner for owner', (tester) async {
    await pumpHome(tester, size: _phone, repository: FakeHomeRepository());
    expect(find.textContaining('hồ sơ pháp lý', skipOffstage: false), findsNothing);
    expect(find.text('Bổ sung', skipOffstage: false), findsNothing);
  });

  testWidgets('reduced motion: numbers visible on first frame', (tester) async {
    await pumpHome(
      tester,
      size: _phone,
      repository: FakeHomeRepository(),
      reduceMotion: true,
      settle: false,
    );
    await tester.pump();
    expect(find.text('8.420.000'), findsOneWidget);
    expect(
      find.ancestor(of: find.text('8.420.000'), matching: find.byType(Opacity)),
      findsNothing,
    );
  });

  testWidgets('numbers flip in when motion allowed', (tester) async {
    await pumpHome(tester, size: _phone, repository: FakeHomeRepository(), settle: false);
    await tester.pump();
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: find.text('8.420.000'), matching: find.byType(Opacity)).first,
    );
    expect(opacity.opacity, lessThan(1));
    await tester.pumpAndSettle();
  });

  testWidgets('tenant change reloads', (tester) async {
    final repo = FakeHomeRepository();
    final controller = await pumpHome(tester, size: _phone, repository: repo);
    expect(repo.calls, 1);
    repo.summary = sampleHomeSummary(revenueToday: 5000000);
    await controller.switchTo('org-002');
    await tester.pumpAndSettle();
    expect(controller.state.current?.tenantId, 'org-002');
    expect(repo.calls, 2);
    expect(find.text('5.000.000'), findsOneWidget);
  });

  testWidgets('R1-G5 date line follows server day of the numbers, greeting follows device hour', (
    tester,
  ) async {
    // Máy đã sang 24/11 lúc 0:30, số liệu vẫn của ngày 23/11 (sampleHomeSummary.today).
    await pumpHome(
      tester,
      size: _phone,
      repository: FakeHomeRepository(),
      now: DateTime(2026, 11, 24, 0, 30),
    );
    expect(find.text('Chào buổi tối · Thứ Hai · 23/11'), findsOneWidget);
  });
}
