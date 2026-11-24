import 'package:equatable/equatable.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';

enum ReceiptListStatus {
  loading,
  ready,
  empty,
  loadError,
}

class ReceiptListState extends Equatable {
  const ReceiptListState({
    this.status = ReceiptListStatus.loading,
    this.all = const [],
    this.suppliers = const [],
    this.supplierId,
    this.query = '',
  });

  final ReceiptListStatus status;
  final List<ReceiptListRow> all;
  final List<ReceiptSupplierOption> suppliers;
  final String? supplierId;
  final String query;

  List<ReceiptListRow> get visible {
    final q = VTextNormalizer.normalizeForSearch(query.trim());
    return all.where((r) {
      if (supplierId != null && r.supplierId != supplierId) {
        return false;
      }
      if (q.isNotEmpty) {
        final matchNo = VTextNormalizer.normalizeForSearch(r.receiptNo).contains(q);
        final matchSupplier = VTextNormalizer.normalizeForSearch(r.supplierName).contains(q);
        final matchDoc = r.supplierDocNo != null &&
            VTextNormalizer.normalizeForSearch(r.supplierDocNo!).contains(q);
        if (!matchNo && !matchSupplier && !matchDoc) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  ReceiptSupplierOption? get selectedSupplier =>
      supplierId == null ? null : suppliers.where((s) => s.id == supplierId).firstOrNull;

  ReceiptListState copyWith({
    ReceiptListStatus? status,
    List<ReceiptListRow>? all,
    List<ReceiptSupplierOption>? suppliers,
    String? supplierId,
    bool clearSupplier = false,
    String? query,
  }) {
    return ReceiptListState(
      status: status ?? this.status,
      all: all ?? this.all,
      suppliers: suppliers ?? this.suppliers,
      supplierId: clearSupplier ? null : (supplierId ?? this.supplierId),
      query: query ?? this.query,
    );
  }

  @override
  List<Object?> get props => [status, all, suppliers, supplierId, query];
}

