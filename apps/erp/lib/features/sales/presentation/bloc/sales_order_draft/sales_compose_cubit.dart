import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_sales_application/application.dart';

import '../../lookups/sales_pricing_ports.dart';
import '../../models/sales_order_draft/sales_compose_customer_vm.dart';
import '../../models/sales_order_draft/sales_compose_line_vm.dart';
import '../../models/shared/sales_customer_selection.dart';
import '../../models/shared/sales_pricing_models.dart';
import '../../models/shared/sales_sellable_product_vm.dart';
import '../../support/sales_compose_draft_ref.dart';
import '../../support/sales_compose_line_reconcile.dart';
import '../../support/sales_external_lookups.dart';
import 'sales_checkout_prepare_result.dart';
import 'sales_compose_state.dart';
import 'sales_draft_contracts.dart';
import 'sales_manual_price_result.dart';

/// Compose orchestration — ERP feature cubit (Sales + Pricing + draft ports).
final class SalesComposeCubit extends Cubit<SalesComposeState> {
  SalesComposeCubit({
    required String draftId,
    required SalesPricingPreviewFn previewPricing,
    required SalesDraftPersistFn persistDraft,
    required SalesDraftRestoreFn restoreDraft,
    required SalesCheckoutPrepareFn prepareCheckout,
    required SalesManualPriceApplyFn applyManualPriceFlow,
    String? composeSessionId,
    Duration quantityPricingDebounceDuration = const Duration(milliseconds: 300),
  }) : _previewPricing = previewPricing,
       _persistDraft = persistDraft,
       _restoreDraft = restoreDraft,
       _prepareCheckout = prepareCheckout,
       _applyManualPriceFlow = applyManualPriceFlow,
       _quantityPricingDebounceDuration = quantityPricingDebounceDuration,
       _composeSessionId = (composeSessionId != null && composeSessionId.trim().isNotEmpty)
           ? composeSessionId.trim()
           : _newComposeSessionId(),
       super(
         SalesComposeLoading(
           draftId: draftId,
           customer: SalesComposeCustomerVm.walkIn(),
           lines: const <SalesComposeLineVm>[],
         ),
       );

  final SalesPricingPreviewFn _previewPricing;
  final SalesDraftPersistFn _persistDraft;
  final SalesDraftRestoreFn _restoreDraft;
  final SalesCheckoutPrepareFn _prepareCheckout;
  final SalesManualPriceApplyFn _applyManualPriceFlow;
  String _composeSessionId;
  final Duration _quantityPricingDebounceDuration;
  Timer? _quantityPricingDebounce;

  /// Stable local identity for first-save idempotency across retries.
  String get composeSessionId => _composeSessionId;

  static String _newComposeSessionId() =>
      'compose-${DateTime.now().microsecondsSinceEpoch}';

  SalesComposeLoaded _asLoaded(SalesComposeState s) {
    if (s is SalesComposeLoaded) return s;
    if (s is SalesComposeError) {
      throw StateError('Cannot promote SalesComposeError to SalesComposeLoaded');
    }
    return SalesComposeLoaded(
      draftId: s.draftId,
      customer: s.customer,
      lines: s.lines,
      orderNote: s.orderNote,
      pricing: s.pricing,
      save: s.save,
      busy: s.busy,
      title: s.title,
      draftVersion: s.draftVersion,
      restoreIssues: s.restoreIssues,
    );
  }

