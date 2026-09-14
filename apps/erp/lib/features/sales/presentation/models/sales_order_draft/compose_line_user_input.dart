import 'package:equatable/equatable.dart';

/// Override giá do user nhập — chỉ là **input** gửi pricing preview (US-04 / US-05).
final class ComposeManualPricing extends Equatable {
  const ComposeManualPricing({
    this.unitPriceMinor,
    this.discountMinor,
    this.discountBasisPoints,
  });

  static const empty = ComposeManualPricing();

  final int? unitPriceMinor;
  final int? discountMinor;
  final int? discountBasisPoints;

  bool get isEmpty =>
      unitPriceMinor == null && discountMinor == null && discountBasisPoints == null;

  ComposeManualPricing copyWith({
    int? unitPriceMinor,
    bool clearUnitPriceMinor = false,
    int? discountMinor,
    bool clearDiscountMinor = false,
    int? discountBasisPoints,
    bool clearDiscountBasisPoints = false,
  }) {
    return ComposeManualPricing(
      unitPriceMinor: clearUnitPriceMinor ? null : (unitPriceMinor ?? this.unitPriceMinor),
      discountMinor: clearDiscountMinor ? null : (discountMinor ?? this.discountMinor),
      discountBasisPoints: clearDiscountBasisPoints
          ? null
          : (discountBasisPoints ?? this.discountBasisPoints),
    );
  }

  @override
  List<Object?> get props => [
    unitPriceMinor,
    discountMinor,
    discountBasisPoints,
  ];
}

/// Phần dòng do user chỉnh trực tiếp trước khi preview chạy lại.
final class ComposeLineUserInput extends Equatable {
  const ComposeLineUserInput({
    required this.quantity,
    this.manual = ComposeManualPricing.empty,
  });

  final int quantity;
  final ComposeManualPricing manual;

  ComposeLineUserInput copyWith({
    int? quantity,
    ComposeManualPricing? manual,
  }) {
    return ComposeLineUserInput(
      quantity: quantity ?? this.quantity,
      manual: manual ?? this.manual,
    );
  }

  @override
  List<Object?> get props => [quantity, manual];
}
