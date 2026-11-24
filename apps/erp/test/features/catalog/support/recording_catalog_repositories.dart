import 'package:erp/features/catalog/data/models.dart';

import 'fake_catalog_repositories.dart';

class RecordingPriceRepository extends FakeProductPriceRepository {
  RecordingPriceRepository({required super.backend});

  final List<({String productId, double basePrice, String currency})>
      setManualBasePriceArgs = [];
  final List<
      ({
        String name,
        double listMarkupRatio,
        double floorMarkupRatio,
        StorePriceRuleStatus status,
      })> setStorePriceRuleArgs = [];

  @override
  Future<void> setManualBasePrice({
    required String productId,
    required double basePrice,
    String currency = 'VND',
  }) {
    calls.add('setManualBasePrice');
    setManualBasePriceArgs.add(
      (productId: productId, basePrice: basePrice, currency: currency),
    );
    return Future.value();
  }

  @override
  Future<StorePriceRuleDto> setStorePriceRule({
    required String name,
    required double listMarkupRatio,
    required double floorMarkupRatio,
    StorePriceRuleStatus status = StorePriceRuleStatus.active,
  }) {
    calls.add('setStorePriceRule');
    setStorePriceRuleArgs.add((
      name: name,
      listMarkupRatio: listMarkupRatio,
      floorMarkupRatio: floorMarkupRatio,
      status: status,
    ));
    return Future.value(
      StorePriceRuleDto(
        id: 'r1',
        tenantId: 't1',
        name: name,
        status: status,
        calculationType: StorePriceCalculationType.markup,
        listMarkupRatio: listMarkupRatio,
        floorMarkupRatio: floorMarkupRatio,
      ),
    );
  }
}

class RecordingProductRepository extends FakeProductRepository {
  RecordingProductRepository({
    required super.backend,
    required this.respond,
  });

  final ProductSearchResultDto Function(ProductSearchCriteria criteria)
      respond;
  final List<ProductSearchCriteria> criteria = [];

  @override
  Future<ProductSearchResultDto> search({
    ProductSearchCriteria? criteria,
    int limit = 50,
    int offset = 0,
  }) {
    calls.add('search');
    final c = criteria ?? ProductSearchCriteria();
    this.criteria.add(c);
    return Future.value(respond(c));
  }
}
