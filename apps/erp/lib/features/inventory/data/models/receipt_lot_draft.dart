import 'package:equatable/equatable.dart';

import 'lot_date.dart';

class ReceiptLotDraft extends Equatable {
  const ReceiptLotDraft({
    this.lotCode = '',
    this.manufactureDate,
    this.expiryDate,
    this.accepted = 0.0,
    this.quarantine = 0.0,
    this.damaged = 0.0,
    this.rejected = 0.0,
  });

  final String lotCode;
  final LotDate? manufactureDate;
  final LotDate? expiryDate;
  final double accepted;
  final double quarantine;
  final double damaged;
  final double rejected;

  /// Tổng kiểm nhận = Đạt + Cách ly + Hỏng + Từ chối
  double get totalReceived => accepted + quarantine + damaged + rejected;

  /// Vào tồn vật lý = Đạt + Cách ly + Hỏng (Lượng từ chối không vào tồn)
  double get totalPhysicalStock => accepted + quarantine + damaged;
  double get physicalStockQuantity => totalPhysicalStock;

  bool get isValid => totalReceived > 0;

  ReceiptLotDraft copyWith({
    String? lotCode,
    LotDate? manufactureDate,
    LotDate? expiryDate,
    double? accepted,
    double? quarantine,
    double? damaged,
    double? rejected,
    bool clearManufactureDate = false,
    bool clearExpiryDate = false,
  }) {
    return ReceiptLotDraft(
      lotCode: lotCode ?? this.lotCode,
      manufactureDate:
          clearManufactureDate ? null : (manufactureDate ?? this.manufactureDate),
      expiryDate: clearExpiryDate ? null : (expiryDate ?? this.expiryDate),
      accepted: accepted ?? this.accepted,
      quarantine: quarantine ?? this.quarantine,
      damaged: damaged ?? this.damaged,
      rejected: rejected ?? this.rejected,
    );
  }

  @override
  List<Object?> get props => [
        lotCode,
        manufactureDate,
        expiryDate,
        accepted,
        quarantine,
        damaged,
        rejected,
      ];
}
