import 'package:erp/core/session/models/session_principal.dart';
import 'package:erp/core/session/session_contracts.dart';
import 'package:erp/core/session/session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_shared_application/application.dart';

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
}
