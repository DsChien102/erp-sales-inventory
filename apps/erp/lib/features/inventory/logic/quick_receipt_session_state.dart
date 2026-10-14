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
  });

  final ReceiptHeaderDraft header;
  final List<ReceiptItemDraft> items;
  final bool isSubmitting;
  final String? errorMessage;
  final ReceiptDocumentModel? submittedDocument;
  final CatalogStatus catalogStatus;
  final List<ReceiptSupplierDto> suppliers;
  final List<ReceiptProductDto> products;

  bool get canReview =>
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
    bool clearError = false,
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
      ];
}
