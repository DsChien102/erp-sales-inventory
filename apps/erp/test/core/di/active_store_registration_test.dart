import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';

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

  test('ERP registers an active store context backed by the IAM session', () async {
    await initDependencies(
      supabaseModule: SupabaseModule(_FakeSupabaseClient()),
    );

    expect(getIt<IamSession>().activeStoreId, isNull);
    expect(getIt<IActiveStoreContext>(), isA<IActiveStoreContext>());
    expect(getIt<IActiveStoreContext>(), isNot(same(getIt<IamSession>())));
  });
}
