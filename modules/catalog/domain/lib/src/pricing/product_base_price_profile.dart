import 'package:vet45_shared_domain/shared_kernel_domain.dart';
import 'base_price.dart';
import 'base_price_mode.dart';

final class ProductBasePriceProfile extends ValueObject {
  const ProductBasePriceProfile({
    required this.mode,
    this.basePrice,
  });

  final BasePriceMode mode;
  final BasePrice? basePrice;

  factory ProductBasePriceProfile.manual({BasePrice? basePrice}) {
    return ProductBasePriceProfile(
      mode: BasePriceMode.manual,
      basePrice: basePrice,
    );
  }

  factory ProductBasePriceProfile.costingModule() {
    return const ProductBasePriceProfile(
      mode: BasePriceMode.costingModule,
      basePrice: null,
    );
  }

  ProductBasePriceProfile withBasePrice(BasePrice price) {
    return ProductBasePriceProfile(
      mode: mode,
      basePrice: price,
    );
  }

  @override
  List<Object?> get props => [mode, basePrice];
}
