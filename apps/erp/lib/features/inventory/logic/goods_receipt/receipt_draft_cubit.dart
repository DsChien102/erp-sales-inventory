import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_repository.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_draft.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_draft_state.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_line_rules.dart';

class ReceiptDraftCubit extends Cubit<ReceiptDraftState> {
  ReceiptDraftCubit({
    required GoodsReceiptRepository repository,
    required SupplierProgramRepository programs,
    String? initialProductId,
    Duration hintDebounce = const Duration(milliseconds: 400),
  })  : _repository = repository,
        _programs = programs,
        _initialProductId = initialProductId,
        _hintDebounce = hintDebounce,
        super(const ReceiptDraftState());

  final GoodsReceiptRepository _repository;
  final SupplierProgramRepository _programs;
  final String? _initialProductId;
  final Duration _hintDebounce;

  final Map<String, Timer> _debounceTimers = {};

  /// % chiết khấu theo `programId`, lấy một lần từ chi tiết chương trình (không nhớ khi lỗi).
  final Map<String, num?> _rebatePercents = {};
  int _lineSeq = 1;
  int _lotSeq = 1;

  bool get isDirty =>
      state.draft.supplier != null ||
      state.draft.docNo.trim().isNotEmpty ||
      state.draft.lines.isNotEmpty;

  void setIdempotencyKeyForTesting(String key) {
    emit(state.copyWith(idempotencyKey: key));
  }

  Future<void> load() async {
    emit(state.copyWith(status: ReceiptDraftStatus.loading));
    try {
      final opts = await _repository.formOptions();
      emit(state.copyWith(
        status: ReceiptDraftStatus.ready,
        options: opts,
      ));
    } catch (_) {
      emit(state.copyWith(status: ReceiptDraftStatus.loadFailed));
    }
  }

  void selectSupplier(ReceiptSupplierOption supplier) {
    final oldSupplier = state.draft.supplier;
    final isDifferent = oldSupplier?.id != supplier.id;

    var updatedLines = state.draft.lines;
    if (isDifferent) {
      updatedLines = updatedLines.map((line) {
        return line.copyWith(
          clearProgramId: true,
          clearTierPercent: true,
          clearHint: true,
          clearRebatePercent: true,
          freeQty: line.freeEdited ? line.freeQty : 0,
        );
      }).toList();
    }

    emit(state.copyWith(
      draft: state.draft.copyWith(
        supplier: supplier,
        lines: updatedLines,
      ),
      clearIdempotencyKey: true,
    ));

    if (isDifferent && !supplier.isSystem && updatedLines.isNotEmpty) {
      refreshAllHints();
    }
  }

  String? addInitialProductLine() {
    if (_initialProductId == null) return null;
    final alreadyAdded =
        state.draft.lines.any((l) => l.product.id == _initialProductId);
    if (alreadyAdded) return null;

    final product = state.options?.products
        .where((p) => p.id == _initialProductId)
        .firstOrNull;
    if (product == null) return null;

    return addLine(product.id, product.baseUnit.id);
  }

  void setDocNo(String docNo) {
    emit(state.copyWith(
      draft: state.draft.copyWith(docNo: docNo),
      clearIdempotencyKey: true,
    ));
  }

  String addLine(String productId, String unitId) {
    // Không thêm dòng trùng product_id và unit_id
    final existing = state.draft.lines.where(
      (l) => l.product.id == productId && l.unit.id == unitId,
    ).firstOrNull;
    if (existing != null) {
      return existing.key;
    }

    final product = state.options?.products.firstWhere((p) => p.id == productId);
    if (product == null) {
      throw StateError('Sản phẩm không tìm thấy: $productId');
    }
    final unit = product.units.firstWhere((u) => u.id == unitId);

    final lineKey = 'line_${_lineSeq++}';
    final initialLot = ReceiptLotEntry(
      key: 'lot_${_lotSeq++}',
      code: '',
      expiryText: '',
      manufactureText: '',
      quantity: 0,
    );

    final newLine = ReceiptLineDraft(
      key: lineKey,
      product: product,
      unit: unit,
      unitPriceVnd: 0,
      lots: [initialLot],
    );

    emit(state.copyWith(
      draft: state.draft.copyWith(
        lines: [...state.draft.lines, newLine],
      ),
      clearIdempotencyKey: true,
    ));

    return lineKey;
  }

