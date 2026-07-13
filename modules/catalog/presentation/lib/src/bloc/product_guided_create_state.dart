import 'package:vet45_catalog_application/application.dart';
import '../models/product_image_draft.dart';
import '../models/product_list_item_model.dart';
import '../utils/catalog_currency_formatters.dart';

enum ProductGuidedCreateStatus {
  initial,
  loading,
  uploadingImages,
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
    this.imageDrafts = const [],
    this.coverImageIndex = 0,
    this.baseUnit = '',
    this.basicStockQuantityBase = '',
    this.baseCost = '',
    this.pricingMethod = 'storeRule',
    this.customAutoMarkup = '',
    this.customAutoFloorMarkup = '',
    this.manualListPrice = '',
    this.manualFloorPrice = '',
    this.isStorePriceRuleLoading = false,
    this.storePriceRuleName,
    this.storeRuleListMarkupRatio,
    this.storeRuleFloorMarkupRatio,
    this.storePriceRuleUnavailableReason,
    this.priceBandConfigured = false,
    this.activeStepIndex = 0,
    this.status = ProductGuidedCreateStatus.initial,
    this.errorMessage,
    this.showValidationErrors = false,
    this.skuError,
    this.barcodeError,
    this.duplicateProductId,
    this.duplicateProductName,
    this.manualPriceError,
    this.createdProduct,
    this.tenantUnits = const [],
    this.isTenantUnitsLoading = false,
    this.customFieldGroups = const [],
    this.isCustomFieldsLoading = false,
    this.customFieldValues = const {},
    this.customFieldValidationErrors = const {},
  });

  final String name;
  final String tradeName;
  final String sku;
  final String barcode;
  final List<ProductImageDraft> imageDrafts;
  final int coverImageIndex;
  final String baseUnit;

  final String basicStockQuantityBase;
  final String baseCost;
  final String pricingMethod; // 'storeRule', 'customAuto', 'manual'
  final String customAutoMarkup;
  final String customAutoFloorMarkup;
  final String manualListPrice;
  final String manualFloorPrice;
  final bool isStorePriceRuleLoading;
  final String? storePriceRuleName;
  final double? storeRuleListMarkupRatio;
  final double? storeRuleFloorMarkupRatio;
  final String? storePriceRuleUnavailableReason;

  /// True when user confirms step 6 (Khung giá bán) via "Tiếp".
  final bool priceBandConfigured;

  final int activeStepIndex;
  final ProductGuidedCreateStatus status;
  final String? errorMessage;
  final bool showValidationErrors;
  final String? skuError;
  final String? barcodeError;
  final String? duplicateProductId;
  final String? duplicateProductName;
  final String? manualPriceError;
  final ProductListItemModel? createdProduct;
  final List<TenantMeasurementUnitDto> tenantUnits;
  final bool isTenantUnitsLoading;
  final List<CustomFieldGroupConfigDto> customFieldGroups;
  final bool isCustomFieldsLoading;
  final Map<String, ProductCustomFieldValueInput> customFieldValues;
  final Map<String, String> customFieldValidationErrors;

  static const baseStepCount = 6;
  static const maxImages = 8;

  bool get isStep1Valid => name.trim().isNotEmpty;
  bool get hasDuplicateError => skuError != null || barcodeError != null;
  bool get isUploadingImages =>
      imageDrafts.any((d) => d.status == ProductImageUploadStatus.uploading);
  bool get hasUploadFailures => imageDrafts.any((d) => d.status == ProductImageUploadStatus.failed);
  int? get parsedBasicStockQuantityBase {
    final raw = basicStockQuantityBase.trim().replaceAll(',', '');
    if (raw.isEmpty) return null;
    final value = int.tryParse(raw);
    if (value == null || value < 0) return null;
    return value;
  }

  String? get basicStockQuantityBaseError {
    final raw = basicStockQuantityBase.trim().replaceAll(',', '');
    if (raw.isEmpty) return null;
    final value = int.tryParse(raw);
    if (value == null) return 'Tồn kho phải là số nguyên hợp lệ';
    if (value < 0) return 'Tồn kho ban đầu không được âm';
    return null;
  }

  String? get baseCostError {
    if (baseCost.trim().isEmpty) return null;
    final value = parseCatalogCurrencyAmount(baseCost);
    if (value == null || value < 0) {
      return 'Giá vốn phải là số không âm';
    }
    return null;
  }

  bool get canSubmit =>
      isStep1Valid &&
      basicStockQuantityBaseError == null &&
      baseCostError == null &&
      !hasDuplicateError &&
      !isUploadingImages &&
      status != ProductGuidedCreateStatus.loading;

  bool get isStorePriceRuleReady =>
      storeRuleListMarkupRatio != null &&
      storeRuleFloorMarkupRatio != null &&
      storePriceRuleUnavailableReason == null;

  bool get canConfirmStoreRulePriceBand => pricingMethod != 'storeRule' || isStorePriceRuleReady;

  double? get parsedCustomAutoMarkupPercent {
    final value = double.tryParse(customAutoMarkup.trim().replaceAll(',', ''));
    if (value == null || value < 0) return null;
    return value;
  }

  double? get parsedCustomAutoFloorMarkupPercent {
    final value = double.tryParse(customAutoFloorMarkup.trim().replaceAll(',', ''));
    if (value == null || value < 0) return null;
    return value;
  }

  bool get canConfirmCustomAutoPriceBand {
    if (pricingMethod != 'customAuto') return true;
    final listPercent = parsedCustomAutoMarkupPercent;
    final floorPercent = parsedCustomAutoFloorMarkupPercent;
    if (listPercent == null || floorPercent == null) return false;
    return floorPercent <= listPercent;
  }

  bool get canConfirmPriceBandStep => canConfirmStoreRulePriceBand && canConfirmCustomAutoPriceBand;
  bool get hasAnyData =>
      name.trim().isNotEmpty ||
      tradeName.trim().isNotEmpty ||
      sku.trim().isNotEmpty ||
      barcode.trim().isNotEmpty ||
      imageDrafts.isNotEmpty ||
      baseUnit.trim().isNotEmpty ||
      basicStockQuantityBase.trim().isNotEmpty ||
      baseCost.trim().isNotEmpty;

  int get stepCount => 6 + customFieldGroups.length;

  ProductGuidedCreateState copyWith({
    String? name,
    String? tradeName,
    String? sku,
    String? barcode,
    List<ProductImageDraft>? imageDrafts,
    int? coverImageIndex,
    String? baseUnit,
    String? basicStockQuantityBase,
    String? baseCost,
    String? pricingMethod,
    String? customAutoMarkup,
    String? customAutoFloorMarkup,
    String? manualListPrice,
    String? manualFloorPrice,
    bool? isStorePriceRuleLoading,
    String? storePriceRuleName,
    double? storeRuleListMarkupRatio,
    double? storeRuleFloorMarkupRatio,
    String? storePriceRuleUnavailableReason,
    bool clearStorePriceRuleUnavailable = false,
    bool clearStorePriceRule = false,
    bool? priceBandConfigured,
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
    String? manualPriceError,
    bool clearManualPriceError = false,
    ProductListItemModel? createdProduct,
    List<TenantMeasurementUnitDto>? tenantUnits,
    bool? isTenantUnitsLoading,
    List<CustomFieldGroupConfigDto>? customFieldGroups,
    bool? isCustomFieldsLoading,
    Map<String, ProductCustomFieldValueInput>? customFieldValues,
    Map<String, String>? customFieldValidationErrors,
  }) {
    return ProductGuidedCreateState(
      name: name ?? this.name,
      tradeName: tradeName ?? this.tradeName,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      imageDrafts: imageDrafts ?? this.imageDrafts,
      coverImageIndex: coverImageIndex ?? this.coverImageIndex,
      baseUnit: baseUnit ?? this.baseUnit,
      basicStockQuantityBase: basicStockQuantityBase ?? this.basicStockQuantityBase,
      baseCost: baseCost ?? this.baseCost,
      pricingMethod: pricingMethod ?? this.pricingMethod,
      customAutoMarkup: customAutoMarkup ?? this.customAutoMarkup,
      customAutoFloorMarkup: customAutoFloorMarkup ?? this.customAutoFloorMarkup,
      manualListPrice: manualListPrice ?? this.manualListPrice,
      manualFloorPrice: manualFloorPrice ?? this.manualFloorPrice,
      isStorePriceRuleLoading: isStorePriceRuleLoading ?? this.isStorePriceRuleLoading,
      storePriceRuleName: clearStorePriceRule
          ? null
          : (storePriceRuleName ?? this.storePriceRuleName),
      storeRuleListMarkupRatio: clearStorePriceRule
          ? null
          : (storeRuleListMarkupRatio ?? this.storeRuleListMarkupRatio),
      storeRuleFloorMarkupRatio: clearStorePriceRule
          ? null
          : (storeRuleFloorMarkupRatio ?? this.storeRuleFloorMarkupRatio),
      storePriceRuleUnavailableReason: clearStorePriceRuleUnavailable
          ? null
          : (storePriceRuleUnavailableReason ?? this.storePriceRuleUnavailableReason),
      priceBandConfigured: priceBandConfigured ?? this.priceBandConfigured,
      activeStepIndex: activeStepIndex ?? this.activeStepIndex,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      showValidationErrors: showValidationErrors ?? this.showValidationErrors,
      skuError: clearSkuError ? null : (skuError ?? this.skuError),
      barcodeError: clearBarcodeError ? null : (barcodeError ?? this.barcodeError),
      duplicateProductId: clearDuplicateMatch
          ? null
          : (duplicateProductId ?? this.duplicateProductId),
      duplicateProductName: clearDuplicateMatch
          ? null
          : (duplicateProductName ?? this.duplicateProductName),
      manualPriceError: clearManualPriceError ? null : (manualPriceError ?? this.manualPriceError),
      createdProduct: createdProduct ?? this.createdProduct,
      tenantUnits: tenantUnits ?? this.tenantUnits,
      isTenantUnitsLoading: isTenantUnitsLoading ?? this.isTenantUnitsLoading,
      customFieldGroups: customFieldGroups ?? this.customFieldGroups,
      isCustomFieldsLoading: isCustomFieldsLoading ?? this.isCustomFieldsLoading,
      customFieldValues: customFieldValues ?? this.customFieldValues,
      customFieldValidationErrors: customFieldValidationErrors ?? this.customFieldValidationErrors,
    );
  }
}
