import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/session/models/tenant_context.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/session/session_state.dart';
import 'package:erp/features/dashboard/presentation/home_tab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/session/fake_session_repository.dart';
import '../../iam/support/fake_iam_backend.dart';

/// 10-8b T0: hành vi đầu Trang chủ (tên tổ chức, bấm đổi tổ chức) giữ khi thay màn.
void main() {
  Widget host(SessionState state, Widget page) {
    final controller = SessionController(
      repository: FakeSessionRepository(scenario: FakeIamScenario.tenantsMulti),
      initialState: state,
    );
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: BlocProvider<SessionController>.value(value: controller, child: page),
    );
  }

  Widget page() => const HomeTabPage();

  const ready = SessionState(
    status: TenantLoadStatus.ready,
    branchDisplayName: 'Thú y Minh Phát',
    current: TenantContext(
      status: TenantContextStatus.valid,
      tenantId: 'org-001',
      tenantName: 'Thú y Minh Phát',
      isOwner: true,
    ),
  );

  testWidgets('home shows "Đang tải…" while branch name is null', (tester) async {
    await tester.pumpWidget(host(const SessionState(status: TenantLoadStatus.loading), page()));
    await tester.pump();
    expect(find.text('Đang tải…'), findsOneWidget);
  });

  testWidgets('home shows "Chọn tổ chức" when blocked', (tester) async {
    await tester.pumpWidget(host(const SessionState(status: TenantLoadStatus.blocked), page()));
    await tester.pump();
    expect(find.text('Chọn tổ chức'), findsOneWidget);
  });

  testWidgets('tap branch name opens tenant selector', (tester) async {
    await tester.pumpWidget(host(ready, page()));
    await tester.pump();
    await tester.tap(find.text('Thú y Minh Phát'));
    await tester.pumpAndSettle();
    expect(find.text('Chọn tổ chức'), findsOneWidget);
  });
}
