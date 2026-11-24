import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:c45_design_system/design_system.dart';

enum ProgramListStatus {
  loading,
  ready,
  empty,
  loadError,
}

class ProgramListState {
  final ProgramListStatus status;
  final List<ProgramRow> all;
  final ProgramFormOptions? options;
  final ProgramStatus statusFilter;
  final String? supplierId;
  final String? productId;
  final String query;

  const ProgramListState({
    this.status = ProgramListStatus.loading,
    this.all = const [],
    this.options,
    this.statusFilter = ProgramStatus.active,
    this.supplierId,
    this.productId,
    this.query = '',
  });

  Iterable<ProgramRow> get _matchingDimensions {
    final normalizedQuery = VTextNormalizer.normalizeForSearch(query.trim());
    return all.where((r) {
      if (supplierId != null && r.supplierId != supplierId) {
        return false;
      }
      if (productId != null && !r.productIds.contains(productId)) {
        return false;
      }
      if (normalizedQuery.isNotEmpty) {
        final normalizedName = VTextNormalizer.normalizeForSearch(r.name);
        if (!normalizedName.contains(normalizedQuery)) {
          return false;
        }
      }
      return true;
    });
  }

  List<ProgramRow> get visible =>
      _matchingDimensions.where((r) => r.status == statusFilter).toList();

  int count(ProgramStatus s) =>
      _matchingDimensions.where((r) => r.status == s).length;

  bool get filterEmpty =>
      status == ProgramListStatus.ready && all.isNotEmpty && visible.isEmpty;

  ProgramListState copyWith({
    ProgramListStatus? status,
    List<ProgramRow>? all,
    ProgramFormOptions? options,
    ProgramStatus? statusFilter,
    String? supplierId,
    bool clearSupplier = false,
    String? productId,
    bool clearProduct = false,
    String? query,
  }) {
    return ProgramListState(
      status: status ?? this.status,
      all: all ?? this.all,
      options: options ?? this.options,
      statusFilter: statusFilter ?? this.statusFilter,
      supplierId: clearSupplier ? null : (supplierId ?? this.supplierId),
      productId: clearProduct ? null : (productId ?? this.productId),
      query: query ?? this.query,
    );
  }
}

