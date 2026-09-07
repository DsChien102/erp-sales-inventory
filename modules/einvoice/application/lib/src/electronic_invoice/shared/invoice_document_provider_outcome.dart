/// Closed provider outcome for invoice document download.
sealed class InvoiceDocumentProviderOutcome {
  const InvoiceDocumentProviderOutcome({
    this.responseReference,
    this.providerReference,
  });

  final String? responseReference;
  final String? providerReference;
}

final class InvoiceDocumentProviderSuccess extends InvoiceDocumentProviderOutcome {
  const InvoiceDocumentProviderSuccess({
    required this.bytes,
    super.responseReference,
    super.providerReference,
  });

  final List<int> bytes;
}

final class InvoiceDocumentProviderCheckRequired extends InvoiceDocumentProviderOutcome {
  const InvoiceDocumentProviderCheckRequired({
    required this.safeErrorCode,
    super.responseReference,
    super.providerReference,
  });

  final String safeErrorCode;
}

final class InvoiceDocumentProviderDefiniteFailure extends InvoiceDocumentProviderOutcome {
  const InvoiceDocumentProviderDefiniteFailure({
    required this.failureCode,
    this.failureMessage,
    super.responseReference,
    super.providerReference,
  });

  final String failureCode;
  final String? failureMessage;
}

final class InvoiceDocumentProviderAmbiguous extends InvoiceDocumentProviderOutcome {
  const InvoiceDocumentProviderAmbiguous({
    required this.safeErrorCode,
    super.responseReference,
  });

  final String safeErrorCode;
}
