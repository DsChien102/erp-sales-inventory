import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'support/stub_platform_admin_gateway.dart';

final class _IdempotentPlatformGateway extends StubPlatformAdminGateway {
  final Map<String, TenantOnboardingResultDto> _byKey = {};
  var createCalls = 0;
  TenantOnboardingOperationDto? operation;
  String? lastOwnerUserId;
  String? lastOwnerEmail;
  bool? lastIsNewUser;
  String? lastOrganizationDisplayName;
  String? lastContactEmail;
  String? lastContactPhone;
  String? lastContactAddressText;
  String? lastProvinceCode;
  String? lastCommuneCode;
  String? lastLegalName;
  String? lastTaxCode;
  String? lastRegisteredAddressText;

  @override
  Future<TenantOnboardingResultDto> createTenantOnboarding({
    required bool isNewUser,
    required String organizationName,
    required String idempotencyKey,
    String? organizationDisplayName,
    String? contactEmail,
    String? contactPhone,
    String? contactAddressText,
    String? provinceCode,
    String? communeCode,
    String? legalName,
    String? taxCode,
    String? registeredAddressText,
    String? ownerUserId,
    String? ownerEmail,
    String? ownerGivenName,
    String? ownerFamilyName,
    String? ownerPhone,
    String? correlationId,
  }) async {
    createCalls++;
    lastOwnerUserId = ownerUserId;
    lastOwnerEmail = ownerEmail;
    lastIsNewUser = isNewUser;
    lastOrganizationDisplayName = organizationDisplayName;
    lastContactEmail = contactEmail;
    lastContactPhone = contactPhone;
    lastContactAddressText = contactAddressText;
    lastProvinceCode = provinceCode;
    lastCommuneCode = communeCode;
    lastLegalName = legalName;
    lastTaxCode = taxCode;
    lastRegisteredAddressText = registeredAddressText;
    final existing = _byKey[idempotencyKey];
    if (existing != null) return existing;
    final result = TenantOnboardingResultDto(
      tenantId: 't-1',
      ownerMembershipId: isNewUser ? null : 'm-1',
      ownerUserId: ownerUserId,
      tenantStatus: 'provisioning',
      correlationId: correlationId ?? 'c-1',
      isNewUser: isNewUser,
      activationIssued: isNewUser,
    );
    _byKey[idempotencyKey] = result;
    return result;
  }

  @override
  Future<TenantOnboardingOperationDto?> getTenantOnboardingOperation(
    String operationId,
  ) async => operation;

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

    test('passes optional organization profile and legal fields to gateway', () async {
      final gateway = _IdempotentPlatformGateway();
      final handler = CreateTenantOnboardingCommandHandler(
        platformGateway: gateway,
      );

      await handler.handle(
        CreateTenantOnboardingCommand(
          owner: OnboardingOwnerInput.existing('u-1'),
          organizationName: 'Store',
          organizationDisplayName: 'Store Display',
          contactEmail: 'store@example.com',
          contactPhone: '0909123456',
          contactAddressText: '123 Main',
          provinceCode: 'Thành phố Hà Nội',
          communeCode: 'Phường Ba Đình',
          legalName: 'Store Legal Co',
          taxCode: '0123456789',
          registeredAddressText: '456 Legal St',
          idempotencyKey: 'k-profile',
        ),
      );

      expect(gateway.lastOrganizationDisplayName, 'Store Display');
      expect(gateway.lastContactEmail, 'store@example.com');
      expect(gateway.lastContactPhone, '0909123456');
      expect(gateway.lastContactAddressText, '123 Main');
      expect(gateway.lastProvinceCode, 'Thành phố Hà Nội');
      expect(gateway.lastCommuneCode, 'Phường Ba Đình');
      expect(gateway.lastLegalName, 'Store Legal Co');
      expect(gateway.lastTaxCode, '0123456789');
      expect(gateway.lastRegisteredAddressText, '456 Legal St');
    });

    test('new owner issues activation without pre-provisioning identity', () async {
      final gateway = _IdempotentPlatformGateway();
      final handler = CreateTenantOnboardingCommandHandler(
        platformGateway: gateway,
      );

      final result = await handler.handle(
        CreateTenantOnboardingCommand(
          owner: const OnboardingOwnerInput.newUser(
            lastName: 'Nguyen',
            firstName: 'An',
            email: 'new@example.com',
            phone: '0909123456',
          ),
          organizationName: 'Store',
          idempotencyKey: 'k-new',
          correlationId: 'corr-new',
        ),
      );

      // Hướng 1: no identity resolution — gateway is called directly with the
      // new-owner email; the account is created later at activation.
      expect(gateway.lastIsNewUser, isTrue);
      expect(gateway.lastOwnerEmail, 'new@example.com');
      expect(gateway.lastOwnerUserId, isNull);
      expect(result.isNewUser, isTrue);
      expect(result.activationIssued, isTrue);
      expect(result.ownerUserId, isNull);
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

      final resumed =
          await RetryTenantOnboardingOperationCommandHandler(
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
