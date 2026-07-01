class PartnerTransactionHistoryItemDto {
  final String transactionCode;
  final String transactionType;
  final String status;
  final DateTime occurredAt;
  final int? amountMinor;

  const PartnerTransactionHistoryItemDto({
    required this.transactionCode,
    required this.transactionType,
    required this.status,
    required this.occurredAt,
    this.amountMinor,
  });

  factory PartnerTransactionHistoryItemDto.fromJson(Map<String, dynamic> json) {
    return PartnerTransactionHistoryItemDto(
      transactionCode: json['transactionCode'] as String? ?? json['id'] as String? ?? '',
      transactionType: json['transactionType'] as String? ?? json['title'] as String? ?? '',
      status: json['status'] as String? ?? '',
      occurredAt: json['occurredAt'] != null 
          ? DateTime.parse(json['occurredAt'] as String)
          : (json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now()),
      amountMinor: json['amountMinor'] as int? ?? 
          (json['amount'] != null ? _parseAmountMinor(json['amount'] as String) : null),
    );
  }

  static int? _parseAmountMinor(String amountStr) {
    final clean = amountStr.replaceAll(RegExp(r'[^\d-]'), '');
    return int.tryParse(clean);
  }
}
