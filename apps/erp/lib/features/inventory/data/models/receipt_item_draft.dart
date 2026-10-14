import 'package:equatable/equatable.dart';

import 'lot_date.dart';
import 'receipt_lot_draft.dart';

class ReceiptItemDraft extends Equatable {
  const ReceiptItemDraft({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.unitId,
    required this.unitName,
    this.isLotTracked = false,
    this.requiresExpiry = false,
    this.lots = const [],
    this.knownLotExpiry = const {},
  });

  final String productId;
  final String productName;
  final String productCode;
  final String unitId;
  final String unitName;
  final bool isLotTracked;
  final bool requiresExpiry;
  final List<ReceiptLotDraft> lots;

  /// Lô đã có trong hệ thống của sản phẩm (key viết hoa) → hạn dùng đã ghi nhận.
  final Map<String, LotDate> knownLotExpiry;

  double get totalAccepted => lots.fold(0.0, (sum, l) => sum + l.accepted);
  double get totalQuarantine => lots.fold(0.0, (sum, l) => sum + l.quarantine);
  double get totalDamaged => lots.fold(0.0, (sum, l) => sum + l.damaged);
  double get totalRejected => lots.fold(0.0, (sum, l) => sum + l.rejected);

  /// Tổng kiểm nhận = Đạt + Cách ly + Hỏng + Từ chối trên mọi lô
  double get totalReceived => lots.fold(0.0, (sum, l) => sum + l.totalReceived);

  /// Vào tồn vật lý = Đạt + Cách ly + Hỏng trên mọi lô
  double get totalPhysicalStock =>
      lots.fold(0.0, (sum, l) => sum + l.totalPhysicalStock);

  ReceiptItemDraft copyWith({
    String? productId,
    String? productName,
    String? productCode,
    String? unitId,
    String? unitName,
    bool? isLotTracked,
    bool? requiresExpiry,
    List<ReceiptLotDraft>? lots,
    Map<String, LotDate>? knownLotExpiry,
  }) {
    return ReceiptItemDraft(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      isLotTracked: isLotTracked ?? this.isLotTracked,
      requiresExpiry: requiresExpiry ?? this.requiresExpiry,
      lots: lots ?? this.lots,
      knownLotExpiry: knownLotExpiry ?? this.knownLotExpiry,
    );
  }

  @override
  List<Object?> get props => [
        productId,
        productName,
        productCode,
        unitId,
        unitName,
        isLotTracked,
        requiresExpiry,
        lots,
        knownLotExpiry,
      ];
}
