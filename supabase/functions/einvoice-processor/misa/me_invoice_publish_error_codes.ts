/** Known MISA publish error codes referenced by Mosaic Retail classification. */
const definiteFailureCodes: ReadonlySet<string> = new Set([
  'InvalidInvSeries',
  'InvalidTemplate',
  'InvalidData',
  'InvoiceDataInvalid',
  'InvalidBuyerTaxCode',
  'InvalidSignType',
])

const publishRejectionCodes: ReadonlySet<string> = new Set([
  ...definiteFailureCodes,
  // Dữ liệu hóa đơn sai.
  'InvalidInvoiceData',
  'TaxRateInfo_VATRateName',
  'BuyerTaxCode_TaxCodeInvalid',
  'InvalidTaxCode',
  'InvalidInvoiceDate',
  'InvalidXMLContainEmoji',
  'TaxReductionDateInValid',
  'InvoiceQuantityTooLarge',
  'XMLTooLong',
  // Mẫu hóa đơn / tờ khai chưa sẵn sàng.
  'InvoiceTemplateNotExist',
  'DeclarationNotExist',
  'InvalidDeclaration',
  'ExistDeclarationNotReceive',
  'InvoiceTemplateNotValidInDeclaration',
  'ExistsInvoiceNextYear',
  // Tài nguyên phát hành.
  'LicenseInfo_NotBuy',
  'LicenseInfo_OutOfInvoice',
  'LicenseInfo_Expired',
  // Chứng thư số không đáp ứng phát hành trực tiếp.
  'CallSignServiceFail',
])

const publishRejectionPrefixes: readonly string[] = [
  'InvoiceDetail_',
  'RequireError_',
  'StockInTaxCode_NotInfo_',
  'Invalid_',
]

export const MeInvoicePublishErrorCodes = {
  duplicateInvoiceRefId: 'DuplicateInvoiceRefID',
  /** MISA typo preserved in wire contract. */
  invoiceNumberNotContinuous: 'InvoiceNumberNotCotinuous',
  invoiceDuplicated: 'InvoiceDuplicated',
  definiteFailureCodes,
  publishRejectionCodes,
  publishRejectionPrefixes,

  isDuplicateRefId: (code: string | null | undefined): boolean => code === 'DuplicateInvoiceRefID',
  isRetryableProviderRejection: (code: string | null | undefined): boolean =>
    code === 'InvoiceNumberNotCotinuous',
  isReconcileFirstDuplicate: (code: string | null | undefined): boolean => code === 'InvoiceDuplicated',
  isDefiniteFailure: (code: string | null | undefined): boolean =>
    code != null && definiteFailureCodes.has(code),
  isPublishRejection(code: string | null | undefined): boolean {
    if (code == null || code === '') return false
    return publishRejectionCodes.has(code) || publishRejectionPrefixes.some((p) => code.startsWith(p))
  },
}
