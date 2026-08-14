import '../../internal/json_helpers.dart';
import 'clock_info.dart';
import 'fee_info.dart';
import 'option_user_defined.dart';
import 'original_invoice_detail.dart';
import 'other_info.dart';
import 'tax_rate_info.dart';

/// §13.3 InvoiceData — dữ liệu hóa đơn.
final class MeInvoiceInvoiceData {
  const MeInvoiceInvoiceData({
    this.refId,
    this.invSeries,
    this.invDate,
    this.currencyCode,
    this.exchangeRate,
    this.paymentMethodName,
    this.isInvoiceSummary,
    this.isSendEmail,
    this.receiverName,
    this.receiverEmail,
    this.sellerShopCode,
    this.sellerShopName,
    this.isInvoiceCalculatingMachine,
    this.buyerCode,
    this.buyerLegalName,
    this.buyerTaxCode,
    this.buyerAddress,
    this.buyerFullName,
    this.buyerPhoneNumber,
    this.buyerEmail,
    this.buyerBankAccount,
    this.buyerBankName,
    this.buyerIdNumber,
    this.buyerPassport,
    this.buyerBudgetCode,
    this.totalSaleAmountOc,
    this.totalSaleAmount,
    this.totalDiscountAmountOc,
    this.totalDiscountAmount,
    this.totalAmountWithoutVatOc,
    this.totalAmountWithoutVat,
    this.totalVatAmountOc,
    this.totalVatAmount,
    this.totalAmountOc,
    this.totalAmount,
    this.totalAmountInWords,
    this.totalAmountInWordsByEng,
    this.totalAmountInWordsUnsignNormalVn,
    this.customField1,
    this.customField2,
    this.customField3,
    this.customField4,
    this.customField5,
    this.customField6,
    this.customField7,
    this.customField8,
    this.customField9,
    this.customField10,
    this.periodName,
    this.periodFromDate,
    this.periodToDate,
    this.newIndex,
    this.oldIndex,
    this.amountOfConsumption,
    this.waterUsed,
    this.environment,
    this.environmmentFeeAmount,
    this.clockInfos,
    this.checkIn,
    this.checkOut,
    this.exciseTaxRate,
    this.serviceFeeRate,
    this.serviceAmountOc,
    this.serviceAmount,
    this.exciseTaxAmountOc,
    this.exciseTaxAmount,
    this.accountObjectIdentificationNumber,
    this.referenceType,
    this.orgInvoiceType,
    this.orgInvTemplateNo,
    this.orgInvSeries,
    this.orgInvNo,
    this.orgInvDate,
    this.invoiceNote,
    this.stockOutLegalName,
    this.stockOutTaxCode,
    this.internalCommand,
    this.stockOutAddress,
    this.transporterName,
    this.transport,
    this.stockOutFullName,
    this.transportContractCode,
    this.stockInLegalName,
    this.stockInTaxCode,
    this.stockInFullName,
    this.stockInAddress,
    this.contractCode,
    this.contractDate,
    this.internalCommandNo,
    this.internalCommandOwner,
    this.internalCommandDate,
    this.journalMemo,
    this.stockTotalAmountOc,
    this.stockTotalAmount,
    this.originalInvoiceDetail,
    this.taxRateInfo,
    this.optionUserDefined,
    this.otherInfo,
    this.feeInfo,
  });

  // --- General ---
  final String? refId;
  final String? invSeries;
  final String? invDate;
  final String? currencyCode;
  final double? exchangeRate;
  final String? paymentMethodName;
  final bool? isInvoiceSummary;
  final bool? isSendEmail;
  final String? receiverName;
  final String? receiverEmail;
  final String? sellerShopCode;
  final String? sellerShopName;
  final bool? isInvoiceCalculatingMachine;

