import 'package:erp/core/session/models/session_principal.dart';
import 'package:erp/core/session/session_contracts.dart';
import 'package:erp/core/session/session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_shared_application/application.dart';

import '../../features/iam/support/fake_iam_backend.dart';
import 'fake_session_repository.dart';

SessionPrincipal _principal({
  String role = 'staff',
  bool isOwner = false,
  List<String> permissions = const [],
}) {
  return SessionPrincipal(
    userId: 'user-1',
    tenantId: 'org-001',
    activeStoreId: 'store-1',
    role: role,
    isOwner: isOwner,
    permissions: permissions,
  );
}

Matcher _denied(String code) => throwsA(
  isA<ApplicationException>().having((e) => e.message, 'message', 'Permission denied: $code'),
);

void main() {
  group('CoreExecutionContext', () {
    test('reads user and tenant from the store', () async {
      final store = SessionStore()..apply(_principal());
      final context = CoreExecutionContext(store: store);

      expect(await context.requireUserId(), 'user-1');
      expect(await context.requireTenantId(), 'org-001');
      expect(context.userId, 'user-1');
      expect(context.tenantId, 'org-001');
    });

    test('keeps the legacy error strings when nothing is selected', () async {
      final context = CoreExecutionContext(store: SessionStore());

      await expectLater(
        context.requireUserId(),
        throwsA(isA<ApplicationException>().having((e) => e.message, 'message', 'User is required')),
      );
      await expectLater(
        context.requireTenantId(),
        throwsA(
          isA<ApplicationException>().having((e) => e.message, 'message', 'Tenant is required'),
        ),
      );
    });

    test('correlation id is stable for one context and differs between contexts', () {
      final store = SessionStore();
      final first = CoreExecutionContext(store: store);
      final second = CoreExecutionContext(store: store);

      expect(first.correlationId, isNotEmpty);
      expect(first.correlationId, first.correlationId);
      expect(first.correlationId, isNot(second.correlationId));
    });
  });

  group('CorePermissionChecker', () {
    late FakeSessionRepository repository;

    CorePermissionChecker checkerFor(SessionStore store) {
      return CorePermissionChecker(
        store: store,
        repository: repository,
        executionContext: CoreExecutionContext(store: store),
      );
    }

    setUp(() {
      repository = FakeSessionRepository(scenario: FakeIamScenario.tenantsMulti);
    });

    test('an Owner passes without any tenant RPC', () async {
      final store = SessionStore()..apply(_principal(isOwner: true));

      await checkerFor(store).require('catalog.product.create');

      expect(repository.permissionChecks, isEmpty);
    });

    test('a member with a resolved role passes without any tenant RPC', () async {
      final store = SessionStore()..apply(_principal());

      await checkerFor(store).require('catalog.product.create');

      expect(repository.permissionChecks, isEmpty);
    });

    test('when the local snapshot lacks the permission it asks iam.has_permission', () async {
      final store = _LocalDenyStore()..apply(_principal());

      await checkerFor(store).require('catalog.product.create');

      expect(repository.permissionChecks, [
        (tenantId: 'org-001', permission: 'catalog.product.create'),
      ]);
    });

    test('the RPC refusing the permission raises Permission denied', () async {
      final store = _LocalDenyStore()..apply(_principal());
      repository.permissionGranted = false;

      await expectLater(
        checkerFor(store).require('catalog.product.create'),
        _denied('catalog.product.create'),
      );
    });

    test('without a tenant it fails with Tenant is required and makes no RPC', () async {
      final store = SessionStore()..applyAuthenticatedUser('user-1');

      await expectLater(
        checkerFor(store).require('catalog.product.create'),
        throwsA(
          isA<ApplicationException>().having((e) => e.message, 'message', 'Tenant is required'),
        ),
      );
      expect(repository.permissionChecks, isEmpty);
    });
  });

  group('CoreTenantAccessChecker', () {
    test('a member of the tenant passes', () async {
      final repository = FakeSessionRepository(scenario: FakeIamScenario.tenantsMulti);
      final checker = CoreTenantAccessChecker(repository: repository);

      await checker.ensureAccess('org-001');
    });

    test('a non-member is denied with the tenant id in the message', () async {
      final repository = FakeSessionRepository(scenario: FakeIamScenario.tenantsMulti);
      final checker = CoreTenantAccessChecker(repository: repository);

      await expectLater(
        checker.ensureAccess('org-unknown'),
        throwsA(
          isA<ApplicationException>().having(
            (e) => e.message,
            'message',
            'Tenant access denied: org-unknown',
          ),
        ),
      );
    });
  });
}

/// Store mà ảnh phiên cục bộ không có quyền nào: mô phỏng ngày luật tạm BR-52 được gỡ.
final class _LocalDenyStore extends SessionStore {
  @override
  bool hasPermission(String code) => false;
}
