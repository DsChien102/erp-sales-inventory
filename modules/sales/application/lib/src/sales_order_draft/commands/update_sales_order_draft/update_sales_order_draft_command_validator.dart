import 'package:vet45_shared_application/application.dart';

import '../../../shared/customer_snapshot_dto.dart';
import '../../../shared/quantity_dto.dart';
import '../../../shared/sales_contract_exception.dart';
import '../../../shared/sales_order_draft_line_input.dart';
import 'update_sales_order_draft_command.dart';

const _walkInCustomerId = 'cust-walk-in';

final class UpdateSalesOrderDraftCommandValidator
    implements ICommandValidator<UpdateSalesOrderDraftCommand> {
  @override
  Future<void> validate(UpdateSalesOrderDraftCommand command) async {
    _requireNotBlank(command.tenantId, 'tenantId');
    _requireNotBlank(command.actorId, 'actorId');
    _requireNotBlank(command.draftId, 'draftId');
    _requireNotBlank(command.storeId, 'storeId');
    _requireNotBlank(command.currencyCode, 'currencyCode');
    _requireNotBlank(command.idempotencyKey, 'idempotencyKey');
    _rejectWalkInCustomerId(command.customer);
    if (command.expectedVersion <= 0) {
      throw const SalesContractException(
        'CONTEXT_INVALID',
        message: 'expectedVersion must be positive.',
      );
    }
    if (command.lines.isEmpty) {
      throw const SalesContractException(
        'CONTEXT_INVALID',
        message: 'Sales draft must contain at least one line.',
      );
    }
    for (final line in command.lines) {
      _validateLine(line, command.currencyCode);
    }
  }

  static void _validateLine(
    SalesOrderDraftLineInput line,
    String draftCurrencyCode,
  ) {
    _requireNotBlank(line.productId, 'productId');
    _requireNotBlank(line.productSku, 'productSku');
    _requireNotBlank(line.productName, 'productName');
    _requireNotBlank(line.productUnitId, 'productUnitId');
    _requireNotBlank(line.unitCode, 'unitCode');
    _requireNotBlank(line.unitName, 'unitName');
    if (line.quantity.quantityMicros <= 0) {
      throw const SalesContractException(
        'CONTEXT_INVALID',
        message: 'Draft line quantity must be positive.',
      );
    }
    _requireCurrency(line.appliedUnitPrice.currencyCode, draftCurrencyCode);
    _requireCurrency(line.lineTotal.currencyCode, draftCurrencyCode);
    if (line.listUnitPrice != null) {
      _requireCurrency(line.listUnitPrice!.currencyCode, draftCurrencyCode);
    }
    if (line.lineTotal.amountMinor < 0) {
      throw const SalesContractException(
        'CONTEXT_INVALID',
        message: 'Draft lineTotal must be non-negative.',
      );
    }
    _validateManualModes(line);
    final hasManual =
        line.manualUnitPriceMinor != null ||
        line.manualDiscountMinor != null ||
        line.manualDiscountBasisPoints != null;
    if (!hasManual) {
      final expected =
          line.appliedUnitPrice.amountMinor * line.quantity.quantityMicros ~/ QuantityDto.scale;
      if (line.lineTotal.amountMinor != expected) {
        throw const SalesContractException(
          'CONTEXT_INVALID',
          message: 'Draft lineTotal does not match applied unit price.',
        );
      }
    }
  }

  static void _validateManualModes(SalesOrderDraftLineInput line) {
    final modes = <String>[
      if (line.manualUnitPriceMinor != null) 'manualUnitPriceMinor',
      if (line.manualDiscountMinor != null) 'manualDiscountMinor',
      if (line.manualDiscountBasisPoints != null) 'manualDiscountBasisPoints',
    ];
    if (modes.length > 1) {
      throw const SalesContractException(
        'CONTEXT_INVALID',
        message: 'At most one manual price or discount mode may be set.',
      );
    }
    final basisPoints = line.manualDiscountBasisPoints;
    if (basisPoints != null && (basisPoints < 0 || basisPoints > 10000)) {
      throw const SalesContractException(
        'CONTEXT_INVALID',
        message: 'manualDiscountBasisPoints must be between 0 and 10000.',
      );
    }
  }

  static void _rejectWalkInCustomerId(CustomerSnapshotDto? customer) {
    if (customer == null) return;
    if (customer.customerId.trim() == _walkInCustomerId) {
      throw const SalesContractException(
        'CONTEXT_INVALID',
        message: 'Walk-in customer must be represented as null customer.',
      );
    }
    _requireNotBlank(customer.customerId, 'customerId');
    _requireNotBlank(customer.displayName, 'displayName');
  }

  static void _requireCurrency(String actual, String expected) {
    if (actual.trim().toUpperCase() != expected.trim().toUpperCase()) {
      throw const SalesContractException(
        'CONTEXT_INVALID',
        message: 'Draft line currency must match draft currency.',
      );
    }
  }

  static void _requireNotBlank(String value, String field) {
    if (value.trim().isEmpty) {
      throw SalesContractException(
        'CONTEXT_INVALID',
        message: '$field is required.',
      );
    }
  }
}
