import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

/// scn_e05_u02_fr01_01 — SwitchTenantContextCommandHandler scenarios (§S2).
class _FakeCurrentTenant implements ICurrentTenant {
  _FakeCurrentTenant(this.tenantId);

  @override
  final String? tenantId;
}

class _FakePreferencePort implements IPlatformUserPreferencePort {
  String? lastSelected;

  @override
  Future<String?> getLastSelectedTenantId() async => lastSelected;

  @override
  Future<void> setLastSelectedTenantId(String? tenantId) async {
    lastSelected = tenantId;
  }
}

class _FakeSessionPort implements IIamSessionPort {
  _FakeSessionPort({this.failEstablish = false});

  String? establishedTenantId;
  final bool failEstablish;
  int establishCount = 0;

  @override
  SessionDto get snapshot => const SessionDto(isAuthenticated: true);

  @override
  void clear() {}

  @override
  void applyAuthenticatedUser(String userId) {}

  @override
  void apply(PrincipalAccessDto context) {
    establishCount++;
    if (failEstablish && establishCount == 1) {
      throw StateError('session establish failed');
    }
    establishedTenantId = context.tenantId;
  }
}

class _FailingPreferencePort implements IPlatformUserPreferencePort {
  @override
  Future<String?> getLastSelectedTenantId() async => null;

  @override
  Future<void> setLastSelectedTenantId(String? tenantId) async {
    throw StateError('preference write failed');
  }
}

class _ScenarioAccessGateway implements IIamAccessGateway {
  _ScenarioAccessGateway({
    this.switchResult,
    this.switchError,
  });

  final TenantContextDto? switchResult;
  final Object? switchError;

  @override
  Future<TenantContextDto> switchTenantContext({
    required String targetTenantId,
  }) async {
    if (switchError != null) {
      throw switchError!;
    }
    return switchResult!;
  }

  @override
  Future<TenantContextDto> getValidatedTenantContext({
    String? sessionTenantId,
  }) async => const TenantContextDto(status: TenantContextStatus.none);

  @override
  Future<List<AccessibleTenantDto>> listAccessibleTenants() async => const [];

  bool failSessionContext = false;
  bool failContextInvalid = false;

  @override
  Future<PrincipalAccessDto?> getSessionContext({String? tenantId}) async {
    if (failContextInvalid) {
      throw ApplicationException(IamBlockedCodes.contextInvalid);
    }
    if (failSessionContext) {
      throw StateError('session establish failed');
    }
    if (tenantId == null) return null;
    return PrincipalAccessDto(
      userId: 'user-1',
      tenantId: tenantId,
      activeStoreId: 'store-1',
      activeStoreCode: 'default',
      activeStoreDisplayName: 'Default',
      role: 'owner',
      isOwner: true,
      permissions: const <String>[],
    );
  }

  @override
  Future<bool> hasPermission({
    required String tenantId,
    required String permission,
  }) async => true;

  @override
  Future<bool> isMember(String tenantId) async => true;

  @override
  Future<CursorPageDto<TenantMemberDto>> listTenantMembers({
    required String tenantId,
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  }) async => const CursorPageDto<TenantMemberDto>(items: []);

  @override
  Future<List<TenantMembershipDto>> listUserTenants() async => const [];

  @override
  Future<void> assignMemberRole({
    required String tenantId,
    required String userId,
    required String role,
  }) async {}
}

