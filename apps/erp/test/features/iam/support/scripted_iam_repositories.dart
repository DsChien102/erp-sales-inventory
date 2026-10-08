import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/auth/data/auth_repository.dart';
import 'package:erp/features/iam/data/account_repository.dart';
import 'package:erp/features/iam/data/models/my_account.dart';
import 'package:erp/features/iam/data/models/password_reset_result.dart';
import 'package:erp/features/iam/data/models/tenant_profile.dart';
import 'package:erp/features/iam/data/models/upsert_legal_profile_result.dart';
import 'package:erp/features/iam/data/organization_repository.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_iam_domain/domain.dart';

SupabaseRpc get _unusedRpc => SupabaseRpc(
  SupabaseClient(
    'http://127.0.0.1',
    'anon',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  ),
);

GoTrueClient get _unusedAuth => GoTrueClient(
  url: 'http://127.0.0.1',
  headers: const {'apikey': 'anon'},
  autoRefreshToken: false,
);

enum OrganizationScript {
  ok,
  updateOk,
  forbidden,
  notFound,
  validation,
  stale,
  duplicateWarning,
  legalOk,
}

final class ScriptedOrganizationRepository extends OrganizationRepository {
  ScriptedOrganizationRepository({
    this.mode = OrganizationScript.ok,
    TenantProfile? tenant,
  }) : tenant = tenant ?? sampleTenantProfile(),
       super(rpc: _unusedRpc, tenantId: () async => 'org-001');

  final OrganizationScript mode;
  TenantProfile? tenant;
  final updates = <Map<String, Object?>>[];
  final upserts = <Map<String, Object?>>[];

  @override
  Future<TenantProfile> getTenant() async {
    if (mode == OrganizationScript.forbidden) {
      throw const AppException(AppErrorCode.noPermission);
    }
    if (mode == OrganizationScript.notFound || tenant == null) {
      throw const AppException(AppErrorCode.notFound);
    }
    return tenant!;
  }

  @override
  Future<TenantProfile> updateProfile({
    required String displayName,
    required String? contactEmail,
    required String? contactPhone,
    required String? contactAddressText,
    required String? provinceCode,
    required String? communeCode,
    required int expectedVersion,
  }) async {
    updates.add({
      'displayName': displayName,
      'expectedVersion': expectedVersion,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'contactAddressText': contactAddressText,
    });
    if (mode == OrganizationScript.validation) {
      throw const AppException(AppErrorCode.validation);
    }
    if (mode == OrganizationScript.stale) {
      throw const AppException(AppErrorCode.stateChanged);
    }
    final current = tenant!;
    tenant = TenantProfile(
      tenantId: current.tenantId,
      displayName: displayName,
      status: current.status,
      version: current.version + 1,
      businessTimezone: current.businessTimezone,
      baseCurrencyCode: current.baseCurrencyCode,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      contactAddressText: contactAddressText,
      provinceCode: provinceCode,
      communeCode: communeCode,
      activatedAt: current.activatedAt,
      legalProfile: current.legalProfile,
    );
    return tenant!;
  }

  @override
  Future<UpsertLegalProfileResult> upsertLegalProfile({
    required String legalEntityType,
    required String legalName,
    required String taxCode,
    required String? registeredAddressText,
    required String? provinceCode,
    required String? communeCode,
    required int expectedVersion,
    bool allowDuplicateTaxCode = false,
  }) async {
    upserts.add({
      'taxCode': taxCode,
      'allowDuplicateTaxCode': allowDuplicateTaxCode,
      'expectedVersion': expectedVersion,
    });
    final current = tenant!;
    if (mode == OrganizationScript.duplicateWarning && !allowDuplicateTaxCode) {
      return UpsertLegalProfileResult.warning(
        tenantVersion: current.version,
        warning: const DuplicateTaxCodeWarning(
          message: 'Tax code already used by another organization',
        ),
      );
    }
    final profile = TenantLegalProfile(
      tenantId: current.tenantId,
      legalEntityType:
          LegalEntityTypeCodes.fromCode(legalEntityType) ?? LegalEntityType.enterprise,
      legalName: legalName,
      taxCode: taxCode,
      version: (current.legalProfile?.version ?? 0) + 1,
      createdAt: current.legalProfile?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      registeredAddressText: registeredAddressText,
      provinceCode: provinceCode,
      communeCode: communeCode,
    );
    tenant = TenantProfile(
      tenantId: current.tenantId,
      displayName: current.displayName,
      status: current.status,
      version: current.version + 1,
      businessTimezone: current.businessTimezone,
      baseCurrencyCode: current.baseCurrencyCode,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
      contactEmail: current.contactEmail,
      contactPhone: current.contactPhone,
      contactAddressText: current.contactAddressText,
      provinceCode: current.provinceCode,
      communeCode: current.communeCode,
      activatedAt: current.activatedAt,
      legalProfile: profile,
    );
    return UpsertLegalProfileResult.saved(
      profile: profile,
      tenantVersion: tenant!.version,
    );
  }
}

