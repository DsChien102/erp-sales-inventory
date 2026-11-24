import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/logic/supplier_program/program_list_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProgramListCubit extends Cubit<ProgramListState> {
  final SupplierProgramRepository _repository;

  ProgramListCubit({
    required SupplierProgramRepository repository,
    String? initialSupplierId,
    ProgramStatus? initialStatus,
  })  : _repository = repository,
        super(
          ProgramListState(
            supplierId: initialSupplierId,
            statusFilter: initialStatus ?? ProgramStatus.active,
          ),
        );

  Future<void> load() async {
    emit(state.copyWith(status: ProgramListStatus.loading));
    try {
      final results = await Future.wait([
        _repository.list(),
        _repository.formOptions(),
      ]);
      final rows = results[0] as List<ProgramRow>;
      final opts = results[1] as ProgramFormOptions;
      emit(
        state.copyWith(
          status:
              rows.isEmpty ? ProgramListStatus.empty : ProgramListStatus.ready,
          all: rows,
          options: opts,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: ProgramListStatus.loadError));
    }
  }

  Future<void> refresh() => load();

  void setStatus(ProgramStatus s) {
    emit(state.copyWith(statusFilter: s));
  }

  void setSupplier(String? id) {
    if (id == null || id.isEmpty) {
      emit(state.copyWith(clearSupplier: true));
    } else {
      emit(state.copyWith(supplierId: id));
    }
  }

  void setProduct(String? id) {
    if (id == null || id.isEmpty) {
      emit(state.copyWith(clearProduct: true));
    } else {
      emit(state.copyWith(productId: id));
    }
  }

  void setQuery(String q) {
    emit(state.copyWith(query: q));
  }

  void clearFilters() {
    emit(
      state.copyWith(
        clearSupplier: true,
        clearProduct: true,
        query: '',
      ),
    );
  }
}

