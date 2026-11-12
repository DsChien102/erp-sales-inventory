import 'package:equatable/equatable.dart';
import 'package:erp/features/inventory/data/costing/costing_models.dart';

enum CostOverviewStatus { loading, ready, denied, error }

enum CostRunFilter { todo, done }

class CostOverviewState extends Equatable {
  const CostOverviewState({
    this.status = CostOverviewStatus.loading,
    this.data,
    this.filter = CostRunFilter.todo,
    this.message,
    this.savingMethod = false,
  });

  final CostOverviewStatus status;
  final CostOverview? data;
  final CostRunFilter filter;
  final String? message;
  final bool savingMethod;

  CostOverviewState copyWith({
    CostOverviewStatus? status,
    CostOverview? data,
    CostRunFilter? filter,
    String? message,
    bool clearMessage = false,
    bool? savingMethod,
  }) {
    return CostOverviewState(
      status: status ?? this.status,
      data: data ?? this.data,
      filter: filter ?? this.filter,
      message: clearMessage ? null : (message ?? this.message),
      savingMethod: savingMethod ?? this.savingMethod,
    );
  }

  @override
  List<Object?> get props => [status, data, filter, message, savingMethod];
}

