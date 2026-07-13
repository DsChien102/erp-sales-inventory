import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'edit_product_unit_price_band_state.dart';

class EditProductUnitPriceBandCubit extends Cubit<EditProductUnitPriceBandState> {
  EditProductUnitPriceBandCubit({
    required this.tenantId,
    required this.productId,
    this.productUnitId,
    required IModuleMediator moduleMediator,
  })  : _moduleMediator = moduleMediator,
        super(EditProductUnitPriceBandInitial());

  final String tenantId;
  final String productId;
  final String? productUnitId;
  final IModuleMediator _moduleMediator;

  Future<void> loadInitialData() async {
    emit(EditProductUnitPriceBandLoading());

    try {
      final suggestion = await _moduleMediator.executeQueryAsync(
        SuggestProductUnitPriceQuery(
          tenantId: tenantId,
          productId: productId,
          productUnitId: productUnitId,
        ),
      );

      emit(EditProductUnitPriceBandLoaded(
        suggestion: suggestion,
        selectedType: PriceBandCalculationType.storeRule,
      ));
    } catch (e) {
      emit(EditProductUnitPriceBandInitial());
    }
  }

  void changeCalculationType(PriceBandCalculationType type) {
    if (state is EditProductUnitPriceBandLoaded) {
      emit((state as EditProductUnitPriceBandLoaded).copyWith(
        selectedType: type,
        clearError: true,
      ));
    }
  }

  void updateCustomBaseMargin(double margin) {
    if (state is EditProductUnitPriceBandLoaded) {
      emit((state as EditProductUnitPriceBandLoaded).copyWith(
        customBaseMargin: margin,
        clearError: true,
      ));
    }
  }

  void updateCustomFloorMargin(double margin) {
    if (state is EditProductUnitPriceBandLoaded) {
      emit((state as EditProductUnitPriceBandLoaded).copyWith(
        customFloorMargin: margin,
        clearError: true,
      ));
    }
  }

  void updateManualListPrice(int price) {
    if (state is EditProductUnitPriceBandLoaded) {
      emit((state as EditProductUnitPriceBandLoaded).copyWith(
        manualListPrice: price,
        clearError: true,
      ));
    }
  }

  void updateManualFloorPrice(int price) {
    if (state is EditProductUnitPriceBandLoaded) {
      emit((state as EditProductUnitPriceBandLoaded).copyWith(
        manualFloorPrice: price,
        clearError: true,
      ));
    }
  }

  Future<void> submit({bool confirmOverwrite = false}) async {
    final currentState = state;
    if (currentState is! EditProductUnitPriceBandLoaded || !currentState.canSubmit) {
      return;
    }

    emit(currentState.copyWith(isSubmitting: true, clearError: true));

    try {
      if (currentState.selectedType == PriceBandCalculationType.storeRule) {
        await _moduleMediator.executeCommandAsync(
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
        await _moduleMediator.executeCommandAsync(
          SetProductUnitPriceBandCommand(
            tenantId: tenantId,
            productId: productId,
            productUnitId: productUnitId,
            listBeforeVat: currentState.calculatedListPrice!,
            listAfterVat: currentState.calculatedListPrice!,
            floorBeforeVat: currentState.calculatedFloorPrice,
            sourceType: PriceBandSourceType.manual,
          ),
        );
      }

      emit(EditProductUnitPriceBandSuccess());
    } on PriceBandOverwriteRequiredException catch (e) {
      emit(EditProductUnitPriceBandNeedsOverwriteConfirm(
        loaded: currentState.copyWith(isSubmitting: false, clearError: true),
        existingListBeforeVat: e.existingListBeforeVat,
        existingFloorBeforeVat: e.existingFloorBeforeVat,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        isSubmitting: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> confirmOverwrite() async {
    final currentState = state;
    if (currentState is EditProductUnitPriceBandNeedsOverwriteConfirm) {
      emit(currentState.loaded);
      await submit(confirmOverwrite: true);
    }
  }

  void cancelOverwrite() {
    final currentState = state;
    if (currentState is EditProductUnitPriceBandNeedsOverwriteConfirm) {
      emit(currentState.loaded);
    }
  }
}
