import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exception.dart';
import '../data/goods_receipt_repository.dart';
import '../data/models/receipt_actor.dart';
import '../data/models/receipt_document_model.dart';
import '../data/models/receipt_header_draft.dart';
import '../data/models/receipt_item_draft.dart';
import 'quick_receipt_session_state.dart';
import 'receipt_rules.dart';

class QuickReceiptSessionCubit extends Cubit<QuickReceiptSessionState> {
  QuickReceiptSessionCubit({
    required GoodsReceiptRepository repository,
    required ReceiptActorLoader actorLoader,
  })  : _repository = repository,
        _actorLoader = actorLoader,
        super(QuickReceiptSessionState(
          header: ReceiptHeaderDraft(receiptDate: DateTime.now()),
        ));

  final GoodsReceiptRepository _repository;
  final ReceiptActorLoader _actorLoader;

  Future<void> loadCatalog() async {
    emit(state.copyWith(catalogStatus: CatalogStatus.loading, clearError: true));
    try {
      final capability = await _repository.getCapability();
      final suppliers = await _repository.getSuppliers();
      final products = await _repository.getProducts();
      emit(state.copyWith(
        catalogStatus: CatalogStatus.ready,
        suppliers: suppliers,
        products: products,
        permissionDenied: false,
        catalogConflict: false,
        warehouseLocked: capability.warehouseLocked,
      ));
    } catch (e) {
      final error = AppException.from(e);
      emit(state.copyWith(
        catalogStatus: CatalogStatus.failure,
        permissionDenied: error.isNoPermission,
        catalogConflict: error.isStateChanged,
        errorMessage: error.userMessage(receiptErrorMessages),
      ));
    }
  }

  void updateHeader(ReceiptHeaderDraft header) {
    emit(state.copyWith(header: header));
  }

  /// Vị trí dòng cùng Product + UOM; -1 nếu chưa có.
  int indexOf(String productId, String unitId) => state.items
      .indexWhere((i) => i.productId == productId && i.unitId == unitId);

  /// Chỉ gọi khi bấm Xong ở SCR-084. Dòng mới thì thêm, dòng đã có thì thay đúng chỗ.
  void saveItem(ReceiptItemDraft item) {
    final existingIndex = indexOf(item.productId, item.unitId);

    final updated = List<ReceiptItemDraft>.from(state.items);
    if (existingIndex >= 0) {
      updated[existingIndex] = item;
    } else {
      updated.add(item);
    }
    emit(state.copyWith(items: updated));
  }

  void removeItem(int index) {
    if (index >= 0 && index < state.items.length) {
      final updated = List<ReceiptItemDraft>.from(state.items)..removeAt(index);
      emit(state.copyWith(items: updated));
    }
  }

  Future<ReceiptDocumentModel?> submitForApproval() async {
    if (!state.canReview) return null;

    emit(state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSubmitErrorCode: true,
    ));
    try {
      final maker = await _actorLoader();
      final doc = await _repository.submitQuickReceipt(
        state.header,
        state.items,
        maker: maker,
      );
      emit(state.copyWith(
        isSubmitting: false,
        submittedDocument: doc,
      ));
      return doc;
    } catch (e) {
      final error = AppException.from(e);
      emit(state.copyWith(
        isSubmitting: false,
        permissionDenied: error.isNoPermission,
        submitErrorCode: error.code,
        errorMessage: error.userMessage(receiptErrorMessages),
      ));
      return null;
    }
  }
}
