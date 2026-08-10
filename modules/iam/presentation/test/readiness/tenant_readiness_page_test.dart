import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_iam_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  testWidgets('wgt_e01_u04_fr01_01: shows blockers and disables activate', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: TenantReadinessPage(
          iamModule: FakeIamModule(scenario: FakeIamScenario.readinessBlocked),
          executionContext: FakeExecutionContext(tenantId: 'org-001'),
          canActivateTenant: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Điều kiện bắt buộc'), findsOneWidget);
    expect(find.byKey(const Key('btn_activate_tenant')), findsNothing);
    expect(find.byKey(const Key('btn_complete_tenant_setup')), findsOneWidget);
    expect(find.text('Thiếu thông tin'), findsOneWidget);
    expect(find.text('Lê Thị Lan'), findsNothing);
    expect(find.text('Chủ cửa hàng'), findsNothing);
  });

  testWidgets('wgt_e01_u05_fr01_01: warning-only shows activate CTA', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: TenantReadinessPage(
          iamModule: FakeIamModule(scenario: FakeIamScenario.readinessWarningOnly),
          executionContext: FakeExecutionContext(tenantId: 'org-002'),
          canActivateTenant: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sẵn sàng kích hoạt'), findsOneWidget);
    expect(find.text('Một số tính năng pháp lý chưa khả dụng'), findsOneWidget);
    expect(find.text('Đã xác thực'), findsOneWidget);
    expect(find.text('Đã phân quyền'), findsOneWidget);
    expect(find.text('Lê Thị Lan'), findsNothing);
    expect(find.text('Chủ cửa hàng'), findsNothing);
    expect(find.byKey(const Key('btn_activate_tenant')), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_activate_tenant')));
    await tester.pumpAndSettle();
    expect(find.text('Kích hoạt tổ chức?'), findsOneWidget);
    expect(
      find.text(
        'Sau khi kích hoạt, thành viên có thể sử dụng các nghiệp vụ theo vai trò và quyền hiện hành.',
      ),
      findsOneWidget,
    );
    expect(find.text('Lý do'), findsOneWidget);
    expect(find.text('Nhập lý do'), findsOneWidget);
    expect(find.text('Lý do được lưu trong lịch sử quản trị.'), findsOneWidget);
    expect(find.widgetWithText(VButton, 'Để sau'), findsOneWidget);
    expect(find.textContaining('Phiên bản hồ sơ'), findsNothing);
    expect(find.textContaining('Bắt buộc:'), findsNothing);
  });

  testWidgets('warning-only mandatory complete still shows activate CTA', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: TenantReadinessPage(
          iamModule: _WarningOnlyCanActivateFalseModule(),
          executionContext: FakeExecutionContext(tenantId: 'org-002'),
          canActivateTenant: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sẵn sàng kích hoạt'), findsOneWidget);
    expect(find.byKey(const Key('btn_activate_tenant')), findsOneWidget);
    expect(find.text('Kích hoạt tổ chức'), findsOneWidget);
    expect(find.text('Bổ sung thông tin tổ chức'), findsNothing);

    await tester.tap(find.byKey(const Key('btn_activate_tenant')));
    await tester.pumpAndSettle();
    expect(find.text('Kích hoạt tổ chức?'), findsOneWidget);
  });

  testWidgets('ready state without activate permission does not ask for profile repair', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: TenantReadinessPage(
          iamModule: FakeIamModule(scenario: FakeIamScenario.readinessWarningOnly),
          executionContext: FakeExecutionContext(tenantId: 'org-002'),
          canActivateTenant: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_activate_tenant')), findsNothing);
    expect(find.text('Bổ sung thông tin tổ chức'), findsNothing);
    expect(find.text('Không có quyền kích hoạt'), findsOneWidget);
  });

  testWidgets('owner blocker shows support hint without profile route', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: TenantReadinessPage(
          iamModule: _OwnerBlockerModule(),
          executionContext: FakeExecutionContext(tenantId: 'org-001'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Email chủ sở hữu'), findsOneWidget);
    expect(find.textContaining('Liên hệ quản trị viên'), findsOneWidget);
  });
}

final class _WarningOnlyCanActivateFalseModule implements IIamModule {
  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError(command.runtimeType.toString());
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    if (query is GetTenantReadinessQuery) {
      return Future.value(
        TenantReadinessDto(
              tenantId: 'org-002',
              status: TenantLifecycleStatus.provisioning,
              blockers: const [],
              warnings: const [TenantReadinessIssueCodes.legalProfileMissing],
              evaluatedAt: DateTime.utc(2026, 8, 4),
              tenantVersion: 1,
              canActivate: false,
            )
            as TResult,
      );
    }
    throw UnsupportedError(query.runtimeType.toString());
  }
}

final class _OwnerBlockerModule implements IIamModule {
  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError(command.runtimeType.toString());
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    if (query is GetTenantReadinessQuery) {
      final readinessQuery = query as GetTenantReadinessQuery;
      return Future.value(
        TenantReadinessDto(
              tenantId: readinessQuery.tenantId,
              status: TenantLifecycleStatus.provisioning,
              blockers: const [TenantReadinessIssueCodes.ownerEmailUnverified],
              warnings: const [],
              evaluatedAt: DateTime.utc(2026, 7, 31),
              tenantVersion: 1,
              canActivate: false,
            )
            as TResult,
      );
    }
    throw UnsupportedError(query.runtimeType.toString());
  }
}