  void _emitLoaded({
    String? draftId,
    SalesComposeCustomerVm? customer,
    List<SalesComposeLineVm>? lines,
    String? orderNote,
    bool clearOrderNote = false,
    SalesComposePricingSlice? pricing,
    SalesComposeSaveSlice? save,
    SalesComposeBusy? busy,
    String? title,
    int? draftVersion,
    bool clearDraftVersion = false,
    List<SalesDraftRestoreIssue>? restoreIssues,
  }) {
    if (state is SalesComposeError) return;
    final current = _asLoaded(state);
    final nextLines = lines ?? current.lines;
    emit(
      SalesComposeLoaded(
        draftId: draftId ?? current.draftId,
        customer: customer ?? current.customer,
        lines: nextLines,
        orderNote: clearOrderNote ? null : (orderNote ?? current.orderNote),
        pricing: pricing ?? current.pricing,
        save: save ?? current.save,
        busy: busy ?? current.busy,
        title: title ?? (nextLines.isEmpty ? 'Tạo đơn' : 'Soạn đơn'),
        draftVersion: clearDraftVersion ? null : (draftVersion ?? current.draftVersion),
        restoreIssues: restoreIssues ?? current.restoreIssues,
      ),
    );
  }

  Future<void> loadDraft(String newDraftId) async {
    emit(
      SalesComposeLoading(
        draftId: newDraftId,
        customer: SalesComposeCustomerVm.walkIn(),
        lines: const <SalesComposeLineVm>[],
      ),
    );
    await hydrate();
  }

  /// Starts a fresh empty order after the current draft was saved or is gone.
  /// Rotates the compose session so the next first save gets a new
  /// idempotency identity instead of replaying the previous draft.
  Future<void> startNewDraft() async {
    _quantityPricingDebounce?.cancel();
    _composeSessionId = _newComposeSessionId();
    await loadDraft(SalesComposeDraftRef.newDraft);
  }

  Future<void> hydrate() async {
    final draftId = state.draftId.trim();
    if (SalesComposeDraftRef.isNew(draftId)) {
      emit(
        SalesComposeLoaded(
          draftId: SalesComposeDraftRef.newDraft,
          customer: SalesComposeCustomerVm.walkIn(),
          lines: const <SalesComposeLineVm>[],
          title: 'Tạo đơn',
          pricing: const SalesComposePricingSlice(
            status: SalesComposePricingStatus.ready,
            pricedContextVersion: 0,
          ),
        ),
      );
      return;
    }

    try {
      final restore = await _restoreDraft(draftId);
      if (isClosed) return;
      emit(
        SalesComposeLoaded(
          draftId: restore.draft.draftId,
          draftVersion: restore.draft.version,
          customer: restore.customer,
          lines: restore.lines,
          orderNote: restore.orderNote,
          title: restore.lines.isEmpty ? 'Tạo đơn' : 'Soạn đơn',
          pricing: SalesComposePricingSlice(
            status: SalesComposePricingStatus.ready,
            previewToken: restore.draft.pricingPreviewToken,
          ),
          save: const SalesComposeSaveSlice(status: SalesComposeSaveStatus.saved),
          restoreIssues: restore.issues,
        ),
      );
      await refreshPricingPreview();
    } catch (error) {
      if (isClosed) return;
      emit(
        SalesComposeError(
          draftId: draftId,
          message: _userSafeMessage(
            error,
            fallback: 'Không khôi phục được đơn nháp.',
          ),
        ),
      );
    }
  }

  Future<SalesCheckoutPrepareResult?> startCheckout() async {
    if (!state.canCheckout || state.busy != SalesComposeBusy.none) return null;
    final checkoutState = state;
    _emitLoaded(busy: SalesComposeBusy.checkingOut);
    try {
      return await _prepareCheckout(checkoutState);
    } finally {
      if (!isClosed && state.busy == SalesComposeBusy.checkingOut) {
        _emitLoaded(busy: SalesComposeBusy.none);
      }
    }
  }

  Future<SalesManualPriceResult?> adjustPrice({
    required SalesComposeLineVm line,
    required SalesManualPriceDraft draft,
    required SalesConfirmFn confirmBelowFloor,
    required SalesConfirmFn confirmOverwrite,
  }) async {
    if (state is SalesComposeError || state.busy != SalesComposeBusy.none) {
      return null;
    }
    _emitLoaded(busy: SalesComposeBusy.adjustingPrice);
    try {
      final outcome = await _applyManualPriceFlow(
        state: state,
        line: line,
        draft: draft,
        confirmBelowFloor: confirmBelowFloor,
        confirmOverwrite: confirmOverwrite,
      );
      if (outcome case SalesManualPriceApplied(:final acceptedDraft)) {
        applyManualPrice(line.identity.lineId, acceptedDraft);
      }
      return outcome;
    } finally {
      if (!isClosed && state.busy == SalesComposeBusy.adjustingPrice) {
        _emitLoaded(busy: SalesComposeBusy.none);
      }
    }
  }

