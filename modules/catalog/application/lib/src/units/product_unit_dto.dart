final class ProductUnitDto {
  const ProductUnitDto({
    required this.id,
    required this.name,
    required this.conversionRateToBase,
    required this.isBaseUnit,
    required this.isActive,
  });

  final String id;
  final String name;
  final double conversionRateToBase;
  final bool isBaseUnit;
  final bool isActive;
}
