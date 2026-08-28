import 'me_invoice_safe_provider_evidence.dart';

/// Closed, safe classification of a MISA publish attempt.
sealed class MeInvoicePublishOutcome {
  const MeInvoicePublishOutcome();
}

/// Correlated provider success with allow-listed identity fields.
final class MeInvoicePublishSuccess extends MeInvoicePublishOutcome {
  const MeInvoicePublishSuccess({
    required this.providerReference,
    required this.invoiceNumber,
    required this.invoiceSeries,
    required this.issuedAt,
    this.safeProviderEvidence,
  });

  final String providerReference;
  final String invoiceNumber;
  final String invoiceSeries;
  final DateTime issuedAt;
  final MeInvoiceSafeProviderEvidence? safeProviderEvidence;
}

/// Explicit provider rejection known to have produced no invoice side effect.
final class MeInvoicePublishDefiniteFailure extends MeInvoicePublishOutcome {
  const MeInvoicePublishDefiniteFailure({
    required this.providerCode,
    required this.providerMessage,
    this.safeProviderEvidence,
  });

  final String providerCode;
  final String providerMessage;
  final MeInvoiceSafeProviderEvidence? safeProviderEvidence;
}

/// Timeout, ambiguous, uncorrelated, duplicate RefID, or other unknown outcome.
final class MeInvoicePublishUndetermined extends MeInvoicePublishOutcome {
  const MeInvoicePublishUndetermined({
    required this.reasonCode,
    this.safeProviderEvidence,
  });

  final String reasonCode;
  final MeInvoiceSafeProviderEvidence? safeProviderEvidence;
}
