import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';

void main() {
  group('scn_e03_u01 members invitations contract', () {
    test('public exports expose S6 symbols', () {
      expect(ListTenantMembersQuery, isNotNull);
      expect(ListInvitationsQuery, isNotNull);
      expect(GetInvitationQuery, isNotNull);
      expect(TenantMemberDto, isNotNull);
      expect(InvitationSummaryDto, isNotNull);
      expect(InvitationDetailDto, isNotNull);
      expect(CursorPageDto, isNotNull);
    });

    test('FakeIamModule members_search_ok and invitations scenarios', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.membersSearchOk);
      final members = await module.executeQueryAsync(
        ListTenantMembersQuery(tenantId: 'org-001', search: 'lan'),
      );
      expect(members.items, isNotEmpty);
      expect(members.items.first.email, contains('@'));
      expect(members.items.first.membershipId, isNotEmpty);

      final invitations = await module.executeQueryAsync(
        ListInvitationsQuery(tenantId: 'org-001', search: 'invitee'),
      );
      expect(invitations.items, isNotEmpty);
      expect(invitations.items.first.status, isNot(equals('')));

      final detail = await module.executeQueryAsync(
        GetInvitationQuery(tenantId: 'org-001', invitationId: 'inv-1'),
      );
      expect(detail.invitationId, 'inv-1');
      expect(detail.createdBy, isNotEmpty);
    });

    test('expired invitations are not pending', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.invitationsExpired);
      final page = await module.executeQueryAsync(
        ListInvitationsQuery(tenantId: 'org-001', status: 'expired'),
      );
      expect(page.items, isNotEmpty);
      expect(page.items.every((i) => i.status == 'expired'), isTrue);
      expect(page.items.any((i) => i.status == 'pending'), isFalse);
    });

    test('cross-tenant invitation detail is RESOURCE_NOT_FOUND', () async {
      final module = FakeIamModule(
        scenario: FakeIamScenario.memberInvitationCrossTenantNotFound,
      );
      expect(
        () => module.executeQueryAsync(
          GetInvitationQuery(tenantId: 'org-001', invitationId: 'inv-x'),
        ),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.resourceNotFound,
          ),
        ),
      );
    });

    test('ListInvitationsQueryHandler validates status + delegates', () async {
      final port = FakeTenantInvitationReadPort(
        invitations: [
          InvitationDetailDto(
            invitationId: 'inv-1',
            inviteeEmail: 'a@b.c',
            initialRoleId: 'role-1',
            initialRoleLabel: 'Staff',
            status: 'pending',
            expiresAt: DateTime.utc(2026, 8, 1),
            deliveryStatus: 'queued',
            deliveryCorrelationId: 'c1',
            version: 1,
            createdAt: DateTime.utc(2026, 7, 25),
            createdBy: 'u1',
          ),
        ],
      );
      final handler = ListInvitationsQueryHandler(readPort: port);
      final page = await handler.handle(
        ListInvitationsQuery(tenantId: 't1', limit: 20),
      );
      expect(page.items, hasLength(1));

      expect(
        () => handler.handle(
          ListInvitationsQuery(tenantId: 't1', status: 'bogus'),
        ),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.validationError,
          ),
        ),
      );
    });
  });
}
