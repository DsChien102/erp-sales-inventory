import 'package:vet45_sales_application/application.dart';

import '../../models/sales_order_draft/sales_compose_customer_vm.dart';
import '../../models/sales_order_draft/sales_compose_line_vm.dart';

/// Presentation-owned draft persist callback — ERP implements against module mediators.
typedef SalesDraftPersistFn =
    Future<SalesOrderDraftDto> Function(
      SalesDraftPersistRequest request,
    );

/// Presentation-owned draft restore callback — ERP revalidates Catalog/Partner/Pricing.
typedef SalesDraftRestoreFn =
    Future<SalesDraftRestoreResult> Function(
      String draftId,
    );

enum SalesDraftRestoreIssueCode {
  customerUnavailable,
  productUnavailable,
  unitUnavailable,
  pricingChanged,
  pricingUnavailable,

  /// Catalog lookup itself failed — retryable, and never a statement about the
  /// products in the draft.
  catalogUnavailable,
}

final class SalesDraftRestoreIssue {
  const SalesDraftRestoreIssue({
    required this.code,
    this.lineId,
    this.message,
  });

  final SalesDraftRestoreIssueCode code;
  final String? lineId;
  final String? message;
}

/// Working-state snapshot ready for cross-module validation + Sales save/update.
final class SalesDraftPersistRequest {
  SalesDraftPersistRequest({
    this.draftId,
    this.expectedVersion,
    required this.composeSessionId,
    required this.customer,
    required List<SalesComposeLineVm> lines,
    this.orderNote,
    this.pricingPreviewToken,
    required this.pricingContextVersion,
    required this.currencyCode,
  }) : lines = List.unmodifiable(lines);

  /// Server draft id when updating; null on first save.
  final String? draftId;

  /// Optimistic concurrency token for update.
  final int? expectedVersion;

  /// Stable local identity used for save idempotency before a server draft id exists.
  final String composeSessionId;

  final SalesComposeCustomerVm customer;
  final List<SalesComposeLineVm> lines;
  final String? orderNote;
  final String? pricingPreviewToken;
  final int pricingContextVersion;
  final String currencyCode;

  bool get isUpdate {
    final id = draftId?.trim();
    return id != null && id.isNotEmpty && expectedVersion != null;
  }
}

final class SalesDraftRestoreResult {
  SalesDraftRestoreResult({
    required this.draft,
    required this.customer,
    required List<SalesComposeLineVm> lines,
    this.orderNote,
    required List<SalesDraftRestoreIssue> issues,
  }) : lines = List.unmodifiable(lines),
       issues = List.unmodifiable(issues);

  final SalesOrderDraftDto draft;
  final SalesComposeCustomerVm customer;
  final List<SalesComposeLineVm> lines;
  final String? orderNote;
  final List<SalesDraftRestoreIssue> issues;
}