  void setOrderNote(String? note) {
    if (state is SalesComposeError) return;
    _emitLoaded(
      orderNote: note,
      clearOrderNote: note == null || note.isEmpty,
      save: state.save.copyWith(
        status: SalesComposeSaveStatus.unsaved,
        clearMessage: true,
      ),
    );
  }

  void setCustomer(SalesComposeCustomerVm customer) {
    if (state is SalesComposeError) return;
    _mutatePricingContext(
      customer: customer,
      pricingMessage: 'Đã đổi khách — đang làm mới giá',
    );
  }

  void applyCustomerSelection(SalesCustomerSelection selection) {
    if (state is SalesComposeError) return;
    setCustomer(SalesComposeCustomerVm.fromSelection(selection));
  }

  void addOrIncrementLine(SalesProductSelection selection) {
    if (state is SalesComposeError) return;
    final current = state;
    final existingIndex = current.lines.indexWhere(
      (line) =>
          line.identity.productId == selection.productId &&
          line.identity.productUnitId == selection.productUnitId,
    );

    late final List<SalesComposeLineVm> next;
    if (existingIndex >= 0) {
      final existing = current.lines[existingIndex];
      final nextQty = existing.input.quantity + 1;
      if (existing.stock?.availableQuantity != null &&
          nextQty > existing.stock!.availableQuantity!) {
        return;
      }
      next = [
        for (var i = 0; i < current.lines.length; i++)
          if (i == existingIndex) existing.withQuantity(nextQty) else current.lines[i],
      ];
    } else {
      next = [
        ...current.lines,
        SalesComposeLineVm.fromProductSelection(
          lineId: 'line-${DateTime.now().microsecondsSinceEpoch}',
          selection: selection,
        ),
      ];
    }

    _mutatePricingContext(lines: next);
  }

  /// Đổi đơn vị bán trên một dòng (giữ SL). Trùng `productId+unit` với dòng khác → merge.
  ///
  /// Trả về message lỗi tồn (nếu có); `null` = thành công / no-op / dòng không còn.
  String? changeLineUnit(String lineId, SalesProductSelection selection) {
    if (state is SalesComposeError) return null;
    final index = state.lines.indexWhere((line) => line.identity.lineId == lineId);
    if (index < 0) return null;

    final current = state.lines[index];
    if (current.identity.productId == selection.productId &&
        current.identity.productUnitId == selection.productUnitId) {
      return null;
    }

    final mergeIndex = state.lines.indexWhere(
      (line) =>
          line.identity.lineId != lineId &&
          line.identity.productId == selection.productId &&
          line.identity.productUnitId == selection.productUnitId,
    );

    if (mergeIndex >= 0) {
      final target = state.lines[mergeIndex];
      final nextQty = target.input.quantity + current.input.quantity;
      final stock = target.stock?.availableQuantity ?? selection.stockQuantity;
      if (stock != null && nextQty > stock) {
        return 'Vượt tồn kho. Chỉ còn $stock ${selection.unitLabel}.';
      }

      final next = [
        for (var i = 0; i < state.lines.length; i++)
          if (i != index)
            (i == mergeIndex ? target.withQuantity(nextQty) : state.lines[i]),
      ];
      _mutatePricingContext(lines: next);
      return null;
    }

    final qty = current.input.quantity;
    if (selection.stockQuantity != null && qty > selection.stockQuantity!) {
      return 'Vượt tồn kho. Chỉ còn ${selection.stockQuantity} ${selection.unitLabel}.';
    }

    final replaced = SalesComposeLineVm.composed(
      identity: current.identity.copyWith(
        productUnitId: selection.productUnitId,
        unitLabel: selection.unitLabel,
        catalogUnitPrice: selection.listUnitPrice ?? selection.unitPrice,
        productName: selection.productName,
      ),
      input: ComposeLineUserInput(quantity: qty),
      pricing: ComposeLinePricingNotReady(
        provisionalAppliedUnitPrice: selection.unitPrice,
        provisionalListUnitPrice: selection.listUnitPrice,
        provisionalFloorUnitPrice: selection.floorUnitPrice,
      ),
      stock: selection.stockQuantity == null
          ? null
          : ComposeLineStockHint(availableQuantity: selection.stockQuantity),
    );

    final next = [
      for (var i = 0; i < state.lines.length; i++)
        if (i == index) replaced else state.lines[i],
    ];
    _mutatePricingContext(lines: next);
    return null;
  }

