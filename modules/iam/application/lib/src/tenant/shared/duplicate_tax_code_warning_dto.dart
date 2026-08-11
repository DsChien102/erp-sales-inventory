/// Duplicate tax-code warning — success variant, not a blocked exception.
///
/// Legal Profile upsert returns this inside [UpsertLegalProfileResultDto]
/// when tax code already exists elsewhere; no peer tenant PII.
final class DuplicateTaxCodeWarningDto {
  const DuplicateTaxCodeWarningDto({
    this.code = codeValue,
    required this.message,
  });

  /// Warning payload code (not part of APPENDICES §6.4 blocked catalog).
  static const codeValue = 'DUPLICATE_TAX_CODE_WARNING';

  final String code;
  final String message;
}
