// Golden 10-8h: Người dùng (ID-14…18) ở 390 và 1280, dữ liệu trùng prototype
// (`specs/themes/theme-01/03.design/prototype/html/app/admin-data.js`).
// Ảnh: docs/refactor/plans/P10/img/10-8h/flutter-<ca>-<rộng>.png
import 'dart:async';

import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/iam/iam_codes.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/iam/data/invitation_repository.dart';
import 'package:erp/features/iam/data/member_repository.dart';
import 'package:erp/features/iam/data/models/cursor_page.dart';
import 'package:erp/features/iam/data/models/tenant_invitation.dart';
import 'package:erp/features/iam/data/models/tenant_member.dart';
import 'package:erp/features/iam/logic/member_ui_mapper.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

import '../../receivable/presentation/receivable_test_harness.dart';
import '../support/iam_fixtures.dart';
import '../support/iam_test_session.dart';

/// Giờ chuẩn của ảnh: 23/11/2026 10:00 (VN).
final _now = DateTime.utc(2026, 11, 23, 3);

SupabaseRpc _unusedRpc() => SupabaseRpc(
  SupabaseClient(
    'http://127.0.0.1',
    'anon',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  ),
);

final _members = [
  TenantMember(
    membershipId: 'm1',
    userId: 'u1',
    displayName: 'Nguyễn Thị Lan',
    email: 'lan@anphat.vn',
    roleId: 'store_owner',
    roleLabel: 'Chủ cửa hàng',
    isOwner: true,
    status: 'active',
    joinedAt: DateTime.utc(2026, 9, 2, 2),
    lastActivityAt: DateTime.utc(2026, 11, 22, 1, 41),
    version: 1,
  ),
  TenantMember(
    membershipId: 'm2',
    userId: 'u2',
    displayName: 'Trần Văn Minh',
    email: 'minh@anphat.vn',
    roleId: 'staff',
    roleLabel: 'Nhân viên bán hàng',
    isOwner: false,
    status: 'active',
    joinedAt: DateTime.utc(2026, 10, 15, 2),
    lastActivityAt: DateTime.utc(2026, 11, 21, 10, 5),
    version: 1,
  ),
  TenantMember(
    membershipId: 'm3',
    userId: 'u3',
    displayName: 'Lê Thu Hà',
    email: 'ha@anphat.vn',
    roleId: 'accountant',
    roleLabel: 'Kế toán',
    isOwner: false,
    status: 'inactive',
    joinedAt: DateTime.utc(2026, 10, 20, 2),
    version: 2,
  ),
];

TenantMemberDetail _detail(String id) {
  if (id == 'm4') {
    return TenantMemberDetail(
      membershipId: 'm4',
      tenantId: 'org-001',
      userId: 'u4',
      displayName: 'Phạm Quốc Bảo',
      email: 'bao@anphat.vn',
      role: 'warehouse',
      roleLabel: 'Thủ kho',
      isOwner: false,
      isSoleOwner: false,
      status: MembershipStatus.removed,
      version: 3,
      joinedAt: DateTime.utc(2026, 10, 1, 2),
      statusChangedAt: DateTime.utc(2026, 11, 10, 7, 30),
      removedAt: DateTime.utc(2026, 11, 10, 7, 30),
    );
  }
  final m = _members.firstWhere((x) => x.membershipId == id);
  return TenantMemberDetail(
    membershipId: m.membershipId,
    tenantId: 'org-001',
    userId: m.userId,
    displayName: m.displayName,
    email: m.email,
    role: m.roleId,
    roleLabel: m.roleLabel,
    isOwner: m.isOwner,
    isSoleOwner: m.isOwner,
    status: switch (m.status) {
      'inactive' => MembershipStatus.inactive,
      _ => MembershipStatus.active,
    },
    version: m.version,
    joinedAt: m.joinedAt,
    lastActivityAt: m.lastActivityAt,
    statusChangedAt: m.status == 'inactive'
        ? DateTime.utc(2026, 11, 18, 2, 12)
        : null,
  );
}

TenantInvitationDetail _invitation(
  String id,
  String email,
  String roleId,
  String roleLabel,
  String status,
  DateTime expiresAt,
  String delivery,
) {
  return TenantInvitationDetail(
    invitationId: id,
    inviteeEmail: email,
    initialRoleId: roleId,
    initialRoleLabel: roleLabel,
    status: status,
    expiresAt: expiresAt,
    deliveryStatus: delivery,
    deliveryCorrelationId: 'corr-$id',
    version: 1,
    createdAt: _now.subtract(const Duration(days: 1)),
    createdBy: 'u1',
  );
}