  String? updateQuantity(String lineId, int quantity) {
    if (state is SalesComposeError) return null;
    if (quantity < 1) {
      return 'Số lượng phải lớn hơn 0.';
    }
    final index = state.lines.indexWhere((l) => l.identity.lineId == lineId);
    if (index < 0) return null;
    final line = state.lines[index];

    final stock = line.stock?.availableQuantity;
    if (stock != null && quantity > stock) {
      return 'Vượt tồn kho. Chỉ còn $stock ${line.identity.unitLabel}.';
    }

    _replaceLine(
      lineId,
      (l) => l.withQuantity(quantity),
      markPricingStale: true,
      debouncePricingRefresh: true,
    );
    return null;
  }

  String? tryIncrementLine(SalesProductSelection selection) {
    if (state is SalesComposeError) return null;
    final existingIndex = state.lines.indexWhere(
      (line) =>
          line.identity.productId == selection.productId &&
          line.identity.productUnitId == selection.productUnitId,
    );
    if (existingIndex < 0) {
      addOrIncrementLine(selection);
      return null;
    }
    final existing = state.lines[existingIndex];
    final nextQty = existing.input.quantity + 1;
    if (existing.stock?.availableQuantity != null && nextQty > existing.stock!.availableQuantity!) {
      return 'Vượt tồn kho. Chỉ còn ${existing.stock!.availableQuantity} ${existing.identity.unitLabel}.';
    }
    addOrIncrementLine(selection);
    return null;
  }

  void removeLine(String lineId) {
    if (state is SalesComposeError) return;
    final next = state.lines.where((l) => l.identity.lineId != lineId).toList();
    _mutatePricingContext(lines: next);
  }

  void applyUnitPrice(String lineId, MoneyDto appliedUnitPrice) {
    if (state is SalesComposeError) return;
    applyManualPrice(
      lineId,
      SalesManualPriceDraft(
        mode: SalesPriceAdjustMode.unitPrice,
        acceptedUnitPrice: appliedUnitPrice,
        manualUnitPriceMinor: appliedUnitPrice.amountMinor,
        manualDiscountMinor: null,
        manualDiscountBasisPoints: null,
        saveAsPrivatePrice: false,
      ),
    );
  }

  void applyManualPrice(String lineId, SalesManualPriceDraft draft) {
    if (state is SalesComposeError) return;
    _replaceLine(
      lineId,
      (line) => line.withManualPricing(
        unitPriceMinor: draft.manualUnitPriceMinor,
        clearUnitPriceMinor: draft.manualUnitPriceMinor == null,
        discountMinor: draft.manualDiscountMinor,
        clearDiscountMinor: draft.manualDiscountMinor == null,
        discountBasisPoints: draft.manualDiscountBasisPoints,
        clearDiscountBasisPoints: draft.manualDiscountBasisPoints == null,
      ),
      markPricingStale: true,
    );
  }

