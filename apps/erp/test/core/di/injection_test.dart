import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:erp/core/session/session_contracts.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/session/session_store.dart';
import 'package:vet45_inventory_application/application.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_infrastructure/infrastructure.dart';
import 'package:vet45_shared_application/application.dart';

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

  test('initDependencies registers session-backed cross-cutting services', () async {
    await initDependencies(supabaseModule: SupabaseModule(_FakeSupabaseClient()));

    expect(getIt.isRegistered<SessionStore>(), isTrue);
    expect(getIt.isRegistered<SessionController>(), isTrue);
    expect(getIt<IExecutionContext>(), isA<CoreExecutionContext>());
    expect(getIt<ICurrentUser>(), isA<CoreExecutionContext>());
    expect(getIt<ICurrentTenant>(), isA<CoreExecutionContext>());
    expect(getIt<IPermissionChecker>(), isA<CorePermissionChecker>());
    expect(getIt<ITenantAccessChecker>(), isA<CoreTenantAccessChecker>());
    expect(getIt.isRegistered<ICatalogModule>(), isTrue);
    expect(getIt<ICatalogModule>(), isNot(isA<FakeCatalogModule>()));
    expect(getIt.isRegistered<IPartnerModule>(), isTrue);
    expect(getIt<IPartnerModule>(), isNot(isA<FakePartnerModule>()));
    expect(getIt.isRegistered<IEInvoiceModule>(), isTrue);
    expect(getIt<IEInvoiceModule>(), isA<EinvoiceModule>());
    expect(getIt<IEInvoiceModule>(), isNot(isA<FakeEInvoiceModule>()));
    expect(getIt.isRegistered<IInventoryModule>(), isTrue);
  });
}
