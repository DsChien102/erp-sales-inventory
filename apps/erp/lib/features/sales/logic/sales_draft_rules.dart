import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/sales_draft_errors.dart';
import 'package:vet45_sales_application/application.dart';

const _walkInCustomerId = 'cust-walk-in';

/// Chép điều kiện + câu của 3 validator cũ (bỏ kiểm tenantId / actorId).
void checkSaveDraft({
  required String storeId,
  CustomerSnapshotDto? customer,
  required String currencyCode,
  required List<SalesOrderDraftLineInput> lines,
  required String idempotencyKey,
}) {
  _requireNotBlank(storeId, 'storeId');
  _requireNotBlank(currencyCode, 'currencyCode');
  _requireNotBlank(idempotencyKey, 'idempotencyKey');
  _rejectWalkInCustomerId(customer);
  _checkLines(lines, currencyCode);
}

void checkUpdateDraft({
  required String draftId,
  required int expectedVersion,
  required String storeId,
  CustomerSnapshotDto? customer,
  required String currencyCode,
  required List<SalesOrderDraftLineInput> lines,
  required String idempotencyKey,
}) {
  _requireNotBlank(draftId, 'draftId');
  _requireNotBlank(storeId, 'storeId');
  _requireNotBlank(currencyCode, 'currencyCode');
  _requireNotBlank(idempotencyKey, 'idempotencyKey');
  _rejectWalkInCustomerId(customer);
  if (expectedVersion <= 0) _fail('expectedVersion must be positive.');
  _checkLines(lines, currencyCode);
}

void checkCancelDraft({
  required String draftId,
  required int expectedVersion,
  required String idempotencyKey,
}) {
  _requireNotBlank(draftId, 'draftId');
  _requireNotBlank(idempotencyKey, 'idempotencyKey');
  if (expectedVersion <= 0) _fail('expectedVersion must be positive.');
}

void _checkLines(List<SalesOrderDraftLineInput> lines, String currencyCode) {
  if (lines.isEmpty) _fail('Sales draft must contain at least one line.');
  for (final line in lines) {
    _checkLine(line, currencyCode);
  }
}

void _checkLine(SalesOrderDraftLineInput line, String draftCurrencyCode) {
  _requireNotBlank(line.productId, 'productId');
  _requireNotBlank(line.productSku, 'productSku');
  _requireNotBlank(line.productName, 'productName');
  _requireNotBlank(line.productUnitId, 'productUnitId');
  _requireNotBlank(line.unitCode, 'unitCode');
  _requireNotBlank(line.unitName, 'unitName');
  if (line.quantity.quantityMicros <= 0) _fail('Draft line quantity must be positive.');
  _requireCurrency(line.appliedUnitPrice.currencyCode, draftCurrencyCode);
  _requireCurrency(line.lineTotal.currencyCode, draftCurrencyCode);
  if (line.listUnitPrice != null) {
    _requireCurrency(line.listUnitPrice!.currencyCode, draftCurrencyCode);
  }
  if (line.lineTotal.amountMinor < 0) _fail('Draft lineTotal must be non-negative.');
  final modes = <String>[
    if (line.manualUnitPriceMinor != null) 'manualUnitPriceMinor',
    if (line.manualDiscountMinor != null) 'manualDiscountMinor',
    if (line.manualDiscountBasisPoints != null) 'manualDiscountBasisPoints',
  ];
  if (modes.length > 1) _fail('At most one manual price or discount mode may be set.');
  final basisPoints = line.manualDiscountBasisPoints;
  if (basisPoints != null && (basisPoints < 0 || basisPoints > 10000)) {
    _fail('manualDiscountBasisPoints must be between 0 and 10000.');
  }
  if (modes.isEmpty) {
    final expected =
        line.appliedUnitPrice.amountMinor * line.quantity.quantityMicros ~/ QuantityDto.scale;
    if (line.lineTotal.amountMinor != expected) {
      _fail('Draft lineTotal does not match applied unit price.');
    }
  }
}

void _rejectWalkInCustomerId(CustomerSnapshotDto? customer) {
  if (customer == null) return;
  if (customer.customerId.trim() == _walkInCustomerId) {
    _fail('Walk-in customer must be represented as null customer.');
  }
  _requireNotBlank(customer.customerId, 'customerId');
  _requireNotBlank(customer.displayName, 'displayName');
}

void _requireCurrency(String actual, String expected) {
  if (actual.trim().toUpperCase() != expected.trim().toUpperCase()) {
    _fail('Draft line currency must match draft currency.');
  }
}

void _requireNotBlank(String value, String field) {
  if (value.trim().isEmpty) _fail('$field is required.');
}

Never _fail(String message) =>
    throw AppException(SalesDraftErrorCodes.contextInvalid, serverMessage: message);