  Future<SalesDraftSaveResult> saveDraft() async {
    if (!state.canSaveDraft) return SalesDraftSaveResult.failed;
    if (state is SalesComposeError) return SalesDraftSaveResult.failed;
    if (state.saveStatus == SalesComposeSaveStatus.saving) {
      return SalesDraftSaveResult.failed;
    }

    final current = _asLoaded(state);
    _emitLoaded(
      save: current.save.copyWith(
        status: SalesComposeSaveStatus.saving,
        clearMessage: true,
      ),
    );

    final serverDraftId = SalesComposeDraftRef.serverId(current.draftId);
    final request = SalesDraftPersistRequest(
      draftId: serverDraftId,
      expectedVersion: serverDraftId == null ? null : current.draftVersion,
      composeSessionId: _composeSessionId,
      customer: current.customer,
      lines: current.lines,
      orderNote: current.orderNote,
      pricingPreviewToken: current.previewToken,
      pricingContextVersion: current.pricingContextVersion,
      currencyCode: 'VND',
    );

    try {
      final saved = await _persistDraft(request);
      if (isClosed) return SalesDraftSaveResult.failed;
      final reconciledLines = reconcileComposeLinesAfterPersist(
        current: current.lines,
        persisted: saved.lines,
      );
      emit(
        SalesComposeLoaded(
          draftId: saved.draftId,
          draftVersion: saved.version,
          customer: current.customer,
          lines: reconciledLines,
          orderNote: current.orderNote,
          save: const SalesComposeSaveSlice(status: SalesComposeSaveStatus.saved),
          pricing: current.pricing.copyWith(
            previewToken: saved.pricingPreviewToken ?? current.previewToken,
          ),
          title: current.lines.isEmpty ? 'Tạo đơn' : 'Soạn đơn',
          restoreIssues: current.restoreIssues,
        ),
      );
      return SalesDraftSaveResult.saved;
    } catch (error) {
      if (isClosed) return SalesDraftSaveResult.failed;
      // Updating a server draft that was cancelled, removed or changed
      // elsewhere can never succeed on retry; report it instead of looping.
      if (serverDraftId != null &&
          error is AppException &&
          (error.code == 'STALE_DATA' || error.code == 'REFERENCE_UNAVAILABLE')) {
        _emitLoaded(
          save: current.save.copyWith(
            status: SalesComposeSaveStatus.error,
            clearMessage: true,
          ),
        );
        return SalesDraftSaveResult.draftGone;
      }
      _emitLoaded(
        save: current.save.copyWith(
          status: SalesComposeSaveStatus.error,
          message: _userSafeMessage(
            error,
            fallback: 'Không lưu được đơn nháp. Vui lòng thử lại.',
          ),
        ),
      );
      return SalesDraftSaveResult.failed;
    }
  }

