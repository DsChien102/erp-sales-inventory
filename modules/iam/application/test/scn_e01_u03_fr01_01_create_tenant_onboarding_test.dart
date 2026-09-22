import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'support/stub_platform_admin_gateway.dart';

final class _IdempotentPlatformGateway extends StubPlatformAdminGateway {
  final Map<String, TenantOnboardingResultDto> _byKey = {};
  var createCalls = 0;
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
  String? lastLegalEntityType;
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
    String? legalEntityType,
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
    lastLegalEntityType = legalEntityType;
    lastRegisteredAddressText = registeredAddressText;
    final existing = _byKey[idempotencyKey];
    if (existing != null) return existing;
    final result = TenantOnboardingResultDto(
      tenantId: 't-1',
      ownerMembershipId: null,
      ownerUserId: isNewUser ? null : ownerUserId,
      tenantStatus: 'provisioning',
      correlationId: correlationId ?? 'c-1',
      isNewUser: isNewUser,
      activationIssued: true,
    );
    _byKey[idempotencyKey] = result;
    return result;
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
          legalEntityType: 'ENTERPRISE',
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
      expect(gateway.lastLegalEntityType, 'ENTERPRISE');
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

      expect(gateway.lastIsNewUser, isTrue);
      expect(gateway.lastOwnerEmail, 'new@example.com');
      expect(gateway.lastOwnerUserId, isNull);
      expect(result.isNewUser, isTrue);
      expect(result.activationIssued, isTrue);
      expect(result.ownerMembershipId, isNull);
      expect(result.ownerUserId, isNull);
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

    test('validator requires legal entity type when legal name and tax code given', () async {
      expect(
        () => CreateTenantOnboardingCommandValidator().validate(
          CreateTenantOnboardingCommand(
            owner: OnboardingOwnerInput.existing('u-1'),
            organizationName: 'Store',
            legalName: 'Store Legal Co',
            taxCode: '0123456789',
            idempotencyKey: 'k',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('validator rejects unknown legal entity type', () async {
      expect(
        () => CreateTenantOnboardingCommandValidator().validate(
          CreateTenantOnboardingCommand(
            owner: OnboardingOwnerInput.existing('u-1'),
            organizationName: 'Store',
            legalName: 'Store Legal Co',
            taxCode: '0123456789',
            legalEntityType: 'VETERINARY_CLINIC',
            idempotencyKey: 'k',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
