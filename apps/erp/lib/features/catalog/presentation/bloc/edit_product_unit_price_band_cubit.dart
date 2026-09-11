import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'edit_product_unit_price_band_state.dart';

class EditProductUnitPriceBandCubit extends Cubit<EditProductUnitPriceBandState> {
  EditProductUnitPriceBandCubit({
    required this.moduleMediator,
    required this.executionContext,
    required this.productId,
    this.productUnitId,
  }) : super(EditProductUnitPriceBandInitial());

  final IModuleMediator moduleMediator;
  final IExecutionContext executionContext;
  final String productId;
  final String? productUnitId;

  Future<void> loadInitialData({
    bool isNewPriceBand = false,
    PriceBandSourceType? currentSourceType,
    int? currentListAfterVat,
    int? currentFloorAfterVat,
    double? currentListMarkupRatio,
    double? currentFloorMarkupRatio,
  }) async {
    emit(EditProductUnitPriceBandLoading());
    try {
      final tenantId = await executionContext.requireTenantId();
      final query = SuggestProductUnitPriceQuery(
        tenantId: tenantId,
        productId: productId,
        productUnitId: productUnitId,
      );
      final suggestion = await moduleMediator.executeQueryAsync(query);

      final initialType = switch (currentSourceType) {
        PriceBandSourceType.customConfig => PriceBandCalculationType.customConfig,
        PriceBandSourceType.manual => PriceBandCalculationType.manual,
        _ => PriceBandCalculationType.storeRule,
      };
      final initialCustomBaseMargin = currentListMarkupRatio == null
          ? null
          : currentListMarkupRatio * 100;
      final initialCustomFloorMargin = currentFloorMarkupRatio == null
          ? null
          : currentFloorMarkupRatio * 100;

      emit(
        EditProductUnitPriceBandLoaded(
          suggestion: suggestion,
          isNewPriceBand: isNewPriceBand,
          selectedType: initialType,
          initialSelectedType: initialType,
          customBaseMargin: initialCustomBaseMargin,
          customFloorMargin: initialCustomFloorMargin,
          // Manual amounts are after-VAT (UI default); submit mirrors before = after.
          manualListPrice: currentListAfterVat,
          manualFloorPrice: currentFloorAfterVat,
          initialCustomBaseMargin: initialCustomBaseMargin,
          initialCustomFloorMargin: initialCustomFloorMargin,
          initialManualListPrice: currentListAfterVat,
          initialManualFloorPrice: currentFloorAfterVat,
        ),
      );
    } catch (e) {
      emit(
        EditProductUnitPriceBandLoaded(
          suggestion: ProductUnitPriceSuggestionDto(
            productId: productId,
            basePrice: 0,
            currency: 'VND',
            canSuggest: false,
            unavailableReason: 'Không thể tải gợi ý giá.',
          ),
          isNewPriceBand: isNewPriceBand,
          selectedType: PriceBandCalculationType.storeRule,
          initialSelectedType: PriceBandCalculationType.storeRule,
          error: e.toString(),
        ),
      );
    }
  }

  void changeCalculationType(PriceBandCalculationType type) {
    if (state is EditProductUnitPriceBandLoaded) {
      final currentState = state as EditProductUnitPriceBandLoaded;
      emit(currentState.copyWith(selectedType: type, clearError: true));
    }
  }

  void updateCustomBaseMargin(double? margin) {
    if (state is EditProductUnitPriceBandLoaded) {
      final currentState = state as EditProductUnitPriceBandLoaded;
      emit(
        currentState.copyWith(
          customBaseMargin: margin,
          clearCustomBaseMargin: margin == null,
          clearError: true,
        ),
      );
    }
  }

  void updateCustomFloorMargin(double? margin) {
    if (state is EditProductUnitPriceBandLoaded) {
      final currentState = state as EditProductUnitPriceBandLoaded;
      emit(
        currentState.copyWith(
          customFloorMargin: margin,
          clearCustomFloorMargin: margin == null,
          clearError: true,
        ),
      );
    }
  }

