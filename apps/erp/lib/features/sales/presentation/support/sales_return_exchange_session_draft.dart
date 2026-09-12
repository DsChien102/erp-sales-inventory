import 'package:vet45_sales_application/application.dart';

import '../bloc/return_exchange_order/sales_return_exchange_session_state.dart';

/// Pure helpers for session draft lines / edit preservation.
abstract final class SalesReturnExchangeSessionDraft {
  static List<ReturnExchangeLineInput> buildLines({
    required List<SalesReturnLineEdit> returnEdits,
    required List<SalesExchangeLineEdit> exchangeEdits,
    required List<ReturnableOrderLineDto> returnableLines,
  }) {
    ReturnableOrderLineDto? lineOf(String id) {
      for (final line in returnableLines) {
        if (line.unitId == id) return line;
      }
      return null;
    }

    final returnLines = [
      for (final edit in returnEdits)
        if (edit.quantityMicros > 0)
          ReturnExchangeLineInput(
            kind: ReturnExchangeLineKind.returnLine,
            productId: lineOf(edit.salesOrderLineId)!.product.productId,
            productUnitId: lineOf(edit.salesOrderLineId)!.unit.productUnitId,
            quantity: QuantityDto(quantityMicros: edit.quantityMicros),
            originalSalesOrderLineId: lineOf(edit.salesOrderLineId)!.salesOrderLineId,
            sourceExchangeLineId: lineOf(edit.salesOrderLineId)!.sourceExchangeLineId,
            reasonCode: edit.reasonCode,
            conditionCode: edit.conditionCode,
          ),
    ];
    final exchangeLines = [
      for (final edit in exchangeEdits)
        if (edit.quantityMicros > 0)
          ReturnExchangeLineInput(
            kind: ReturnExchangeLineKind.exchangeLine,
            productId: edit.productId,
            productUnitId: edit.productUnitId,
            quantity: QuantityDto(quantityMicros: edit.quantityMicros),
            exchangeProductSnapshot: ProductSnapshotDto(
              productId: edit.productId,
              sku: edit.sku,
              displayName: edit.productName,
            ),
            exchangeUnitSnapshot: ProductUnitSnapshotDto(
              productUnitId: edit.productUnitId,
              unitCode: null,
              unitName: edit.unitLabel,
            ),
            exchangeUnitPrice: edit.unitPrice,
          ),
    ];
    return [...returnLines, ...exchangeLines];
  }

  static bool sameLines(
    List<ReturnExchangeLineInput> left,
    List<ReturnExchangeLineInput> right,
  ) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      final a = left[i];
      final b = right[i];
      if (a.kind != b.kind ||
          a.productId != b.productId ||
          a.productUnitId != b.productUnitId ||
          a.quantity.quantityMicros != b.quantity.quantityMicros ||
          a.originalSalesOrderLineId != b.originalSalesOrderLineId ||
          a.sourceExchangeLineId != b.sourceExchangeLineId ||
          a.reasonCode != b.reasonCode ||
          a.conditionCode != b.conditionCode ||
          a.exchangeProductSnapshot?.displayName != b.exchangeProductSnapshot?.displayName ||
          a.exchangeProductSnapshot?.sku != b.exchangeProductSnapshot?.sku ||
          a.exchangeUnitSnapshot?.unitName != b.exchangeUnitSnapshot?.unitName ||
          a.exchangeUnitPrice?.amountMinor != b.exchangeUnitPrice?.amountMinor ||
          a.exchangeUnitPrice?.currencyCode != b.exchangeUnitPrice?.currencyCode) {
        return false;
      }
    }
    return true;
  }

  static ({
    List<SalesReturnLineEdit> returnEdits,
    List<SalesExchangeLineEdit> exchangeEdits,
    String? fieldError,
  })
  preserveEdits({
    required List<SalesReturnLineEdit> currentReturns,
    required List<SalesExchangeLineEdit> currentExchanges,
    required List<ReturnableOrderLineDto> returnableLines,
    required List<ReturnExchangePolicyOptionDto> reasons,
    required List<ReturnExchangePolicyOptionDto> conditions,
  }) {
    final reasonCodes = {for (final r in reasons) r.code.toUpperCase()};
    final conditionCodes = {for (final c in conditions) c.code.toUpperCase()};
    final returnableById = {
      for (final line in returnableLines) line.unitId: line,
    };
    final nextReturns = <SalesReturnLineEdit>[];
    String? fieldError;
    for (final edit in currentReturns) {
      final line = returnableById[edit.salesOrderLineId];
      if (line == null) continue;
      var next = edit;
      if (edit.quantityMicros > line.returnableQuantity.quantityMicros) {
        next = next.copyWith(quantityMicros: line.returnableQuantity.quantityMicros);
      }
      if (edit.reasonCode != null && !reasonCodes.contains(edit.reasonCode!.toUpperCase())) {
        next = next.copyWith(clearReason: true);
        fieldError = 'Lý do trả hàng không còn hiệu lực.';
      }
      if (edit.conditionCode != null &&
          !conditionCodes.contains(edit.conditionCode!.toUpperCase())) {
        next = next.copyWith(clearCondition: true);
        fieldError = 'Tình trạng hàng trả không còn hiệu lực.';
      }
      if (next.quantityMicros > 0) {
        nextReturns.add(next);
      }
    }
    return (
      returnEdits: nextReturns,
      exchangeEdits: currentExchanges,
      fieldError: fieldError,
    );
  }

  static List<SalesReturnLineEdit> upsertReturnEdit({
    required List<SalesReturnLineEdit> current,
    required String salesOrderLineId,
    required SalesReturnLineEdit Function(SalesReturnLineEdit edit) update,
  }) {
    final edits = [...current];
    final index = edits.indexWhere((e) => e.salesOrderLineId == salesOrderLineId);
    if (index >= 0) {
      edits[index] = update(edits[index]);
    } else {
      edits.add(
        update(
          SalesReturnLineEdit(
            salesOrderLineId: salesOrderLineId,
            quantityMicros: 0,
          ),
        ),
      );
    }
    return edits;
  }

  static ReturnableOrderLineDto? returnableLineOf({
    required List<ReturnableOrderLineDto> lines,
    required String salesOrderLineId,
  }) {
    for (final line in lines) {
      if (line.unitId == salesOrderLineId) return line;
    }
    return null;
  }

  static bool hasPolicyCode(
    List<ReturnExchangePolicyOptionDto> options,
    String code,
  ) => options.any((o) => o.code.toUpperCase() == code);
}