final _invitations = [
  _invitation('i1', 'tuan@anphat.vn', 'staff', 'Nhân viên bán hàng', 'pending',
      _now.add(const Duration(days: 6, hours: 1)), 'sent'),
  _invitation('i2', 'nga.kt@gmail.com', 'accountant', 'Kế toán', 'pending',
      _now.add(const Duration(days: 1, hours: 1)), 'sent'),
  _invitation('i3', 'khoa@anphat.vn', 'warehouse', 'Thủ kho', 'pending',
      _now.add(const Duration(days: 5, hours: 1)), 'failed'),
  _invitation('i4', 'vy@anphat.vn', 'staff', 'Nhân viên bán hàng', 'expired',
      _now.subtract(const Duration(days: 1)), 'sent'),
];

TenantInvitation _summary(TenantInvitationDetail d) => TenantInvitation(
  invitationId: d.invitationId,
  inviteeEmail: d.inviteeEmail,
  initialRoleId: d.initialRoleId,
  initialRoleLabel: d.initialRoleLabel,
  status: d.status,
  expiresAt: d.expiresAt,
  deliveryStatus: d.deliveryStatus,
  deliveryCorrelationId: d.deliveryCorrelationId,
  version: d.version,
);

final class _GoldenMembers extends MemberRepository {
  _GoldenMembers({this.forbidden = false, this.pending})
    : super(rpc: _unusedRpc(), tenantId: () async => 'org-001');

  final bool forbidden;
  final Completer<void>? pending;

  @override
  Future<CursorPage<TenantMember>> listMembers({
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  }) async {
    if (pending != null) await pending!.future;
    if (forbidden) {
      throw const AppException(IamBlockedCodes.permissionDenied);
    }
    final q = VTextNormalizer.normalizeForSearch(search ?? '');
    final items = _members.where((m) {
      if (status != null && m.status != status) return false;
      if (q.isEmpty) return true;
      return VTextNormalizer.normalizeForSearch(
        '${m.displayName} ${m.email}',
      ).contains(q);
    }).toList();
    return CursorPage(items: items);
  }

  @override
  Future<TenantMemberDetail> getMember(String membershipId) async =>
      _detail(membershipId);
}

final class _GoldenInvitations extends InvitationRepository {
  _GoldenInvitations({this.empty = false})
    : super(rpc: _unusedRpc(), tenantId: () async => 'org-001');

  final bool empty;

  @override
  Future<CursorPage<TenantInvitation>> listInvitations({
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  }) async {
    if (empty) return const CursorPage(items: []);
    return CursorPage(
      items: _invitations
          .where((i) => status == null || i.status == status)
          .map(_summary)
          .toList(),
    );
  }

  @override
  Future<TenantInvitationDetail> getInvitation(String invitationId) async =>
      _invitations.firstWhere((i) => i.invitationId == invitationId);
}

final class _GoldenRoles implements InvitationRoleOptionsSource {
  @override
  Future<List<InvitationRoleOption>> load(String tenantId) async => const [
    InvitationRoleOption(roleId: 'staff', label: 'Nhân viên bán hàng'),
    InvitationRoleOption(roleId: 'accountant', label: 'Kế toán'),
    InvitationRoleOption(roleId: 'warehouse', label: 'Thủ kho'),
    InvitationRoleOption(roleId: 'store_owner', label: 'Chủ cửa hàng'),
  ];
}

Future<void> _capture(
  WidgetTester tester, {
  required int width,
  required String name,
  required Widget page,
  Future<void> Function()? act,
  bool settle = true,
}) async {
  final phone = width == 390;
  final view = tester.view;
  view.physicalSize = phone ? const Size(390, 844) : const Size(1280, 800);
  view.devicePixelRatio = 1;
  if (phone) {
    view.padding = const FakeViewPadding(top: 30, bottom: 34);
    view.viewPadding = const FakeViewPadding(top: 30, bottom: 34);
  }
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: VTheme.lightTheme,
      // Bọc cả Navigator để sheet / hộp thoại lọt vào ảnh.
      builder: (context, child) => RepaintBoundary(key: key, child: child),
      home: page,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 300));
  }
  if (act != null) {
    await act();
    await tester.pumpAndSettle();
  }
  await expectLater(
    find.byKey(key),
    matchesGoldenFile(
      '${repoRoot()}/docs/refactor/plans/P10/img/10-8h/flutter-$name-$width.png',
    ),
  );
}