  void selectLine(String? key) {
    emit(state.copyWith(
      selectedLineKey: key,
      clearSelectedLineKey: key == null,
    ));
  }

  void updateLine(String key, ReceiptLineDraft Function(ReceiptLineDraft) change) {
    final idx = state.draft.lines.indexWhere((l) => l.key == key);
    if (idx < 0) return;

    final oldLine = state.draft.lines[idx];
    final newLine = change(oldLine);

    final updatedLines = List<ReceiptLineDraft>.from(state.draft.lines);
    updatedLines[idx] = newLine;

    emit(state.copyWith(
      draft: state.draft.copyWith(lines: updatedLines),
      clearIdempotencyKey: true,
    ));

    // Debounce lấy gợi ý ưu đãi khi số lượng hoặc đơn giá thay đổi
    final qtyChanged = oldLine.paidQuantity != newLine.paidQuantity;
    final priceChanged = oldLine.unitPriceVnd != newLine.unitPriceVnd;
    if (qtyChanged || priceChanged) {
      final supplier = state.draft.supplier;
      if (supplier != null && !supplier.isSystem) {
        _debounceTimers[key]?.cancel();
        _debounceTimers[key] = Timer(_hintDebounce, () {
          _fetchHintForLine(key);
        });
      }
    }
  }

  void removeLine(String key) {
    _debounceTimers[key]?.cancel();
    _debounceTimers.remove(key);

    emit(state.copyWith(
      draft: state.draft.copyWith(
        lines: state.draft.lines.where((l) => l.key != key).toList(),
      ),
      clearIdempotencyKey: true,
    ));
  }

  void setFreightVnd(int freight) {
    emit(state.copyWith(
      draft: state.draft.copyWith(freightVnd: freight),
      clearIdempotencyKey: true,
    ));
  }

  void setDiscountVnd(int discount) {
    emit(state.copyWith(
      draft: state.draft.copyWith(discountVnd: discount),
      clearIdempotencyKey: true,
    ));
  }

  Future<void> refreshAllHints() async {
    final supplier = state.draft.supplier;
    if (supplier == null || supplier.isSystem || state.draft.lines.isEmpty) {
      return;
    }

    emit(state.copyWith(hintsLoading: true));
    try {
      final inputs = [
        for (final l in state.draft.lines)
          (
            productId: l.product.id,
            paidQty: l.paidQuantity * l.unit.rate,
            unitPrice: (l.unitPriceVnd / (l.unit.rate > 0 ? l.unit.rate : 1)).round(),
          ),
      ];

      final hints = await _programs.receiptHints(
        supplierId: supplier.id,
        lines: inputs,
      );

      final updatedLines = <ReceiptLineDraft>[];
      for (var i = 0; i < state.draft.lines.length; i++) {
        final line = state.draft.lines[i];
        final hint = i < hints.length ? hints[i] : null;
        updatedLines.add(applyHint(line, hint));
      }

      emit(state.copyWith(
        draft: state.draft.copyWith(lines: updatedLines),
        hintsLoading: false,
      ));
      for (final line in updatedLines) {
        await _syncRebatePercent(line.key);
      }
    } catch (_) {
      emit(state.copyWith(hintsLoading: false));
    }
  }

  /// Lấy % chiết khấu cho dòng có chương trình đạt mốc; dòng không còn hint đạt mốc thì xoá.
  Future<void> _syncRebatePercent(String lineKey) async {
    final line = state.draft.lines.where((l) => l.key == lineKey).firstOrNull;
    if (line == null) return;

    final programId = line.programId;
    if (line.hint?.kind != ProgramKind.volumeRebate || programId == null) {
      if (line.rebatePercent != null) _setRebatePercent(lineKey, null, null);
      return;
    }

    if (!_rebatePercents.containsKey(programId)) {
      try {
        final detail = await _programs.get(programId);
        _rebatePercents[programId] = detail.row.rebatePercent;
      } catch (_) {
        return; // Lỗi: giữ banner như cũ, không hiện lỗi.
      }
    }
    _setRebatePercent(lineKey, programId, _rebatePercents[programId]);
  }

