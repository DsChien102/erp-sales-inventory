import 'package:erp/core/errors/app_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/data/product_price_repository.dart';
import 'package:erp/features/catalog/logic/edit_product_unit_price_band_cubit.dart';
import 'package:erp/features/catalog/logic/edit_product_unit_price_band_state.dart';

final class _ErrorPriceRepository extends Fake implements ProductPriceRepository {
  _ErrorPriceRepository({required this.onApplyStorePriceRule});

  final Future<void> Function({
    required String productId,
    String? productUnitId,
    String? storePriceRuleId,
    int? basePriceVersion,
    bool confirmOverwrite,
  }) onApplyStorePriceRule;

  @override
  Future<ProductUnitPriceSuggestionDto> suggestUnitPrice({
    required String productId,
    String? productUnitId,
  }) async {
    return const ProductUnitPriceSuggestionDto(
      productId: 'product-1',
      productUnitId: 'unit-box',
      unitName: 'Hộp',
      basePrice: 50000,
      currency: 'VND',
      suggestedListBeforeVat: 70000,
      suggestedFloorBeforeVat: 60000,
      storePriceRuleId: 'rule-1',
      canSuggest: true,
    );
  }

  @override
  Future<void> applyStorePriceRule({
    required String productId,
    String? productUnitId,
    String? storePriceRuleId,
    int? basePriceVersion,
    bool confirmOverwrite = false,
  }) {
    return onApplyStorePriceRule(
      productId: productId,
      productUnitId: productUnitId,
      storePriceRuleId: storePriceRuleId,
      basePriceVersion: basePriceVersion,
      confirmOverwrite: confirmOverwrite,
    );
  }
}

final class _RecordingPriceRepository extends Fake implements ProductPriceRepository {
  Map<String, dynamic>? lastSetUnitPriceBandArgs;
  Map<String, dynamic>? lastApplyStorePriceRuleArgs;

  @override
  Future<ProductUnitPriceSuggestionDto> suggestUnitPrice({
    required String productId,
    String? productUnitId,
  }) async {
    return const ProductUnitPriceSuggestionDto(
      productId: 'product-1',
      productUnitId: 'unit-box',
      unitName: 'Hộp',
      basePrice: 50000,
      currency: 'VND',
      suggestedListBeforeVat: 70000,
      suggestedFloorBeforeVat: 60000,
      storePriceRuleId: 'rule-1',
      canSuggest: true,
    );
  }

  @override
  Future<void> setUnitPriceBand({
    required String productId,
    String? productUnitId,
    PriceBandSourceType sourceType = PriceBandSourceType.manual,
    int? listBeforeVat,
    int? listAfterVat,
    int? floorBeforeVat,
    int? floorAfterVat,
    double? listMarkupRatio,
    double? floorMarkupRatio,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    ProductPriceBandStatus? status,
  }) async {
    lastSetUnitPriceBandArgs = {
      'sourceType': sourceType,
      'listBeforeVat': listBeforeVat,
      'listAfterVat': listAfterVat,
      'floorBeforeVat': floorBeforeVat,
      'floorAfterVat': floorAfterVat,
      'listMarkupRatio': listMarkupRatio,
      'floorMarkupRatio': floorMarkupRatio,
    };
  }

  @override
  Future<void> applyStorePriceRule({
    required String productId,
    String? productUnitId,
    String? storePriceRuleId,
    int? basePriceVersion,
    bool confirmOverwrite = false,
  }) async {
    lastApplyStorePriceRuleArgs = {
      'storePriceRuleId': storePriceRuleId,
      'basePriceVersion': basePriceVersion,
      'confirmOverwrite': confirmOverwrite,
    };
  }
}

