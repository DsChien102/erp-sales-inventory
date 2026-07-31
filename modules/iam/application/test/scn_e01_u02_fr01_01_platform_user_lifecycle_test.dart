import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'support/stub_platform_admin_gateway.dart';

final class _RecordingPlatformGateway extends StubPlatformAdminGateway {
  String? activationUserId;
  String? passwordResetUserId;
  String? suspendUserId;
  String? suspendReason;
  String? restoreUserId;
  int? lastExpectedVersion;
  String? lastIdempotencyKey;

  @override
  Future<void> sendActivationInvitation({
    required String userId,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    activationUserId = userId;
    lastExpectedVersion = expectedVersion;
    lastIdempotencyKey = idempotencyKey;
  }

  @override
  Future<void> requestPasswordReset({
    required String userId,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    passwordResetUserId = userId;
    lastExpectedVersion = expectedVersion;
    lastIdempotencyKey = idempotencyKey;
  }

  @override
  Future<void> suspendPlatformUser({
    required String userId,
    required String reason,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    suspendUserId = userId;
    suspendReason = reason;
    lastExpectedVersion = expectedVersion;
    lastIdempotencyKey = idempotencyKey;
  }

  @override
  Future<void> restorePlatformUser({
    required String userId,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    restoreUserId = userId;
    lastExpectedVersion = expectedVersion;
    lastIdempotencyKey = idempotencyKey;
  }
}

void main() {
  group('scn_e01_u02_fr01_01 platform user lifecycle', () {
    test('activation_resend_ok delegates with version/key', () async {
      final gateway = _RecordingPlatformGateway();
      await SendActivationInvitationCommandHandler(
        platformGateway: gateway,
      ).handle(
        SendActivationInvitationCommand(
          userId: 'u-pending',
          expectedVersion: 1,
          idempotencyKey: 'act-1',
        ),
      );
      expect(gateway.activationUserId, 'u-pending');
      expect(gateway.lastExpectedVersion, 1);
      expect(gateway.lastIdempotencyKey, 'act-1');
    });

    test('password reset initiate delegates without credentials', () async {
      final gateway = _RecordingPlatformGateway();
      await RequestPlatformPasswordResetCommandHandler(
        platformGateway: gateway,
      ).handle(
        RequestPlatformPasswordResetCommand(
          userId: 'u-active',
          expectedVersion: 2,
          idempotencyKey: 'pwd-1',
        ),
      );
      expect(gateway.passwordResetUserId, 'u-active');
    });

    test('suspend_ok requires reason and delegates', () async {
      final gateway = _RecordingPlatformGateway();
      final command = SuspendPlatformUserCommand(
        userId: 'u-1',
        reason: 'abuse',
        expectedVersion: 1,
        idempotencyKey: 'sus-1',
      );
      await SuspendPlatformUserCommandValidator().validate(command);
      await SuspendPlatformUserCommandHandler(
        platformGateway: gateway,
      ).handle(command);
      expect(gateway.suspendUserId, 'u-1');
      expect(gateway.suspendReason, 'abuse');
    });

    test('suspend validator rejects empty reason', () async {
      expect(
        () => SuspendPlatformUserCommandValidator().validate(
          SuspendPlatformUserCommand(
            userId: 'u-1',
            reason: '  ',
            expectedVersion: 1,
            idempotencyKey: 'sus-1',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('restore_ok delegates', () async {
      final gateway = _RecordingPlatformGateway();
      await RestorePlatformUserCommandHandler(platformGateway: gateway).handle(
        RestorePlatformUserCommand(
          userId: 'u-suspended',
          expectedVersion: 4,
          idempotencyKey: 'res-1',
        ),
      );
      expect(gateway.restoreUserId, 'u-suspended');
    });
  });
}