  // --- Buyer ---
  final String? buyerCode;
  final String? buyerLegalName;
  final String? buyerTaxCode;
  final String? buyerAddress;
  final String? buyerFullName;
  final String? buyerPhoneNumber;
  final String? buyerEmail;
  final String? buyerBankAccount;
  final String? buyerBankName;
  final String? buyerIdNumber;
  final String? buyerPassport;
  final String? buyerBudgetCode;

  // --- Totals ---
  final double? totalSaleAmountOc;
  final double? totalSaleAmount;
  final double? totalDiscountAmountOc;
  final double? totalDiscountAmount;
  final double? totalAmountWithoutVatOc;
  final double? totalAmountWithoutVat;
  final double? totalVatAmountOc;
  final double? totalVatAmount;
  final double? totalAmountOc;
  final double? totalAmount;
  final String? totalAmountInWords;
  final String? totalAmountInWordsByEng;
  final String? totalAmountInWordsUnsignNormalVn;

  // --- Custom fields ---
  final String? customField1;
  final String? customField2;
  final String? customField3;
  final String? customField4;
  final String? customField5;
  final String? customField6;
  final String? customField7;
  final String? customField8;
  final String? customField9;
  final String? customField10;

  // --- Utilities (electric/water) ---
  final String? periodName;
  final DateTime? periodFromDate;
  final DateTime? periodToDate;
  final double? newIndex;
  final double? oldIndex;
  final double? amountOfConsumption;
  final double? waterUsed;
  final double? environment;
  /// MISA wire key typo: `EnvironmmentFeeAmount`.
  final double? environmmentFeeAmount;
  final List<MeInvoiceClockInfo>? clockInfos;

  // --- Hotel ---
  final DateTime? checkIn;
  final DateTime? checkOut;
  final double? exciseTaxRate;
  final double? serviceFeeRate;
  final double? serviceAmountOc;
  final double? serviceAmount;
  final double? exciseTaxAmountOc;
  final double? exciseTaxAmount;
  final String? accountObjectIdentificationNumber;

  // --- Adjustment / replacement ---
  final int? referenceType;
  final int? orgInvoiceType;
  final String? orgInvTemplateNo;
  final String? orgInvSeries;
  final String? orgInvNo;
  final String? orgInvDate;
  final String? invoiceNote;

  // --- Stock export (PXK) ---
  final String? stockOutLegalName;
  final String? stockOutTaxCode;
  final String? internalCommand;
  final String? stockOutAddress;
  final String? transporterName;
  final String? transport;
  final String? stockOutFullName;
  final String? transportContractCode;
  final String? stockInLegalName;
  final String? stockInTaxCode;
  final String? stockInFullName;
  final String? stockInAddress;
  final String? contractCode;
  final DateTime? contractDate;
  final String? internalCommandNo;
  final String? internalCommandOwner;
  final DateTime? internalCommandDate;
  final String? journalMemo;
  final double? stockTotalAmountOc;
  final double? stockTotalAmount;

  // --- Nested ---
  final List<MeInvoiceOriginalInvoiceDetail>? originalInvoiceDetail;
  final List<MeInvoiceTaxRateInfo>? taxRateInfo;
  final MeInvoiceOptionUserDefined? optionUserDefined;
  final List<MeInvoiceOtherInfo>? otherInfo;
  final List<MeInvoiceFeeInfo>? feeInfo;

