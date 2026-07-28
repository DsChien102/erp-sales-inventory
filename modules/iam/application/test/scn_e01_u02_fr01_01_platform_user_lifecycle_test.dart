import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

class _RecordingPlatformGateway implements IPlatformAdminGateway {
  String? activationUserId;
  String? passwordResetUserId;
  String? suspendUserId;
  String? suspendReason;
  String? restoreUserId;

  @override
  Future<bool> hasPlatformPermission(String permission) async => true;

  @override
  Future<List<PlatformUserSummaryDto>> searchPlatformUsers({
    String? query,
    PlatformUserStatus? status,
  }) async =>
      const [];

  @override
  Future<PlatformUserDetailDto> getPlatformUser(String userId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> sendActivationInvitation(String userId) async {
    activationUserId = userId;
  }

  @override
  Future<void> requestPasswordReset(String userId) async {
    passwordResetUserId = userId;
  }

  @override
  Future<void> suspendPlatformUser({
    required String userId,
    required String reason,
  }) async {
    suspendUserId = userId;
    suspendReason = reason;
  }

  @override
  Future<void> restorePlatformUser(String userId) async {
    restoreUserId = userId;
  }

  @override
  Future<TenantOnboardingResultDto> createTenantOnboarding({
    required OnboardingOwnerInput owner,
    required String organizationName,
    required String idempotencyKey,
    String? correlationId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<PlatformTenantSummaryDto>> searchPlatformTenants({
    String? query,
    TenantLifecycleStatus? status,
  }) async =>
      throw UnimplementedError();

  @override
  Future<PlatformTenantDetailDto> getPlatformTenant(String tenantId) async =>
      throw UnimplementedError();

  @override
  Future<List<PlatformTenantMemberDto>> listPlatformTenantMembers(
    String tenantId,
  ) async =>
      throw UnimplementedError();

  @override
  Future<void> suspendPlatformTenant({
    required String tenantId,
    required String reason,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> restorePlatformTenant(String tenantId) async =>
      throw UnimplementedError();

  @override
  Future<void> transferPlatformTenantOwnership({
    required String tenantId,
    required String newOwnerUserId,
    required String idempotencyKey,
  }) async =>
      throw UnimplementedError();

  @override
  Future<List<PlatformAuditLogSummaryDto>> searchPlatformAuditLogs({
    String? query,
    PlatformAuditLogStatus? status,
  }) async =>
      throw UnimplementedError();

  @override
  Future<PlatformAuditLogDetailDto> getPlatformAuditLog(String auditLogId) async =>
      throw UnimplementedError();

}

void main() {
  group('scn_e01_u02_fr01_01 platform user lifecycle', () {
    test('activation_resend_ok delegates', () async {
      final gateway = _RecordingPlatformGateway();
      final handler = SendActivationInvitationCommandHandler(
        platformGateway: gateway,
      );

      await handler.handle(
        SendActivationInvitationCommand(userId: 'u-pending'),
      );

      expect(gateway.activationUserId, 'u-pending');
    });

    test('password reset initiate delegates without credentials', () async {
      final gateway = _RecordingPlatformGateway();
      final handler = RequestPlatformPasswordResetCommandHandler(
        platformGateway: gateway,
      );

      await handler.handle(
        RequestPlatformPasswordResetCommand(userId: 'u-active'),
      );

      expect(gateway.passwordResetUserId, 'u-active');
    });

    test('suspend_ok requires reason and delegates', () async {
      final gateway = _RecordingPlatformGateway();
      final validator = SuspendPlatformUserCommandValidator();
      final handler = SuspendPlatformUserCommandHandler(
        platformGateway: gateway,
      );

      await validator.validate(
        SuspendPlatformUserCommand(userId: 'u-1', reason: 'abuse'),
      );
      await handler.handle(
        SuspendPlatformUserCommand(userId: 'u-1', reason: 'abuse'),
      );

      expect(gateway.suspendUserId, 'u-1');
      expect(gateway.suspendReason, 'abuse');
    });

    test('suspend validator rejects empty reason', () async {
      final validator = SuspendPlatformUserCommandValidator();

      expect(
        () => validator.validate(
          SuspendPlatformUserCommand(userId: 'u-1', reason: '  '),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('restore_ok delegates', () async {
      final gateway = _RecordingPlatformGateway();
      final handler = RestorePlatformUserCommandHandler(
        platformGateway: gateway,
      );

      await handler.handle(RestorePlatformUserCommand(userId: 'u-suspended'));

      expect(gateway.restoreUserId, 'u-suspended');
    });
  });
}
