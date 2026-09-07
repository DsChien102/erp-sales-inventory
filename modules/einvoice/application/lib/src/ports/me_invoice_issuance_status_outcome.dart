import '../issuance/shared/issuance_result_evidence_dto.dart';

/// Closed outcome hierarchy for MISA getStatus provider polling.
sealed class MeInvoiceIssuanceStatusOutcome {
  const MeInvoiceIssuanceStatusOutcome();

  const factory MeInvoiceIssuanceStatusOutcome.success(
    IssuanceSuccessEvidenceDto evidence,
  ) = MeInvoiceIssuanceStatusSuccess;

  const factory MeInvoiceIssuanceStatusOutcome.definiteFailure(
    IssuanceDefiniteFailureEvidenceDto evidence,
  ) = MeInvoiceIssuanceStatusDefiniteFailure;

  const factory MeInvoiceIssuanceStatusOutcome.pending() = MeInvoiceIssuanceStatusPending;

  const factory MeInvoiceIssuanceStatusOutcome.undetermined(
    String reasonCode,
  ) = MeInvoiceIssuanceStatusUndetermined;
}

final class MeInvoiceIssuanceStatusSuccess extends MeInvoiceIssuanceStatusOutcome {
  const MeInvoiceIssuanceStatusSuccess(this.evidence);

  final IssuanceSuccessEvidenceDto evidence;
}

final class MeInvoiceIssuanceStatusDefiniteFailure extends MeInvoiceIssuanceStatusOutcome {
  const MeInvoiceIssuanceStatusDefiniteFailure(this.evidence);

  final IssuanceDefiniteFailureEvidenceDto evidence;
}

final class MeInvoiceIssuanceStatusPending extends MeInvoiceIssuanceStatusOutcome {
  const MeInvoiceIssuanceStatusPending();
}

final class MeInvoiceIssuanceStatusUndetermined extends MeInvoiceIssuanceStatusOutcome {
  const MeInvoiceIssuanceStatusUndetermined(this.reasonCode);

  final String reasonCode;
}
