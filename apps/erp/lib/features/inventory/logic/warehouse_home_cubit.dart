import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/inventory_repository.dart';
import 'warehouse_home_state.dart';

class WarehouseHomeCubit extends Cubit<WarehouseHomeState> {
  WarehouseHomeCubit({InventoryRepository? repository})
      : _repository = repository ?? const InventoryRepository(),
        super(const WarehouseHomeInitial());

  final InventoryRepository _repository;

  Future<void> load() async {
    emit(const WarehouseHomeLoading());
    try {
      final tasks = await _repository.getPendingTasks();
      final utilities = _repository.getLookupUtilities();
      final manualActions = _repository.getManualActions();

      emit(WarehouseHomeLoaded(
        allTasks: tasks,
        filteredTasks: tasks,
        utilities: utilities,
        manualActions: manualActions,
      ));
    } catch (e) {
      emit(WarehouseHomeError(e.toString()));
    }
  }

  void search(String query) {
    final current = state;
    if (current is! WarehouseHomeLoaded) return;

    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      emit(current.copyWith(
        filteredTasks: current.allTasks,
        searchQuery: '',
      ));
      return;
    }

    final filtered = current.allTasks.where((task) {
      return task.title.toLowerCase().contains(trimmed) ||
          task.subtitle.toLowerCase().contains(trimmed) ||
          (task.badgeLabel?.toLowerCase().contains(trimmed) ?? false);
    }).toList();

    emit(current.copyWith(
      filteredTasks: filtered,
      searchQuery: query,
    ));
  }
}
