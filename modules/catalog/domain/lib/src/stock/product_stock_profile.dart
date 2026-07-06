import 'package:vet45_shared_domain/shared_kernel_domain.dart';
import 'stock_mode.dart';

final class ProductStockProfile extends ValueObject {
  const ProductStockProfile({
    required this.mode,
    this.initialStock,
  });

  final StockMode mode;
  final double? initialStock;

  factory ProductStockProfile.basic({double? initialStock}) {
    return ProductStockProfile(
      mode: StockMode.basic,
      initialStock: initialStock,
    );
  }

  factory ProductStockProfile.advanced() {
    return const ProductStockProfile(
      mode: StockMode.advanced,
      initialStock: null,
    );
  }

  ProductStockProfile withInitialStock(double quantity) {
    return ProductStockProfile(
      mode: mode,
      initialStock: quantity,
    );
  }

  @override
  List<Object?> get props => [mode, initialStock];
}
