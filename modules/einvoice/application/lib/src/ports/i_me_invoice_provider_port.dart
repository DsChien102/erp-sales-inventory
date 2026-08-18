/// Outbound MISA provider operations (worker-only implementation).
abstract interface class IMeInvoiceProviderPort {
  Future<MeInvoiceAuthOutcome> authenticateAndListTemplates({
    required String tenantId,
    required String connectionId,
  });
}

/// Result of MISA auth + template listing for capability sync.
final class MeInvoiceAuthOutcome {
  const MeInvoiceAuthOutcome.success({
    required this.templateCount,
    required this.supportsEmailDelivery,
  }) : authFailed = false,
       providerUnavailable = false;

  const MeInvoiceAuthOutcome.authFailed()
    : templateCount = 0,
      supportsEmailDelivery = false,
      authFailed = true,
      providerUnavailable = false;

  const MeInvoiceAuthOutcome.providerUnavailable()
    : templateCount = 0,
      supportsEmailDelivery = false,
      authFailed = false,
      providerUnavailable = true;

  final int templateCount;
  final bool supportsEmailDelivery;
  final bool authFailed;
  final bool providerUnavailable;

  bool get isSuccess => !authFailed && !providerUnavailable;
}
