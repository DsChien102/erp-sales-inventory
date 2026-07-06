import '../adjust_basic_stock_command.dart';

final class AdjustBasicStockGatewayResult {
  const AdjustBasicStockGatewayResult({
    required this.previousQuantity,
    required this.newQuantity,
    this.unitName,
  });

  final double previousQuantity;
  final double newQuantity;
  final String? unitName;
}

abstract interface class ICatalogStockGateway {
  Future<AdjustBasicStockGatewayResult> adjustBasicStock({
    required AdjustBasicStockCommand command,
  });
}
