import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import '../../support/fake_iam_backend.dart';
import '../../support/iam_test_session.dart';
import 'package:erp/features/iam/presentation.dart';
import '../../support/iam_fixtures.dart';

final class _FakeRoles implements InvitationRoleOptionsSource {
  @override
  Future<List<InvitationRoleOption>> load(String tenantId) async {
    return const [
      InvitationRoleOption(roleId: 'role-staff', label: 'Nhân viên bán hàng'),
      InvitationRoleOption(roleId: 'role-warehouse', label: 'Thủ kho'),
    ];
  }
}

void main() {
  testWidgets('wgt_e03_u02_fr01_01: invite form loads roles and submits without FakeRolesData', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamBackend(scenario: FakeIamScenario.inviteOk);
    final cubit = OrganizationInviteMemberCubit(
      session: testSessionController(),
      invitations: FakeInvitationRepository(module),
      roleOptionsSource: _FakeRoles(),
      keyFactory: FakeIdempotencyKeyFactory(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationInviteMemberPage(cubit: cubit),
      ),
    );
    await cubit.loadRoleOptions();
    await tester.pumpAndSettle();

    expect(find.text('Mời thành viên'), findsWidgets);
    expect(find.text('Nhân viên bán hàng'), findsWidgets);
    expect(find.text('FakeRolesData'), findsNothing);

    await tester.enterText(find.byType(TextField), 'staff@example.com');
    await tester.pump();
    await tester.tap(find.text('Gửi lời mời'));
    await tester.pumpAndSettle();

    expect(module.commandsOf<CreateInvitationCommand>(), hasLength(1));
    expect(
      module.commandsOf<CreateInvitationCommand>().single.initialRoleId,
      'role-staff',
    );
    expect(find.text('Đã gửi lời mời thành công.'), findsOneWidget);

    await cubit.close();
  });

  testWidgets('empty email submits and shows inline validation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = OrganizationInviteMemberCubit(
      session: testSessionController(),
      invitations: FakeInvitationRepository(FakeIamBackend(scenario: FakeIamScenario.inviteOk)),
      roleOptionsSource: _FakeRoles(),
      keyFactory: FakeIdempotencyKeyFactory(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationInviteMemberPage(cubit: cubit),
      ),
    );
    await cubit.loadRoleOptions();
    await tester.pumpAndSettle();

    final send = tester.widget<VButton>(
      find.widgetWithText(VButton, 'Gửi lời mời'),
    );
    expect(send.onPressed, isNotNull);
    await tester.tap(find.widgetWithText(VButton, 'Gửi lời mời'));
    await tester.pump();
    expect(find.text('Vui lòng nhập email và chọn vai trò.'), findsOneWidget);

    await cubit.close();
  });

  testWidgets('invalid email shows inline error under email field without toast', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = OrganizationInviteMemberCubit(
      session: testSessionController(),
      invitations: FakeInvitationRepository(FakeIamBackend(scenario: FakeIamScenario.inviteOk)),
      roleOptionsSource: _FakeRoles(),
      keyFactory: FakeIdempotencyKeyFactory(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationInviteMemberPage(cubit: cubit),
      ),
    );
    await cubit.loadRoleOptions();
    await tester.pumpAndSettle();

    // Verify helper text exists
    expect(
      find.textContaining('Người nhận phải đăng nhập đúng email.'),
      findsOneWidget,
    );

    // Enter invalid email 'abc'
    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump();
    await tester.tap(find.widgetWithText(VButton, 'Gửi lời mời'));
    await tester.pumpAndSettle();

    expect(find.text('Email không hợp lệ'), findsOneWidget);
    expect(find.byType(VToast), findsNothing);

    await cubit.close();
  });

  testWidgets('backend DUPLICATE_MEMBERSHIP shows inline error without toast', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = OrganizationInviteMemberCubit(
      session: testSessionController(),
      invitations: FakeInvitationRepository(FakeIamBackend(
        scenario: FakeIamScenario.inviteDuplicateMembership,
      )),
      roleOptionsSource: _FakeRoles(),
      keyFactory: FakeIdempotencyKeyFactory(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationInviteMemberPage(cubit: cubit),
      ),
    );
    await cubit.loadRoleOptions();
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'existing@example.com');
    await tester.pump();
    await tester.tap(find.widgetWithText(VButton, 'Gửi lời mời'));
    await tester.pumpAndSettle();

    expect(find.text('Thành viên đã tồn tại trong tổ chức.'), findsOneWidget);
    expect(find.byType(VToast), findsNothing);

    await cubit.close();
  });
}
