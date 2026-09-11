import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:erp/features/catalog/presentation.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

final class _RecordingMediator implements IModuleMediator {
  ICommand<Object?>? lastCommand;

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is SuggestProductUnitPriceQuery) {
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
          )
          as TResult;
    }
    throw UnimplementedError();
  }

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    lastCommand = command as ICommand<Object?>;
    return null as TResult;
  }
}

void main() {
  EditProductUnitPriceBandCubit createCubit(_RecordingMediator mediator) =>
      EditProductUnitPriceBandCubit(
        moduleMediator: mediator,
        executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
        productId: 'product-1',
        productUnitId: 'unit-box',
      );

  test('loads persisted custom ratios without inferring them from prices', () async {
    final cubit = createCubit(_RecordingMediator());

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
    final mediator = _RecordingMediator();
    final cubit = createCubit(mediator);
    await cubit.loadInitialData(
      currentSourceType: PriceBandSourceType.customConfig,
      currentListMarkupRatio: 0.35,
      currentFloorMarkupRatio: 0.15,
    );

    cubit.updateCustomBaseMargin(40);
    cubit.updateCustomFloorMargin(null);
    await cubit.save();

    final command = mediator.lastCommand as SetProductUnitPriceBandCommand;
    expect(command.sourceType, PriceBandSourceType.customConfig);
    expect(command.listMarkupRatio, 0.40);
    expect(command.floorMarkupRatio, isNull);
    expect(command.listBeforeVat, isNull);
    expect(command.listAfterVat, isNull);
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
    final mediator = _RecordingMediator();
    final cubit = createCubit(mediator);
    await cubit.loadInitialData(
      currentSourceType: PriceBandSourceType.manual,
      currentListAfterVat: 70000,
      currentFloorAfterVat: 60000,
    );

    cubit.updateManualListPrice(75000);
    await cubit.save();

    final command = mediator.lastCommand as SetProductUnitPriceBandCommand;
    expect(command.sourceType, PriceBandSourceType.manual);
    expect(command.listBeforeVat, 75000);
    expect(command.floorBeforeVat, 60000);
    expect(command.listMarkupRatio, isNull);
    expect(command.floorMarkupRatio, isNull);
    await cubit.close();
  });

  test('new price band can immediately apply the active store rule', () async {
    final mediator = _RecordingMediator();
    final cubit = createCubit(mediator);

    await cubit.loadInitialData(isNewPriceBand: true);

    final state = cubit.state as EditProductUnitPriceBandLoaded;
    expect(state.selectedType, PriceBandCalculationType.storeRule);
    expect(state.hasChanges, isFalse);
    expect(state.canSubmit, isTrue);

    await cubit.save();

    final command = mediator.lastCommand as ApplyStorePriceRuleCommand;
    expect(command.storePriceRuleId, 'rule-1');
    await cubit.close();
  });

  test('persisted store-rule band stays disabled until it changes', () async {
    final cubit = createCubit(_RecordingMediator());

    await cubit.loadInitialData(
      currentSourceType: PriceBandSourceType.ruleBased,
    );

    final state = cubit.state as EditProductUnitPriceBandLoaded;
    expect(state.isNewPriceBand, isFalse);
    expect(state.hasChanges, isFalse);
    expect(state.canSubmit, isFalse);
    await cubit.close();
  });
}
