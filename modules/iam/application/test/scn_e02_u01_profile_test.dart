import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';

void main() {
  final sample = TenantDto(
    tenantId: 'org-001',
    displayName: 'Mậu Hiên',
    status: TenantLifecycleStatus.active,
    version: 1,
    businessTimezone: 'Asia/Ho_Chi_Minh',
    baseCurrencyCode: 'VND',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
    contactEmail: 'contact@mauhien.vn',
    contactPhone: '+84901234567',
    contactAddressText: '123 Nguyen Trai',
  );

  group('scn_e02_u01 tenant profile handlers', () {
    test('GetTenantQuery returns tenant profile', () async {
      final gateway = _RecordingReadGateway(sample);
      final handler = GetTenantQueryHandler(readGateway: gateway);
      final result = await handler.handle(
        GetTenantQuery(tenantId: 'org-001'),
      );
      expect(result.displayName, 'Mậu Hiên');
      expect(gateway.calls, 1);
    });

    test('GetTenantQuery throws RESOURCE_NOT_FOUND', () async {
      final handler = GetTenantQueryHandler(
        readGateway: _RecordingReadGateway(null),
      );
      expect(
        () => handler.handle(GetTenantQuery(tenantId: 'missing')),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.resourceNotFound,
          ),
        ),
      );
    });

    test('UpdateTenantProfileCommand delegates to gateway', () async {
      final gateway = _RecordingCommandGateway(
        sample.copyWith(displayName: 'Updated', version: 2),
      );
      final handler = UpdateTenantProfileCommandHandler(
        commandGateway: gateway,
      );
      final result = await handler.handle(
        UpdateTenantProfileCommand(
          tenantId: 'org-001',
          displayName: 'Updated',
          contactEmail: 'contact@mauhien.vn',
          contactPhone: '+84901234567',
          contactAddressText: '123 Nguyen Trai',
          provinceCode: null,
          communeCode: null,
          expectedVersion: 1,
        ),
      );
      expect(result.version, 2);
      expect(gateway.lastOp, 'updateProfile');
    });

    test('UpsertLegalProfileCommand delegates to gateway', () async {
      final profile = TenantLegalProfileDto(
        tenantId: 'org-001',
        legalEntityType: LegalEntityType.enterprise,
        legalName: 'Mậu Hiên Co., Ltd',
        taxCode: '0123456789',
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      final gateway = _RecordingCommandGateway(
        UpsertLegalProfileResultDto.saved(profile: profile, tenantVersion: 2),
      );
      final handler = UpsertLegalProfileCommandHandler(
        commandGateway: gateway,
      );
      final result = await handler.handle(
        UpsertLegalProfileCommand(
          tenantId: 'org-001',
          legalEntityType: 'ENTERPRISE',
          legalName: 'Mậu Hiên Co., Ltd',
          taxCode: '0123456789',
          registeredAddressText: null,
          provinceCode: null,
          communeCode: null,
          expectedVersion: 1,
          allowDuplicateTaxCode: false,
        ),
      );
      expect(result.isSaved, isTrue);
      expect(gateway.lastOp, 'upsertLegalProfile');
    });

    test('legal_duplicate_warning — success warning not exception', () async {
      final gateway = _RecordingCommandGateway(
        UpsertLegalProfileResultDto.warning(
          warning: const DuplicateTaxCodeWarningDto(
            code: DuplicateTaxCodeWarningDto.codeValue,
            message: 'Tax code already used',
          ),
          tenantVersion: 1,
        ),
      );
      final handler = UpsertLegalProfileCommandHandler(
        commandGateway: gateway,
      );
      final result = await handler.handle(
        UpsertLegalProfileCommand(
          tenantId: 'org-001',
          legalEntityType: 'ENTERPRISE',
          legalName: 'Other',
          taxCode: '0123456789',
          registeredAddressText: null,
          provinceCode: null,
          communeCode: null,
          expectedVersion: 1,
          allowDuplicateTaxCode: false,
        ),
      );
      expect(result.isSaved, isFalse);
      expect(result.warning?.code, DuplicateTaxCodeWarningDto.codeValue);
    });

    test('tenant_profile_stale — STATE_CHANGED from gateway', () async {
      final handler = UpdateTenantProfileCommandHandler(
        commandGateway: _ThrowingCommandGateway(
          const IamBlockedException(IamBlockedCodes.stateChanged),
        ),
      );
      expect(
        () => handler.handle(
          UpdateTenantProfileCommand(
            tenantId: 'org-001',
            displayName: 'X',
            contactEmail: 'a@b.c',
            contactPhone: '+84901234567',
            contactAddressText: 'addr',
            provinceCode: null,
            communeCode: null,
            expectedVersion: 1,
          ),
        ),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.stateChanged,
          ),
        ),
      );
    });
  });
}

extension on TenantDto {
  TenantDto copyWith({String? displayName, int? version}) {
    return TenantDto(
      tenantId: tenantId,
      displayName: displayName ?? this.displayName,
      status: status,
      version: version ?? this.version,
      businessTimezone: businessTimezone,
      baseCurrencyCode: baseCurrencyCode,
      createdAt: createdAt,
      updatedAt: updatedAt,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      contactAddressText: contactAddressText,
      provinceCode: provinceCode,
      communeCode: communeCode,
      activatedAt: activatedAt,
      legalProfile: legalProfile,
    );
  }
}

final class _RecordingReadGateway implements ITenantProfileReadGateway {
  _RecordingReadGateway(this.tenant);

  final TenantDto? tenant;
  int calls = 0;

  @override
  Future<TenantDto?> getTenant({required String tenantId}) async {
    calls++;
    return tenant;
  }
}

final class _RecordingCommandGateway implements ITenantProfileCommandGateway {
  _RecordingCommandGateway(this.result);

  final Object result;
  String? lastOp;

  @override
  Future<TenantDto> updateProfile({
    required String tenantId,
    required String displayName,
    required String? contactEmail,
    required String? contactPhone,
    required String? contactAddressText,
    required String? provinceCode,
    required String? communeCode,
    required int expectedVersion,
  }) async {
    lastOp = 'updateProfile';
    return result as TenantDto;
  }

  @override
  Future<UpsertLegalProfileResultDto> upsertLegalProfile({
    required String tenantId,
    required String legalEntityType,
    required String legalName,
    required String taxCode,
    required String? registeredAddressText,
    required String? provinceCode,
    required String? communeCode,
    required int expectedVersion,
    required bool allowDuplicateTaxCode,
  }) async {
    lastOp = 'upsertLegalProfile';
    return result as UpsertLegalProfileResultDto;
  }
}

final class _ThrowingCommandGateway implements ITenantProfileCommandGateway {
  _ThrowingCommandGateway(this.error);

  final Object error;

  @override
  Future<TenantDto> updateProfile({
    required String tenantId,
    required String displayName,
    required String? contactEmail,
    required String? contactPhone,
    required String? contactAddressText,
    required String? provinceCode,
    required String? communeCode,
    required int expectedVersion,
  }) async {
    throw error;
  }

  @override
  Future<UpsertLegalProfileResultDto> upsertLegalProfile({
    required String tenantId,
    required String legalEntityType,
    required String legalName,
    required String taxCode,
    required String? registeredAddressText,
    required String? provinceCode,
    required String? communeCode,
    required int expectedVersion,
    required bool allowDuplicateTaxCode,
  }) async {
    throw error;
  }
}
