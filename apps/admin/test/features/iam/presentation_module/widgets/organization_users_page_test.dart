import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:admin/features/iam/presentation.dart';
import 'package:admin/features/iam/presentation/users/widgets/member_filter_bottom_sheet.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  testWidgets('wgt_e03_u01_fr01_01: OrganizationUsersPage loads real members (no FakeUsersData)', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamModule(scenario: FakeIamScenario.membersSearchOk);
    final cubit = OrganizationUsersCubit(
      iamModule: module,
      executionContext: FakeExecutionContext(tenantId: 'org-001'),
      searchDebounce: Duration.zero,
      clock: () => DateTime.utc(2026, 7, 31),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationUsersPage(cubit: cubit),
      ),
    );
    await cubit.loadMembers(reset: true);
    await tester.pumpAndSettle();

    expect(find.text('Người dùng'), findsWidgets);
    expect(find.textContaining('thành viên'), findsWidgets);
    expect(find.text('Lan Le'), findsOneWidget);
    expect(find.text('Nguyễn Văn Minh'), findsNothing);
    expect(find.text('Lời mời'), findsNothing);
    expect(find.text('Mời thành viên'), findsNothing);

    await cubit.close();
  });

  testWidgets('Admin OrganizationUsersPage has no invitation tab or invite CTA', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamModule(scenario: FakeIamScenario.invitationsSearchOk);
    final cubit = OrganizationUsersCubit(
      iamModule: module,
      executionContext: FakeExecutionContext(tenantId: 'org-001'),
      searchDebounce: Duration.zero,
      clock: () => DateTime.utc(2026, 7, 31),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationUsersPage(cubit: cubit),
      ),
    );
    await cubit.loadMembers(reset: true);
    await tester.pumpAndSettle();

    expect(find.text('Lời mời'), findsNothing);
    expect(find.text('Mời thành viên'), findsNothing);
    expect(find.text('invitee@example.com'), findsNothing);
    expect(find.byIcon(Icons.add), findsNothing);

    await cubit.close();
  });

  testWidgets('member filter chip triggers server status query', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamModule(scenario: FakeIamScenario.membersSearchOk);
    final cubit = OrganizationUsersCubit(
      iamModule: module,
      executionContext: FakeExecutionContext(tenantId: 'org-001'),
      searchDebounce: Duration.zero,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationUsersPage(cubit: cubit),
      ),
    );
    await cubit.loadMembers(reset: true);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tạm ngừng').first);
    await tester.pumpAndSettle();

    expect(find.text('Minh Nguyen'), findsOneWidget);
    expect(find.text('Lan Le'), findsNothing);

    await cubit.close();
  });

  testWidgets('forbidden shows permission empty state', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = OrganizationUsersCubit(
      iamModule: FakeIamModule(
        scenario: FakeIamScenario.memberInvitationForbidden,
      ),
      executionContext: FakeExecutionContext(tenantId: 'org-001'),
      searchDebounce: Duration.zero,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationUsersPage(cubit: cubit),
      ),
    );
    await cubit.loadMembers(reset: true);
    await tester.pumpAndSettle();

    await cubit.close();
  });

  testWidgets('tapping filter button opens MemberFilterBottomSheet and applies filter', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamModule(scenario: FakeIamScenario.membersSearchOk);
    final cubit = OrganizationUsersCubit(
      iamModule: module,
      executionContext: FakeExecutionContext(tenantId: 'org-001'),
      searchDebounce: Duration.zero,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationUsersPage(cubit: cubit),
      ),
    );
    await cubit.loadMembers(reset: true);
    await tester.pumpAndSettle();

    final filterButton = find.byWidgetPredicate(
      (w) => w is VIcon && w.icon == VIcons.tune,
    );
    expect(filterButton, findsOneWidget);
    await tester.tap(filterButton);
    await tester.pumpAndSettle();

    expect(find.byType(MemberFilterBottomSheet), findsOneWidget);
    expect(find.text('Bộ lọc thành viên'), findsOneWidget);
    expect(find.text('Trạng thái'), findsOneWidget);
    expect(find.text('Vai trò'), findsOneWidget);
    expect(find.text('Sắp xếp'), findsOneWidget);

    await tester.tap(find.text('Tạm ngừng').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(VButton, 'Áp dụng'));
    await tester.pumpAndSettle();

    expect(find.byType(MemberFilterBottomSheet), findsNothing);
    expect(find.text('Minh Nguyen'), findsOneWidget);
    expect(find.text('Lan Le'), findsNothing);

    await cubit.close();
  });
}
