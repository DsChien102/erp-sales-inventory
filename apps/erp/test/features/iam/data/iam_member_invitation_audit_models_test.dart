import 'package:erp/features/iam/data/models/tenant_audit_log.dart';
import 'package:erp/features/iam/data/models/tenant_invitation.dart';
import 'package:erp/features/iam/data/models/tenant_member.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_domain/domain.dart';

void main() {
  test('TenantMemberDetail.fromJson maps lifecycle fields', () {
    final detail = TenantMemberDetail.fromJson({
      'membership_id': 'mem-1',
      'tenant_id': 'org-1',
      'user_id': 'user-1',
      'display_name': 'Lan',
      'email': 'lan@example.com',
      'role': 'staff',
      'role_label': 'Nhân viên',
      'is_owner': false,
      'is_sole_owner': false,
      'status': 'inactive',
      'version': 4,
      'joined_at': '2026-01-02T00:00:00Z',
    });

    expect(detail.membershipId, 'mem-1');
    expect(detail.status, MembershipStatus.inactive);
    expect(detail.version, 4);
    expect(detail.role, 'staff');
  });

  test('TenantInvitationDetail.fromJson keeps delivery status', () {
    final detail = TenantInvitationDetail.fromJson(
      {
        'invitation_id': 'inv-1',
        'invitee_email': 'a@example.com',
        'initial_role_id': 'staff',
        'initial_role_label': 'Nhân viên',
        'status': 'pending',
        'expires_at': '2026-08-01T00:00:00Z',
        'delivery_status': 'failed',
        'delivery_correlation_id': 'corr-1',
        'version': 2,
        'created_at': '2026-07-01T00:00:00Z',
        'created_by': 'owner-1',
      },
      defaultDeliveryStatus: 'unknown',
    );

    expect(detail.inviteeEmail, 'a@example.com');
    expect(detail.deliveryStatus, 'failed');
    expect(detail.version, 2);
  });

  test('TenantAuditLogPage.fromJson keeps next_cursor and empty before_state', () {
    final page = TenantAuditLogPage.fromJson({
      'items': [
        {
          'audit_log_id': 'aud-1',
          'event_code': 'iam.membership.deactivated',
          'event_category': 'member',
          'result': 'success',
          'occurred_at': '2026-08-01T00:00:00Z',
          'source': 'iam',
          'tracking_id': 'trk-1',
          'actor': {'display_origin': 'snapshot'},
          'subject': {'type': 'membership', 'display_origin': 'snapshot'},
        },
      ],
      'total_count': 1,
      'next_cursor': 'cursor-2',
    });
    final detail = TenantAuditLogDetail.fromJson({
      'audit_log_id': 'aud-1',
      'tenant_id': 'org-1',
      'event_code': 'iam.membership.deactivated',
      'result': 'success',
      'occurred_at': '2026-08-01T00:00:00Z',
      'tracking_id': 'trk-1',
      'actor_unavailable': false,
      'before_redacted': false,
      'after_redacted': false,
      'before_state': <String, dynamic>{},
      'after_state': <String, dynamic>{},
      'actor': {'display_origin': 'snapshot'},
      'subject': {'type': 'membership', 'display_origin': 'snapshot'},
    });

    expect(page.nextCursor, 'cursor-2');
    expect(page.items, hasLength(1));
    expect(detail.beforeState, isEmpty);
    expect(detail.afterState, isEmpty);
  });
}
