import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_application/testing.dart';
import 'package:vet45_sales_infrastructure/infrastructure.dart';

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

  test('ERP DI source wires SalesStartup and omits SalesFeShellModule', () {
    final source = File(
      '${_findRepoRoot().path}/apps/erp/lib/core/di/injection.dart',
    ).readAsStringSync();

    expect(source, contains('SalesStartup.initialize('));
    expect(source, contains('vet45_sales_infrastructure'));
    expect(source, isNot(contains('SalesFeShellModule')));
    expect(source, isNot(contains('SalesFeShell')));
  });

  test('initDependencies registers real SalesStartup module', () async {
    await initDependencies(
      supabaseModule: SupabaseModule(_FakeSupabaseClient()),
    );

    expect(getIt.isRegistered<ISalesModule>(), isTrue);
    expect(getIt<ISalesModule>(), isA<SalesModule>());
    expect(getIt<ISalesModule>(), isNot(isA<SalesFeShellModule>()));
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
  throw StateError('Unable to locate the Vet45 repository root');
}
