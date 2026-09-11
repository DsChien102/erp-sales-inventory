import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:admin/features/iam/presentation.dart';
import 'package:admin/features/iam/testing.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

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

    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.inviteOk),
    );
    final cubit = OrganizationInviteMemberCubit(
      iamModule: module,
      executionContext: FakeExecutionContext(tenantId: 'org-001'),
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

  testWidgets('empty email disables submit path with validation toast', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = OrganizationInviteMemberCubit(
      iamModule: FakeIamModule(scenario: FakeIamScenario.inviteOk),
      executionContext: FakeExecutionContext(tenantId: 'org-001'),
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
    expect(send.onPressed, isNull);

    await cubit.close();
  });
}
