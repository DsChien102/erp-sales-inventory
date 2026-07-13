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

  Future<void> loadInitialData() async {
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

      emit(
        EditProductUnitPriceBandLoaded(
          suggestion: suggestion,
          selectedType: initialType,
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

  Future<void> save({bool confirmAcknowledgeWarnings = false}) async {
    if (state is! EditProductUnitPriceBandLoaded) return;
    final currentState = state as EditProductUnitPriceBandLoaded;

    if (!currentState.canSubmit) {
      emit(currentState.copyWith(error: 'Vui lòng kiểm tra lại thông tin giá.'));
      return;
    }

    emit(currentState.copyWith(isSubmitting: true, clearError: true));

    try {
      final tenantId = await executionContext.requireTenantId();
      final command = SetProductUnitPriceBandCommand(
        tenantId: tenantId,
        productId: productId,
        productUnitId: productUnitId,
        listBeforeVat: currentState.calculatedListPrice!,
        listAfterVat: currentState.calculatedListPrice!,
        floorBeforeVat: currentState.calculatedFloorPrice,
        sourceType: currentState.selectedType == PriceBandCalculationType.storeRule
            ? PriceBandSourceType.ruleBased
            : PriceBandSourceType.manual,
        storePriceRuleId: currentState.selectedType == PriceBandCalculationType.storeRule
            ? currentState.suggestion.storePriceRuleId
            : null,
        confirmAcknowledgeWarnings: confirmAcknowledgeWarnings,
      );

      await moduleMediator.executeCommandAsync(command);
      emit(EditProductUnitPriceBandSuccess());
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
}
