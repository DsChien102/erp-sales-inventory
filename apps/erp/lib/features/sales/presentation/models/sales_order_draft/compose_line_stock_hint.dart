import 'package:equatable/equatable.dart';

enum SalesStockWarningLevel { none, low, critical, out }

/// Ngưỡng tồn thấp: ≤2 hiển thị "Chỉ còn N {ĐVT}" trên dòng đơn (Hình 3).
abstract final class SalesStockWarning {
  static const int lowStockThreshold = 2;

  static SalesStockWarningLevel level(int? stockQuantity) {
    if (stockQuantity == null) return SalesStockWarningLevel.none;
    if (stockQuantity <= 0) return SalesStockWarningLevel.out;
    if (stockQuantity <= 1) return SalesStockWarningLevel.critical;
    if (stockQuantity <= lowStockThreshold) return SalesStockWarningLevel.low;
    return SalesStockWarningLevel.none;
  }

  static String? text({required int? stockQuantity, required String unitLabel}) {
    switch (level(stockQuantity)) {
      case SalesStockWarningLevel.none:
        return null;
      case SalesStockWarningLevel.out:
        return 'Hết hàng';
      case SalesStockWarningLevel.critical:
      case SalesStockWarningLevel.low:
        return 'Chỉ còn $stockQuantity $unitLabel';
    }
  }
}

/// Tồn kho runtime cho UX cảnh báo / cap số lượng — tách khỏi pricing.
final class ComposeLineStockHint extends Equatable {
  const ComposeLineStockHint({required this.availableQuantity});

  final int? availableQuantity;

  String? warningText(String unitLabel) =>
      SalesStockWarning.text(stockQuantity: availableQuantity, unitLabel: unitLabel);

  SalesStockWarningLevel get warningLevel => SalesStockWarning.level(availableQuantity);

  int get maxQuantity => availableQuantity ?? 9999;

  ComposeLineStockHint copyWith({int? availableQuantity}) {
    return ComposeLineStockHint(
      availableQuantity: availableQuantity ?? this.availableQuantity,
    );
  }

  @override
  List<Object?> get props => [availableQuantity];
}
