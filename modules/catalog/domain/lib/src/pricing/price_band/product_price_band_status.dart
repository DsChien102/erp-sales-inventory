import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// Lifecycle status for a product unit price band.
final class ProductPriceBandStatus extends ValueObject {
  const ProductPriceBandStatus._(this._wire);

  static const ProductPriceBandStatus active = ProductPriceBandStatus._('active');
  static const ProductPriceBandStatus inactive =
      ProductPriceBandStatus._('inactive');
  static const ProductPriceBandStatus deleted =
      ProductPriceBandStatus._('deleted');

  static const List<ProductPriceBandStatus> values = [
    active,
    inactive,
    deleted,
  ];

  final String _wire;

  bool get isActive => this == active;
  bool get isInactive => this == inactive;
  bool get isDeleted => this == deleted;

  String toWire() => _wire;

  String get name => _wire;

  factory ProductPriceBandStatus.fromWire(String? raw) {
    final wire = (raw ?? '').trim().toLowerCase();
    return switch (wire) {
      'active' => active,
      'inactive' => inactive,
      'deleted' => deleted,
      _ => throw DomainException(
          'Unsupported product price band status: ${raw ?? '(null)'}.',
        ),
    };
  }

  static ProductPriceBandStatus tryFromWire(String? raw) {
    try {
      return ProductPriceBandStatus.fromWire(raw);
    } on DomainException {
      return active;
    }
  }

  @override
  List<Object?> get props => [_wire];

  @override
  String toString() => 'ProductPriceBandStatus.$_wire';
}
