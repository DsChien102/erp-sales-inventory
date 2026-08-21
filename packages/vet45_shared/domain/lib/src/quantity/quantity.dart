import '../value_object.dart';
import 'rules/quantity_must_be_non_negative_rule.dart';

/// Fractional quantity at a fixed micro scale (1 unit = 1_000_000 micros).
final class Quantity extends ValueObject {
  Quantity({required this.quantityMicros}) {
    ValueObject.checkRule(QuantityMustBeNonNegativeRule(quantityMicros));
  }

  static const scale = 1000000;

  final int quantityMicros;

  static Quantity zero = Quantity(quantityMicros: 0);

  bool get isZero => quantityMicros == 0;
  bool get isNotZero => quantityMicros != 0;

  Quantity operator +(Quantity other) =>
      Quantity(quantityMicros: quantityMicros + other.quantityMicros);

  Quantity operator -(Quantity other) =>
      Quantity(quantityMicros: quantityMicros - other.quantityMicros);

  bool operator >(Quantity other) => quantityMicros > other.quantityMicros;
  bool operator >=(Quantity other) => quantityMicros >= other.quantityMicros;
  bool operator <(Quantity other) => quantityMicros < other.quantityMicros;
  bool operator <=(Quantity other) => quantityMicros <= other.quantityMicros;

  @override
  List<Object?> get props => [quantityMicros];

  @override
  String toString() => 'Quantity($quantityMicros)';
}
