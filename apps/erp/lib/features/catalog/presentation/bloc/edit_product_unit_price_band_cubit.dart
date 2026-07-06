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
      // In a real app, handle error properly
      emit(EditProductUnitPriceBandInitial()); // or Error state
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

  void updateManualListPrice(double price) {
    if (state is EditProductUnitPriceBandLoaded) {
      emit((state as EditProductUnitPriceBandLoaded).copyWith(
        manualListPrice: price,
        clearError: true,
      ));
    }
  }

  void updateManualFloorPrice(double price) {
    if (state is EditProductUnitPriceBandLoaded) {
      emit((state as EditProductUnitPriceBandLoaded).copyWith(
        manualFloorPrice: price,
        clearError: true,
      ));
    }
  }

  Future<void> submit() async {
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
            confirmOverwrite: true, // Auto confirm for now, or handle in UI
          ),
        );
      } else {
        await _moduleMediator.executeCommandAsync(
          SetProductUnitPriceBandCommand(
            tenantId: tenantId,
            productId: productId,
            productUnitId: productUnitId,
            listPrice: currentState.calculatedListPrice!,
            floorPrice: currentState.calculatedFloorPrice!,
            sourceType: PriceBandSourceType.manual,
          ),
        );
      }
      
      emit(EditProductUnitPriceBandSuccess());
    } catch (e) {
      emit(currentState.copyWith(
        isSubmitting: false,
        error: e.toString(), // or specific validation error message
      ));
    }
  }
}
