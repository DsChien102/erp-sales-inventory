import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_infrastructure/infrastructure.dart';

class _FakeGoTrueClient implements GoTrueClient {
  @override
  User? get currentUser => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeSupabaseClient implements SupabaseClient {
  final _FakeGoTrueClient _auth = _FakeGoTrueClient();

  @override
  GoTrueClient get auth => _auth;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  test('initializeForTesting wires catalog module', () {
    final module = CatalogStartup.initializeForTesting(
      supabase: _FakeSupabaseClient(),
    );

    expect(module, isA<ICatalogModule>());
  });
}
