import 'package:vet45_catalog_domain/domain.dart';

final class ProductPriceBandSnapshotItemDto {
  const ProductPriceBandSnapshotItemDto({
    required this.productId,
    required this.productUnitId,
    required this.unitName,
    required this.currency,
    required this.listBeforeVatMissing,
    required this.floorBeforeVatMissing,
    required this.floorBeforeVatHidden,
    required this.isUnitActive,
    required this.productBusinessStatus,
    required this.capturedAt,
    this.listBeforeVat,
    this.floorBeforeVat,
    this.listAfterVat,
    this.floorAfterVat,
    this.effectiveFrom,
    this.effectiveTo,
    this.status,
  });

  final String productId;
  final String productUnitId;
  final String unitName;
  final String currency;
  final int? listBeforeVat;
  final bool listBeforeVatMissing;
  final int? floorBeforeVat;
  final bool floorBeforeVatMissing;
  final bool floorBeforeVatHidden;
  final int? listAfterVat;
  final int? floorAfterVat;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final ProductPriceBandStatus? status;
  final bool isUnitActive;
  final ProductBusinessStatus productBusinessStatus;
  final DateTime capturedAt;
}
