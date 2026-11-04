import 'package:erp/core/errors/app_exception.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models.dart';
import '../data/product_price_repository.dart';
import 'catalog_error_messages.dart';
import 'edit_product_unit_price_band_state.dart';

class EditProductUnitPriceBandCubit extends Cubit<EditProductUnitPriceBandState> {
  EditProductUnitPriceBandCubit({
    required ProductPriceRepository productPriceRepository,
    required this.productId,
    this.productUnitId,
  })  : _productPriceRepository = productPriceRepository,
        super(EditProductUnitPriceBandInitial());

  final ProductPriceRepository _productPriceRepository;
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
      final suggestion = await _productPriceRepository.suggestUnitPrice(
        productId: productId,
        productUnitId: productUnitId,
      );

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
          error: catalogErrorMessage(e, fallback: 'Không thể tải gợi ý giá.'),
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
  }) async {
    if (state is! EditProductUnitPriceBandLoaded) return;
    final currentState = state as EditProductUnitPriceBandLoaded;

    if (!currentState.canSubmit) {
      emit(currentState.copyWith(error: 'Vui lòng kiểm tra lại thông tin giá.'));
      return;
    }

    emit(currentState.copyWith(isSubmitting: true, clearError: true));

    try {
      if (currentState.selectedType == PriceBandCalculationType.storeRule) {
        await _productPriceRepository.applyStorePriceRule(
          productId: productId,
          productUnitId: productUnitId,
          storePriceRuleId: currentState.suggestion.storePriceRuleId,
          basePriceVersion: currentState.suggestion.basePriceVersion,
          confirmOverwrite: confirmOverwrite,
        );
      } else {
        if (currentState.selectedType == PriceBandCalculationType.customConfig) {
          await _productPriceRepository.setUnitPriceBand(
            productId: productId,
            productUnitId: productUnitId,
            sourceType: PriceBandSourceType.customConfig,
            listMarkupRatio: currentState.customBaseMargin! / 100,
            floorMarkupRatio: currentState.customFloorMargin == null
                ? null
                : currentState.customFloorMargin! / 100,
          );
        } else {
          await _productPriceRepository.setUnitPriceBand(
            productId: productId,
            productUnitId: productUnitId,
            listBeforeVat: currentState.manualListPrice!,
            listAfterVat: currentState.manualListPrice!,
            floorBeforeVat: currentState.manualFloorPrice,
            floorAfterVat: currentState.manualFloorPrice,
            sourceType: PriceBandSourceType.manual,
          );
        }
      }
      emit(EditProductUnitPriceBandSuccess());
    } on AppException catch (e) {
      if (e.code == CatalogErrorCodes.priceBandOverwriteRequired) {
        final existingList = (e.details?['existing_list_after_vat'] as num?)?.toInt();
        final existingFloor = (e.details?['existing_floor_after_vat'] as num?)?.toInt();
        emit(
          EditProductUnitPriceBandNeedsOverwriteConfirm(
            loaded: currentState.copyWith(isSubmitting: false, clearError: true),
            existingListAfterVat: existingList,
            existingFloorAfterVat: existingFloor,
          ),
        );
        return;
      }
      emit(
        currentState.copyWith(
          isSubmitting: false,
          error: catalogErrorMessage(e),
        ),
      );
    } catch (e) {
      emit(
        currentState.copyWith(
          isSubmitting: false,
          error: catalogErrorMessage(e),
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
