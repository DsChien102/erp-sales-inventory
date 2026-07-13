import 'package:equatable/equatable.dart';
import 'package:vet45_catalog_application/application.dart';

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
  final PriceBandCalculationType selectedType;

  // For customConfig
  final double? customBaseMargin;
  final double? customFloorMargin;

  // For manual
  final int? manualListPrice;
  final int? manualFloorPrice;

  final bool isSubmitting;
  final String? error;

  const EditProductUnitPriceBandLoaded({
    required this.suggestion,
    required this.selectedType,
    this.customBaseMargin,
    this.customFloorMargin,
    this.manualListPrice,
    this.manualFloorPrice,
    this.isSubmitting = false,
    this.error,
  });

  EditProductUnitPriceBandLoaded copyWith({
    ProductUnitPriceSuggestionDto? suggestion,
    PriceBandCalculationType? selectedType,
    double? customBaseMargin,
    double? customFloorMargin,
    int? manualListPrice,
    int? manualFloorPrice,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return EditProductUnitPriceBandLoaded(
      suggestion: suggestion ?? this.suggestion,
      selectedType: selectedType ?? this.selectedType,
      customBaseMargin: customBaseMargin ?? this.customBaseMargin,
      customFloorMargin: customFloorMargin ?? this.customFloorMargin,
      manualListPrice: manualListPrice ?? this.manualListPrice,
      manualFloorPrice: manualFloorPrice ?? this.manualFloorPrice,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }

  int? get calculatedListPrice {
    if (selectedType == PriceBandCalculationType.storeRule) {
      return suggestion.suggestedListBeforeVat;
    } else if (selectedType == PriceBandCalculationType.customConfig) {
      if (customBaseMargin == null) return null;
      return (suggestion.basePrice * (1 + customBaseMargin! / 100)).round();
    } else {
      return manualListPrice;
    }
  }

  int? get calculatedFloorPrice {
    if (selectedType == PriceBandCalculationType.storeRule) {
      return suggestion.suggestedFloorBeforeVat;
    } else if (selectedType == PriceBandCalculationType.customConfig) {
      if (customFloorMargin == null) return null;
      return (suggestion.basePrice * (1 + customFloorMargin! / 100)).round();
    } else {
      return manualFloorPrice;
    }
  }

  bool get canSubmit {
    if (isSubmitting) return false;
    final listP = calculatedListPrice;
    if (listP == null) return false;
    final floorP = calculatedFloorPrice;
    if (floorP != null && floorP > listP) return false;
    if (selectedType == PriceBandCalculationType.storeRule) {
      return suggestion.canSuggest;
    }
    return true;
  }

  @override
  List<Object?> get props => [
    suggestion,
    selectedType,
    customBaseMargin,
    customFloorMargin,
    manualListPrice,
    manualFloorPrice,
    isSubmitting,
    error,
  ];
}

class EditProductUnitPriceBandSuccess extends EditProductUnitPriceBandState {}
