import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/session/models/session_principal.dart';
import 'package:erp/core/session/session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_shared_application/application.dart';

import '../../features/iam/support/fake_iam_backend.dart';
import 'fake_session_repository.dart';

SessionPrincipal _principal({
  String? activeStoreId,
  String role = 'staff',
  bool isOwner = false,
  List<String> permissions = const [],
}) {
  return SessionPrincipal(
    userId: 'user-1',
    tenantId: 'org-001',
    activeStoreId: activeStoreId,
    activeStoreCode: activeStoreId == null ? null : 'CH-01',
    activeStoreDisplayName: activeStoreId == null ? null : 'Cửa hàng 1',
    role: role,
    isOwner: isOwner,
    permissions: permissions,
  );
}

void main() {
  group('SessionStore', () {
    test('apply stores the principal; clear resets everything', () {
      final store = SessionStore()..apply(_principal(activeStoreId: ' store-1 ', isOwner: true));

      expect(store.userId, 'user-1');
      expect(store.tenantId, 'org-001');
      expect(store.activeStoreId, 'store-1');
      expect(store.activeStoreCode, 'CH-01');
      expect(store.activeStoreDisplayName, 'Cửa hàng 1');
      expect(store.role, 'staff');
      expect(store.isOwner, isTrue);

      store.clear();

      expect(store.userId, isNull);
      expect(store.tenantId, isNull);
      expect(store.activeStoreId, isNull);
      expect(store.activeStoreCode, isNull);
      expect(store.role, isNull);
      expect(store.isOwner, isFalse);
      expect(store.permissions, isEmpty);
    });

    test('applyAuthenticatedUser keeps only the user', () {
      final store = SessionStore()..apply(_principal(activeStoreId: 'store-1'));

      store.applyAuthenticatedUser('user-2');

      expect(store.userId, 'user-2');
      expect(store.tenantId, isNull);
      expect(store.activeStoreId, isNull);
      expect(store.role, isNull);
    });

    test('an active member has every business permission (BR-52 interim rule)', () {
      final store = SessionStore()..apply(_principal(role: 'staff'));

      expect(store.hasPermission('catalog.product.create'), isTrue);

      store.applyAuthenticatedUser('user-1');

      expect(store.hasPermission('catalog.product.create'), isFalse);
    });

    test('permissions are read-only', () {
      final store = SessionStore()..apply(_principal(permissions: const ['a']));

      expect(() => store.permissions.add('b'), throwsUnsupportedError);
    });

    group('requireActiveStoreId', () {
      test('returns the bound store without calling the server', () async {
        final repository = FakeSessionRepository(scenario: FakeIamScenario.tenantsMulti);
        final store = SessionStore(repository: repository)
          ..apply(_principal(activeStoreId: 'store-9'));

        expect(await store.requireActiveStoreId(), 'store-9');
        expect(repository.sessionContextReads, 0);
      });

      test('reloads once for parallel callers when the store is missing', () async {
        final repository = FakeSessionRepository(scenario: FakeIamScenario.tenantsMulti);
        await repository.getTenantContext('org-001');
        repository.sessionContextReads = 0;
        final store = SessionStore(repository: repository)..apply(_principal());

        final ids = await Future.wait([
          store.requireActiveStoreId(),
          store.requireActiveStoreId(),
          store.requireActiveStoreId(),
        ]);

        expect(ids, everyElement('store-org-001'));
        expect(repository.sessionContextReads, 1);
        expect(store.activeStoreId, 'store-org-001');
      });

      test('reloads again after a settled refresh when the store is cleared', () async {
        final repository = FakeSessionRepository(scenario: FakeIamScenario.tenantsMulti);
        final store = SessionStore(repository: repository)..apply(_principal());

        await store.requireActiveStoreId();
        store.apply(_principal());
        await store.requireActiveStoreId();

        expect(repository.sessionContextReads, 2);
      });

      test('without a tenant it fails and never calls the server', () async {
        final repository = FakeSessionRepository();
        final store = SessionStore(repository: repository)..applyAuthenticatedUser('user-1');

        await expectLater(
          store.requireActiveStoreId(),
          throwsA(
            isA<ApplicationException>().having(
              (e) => e.message,
              'message',
              'Tenant context is required.',
            ),
          ),
        );
        expect(repository.sessionContextReads, 0);
      });

      test('fails when the server has no session context for the tenant', () async {
        final repository = FakeSessionRepository(noTenants: true);
        final store = SessionStore(repository: repository)..apply(_principal());

        await expectLater(
          store.requireActiveStoreId(),
          throwsA(
            isA<ApplicationException>().having(
              (e) => e.message,
              'message',
              'Active store context is required.',
            ),
          ),
        );
      });

      test('a failed refresh does not stay in flight', () async {
        final repository = FakeSessionRepository(scenario: FakeIamScenario.tenantsMulti)
          ..failGetSession = true;
        final store = SessionStore(repository: repository)..apply(_principal());

        await expectLater(store.requireActiveStoreId(), throwsA(isA<AppException>()));

        repository.failGetSession = false;
        expect(await store.requireActiveStoreId(), 'store-org-001');
      });
    });
  });
}
