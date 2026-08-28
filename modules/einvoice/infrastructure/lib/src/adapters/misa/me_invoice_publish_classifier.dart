import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_misa/e_invoice.dart';

/// Maps low-level MISA publish results into closed [MeInvoicePublishOutcome].
abstract final class MeInvoicePublishClassifier {
  static MeInvoicePublishOutcome classify({
    required String idempotencyKey,
    required MeInvoiceResult<List<MeInvoicePublishInvoiceResultItem>> result,
    required Map<String, Object?> canonicalInvoice,
  }) {
    if (!result.isSuccess) {
      return _classifyTransportOrEnvelopeFailure(
        idempotencyKey: idempotencyKey,
        error: result.error ?? 'meinvoice_unknown_error',
      );
    }

    final items = result.data ?? const [];
    if (items.isEmpty) {
      return MeInvoicePublishUndetermined(
        reasonCode: 'PROVIDER_EMPTY_RESULT',
        safeProviderEvidence: MeInvoiceSafeProviderEvidence(refId: idempotencyKey),
      );
    }

    final item = items.first;

    if (MeInvoicePublishErrorCodes.isDuplicateRefId(item.errorCode)) {
      return MeInvoicePublishUndetermined(
        reasonCode: 'DUPLICATE_INVOICE_REF_ID',
        safeProviderEvidence: _safeEvidence(item),
      );
    }

    if (item.refId != null &&
        item.refId!.isNotEmpty &&
        item.refId != idempotencyKey) {
      return MeInvoicePublishUndetermined(
        reasonCode: 'PROVIDER_UNCORRELATED_RESPONSE',
        safeProviderEvidence: _safeEvidence(item),
      );
    }

    if (item.isSuccess &&
        _hasText(item.transactionId) &&
        _hasText(item.invNo) &&
        _hasText(item.invSeries)) {
      return MeInvoicePublishSuccess(
        providerReference: item.transactionId!,
        invoiceNumber: item.invNo!,
        invoiceSeries: item.invSeries!,
        issuedAt: _resolveIssuedAt(canonicalInvoice),
        safeProviderEvidence: _safeEvidence(item),
      );
    }

    if (!item.isSuccess &&
        MeInvoicePublishErrorCodes.isDefiniteFailure(item.errorCode)) {
      return MeInvoicePublishDefiniteFailure(
        providerCode: item.errorCode!,
        providerMessage: _safeMessage(item),
        safeProviderEvidence: _safeEvidence(item),
      );
    }

    if (!item.isSuccess) {
      return MeInvoicePublishUndetermined(
        reasonCode: 'PROVIDER_ITEM_ERROR',
        safeProviderEvidence: _safeEvidence(item),
      );
    }

    return MeInvoicePublishUndetermined(
      reasonCode: 'PROVIDER_INCOMPLETE_SUCCESS',
      safeProviderEvidence: _safeEvidence(item),
    );
  }

  static MeInvoicePublishOutcome _classifyTransportOrEnvelopeFailure({
    required String idempotencyKey,
    required String error,
  }) {
    final normalized = error.toLowerCase();
    if (normalized.contains('timeout') ||
        normalized.contains('meinvoice_network') ||
        normalized.contains('connection')) {
      return MeInvoicePublishUndetermined(
        reasonCode: 'PROVIDER_TIMEOUT',
        safeProviderEvidence: MeInvoiceSafeProviderEvidence(refId: idempotencyKey),
      );
    }
    if (normalized.contains('meinvoice_invalid_response') ||
        normalized.contains('not a json object')) {
      return MeInvoicePublishUndetermined(
        reasonCode: 'PROVIDER_MALFORMED_RESPONSE',
        safeProviderEvidence: MeInvoiceSafeProviderEvidence(refId: idempotencyKey),
      );
    }
    if (_isEnvelopeDefiniteFailure(error)) {
      final parts = error.split(':');
      final code = parts.first.trim();
      final message = parts.length > 1 ? parts.sublist(1).join(':').trim() : code;
      return MeInvoicePublishDefiniteFailure(
        providerCode: code,
        providerMessage: message,
        safeProviderEvidence: MeInvoiceSafeProviderEvidence(
          refId: idempotencyKey,
          providerCode: code,
          providerMessage: message,
        ),
      );
    }
    return MeInvoicePublishUndetermined(
      reasonCode: 'PROVIDER_TRANSPORT_ERROR',
      safeProviderEvidence: MeInvoiceSafeProviderEvidence(refId: idempotencyKey),
    );
  }

  static bool _isEnvelopeDefiniteFailure(String error) {
    final code = error.split(':').first.trim();
    return MeInvoicePublishErrorCodes.isDefiniteFailure(code);
  }

  static MeInvoiceSafeProviderEvidence _safeEvidence(
    MeInvoicePublishInvoiceResultItem item,
  ) {
    return MeInvoiceSafeProviderEvidence(
      refId: item.refId,
      transactionId: item.transactionId,
      invoiceNumber: item.invNo,
      invoiceSeries: item.invSeries,
      providerCode: item.errorCode,
      providerMessage: _safeMessage(item),
    );
  }

  static String _safeMessage(MeInvoicePublishInvoiceResultItem item) {
    final description = item.descriptionErrorCode?.trim();
    if (description != null && description.isNotEmpty) {
      return description.length <= 200
          ? description
          : '${description.substring(0, 200)}…';
    }
    return item.errorCode ?? 'provider_error';
  }

  static DateTime _resolveIssuedAt(Map<String, Object?> canonicalInvoice) {
    final invDate = canonicalInvoice['invDate'];
    if (invDate is String && invDate.isNotEmpty) {
      final parts = invDate.split('-');
      if (parts.length == 3) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);
        if (year != null && month != null && day != null) {
          return DateTime.utc(year, month, day);
        }
      }
      final parsed = DateTime.tryParse(invDate);
      if (parsed != null) {
        return parsed.toUtc();
      }
    }
    return DateTime.now().toUtc();
  }

  static bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
}
