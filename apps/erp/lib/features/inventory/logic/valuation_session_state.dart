import '../data/models/valuation_group_item.dart';
import '../data/models/valuation_result_model.dart';
import '../data/models/valuation_work_item.dart';

enum ValuationSessionStatus {
  initial,
  loading,
  ready,
  sourceChanged,
  confirming,
  confirmed,
  failure,
}

class ValuationSessionState {
  const ValuationSessionState({
    this.receiptId = '',
    this.receiptNumber = '',
    this.supplierName = '',
    this.receivedAt = '',
    this.entryType = ValuationEntryType.document,
    this.groups = const [],
    this.sourceVersion = 1,
    this.reviewSourceVersion,
    this.lastResult,
    this.status = ValuationSessionStatus.initial,
    this.errorMessage,
  });

  final String receiptId;
  final String receiptNumber;
  final String supplierName;
  final String receivedAt;
  final ValuationEntryType entryType;
  final List<ValuationGroupItem> groups;
  final int sourceVersion;
  final int? reviewSourceVersion;
  final ValuationResultModel? lastResult;
  final ValuationSessionStatus status;
  final String? errorMessage;

  bool get isLoading => status == ValuationSessionStatus.loading;
  bool get isConfirming => status == ValuationSessionStatus.confirming;
  bool get isConfirmed => status == ValuationSessionStatus.confirmed;

  List<ValuationGroupItem> get pendingGroups =>
      groups.where((g) => g.pendingQty > 0).toList();

  List<ValuationGroupItem> get selectedGroups =>
      groups.where((g) => g.isSelected && g.pendingQty > 0).toList();

  bool get canReview =>
      selectedGroups.isNotEmpty &&
      selectedGroups.every((g) => g.status == ValuationGroupStatus.ready);

  double get totalSelectedValue =>
      selectedGroups.fold(0.0, (sum, g) => sum + g.totalValue);

  bool get isStaleForReview =>
      reviewSourceVersion != null && reviewSourceVersion != sourceVersion;

  ValuationSessionState copyWith({
    String? receiptId,
    String? receiptNumber,
    String? supplierName,
    String? receivedAt,
    ValuationEntryType? entryType,
    List<ValuationGroupItem>? groups,
    int? sourceVersion,
    int? reviewSourceVersion,
    ValuationResultModel? lastResult,
    ValuationSessionStatus? status,
    String? errorMessage,
  }) {
    return ValuationSessionState(
      receiptId: receiptId ?? this.receiptId,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      supplierName: supplierName ?? this.supplierName,
      receivedAt: receivedAt ?? this.receivedAt,
      entryType: entryType ?? this.entryType,
      groups: groups ?? this.groups,
      sourceVersion: sourceVersion ?? this.sourceVersion,
      reviewSourceVersion: reviewSourceVersion ?? this.reviewSourceVersion,
      lastResult: lastResult ?? this.lastResult,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
