import 'package:vet45_catalog_domain/domain.dart';

import 'package:vet45_catalog_application/src/product_change_history/shared/product_change_history_entry_dto.dart';
import 'package:vet45_catalog_application/src/product/queries/get_product_control_center/product_conversion_unit_dto.dart';
import 'package:vet45_catalog_application/src/product/queries/get_product_control_center/custom_field_group_card_dto.dart';
import 'package:vet45_catalog_application/src/product_unit_price_band/queries/list_product_unit_price_bands/price_band_source_type.dart';

/// Raw control-center projection loaded from RPC before permission-aware assembly.
final class ProductControlCenterReadModel {
  const ProductControlCenterReadModel({
    required this.productId,
    required this.name,
    this.tradeName,
    this.sku,
    this.barcode,
    this.description,
    this.note,
    required this.businessStatus,
    this.primaryImageUrl,
    this.images = const [],
    this.baseUnitName,
    this.conversionUnits = const [],
    required this.facts,
    this.stockQuantity,
    this.stockVersion,
    this.basePriceAmount,
    this.basePriceCurrency = 'VND',
    this.listPrice,
    this.floorPrice,
    this.priceBandSourceType,
    this.storePriceRuleName,
    this.isCustomOverride = false,
    this.customFieldGroupCards = const [],
    this.changeHistoryPreview = const [],
  });

  final String productId;
  final String name;
  final String? tradeName;
  final String? sku;
  final String? barcode;
  final String? description;
  final String? note;
  final ProductBusinessStatus businessStatus;
  final String? primaryImageUrl;
  final List<String> images;
  final String? baseUnitName;
  final List<ProductConversionUnitDto> conversionUnits;
  final ProductReadinessFacts facts;
  final int? stockQuantity;
  final int? stockVersion;
  final double? basePriceAmount;
  final String basePriceCurrency;
  final double? listPrice;
  final double? floorPrice;
  final PriceBandSourceType? priceBandSourceType;
  final String? storePriceRuleName;
  final bool isCustomOverride;
  final List<CustomFieldGroupCardDto> customFieldGroupCards;
  final List<ProductChangeHistoryEntryDto> changeHistoryPreview;

  bool get isSoftDeleted => businessStatus.isSoftDeleted;
}
