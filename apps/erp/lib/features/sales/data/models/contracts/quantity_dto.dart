/// Fractional quantity represented at the fixed scale of 1,000,000.
final class QuantityDto {
  const QuantityDto({required this.quantityMicros});

  static const scale = 1000000;

  final int quantityMicros;
}
