import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_presentation/presentation.dart';

InvitationSummaryDto _summary({
  required String status,
  String deliveryStatus = 'sent',
  Duration expiresIn = const Duration(days: 6),
}) {
  return InvitationSummaryDto(
    invitationId: 'inv-1',
    inviteeEmail: 'invitee@example.com',
    initialRoleId: 'role-1',
    initialRoleLabel: 'Quản lý',
    status: status,
    expiresAt: DateTime.utc(2026, 8, 2).add(expiresIn),
    deliveryStatus: deliveryStatus,
    deliveryCorrelationId: 'corr-1',
    version: 1,
  );
}

void main() {
  final now = DateTime.utc(2026, 8, 2);

  group('InvitationUiMapper lifecycle status', () {
    test('maps each terminal wire status to its own UI status', () {
      expect(
        InvitationUiMapper.fromSummary(_summary(status: 'revoked'), nowUtc: now)
            .status,
        InvitationStatus.revoked,
      );
      expect(
        InvitationUiMapper.fromSummary(_summary(status: 'accepted'), nowUtc: now)
            .status,
        InvitationStatus.accepted,
      );
      expect(
        InvitationUiMapper.fromSummary(_summary(status: 'declined'), nowUtc: now)
            .status,
        InvitationStatus.declined,
      );
      expect(
        InvitationUiMapper.fromSummary(_summary(status: 'expired'), nowUtc: now)
            .status,
        InvitationStatus.expired,
      );
    });

    test('keeps pending and expiring behaviour', () {
      expect(
        InvitationUiMapper.fromSummary(_summary(status: 'pending'), nowUtc: now)
            .status,
        InvitationStatus.pending,
      );
      expect(
        InvitationUiMapper.fromSummary(
          _summary(status: 'pending', expiresIn: const Duration(hours: 12)),
          nowUtc: now,
        ).status,
        InvitationStatus.expiring,
      );
    });

    test('delivery failure surfaces only while the invitation is pending', () {
      expect(
        InvitationUiMapper.fromSummary(
          _summary(status: 'pending', deliveryStatus: 'failed'),
          nowUtc: now,
        ).status,
        InvitationStatus.failed,
      );
      // A revoked invitation must not be reported as a delivery problem.
      expect(
        InvitationUiMapper.fromSummary(
          _summary(status: 'revoked', deliveryStatus: 'failed'),
          nowUtc: now,
        ).status,
        InvitationStatus.revoked,
      );
    });
  });
}
