import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_misa/e_invoice.dart';

import 'me_invoice_provider_call_support.dart';

/// Maps MISA `sendEmail` results into closed [DeliveryProviderOutcome].
///
/// Closed allowlist: unknown codes and unexpected shapes are undetermined,
/// never definite failure. Never returns raw provider message/body text.
abstract final class MeInvoiceDeliveryClassifier {
  static const _definiteAuthOrCredentialCodes = <String>{
    'InvalidAppID',
    'InactiveAppID',
    'TaxCodeNotExist',
    'InactiveTaxCode',
    'UserNotExist',
    'WrongPassWord',
    'InactiveUser',
    'MisaIdError',
    'TwoFactorAuthen',
    'UnAuthorize',
    'TokenExpiredCode',
    'missing_MISA_MEINVOICE_APP_ID',
  };

  static DeliveryProviderOutcome classify(
    MeInvoiceResult<List<MeInvoiceSendEmailResultItem>> result, {
    required String transactionId,
  }) {
    if (result.rateLimited || _isRateLimited(result.error)) {
      return DeliveryProviderRetryableFailure(
        MeInvoiceProviderCallSupport.safeErrorCode(
          result.error ?? 'RATE_LIMITED',
        ),
      );
    }

    if (result.isSuccess) {
      final items = result.data;
      if (transactionId.isEmpty ||
          items == null ||
          items.length != 1 ||
          items.single.transactionId != transactionId) {
        return const DeliveryProviderUndetermined(
          'PROVIDER_UNEXPECTED_SUCCESS_SHAPE',
        );
      }
      final item = items.single;
      if (item.sendEmailStatus == 3 &&
          (item.errorCode?.trim().isEmpty ?? true)) {
        return const DeliveryProviderSucceeded();
      }
      if (item.sendEmailStatus == 2) {
        return DeliveryProviderDefiniteFailure(
          MeInvoiceProviderCallSupport.safeErrorCode(
            item.errorCode ?? 'PROVIDER_EMAIL_FAILED',
          ),
        );
      }
      return const DeliveryProviderUndetermined('PROVIDER_EMAIL_NOT_CONFIRMED');
    }

    final error = result.error ?? 'unknown_error';
    final code = MeInvoiceProviderCallSupport.safeErrorCode(error);

    if (_isAmbiguousTransport(error)) {
      return DeliveryProviderUndetermined(code);
    }

    if (_isDefiniteAuthOrCredential(code, error)) {
      return const DeliveryProviderDefiniteFailure('PROVIDER_AUTH_FAILED');
    }

    if (MeInvoicePublishErrorCodes.isDefiniteFailure(code)) {
      return DeliveryProviderDefiniteFailure(code);
    }

    return DeliveryProviderUndetermined(code);
  }

  /// Closed allowlist only: prefix code and optional vendor token after `:`.
  /// Never substring-matches `auth` / `forbidden`.
  static bool _isDefiniteAuthOrCredential(String code, String error) {
    if (_definiteAuthOrCredentialCodes.contains(code)) {
      return true;
    }
    final vendorToken = _vendorTokenAfterColon(error);
    return vendorToken != null &&
        _definiteAuthOrCredentialCodes.contains(vendorToken);
  }

  /// e.g. `meinvoice_401: UnAuthorize` → `UnAuthorize`.
  static String? _vendorTokenAfterColon(String error) {
    final separator = error.indexOf(':');
    if (separator < 0) {
      return null;
    }
    final after = error.substring(separator + 1).trim();
    if (after.isEmpty) {
      return null;
    }
    final match = RegExp(r'^[A-Za-z][A-Za-z0-9_]{0,63}').firstMatch(after);
    return match?.group(0);
  }

  static bool _isRateLimited(String? error) {
    if (error == null) {
      return false;
    }
    final normalized = error.toLowerCase();
    return normalized.contains('rate_limited') || normalized.contains('429');
  }

  static bool _isAmbiguousTransport(String error) {
    final normalized = error.toLowerCase();
    return normalized.contains('timeout') ||
        normalized.contains('meinvoice_network') ||
        normalized.contains('connection') ||
        normalized.contains('meinvoice_5xx') ||
        normalized.contains('unavailable') ||
        normalized.contains('meinvoice_invalid_response') ||
        normalized.contains('not a json object') ||
        normalized.contains('malformed');
  }
}