void main() {
  group('scn_e05_u02_fr01_01 SwitchTenantContextCommandHandler', () {
    test('switch_ok — valid target updates preference + session', () async {
      final preference = _FakePreferencePort();
      final session = _FakeSessionPort();
      final handler = SwitchTenantContextCommandHandler(
        accessGateway: _ScenarioAccessGateway(
          switchResult: const TenantContextDto(
            status: TenantContextStatus.valid,
            tenantId: 'tenant-b',
            tenantName: 'Beta',
            roleLabel: 'staff',
            tenantStatus: TenantLifecycleStatus.active,
          ),
        ),
        preferencePort: preference,
        sessionPort: session,
        currentTenant: _FakeCurrentTenant('tenant-a'),
      );

      final result = await handler.handle(
        SwitchTenantContextCommand(targetTenantId: 'tenant-b'),
      );

      expect(result.status, TenantContextStatus.valid);
      expect(result.tenantId, 'tenant-b');
      expect(preference.lastSelected, 'tenant-b');
      expect(session.establishedTenantId, 'tenant-b');
    });

    test('switch_same_tenant — validation error', () async {
      final handler = SwitchTenantContextCommandHandler(
        accessGateway: _ScenarioAccessGateway(),
        preferencePort: _FakePreferencePort(),
        sessionPort: _FakeSessionPort(),
        currentTenant: _FakeCurrentTenant('tenant-a'),
      );

      expect(
        () => handler.handle(
          SwitchTenantContextCommand(targetTenantId: 'tenant-a'),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('switch_denied — gateway error propagates', () async {
      final preference = _FakePreferencePort();
      final handler = SwitchTenantContextCommandHandler(
        accessGateway: _ScenarioAccessGateway(
          switchError: ApplicationException('TENANT_ACCESS_DENIED'),
        ),
        preferencePort: preference,
        sessionPort: _FakeSessionPort(),
        currentTenant: _FakeCurrentTenant('tenant-a'),
      );

      await expectLater(
        handler.handle(SwitchTenantContextCommand(targetTenantId: 'tenant-x')),
        throwsA(
          isA<ApplicationException>().having(
            (e) => e.message,
            'message',
            'TENANT_ACCESS_DENIED',
          ),
        ),
      );
      expect(preference.lastSelected, isNull);
    });

    test('switch_suspended — gateway error propagates', () async {
      final handler = SwitchTenantContextCommandHandler(
        accessGateway: _ScenarioAccessGateway(
          switchError: ApplicationException('TENANT_SUSPENDED'),
        ),
        preferencePort: _FakePreferencePort(),
        sessionPort: _FakeSessionPort(),
        currentTenant: _FakeCurrentTenant('tenant-a'),
      );

      await expectLater(
        handler.handle(SwitchTenantContextCommand(targetTenantId: 'tenant-s')),
        throwsA(
          isA<ApplicationException>().having(
            (e) => e.message,
            'message',
            'TENANT_SUSPENDED',
          ),
        ),
      );
    });

    test('switch_closed — gateway error propagates', () async {
      final handler = SwitchTenantContextCommandHandler(
        accessGateway: _ScenarioAccessGateway(
          switchError: ApplicationException('TENANT_CLOSED'),
        ),
        preferencePort: _FakePreferencePort(),
        sessionPort: _FakeSessionPort(),
        currentTenant: _FakeCurrentTenant('tenant-a'),
      );

      await expectLater(
        handler.handle(SwitchTenantContextCommand(targetTenantId: 'tenant-c')),
        throwsA(
          isA<ApplicationException>().having(
            (e) => e.message,
            'message',
            'TENANT_CLOSED',
          ),
        ),
      );
    });

    test('switch_session_context_invalid — surfaces CONTEXT_INVALID', () async {
      final preference = _FakePreferencePort();
      final gateway = _ScenarioAccessGateway(
        switchResult: const TenantContextDto(
          status: TenantContextStatus.valid,
          tenantId: 'tenant-b',
          tenantName: 'Beta',
          roleLabel: 'staff',
          tenantStatus: TenantLifecycleStatus.active,
        ),
      )..failContextInvalid = true;
      final handler = SwitchTenantContextCommandHandler(
        accessGateway: gateway,
        preferencePort: preference,
        sessionPort: _FakeSessionPort(),
        currentTenant: _FakeCurrentTenant('tenant-a'),
      );

      await expectLater(
        handler.handle(SwitchTenantContextCommand(targetTenantId: 'tenant-b')),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.contextInvalid,
          ),
        ),
      );
      expect(preference.lastSelected, isNull);
    });

    test('switch_session_failure — preference unchanged', () async {
      final preference = _FakePreferencePort();
      final handler = SwitchTenantContextCommandHandler(
        accessGateway: _ScenarioAccessGateway(
          switchResult: const TenantContextDto(
            status: TenantContextStatus.valid,
            tenantId: 'tenant-b',
            tenantName: 'Beta',
            roleLabel: 'staff',
            tenantStatus: TenantLifecycleStatus.active,
          ),
        ),
        preferencePort: preference,
        sessionPort: _FakeSessionPort(failEstablish: true),
        currentTenant: _FakeCurrentTenant('tenant-a'),
      );

      await expectLater(
        handler.handle(SwitchTenantContextCommand(targetTenantId: 'tenant-b')),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.systemError,
          ),
        ),
      );
      expect(preference.lastSelected, isNull);
    });

    test('switch_preference_failure — restores previous session', () async {
      final session = _FakeSessionPort();
      final handler = SwitchTenantContextCommandHandler(
        accessGateway: _ScenarioAccessGateway(
          switchResult: const TenantContextDto(
            status: TenantContextStatus.valid,
            tenantId: 'tenant-b',
            tenantName: 'Beta',
            roleLabel: 'staff',
            tenantStatus: TenantLifecycleStatus.active,
          ),
        ),
        preferencePort: _FailingPreferencePort(),
        sessionPort: session,
        currentTenant: _FakeCurrentTenant('tenant-a'),
      );

      await expectLater(
        handler.handle(SwitchTenantContextCommand(targetTenantId: 'tenant-b')),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.systemError,
          ),
        ),
      );
      expect(session.establishedTenantId, 'tenant-a');
      expect(session.establishCount, 2);
    });
  });
}
