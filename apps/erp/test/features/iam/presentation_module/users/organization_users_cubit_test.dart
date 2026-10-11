import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/core/iam/iam_codes.dart';
import 'package:erp/features/iam/data/models/cursor_page.dart';
import 'package:erp/features/iam/data/models/tenant_invitation.dart';
import 'package:erp/features/iam/data/models/tenant_member.dart';
import '../../support/fake_iam_backend.dart';
import 'package:erp/features/iam/presentation.dart';
import '../../support/iam_fixtures.dart';

void main() {
  test('loads members and preserves nextCursor', () async {
    final module = FakeIamBackend(scenario: FakeIamScenario.membersSearchOk);
    final cubit = OrganizationUsersCubit(
      members: FakeMemberRepository(module),
      invitations: FakeInvitationRepository(module),
      searchDebounce: Duration.zero,
    );
    await cubit.loadMembers(reset: true);
    expect(cubit.state.members, isNotEmpty);
    expect(cubit.state.memberStatus, IamLoadStatus.success);
    final query = module.queriesOf<ListTenantMembersQuery>().single;
    expect(query.tenantId, 'org-001');
    await cubit.close();
  });

  test('forbidden emits typed permission failure', () async {
    final cubit = OrganizationUsersCubit(
      members: FakeMemberRepository(FakeIamBackend(
        scenario: FakeIamScenario.memberInvitationForbidden,
      )),
      invitations: FakeInvitationRepository(FakeIamBackend(
        scenario: FakeIamScenario.memberInvitationForbidden,
      )),
      searchDebounce: Duration.zero,
    );
    await cubit.loadMembers(reset: true);
    expect(cubit.state.memberFailure?.code, IamBlockedCodes.permissionDenied);
    await cubit.close();
  });

  test('page 2 receives exact cursor from page 1', () async {
    var page = 0;
    final scripted = FakeIamBackend(
      onListMembers: (message) async {
        page += 1;
        if (page == 1) {
          expect(message.cursor, isNull);
          return CursorPage<TenantMember>(
            items: [
              TenantMember(
                membershipId: 'm-1',
                userId: 'u-1',
                displayName: 'A',
                email: 'a@example.com',
                roleId: 'r1',
                roleLabel: 'Staff',
                isOwner: false,
                status: 'active',
                joinedAt: DateTime.utc(2026, 1, 1),
                version: 1,
              ),
            ],
            nextCursor: 'cursor-page-1',
          );
        }
        expect(message.cursor, 'cursor-page-1');
        return CursorPage<TenantMember>(
          items: [
            TenantMember(
              membershipId: 'm-2',
              userId: 'u-2',
              displayName: 'B',
              email: 'b@example.com',
              roleId: 'r1',
              roleLabel: 'Staff',
              isOwner: false,
              status: 'active',
              joinedAt: DateTime.utc(2026, 2, 1),
              version: 1,
            ),
          ],
        );
      },
    );
    final cubit = OrganizationUsersCubit(
      members: FakeMemberRepository(scripted),
      invitations: FakeInvitationRepository(scripted),
      searchDebounce: Duration.zero,
    );
    await cubit.loadMembers(reset: true);
    expect(cubit.state.memberNextCursor, 'cursor-page-1');
    await cubit.loadNextMembersPage();
    expect(cubit.state.members.map((m) => m.id), ['m-1', 'm-2']);
    expect(cubit.state.memberNextCursor, isNull);
    await cubit.close();
  });

  test('always places owner at the top of the member list', () async {
    final scripted = FakeIamBackend(
      onListMembers: (message) async {
        return CursorPage<TenantMember>(
          items: [
            TenantMember(
              membershipId: 'm-regular',
              userId: 'u-reg',
              displayName: 'Nguyen Duong',
              email: 'dn200422@gmail.com',
              roleId: 'accountant',
              roleLabel: 'Kế toán',
              isOwner: false,
              status: 'active',
              joinedAt: DateTime.utc(2026, 1, 1),
              version: 1,
            ),
            TenantMember(
              membershipId: 'm-owner',
              userId: 'u-owner',
              displayName: 'Đỗ Sỹ Chiến',
              email: 'dosychien9@gmail.com',
              roleId: 'store_owner',
              roleLabel: 'Chủ cửa hàng',
              isOwner: true,
              status: 'active',
              joinedAt: DateTime.utc(2026, 1, 2),
              version: 1,
            ),
          ],
        );
      },
    );
    final cubit = OrganizationUsersCubit(
      members: FakeMemberRepository(scripted),
      invitations: FakeInvitationRepository(scripted),
      searchDebounce: Duration.zero,
    );
    await cubit.loadMembers(reset: true);
    expect(cubit.state.members.first.id, 'm-owner');
    expect(cubit.state.members.first.isOwner, isTrue);
    expect(cubit.state.members.last.id, 'm-regular');
    await cubit.close();
  });

  test('filters invitations by sendResult (Đã gửi, Gửi lỗi, Thu hồi)', () async {
    final invitations = [
      TenantInvitation(
        invitationId: 'inv-sent',
        inviteeEmail: 'sent@example.com',
        initialRoleId: 'r1',
        initialRoleLabel: 'Staff',
        status: 'pending',
        expiresAt: DateTime.utc(2026, 8, 10),
        deliveryStatus: 'sent',
        deliveryCorrelationId: 'c1',
        version: 1,
      ),
      TenantInvitation(
        invitationId: 'inv-failed',
        inviteeEmail: 'failed@example.com',
        initialRoleId: 'r1',
        initialRoleLabel: 'Staff',
        status: 'pending',
        expiresAt: DateTime.utc(2026, 8, 10),
        deliveryStatus: 'failed',
        deliveryCorrelationId: 'c2',
        version: 1,
      ),
      TenantInvitation(
        invitationId: 'inv-revoked',
        inviteeEmail: 'revoked@example.com',
        initialRoleId: 'r1',
        initialRoleLabel: 'Staff',
        status: 'revoked',
        expiresAt: DateTime.utc(2026, 8, 10),
        deliveryStatus: 'sent',
        deliveryCorrelationId: 'c3',
        version: 1,
      ),
    ];

    final scripted = FakeIamBackend(
      onListInvitations: (m) async {
        return CursorPage<TenantInvitation>(items: invitations);
      },
    );

    final cubit = OrganizationUsersCubit(
      members: FakeMemberRepository(scripted),
      invitations: FakeInvitationRepository(scripted),
      searchDebounce: Duration.zero,
      clock: () => DateTime.utc(2026, 8, 5),
    );

    // Initial load: 3 invitations
    await cubit.loadInvitations(reset: true);
    expect(cubit.state.invitations, hasLength(3));

    // Filter 'Đã gửi' -> inv-sent
    await cubit.applyInvitationCriteria(sendResult: 'Đã gửi');
    expect(cubit.state.invitations, hasLength(1));
    expect(cubit.state.invitations.first.id, 'inv-sent');

    // Filter 'Gửi lỗi' -> inv-failed
    await cubit.applyInvitationCriteria(sendResult: 'Gửi lỗi');
    expect(cubit.state.invitations, hasLength(1));
    expect(cubit.state.invitations.first.id, 'inv-failed');

    // Filter 'Thu hồi' -> inv-revoked
    await cubit.applyInvitationCriteria(sendResult: 'Thu hồi');
    expect(cubit.state.invitations, hasLength(1));
    expect(cubit.state.invitations.first.id, 'inv-revoked');

    await cubit.close();
  });

  test('filters invitations by timeRange (7 ngày, 30 ngày, Tùy chọn)', () async {
    final now = DateTime.utc(2026, 8, 10);
    // expiresAt = createdAt + 7 days => createdAt = expiresAt - 7 days
    final invitations = [
      // Created on 2026-08-08 (2 days ago -> within 7 days & 30 days)
      TenantInvitation(
        invitationId: 'inv-recent',
        inviteeEmail: 'recent@example.com',
        initialRoleId: 'r1',
        initialRoleLabel: 'Staff',
        status: 'pending',
        expiresAt: DateTime.utc(2026, 8, 15),
        deliveryStatus: 'sent',
        deliveryCorrelationId: 'c1',
        version: 1,
      ),
      // Created on 2026-07-25 (16 days ago -> within 30 days, not within 7 days)
      TenantInvitation(
        invitationId: 'inv-medium',
        inviteeEmail: 'medium@example.com',
        initialRoleId: 'r1',
        initialRoleLabel: 'Staff',
        status: 'pending',
        expiresAt: DateTime.utc(2026, 8, 1),
        deliveryStatus: 'sent',
        deliveryCorrelationId: 'c2',
        version: 1,
      ),
      // Created on 2026-06-01 (> 60 days ago -> outside 30 days)
      TenantInvitation(
        invitationId: 'inv-old',
        inviteeEmail: 'old@example.com',
        initialRoleId: 'r1',
        initialRoleLabel: 'Staff',
        status: 'expired',
        expiresAt: DateTime.utc(2026, 6, 8),
        deliveryStatus: 'sent',
        deliveryCorrelationId: 'c3',
        version: 1,
      ),
    ];

    final scripted = FakeIamBackend(
      onListInvitations: (m) async {
        return CursorPage<TenantInvitation>(items: invitations);
      },
    );

    final cubit = OrganizationUsersCubit(
      members: FakeMemberRepository(scripted),
      invitations: FakeInvitationRepository(scripted),
      searchDebounce: Duration.zero,
      clock: () => now,
    );

    // Filter '7 ngày'
    await cubit.applyInvitationCriteria(timeRange: '7 ngày');
    expect(cubit.state.invitations, hasLength(1));
    expect(cubit.state.invitations.first.id, 'inv-recent');

    // Filter '30 ngày'
    await cubit.applyInvitationCriteria(timeRange: '30 ngày');
    expect(cubit.state.invitations, hasLength(2));
    expect(cubit.state.invitations.map((i) => i.id), containsAll(['inv-recent', 'inv-medium']));

    // Filter 'Tùy chọn'
    await cubit.applyInvitationCriteria(
      timeRange: 'Tùy chọn',
      customDateRange: DateTimeRange(
        start: DateTime(2026, 7, 20),
        end: DateTime(2026, 7, 30),
      ),
    );
    expect(cubit.state.invitations, hasLength(1));
    expect(cubit.state.invitations.first.id, 'inv-medium');

    await cubit.close();
  });
}
