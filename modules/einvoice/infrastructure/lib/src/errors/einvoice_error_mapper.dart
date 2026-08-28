import 'dart:convert';

import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

EInvoiceBlockedException mapEinvoiceRpcError(RpcException error) {
  final message = error.message;
  final upper = message.toUpperCase();

  if (upper.contains(EInvoiceBlockedCodes.idempotencyConflict)) {
    return EInvoiceBlockedException(
      EInvoiceBlockedCodes.idempotencyConflict,
      message: message,
    );
  }

  if (upper.contains(EInvoiceBlockedCodes.issuanceNotReady)) {
    return IssuanceNotReadyException(
      blockers: _parseIssuanceBlockers(message),
      message: message,
    );
  }

  for (final code in [
    EInvoiceBlockedCodes.noPermission,
    EInvoiceBlockedCodes.notFound,
    EInvoiceBlockedCodes.validationError,
    EInvoiceBlockedCodes.invalidStatus,
    EInvoiceBlockedCodes.stateChanged,
    EInvoiceBlockedCodes.providerNotConnected,
    EInvoiceBlockedCodes.providerAuthFailed,
    EInvoiceBlockedCodes.providerUnavailable,
    EInvoiceBlockedCodes.configNotReady,
    EInvoiceBlockedCodes.buyerDataIncomplete,
    EInvoiceBlockedCodes.buyerTaxCodeRequired,
    EInvoiceBlockedCodes.orderNotCompleted,
    EInvoiceBlockedCodes.alreadyIssued,
    EInvoiceBlockedCodes.operationInProgress,
    EInvoiceBlockedCodes.resultUndetermined,
    EInvoiceBlockedCodes.documentUnavailable,
    EInvoiceBlockedCodes.deliveryNotSupported,
  ]) {
    if (upper.contains(code)) {
      return EInvoiceBlockedException(code, message: message);
    }
  }

  if (message.toLowerCase().contains('permission denied')) {
    return EInvoiceBlockedException(
      EInvoiceBlockedCodes.noPermission,
      message: message,
    );
  }

  return EInvoiceBlockedException(
    EInvoiceBlockedCodes.systemError,
    message: message,
  );
}

List<String> _parseIssuanceBlockers(String message) {
  final colonIndex = message.indexOf(':');
  if (colonIndex < 0) {
    return const [];
  }

  final payload = message.substring(colonIndex + 1).trim();
  if (payload.isEmpty) {
    return const [];
  }

  try {
    final decoded = jsonDecode(payload);
    if (decoded is! Map) {
      return const [];
    }
    final details = decoded['details'];
    if (details is! Map) {
      return const [];
    }
    final blockers = details['blockers'];
    if (blockers is! List) {
      return const [];
    }
    return blockers.map((item) => item.toString()).toList(growable: false);
  } on FormatException {
    return const [];
  }
}
