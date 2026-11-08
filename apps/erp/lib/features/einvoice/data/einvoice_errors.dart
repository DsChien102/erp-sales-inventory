import 'dart:convert';

import 'package:supabase/supabase.dart';

import 'package:erp/core/errors/app_exception.dart';

abstract final class EInvoiceErrorCodes {
  static const noPermission = 'NO_PERMISSION';
  static const notFound = 'NOT_FOUND';
  static const validationError = 'VALIDATION_ERROR';
  static const invalidStatus = 'INVALID_STATUS';
  static const stateChanged = 'STATE_CHANGED';
  static const systemError = 'SYSTEM_ERROR';
  static const providerNotConnected = 'PROVIDER_NOT_CONNECTED';
  static const providerAuthFailed = 'PROVIDER_AUTH_FAILED';
  static const providerUnavailable = 'PROVIDER_UNAVAILABLE';
  static const configNotReady = 'CONFIG_NOT_READY';
  static const issuanceNotReady = 'ISSUANCE_NOT_READY';
  static const buyerDataIncomplete = 'BUYER_DATA_INCOMPLETE';
  static const buyerTaxCodeRequired = 'BUYER_TAX_CODE_REQUIRED';
  static const buyerAddressRequired = 'BUYER_ADDRESS_REQUIRED';
  static const templateNotAvailable = 'TEMPLATE_NOT_AVAILABLE';
  static const signingConfigurationNotAvailable =
      'SIGNING_CONFIGURATION_NOT_AVAILABLE';
  static const unsupportedTaxData = 'UNSUPPORTED_TAX_DATA';
  static const orderNotCompleted = 'ORDER_NOT_COMPLETED';
  static const orderFullyReturned = 'ORDER_FULLY_RETURNED';
  static const sourceVersionMismatch = 'SOURCE_VERSION_MISMATCH';
  static const alreadyIssued = 'ALREADY_ISSUED';
  static const operationInProgress = 'OPERATION_IN_PROGRESS';
  static const resultUndetermined = 'RESULT_UNDETERMINED';
  static const documentUnavailable = 'DOCUMENT_UNAVAILABLE';
  static const deliveryNotSupported = 'DELIVERY_NOT_SUPPORTED';
  static const idempotencyConflict = 'IDEMPOTENCY_CONFLICT';
  static const network = 'NETWORK_ERROR';
}

const _codesByPriority = <String>[
  EInvoiceErrorCodes.noPermission,
  EInvoiceErrorCodes.notFound,
  EInvoiceErrorCodes.validationError,
  EInvoiceErrorCodes.invalidStatus,
  EInvoiceErrorCodes.stateChanged,
  EInvoiceErrorCodes.providerNotConnected,
  EInvoiceErrorCodes.providerAuthFailed,
  EInvoiceErrorCodes.providerUnavailable,
  EInvoiceErrorCodes.configNotReady,
  EInvoiceErrorCodes.buyerDataIncomplete,
  EInvoiceErrorCodes.buyerTaxCodeRequired,
  EInvoiceErrorCodes.orderNotCompleted,
  EInvoiceErrorCodes.alreadyIssued,
  EInvoiceErrorCodes.operationInProgress,
  EInvoiceErrorCodes.resultUndetermined,
  EInvoiceErrorCodes.documentUnavailable,
  EInvoiceErrorCodes.deliveryNotSupported,
  EInvoiceErrorCodes.templateNotAvailable,
  EInvoiceErrorCodes.signingConfigurationNotAvailable,
];

List<String> _parseIssuanceBlockers(String message) {
  final upper = message.toUpperCase();
  const token = 'ISSUANCE_NOT_READY:';
  final index = upper.indexOf(token);
  if (index < 0) return const [];
  final payload = message.substring(index + token.length).trim();
  if (payload.isEmpty) return const [];
  try {
    final decoded = jsonDecode(payload);
    if (decoded is! Map) return const [];
    final details = decoded['details'];
    if (details is! Map) return const [];
    final blockers = details['blockers'];
    if (blockers is! List) return const [];
    return blockers.map((e) => e.toString()).toList(growable: false);
  } catch (_) {
    return const [];
  }
}

/// Q2 / Q7. Thứ tự giữ đúng mapEinvoiceRpcError.
AppException einvoiceException(Object error) {
  // 1. PostgrestException cause (directly or wrapped in AppException)
  final postgrest = switch (error) {
    AppException e when e.cause is PostgrestException =>
      e.cause as PostgrestException,
    PostgrestException e => e,
    _ => null,
  };

  if (postgrest != null) {
    final text = postgrest.toString();
    final upper = text.toUpperCase();

    if (upper.contains(EInvoiceErrorCodes.idempotencyConflict)) {
      return AppException(
        EInvoiceErrorCodes.idempotencyConflict,
        serverMessage: postgrest.message,
        cause: postgrest,
      );
    }

    if (upper.contains(EInvoiceErrorCodes.issuanceNotReady)) {
      final blockers = _parseIssuanceBlockers(postgrest.message);
      return AppException(
        EInvoiceErrorCodes.issuanceNotReady,
        serverMessage: postgrest.message,
        details: {'blockers': blockers},
        cause: postgrest,
      );
    }

    for (final code in _codesByPriority) {
      if (upper.contains(code)) {
        return AppException(
          code,
          serverMessage: postgrest.message,
          cause: postgrest,
        );
      }
    }

    if (text.toLowerCase().contains('permission denied')) {
      return AppException(
        EInvoiceErrorCodes.noPermission,
        serverMessage: postgrest.message,
        cause: postgrest,
      );
    }

    return AppException(
      EInvoiceErrorCodes.systemError,
      serverMessage: postgrest.message,
      cause: postgrest,
    );
  }

  // 2. error is AppException with NETWORK_ERROR
  if (error is AppException && error.code == EInvoiceErrorCodes.network) {
    return error;
  }

  // 3. other AppException (rules, CONFIG_NOT_READY / ISSUANCE_NOT_READY from requestPreview, etc.)
  if (error is AppException) {
    return error;
  }

  // 4. Remaining (FormatException, TypeError, StateError...)
  return AppException(EInvoiceErrorCodes.systemError, cause: error);
}

