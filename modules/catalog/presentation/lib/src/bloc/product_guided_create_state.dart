import '../models/product_list_item_model.dart';

enum ProductGuidedCreateStatus {
  initial,
  loading,
  success,
  error,
}

/// Slice #1 (EPIC-02/US-01) — identification, images, base unit only.
class ProductGuidedCreateState {
  const ProductGuidedCreateState({
    this.name = '',
    this.tradeName = '',
    this.sku = '',
    this.barcode = '',
    this.images = const [],
    this.coverImageIndex = 0,
    this.baseUnit = '',
    this.activeStepIndex = 0,
    this.status = ProductGuidedCreateStatus.initial,
    this.errorMessage,
    this.showValidationErrors = false,
    this.skuError,
    this.barcodeError,
    this.duplicateProductId,
    this.duplicateProductName,
    this.createdProduct,
  });

  final String name;
  final String tradeName;
  final String sku;
  final String barcode;
  final List<String> images;
  final int coverImageIndex;
  final String baseUnit;

  final int activeStepIndex;
  final ProductGuidedCreateStatus status;
  final String? errorMessage;
  final bool showValidationErrors;
  final String? skuError;
  final String? barcodeError;
  final String? duplicateProductId;
  final String? duplicateProductName;
  final ProductListItemModel? createdProduct;

  static const stepCount = 3;

  bool get isStep1Valid => name.trim().isNotEmpty;
  bool get hasDuplicateError => skuError != null || barcodeError != null;
  bool get canSubmit => isStep1Valid && !hasDuplicateError;

  ProductGuidedCreateState copyWith({
    String? name,
    String? tradeName,
    String? sku,
    String? barcode,
    List<String>? images,
    int? coverImageIndex,
    String? baseUnit,
    int? activeStepIndex,
    ProductGuidedCreateStatus? status,
    String? errorMessage,
    bool clearError = false,
    bool? showValidationErrors,
    String? skuError,
    bool clearSkuError = false,
    String? barcodeError,
    bool clearBarcodeError = false,
    String? duplicateProductId,
    String? duplicateProductName,
    bool clearDuplicateMatch = false,
    ProductListItemModel? createdProduct,
  }) {
    return ProductGuidedCreateState(
      name: name ?? this.name,
      tradeName: tradeName ?? this.tradeName,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      images: images ?? this.images,
      coverImageIndex: coverImageIndex ?? this.coverImageIndex,
      baseUnit: baseUnit ?? this.baseUnit,
      activeStepIndex: activeStepIndex ?? this.activeStepIndex,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      showValidationErrors: showValidationErrors ?? this.showValidationErrors,
      skuError: clearSkuError ? null : (skuError ?? this.skuError),
      barcodeError: clearBarcodeError ? null : (barcodeError ?? this.barcodeError),
      duplicateProductId:
          clearDuplicateMatch ? null : (duplicateProductId ?? this.duplicateProductId),
      duplicateProductName:
          clearDuplicateMatch ? null : (duplicateProductName ?? this.duplicateProductName),
      createdProduct: createdProduct ?? this.createdProduct,
    );
  }
}