  void updateManualListPrice(int? price) {
    if (state is EditProductUnitPriceBandLoaded) {
      final currentState = state as EditProductUnitPriceBandLoaded;
      emit(
        currentState.copyWith(
          manualListPrice: price,
          clearManualListPrice: price == null,
          clearError: true,
        ),
      );
    }
  }

  void updateManualFloorPrice(int? price) {
    if (state is EditProductUnitPriceBandLoaded) {
      final currentState = state as EditProductUnitPriceBandLoaded;
      emit(
        currentState.copyWith(
          manualFloorPrice: price,
          clearManualFloorPrice: price == null,
          clearError: true,
        ),
      );
    }
  }

  Future<void> save({
    bool confirmOverwrite = false,
    bool confirmAcknowledgeWarnings = false,
  }) async {
    if (state is! EditProductUnitPriceBandLoaded) return;
    final currentState = state as EditProductUnitPriceBandLoaded;

    if (!currentState.canSubmit) {
      emit(currentState.copyWith(error: 'Vui lòng kiểm tra lại thông tin giá.'));
      return;
    }

    emit(currentState.copyWith(isSubmitting: true, clearError: true));

    try {
      final tenantId = await executionContext.requireTenantId();
      if (currentState.selectedType == PriceBandCalculationType.storeRule) {
        await moduleMediator.executeCommandAsync(
          ApplyStorePriceRuleCommand(
            tenantId: tenantId,
            productId: productId,
            productUnitId: productUnitId,
            storePriceRuleId: currentState.suggestion.storePriceRuleId,
            basePriceVersion: currentState.suggestion.basePriceVersion,
            confirmOverwrite: confirmOverwrite,
          ),
        );
      } else {
        final command = currentState.selectedType == PriceBandCalculationType.customConfig
            ? SetProductUnitPriceBandCommand(
                tenantId: tenantId,
                productId: productId,
                productUnitId: productUnitId,
                sourceType: PriceBandSourceType.customConfig,
                listMarkupRatio: currentState.customBaseMargin! / 100,
                floorMarkupRatio: currentState.customFloorMargin == null
                    ? null
                    : currentState.customFloorMargin! / 100,
                confirmAcknowledgeWarnings: confirmAcknowledgeWarnings,
              )
            : SetProductUnitPriceBandCommand(
                tenantId: tenantId,
                productId: productId,
                productUnitId: productUnitId,
                listBeforeVat: currentState.manualListPrice!,
                listAfterVat: currentState.manualListPrice!,
                floorBeforeVat: currentState.manualFloorPrice,
                floorAfterVat: currentState.manualFloorPrice,
                sourceType: PriceBandSourceType.manual,
                confirmAcknowledgeWarnings: confirmAcknowledgeWarnings,
              );
        await moduleMediator.executeCommandAsync(command);
      }
      emit(EditProductUnitPriceBandSuccess());
    } on PriceBandOverwriteRequiredException catch (e) {
      emit(
        EditProductUnitPriceBandNeedsOverwriteConfirm(
          loaded: currentState.copyWith(isSubmitting: false, clearError: true),
          existingListAfterVat: e.existingListAfterVat,
          existingFloorAfterVat: e.existingFloorAfterVat,
        ),
      );
    } on PriceBandWarningsRequireAcknowledgmentException {
      emit(
        currentState.copyWith(
          isSubmitting: false,
          error: 'WARNING_REQUIRE_ACK', // A special flag for UI to show a dialog
        ),
      );
    } catch (e) {
      emit(
        currentState.copyWith(
          isSubmitting: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> confirmOverwrite() async {
    final currentState = state;
    if (currentState is EditProductUnitPriceBandNeedsOverwriteConfirm) {
      emit(currentState.loaded);
      await save(confirmOverwrite: true);
    }
  }

  void cancelOverwrite() {
    final currentState = state;
    if (currentState is EditProductUnitPriceBandNeedsOverwriteConfirm) {
      emit(currentState.loaded);
    }
  }
}
