import 'package:equatable/equatable.dart';

class ReceiptHeaderDraft extends Equatable {
  const ReceiptHeaderDraft({
    this.supplierId = '',
    this.supplierName = '',
    this.warehouseId = 'wh_default',
    this.warehouseName = 'Kho trung tâm',
    required this.receiptDate,
    this.documentFileNames = const [],
  });

  final String supplierId;
  final String supplierName;
  final String warehouseId;
  final String warehouseName;
  final DateTime receiptDate;
  final List<String> documentFileNames;

  bool get isValid =>
      supplierId.isNotEmpty && warehouseId.isNotEmpty && documentFileNames.isNotEmpty;

  ReceiptHeaderDraft copyWith({
    String? supplierId,
    String? supplierName,
    String? warehouseId,
    String? warehouseName,
    DateTime? receiptDate,
    List<String>? documentFileNames,
  }) {
    return ReceiptHeaderDraft(
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      receiptDate: receiptDate ?? this.receiptDate,
      documentFileNames: documentFileNames ?? this.documentFileNames,
    );
  }

  @override
  List<Object?> get props => [
        supplierId,
        supplierName,
        warehouseId,
        warehouseName,
        receiptDate,
        documentFileNames,
      ];
}
