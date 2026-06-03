import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:erp/core/di/injection.dart';
import 'package:erp/core/supabase/supabase_module.dart';
import 'package:erp/features/auth/domain/repositories/auth_repository.dart';
import 'package:erp/features/auth/domain/usecases/get_auth_state_use_case.dart';

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

void main() {
  setUp(() async {
    await getIt.reset();
  });

  test('initDependencies registers auth and shared infrastructure', () async {
    await initDependencies(supabaseModule: SupabaseModule(_FakeSupabaseClient()));

    expect(getIt.isRegistered<AuthRepository>(), isTrue);
    expect(getIt.isRegistered<GetAuthStateUseCase>(), isTrue);
  });
}
