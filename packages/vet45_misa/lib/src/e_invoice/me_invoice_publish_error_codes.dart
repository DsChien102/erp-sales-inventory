/// Known MISA publish error codes referenced by Vet45 classification.
abstract final class MeInvoicePublishErrorCodes {
  static const duplicateInvoiceRefId = 'DuplicateInvoiceRefID';

  /// Explicit validation rejections treated as definite no-side-effect failures.
  static const definiteFailureCodes = <String>{
    'InvalidInvSeries',
    'InvalidTemplate',
    'InvalidData',
    'InvoiceDataInvalid',
    'InvalidBuyerTaxCode',
    'InvalidSignType',
  };

  static bool isDuplicateRefId(String? code) =>
      code == duplicateInvoiceRefId;

  static bool isDefiniteFailure(String? code) =>
      code != null && definiteFailureCodes.contains(code);
}