void main() {
  EditProductUnitPriceBandCubit createCubit(ProductPriceRepository repository) =>
      EditProductUnitPriceBandCubit(
        productPriceRepository: repository,
        productId: 'product-1',
        productUnitId: 'unit-box',
      );

  test('loads persisted custom ratios without inferring them from prices', () async {
    final cubit = createCubit(_RecordingPriceRepository());

    await cubit.loadInitialData(
      currentSourceType: PriceBandSourceType.customConfig,
      currentListAfterVat: 99999,
      currentFloorAfterVat: 88888,
      currentListMarkupRatio: 0.35,
      currentFloorMarkupRatio: 0.15,
    );

    final state = cubit.state as EditProductUnitPriceBandLoaded;
    expect(state.selectedType, PriceBandCalculationType.customConfig);
    expect(state.customBaseMargin, 35);
    expect(state.customFloorMargin, 15);
    expect(state.calculatedListPrice, 67500);
    expect(state.calculatedFloorPrice, 57500);
    await cubit.close();
  });

  test('custom config submits decimal ratios and no manual prices', () async {
    final repository = _RecordingPriceRepository();
    final cubit = createCubit(repository);
    await cubit.loadInitialData(
      currentSourceType: PriceBandSourceType.customConfig,
      currentListMarkupRatio: 0.35,
      currentFloorMarkupRatio: 0.15,
    );

    cubit.updateCustomBaseMargin(40);
    cubit.updateCustomFloorMargin(null);
    await cubit.save();

    final args = repository.lastSetUnitPriceBandArgs!;
    expect(args['sourceType'], PriceBandSourceType.customConfig);
    expect(args['listMarkupRatio'], 0.40);
    expect(args['floorMarkupRatio'], isNull);
    expect(args['listBeforeVat'], isNull);
    expect(args['listAfterVat'], isNull);
    await cubit.close();
  });

  test('custom config remains submittable while base price is missing', () {
    const state = EditProductUnitPriceBandLoaded(
      suggestion: ProductUnitPriceSuggestionDto(
        productId: 'product-1',
        productUnitId: 'unit-box',
        unitName: 'Hộp',
        basePrice: 0,
        currency: 'VND',
        canSuggest: false,
        unavailableReason: 'Chưa thiết lập Giá cơ sở.',
      ),
      isNewPriceBand: true,
      selectedType: PriceBandCalculationType.customConfig,
      customBaseMargin: 35,
      customFloorMargin: 15,
    );

    expect(state.calculatedListPrice, isNull);
    expect(state.calculatedFloorPrice, isNull);
    expect(state.canSubmit, isTrue);
  });

  test('manual submits absolute prices without ratios', () async {
    final repository = _RecordingPriceRepository();
    final cubit = createCubit(repository);
    await cubit.loadInitialData(
      currentSourceType: PriceBandSourceType.manual,
      currentListAfterVat: 70000,
      currentFloorAfterVat: 60000,
    );

    cubit.updateManualListPrice(75000);
    await cubit.save();

    final args = repository.lastSetUnitPriceBandArgs!;
    expect(args['sourceType'], PriceBandSourceType.manual);
    expect(args['listBeforeVat'], 75000);
    expect(args['floorBeforeVat'], 60000);
    expect(args['listMarkupRatio'], isNull);
    expect(args['floorMarkupRatio'], isNull);
    await cubit.close();
  });

  test('new price band can immediately apply the active store rule', () async {
    final repository = _RecordingPriceRepository();
    final cubit = createCubit(repository);

    await cubit.loadInitialData(isNewPriceBand: true);

    final state = cubit.state as EditProductUnitPriceBandLoaded;
    expect(state.selectedType, PriceBandCalculationType.storeRule);
    expect(state.hasChanges, isFalse);
    expect(state.canSubmit, isTrue);

    await cubit.save();

    final args = repository.lastApplyStorePriceRuleArgs!;
    expect(args['storePriceRuleId'], 'rule-1');
    await cubit.close();
  });

  test('persisted store-rule band stays disabled until it changes', () async {
    final cubit = createCubit(_RecordingPriceRepository());

    await cubit.loadInitialData(
      currentSourceType: PriceBandSourceType.ruleBased,
    );

    final state = cubit.state as EditProductUnitPriceBandLoaded;
    expect(state.isNewPriceBand, isFalse);
    expect(state.hasChanges, isFalse);
    expect(state.canSubmit, isFalse);
    await cubit.close();
  });

  test('PRICE_BAND_OVERWRITE_REQUIRED emits EditProductUnitPriceBandNeedsOverwriteConfirm (H15)', () async {
    final repository = _ErrorPriceRepository(
      onApplyStorePriceRule: ({
        required productId,
        productUnitId,
        storePriceRuleId,
        basePriceVersion,
        confirmOverwrite = false,
      }) async {
        throw const AppException(
          CatalogErrorCodes.priceBandOverwriteRequired,
          details: {
            'existing_list_after_vat': 120000,
            'existing_floor_after_vat': 100000,
          },
        );
      },
    );

    final cubit = createCubit(repository);
    await cubit.loadInitialData(isNewPriceBand: true);
    await cubit.save();

    expect(cubit.state, isA<EditProductUnitPriceBandNeedsOverwriteConfirm>());
    final confirmState = cubit.state as EditProductUnitPriceBandNeedsOverwriteConfirm;
    expect(confirmState.existingListAfterVat, 120000);
    expect(confirmState.existingFloorAfterVat, 100000);
    await cubit.close();
  });

  test('round_trip_vat_price_calculation', () async {
    final repository = _RecordingPriceRepository();
    final cubit = createCubit(repository);

    // Initial basePrice = 50000 in suggestion
    await cubit.loadInitialData(
      currentSourceType: PriceBandSourceType.customConfig,
      currentListMarkupRatio: 0.20,
      currentFloorMarkupRatio: 0.10,
    );

    var state = cubit.state as EditProductUnitPriceBandLoaded;
    // 50000 * 1.20 = 60000; 50000 * 1.10 = 55000
    expect(state.calculatedListPrice, 60000);
    expect(state.calculatedFloorPrice, 55000);

    // Switch to manual mode
    cubit.changeCalculationType(PriceBandCalculationType.manual);
    cubit.updateManualListPrice(65000);
    cubit.updateManualFloorPrice(58000);

    state = cubit.state as EditProductUnitPriceBandLoaded;
    expect(state.calculatedListPrice, 65000);
    expect(state.calculatedFloorPrice, 58000);

    await cubit.save();
    final args = repository.lastSetUnitPriceBandArgs!;
    expect(args['sourceType'], PriceBandSourceType.manual);
    expect(args['listBeforeVat'], 65000);
    expect(args['floorBeforeVat'], 58000);

    await cubit.close();
  });
}
