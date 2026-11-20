final class SecondaryUnitInput {
  const SecondaryUnitInput({
    this.name = '',
    this.multiplier = '',
    this.stock = '',
    this.listBeforeVat = '',
    this.floorBeforeVat = '',
  });

  final String name;
  final String multiplier;
  final String stock;
  final String listBeforeVat;
  final String floorBeforeVat;

  SecondaryUnitInput copyWith({
    String? name,
    String? multiplier,
    String? stock,
    String? listBeforeVat,
    String? floorBeforeVat,
  }) {
    return SecondaryUnitInput(
      name: name ?? this.name,
      multiplier: multiplier ?? this.multiplier,
      stock: stock ?? this.stock,
      listBeforeVat: listBeforeVat ?? this.listBeforeVat,
      floorBeforeVat: floorBeforeVat ?? this.floorBeforeVat,
    );
  }
}
