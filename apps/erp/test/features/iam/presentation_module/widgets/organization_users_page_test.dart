import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import '../../support/fake_iam_backend.dart';
import 'package:erp/features/iam/presentation.dart';

void main() {
  testWidgets('wgt_e03_u01_fr01_01: OrganizationUsersPage loads real members (no FakeUsersData)', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamBackend(scenario: FakeIamScenario.membersSearchOk);
    final cubit = OrganizationUsersCubit(
      members: FakeMemberRepository(module),
      invitations: FakeInvitationRepository(module),
      searchDebounce: Duration.zero,
      clock: () => DateTime.utc(2026, 7, 31),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationUsersPage(cubit: cubit),
      ),
    );
    await cubit.loadInitial();
    await tester.pumpAndSettle();

    expect(find.text('Người dùng'), findsWidgets);
    expect(find.textContaining('thành viên'), findsWidgets);
    expect(find.text('Lan Le'), findsOneWidget);
    expect(find.text('Nguyễn Văn Minh'), findsNothing);

    await cubit.close();
  });

  testWidgets('OrganizationUsersPage switches to invitation tab', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamBackend(scenario: FakeIamScenario.invitationsSearchOk);
    final cubit = OrganizationUsersCubit(
      members: FakeMemberRepository(module),
      invitations: FakeInvitationRepository(module),
      searchDebounce: Duration.zero,
      clock: () => DateTime.utc(2026, 7, 31),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationUsersPage(cubit: cubit),
      ),
    );
    await cubit.loadInitial();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lời mời'));
    await tester.pumpAndSettle();

    expect(find.text('invitee@example.com'), findsOneWidget);
    expect(find.text('Nguyễn Văn Minh'), findsNothing);

    await cubit.close();
  });

  testWidgets('member filter chip triggers server status query', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamBackend(scenario: FakeIamScenario.membersSearchOk);
    final cubit = OrganizationUsersCubit(
      members: FakeMemberRepository(module),
      invitations: FakeInvitationRepository(module),
      searchDebounce: Duration.zero,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationUsersPage(cubit: cubit),
      ),
    );
    await cubit.loadInitial();
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
      members: FakeMemberRepository(FakeIamBackend(
        scenario: FakeIamScenario.memberInvitationForbidden,
      )),
      invitations: FakeInvitationRepository(FakeIamBackend(
        scenario: FakeIamScenario.memberInvitationForbidden,
      )),
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

    final module = FakeIamBackend(scenario: FakeIamScenario.membersSearchOk);
    final cubit = OrganizationUsersCubit(
      members: FakeMemberRepository(module),
      invitations: FakeInvitationRepository(module),
      searchDebounce: Duration.zero,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationUsersPage(cubit: cubit),
      ),
    );
    await cubit.loadInitial();
    await tester.pumpAndSettle();

    // Tap filter button (IconButton containing tune icon)
    final filterButton = find.byWidgetPredicate(
      (w) => w is VIcon && w.icon == VIcons.tune,
    );
    expect(filterButton, findsOneWidget);
    await tester.tap(filterButton);
    await tester.pumpAndSettle();

    // Verify MemberFilterBottomSheet is opened
    expect(find.byType(MemberFilterBottomSheet), findsOneWidget);
    expect(find.text('Bộ lọc thành viên'), findsOneWidget);
    expect(find.text('Trạng thái'), findsOneWidget);
    expect(find.text('Vai trò'), findsOneWidget);
    expect(find.text('Sắp xếp'), findsOneWidget);

    // Tap "Tạm ngừng" chip inside bottom sheet and "Áp dụng"
    await tester.tap(find.text('Tạm ngừng').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(VButton, 'Áp dụng'));
    await tester.pumpAndSettle();

    // Bottom sheet is closed and filter is applied
    expect(find.byType(MemberFilterBottomSheet), findsNothing);
    expect(find.text('Minh Nguyen'), findsOneWidget);
    expect(find.text('Lan Le'), findsNothing);

    await cubit.close();
  });

  testWidgets(
    'OrganizationUsersPage opens InvitationFilterBottomSheet on invitation tab and applies filter',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = FakeIamBackend(scenario: FakeIamScenario.invitationsSearchOk);
      final cubit = OrganizationUsersCubit(
        members: FakeMemberRepository(module),
        invitations: FakeInvitationRepository(module),
        searchDebounce: Duration.zero,
        clock: () => DateTime.utc(2026, 7, 31),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OrganizationUsersPage(cubit: cubit),
        ),
      );
      await cubit.loadInitial();
      await tester.pumpAndSettle();

      // Switch to invitation tab
      await tester.tap(find.text('Lời mời'));
      await tester.pumpAndSettle();

      // Tap filter button (IconButton containing tune icon)
      final filterButton = find.byWidgetPredicate(
        (w) => w is VIcon && w.icon == VIcons.tune,
      );
      expect(filterButton, findsOneWidget);
      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      // Verify InvitationFilterBottomSheet is opened
      expect(find.byType(InvitationFilterBottomSheet), findsOneWidget);
      expect(find.text('Bộ lọc lời mời'), findsOneWidget);
      expect(find.text('Trạng thái'), findsOneWidget);
      expect(find.text('Kết quả gửi'), findsOneWidget);
      expect(find.text('Thời gian'), findsOneWidget);

      // Tap "Hết hạn" chip inside bottom sheet and "Áp dụng"
      await tester.tap(find.text('Hết hạn').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(VButton, 'Áp dụng'));
      await tester.pumpAndSettle();

      // Bottom sheet is closed and filter is applied
      expect(find.byType(InvitationFilterBottomSheet), findsNothing);
      expect(cubit.state.invitationFilter, equals('expired'));

      await cubit.close();
    },
  );

  testWidgets(
    'OrganizationUsersPage applies sendResult and timeRange filters from InvitationFilterBottomSheet',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = FakeIamBackend(scenario: FakeIamScenario.invitationsSearchOk);
      final cubit = OrganizationUsersCubit(
        members: FakeMemberRepository(module),
        invitations: FakeInvitationRepository(module),
        searchDebounce: Duration.zero,
        clock: () => DateTime.utc(2026, 7, 31),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OrganizationUsersPage(cubit: cubit),
        ),
      );
      await cubit.loadInitial();
      await tester.pumpAndSettle();

      // Switch to invitation tab
      await tester.tap(find.text('Lời mời'));
      await tester.pumpAndSettle();

      // Tap filter button
      final filterButton = find.byWidgetPredicate(
        (w) => w is VIcon && w.icon == VIcons.tune,
      );
      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      // Tap "Đã gửi" and "7 ngày"
      await tester.tap(find.text('Đã gửi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('7 ngày'));
      await tester.pumpAndSettle();

      // Tap "Áp dụng"
      await tester.tap(find.widgetWithText(VButton, 'Áp dụng'));
      await tester.pumpAndSettle();

      expect(cubit.state.invitationSendResultFilter, equals('Đã gửi'));
      expect(cubit.state.invitationTimeRangeFilter, equals('7 ngày'));

      await cubit.close();
    },
  );

  testWidgets('invite button presence depends on canInvite', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamBackend(scenario: FakeIamScenario.membersSearchOk);
    final cubit = OrganizationUsersCubit(
      members: FakeMemberRepository(module),
      invitations: FakeInvitationRepository(module),
      searchDebounce: Duration.zero,
    );

    // canInvite: true
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationUsersPage(cubit: cubit, canInvite: true),
      ),
    );
    await cubit.loadInitial();
    await tester.pumpAndSettle();

    final inviteButton = find.byKey(const Key('users_invite'));
    expect(inviteButton, findsOneWidget);
    expect(tester.widget<IconButton>(inviteButton).tooltip, 'Mời thành viên');

    // Switch to invitations tab
    await tester.tap(find.text('Lời mời'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('users_invite')), findsOneWidget);
    await cubit.close();

    // canInvite: false
    final cubit2 = OrganizationUsersCubit(
      members: FakeMemberRepository(module),
      invitations: FakeInvitationRepository(module),
      searchDebounce: Duration.zero,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationUsersPage(cubit: cubit2, canInvite: false),
      ),
    );
    await cubit2.loadInitial();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('users_invite')), findsNothing);
    expect(find.widgetWithText(VButton, 'Mời thành viên'), findsNothing);
    await cubit2.close();
  });

  testWidgets('tab and chip semantics show isSelected', (tester) async {
    final handle = tester.ensureSemantics();
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamBackend(scenario: FakeIamScenario.membersSearchOk);
    final cubit = OrganizationUsersCubit(
      members: FakeMemberRepository(module),
      invitations: FakeInvitationRepository(module),
      searchDebounce: Duration.zero,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationUsersPage(cubit: cubit),
      ),
    );
    await cubit.loadInitial();
    await tester.pumpAndSettle();

    // Tab "Thành viên" is selected by default
    final memberTabNode = tester.getSemantics(find.text('Thành viên'));
    expect(memberTabNode.hasFlag(SemanticsFlag.isSelected), isTrue);

    // Tap "Hoạt động" chip
    await tester.tap(find.widgetWithText(VChip, 'Hoạt động'));
    await tester.pumpAndSettle();

    final activeChipNode = tester.getSemantics(find.widgetWithText(VChip, 'Hoạt động'));
    expect(activeChipNode.hasFlag(SemanticsFlag.isSelected), isTrue);

    await cubit.close();
    handle.dispose();
  });

  testWidgets('filter button tooltip changes to (đang áp dụng) when filter is active', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamBackend(scenario: FakeIamScenario.membersSearchOk);
    final cubit = OrganizationUsersCubit(
      members: FakeMemberRepository(module),
      invitations: FakeInvitationRepository(module),
      searchDebounce: Duration.zero,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationUsersPage(cubit: cubit),
      ),
    );
    await cubit.loadInitial();
    await tester.pumpAndSettle();

    expect(find.byTooltip('Bộ lọc'), findsOneWidget);
    expect(find.byTooltip('Bộ lọc (đang áp dụng)'), findsNothing);

    // Tap "Hoạt động" chip to apply filter
    await tester.tap(find.widgetWithText(VChip, 'Hoạt động'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Bộ lọc'), findsNothing);
    expect(find.byTooltip('Bộ lọc (đang áp dụng)'), findsOneWidget);

    await cubit.close();
  });

  testWidgets('accessibility guidelines: tap target size and labeled tap target', (tester) async {
    final handle = tester.ensureSemantics();
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamBackend(scenario: FakeIamScenario.membersSearchOk);
    final cubit = OrganizationUsersCubit(
      members: FakeMemberRepository(module),
      invitations: FakeInvitationRepository(module),
      searchDebounce: Duration.zero,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationUsersPage(cubit: cubit),
      ),
    );
    await cubit.loadInitial();
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    await cubit.close();
    handle.dispose();
  });
}
