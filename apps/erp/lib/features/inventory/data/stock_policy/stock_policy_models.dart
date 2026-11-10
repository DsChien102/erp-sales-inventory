// Mô hình dữ liệu cho chính sách tồn và cận hạn (CAP-01).

class StockPolicyProduct {
  final String productId;
  final String name;
  final String code;
  final String uom;
  final bool isLotTracked;
  final num available;
  final bool hasExpired;
  final bool hasNearExpiry;
  final num? threshold;
  final num? target;
  final int? nearExpiryDaysOverride;

  const StockPolicyProduct({
    required this.productId,
    required this.name,
    required this.code,
    required this.uom,
    required this.isLotTracked,
    required this.available,
    required this.hasExpired,
    required this.hasNearExpiry,
    this.threshold,
    this.target,
    this.nearExpiryDaysOverride,
  });

  bool get configured => threshold != null;

  factory StockPolicyProduct.fromJson(Map<String, dynamic> json) {
    return StockPolicyProduct(
      productId: json['product_id'] as String,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      uom: json['base_uom'] as String? ?? '',
      isLotTracked: json['is_lot_tracked'] as bool? ?? false,
      available: (json['available'] as num?) ?? 0,
      hasExpired: json['has_expired'] as bool? ?? false,
      hasNearExpiry: json['has_near_expiry'] as bool? ?? false,
      threshold: json['reorder_threshold'] as num?,
      target: json['target_level'] as num?,
      nearExpiryDaysOverride: (json['near_expiry_days'] as num?)?.toInt(),
    );
  }
}

class StockPolicySnapshot {
  final int revision;
  final bool isOwner;
  final int? nearExpiryDays;
  final List<StockPolicyProduct> products;

  const StockPolicySnapshot({
    required this.revision,
    required this.isOwner,
    this.nearExpiryDays,
    required this.products,
  });

  factory StockPolicySnapshot.fromJson(Map<String, dynamic> json) {
    return StockPolicySnapshot(
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      isOwner: json['is_owner'] as bool? ?? false,
      nearExpiryDays: (json['near_expiry_days'] as num?)?.toInt(),
      products: ((json['products'] as List?) ?? [])
          .map((e) => StockPolicyProduct.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class ThresholdChange {
  final String productId;
  final int threshold;
  final int target;

  const ThresholdChange({
    required this.productId,
    required this.threshold,
    required this.target,
  });

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'reorder_threshold': threshold,
        'target_level': target,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThresholdChange &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          threshold == other.threshold &&
          target == other.target;

  @override
  int get hashCode => Object.hash(productId, threshold, target);
}

class NearExpiryOverride {
  final String productId;
  final int days;

  const NearExpiryOverride({
    required this.productId,
    required this.days,
  });

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'days': days,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NearExpiryOverride &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          days == other.days;

  @override
  int get hashCode => Object.hash(productId, days);
}
