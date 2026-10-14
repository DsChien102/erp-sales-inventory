class ValuationCostSource {
  const ValuationCostSource({
    required this.id,
    required this.label,
    required this.unitPrice,
    this.currency = 'VND',
    this.fxRate = 1.0,
    this.unitLineDiscount = 0,
    this.unitDocDiscount = 0,
    this.unitKnownCost = 0,
    this.unitNonDeductibleVat = 0,
    this.directReason,
    this.taxMode,
    this.sourceDate,
    this.reference,
  });

  final String id;
  final String label;
  final double unitPrice;
  final String currency;
  final double fxRate;
  final double unitLineDiscount;
  final double unitDocDiscount;
  final double unitKnownCost;
  final double unitNonDeductibleVat;
  final String? directReason;
  final String? taxMode;
  final String? sourceDate;
  final String? reference;

  /// Đơn giá ghi nhận ban đầu = Giá mua quy đổi − Chiết khấu dòng − Chiết khấu chứng từ + Chi phí mua đã biết + Thuế không thu hồi
  double get unitActual {
    final basePrice = unitPrice * fxRate;
    return basePrice -
        unitLineDiscount -
        unitDocDiscount +
        unitKnownCost +
        unitNonDeductibleVat;
  }

  ValuationCostSource copyWith({
    String? id,
    String? label,
    double? unitPrice,
    String? currency,
    double? fxRate,
    double? unitLineDiscount,
    double? unitDocDiscount,
    double? unitKnownCost,
    double? unitNonDeductibleVat,
    String? directReason,
    String? taxMode,
    String? sourceDate,
    String? reference,
  }) {
    return ValuationCostSource(
      id: id ?? this.id,
      label: label ?? this.label,
      unitPrice: unitPrice ?? this.unitPrice,
      currency: currency ?? this.currency,
      fxRate: fxRate ?? this.fxRate,
      unitLineDiscount: unitLineDiscount ?? this.unitLineDiscount,
      unitDocDiscount: unitDocDiscount ?? this.unitDocDiscount,
      unitKnownCost: unitKnownCost ?? this.unitKnownCost,
      unitNonDeductibleVat: unitNonDeductibleVat ?? this.unitNonDeductibleVat,
      directReason: directReason ?? this.directReason,
      taxMode: taxMode ?? this.taxMode,
      sourceDate: sourceDate ?? this.sourceDate,
      reference: reference ?? this.reference,
    );
  }
}