  Future<void> refreshPricingPreview() async {
    if (state is SalesComposeError) return;
    final current = _asLoaded(state);
    if (current.lines.isEmpty) {
      if (isClosed) return;
      _emitLoaded(
        pricing: current.pricing.copyWith(
          status: SalesComposePricingStatus.ready,
          pricedContextVersion: current.pricingContextVersion,
          clearMessage: true,
          clearPreviewToken: true,
        ),
      );
      return;
    }
    final requestVersion = current.pricingContextVersion;
    final expectedLineIds = current.lines
        .map((line) => line.identity.lineId)
        .toList(growable: false);
    final request = SalesPricingPreviewRequest(
      customerId: current.customer.isWalkIn ? null : current.customer.partnerId,
      currencyCode: 'VND',
      contextVersion: requestVersion,
      effectiveAt: DateTime.now().toUtc(),
      lines: [
        for (final line in current.lines)
          SalesPricingLineRequest(
            localLineId: line.identity.lineId,
            productId: line.identity.productId,
            productUnitId: line.identity.productUnitId,
            quantityMicros: line.input.quantity * 1000000,
            manualUnitPriceMinor: line.input.manual.unitPriceMinor,
            manualDiscountMinor: line.input.manual.discountMinor,
            manualDiscountBasisPoints: line.input.manual.discountBasisPoints,
          ),
      ],
    );
    _emitLoaded(
      pricing: current.pricing.copyWith(status: SalesComposePricingStatus.refreshing),
    );

    try {
      final result = await _previewPricing(request);
      if (isClosed || state.pricingContextVersion != requestVersion) return;
      if (result.contextVersion != state.pricingContextVersion) return;

      final actualIds = result.lines.map((line) => line.localLineId).toList(growable: false);
      if (result.currencyCode != request.currencyCode ||
          actualIds.length != expectedLineIds.length ||
          actualIds.toSet().length != actualIds.length ||
          !actualIds.toSet().containsAll(expectedLineIds)) {
        throw const FormatException('Incomplete pricing preview response.');
      }
      final byId = {for (final line in result.lines) line.localLineId: line};
      final nextLines = [
        for (final line in state.lines)
          line.withPricingPreview(byId[line.identity.lineId]!, contextVersion: requestVersion),
      ];
      _emitLoaded(
        lines: nextLines,
        pricing: current.pricing.copyWith(
          status: SalesComposePricingStatus.ready,
          pricedContextVersion: requestVersion,
          previewToken: result.previewToken,
          clearMessage: true,
        ),
      );
    } catch (_) {
      if (isClosed || state.pricingContextVersion != requestVersion) return;
      _emitLoaded(
        pricing: current.pricing.copyWith(
          status: SalesComposePricingStatus.error,
          message: 'Không làm mới được giá. Vui lòng thử lại.',
        ),
      );
    }
  }

  void _replaceLine(
    String lineId,
    SalesComposeLineVm Function(SalesComposeLineVm) map, {
    bool markPricingStale = false,
    bool debouncePricingRefresh = false,
  }) {
    if (state is SalesComposeError) return;
    final next = state.lines
        .map((line) => line.identity.lineId == lineId ? map(line) : line)
        .toList(growable: false);
    if (markPricingStale) {
      _mutatePricingContext(
        lines: next,
        debouncePricingRefresh: debouncePricingRefresh,
      );
    } else {
      _emitLoaded(
        lines: next,
        save: state.save.copyWith(
          status: SalesComposeSaveStatus.unsaved,
          clearMessage: true,
        ),
      );
    }
  }

  void _mutatePricingContext({
    SalesComposeCustomerVm? customer,
    List<SalesComposeLineVm>? lines,
    String? pricingMessage,
    bool debouncePricingRefresh = false,
  }) {
    if (state is SalesComposeError) return;
    final current = _asLoaded(state);
    final nextLines = (lines ?? current.lines)
        .map((line) => line.withPricingStale())
        .toList(growable: false);
    _emitLoaded(
      customer: customer,
      lines: nextLines,
      save: current.save.copyWith(
        status: SalesComposeSaveStatus.unsaved,
        clearMessage: true,
      ),
      pricing: current.pricing.copyWith(
        status: SalesComposePricingStatus.stale,
        contextVersion: current.pricingContextVersion + 1,
        message: pricingMessage,
        clearMessage: pricingMessage == null,
        clearPreviewToken: true,
      ),
    );
    _schedulePricingRefresh(debounce: debouncePricingRefresh);
  }

  void _schedulePricingRefresh({required bool debounce}) {
    _quantityPricingDebounce?.cancel();
    _quantityPricingDebounce = null;
    if (!debounce || _quantityPricingDebounceDuration == Duration.zero) {
      unawaited(refreshPricingPreview());
      return;
    }
    _quantityPricingDebounce = Timer(_quantityPricingDebounceDuration, () {
      _quantityPricingDebounce = null;
      if (isClosed) return;
      unawaited(refreshPricingPreview());
    });
  }

  @override
  Future<void> close() {
    _quantityPricingDebounce?.cancel();
    _quantityPricingDebounce = null;
    return super.close();
  }

  String _userSafeMessage(Object error, {required String fallback}) {
    if (error is SalesExternalOperationException) {
      final message = error.message.trim();
      if (message.isNotEmpty) return message;
    }
    return fallback;
  }
}
