import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_infrastructure/infrastructure.dart';

final class _FakeGoTrueClient implements GoTrueClient {
  @override
  User? get currentUser => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final class _FakeSupabaseClient implements SupabaseClient {
  final _FakeGoTrueClient _auth = _FakeGoTrueClient();

  @override
  GoTrueClient get auth => _auth;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  test('Catalog startup registers the sales read gateway and generated query wiring', () {
    final container = GetIt.asNewInstance();
    CatalogStartup.initializeForTesting(
      supabase: _FakeSupabaseClient(),
      container: container,
    );

    expect(container.isRegistered<ICatalogSalesReadGateway>(), isTrue);
    expect(
      () => container.get<SearchSellableProductsQueryValidator>(),
      returnsNormally,
    );
    expect(
      () => container.get<ResolveSellableBarcodeQueryValidator>(),
      returnsNormally,
    );
    expect(
      () => container.get<ListSellableProductUnitsQueryValidator>(),
      returnsNormally,
    );
  });
}
