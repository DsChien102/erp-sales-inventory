import 'package:equatable/equatable.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';

enum StocktakeCreateStatus { loading, loadError, ready, submitting }

class StocktakeCreateState extends Equatable {
  const StocktakeCreateState({
    this.status = StocktakeCreateStatus.loading,
    this.options,
    this.scopeKind = StocktakeScopeKind.all,
    this.selectedProductId,
    this.selectedLotId,
    this.counterUserId = '',
    this.reason = 'Kiểm kê định kỳ',
    this.reasonTouched = false,
    this.conflict,
    this.submitError,
    this.isScopeEmptyError = false,
    this.openedSessionId,
  });

  final StocktakeCreateStatus status;
  final StocktakeFormOptions? options;
  final StocktakeScopeKind scopeKind;
  final String? selectedProductId;
  final String? selectedLotId;
  final String counterUserId;
  final String reason;
  final bool reasonTouched;
  final StocktakeConflict? conflict;
  final String? submitError;
  final bool isScopeEmptyError;
  final String? openedSessionId;

  StocktakeProductOption? get selectedProduct {
    final opts = options;
    final id = selectedProductId;
    if (opts == null || id == null) return null;
    for (final p in opts.products) {
      if (p.id == id) return p;
    }
    return null;
  }

  StocktakeLotOption? get selectedLot {
    final opts = options;
    final id = selectedLotId;
    if (opts == null || id == null) return null;
    for (final l in opts.lots) {
      if (l.id == id) return l;
    }
    return null;
  }

  bool get isScopeKnown => switch (scopeKind) {
    StocktakeScopeKind.all => options != null,
    StocktakeScopeKind.product => selectedProduct != null,
    StocktakeScopeKind.lot => selectedLot != null,
  };

  int get scopeLineCount => switch (scopeKind) {
    StocktakeScopeKind.all => options?.allCount ?? 0,
    StocktakeScopeKind.product => selectedProduct?.lineCount ?? 0,
    StocktakeScopeKind.lot => selectedLot != null ? 1 : 0,
  };

  String? get scopeDisplayName => switch (scopeKind) {
    StocktakeScopeKind.all => 'Toàn kho',
    StocktakeScopeKind.product => selectedProduct?.name,
    StocktakeScopeKind.lot =>
      selectedLot == null
          ? null
          : '${selectedLot!.productName} · Lô ${selectedLot!.lotCode}',
  };

  String? get counterName {
    final opts = options;
    if (opts == null) return null;
    for (final m in opts.members) {
      if (m.userId == counterUserId) return m.name;
    }
    return null;
  }

  String? get blocker {
    if (!isScopeKnown) return 'Chọn phạm vi cụ thể';
    if (reason.trim().isEmpty) return 'Nhập lý do kiểm kê';
    return null;
  }

  /// Danh sách tên mặt hàng trong phạm vi để tóm tắt trên cột phụ web.
  List<String> get previewItems {
    final opts = options;
    if (opts == null || !isScopeKnown) return const [];
    if (scopeKind == StocktakeScopeKind.lot) {
      final l = selectedLot!;
      return ['${l.productName} · Lô ${l.lotCode}'];
    }
    if (scopeKind == StocktakeScopeKind.product) {
      final p = selectedProduct!;
      final lots = opts.lots
          .where((l) => l.productId == p.id)
          .map((l) => '${l.productName} · Lô ${l.lotCode}')
          .toList(growable: false);
      return lots.isNotEmpty ? lots : [p.name];
    }

    final lotsByProduct = <String, List<StocktakeLotOption>>{};
    for (final l in opts.lots) {
      lotsByProduct.putIfAbsent(l.productId, () => []).add(l);
    }
    final items = <String>[];
    for (final p in opts.products) {
      final pLots = lotsByProduct[p.id];
      if (pLots != null && pLots.isNotEmpty) {
        for (final l in pLots) {
          items.add('${l.productName} · Lô ${l.lotCode}');
        }
      } else {
        items.add(p.name);
      }
    }
    return items;
  }

  StocktakeCreateState copyWith({
    StocktakeCreateStatus? status,
    StocktakeFormOptions? options,
    StocktakeScopeKind? scopeKind,
    String? selectedProductId,
    bool clearSelectedProduct = false,
    String? selectedLotId,
    bool clearSelectedLot = false,
    String? counterUserId,
    String? reason,
    bool? reasonTouched,
    StocktakeConflict? conflict,
    bool clearConflict = false,
    String? submitError,
    bool clearSubmitError = false,
    bool? isScopeEmptyError,
    String? openedSessionId,
  }) {
    return StocktakeCreateState(
      status: status ?? this.status,
      options: options ?? this.options,
      scopeKind: scopeKind ?? this.scopeKind,
      selectedProductId: clearSelectedProduct
          ? null
          : (selectedProductId ?? this.selectedProductId),
      selectedLotId: clearSelectedLot
          ? null
          : (selectedLotId ?? this.selectedLotId),
      counterUserId: counterUserId ?? this.counterUserId,
      reason: reason ?? this.reason,
      reasonTouched: reasonTouched ?? this.reasonTouched,
      conflict: clearConflict ? null : (conflict ?? this.conflict),
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      isScopeEmptyError: isScopeEmptyError ?? this.isScopeEmptyError,
      openedSessionId: openedSessionId ?? this.openedSessionId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    options,
    scopeKind,
    selectedProductId,
    selectedLotId,
    counterUserId,
    reason,
    reasonTouched,
    conflict,
    submitError,
    isScopeEmptyError,
    openedSessionId,
  ];
}

