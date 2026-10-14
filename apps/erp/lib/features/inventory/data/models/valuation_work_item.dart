enum ValuationEntryType {
  quick,
  document;

  String get label => switch (this) {
        ValuationEntryType.quick => 'Nhập nhanh',
        ValuationEntryType.document => 'Theo chứng từ',
      };
}

enum ValuationWorkItemStatus {
  ready,
  conflict,
  missing;

  String get label => switch (this) {
        ValuationWorkItemStatus.ready => 'Có thể xác lập',
        ValuationWorkItemStatus.conflict => 'Cần đối chiếu',
        ValuationWorkItemStatus.missing => 'Cần căn cứ',
      };
}

class ValuationWorkItem {
  const ValuationWorkItem({
    required this.id,
    required this.receiptNumber,
    required this.supplierName,
    required this.entryType,
    required this.pendingLinesCount,
    required this.receivedAt,
    required this.status,
  });

  final String id;
  final String receiptNumber;
  final String supplierName;
  final ValuationEntryType entryType;
  final int pendingLinesCount;
  final String receivedAt;
  final ValuationWorkItemStatus status;

  ValuationWorkItem copyWith({
    String? id,
    String? receiptNumber,
    String? supplierName,
    ValuationEntryType? entryType,
    int? pendingLinesCount,
    String? receivedAt,
    ValuationWorkItemStatus? status,
  }) {
    return ValuationWorkItem(
      id: id ?? this.id,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      supplierName: supplierName ?? this.supplierName,
      entryType: entryType ?? this.entryType,
      pendingLinesCount: pendingLinesCount ?? this.pendingLinesCount,
      receivedAt: receivedAt ?? this.receivedAt,
      status: status ?? this.status,
    );
  }
}