TenantProfile sampleTenantProfile() {
  return TenantProfile(
    tenantId: 'org-001',
    displayName: 'Mậu Hiên',
    status: TenantLifecycleStatus.active,
    version: 1,
    businessTimezone: 'Asia/Ho_Chi_Minh',
    baseCurrencyCode: 'VND',
    createdAt: DateTime(2026, 7, 10, 10),
    updatedAt: DateTime(2026, 7, 12, 16),
    contactEmail: 'contact@mauhien.vn',
    contactPhone: '+84901234567',
    contactAddressText: '123 Nguyen Trai, Ha Noi',
    activatedAt: DateTime(2026, 7, 12, 16, 45),
    legalProfile: TenantLegalProfile(
      tenantId: 'org-001',
      legalEntityType: LegalEntityType.enterprise,
      legalName: 'Mậu Hiên Co., Ltd',
      taxCode: '0123456789',
      version: 1,
      createdAt: DateTime(2026, 7, 11),
      updatedAt: DateTime(2026, 7, 11),
    ),
  );
}

final class ScriptedAccountRepository extends AccountRepository {
  ScriptedAccountRepository({MyAccount? profile})
    : profile =
          profile ??
          const MyAccount(
            userId: 'lan-le',
            email: 'lan@gmail.com',
            givenName: 'Lan',
            familyName: 'Le',
            phone: '+84901234567',
            emailVerified: true,
          ),
      super(rpc: _unusedRpc, auth: _unusedAuth);

  MyAccount profile;
  int updateCount = 0;

  @override
  Future<MyAccount> getMyAccount() async => profile;

  @override
  Future<MyAccount> updateMyAccount({
    String? avatarReference,
    required String givenName,
    required String familyName,
    String? phone,
  }) async {
    updateCount += 1;
    profile = MyAccount(
      userId: profile.userId,
      email: profile.email,
      givenName: givenName,
      familyName: familyName,
      phone: phone,
      emailVerified: profile.emailVerified,
      avatarReference: avatarReference,
    );
    return profile;
  }
}

final class RecordingAuthRepository extends AuthRepository {
  RecordingAuthRepository({
    this.verifyResult = true,
    this.failFirstRequest = false,
    this.clock,
    Duration? resendAfter,
  }) : resendAfter = resendAfter ?? const Duration(seconds: 3),
       super(rpc: _unusedRpc, auth: _unusedAuth);

  final bool verifyResult;
  final bool failFirstRequest;
  final DateTime Function()? clock;
  final Duration resendAfter;
  final calls = <String>[];
  int _requests = 0;

  PasswordResetRequestResult _request() {
    final now = (clock ?? DateTime.now)().toUtc();
    return PasswordResetRequestResult(
      operationId: 'op-1',
      maskedEmail: 'l***@example.com',
      expiresAt: now.add(const Duration(minutes: 10)),
      resendAvailableAt: now.add(resendAfter),
    );
  }

  @override
  Future<PasswordResetRequestResult> requestMyPasswordReset() async {
    calls.add('requestMy');
    _requests += 1;
    if (failFirstRequest && _requests == 1) {
      throw const AppException(AppErrorCode.unknown);
    }
    return _request();
  }

  @override
  Future<PasswordResetRequestResult> resendMyPasswordReset(String operationId) async {
    calls.add('resendMy:$operationId');
    return _request();
  }

  @override
  Future<PasswordResetVerifyResult> verifyMyPasswordReset(
    String operationId,
    String code,
  ) async {
    calls.add('verifyMy');
    return PasswordResetVerifyResult(verified: verifyResult);
  }

  @override
  Future<PasswordResetCompletionResult> completeMyPasswordReset(
    String operationId,
    String newPassword,
  ) async {
    calls.add('completeMy');
    return const PasswordResetCompletionResult(
      currentSessionRotated: true,
      otherSessionsRevoked: true,
    );
  }

  @override
  Future<PasswordResetRequestResult> requestPasswordResetByEmail(String email) async {
    calls.add('requestByEmail:$email');
    return _request();
  }

  @override
  Future<PasswordResetRequestResult> resendPasswordResetByEmail(String operationId) async {
    calls.add('resendByEmail:$operationId');
    return _request();
  }

  @override
  Future<PasswordResetVerifyResult> verifyPasswordResetByEmail(
    String operationId,
    String code,
  ) async {
    calls.add('verifyByEmail');
    return PasswordResetVerifyResult(verified: verifyResult);
  }

  @override
  Future<PasswordResetCompletionResult> completePasswordResetByEmail(
    String operationId,
    String newPassword,
  ) async {
    calls.add('completeByEmail');
    return const PasswordResetCompletionResult(
      currentSessionRotated: false,
      otherSessionsRevoked: true,
    );
  }
}