OrganizationUsersCubit _usersCubit({
  MemberRepository? members,
  InvitationRepository? invitations,
}) => OrganizationUsersCubit(
  members: members ?? _GoldenMembers(),
  invitations: invitations ?? _GoldenInvitations(),
  clock: () => _now,
  searchDebounce: Duration.zero,
);

OrganizationInviteMemberCubit _inviteCubit() => OrganizationInviteMemberCubit(
  session: testSessionController(),
  invitations: _GoldenInvitations(),
  roleOptionsSource: _GoldenRoles(),
  keyFactory: FakeIdempotencyKeyFactory(),
)..loadRoleOptions();

MemberUiModel _uiMember(String id) => MemberUiMapper.fromDetail(_detail(id));

void main() {
  setUpAll(() async {
    await loadInterFont();
  });

  for (final width in const [390, 1280]) {
    // ── ID-14 ──
    testWidgets('users__members $width', (tester) async {
      final cubit = _usersCubit()..loadInitial();
      addTearDown(cubit.close);
      await _capture(
        tester,
        width: width,
        name: 'users__members',
        page: OrganizationUsersPage(cubit: cubit),
      );
    });

    testWidgets('users__invitations $width', (tester) async {
      final cubit = _usersCubit()..loadInitial();
      addTearDown(cubit.close);
      await _capture(
        tester,
        width: width,
        name: 'users__invitations',
        page: OrganizationUsersPage(cubit: cubit),
        act: () => tester.tap(find.text('Lời mời')),
      );
    });

    testWidgets('users__loading $width', (tester) async {
      final gate = Completer<void>();
      final cubit = _usersCubit(members: _GoldenMembers(pending: gate))
        ..loadInitial();
      addTearDown(() async {
        gate.complete();
        await cubit.close();
      });
      await _capture(
        tester,
        width: width,
        name: 'users__loading',
        page: OrganizationUsersPage(cubit: cubit),
        settle: false,
      );
    });

    testWidgets('users__invitations-empty $width', (tester) async {
      final cubit = _usersCubit(
        invitations: _GoldenInvitations(empty: true),
      )..loadInitial();
      addTearDown(cubit.close);
      await _capture(
        tester,
        width: width,
        name: 'users__invitations-empty',
        page: OrganizationUsersPage(cubit: cubit),
        act: () => tester.tap(find.text('Lời mời')),
      );
    });

    testWidgets('users__no-results $width', (tester) async {
      final cubit = _usersCubit()..loadInitial();
      addTearDown(cubit.close);
      await _capture(
        tester,
        width: width,
        name: 'users__no-results',
        page: OrganizationUsersPage(cubit: cubit),
        act: () => tester.enterText(find.byType(TextField).first, 'hoàng'),
      );
    });

    testWidgets('users__forbidden $width', (tester) async {
      final cubit = _usersCubit(members: _GoldenMembers(forbidden: true))
        ..loadInitial();
      addTearDown(cubit.close);
      await _capture(
        tester,
        width: width,
        name: 'users__forbidden',
        page: OrganizationUsersPage(cubit: cubit),
      );
    });

    testWidgets('users__filter-applied $width', (tester) async {
      final cubit = _usersCubit()..loadInitial();
      addTearDown(cubit.close);
      await _capture(
        tester,
        width: width,
        name: 'users__filter-applied',
        page: OrganizationUsersPage(cubit: cubit),
        act: () => cubit.applyMemberCriteria(role: 'Kế toán'),
      );
    });

    testWidgets('users__filter-invitations $width', (tester) async {
      final cubit = _usersCubit()..loadInitial();
      addTearDown(cubit.close);
      await _capture(
        tester,
        width: width,
        name: 'users__filter-invitations',
        page: OrganizationUsersPage(cubit: cubit),
        act: () async {
          await tester.tap(find.text('Lời mời'));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Bộ lọc'));
        },
      );
    });

    // ── ID-15 ──
    testWidgets('invite__empty $width', (tester) async {
      final cubit = _inviteCubit();
      addTearDown(cubit.close);
      await _capture(
        tester,
        width: width,
        name: 'invite__empty',
        page: OrganizationInviteMemberPage(cubit: cubit),
      );
    });

    testWidgets('invite__filled $width', (tester) async {
      final cubit = _inviteCubit();
      addTearDown(cubit.close);
      await _capture(
        tester,
        width: width,
        name: 'invite__filled',
        page: OrganizationInviteMemberPage(cubit: cubit),
        act: () async {
          await tester.enterText(find.byType(TextField).first, 'tuan@anphat.vn');
          await tester.tap(find.text('Nhân viên bán hàng'));
          FocusManager.instance.primaryFocus?.unfocus();
        },
      );
    });

    testWidgets('invite__empty-submit $width', (tester) async {
      final cubit = _inviteCubit();
      addTearDown(cubit.close);
      await _capture(
        tester,
        width: width,
        name: 'invite__empty-submit',
        page: OrganizationInviteMemberPage(cubit: cubit),
        act: () => tester.tap(find.widgetWithText(VButton, 'Gửi lời mời')),
      );
    });

    // ── ID-16 ──
    Widget invitationPage(String id) => OrganizationInvitationDetailPage(
      invitationId: id,
      invitations: _GoldenInvitations(),
      clock: () => _now,
    );

    testWidgets('invitation-detail__pending $width', (tester) async {
      await _capture(
        tester,
        width: width,
        name: 'invitation-detail__pending',
        page: invitationPage('i1'),
      );
    });

    testWidgets('invitation-detail__expired $width', (tester) async {
      await _capture(
        tester,
        width: width,
        name: 'invitation-detail__expired',
        page: invitationPage('i4'),
      );
    });

    testWidgets('invitation-detail__revoke $width', (tester) async {
      await _capture(
        tester,
        width: width,
        name: 'invitation-detail__revoke',
        page: invitationPage('i1'),
        act: () async {
          if (width == 390) {
            await tester.tap(find.text('Thao tác'));
            await tester.pumpAndSettle();
          }
          await tester.tap(find.text('Thu hồi lời mời').last);
        },
      );
    });

    // ── ID-17 ──
    Widget memberPage(String id) => OrganizationMemberDetailPage(
      membershipId: id,
      members: _GoldenMembers(),
    );

    for (final (name, id) in const [
      ('member-detail__active', 'm2'),
      ('member-detail__suspended', 'm3'),
      ('member-detail__removed', 'm4'),
      ('member-detail__owner', 'm1'),
    ]) {
      testWidgets('$name $width', (tester) async {
        await _capture(tester, width: width, name: name, page: memberPage(id));
      });
    }

    testWidgets('member-detail__deactivate $width', (tester) async {
      await _capture(
        tester,
        width: width,
        name: 'member-detail__deactivate',
        page: memberPage('m2'),
        act: () async {
          if (width == 390) {
            await tester.tap(find.text('Thao tác'));
            await tester.pumpAndSettle();
          }
          await tester.tap(find.text('Tạm ngừng thành viên').last);
        },
      );
    });

    // ── ID-18 ──
    Widget selectRolePage() => OrganizationSelectRolePage(
      member: _uiMember('m2'),
      onConfirm: (_) async => false,
    );

    testWidgets('select-role__default $width', (tester) async {
      await _capture(
        tester,
        width: width,
        name: 'select-role__default',
        page: selectRolePage(),
      );
    });

    testWidgets('select-role__selected $width', (tester) async {
      await _capture(
        tester,
        width: width,
        name: 'select-role__selected',
        page: selectRolePage(),
        act: () => tester.tap(find.text('Thủ kho')),
      );
    });

    testWidgets('select-role__confirm $width', (tester) async {
      await _capture(
        tester,
        width: width,
        name: 'select-role__confirm',
        page: selectRolePage(),
        act: () async {
          await tester.tap(find.text('Thủ kho'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(VButton, 'Tiếp tục'));
        },
      );
    });
  }

  // ── Chỉ iPhone: sheet "Thao tác" ──
  testWidgets('invitation-detail__actions 390', (tester) async {
    await _capture(
      tester,
      width: 390,
      name: 'invitation-detail__actions',
      page: OrganizationInvitationDetailPage(
        invitationId: 'i1',
        invitations: _GoldenInvitations(),
        clock: () => _now,
      ),
      act: () => tester.tap(find.text('Thao tác')),
    );
  });

  for (final (name, id) in const [
    ('member-detail__actions', 'm2'),
    ('member-detail__actions-suspended', 'm3'),
  ]) {
    testWidgets('$name 390', (tester) async {
      await _capture(
        tester,
        width: 390,
        name: name,
        page: OrganizationMemberDetailPage(
          membershipId: id,
          members: _GoldenMembers(),
        ),
        act: () => tester.tap(find.text('Thao tác')),
      );
    });
  }
}
