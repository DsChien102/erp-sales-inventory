import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// Business lifecycle status for a product (source of truth for soft delete).
final class ProductBusinessStatus extends ValueObject {
  const ProductBusinessStatus._(this._wire);

  static const ProductBusinessStatus active = ProductBusinessStatus._('active');
  static const ProductBusinessStatus inactive =
      ProductBusinessStatus._('inactive');
  static const ProductBusinessStatus softDeleted =
      ProductBusinessStatus._('soft_deleted');

  static const List<ProductBusinessStatus> values = [
    active,
    inactive,
    softDeleted,
  ];

  final String _wire;

  bool get isActive => this == active;
  bool get isInactive => this == inactive;
  bool get isSoftDeleted => this == softDeleted;

  String toWire() => _wire;

  /// Dart identifier-style name for sorting/logging (`softDeleted`, not wire).
  String get name => switch (_wire) {
        'active' => 'active',
        'inactive' => 'inactive',
        'soft_deleted' => 'softDeleted',
        _ => _wire,
      };

  factory ProductBusinessStatus.fromWire(String? raw) {
    final wire = (raw ?? '').trim().toLowerCase();
    return switch (wire) {
      'active' => active,
      'inactive' => inactive,
      'soft_deleted' || 'softdeleted' => softDeleted,
      _ => throw DomainException(
          'Unsupported product business status: ${raw ?? '(null)'}.',
        ),
    };
  }

  /// Lenient parse for RPC rows; unknown → [active].
  static ProductBusinessStatus tryFromWire(String? raw) {
    try {
      return ProductBusinessStatus.fromWire(raw);
    } on DomainException {
      return active;
    }
  }

  @override
  List<Object?> get props => [_wire];

  @override
  String toString() => 'ProductBusinessStatus.$_wire';
}
