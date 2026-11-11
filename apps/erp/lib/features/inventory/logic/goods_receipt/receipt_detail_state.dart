import 'package:equatable/equatable.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';

enum ReceiptDetailStatus {
  loading,
  ready,
  notFound,
  loadError,
}

class ReceiptDetailState extends Equatable {
  const ReceiptDetailState({
    this.status = ReceiptDetailStatus.loading,
    this.receipt,
  });

  final ReceiptDetailStatus status;
  final ReceiptDetail? receipt;

  ReceiptDetailState copyWith({
    ReceiptDetailStatus? status,
    ReceiptDetail? receipt,
  }) {
    return ReceiptDetailState(
      status: status ?? this.status,
      receipt: receipt ?? this.receipt,
    );
  }

  @override
  List<Object?> get props => [status, receipt];
}

