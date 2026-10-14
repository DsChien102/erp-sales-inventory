import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/valuation_direct_basis_draft.dart';
import '../data/valuation_repository.dart';
import 'valuation_session_state.dart';

class ValuationSessionCubit extends Cubit<ValuationSessionState> {
  ValuationSessionCubit({required ValuationRepository repository})
      : _repository = repository,
        super(const ValuationSessionState());

  final ValuationRepository _repository;

  Future<void> loadReceipt(String receiptId) async {
    emit(state.copyWith(status: ValuationSessionStatus.loading));
    try {
      final data = await _repository.getReceiptValuation(receiptId);
      emit(state.copyWith(
        status: ValuationSessionStatus.ready,
        receiptId: data.id,
        receiptNumber: data.receiptNumber,
        supplierName: data.supplierName,
        receivedAt: data.receivedAt,
        entryType: data.entryType,
        groups: data.groups,
        sourceVersion: data.sourceVersion,
        reviewSourceVersion: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ValuationSessionStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void toggleGroupSelection(String groupId) {
    final updatedGroups = state.groups.map((g) {
      if (g.id == groupId) {
        return g.copyWith(isSelected: !g.isSelected);
      }
      return g;
    }).toList();
    emit(state.copyWith(groups: updatedGroups));
  }

  void selectAll(bool select) {
    final updatedGroups = state.groups.map((g) {
      return g.copyWith(isSelected: select);
    }).toList();
    emit(state.copyWith(groups: updatedGroups));
  }

  void prepareReview() {
    emit(state.copyWith(reviewSourceVersion: state.sourceVersion));
  }

  Future<void> addDirectBasis(
    String groupId,
    ValuationDirectBasisDraft draft,
  ) async {
    try {
      final updatedData = await _repository.saveDirectBasis(
        receiptId: state.receiptId,
        groupId: groupId,
        draft: draft,
      );
      emit(state.copyWith(
        groups: updatedData.groups,
        sourceVersion: updatedData.sourceVersion,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> confirmValuation() async {
    final selectedIds = state.selectedGroups.map((g) => g.id).toList();
    if (selectedIds.isEmpty) return;

    emit(state.copyWith(status: ValuationSessionStatus.confirming));
    try {
      final result = await _repository.confirmValuation(
        receiptId: state.receiptId,
        selectedGroupIds: selectedIds,
      );
      emit(state.copyWith(
        status: ValuationSessionStatus.confirmed,
        lastResult: result,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ValuationSessionStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
