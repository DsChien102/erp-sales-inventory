import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/core/iam/idempotency_key_factory.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/receivable_models.dart';
import '../data/receivable_repository.dart';
import 'customer_collection_state.dart';
import 'receivable_allocation.dart';
import 'receivable_error_messages.dart';

/// CN-03: thu tiền theo khách vào các đơn đã tick (chia cũ trước).
class CustomerCollectionCubit extends Cubit<CustomerCollectionState> {
  CustomerCollectionCubit({
    required ReceivableRepository repository,
    required this.customerId,
    required this.orders,
    IdempotencyKeyFactory keyFactory = const UuidIdempotencyKeyFactory(),
  }) : _repository = repository,
       _keyFactory = keyFactory,
       super(
         CustomerCollectionState(
           preview: collectionPreview(orders: orders, selectedIds: const {}, amountMinor: 0),
         ),
       );

  final ReceivableRepository _repository;
  final IdempotencyKeyFactory _keyFactory;
  final String customerId;
  final List<OpenReceivableOrder> orders;

  static const _genericError = 'Không ghi nhận được. Thử lại?';

  bool get _locked => state.phase == CollectionPhase.submitting;

  CollectionPreview _preview(Set<String> ids, int amount) =>
      collectionPreview(orders: orders, selectedIds: ids, amountMinor: amount);

  /// Mọi lệnh sửa: khoá chống trùng đổi, trạng thái về `idle`.
  void _edit({Set<String>? ids, int? amount, CollectionMethod? method, String? reference}) {
    if (_locked) return;
    final nextIds = ids ?? state.selectedIds;
    final nextAmount = amount ?? state.amountMinor;
    emit(
      CustomerCollectionState(
        selectedIds: nextIds,
        amountMinor: nextAmount,
        method: method ?? state.method,
        externalReference: reference ?? state.externalReference,
        step: state.step,
        phase: CollectionPhase.idle,
        preview: _preview(nextIds, nextAmount),
      ),
    );
  }

  void toggleOrder(String salesOrderId) {
    final ids = {...state.selectedIds};
    if (!ids.add(salesOrderId)) ids.remove(salesOrderId);
    _edit(ids: ids, amount: _preview(ids, 0).scopeTotal);
  }

  void toggleAll() {
    final all = state.selectedIds.length == orders.length && orders.isNotEmpty;
    final ids = all ? <String>{} : {for (final o in orders) o.salesOrderId};
    _edit(ids: ids, amount: _preview(ids, 0).scopeTotal);
  }

  void setAmountText(String text) => _edit(amount: MoneyFormatter.parseMinor(text));

  void setMethod(CollectionMethod method) => _edit(method: method);

  void setReference(String text) => _edit(reference: text);

  void openConfirm() {
    if (_locked || !state.preview.canSubmit) return;
    emit(_copy(step: CollectionStep.confirm));
  }

  void backToForm() {
    if (_locked) return;
    emit(_copy(step: CollectionStep.form));
  }

  Future<void> submit() async {
    if (_locked || !state.preview.canSubmit) return;
    final key = state.idempotencyKey ?? _keyFactory.next('receivable-collection');
    emit(
      _copy(
        step: CollectionStep.form,
        phase: CollectionPhase.submitting,
        idempotencyKey: key,
        clearError: true,
      ),
    );
    final ref = state.externalReference.trim();
    try {
      final result = await _repository.recordCollection(
        CustomerCollectionRequest(
          customerId: customerId,
          amountMinor: state.amountMinor,
          method: state.method,
          externalReference: state.method == CollectionMethod.manualBankTransfer && ref.isNotEmpty
              ? ref
              : null,
          orderIds: [for (final o in state.preview.applicable) o.salesOrderId],
          expectedOutstandingMinor: state.preview.scopeTotal,
          idempotencyKey: key,
        ),
      );
      if (isClosed) return;
      emit(_copy(phase: CollectionPhase.success, result: result));
    } catch (e) {
      if (isClosed) return;
      final error = AppException.from(e);
      if (error.code == 'RECEIVABLE_CHANGED') {
        emit(_copy(phase: CollectionPhase.changed));
      } else {
        emit(
          _copy(
            phase: CollectionPhase.error,
            errorMessage: kReceivableErrorMessages.containsKey(error.code)
                ? error.userMessage(kReceivableErrorMessages)
                : _genericError,
          ),
        );
      }
    }
  }

  CustomerCollectionState _copy({
    CollectionStep? step,
    CollectionPhase? phase,
    String? errorMessage,
    bool clearError = false,
    String? idempotencyKey,
    CustomerCollectionResult? result,
  }) => CustomerCollectionState(
    selectedIds: state.selectedIds,
    amountMinor: state.amountMinor,
    method: state.method,
    externalReference: state.externalReference,
    step: step ?? state.step,
    phase: phase ?? state.phase,
    errorMessage: clearError ? null : (errorMessage ?? state.errorMessage),
    idempotencyKey: idempotencyKey ?? state.idempotencyKey,
    result: result ?? state.result,
    preview: state.preview,
  );
}
