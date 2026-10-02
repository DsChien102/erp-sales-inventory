/// Known MISA publish error codes referenced by Vet45 classification.
abstract final class MeInvoicePublishErrorCodes {
  static const duplicateInvoiceRefId = 'DuplicateInvoiceRefID';

  /// MISA typo preserved in wire contract.
  static const invoiceNumberNotContinuous = 'InvoiceNumberNotCotinuous';

  static const invoiceDuplicated = 'InvoiceDuplicated';

  /// Explicit validation rejections treated as definite no-side-effect failures.
  static const definiteFailureCodes = <String>{
    'InvalidInvSeries',
    'InvalidTemplate',
    'InvalidData',
    'InvoiceDataInvalid',
    'InvalidBuyerTaxCode',
    'InvalidSignType',
  };

  static bool isDuplicateRefId(String? code) => code == duplicateInvoiceRefId;

  static bool isRetryableProviderRejection(String? code) => code == invoiceNumberNotContinuous;

  static bool isReconcileFirstDuplicate(String? code) => code == invoiceDuplicated;

  static bool isDefiniteFailure(String? code) =>
      code != null && definiteFailureCodes.contains(code);

  /// Mã MISA từ chối `POST /invoice` trước khi phát hành (tài liệu AIO V2,
  /// mục "Mã lỗi thường gặp"): hóa đơn chắc chắn chưa được tạo.
  ///
  /// CHỈ dùng cho kết quả phát hành. Không gộp vào [definiteFailureCodes]:
  /// tập đó còn dùng cho `/invoice/status`, nơi lỗi khi hỏi trạng thái (vd.
  /// hết tài nguyên) không chứng minh hóa đơn chưa phát hành.
  ///
  /// Cố ý để ngoài (vẫn là undetermined, đi đối soát): `Exception`,
  /// `SignEsignHSMError`, `SignSoftDream78Exception`, `CreateInvoiceDataError`,
  /// `DuplicateRefID` — tài liệu không khẳng định chưa phát hành.
  static const publishRejectionCodes = <String>{
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
  };

  /// Mã có phần đuôi là tên trường, vd. `InvoiceDetail_ItemName`.
  /// `Invalid_` là dạng quan sát trên sandbox 2026-09-14:
  /// `Invalid_[Invoice.TaxRateInfo]`.
  static const publishRejectionPrefixes = <String>[
    'InvoiceDetail_',
    'RequireError_',
    'StockInTaxCode_NotInfo_',
    'Invalid_',
  ];

  static bool isPublishRejection(String? code) {
    if (code == null || code.isEmpty) {
      return false;
    }
    return publishRejectionCodes.contains(code) ||
        publishRejectionPrefixes.any(code.startsWith);
  }
}
