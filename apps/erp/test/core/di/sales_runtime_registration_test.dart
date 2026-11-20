import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:erp/core/di/injection.dart';
import 'package:erp/core/supabase/supabase_module.dart';
import 'package:erp/features/sales/data/return_exchange_repository.dart';
import 'package:erp/features/sales/data/sales_cancellation_repository.dart';
import 'package:erp/features/sales/data/sales_checkout_repository.dart';
import 'package:erp/features/sales/data/sales_draft_repository.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/data/sales_payment_repository.dart';
import 'package:erp/features/sales/data/sales_receipt_repository.dart';

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

  test('ERP DI source has no sales module', () {
    final source = File(
      '${_findRepoRoot().path}/apps/erp/lib/core/di/injection.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('SalesStartup')));
    expect(source, isNot(contains('ISalesModule')));
    expect(source, isNot(contains('c45_sales_')));
  });

  test('initDependencies registers sales repositories', () async {
    await initDependencies(
      supabaseModule: SupabaseModule(_FakeSupabaseClient()),
    );

    expect(getIt.isRegistered<SalesDraftRepository>(), isTrue);
    expect(getIt.isRegistered<SalesCheckoutRepository>(), isTrue);
    expect(getIt.isRegistered<SalesPaymentRepository>(), isTrue);
    expect(getIt.isRegistered<SalesOrderRepository>(), isTrue);
    expect(getIt.isRegistered<SalesReceiptRepository>(), isTrue);
    expect(getIt.isRegistered<SalesCancellationRepository>(), isTrue);
    expect(getIt.isRegistered<ReturnExchangeRepository>(), isTrue);
  });
}

Directory _findRepoRoot() {
  var directory = Directory.current.absolute;
  while (directory.parent.path != directory.path) {
    if (File('${directory.path}/AGENTS.md').existsSync() &&
        Directory('${directory.path}/apps/erp').existsSync()) {
      return directory;
    }
    directory = directory.parent;
  }
  throw StateError('Unable to locate the Mosaic Retail repository root');
}
