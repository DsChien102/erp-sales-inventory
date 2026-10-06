import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
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

  test('initDependencies registers IAM cross-cutting services', () async {
    await initDependencies(supabaseModule: SupabaseModule(_FakeSupabaseClient()));

    expect(getIt.isRegistered<IIamModule>(), isTrue);
    expect(getIt.isRegistered<IExecutionContext>(), isTrue);
    expect(getIt.isRegistered<IPermissionChecker>(), isTrue);
    expect(getIt.isRegistered<ITenantAccessChecker>(), isTrue);
    expect(getIt.isRegistered<IamSession>(), isTrue);
    expect(getIt.isRegistered<ICurrentUser>(), isTrue);
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
