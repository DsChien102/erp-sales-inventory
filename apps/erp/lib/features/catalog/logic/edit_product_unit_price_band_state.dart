import 'package:equatable/equatable.dart';
import 'package:erp/features/catalog/data/models.dart';

enum PriceBandCalculationType {
  storeRule,
  customConfig,
  manual,
}

abstract class EditProductUnitPriceBandState extends Equatable {
  const EditProductUnitPriceBandState();

  @override
  List<Object?> get props => [];
}

class EditProductUnitPriceBandInitial extends EditProductUnitPriceBandState {}

class EditProductUnitPriceBandLoading extends EditProductUnitPriceBandState {}

class EditProductUnitPriceBandLoaded extends EditProductUnitPriceBandState {
  final ProductUnitPriceSuggestionDto suggestion;
  final bool isNewPriceBand;
  final PriceBandCalculationType selectedType;

  // For customConfig
  final double? customBaseMargin;
  final double? customFloorMargin;

  // For manual
  final int? manualListPrice;
  final int? manualFloorPrice;

  final PriceBandCalculationType initialSelectedType;
  final double? initialCustomBaseMargin;
  final double? initialCustomFloorMargin;
  final int? initialManualListPrice;
  final int? initialManualFloorPrice;

  final bool isSubmitting;
  final String? error;

  const EditProductUnitPriceBandLoaded({
    required this.suggestion,
    this.isNewPriceBand = false,
    required this.selectedType,
    this.customBaseMargin,
    this.customFloorMargin,
    this.manualListPrice,
    this.manualFloorPrice,
    this.initialSelectedType = PriceBandCalculationType.storeRule,
    this.initialCustomBaseMargin,
    this.initialCustomFloorMargin,
    this.initialManualListPrice,
    this.initialManualFloorPrice,
    this.isSubmitting = false,
    this.error,
  });

  EditProductUnitPriceBandLoaded copyWith({
    ProductUnitPriceSuggestionDto? suggestion,
    bool? isNewPriceBand,
    PriceBandCalculationType? selectedType,
    double? customBaseMargin,
    double? customFloorMargin,
    int? manualListPrice,
    int? manualFloorPrice,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    bool clearCustomBaseMargin = false,
    bool clearCustomFloorMargin = false,
    bool clearManualListPrice = false,
    bool clearManualFloorPrice = false,
  }) {
    return EditProductUnitPriceBandLoaded(
      suggestion: suggestion ?? this.suggestion,
      isNewPriceBand: isNewPriceBand ?? this.isNewPriceBand,
      selectedType: selectedType ?? this.selectedType,
      customBaseMargin: clearCustomBaseMargin ? null : (customBaseMargin ?? this.customBaseMargin),
      customFloorMargin: clearCustomFloorMargin
          ? null
          : (customFloorMargin ?? this.customFloorMargin),
      manualListPrice: clearManualListPrice ? null : (manualListPrice ?? this.manualListPrice),
      manualFloorPrice: clearManualFloorPrice ? null : (manualFloorPrice ?? this.manualFloorPrice),
      initialSelectedType: initialSelectedType,
      initialCustomBaseMargin: initialCustomBaseMargin,
      initialCustomFloorMargin: initialCustomFloorMargin,
      initialManualListPrice: initialManualListPrice,
      initialManualFloorPrice: initialManualFloorPrice,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }

  int? get calculatedListPrice {
    if (selectedType == PriceBandCalculationType.storeRule) {
      return suggestion.suggestedListBeforeVat;
    } else if (selectedType == PriceBandCalculationType.customConfig) {
      if (customBaseMargin == null || !_hasBasePrice) return null;
      return (suggestion.basePrice * (1 + customBaseMargin! / 100)).round();
    } else {
      return manualListPrice;
    }
  }

  int? get calculatedFloorPrice {
    if (selectedType == PriceBandCalculationType.storeRule) {
      return suggestion.suggestedFloorBeforeVat;
    } else if (selectedType == PriceBandCalculationType.customConfig) {
      if (customFloorMargin == null || !_hasBasePrice) return null;
      return (suggestion.basePrice * (1 + customFloorMargin! / 100)).round();
    } else {
      return manualFloorPrice;
    }
  }

  bool get hasChanges =>
      selectedType != initialSelectedType ||
      customBaseMargin != initialCustomBaseMargin ||
      customFloorMargin != initialCustomFloorMargin ||
      manualListPrice != initialManualListPrice ||
      manualFloorPrice != initialManualFloorPrice;

  bool get _hasBasePrice => suggestion.basePriceVersion != null || suggestion.basePrice > 0;

  bool get canSubmit {
    if (isSubmitting) return false;
    if (!isNewPriceBand && !hasChanges) return false;
    if (selectedType == PriceBandCalculationType.storeRule) {
      return suggestion.canSuggest;
    }
    if (selectedType == PriceBandCalculationType.customConfig) {
      final listMargin = customBaseMargin;
      final floorMargin = customFloorMargin;
      if (listMargin == null || listMargin < 0) return false;
      if (floorMargin != null && (floorMargin < 0 || floorMargin > listMargin)) {
        return false;
      }
      return true;
    }
    final listP = calculatedListPrice;
    if (listP == null) return false;
    final floorP = calculatedFloorPrice;
    if (floorP != null && floorP > listP) return false;
    return true;
  }

  @override
  List<Object?> get props => [
    suggestion,
    isNewPriceBand,
    selectedType,
    customBaseMargin,
    customFloorMargin,
    manualListPrice,
    manualFloorPrice,
    initialSelectedType,
    initialCustomBaseMargin,
    initialCustomFloorMargin,
    initialManualListPrice,
    initialManualFloorPrice,
    isSubmitting,
    error,
  ];
}

class EditProductUnitPriceBandSuccess extends EditProductUnitPriceBandState {}

class EditProductUnitPriceBandNeedsOverwriteConfirm extends EditProductUnitPriceBandState {
  final EditProductUnitPriceBandLoaded loaded;
  final int? existingListAfterVat;
  final int? existingFloorAfterVat;

  const EditProductUnitPriceBandNeedsOverwriteConfirm({
    required this.loaded,
    this.existingListAfterVat,
    this.existingFloorAfterVat,
  });

  @override
  List<Object?> get props => [loaded, existingListAfterVat, existingFloorAfterVat];
}
