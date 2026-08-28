/// Allow-listed typed evidence for immediate issuance result landing.
sealed class IssuanceResultEvidenceDto {
  const IssuanceResultEvidenceDto({
    required this.idempotencyKey,
    required this.payloadHash,
  });

  final String idempotencyKey;
  final String payloadHash;

  factory IssuanceResultEvidenceDto.success({
    required String idempotencyKey,
    required String payloadHash,
    required String providerReference,
    required String invoiceNumber,
    required String invoiceSeries,
    required DateTime issuedAt,
  }) = IssuanceSuccessEvidenceDto;

  factory IssuanceResultEvidenceDto.definiteFailure({
    required String idempotencyKey,
    required String payloadHash,
    required String providerCode,
    required String providerMessage,
  }) = IssuanceDefiniteFailureEvidenceDto;

  factory IssuanceResultEvidenceDto.undetermined({
    required String idempotencyKey,
    required String payloadHash,
    required String reasonCode,
  }) = IssuanceUndeterminedEvidenceDto;
}

final class IssuanceSuccessEvidenceDto extends IssuanceResultEvidenceDto {
  const IssuanceSuccessEvidenceDto({
    required super.idempotencyKey,
    required super.payloadHash,
    required this.providerReference,
    required this.invoiceNumber,
    required this.invoiceSeries,
    required this.issuedAt,
  });

  final String providerReference;
  final String invoiceNumber;
  final String invoiceSeries;
  final DateTime issuedAt;
}

final class IssuanceDefiniteFailureEvidenceDto extends IssuanceResultEvidenceDto {
  const IssuanceDefiniteFailureEvidenceDto({
    required super.idempotencyKey,
    required super.payloadHash,
    required this.providerCode,
    required this.providerMessage,
  });

  final String providerCode;
  final String providerMessage;
}

final class IssuanceUndeterminedEvidenceDto extends IssuanceResultEvidenceDto {
  const IssuanceUndeterminedEvidenceDto({
    required super.idempotencyKey,
    required super.payloadHash,
    required this.reasonCode,
  });

  final String reasonCode;
}
