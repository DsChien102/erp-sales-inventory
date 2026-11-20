/// Catalog input models for commands and mutations.
library;

import 'catalog_enums.dart';

/// Image payload for guided product create.
final class ProductImageInput {
  const ProductImageInput({
    required this.storageKey,
    this.slotId,
    this.url,
    this.isPrimary = false,
    this.sortOrder = 0,
  });

  final String storageKey;
  final String? slotId;
  final String? url;
  final bool isPrimary;
  final int sortOrder;
}

/// Image payload for replacing the current visible product gallery.
final class ProductImageMutationInput {
  const ProductImageMutationInput({
    this.imageId,
    required this.storageKey,
    this.slotId,
    this.url,
    this.isPrimary = false,
    this.sortOrder = 0,
  });

  final String? imageId;
  final String storageKey;
  final String? slotId;
  final String? url;
  final bool isPrimary;
  final int sortOrder;
}

/// How to resolve the base unit when setting it on a product (EPIC-04/US-01).
sealed class BaseUnitSelection {
  const BaseUnitSelection();
}

/// Pick an existing tenant measurement unit by id.
final class ExistingTenantUnit extends BaseUnitSelection {
  const ExistingTenantUnit(this.unitId);

  final String unitId;
}

/// Quick-create a new tenant measurement unit by name.
final class NewTenantUnit extends BaseUnitSelection {
  const NewTenantUnit(this.name);

  final String name;
}

/// Value mutation input for one product custom field.
final class ProductCustomFieldValueInput {
  const ProductCustomFieldValueInput({
    required this.fieldId,
    this.textValue,
    this.numberValue,
    this.dateValue,
    this.booleanValue,
    this.optionId,
  });

  final String fieldId;
  final String? textValue;
  final double? numberValue;
  final DateTime? dateValue;
  final bool? booleanValue;
  final String? optionId;

  bool get isEmpty =>
      (textValue == null || textValue!.trim().isEmpty) &&
      numberValue == null &&
      dateValue == null &&
      booleanValue == null &&
      (optionId == null || optionId!.trim().isEmpty);
}

/// Input for guided product create (replaces CreateGuidedProductCommand).
final class CreateGuidedProductInput {
  const CreateGuidedProductInput({
    required this.productName,
    this.commercialName,
    this.sku,
    this.barcode,
    this.note,
    this.images = const [],
    this.baseUnit,
    this.basePrice,
    this.listBeforeVat,
    this.floorBeforeVat,
    this.useStorePriceRule = false,
    this.priceBandSourceType,
    this.listMarkupRatio,
    this.floorMarkupRatio,
    this.customFieldValues = const [],
    this.trackingMode = ProductTrackingMode.none,
    this.expiryRequired = false,
  });

  final String productName;
  final String? commercialName;
  final String? sku;
  final String? barcode;
  final String? note;
  final List<ProductImageInput> images;
  final BaseUnitSelection? baseUnit;
  final double? basePrice;
  final int? listBeforeVat;
  final int? floorBeforeVat;
  final bool useStorePriceRule;
  final PriceBandSourceType? priceBandSourceType;
  final double? listMarkupRatio;
  final double? floorMarkupRatio;
  final List<ProductCustomFieldValueInput> customFieldValues;
  final ProductTrackingMode trackingMode;
  final bool expiryRequired;
}

