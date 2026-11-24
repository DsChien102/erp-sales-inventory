import 'package:equatable/equatable.dart';
import 'package:erp/features/catalog/data/models.dart';

enum ProductControlCenterStatus { initial, loading, success, failure }

enum ProductLifecycleActionStatus { initial, loading, success, failure, warning }

final class ProductControlCenterState extends Equatable {
  const ProductControlCenterState({
    this.status = ProductControlCenterStatus.initial,
    this.controlCenter,
    this.readinessView,
    this.errorMessage,
    this.actionStatus = ProductLifecycleActionStatus.initial,
    this.actionErrorMessage,
    this.actionWarnings,
  });

  final ProductControlCenterStatus status;
  final ProductControlCenterDto? controlCenter;
  final ProductReadinessViewDto? readinessView;
  final String? errorMessage;

  final ProductLifecycleActionStatus actionStatus;
  final String? actionErrorMessage;
  final List<ProductBusinessStatusWarningDto>? actionWarnings;

  ProductControlCenterState copyWith({
    ProductControlCenterStatus? status,
    ProductControlCenterDto? controlCenter,
    ProductReadinessViewDto? readinessView,
    String? errorMessage,
    ProductLifecycleActionStatus? actionStatus,
    String? actionErrorMessage,
    List<ProductBusinessStatusWarningDto>? actionWarnings,
    bool clearActionWarnings = false,
  }) {
    return ProductControlCenterState(
      status: status ?? this.status,
      controlCenter: controlCenter ?? this.controlCenter,
      readinessView: readinessView ?? this.readinessView,
      errorMessage: errorMessage ?? this.errorMessage,
      actionStatus: actionStatus ?? this.actionStatus,
      actionErrorMessage: actionErrorMessage ?? this.actionErrorMessage,
      actionWarnings: clearActionWarnings ? null : (actionWarnings ?? this.actionWarnings),
    );
  }

  @override
  List<Object?> get props => [
    status,
    controlCenter,
    readinessView,
    errorMessage,
    actionStatus,
    actionErrorMessage,
    actionWarnings,
  ];
}
