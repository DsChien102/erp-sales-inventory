import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'support/stub_platform_admin_gateway.dart';

final class _IdempotentPlatformGateway extends StubPlatformAdminGateway {
  final Map<String, TenantOnboardingResultDto> _byKey = {};
  var createCalls = 0;
  TenantOnboardingOperationDto? operation;

  @override
  Future<TenantOnboardingResultDto> createTenantOnboarding({
    required OnboardingOwnerInput owner,
    required String organizationName,
    required String idempotencyKey,
    String? correlationId,
  }) async {
    createCalls++;
    final existing = _byKey[idempotencyKey];
    if (existing != null) return existing;
    final result = TenantOnboardingResultDto(
      tenantId: 't-1',
      ownerMembershipId: 'm-1',
      ownerUserId: owner.existingUserId ?? 'u-new',
      tenantStatus: 'provisioning',
      correlationId: correlationId ?? 'c-1',
      isNewUser: owner.isNewUser,
    );
    _byKey[idempotencyKey] = result;
    return result;
  }

  @override
  Future<TenantOnboardingOperationDto?> getTenantOnboardingOperation(
    String operationId,
  ) async =>
      operation;

  @override
  Future<TenantOnboardingOperationDto> retryTenantOnboardingOperation({
    required String operationId,
    required String idempotencyKey,
  }) async {
    return TenantOnboardingOperationDto(
      operationId: operationId,
      status: TenantOnboardingOperationStatus.completed,
      completedSteps: const ['tenant', 'membership', 'identity'],
      correlationId: 'c-retry',
      tenantId: 't-1',
      ownerUserId: 'u-1',
    );
  }
}

void main() {
  group('scn_e01_u03 onboarding', () {
    test('create is idempotent by key', () async {
      final gateway = _IdempotentPlatformGateway();
      final handler = CreateTenantOnboardingCommandHandler(
        platformGateway: gateway,
      );
      final cmd = CreateTenantOnboardingCommand(
            owner: OnboardingOwnerInput.existing('u-1'),
            organizationName: 'Store',
            idempotencyKey: 'k-1',
          );
      final a = await handler.handle(cmd);
      final b = await handler.handle(cmd);
      expect(a.tenantId, b.tenantId);
      expect(gateway.createCalls, 2);
    });

    test('get + retry onboarding operation', () async {
      final gateway = _IdempotentPlatformGateway()
        ..operation = const TenantOnboardingOperationDto(
          operationId: 'op-1',
          status: TenantOnboardingOperationStatus.partialFailure,
          completedSteps: ['tenant'],
          failedStep: 'identity',
          correlationId: 'c-1',
        );
      final got = await GetTenantOnboardingOperationQueryHandler(
        platformGateway: gateway,
      ).handle(GetTenantOnboardingOperationQuery(operationId: 'op-1'));
      expect(got.status, TenantOnboardingOperationStatus.partialFailure);

      final resumed = await RetryTenantOnboardingOperationCommandHandler(
        platformGateway: gateway,
      ).handle(
        RetryTenantOnboardingOperationCommand(
          operationId: 'op-1',
          idempotencyKey: 'retry-1',
        ),
      );
      expect(resumed.status, TenantOnboardingOperationStatus.completed);
    });

    test('validator rejects empty org name', () async {
      expect(
        () => CreateTenantOnboardingCommandValidator().validate(
          CreateTenantOnboardingCommand(
            owner: OnboardingOwnerInput.existing('u-1'),
            organizationName: ' ',
            idempotencyKey: 'k',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
