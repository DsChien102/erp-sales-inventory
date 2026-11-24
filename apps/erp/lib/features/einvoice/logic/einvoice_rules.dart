import 'package:uuid/uuid.dart';

import 'package:erp/core/errors/app_exception.dart';
import '../data/einvoice_errors.dart';

abstract final class EInvoiceRules {
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static void checkConnect({
    required String username,
    required String password,
  }) {
    if (username.trim().isEmpty) {
      throw const AppException(
        EInvoiceErrorCodes.validationError,
        serverMessage: 'username is required',
      );
    }
    if (password.isEmpty) {
      throw const AppException(
        EInvoiceErrorCodes.validationError,
        serverMessage: 'password is required',
      );
    }
  }

  static void checkSetDefaultConfiguration({
    required String templateId,
    required String signingConfigId,
  }) {
    if (templateId.trim().isEmpty) {
      throw const AppException(
        EInvoiceErrorCodes.validationError,
        serverMessage: 'templateId is required',
      );
    }
    if (signingConfigId.trim().isEmpty) {
      throw const AppException(
        EInvoiceErrorCodes.validationError,
        serverMessage: 'signingConfigId is required',
      );
    }
  }

  static void checkUpdateAutomationPolicy({
    required int expectedPolicyVersion,
    bool? autoIssueEnabled,
    bool? autoSendEnabled,
  }) {
    if (expectedPolicyVersion < 0) {
      throw const AppException(
        EInvoiceErrorCodes.validationError,
        serverMessage: 'expectedPolicyVersion must be non-negative',
      );
    }
    if (autoIssueEnabled == null && autoSendEnabled == null) {
      throw const AppException(
        EInvoiceErrorCodes.validationError,
        serverMessage:
            'At least one of autoIssueEnabled or autoSendEnabled must be set',
      );
    }
  }

  static void checkSalesOrderId(String salesOrderId) {
    if (salesOrderId.trim().isEmpty) {
      throw const AppException(
        EInvoiceErrorCodes.validationError,
        serverMessage: 'salesOrderId is required',
      );
    }
  }

  static void checkIssue({
    required String salesOrderId,
    required String sourceVersion,
    required String idempotencyKey,
  }) {
    checkSalesOrderId(salesOrderId);
    if (sourceVersion.trim().isEmpty) {
      throw const AppException(
        EInvoiceErrorCodes.validationError,
        serverMessage: 'sourceVersion is required',
      );
    }
    if (!Uuid.isValidUUID(fromString: idempotencyKey)) {
      throw const AppException(
        EInvoiceErrorCodes.validationError,
        serverMessage: 'idempotencyKey must be a canonical UUID',
      );
    }
  }

  static void checkRetry({
    required String salesOrderId,
    required int expectedOrderVersion,
    required String idempotencyKey,
  }) {
    checkSalesOrderId(salesOrderId);
    if (expectedOrderVersion <= 0) {
      throw const AppException(
        EInvoiceErrorCodes.validationError,
        serverMessage: 'expectedOrderVersion must be positive',
      );
    }
    if (!Uuid.isValidUUID(fromString: idempotencyKey)) {
      throw const AppException(
        EInvoiceErrorCodes.validationError,
        serverMessage: 'idempotencyKey must be a canonical UUID',
      );
    }
  }

  static void checkSend({
    required String salesOrderId,
    required String recipientEmail,
    required String idempotencyKey,
  }) {
    checkSalesOrderId(salesOrderId);
    final email = recipientEmail.trim();
    if (email.isEmpty || !_emailPattern.hasMatch(email)) {
      throw const AppException(
        EInvoiceErrorCodes.validationError,
        serverMessage: 'Delivery recipient email must be a valid address',
      );
    }
    if (!Uuid.isValidUUID(fromString: idempotencyKey)) {
      throw const AppException(
        EInvoiceErrorCodes.validationError,
        serverMessage: 'idempotencyKey must be a canonical UUID',
      );
    }
  }
}

