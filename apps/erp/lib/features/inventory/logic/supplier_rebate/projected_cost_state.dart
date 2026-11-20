import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_models.dart';

class ProjectedCostState {
  final String productId;
  final String extraText;
  final String priceText;
  final ProjectedCost? result;
  final bool loading;
  final bool error;

  const ProjectedCostState({
    required this.productId,
    this.extraText = '',
    this.priceText = '',
    this.result,
    this.loading = false,
    this.error = false,
  });

  ProjectedCostState copyWith({
    String? productId,
    String? extraText,
    String? priceText,
    ProjectedCost? result,
    bool clearResult = false,
    bool? loading,
    bool? error,
  }) {
    return ProjectedCostState(
      productId: productId ?? this.productId,
      extraText: extraText ?? this.extraText,
      priceText: priceText ?? this.priceText,
      result: clearResult ? null : (result ?? this.result),
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }
}

