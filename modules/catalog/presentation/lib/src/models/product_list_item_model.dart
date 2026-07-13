import 'product_business_status.dart';

import 'product_readiness_status.dart';

class ProductListItemModel {
  const ProductListItemModel({
    required this.id,
    required this.name,
    this.tradeName,
    this.sku,
    this.barcode,
    this.imageUrl,
    required this.businessStatus,
    required this.readinessStatus,
    this.listPriceLabel,
    this.stockLabel,
    this.stockQty,
    this.baseUnit,
    this.listBeforeVat,
    this.floorBeforeVat,
    this.baseCost,
    this.industryInfo,
    this.notes,
    this.images,
  });

  final String id;
  final String name;
  final String? tradeName;
  final String? sku;
  final String? barcode;
  final String? imageUrl;
  final ProductBusinessStatus businessStatus;
  final ProductReadinessStatus readinessStatus;
  final String? listPriceLabel;
  final String? stockLabel;
  final int? stockQty;
  final String? baseUnit;
  final int? listBeforeVat;
  final int? floorBeforeVat;
  final double? baseCost;
  final String? industryInfo;
  final String? notes;
  final List<String>? images;

  bool get isSoftDeleted => businessStatus.isSoftDeleted;

  String get displaySubtitle {
    final parts = <String>[];

    if (sku != null && sku!.isNotEmpty) {
      parts.add(sku!);
    }

    if (barcode != null && barcode!.isNotEmpty) {
      parts.add(barcode!);
    }

    if (parts.isEmpty) {
      return '—';
    }

    return parts.join(' · ');
  }

  ProductListItemModel copyWith({
    String? id,
    String? name,
    String? tradeName,
    String? sku,
    String? barcode,
    String? imageUrl,
    ProductBusinessStatus? businessStatus,
    ProductReadinessStatus? readinessStatus,
    String? listPriceLabel,
    String? stockLabel,
    int? stockQty,
    String? baseUnit,
    int? listBeforeVat,
    int? floorBeforeVat,
    double? baseCost,
    String? industryInfo,
    String? notes,
    List<String>? images,
  }) {
    return ProductListItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      tradeName: tradeName ?? this.tradeName,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      businessStatus: businessStatus ?? this.businessStatus,
      readinessStatus: readinessStatus ?? this.readinessStatus,
      listPriceLabel: listPriceLabel ?? this.listPriceLabel,
      stockLabel: stockLabel ?? this.stockLabel,
      stockQty: stockQty ?? this.stockQty,
      baseUnit: baseUnit ?? this.baseUnit,
      listBeforeVat: listBeforeVat ?? this.listBeforeVat,
      floorBeforeVat: floorBeforeVat ?? this.floorBeforeVat,
      baseCost: baseCost ?? this.baseCost,
      industryInfo: industryInfo ?? this.industryInfo,
      notes: notes ?? this.notes,
      images: images ?? this.images,
    );
  }
}
