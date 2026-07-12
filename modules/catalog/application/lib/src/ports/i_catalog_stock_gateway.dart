import 'package:vet45_catalog_application/src/product_stock_profile/commands/adjust_basic_stock/adjust_basic_stock_command.dart';

final class AdjustBasicStockGatewayResult {
  const AdjustBasicStockGatewayResult({
    required this.previousQuantity,
    required this.newQuantity,
    this.unitName,
  });

  final int previousQuantity;
  final int newQuantity;
  final String? unitName;
}

abstract interface class ICatalogStockGateway {
  Future<AdjustBasicStockGatewayResult> adjustBasicStock({
    required AdjustBasicStockCommand command,
  });
}
