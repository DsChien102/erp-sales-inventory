import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'price_band_markup_config.dart';

final class CalculatedPriceBand {
  const CalculatedPriceBand({
    required this.listPrice,
    this.floorPrice,
  });

  final int listPrice;
  final int? floorPrice;
}

abstract final class PriceBandMarkupCalculator {
  static CalculatedPriceBand calculate({
    required num basePriceForUnit,
    required PriceBandMarkupConfig config,
  }) {
    if (basePriceForUnit < 0) {
      throw DomainException('Base price for unit must not be negative.');
    }

    return CalculatedPriceBand(
      listPrice: (basePriceForUnit * (1 + config.listMarkupRatio)).round(),
      floorPrice: config.floorMarkupRatio == null
          ? null
          : (basePriceForUnit * (1 + config.floorMarkupRatio!)).round(),
    );
  }
}
