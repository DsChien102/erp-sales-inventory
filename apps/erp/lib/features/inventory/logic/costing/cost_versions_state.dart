import 'package:equatable/equatable.dart';
import 'package:erp/features/inventory/data/costing/costing_models.dart';

enum CostVersionsStatus { loading, ready, error }

class CostVersionsState extends Equatable {
  const CostVersionsState({
    this.status = CostVersionsStatus.loading,
    this.data,
    this.message,
  });

  final CostVersionsStatus status;
  final CostVersionList? data;
  final String? message;

  CostVersionsState copyWith({
    CostVersionsStatus? status,
    CostVersionList? data,
    String? message,
    bool clearMessage = false,
  }) {
    return CostVersionsState(
      status: status ?? this.status,
      data: data ?? this.data,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [status, data, message];
}

