import 'package:equatable/equatable.dart';

import '../data/goods_receipt_repository.dart';
import '../data/models/receipt_document_model.dart';
import '../data/models/receipt_header_draft.dart';
import '../data/models/receipt_item_draft.dart';
import 'receipt_rules.dart';

enum CatalogStatus { loading, ready, failure }

class QuickReceiptSessionState extends Equatable {
  const QuickReceiptSessionState({
    required this.header,
    this.items = const [],
    this.isSubmitting = false,
    this.errorMessage,
    this.submittedDocument,
    this.catalogStatus = CatalogStatus.loading,
    this.suppliers = const [],
    this.products = const [],
    this.permissionDenied = false,
    this.warehouseLocked = false,
    this.catalogConflict = false,
    this.submitErrorCode,
  });

  final ReceiptHeaderDraft header;
  final List<ReceiptItemDraft> items;
  final bool isSubmitting;
  final String? errorMessage;
  final ReceiptDocumentModel? submittedDocument;
  final CatalogStatus catalogStatus;
  final List<ReceiptSupplierDto> suppliers;
  final List<ReceiptProductDto> products;
  final bool permissionDenied;
  final bool warehouseLocked;

  /// Danh mục vừa đổi, chờ người dùng "Tải lại".
  final bool catalogConflict;

  /// Mã lỗi của lần gửi gần nhất, vd `APPROVER_CONFIGURATION_MISSING`.
  final String? submitErrorCode;

  bool get canReview =>
      !warehouseLocked &&
      header.isValid &&
      items.isNotEmpty &&
      items.every((i) => validateReceiptItem(i).isValid) &&
      items.any((i) => i.totalPhysicalStock > 0);

  QuickReceiptSessionState copyWith({
    ReceiptHeaderDraft? header,
    List<ReceiptItemDraft>? items,
    bool? isSubmitting,
    String? errorMessage,
    ReceiptDocumentModel? submittedDocument,
    CatalogStatus? catalogStatus,
    List<ReceiptSupplierDto>? suppliers,
    List<ReceiptProductDto>? products,
    bool? permissionDenied,
    bool? warehouseLocked,
    bool? catalogConflict,
    String? submitErrorCode,
    bool clearError = false,
    bool clearSubmitErrorCode = false,
  }) {
    return QuickReceiptSessionState(
      header: header ?? this.header,
      items: items ?? this.items,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      submittedDocument: submittedDocument ?? this.submittedDocument,
      catalogStatus: catalogStatus ?? this.catalogStatus,
      suppliers: suppliers ?? this.suppliers,
      products: products ?? this.products,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      warehouseLocked: warehouseLocked ?? this.warehouseLocked,
      catalogConflict: catalogConflict ?? this.catalogConflict,
      submitErrorCode: clearSubmitErrorCode
          ? null
          : (submitErrorCode ?? this.submitErrorCode),
    );
  }

  @override
  List<Object?> get props => [
        header,
        items,
        isSubmitting,
        errorMessage,
        submittedDocument,
        catalogStatus,
        suppliers,
        products,
        permissionDenied,
        warehouseLocked,
        catalogConflict,
        submitErrorCode,
      ];
}
