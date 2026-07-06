import 'package:vet45_catalog_domain/domain.dart';

/// Stock card on Product Control Center (EPIC-01/US-02/FR-02).
final class ProductStockCardDto {
  const ProductStockCardDto({
    required this.mode,
    this.quantity,
    this.unitName,
    this.isPendingExternal = false,
    this.isMissing = false,
    this.missingMessage,
  });

  final StockMode mode;
  final int? quantity;
  final String? unitName;
  final bool isPendingExternal;
  final bool isMissing;
  final String? missingMessage;
}
