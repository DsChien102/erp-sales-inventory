enum ValuationTaxMode {
  included,
  excluded;

  String get label => switch (this) {
        ValuationTaxMode.included => 'Đã gồm thuế',
        ValuationTaxMode.excluded => 'Chưa gồm thuế',
      };
}

class ValuationDirectBasisDraft {
  const ValuationDirectBasisDraft({
    this.unitPrice = 0,
    this.taxMode = ValuationTaxMode.included,
    this.taxAmount = 0,
    this.source = '',
    this.date,
    this.reference,
    this.reason = '',
  });

  final double unitPrice;
  final ValuationTaxMode taxMode;
  final double taxAmount;
  final String source;
  final DateTime? date;
  final String? reference;
  final String reason;

  bool get isValid =>
      unitPrice > 0 &&
      source.trim().isNotEmpty &&
      date != null &&
      reason.trim().isNotEmpty;

  ValuationDirectBasisDraft copyWith({
    double? unitPrice,
    ValuationTaxMode? taxMode,
    double? taxAmount,
    String? source,
    DateTime? date,
    String? reference,
    String? reason,
  }) {
    return ValuationDirectBasisDraft(
      unitPrice: unitPrice ?? this.unitPrice,
      taxMode: taxMode ?? this.taxMode,
      taxAmount: taxAmount ?? this.taxAmount,
      source: source ?? this.source,
      date: date ?? this.date,
      reference: reference ?? this.reference,
      reason: reason ?? this.reason,
    );
  }
}
