import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/session/session_store.dart';
import 'package:erp/features/catalog/data/custom_field_repository.dart';
import 'package:erp/features/catalog/data/measurement_unit_repository.dart';
import 'package:erp/features/catalog/data/product_price_repository.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:erp/features/dashboard/data/default_pair_repository.dart';
import 'package:erp/features/einvoice/data/einvoice_configuration_repository.dart';
import 'package:erp/features/einvoice/data/einvoice_processor_trigger.dart';
import 'package:erp/features/einvoice/data/einvoice_repository.dart';
import 'package:erp/features/einvoice/data/invoice_document_signed_urls.dart';

import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_repository.dart';
import 'package:erp/features/partner/data/partner_repository.dart';
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
    expect(getIt.isRegistered<ProductRepository>(), isTrue);
    expect(getIt.isRegistered<MeasurementUnitRepository>(), isTrue);
    expect(getIt.isRegistered<CustomFieldRepository>(), isTrue);
    expect(getIt.isRegistered<ProductPriceRepository>(), isTrue);
    expect(getIt.isRegistered<PartnerRepository>(), isTrue);
    expect(getIt.isRegistered<SupplierRebateRepository>(), isTrue);
    expect(getIt.isRegistered<EInvoiceProcessorTrigger>(), isTrue);
    expect(getIt.isRegistered<EInvoiceConfigurationRepository>(), isTrue);
    expect(getIt.isRegistered<InvoiceDocumentSignedUrls>(), isTrue);
    expect(getIt.isRegistered<EInvoiceRepository>(), isTrue);
    expect(getIt.isRegistered<DefaultPairRepository>(), isTrue);
  });

  test('initDependencies gives SessionController a stable correlation id', () async {
    await initDependencies(supabaseModule: SupabaseModule(_FakeSupabaseClient()));

    expect(getIt<SessionController>().correlationId.trim(), isNotEmpty);
  });

  test('ERP DI source has no einvoice module', () {
    final repoRoot = _findRepoRoot();
    final diFile = File('${repoRoot.path}/apps/erp/lib/core/di/injection.dart');
    final content = diFile.readAsStringSync();

    expect(content.contains('c45_einvoice_'), isFalse);
    expect(content.contains('EinvoiceStartup'), isFalse);
    expect(content.contains('IEInvoiceModule'), isFalse);
    expect(content.contains('CorePermissionChecker'), isFalse);
    expect(content.contains('CoreTenantAccessChecker'), isFalse);
  });
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;
  while (!Directory('${current.path}/supabase/migrations').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate Mosaic Retail workspace root');
    }
    current = parent;
  }
  return current;
}
