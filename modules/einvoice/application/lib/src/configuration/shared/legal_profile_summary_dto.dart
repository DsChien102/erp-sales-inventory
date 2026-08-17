/// Read-only legal profile shown on provider connection screen.
final class LegalProfileSummaryDto {
  const LegalProfileSummaryDto({
    required this.legalName,
    required this.taxCode,
    this.address,
  });

  final String legalName;
  final String taxCode;
  final String? address;
}
