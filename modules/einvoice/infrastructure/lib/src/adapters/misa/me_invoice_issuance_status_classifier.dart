import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_misa/e_invoice.dart';

/// Classifies raw MISA getStatus responses into closed [MeInvoiceIssuanceStatusOutcome].
///
/// Invariants:
/// - Never infers definite failure from network/parse/transport errors.
/// - Only terminal rejection codes become definite failure.
/// - Returns [MeInvoiceIssuanceStatusSuccess] only when invoice number, series, and provider reference are present.
/// - Returns [MeInvoiceIssuanceStatusPending] when status indicates still processing.
/// - Returns [MeInvoiceIssuanceStatusUndetermined] on transport errors, malformed responses, or unrecognized results.
abstract final class MeInvoiceIssuanceStatusClassifier {
  static MeInvoiceIssuanceStatusOutcome classify({
    required MeInvoiceResult<List<MeInvoiceInvoiceStatus>> statusResult,
    required String idempotencyKey,
    required String payloadHash,
  }) {
    if (!statusResult.isSuccess) {
      final error = statusResult.error ?? 'unknown_error';
      return _classifyError(
        error: error,
        idempotencyKey: idempotencyKey,
        payloadHash: payloadHash,
      );
    }

    final statuses = statusResult.data;
    if (statuses == null || statuses.isEmpty) {
      return const MeInvoiceIssuanceStatusUndetermined('STATUS_EMPTY_DATA');
    }

    final item = statuses.first;

    // PublishStatus == 1 indicates published / issued in MISA meInvoice API.
    if (item.publishStatus == 1 &&
        _hasText(item.invNo) &&
        _hasText(item.invSeries) &&
        _hasText(item.transactionId)) {
      final issuedAt = item.publishedTime?.toUtc() ?? DateTime.now().toUtc();
      return MeInvoiceIssuanceStatusOutcome.success(
        IssuanceResultEvidenceDto.success(
              idempotencyKey: idempotencyKey,
              payloadHash: payloadHash,
              providerReference: item.transactionId!,
              invoiceNumber: item.invNo!,
              invoiceSeries: item.invSeries!,
              issuedAt: issuedAt,
            )
            as IssuanceSuccessEvidenceDto,
      );
    }

    // Check if item contains an explicit definite failure code.
    // If invoiceCode or other string field contains terminal rejection:
    if (_hasText(item.invoiceCode) &&
        MeInvoicePublishErrorCodes.isDefiniteFailure(item.invoiceCode)) {
      return MeInvoiceIssuanceStatusOutcome.definiteFailure(
        IssuanceResultEvidenceDto.definiteFailure(
              idempotencyKey: idempotencyKey,
              payloadHash: payloadHash,
              providerCode: item.invoiceCode!,
              providerMessage: item.invoiceCode!,
            )
            as IssuanceDefiniteFailureEvidenceDto,
      );
    }

    // Pending / still processing (e.g. PublishStatus == 0 or other intermediate states)
    if (item.publishStatus == 0 || item.publishStatus == null) {
      return const MeInvoiceIssuanceStatusOutcome.pending();
    }

    // Default fallback for ambiguous states
    return const MeInvoiceIssuanceStatusOutcome.pending();
  }

  static MeInvoiceIssuanceStatusOutcome _classifyError({
    required String error,
    required String idempotencyKey,
    required String payloadHash,
  }) {
    final parts = error.split(':');
    final code = parts.first.trim();
    final message = parts.length > 1 ? parts.sublist(1).join(':').trim() : code;

    if (MeInvoicePublishErrorCodes.isDefiniteFailure(code)) {
      return MeInvoiceIssuanceStatusOutcome.definiteFailure(
        IssuanceResultEvidenceDto.definiteFailure(
              idempotencyKey: idempotencyKey,
              payloadHash: payloadHash,
              providerCode: code,
              providerMessage: message,
            )
            as IssuanceDefiniteFailureEvidenceDto,
      );
    }

    return MeInvoiceIssuanceStatusOutcome.undetermined(code);
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}
