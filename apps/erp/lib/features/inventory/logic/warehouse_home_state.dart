import 'package:equatable/equatable.dart';

import '../data/models/warehouse_manual_action.dart';
import '../data/models/warehouse_task_item.dart';

sealed class WarehouseHomeState extends Equatable {
  const WarehouseHomeState();

  @override
  List<Object?> get props => [];
}

class WarehouseHomeInitial extends WarehouseHomeState {
  const WarehouseHomeInitial();
}

class WarehouseHomeLoading extends WarehouseHomeState {
  const WarehouseHomeLoading();
}

class WarehouseHomeLoaded extends WarehouseHomeState {
  const WarehouseHomeLoaded({
    required this.allTasks,
    required this.filteredTasks,
    required this.utilities,
    required this.manualActions,
    this.searchQuery = '',
  });

  final List<WarehouseTaskItem> allTasks;
  final List<WarehouseTaskItem> filteredTasks;
  final List<WarehouseTaskItem> utilities;
  final List<WarehouseManualAction> manualActions;
  final String searchQuery;

  @override
  List<Object?> get props => [
        allTasks,
        filteredTasks,
        utilities,
        manualActions,
        searchQuery,
      ];

  WarehouseHomeLoaded copyWith({
    List<WarehouseTaskItem>? allTasks,
    List<WarehouseTaskItem>? filteredTasks,
    List<WarehouseTaskItem>? utilities,
    List<WarehouseManualAction>? manualActions,
    String? searchQuery,
  }) {
    return WarehouseHomeLoaded(
      allTasks: allTasks ?? this.allTasks,
      filteredTasks: filteredTasks ?? this.filteredTasks,
      utilities: utilities ?? this.utilities,
      manualActions: manualActions ?? this.manualActions,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class WarehouseHomeError extends WarehouseHomeState {
  const WarehouseHomeError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
