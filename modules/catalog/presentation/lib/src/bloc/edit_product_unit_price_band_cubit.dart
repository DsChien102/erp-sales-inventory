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
    PriceBandSourceType? currentSourceType,
    bool isCustomOverride = false,
    int? currentListBeforeVat,
    int? currentFloorBeforeVat,
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

      PriceBandCalculationType initialType = PriceBandCalculationType.storeRule;
      if (currentSourceType == PriceBandSourceType.manual) {
        if (isCustomOverride) {
          initialType = PriceBandCalculationType.customConfig;
        } else {
          initialType = PriceBandCalculationType.manual;
        }
      }

      double? initialCustomBaseMargin;
      double? initialCustomFloorMargin;
      if (isCustomOverride && suggestion.basePrice > 0) {
        if (currentListBeforeVat != null) {
          initialCustomBaseMargin =
              ((currentListBeforeVat - suggestion.basePrice) / suggestion.basePrice * 100);
        }
        if (currentFloorBeforeVat != null) {
          initialCustomFloorMargin =
              ((currentFloorBeforeVat - suggestion.basePrice) / suggestion.basePrice * 100);
        }
      }

      emit(
        EditProductUnitPriceBandLoaded(
          suggestion: suggestion,
          selectedType: initialType,
          initialSelectedType: initialType,
          customBaseMargin: initialCustomBaseMargin,
          customFloorMargin: initialCustomFloorMargin,
          manualListPrice: currentListBeforeVat,
          manualFloorPrice: currentFloorBeforeVat,
          initialCustomBaseMargin: initialCustomBaseMargin,
          initialCustomFloorMargin: initialCustomFloorMargin,
          initialManualListPrice: currentListBeforeVat?.toDouble(),
          initialManualFloorPrice: currentFloorBeforeVat?.toDouble(),
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

  void updateCustomBaseMargin(double margin) {
    if (state is EditProductUnitPriceBandLoaded) {
      final currentState = state as EditProductUnitPriceBandLoaded;
      emit(currentState.copyWith(customBaseMargin: margin, clearError: true));
    }
  }

  void updateCustomFloorMargin(double margin) {
    if (state is EditProductUnitPriceBandLoaded) {
      final currentState = state as EditProductUnitPriceBandLoaded;
      emit(currentState.copyWith(customFloorMargin: margin, clearError: true));
    }
  }

  void updateManualListPrice(int price) {
    if (state is EditProductUnitPriceBandLoaded) {
      final currentState = state as EditProductUnitPriceBandLoaded;
      emit(currentState.copyWith(manualListPrice: price, clearError: true));
    }
  }

  void updateManualFloorPrice(int price) {
    if (state is EditProductUnitPriceBandLoaded) {
      final currentState = state as EditProductUnitPriceBandLoaded;
      emit(currentState.copyWith(manualFloorPrice: price, clearError: true));
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
        final command = SetProductUnitPriceBandCommand(
          tenantId: tenantId,
          productId: productId,
          productUnitId: productUnitId,
          listBeforeVat: currentState.calculatedListPrice!,
          listAfterVat: currentState.calculatedListPrice!,
          floorBeforeVat: currentState.calculatedFloorPrice,
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
          existingListBeforeVat: e.existingListBeforeVat,
          existingFloorBeforeVat: e.existingFloorBeforeVat,
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
