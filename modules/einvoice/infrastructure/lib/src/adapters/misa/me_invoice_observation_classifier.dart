import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_misa/e_invoice.dart';

import 'me_invoice_provider_call_support.dart';

/// Classifies MISA `getStatus` results for provider observation polls.
abstract final class MeInvoiceObservationClassifier {
  static const _allowedDetailKeys = <String>{
    'publishStatus',
    'eInvoiceStatus',
    'referenceType',
    'sendTaxStatus',
    'invoiceCode',
    'invNo',
    'invSeries',
    'publishedTime',
    'transactionId',
  };

  static ProviderObservationOutcome classify({
    required MeInvoiceResult<List<MeInvoiceInvoiceStatus>> result,
    required String providerInvoiceReference,
    required DateTime now,
  }) {
    if (!result.isSuccess) {
      final error = result.error ?? 'unknown_error';
      MeInvoiceProviderCallSupport.throwIfTransportAmbiguous(error);
      return ProviderObservationAmbiguous(
        safeErrorCode: MeInvoiceProviderCallSupport.safeErrorCode(error),
      );
    }

    final statuses = result.data;
    if (statuses == null || statuses.isEmpty) {
      return ProviderObservationNotFound(
        providerStateCode: 'NOT_FOUND',
        safeDescription: 'PROVIDER_STATUS_NOT_FOUND',
        observedAt: now,
        providerReference: providerInvoiceReference,
      );
    }

    final item = statuses.first;
    if (_hasText(item.transactionId) &&
        item.transactionId != providerInvoiceReference) {
      return ProviderObservationMismatch(
        providerStateCode: 'MISMATCH',
        safeDescription: 'PROVIDER_IDENTITY_MISMATCH',
        observedAt: now,
        providerReference: providerInvoiceReference,
      );
    }

    final observedAt = item.publishedTime?.toUtc() ?? now;
    final providerStateCode = _providerStateCode(item);
    final safeDescription = _safeDescription(item);
    final detailsSnapshot = _detailsSnapshot(item);

    return ProviderObservationFound(
      providerStateCode: providerStateCode,
      safeDescription: safeDescription,
      observedAt: observedAt,
      detailsSnapshot: detailsSnapshot,
      providerReference: item.transactionId ?? providerInvoiceReference,
    );
  }

  static Map<String, Object?> _detailsSnapshot(MeInvoiceInvoiceStatus item) {
    final snapshot = <String, Object?>{};
    if (item.publishStatus != null) {
      snapshot['publishStatus'] = item.publishStatus;
    }
    if (item.eInvoiceStatus != null) {
      snapshot['eInvoiceStatus'] = item.eInvoiceStatus;
    }
    if (item.referenceType != null) {
      snapshot['referenceType'] = item.referenceType;
    }
    if (item.sendTaxStatus != null) {
      snapshot['sendTaxStatus'] = item.sendTaxStatus;
    }
    if (_hasText(item.invoiceCode)) {
      snapshot['invoiceCode'] = item.invoiceCode;
    }
    if (_hasText(item.invNo)) {
      snapshot['invNo'] = item.invNo;
    }
    if (_hasText(item.invSeries)) {
      snapshot['invSeries'] = item.invSeries;
    }
    if (item.publishedTime != null) {
      snapshot['publishedTime'] = item.publishedTime!.toUtc().toIso8601String();
    }
    if (_hasText(item.transactionId)) {
      snapshot['transactionId'] = item.transactionId;
    }
    assert(snapshot.keys.every(_allowedDetailKeys.contains));
    return snapshot;
  }

  static String _providerStateCode(MeInvoiceInvoiceStatus item) {
    final publish = item.publishStatus;
    final eInvoice = item.eInvoiceStatus;
    final publishLabel = publish == null ? 'UNKNOWN' : 'PS_$publish';
    final eInvoiceLabel = eInvoice == null ? 'UNKNOWN' : 'ES_$eInvoice';
    return '${publishLabel}_${eInvoiceLabel}';
  }

  static String _safeDescription(MeInvoiceInvoiceStatus item) {
    switch (item.publishStatus) {
      case 0:
        return 'NOT_PUBLISHED';
      case 1:
        return 'PUBLISHED';
      case null:
        return 'UNKNOWN_PUBLISH_STATUS';
      default:
        return 'UNKNOWN_${item.publishStatus}';
    }
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}
