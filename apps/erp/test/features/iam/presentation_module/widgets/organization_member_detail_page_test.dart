import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/iam/data/models/tenant_member.dart';
import '../../support/fake_iam_backend.dart';
import 'package:erp/features/iam/presentation.dart';
import '../../support/iam_fixtures.dart';

void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    required FakeIamScenario scenario,
    String membershipId = 'mem-staff-1',
    OrganizationMemberDetailCubit? cubit,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationMemberDetailPage(
          membershipId: membershipId,
          members: FakeMemberRepository(FakeIamBackend(scenario: scenario)),
          cubit: cubit,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('wgt_e03_u05_fr01_01: loads member by id and shows lifecycle actions including role change',
      (tester) async {
    await pumpPage(
      tester,
      scenario: FakeIamScenario.memberDeactivateOk,
    );

    expect(find.text('Chi tiết thành viên'), findsOneWidget);
    expect(find.text('Hoa Tran'), findsWidgets);
    expect(find.text('Thao tác'), findsOneWidget);

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();

    expect(find.text('Thao tác thành viên'), findsOneWidget);
    expect(find.text('Thay đổi vai trò'), findsOneWidget);
    expect(find.text('Tạm ngừng thành viên'), findsOneWidget);
    expect(find.text('Loại khỏi tổ chức'), findsOneWidget);
  });

  testWidgets('tapping Thay đổi vai trò opens select role page', (tester) async {
    await pumpPage(
      tester,
      scenario: FakeIamScenario.memberDeactivateOk,
    );

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thay đổi vai trò'));
    await tester.pumpAndSettle();

    expect(find.text('Chọn vai trò mới'), findsOneWidget);
  });

  testWidgets('removed member is read-only without action buttons', (tester) async {
    await pumpPage(
      tester,
      scenario: FakeIamScenario.memberDetailOk,
      membershipId: 'mem-removed-1',
    );

    expect(find.text('Đã loại'), findsOneWidget);
    expect(find.text('Thao tác'), findsNothing);
    expect(find.text('Tạm ngừng thành viên'), findsNothing);
    expect(find.text('Kích hoạt lại'), findsNothing);
    expect(find.text('Loại khỏi tổ chức'), findsNothing);
  });

  testWidgets('wgt_e03_u06_fr01_01: sole owner has no destructive CTAs', (tester) async {
    await pumpPage(
      tester,
      scenario: FakeIamScenario.memberDetailOk,
      membershipId: 'mem-owner-1',
    );

    expect(find.text('Thao tác'), findsNothing);
  });

  testWidgets('deactivate confirmation mutates to inactive', (tester) async {
    final module = FakeIamBackend(scenario: FakeIamScenario.memberDeactivateOk);
    final cubit = OrganizationMemberDetailCubit(
      membershipId: 'mem-staff-1',
      members: FakeMemberRepository(module),
    );
    await cubit.load();

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationMemberDetailPage(
          membershipId: 'mem-staff-1',
          cubit: cubit,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạm ngừng thành viên'));
    await tester.pumpAndSettle();
    expect(find.text('Tạm ngừng thành viên?'), findsOneWidget);

    await tester.tap(find.widgetWithText(VButton, 'Tạm ngừng'));
    await tester.pumpAndSettle();

    expect(module.commandsOf<DeactivateMembershipCommand>(), hasLength(1));
    expect(cubit.state.member?.status, MembershipStatus.inactive);
    expect(find.text('Quyền truy cập đã tạm ngừng'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('selecting new role and tapping Tiếp tục changes role immediately', (tester) async {
    final module = FakeIamBackend(scenario: FakeIamScenario.memberDeactivateOk);
    final cubit = OrganizationMemberDetailCubit(
      membershipId: 'mem-staff-1',
      members: FakeMemberRepository(module),
    );
    await cubit.load();

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationMemberDetailPage(
          membershipId: 'mem-staff-1',
          cubit: cubit,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thay đổi vai trò'));
    await tester.pumpAndSettle();

    expect(find.text('Chọn vai trò mới'), findsOneWidget);

    // Tap on Kế toán option
    await tester.tap(find.text('Kế toán'));
    await tester.pumpAndSettle();

    // Tap on Tiếp tục
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();

    expect(module.commandsOf<AssignMemberRoleCommand>(), hasLength(1));
    expect(module.commandsOf<AssignMemberRoleCommand>().first.role, 'accountant');
    expect(find.text('Đã thay đổi vai trò thành công.'), findsOneWidget);
    await cubit.close();
  });
}
