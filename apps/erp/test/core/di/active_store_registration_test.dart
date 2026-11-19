import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:erp/core/session/models/session_principal.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/session/session_store.dart';
import 'package:c45_shared_application/application.dart';

import 'package:erp/core/di/injection.dart';
import 'package:erp/core/supabase/supabase_module.dart';

class _FakeGoTrueClient extends Fake implements GoTrueClient {
  @override
  User? get currentUser => null;

  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {
  @override
  GoTrueClient get auth => _FakeGoTrueClient();
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await getIt.reset();
  });

  test('ERP resolves the active store from the one session store', () async {
    await initDependencies(
      supabaseModule: SupabaseModule(_FakeSupabaseClient()),
    );

    final store = getIt<SessionStore>();
    expect(store.activeStoreId, isNull);
    expect(getIt<SessionController>().activeStoreId, isNull);

    store.apply(
      const SessionPrincipal(
        userId: 'user-1',
        tenantId: 'org-001',
        activeStoreId: 'store-1',
        role: 'staff',
        isOwner: false,
        permissions: [],
      ),
    );

    expect(getIt<SessionController>().activeStoreId, 'store-1');
    expect(await getIt<SessionController>().requireActiveStoreId(), 'store-1');
    expect(await getIt<IExecutionContext>().requireTenantId(), 'org-001');
  });
}
