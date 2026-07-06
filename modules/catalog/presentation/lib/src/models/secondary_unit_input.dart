final class SecondaryUnitInput {
  const SecondaryUnitInput({
    this.name = '',
    this.multiplier = '',
    this.stock = '',
    this.listPrice = '',
    this.floorPrice = '',
  });

  final String name;
  final String multiplier;
  final String stock;
  final String listPrice;
  final String floorPrice;

  SecondaryUnitInput copyWith({
    String? name,
    String? multiplier,
    String? stock,
    String? listPrice,
    String? floorPrice,
  }) {
    return SecondaryUnitInput(
      name: name ?? this.name,
      multiplier: multiplier ?? this.multiplier,
      stock: stock ?? this.stock,
      listPrice: listPrice ?? this.listPrice,
      floorPrice: floorPrice ?? this.floorPrice,
    );
  }
}
