import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_iam_presentation/presentation.dart';
import 'package:vet45_iam_presentation/testing.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

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
          iamModule: FakeIamModule(scenario: scenario),
          executionContext: FakeExecutionContext(tenantId: 'org-001'),
          cubit: cubit,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('wgt_e03_u05_fr01_01: loads member by id and shows lifecycle actions without role change',
      (tester) async {
    await pumpPage(
      tester,
      scenario: FakeIamScenario.memberDeactivateOk,
    );

    expect(find.text('Chi tiết thành viên'), findsOneWidget);
    expect(find.text('hoa-tran'), findsWidgets);
    expect(find.text('Thao tác'), findsOneWidget);

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();

    expect(find.text('Thao tác thành viên'), findsOneWidget);
    expect(find.text('Tạm ngừng thành viên'), findsOneWidget);
    expect(find.text('Loại khỏi tổ chức'), findsOneWidget);
    expect(find.text('Thay đổi vai trò'), findsNothing);
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
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.memberDeactivateOk),
    );
    final cubit = OrganizationMemberDetailCubit(
      membershipId: 'mem-staff-1',
      iamModule: module,
      executionContext: FakeExecutionContext(tenantId: 'org-001'),
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
}