  factory MeInvoiceInvoiceData.fromJson(Map<String, dynamic> json) {
    return MeInvoiceInvoiceData(
      refId: MeInvoiceJsonHelpers.readString(json, 'RefID'),
      invSeries: MeInvoiceJsonHelpers.readString(json, 'InvSeries'),
      invDate: MeInvoiceJsonHelpers.readString(json, 'InvDate'),
      currencyCode: MeInvoiceJsonHelpers.readString(json, 'CurrencyCode'),
      exchangeRate: MeInvoiceJsonHelpers.readDouble(json, 'ExchangeRate'),
      paymentMethodName: MeInvoiceJsonHelpers.readString(
        json,
        'PaymentMethodName',
      ),
      isInvoiceSummary: MeInvoiceJsonHelpers.readBool(json, 'IsInvoiceSummary'),
      isSendEmail: MeInvoiceJsonHelpers.readBool(json, 'IsSendEmail'),
      receiverName: MeInvoiceJsonHelpers.readString(json, 'ReceiverName'),
      receiverEmail: MeInvoiceJsonHelpers.readString(json, 'ReceiverEmail'),
      sellerShopCode: MeInvoiceJsonHelpers.readString(json, 'SellerShopCode'),
      sellerShopName: MeInvoiceJsonHelpers.readString(json, 'SellerShopName'),
      isInvoiceCalculatingMachine: MeInvoiceJsonHelpers.readBool(
        json,
        'IsInvoiceCalculatingMachine',
      ),
      buyerCode: MeInvoiceJsonHelpers.readString(json, 'BuyerCode'),
      buyerLegalName: MeInvoiceJsonHelpers.readString(json, 'BuyerLegalName'),
      buyerTaxCode: MeInvoiceJsonHelpers.readString(json, 'BuyerTaxCode'),
      buyerAddress: MeInvoiceJsonHelpers.readString(json, 'BuyerAddress'),
      buyerFullName: MeInvoiceJsonHelpers.readString(json, 'BuyerFullName'),
      buyerPhoneNumber: MeInvoiceJsonHelpers.readString(
        json,
        'BuyerPhoneNumber',
      ),
      buyerEmail: MeInvoiceJsonHelpers.readString(json, 'BuyerEmail'),
      buyerBankAccount: MeInvoiceJsonHelpers.readString(
        json,
        'BuyerBankAccount',
      ),
      buyerBankName: MeInvoiceJsonHelpers.readString(json, 'BuyerBankName'),
      buyerIdNumber: MeInvoiceJsonHelpers.readString(json, 'BuyerIDNumber'),
      buyerPassport: MeInvoiceJsonHelpers.readString(json, 'BuyerPassport'),
      buyerBudgetCode: MeInvoiceJsonHelpers.readString(json, 'BuyerBudgetCode'),
      totalSaleAmountOc: MeInvoiceJsonHelpers.readDouble(
        json,
        'TotalSaleAmountOC',
      ),
      totalSaleAmount: MeInvoiceJsonHelpers.readDouble(json, 'TotalSaleAmount'),
      totalDiscountAmountOc: MeInvoiceJsonHelpers.readDouble(
        json,
        'TotalDiscountAmountOC',
      ),
      totalDiscountAmount: MeInvoiceJsonHelpers.readDouble(
        json,
        'TotalDiscountAmount',
      ),
      totalAmountWithoutVatOc: MeInvoiceJsonHelpers.readDouble(
        json,
        'TotalAmountWithoutVATOC',
      ),
      totalAmountWithoutVat: MeInvoiceJsonHelpers.readDouble(
        json,
        'TotalAmountWithoutVAT',
      ),
      totalVatAmountOc: MeInvoiceJsonHelpers.readDouble(json, 'TotalVATAmountOC'),
      totalVatAmount: MeInvoiceJsonHelpers.readDouble(json, 'TotalVATAmount'),
      totalAmountOc: MeInvoiceJsonHelpers.readDouble(json, 'TotalAmountOC'),
      totalAmount: MeInvoiceJsonHelpers.readDouble(json, 'TotalAmount'),
      totalAmountInWords: MeInvoiceJsonHelpers.readString(
        json,
        'TotalAmountInWords',
      ),
      totalAmountInWordsByEng: MeInvoiceJsonHelpers.readString(
        json,
        'TotalAmountInWordsByENG',
      ),
      totalAmountInWordsUnsignNormalVn: MeInvoiceJsonHelpers.readString(
        json,
        'TotalAmountInWordsUnsignNormalVN',
      ),
      customField1: MeInvoiceJsonHelpers.readString(json, 'CustomField1'),
      customField2: MeInvoiceJsonHelpers.readString(json, 'CustomField2'),
      customField3: MeInvoiceJsonHelpers.readString(json, 'CustomField3'),
      customField4: MeInvoiceJsonHelpers.readString(json, 'CustomField4'),
      customField5: MeInvoiceJsonHelpers.readString(json, 'CustomField5'),
      customField6: MeInvoiceJsonHelpers.readString(json, 'CustomField6'),
      customField7: MeInvoiceJsonHelpers.readString(json, 'CustomField7'),
      customField8: MeInvoiceJsonHelpers.readString(json, 'CustomField8'),
      customField9: MeInvoiceJsonHelpers.readString(json, 'CustomField9'),
      customField10: MeInvoiceJsonHelpers.readString(json, 'CustomField10'),
      periodName: MeInvoiceJsonHelpers.readString(json, 'PeriodName'),
      periodFromDate: MeInvoiceJsonHelpers.readDateTime(json, 'PeriodFromDate'),
      periodToDate: MeInvoiceJsonHelpers.readDateTime(json, 'PeriodToDate'),
      newIndex: MeInvoiceJsonHelpers.readDouble(json, 'NewIndex'),
      oldIndex: MeInvoiceJsonHelpers.readDouble(json, 'OldIndex'),
      amountOfConsumption: MeInvoiceJsonHelpers.readDouble(
        json,
        'AmountOfConsumption',
      ),
      waterUsed: MeInvoiceJsonHelpers.readDouble(json, 'WaterUsed'),
      environment: MeInvoiceJsonHelpers.readDouble(json, 'Environment'),
      environmmentFeeAmount: MeInvoiceJsonHelpers.readDouble(
        json,
        'EnvironmmentFeeAmount',
      ),
      clockInfos: _parseClockInfos(json['ClockInfos']),
      checkIn: MeInvoiceJsonHelpers.readDateTime(json, 'CheckIn'),
      checkOut: MeInvoiceJsonHelpers.readDateTime(json, 'CheckOut'),
      exciseTaxRate: MeInvoiceJsonHelpers.readDouble(json, 'ExciseTaxRate'),
      serviceFeeRate: MeInvoiceJsonHelpers.readDouble(json, 'ServiceFeeRate'),
      serviceAmountOc: MeInvoiceJsonHelpers.readDouble(
        json,
        'ServiceAmountOC',
      ),
      serviceAmount: MeInvoiceJsonHelpers.readDouble(json, 'ServiceAmount'),
      exciseTaxAmountOc: MeInvoiceJsonHelpers.readDouble(
        json,
        'ExciseTaxAmountOC',
      ),
      exciseTaxAmount: MeInvoiceJsonHelpers.readDouble(json, 'ExciseTaxAmount'),
      accountObjectIdentificationNumber: MeInvoiceJsonHelpers.readString(
        json,
        'AccountObjectIdentificationNumber',
      ),
      referenceType: MeInvoiceJsonHelpers.readInt(json, 'ReferenceType'),
      orgInvoiceType: MeInvoiceJsonHelpers.readInt(json, 'OrgInvoiceType'),
      orgInvTemplateNo: MeInvoiceJsonHelpers.readString(
        json,
        'OrgInvTemplateNo',
      ),
      orgInvSeries: MeInvoiceJsonHelpers.readString(json, 'OrgInvSeries'),
      orgInvNo: MeInvoiceJsonHelpers.readString(json, 'OrgInvNo'),
      orgInvDate: MeInvoiceJsonHelpers.readString(json, 'OrgInvDate'),
      invoiceNote: MeInvoiceJsonHelpers.readString(json, 'InvoiceNote'),
      stockOutLegalName: MeInvoiceJsonHelpers.readString(
        json,
        'StockOutLegalName',
      ),
      stockOutTaxCode: MeInvoiceJsonHelpers.readString(json, 'StockOutTaxCode'),
      internalCommand: MeInvoiceJsonHelpers.readString(json, 'InternalCommand'),
      stockOutAddress: MeInvoiceJsonHelpers.readString(json, 'StockOutAddress'),
      transporterName: MeInvoiceJsonHelpers.readString(json, 'TransporterName'),
      transport: MeInvoiceJsonHelpers.readString(json, 'Transport'),
      stockOutFullName: MeInvoiceJsonHelpers.readString(
        json,
        'StockOutFullName',
      ),
      transportContractCode: MeInvoiceJsonHelpers.readString(
        json,
        'TransportContractCode',
      ),
      stockInLegalName: MeInvoiceJsonHelpers.readString(json, 'StockInLegalName'),
      stockInTaxCode: MeInvoiceJsonHelpers.readString(json, 'StockInTaxCode'),
      stockInFullName: MeInvoiceJsonHelpers.readString(json, 'StockInFullName'),
      stockInAddress: MeInvoiceJsonHelpers.readString(json, 'StockInAddress'),
      contractCode: MeInvoiceJsonHelpers.readString(json, 'ContractCode'),
      contractDate: MeInvoiceJsonHelpers.readDateTime(json, 'ContractDate'),
      internalCommandNo: MeInvoiceJsonHelpers.readString(
        json,
        'InternalCommandNo',
      ),
      internalCommandOwner: MeInvoiceJsonHelpers.readString(
        json,
        'InternalCommandOwner',
      ),
      internalCommandDate: MeInvoiceJsonHelpers.readDateTime(
        json,
        'InternalCommandDate',
      ),
      journalMemo: MeInvoiceJsonHelpers.readString(json, 'JournalMemo'),
      stockTotalAmountOc: MeInvoiceJsonHelpers.readDouble(
        json,
        'StockTotalAmountOC',
      ),
      stockTotalAmount: MeInvoiceJsonHelpers.readDouble(
        json,
        'StockTotalAmount',
      ),
      originalInvoiceDetail: _parseDetails(json['OriginalInvoiceDetail']),
      taxRateInfo: _parseTaxRates(json['TaxRateInfo']),
      optionUserDefined: _parseOption(json['OptionUserDefined']),
      otherInfo: _parseOtherInfo(json['OtherInfo']),
      feeInfo: _parseFeeInfo(json['FeeInfo']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'RefID', refId);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'InvSeries', invSeries);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'InvDate', invDate);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'CurrencyCode', currencyCode);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'ExchangeRate', exchangeRate);
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'PaymentMethodName',
      paymentMethodName,
    );
    MeInvoiceJsonHelpers.writeIfPresent(map, 'IsInvoiceSummary', isInvoiceSummary);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'IsSendEmail', isSendEmail);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'ReceiverName', receiverName);
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'ReceiverEmail',
      receiverEmail,
    );
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'SellerShopCode', sellerShopCode);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'SellerShopName', sellerShopName);
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'IsInvoiceCalculatingMachine',
      isInvoiceCalculatingMachine,
    );
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'BuyerCode', buyerCode);
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'BuyerLegalName',
      buyerLegalName,
    );
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'BuyerTaxCode', buyerTaxCode);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'BuyerAddress', buyerAddress);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'BuyerFullName', buyerFullName);
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'BuyerPhoneNumber',
      buyerPhoneNumber,
    );
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'BuyerEmail', buyerEmail);
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'BuyerBankAccount',
      buyerBankAccount,
    );
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'BuyerBankName', buyerBankName);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'BuyerIDNumber', buyerIdNumber);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'BuyerPassport', buyerPassport);
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'BuyerBudgetCode',
      buyerBudgetCode,
    );
    MeInvoiceJsonHelpers.writeIfPresent(map, 'TotalSaleAmountOC', totalSaleAmountOc);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'TotalSaleAmount', totalSaleAmount);
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'TotalDiscountAmountOC',
      totalDiscountAmountOc,
    );
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'TotalDiscountAmount',
      totalDiscountAmount,
    );
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'TotalAmountWithoutVATOC',
      totalAmountWithoutVatOc,
    );
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'TotalAmountWithoutVAT',
      totalAmountWithoutVat,
    );
    MeInvoiceJsonHelpers.writeIfPresent(map, 'TotalVATAmountOC', totalVatAmountOc);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'TotalVATAmount', totalVatAmount);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'TotalAmountOC', totalAmountOc);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'TotalAmount', totalAmount);
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'TotalAmountInWords',
      totalAmountInWords,
    );
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'TotalAmountInWordsByENG',
      totalAmountInWordsByEng,
    );
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'TotalAmountInWordsUnsignNormalVN',
      totalAmountInWordsUnsignNormalVn,
    );
    for (final entry in <MapEntry<String, String?>>[
      MapEntry('CustomField1', customField1),
      MapEntry('CustomField2', customField2),
      MapEntry('CustomField3', customField3),
      MapEntry('CustomField4', customField4),
      MapEntry('CustomField5', customField5),
      MapEntry('CustomField6', customField6),
      MapEntry('CustomField7', customField7),
      MapEntry('CustomField8', customField8),
      MapEntry('CustomField9', customField9),
      MapEntry('CustomField10', customField10),
    ]) {
      MeInvoiceJsonHelpers.writeStringIfPresent(map, entry.key, entry.value);
    }
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'PeriodName', periodName);
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'PeriodFromDate',
      periodFromDate?.toUtc().toIso8601String(),
    );
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'PeriodToDate',
      periodToDate?.toUtc().toIso8601String(),
    );
    MeInvoiceJsonHelpers.writeIfPresent(map, 'NewIndex', newIndex);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'OldIndex', oldIndex);
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'AmountOfConsumption',
      amountOfConsumption,
    );
    MeInvoiceJsonHelpers.writeIfPresent(map, 'WaterUsed', waterUsed);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'Environment', environment);
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'EnvironmmentFeeAmount',
      environmmentFeeAmount,
    );
    if (clockInfos != null && clockInfos!.isNotEmpty) {
      map['ClockInfos'] = clockInfos!.map((e) => e.toJson()).toList();
    }
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'CheckIn',
      checkIn?.toUtc().toIso8601String(),
    );
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'CheckOut',
      checkOut?.toUtc().toIso8601String(),
    );
    MeInvoiceJsonHelpers.writeIfPresent(map, 'ExciseTaxRate', exciseTaxRate);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'ServiceFeeRate', serviceFeeRate);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'ServiceAmountOC', serviceAmountOc);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'ServiceAmount', serviceAmount);
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'ExciseTaxAmountOC',
      exciseTaxAmountOc,
    );
    MeInvoiceJsonHelpers.writeIfPresent(map, 'ExciseTaxAmount', exciseTaxAmount);
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'AccountObjectIdentificationNumber',
      accountObjectIdentificationNumber,
    );
    MeInvoiceJsonHelpers.writeIfPresent(map, 'ReferenceType', referenceType);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'OrgInvoiceType', orgInvoiceType);
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'OrgInvTemplateNo',
      orgInvTemplateNo,
    );
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'OrgInvSeries', orgInvSeries);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'OrgInvNo', orgInvNo);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'OrgInvDate', orgInvDate);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'InvoiceNote', invoiceNote);
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'StockOutLegalName',
      stockOutLegalName,
    );
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'StockOutTaxCode', stockOutTaxCode);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'InternalCommand', internalCommand);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'StockOutAddress', stockOutAddress);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'TransporterName', transporterName);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'Transport', transport);
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'StockOutFullName',
      stockOutFullName,
    );
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'TransportContractCode',
      transportContractCode,
    );
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'StockInLegalName', stockInLegalName);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'StockInTaxCode', stockInTaxCode);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'StockInFullName', stockInFullName);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'StockInAddress', stockInAddress);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'ContractCode', contractCode);
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'ContractDate',
      contractDate?.toUtc().toIso8601String(),
    );
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'InternalCommandNo',
      internalCommandNo,
    );
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'InternalCommandOwner',
      internalCommandOwner,
    );
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'InternalCommandDate',
      internalCommandDate?.toUtc().toIso8601String(),
    );
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'JournalMemo', journalMemo);
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'StockTotalAmountOC',
      stockTotalAmountOc,
    );
    MeInvoiceJsonHelpers.writeIfPresent(map, 'StockTotalAmount', stockTotalAmount);
    if (originalInvoiceDetail != null && originalInvoiceDetail!.isNotEmpty) {
      map['OriginalInvoiceDetail'] =
          originalInvoiceDetail!.map((e) => e.toJson()).toList();
    }
    if (taxRateInfo != null && taxRateInfo!.isNotEmpty) {
      map['TaxRateInfo'] = taxRateInfo!.map((e) => e.toJson()).toList();
    }
    if (optionUserDefined != null) {
      map['OptionUserDefined'] = optionUserDefined!.toJson();
    }
    if (otherInfo != null && otherInfo!.isNotEmpty) {
      map['OtherInfo'] = otherInfo!.map((e) => e.toJson()).toList();
    }
    if (feeInfo != null && feeInfo!.isNotEmpty) {
      map['FeeInfo'] = feeInfo!.map((e) => e.toJson()).toList();
    }
    return map;
  }

  static List<MeInvoiceClockInfo>? _parseClockInfos(Object? raw) {
    final list = MeInvoiceJsonHelpers.asList(raw);
    if (list.isEmpty) {
      return null;
    }
    return list
        .map(MeInvoiceJsonHelpers.asMap)
        .whereType<Map<String, dynamic>>()
        .map(MeInvoiceClockInfo.fromJson)
        .toList();
  }

  static List<MeInvoiceOriginalInvoiceDetail>? _parseDetails(Object? raw) {
    final list = MeInvoiceJsonHelpers.asList(raw);
    if (list.isEmpty) {
      return null;
    }
    return list
        .map(MeInvoiceJsonHelpers.asMap)
        .whereType<Map<String, dynamic>>()
        .map(MeInvoiceOriginalInvoiceDetail.fromJson)
        .toList();
  }

  static List<MeInvoiceTaxRateInfo>? _parseTaxRates(Object? raw) {
    final list = MeInvoiceJsonHelpers.asList(raw);
    if (list.isEmpty) {
      return null;
    }
    return list
        .map(MeInvoiceJsonHelpers.asMap)
        .whereType<Map<String, dynamic>>()
        .map(MeInvoiceTaxRateInfo.fromJson)
        .toList();
  }

  static MeInvoiceOptionUserDefined? _parseOption(Object? raw) {
    final map = MeInvoiceJsonHelpers.asMap(raw);
    if (map == null) {
      return null;
    }
    return MeInvoiceOptionUserDefined.fromJson(map);
  }

  static List<MeInvoiceOtherInfo>? _parseOtherInfo(Object? raw) {
    final list = MeInvoiceJsonHelpers.asList(raw);
    if (list.isEmpty) {
      return null;
    }
    return list
        .map(MeInvoiceJsonHelpers.asMap)
        .whereType<Map<String, dynamic>>()
        .map(MeInvoiceOtherInfo.fromJson)
        .toList();
  }

  static List<MeInvoiceFeeInfo>? _parseFeeInfo(Object? raw) {
    final list = MeInvoiceJsonHelpers.asList(raw);
    if (list.isEmpty) {
      return null;
    }
    return list
        .map(MeInvoiceJsonHelpers.asMap)
        .whereType<Map<String, dynamic>>()
        .map(MeInvoiceFeeInfo.fromJson)
        .toList();
  }
}
