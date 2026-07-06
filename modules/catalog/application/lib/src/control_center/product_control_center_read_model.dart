import 'package:vet45_catalog_domain/domain.dart';

import '../control_center/product_change_history_entry_dto.dart';
import '../control_center/product_conversion_unit_dto.dart';
import '../pricing/store_rule/price_band_source_type.dart';

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
    this.isSoftDeleted = false,
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
    this.changeHistoryPreview = const [],
  });

  final String productId;
  final String name;
  final String? tradeName;
  final String? sku;
  final String? barcode;
  final String? description;
  final String? note;
  final ProductStatus businessStatus;
  final bool isSoftDeleted;
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
  final List<ProductChangeHistoryEntryDto> changeHistoryPreview;
}
