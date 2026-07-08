import 'package:vet45_catalog_domain/domain.dart';
import '../stock/stock_data_source.dart';

/// Stock card on Product Control Center (EPIC-01/US-02/FR-02).
final class ProductStockCardDto {
  const ProductStockCardDto({
    required this.mode,
    required this.source,
    required this.sourceLabel,
    this.quantity,
    this.unitName,
    this.isConfigured = false,
    this.isOutOfStock = false,
    this.canAdjust = false,
    this.currentVersion,
    this.isPendingExternal = false,
    this.isMissing = false,
    this.missingMessage,
  });

  final StockMode mode;
  final StockDataSource source;
  final String sourceLabel;
  final int? quantity;
  final String? unitName;
  final bool isConfigured;
  final bool isOutOfStock;
  final bool canAdjust;
  final int? currentVersion;
  final bool isPendingExternal;
  final bool isMissing;
  final String? missingMessage;
}
