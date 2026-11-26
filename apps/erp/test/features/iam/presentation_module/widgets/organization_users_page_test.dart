import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/iam/data/models/cursor_page.dart';
import 'package:erp/features/iam/data/models/tenant_member.dart';
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
    expect(tester.widget<VButton>(inviteButton).label, 'Mời thành viên');

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
    expect(memberTabNode.flagsCollection.isSelected, Tristate.isTrue);

    // Tap "Hoạt động" chip
    await tester.tap(find.widgetWithText(VChip, 'Hoạt động'));
    await tester.pumpAndSettle();

    final activeChipNode = tester.getSemantics(find.widgetWithText(VChip, 'Hoạt động'));
    expect(activeChipNode.flagsCollection.isSelected, Tristate.isTrue);

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

  testWidgets('search text is kept per tab', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
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

    await tester.enterText(find.byType(TextField), 'Lan');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lời mời'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, isEmpty);

    await tester.enterText(find.byType(TextField), 'invitee');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thành viên'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, 'Lan');

    await cubit.close();
  });

  testWidgets('suspending in detail refreshes the list badge', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamBackend(scenario: FakeIamScenario.memberDeactivateOk);
    final membersRepo = FakeMemberRepository(module);
    final invitationsRepo = FakeInvitationRepository(module);
    final cubit = OrganizationUsersCubit(
      members: membersRepo,
      invitations: invitationsRepo,
      searchDebounce: Duration.zero,
    );
    await cubit.loadInitial();

    final router = GoRouter(
      initialLocation: '/more/users',
      routes: [
        GoRoute(
          path: '/more/users',
          builder: (_, _) => OrganizationUsersPage(cubit: cubit),
        ),
        GoRoute(
          path: '/more/users/members/:id',
          builder: (_, state) => OrganizationMemberDetailPage(
            membershipId: state.pathParameters['id']!,
            members: membersRepo,
            onMutated: () => cubit.loadMembers(reset: true),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: VTheme.lightTheme,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hoa Tran'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạm ngừng thành viên'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(VButton, 'Tạm ngừng'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();

    // Hoa Tran was active; now both Hoa Tran and Minh Nguyen are Tạm ngừng.
    expect(find.text('Tạm ngừng'), findsAtLeastNWidgets(2));
    await cubit.close();
  });

  testWidgets('1280: table with four headers and last activity', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final scripted = FakeIamBackend(
      onListMembers: (_) async => CursorPage<TenantMember>(
        items: [
          TenantMember(
            membershipId: 'm1',
            userId: 'u1',
            displayName: 'Nguyễn Văn An',
            email: 'an@example.com',
            roleId: 'store_owner',
            roleLabel: 'Chủ cửa hàng',
            isOwner: true,
            status: 'active',
            joinedAt: DateTime.utc(2026, 1, 1),
            lastActivityAt: DateTime.utc(2026, 11, 21, 10, 5),
            version: 1,
          ),
          TenantMember(
            membershipId: 'm2',
            userId: 'u2',
            displayName: 'Trần Thị Bình',
            email: 'binh@example.com',
            roleId: 'staff',
            roleLabel: 'Nhân viên bán hàng',
            isOwner: false,
            status: 'inactive',
            joinedAt: DateTime.utc(2026, 1, 2),
            lastActivityAt: DateTime.utc(2026, 11, 20, 9, 0),
            version: 1,
          ),
        ],
      ),
    );
    final cubit = OrganizationUsersCubit(
      members: FakeMemberRepository(scripted),
      invitations: FakeInvitationRepository(scripted),
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

    expect(find.text('Tên'), findsOneWidget);
    expect(find.text('Vai trò hiện hành'), findsOneWidget);
    expect(find.text('Trạng thái truy cập'), findsOneWidget);
    expect(find.text('Hoạt động gần nhất'), findsOneWidget);
    expect(find.text('21/11/2026 · 17:05'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('1280: invite button in the app bar, no bottom bar', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
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
        home: OrganizationUsersPage(cubit: cubit, canInvite: true),
      ),
    );
    await cubit.loadInitial();
    await tester.pumpAndSettle();

    final inviteButton = find.byKey(const Key('users_invite'));
    expect(inviteButton, findsOneWidget);
    expect(
      find.descendant(of: find.byType(VAppBar), matching: inviteButton),
      findsOneWidget,
    );
    await cubit.close();
  });

  testWidgets('390: invite in the bottom bar, hidden on failure and on empty', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
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
        home: OrganizationUsersPage(cubit: cubit, canInvite: true),
      ),
    );
    await cubit.loadInitial();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('users_invite')), findsOneWidget);
    expect(
      find.descendant(of: find.byType(VAppBar), matching: find.byKey(const Key('users_invite'))),
      findsNothing,
    );

    final emptyBackend = FakeIamBackend(
      onListMembers: (_) async => const CursorPage<TenantMember>(items: []),
    );
    final emptyCubit = OrganizationUsersCubit(
      members: FakeMemberRepository(emptyBackend),
      invitations: FakeInvitationRepository(emptyBackend),
      searchDebounce: Duration.zero,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationUsersPage(cubit: emptyCubit, canInvite: true),
      ),
    );
    await emptyCubit.loadInitial();
    await tester.pumpAndSettle();

    // Empty state has its own button; bottom bar is hidden so only 1 button exists.
    expect(find.widgetWithText(VButton, 'Mời thành viên'), findsOneWidget);

    await cubit.close();
    await emptyCubit.close();
  });

  testWidgets('1280: tapping a row goes to the member url and back returns', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamBackend(scenario: FakeIamScenario.membersSearchOk);
    final membersRepo = FakeMemberRepository(module);
    final cubit = OrganizationUsersCubit(
      members: membersRepo,
      invitations: FakeInvitationRepository(module),
      searchDebounce: Duration.zero,
    );
    await cubit.loadInitial();

    final router = GoRouter(
      initialLocation: '/more/users',
      routes: [
        GoRoute(
          path: '/more/users',
          builder: (_, _) => OrganizationUsersPage(cubit: cubit),
          routes: [
            GoRoute(
              path: 'members/:id',
              builder: (_, state) => OrganizationMemberDetailPage(
                membershipId: state.pathParameters['id']!,
                members: membersRepo,
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: VTheme.lightTheme,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lan Le'));
    await tester.pumpAndSettle();

    expect(find.text('Chi tiết thành viên'), findsOneWidget);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();

    expect(find.text('Người dùng'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('role filter with no match shows Không tìm thấy kết quả', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
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

    await cubit.applyMemberCriteria(role: 'Thủ kho');
    await tester.pumpAndSettle();

    expect(find.text('Không tìm thấy kết quả'), findsOneWidget);
    expect(find.text('Chưa có thành viên khác'), findsNothing);
    await cubit.close();
  });

  testWidgets('load more failure shows a toast and keeps rows', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var call = 0;
    final scripted = FakeIamBackend(
      onListMembers: (_) async {
        call += 1;
        if (call == 1) {
          return CursorPage<TenantMember>(
            items: [
              TenantMember(
                membershipId: 'm1',
                userId: 'u1',
                displayName: 'Nguyễn Văn An',
                email: 'an@example.com',
                roleId: 'staff',
                roleLabel: 'Nhân viên bán hàng',
                isOwner: false,
                status: 'active',
                joinedAt: DateTime.utc(2026, 1, 1),
                version: 1,
              ),
            ],
            nextCursor: 'c2',
          );
        }
        throw Exception('network down');
      },
    );
    final cubit = OrganizationUsersCubit(
      members: FakeMemberRepository(scripted),
      invitations: FakeInvitationRepository(scripted),
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

    await cubit.loadNextMembersPage();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(find.textContaining('Không tải thêm được'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('invitations empty text follows TH-01', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final emptyBackend = FakeIamBackend(
      onListInvitations: (_) async => const CursorPage(items: []),
    );
    final cubit = OrganizationUsersCubit(
      members: FakeMemberRepository(emptyBackend),
      invitations: FakeInvitationRepository(emptyBackend),
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

    await tester.tap(find.text('Lời mời'));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có lời mời nào'), findsOneWidget);
    expect(
      find.text('Tạo lời mời mới để thêm người dùng vào tổ chức.'),
      findsOneWidget,
    );
    await cubit.close();
  });

  testWidgets('320 at text scale 2.0 does not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 844);
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
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 844),
          textScaler: TextScaler.linear(2.0),
        ),
        child: MaterialApp(
          theme: VTheme.lightTheme,
          home: OrganizationUsersPage(cubit: cubit),
        ),
      ),
    );
    await cubit.loadInitial();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await cubit.close();
  });
}
