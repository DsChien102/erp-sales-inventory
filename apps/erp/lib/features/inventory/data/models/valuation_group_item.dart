import 'valuation_cost_source.dart';

enum ValuationGroupStatus {
  ready,
  commercialConflict,
  commercialMissing,
  directMissing;

  String get label => switch (this) {
        ValuationGroupStatus.ready => 'Sẵn sàng',
        ValuationGroupStatus.commercialConflict => 'Cần đối chiếu',
        ValuationGroupStatus.commercialMissing => 'Cần căn cứ',
        ValuationGroupStatus.directMissing => 'Chưa có căn cứ',
      };
}

class ValuationGroupItem {
  const ValuationGroupItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.uom,
    this.tracking = 'NONE',
    required this.pendingQty,
    this.lotsCount = 0,
    required this.status,
    this.sources = const [],
    this.selectedSourceId,
    this.isSelected = false,
  });

  final String id;
  final String productId;
  final String productName;
  final String productCode;
  final String uom;
  final String tracking;
  final double pendingQty;
  final int lotsCount;
  final ValuationGroupStatus status;
  final List<ValuationCostSource> sources;
  final String? selectedSourceId;
  final bool isSelected;

  ValuationCostSource? get selectedSource {
    if (sources.isEmpty) return null;
    if (selectedSourceId != null) {
      return sources.cast<ValuationCostSource?>().firstWhere(
            (s) => s?.id == selectedSourceId,
            orElse: () => sources.first,
          );
    }
    return sources.first;
  }

  double? get unitActual => selectedSource?.unitActual;

  double get totalValue {
    final actual = unitActual;
    if (actual == null) return 0;
    return actual * pendingQty;
  }

  ValuationGroupItem copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productCode,
    String? uom,
    String? tracking,
    double? pendingQty,
    int? lotsCount,
    ValuationGroupStatus? status,
    List<ValuationCostSource>? sources,
    String? selectedSourceId,
    bool? isSelected,
  }) {
    return ValuationGroupItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      uom: uom ?? this.uom,
      tracking: tracking ?? this.tracking,
      pendingQty: pendingQty ?? this.pendingQty,
      lotsCount: lotsCount ?? this.lotsCount,
      status: status ?? this.status,
      sources: sources ?? this.sources,
      selectedSourceId: selectedSourceId ?? this.selectedSourceId,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