  void _setRebatePercent(String lineKey, String? programId, num? percent) {
    final idx = state.draft.lines.indexWhere((l) => l.key == lineKey);
    if (idx < 0) return;
    final current = state.draft.lines[idx];
    // Dòng đã đổi chương trình trong lúc chờ: bỏ kết quả cũ.
    if (programId != null && current.programId != programId) return;

    final lines = List<ReceiptLineDraft>.from(state.draft.lines);
    lines[idx] = percent == null
        ? current.copyWith(clearRebatePercent: true)
        : current.copyWith(rebatePercent: percent);
    emit(state.copyWith(draft: state.draft.copyWith(lines: lines)));
  }

  Future<void> _fetchHintForLine(String lineKey) async {
    final supplier = state.draft.supplier;
    if (supplier == null || supplier.isSystem) return;

    final line = state.draft.lines.where((l) => l.key == lineKey).firstOrNull;
    if (line == null) return;

    try {
      final hints = await _programs.receiptHints(
        supplierId: supplier.id,
        lines: [
          (
            productId: line.product.id,
            paidQty: line.paidQuantity * line.unit.rate,
            unitPrice: (line.unitPriceVnd / (line.unit.rate > 0 ? line.unit.rate : 1)).round(),
          ),
        ],
      );

      final hint = hints.firstOrNull;
      final currentIdx = state.draft.lines.indexWhere((l) => l.key == lineKey);
      if (currentIdx >= 0) {
        final currentLine = state.draft.lines[currentIdx];
        final applied = applyHint(currentLine, hint);
        final lines = List<ReceiptLineDraft>.from(state.draft.lines);
        lines[currentIdx] = applied;
        emit(state.copyWith(draft: state.draft.copyWith(lines: lines)));
        await _syncRebatePercent(lineKey);
      }
    } catch (_) {
      // Ignore hint failure
    }
  }

  Future<void> prepareReview() async {
    final updatedLines = state.draft.lines.map((l) {
      return l.hintAtEntry == null ? l.copyWith(hintAtEntry: l.hint) : l;
    }).toList();
    emit(state.copyWith(draft: state.draft.copyWith(lines: updatedLines)));
    await refreshAllHints();
  }

  Future<void> submit() async {
    if (state.submit == ReceiptSubmitStatus.submitting) return;

    final key = state.idempotencyKey ?? 'idem_${DateTime.now().microsecondsSinceEpoch}';
    emit(state.copyWith(
      submit: ReceiptSubmitStatus.submitting,
      idempotencyKey: key,
      clearSubmitError: true,
      submitNetworkError: false,
    ));

    try {
      final payload = state.draft.toPayload();
      final result = await _repository.record(
        idempotencyKey: key,
        payload: payload,
      );
      emit(state.copyWith(
        submit: ReceiptSubmitStatus.idle,
        result: result,
        clearSubmitError: true,
        submitNetworkError: false,
      ));
    } on AppException catch (e) {
      if (e.code == 'RECEIPT_PROGRAM_CHANGED') {
        emit(state.copyWith(
          submit: ReceiptSubmitStatus.failed,
          submitError: e.code,
          clearIdempotencyKey: true,
          submitNetworkError: false,
        ));
        await refreshAllHints();
      } else if (e.code == 'NETWORK_ERROR' || e.code.contains('NETWORK')) {
        emit(state.copyWith(
          submit: ReceiptSubmitStatus.failed,
          submitError: e.code,
          submitNetworkError: true,
        ));
      } else {
        emit(state.copyWith(
          submit: ReceiptSubmitStatus.failed,
          submitError: e.code,
          submitNetworkError: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        submit: ReceiptSubmitStatus.failed,
        submitError: e.toString(),
        submitNetworkError: false,
      ));
    }
  }

  @override
  Future<void> close() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    return super.close();
  }
}
