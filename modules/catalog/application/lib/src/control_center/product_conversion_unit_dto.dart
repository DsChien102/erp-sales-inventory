/// Conversion unit row on the units card (EPIC-01/US-02/FR-02).
final class ProductConversionUnitDto {
  const ProductConversionUnitDto({
    required this.name,
    required this.conversionRate,
    required this.isActive,
  });

  final String name;
  final double conversionRate;
  final bool isActive;
}
