import { MeInvoiceJsonHelpers as J } from '../../internal/json_helpers.ts'
import { MeInvoiceClockInfo } from './clock_info.ts'
import { MeInvoiceFeeInfo } from './fee_info.ts'
import { MeInvoiceOptionUserDefined } from './option_user_defined.ts'
import { MeInvoiceOriginalInvoiceDetail } from './original_invoice_detail.ts'
import { MeInvoiceOtherInfo } from './other_info.ts'
import { MeInvoiceTaxRateInfo } from './tax_rate_info.ts'

export interface MeInvoiceInvoiceDataInit {
  refId?: string | null
  invSeries?: string | null
  invDate?: string | null
  currencyCode?: string | null
  exchangeRate?: number | null
  paymentMethodName?: string | null
  isInvoiceSummary?: boolean | null
  isSendEmail?: boolean | null
  receiverName?: string | null
  receiverEmail?: string | null
  sellerShopCode?: string | null
  sellerShopName?: string | null
  isInvoiceCalculatingMachine?: boolean | null
  buyerCode?: string | null
  buyerLegalName?: string | null
  buyerTaxCode?: string | null
  buyerAddress?: string | null
  buyerFullName?: string | null
  buyerPhoneNumber?: string | null
  buyerEmail?: string | null
  buyerBankAccount?: string | null
  buyerBankName?: string | null
  buyerIdNumber?: string | null
  buyerPassport?: string | null
  buyerBudgetCode?: string | null
  totalSaleAmountOc?: number | null
  totalSaleAmount?: number | null
  totalDiscountAmountOc?: number | null
  totalDiscountAmount?: number | null
  totalAmountWithoutVatOc?: number | null
  totalAmountWithoutVat?: number | null
  totalVatAmountOc?: number | null
  totalVatAmount?: number | null
  totalAmountOc?: number | null
  totalAmount?: number | null
  totalAmountInWords?: string | null
  totalAmountInWordsByEng?: string | null
  totalAmountInWordsUnsignNormalVn?: string | null
  customField1?: string | null
  customField2?: string | null
  customField3?: string | null
  customField4?: string | null
  customField5?: string | null
  customField6?: string | null
  customField7?: string | null
  customField8?: string | null
  customField9?: string | null
  customField10?: string | null
  periodName?: string | null
  periodFromDate?: Date | null
  periodToDate?: Date | null
  newIndex?: number | null
  oldIndex?: number | null
  amountOfConsumption?: number | null
  waterUsed?: number | null
  environment?: number | null
  environmmentFeeAmount?: number | null
  clockInfos?: MeInvoiceClockInfo[] | null
  checkIn?: Date | null
  checkOut?: Date | null
  exciseTaxRate?: number | null
  serviceFeeRate?: number | null
  serviceAmountOc?: number | null
  serviceAmount?: number | null
  exciseTaxAmountOc?: number | null
  exciseTaxAmount?: number | null
  accountObjectIdentificationNumber?: string | null
  referenceType?: number | null
  orgInvoiceType?: number | null
  orgInvTemplateNo?: string | null
  orgInvSeries?: string | null
  orgInvNo?: string | null
  orgInvDate?: string | null
  invoiceNote?: string | null
  stockOutLegalName?: string | null
  stockOutTaxCode?: string | null
  internalCommand?: string | null
  stockOutAddress?: string | null
  transporterName?: string | null
  transport?: string | null
  stockOutFullName?: string | null
  transportContractCode?: string | null
  stockInLegalName?: string | null
  stockInTaxCode?: string | null
  stockInFullName?: string | null
  stockInAddress?: string | null
  contractCode?: string | null
  contractDate?: Date | null
  internalCommandNo?: string | null
  internalCommandOwner?: string | null
  internalCommandDate?: Date | null
  journalMemo?: string | null
  stockTotalAmountOc?: number | null
  stockTotalAmount?: number | null
  originalInvoiceDetail?: MeInvoiceOriginalInvoiceDetail[] | null
  taxRateInfo?: MeInvoiceTaxRateInfo[] | null
  optionUserDefined?: MeInvoiceOptionUserDefined | null
  otherInfo?: MeInvoiceOtherInfo[] | null
  feeInfo?: MeInvoiceFeeInfo[] | null
}

export class MeInvoiceInvoiceData {
  readonly refId: string | null
  readonly invSeries: string | null
  readonly invDate: string | null
  readonly currencyCode: string | null
  readonly exchangeRate: number | null
  readonly paymentMethodName: string | null
  readonly isInvoiceSummary: boolean | null
  readonly isSendEmail: boolean | null
  readonly receiverName: string | null
  readonly receiverEmail: string | null
  readonly sellerShopCode: string | null
  readonly sellerShopName: string | null
  readonly isInvoiceCalculatingMachine: boolean | null
  readonly buyerCode: string | null
  readonly buyerLegalName: string | null
  readonly buyerTaxCode: string | null
  readonly buyerAddress: string | null
  readonly buyerFullName: string | null
  readonly buyerPhoneNumber: string | null
  readonly buyerEmail: string | null
  readonly buyerBankAccount: string | null
  readonly buyerBankName: string | null
  readonly buyerIdNumber: string | null
  readonly buyerPassport: string | null
  readonly buyerBudgetCode: string | null
  readonly totalSaleAmountOc: number | null
  readonly totalSaleAmount: number | null
  readonly totalDiscountAmountOc: number | null
  readonly totalDiscountAmount: number | null
  readonly totalAmountWithoutVatOc: number | null
  readonly totalAmountWithoutVat: number | null
  readonly totalVatAmountOc: number | null
  readonly totalVatAmount: number | null
  readonly totalAmountOc: number | null
  readonly totalAmount: number | null
  readonly totalAmountInWords: string | null
  readonly totalAmountInWordsByEng: string | null
  readonly totalAmountInWordsUnsignNormalVn: string | null
  readonly customField1: string | null
  readonly customField2: string | null
  readonly customField3: string | null
  readonly customField4: string | null
  readonly customField5: string | null
  readonly customField6: string | null
  readonly customField7: string | null
  readonly customField8: string | null
  readonly customField9: string | null
  readonly customField10: string | null
  readonly periodName: string | null
  readonly periodFromDate: Date | null
  readonly periodToDate: Date | null
  readonly newIndex: number | null
  readonly oldIndex: number | null
  readonly amountOfConsumption: number | null
  readonly waterUsed: number | null
  readonly environment: number | null
  readonly environmmentFeeAmount: number | null
  readonly clockInfos: MeInvoiceClockInfo[] | null
  readonly checkIn: Date | null
  readonly checkOut: Date | null
  readonly exciseTaxRate: number | null
  readonly serviceFeeRate: number | null
  readonly serviceAmountOc: number | null
  readonly serviceAmount: number | null
  readonly exciseTaxAmountOc: number | null
  readonly exciseTaxAmount: number | null
  readonly accountObjectIdentificationNumber: string | null
  readonly referenceType: number | null
  readonly orgInvoiceType: number | null
  readonly orgInvTemplateNo: string | null
  readonly orgInvSeries: string | null
  readonly orgInvNo: string | null
  readonly orgInvDate: string | null
  readonly invoiceNote: string | null
  readonly stockOutLegalName: string | null
  readonly stockOutTaxCode: string | null
  readonly internalCommand: string | null
  readonly stockOutAddress: string | null
  readonly transporterName: string | null
  readonly transport: string | null
  readonly stockOutFullName: string | null
  readonly transportContractCode: string | null
  readonly stockInLegalName: string | null
  readonly stockInTaxCode: string | null
  readonly stockInFullName: string | null
  readonly stockInAddress: string | null
  readonly contractCode: string | null
  readonly contractDate: Date | null
  readonly internalCommandNo: string | null
  readonly internalCommandOwner: string | null
  readonly internalCommandDate: Date | null
  readonly journalMemo: string | null
  readonly stockTotalAmountOc: number | null
  readonly stockTotalAmount: number | null
  readonly originalInvoiceDetail: MeInvoiceOriginalInvoiceDetail[] | null
  readonly taxRateInfo: MeInvoiceTaxRateInfo[] | null
  readonly optionUserDefined: MeInvoiceOptionUserDefined | null
  readonly otherInfo: MeInvoiceOtherInfo[] | null
  readonly feeInfo: MeInvoiceFeeInfo[] | null
  constructor(init: MeInvoiceInvoiceDataInit = {}) {
    this.refId = init.refId ?? null
    this.invSeries = init.invSeries ?? null
    this.invDate = init.invDate ?? null
    this.currencyCode = init.currencyCode ?? null
    this.exchangeRate = init.exchangeRate ?? null
    this.paymentMethodName = init.paymentMethodName ?? null
    this.isInvoiceSummary = init.isInvoiceSummary ?? null
    this.isSendEmail = init.isSendEmail ?? null
    this.receiverName = init.receiverName ?? null
    this.receiverEmail = init.receiverEmail ?? null
    this.sellerShopCode = init.sellerShopCode ?? null
    this.sellerShopName = init.sellerShopName ?? null
    this.isInvoiceCalculatingMachine = init.isInvoiceCalculatingMachine ?? null
    this.buyerCode = init.buyerCode ?? null
    this.buyerLegalName = init.buyerLegalName ?? null
    this.buyerTaxCode = init.buyerTaxCode ?? null
    this.buyerAddress = init.buyerAddress ?? null
    this.buyerFullName = init.buyerFullName ?? null
    this.buyerPhoneNumber = init.buyerPhoneNumber ?? null
    this.buyerEmail = init.buyerEmail ?? null
    this.buyerBankAccount = init.buyerBankAccount ?? null
    this.buyerBankName = init.buyerBankName ?? null
    this.buyerIdNumber = init.buyerIdNumber ?? null
    this.buyerPassport = init.buyerPassport ?? null
    this.buyerBudgetCode = init.buyerBudgetCode ?? null
    this.totalSaleAmountOc = init.totalSaleAmountOc ?? null
    this.totalSaleAmount = init.totalSaleAmount ?? null
    this.totalDiscountAmountOc = init.totalDiscountAmountOc ?? null
    this.totalDiscountAmount = init.totalDiscountAmount ?? null
    this.totalAmountWithoutVatOc = init.totalAmountWithoutVatOc ?? null
    this.totalAmountWithoutVat = init.totalAmountWithoutVat ?? null
    this.totalVatAmountOc = init.totalVatAmountOc ?? null
    this.totalVatAmount = init.totalVatAmount ?? null
    this.totalAmountOc = init.totalAmountOc ?? null
    this.totalAmount = init.totalAmount ?? null
    this.totalAmountInWords = init.totalAmountInWords ?? null
    this.totalAmountInWordsByEng = init.totalAmountInWordsByEng ?? null
    this.totalAmountInWordsUnsignNormalVn = init.totalAmountInWordsUnsignNormalVn ?? null
    this.customField1 = init.customField1 ?? null
    this.customField2 = init.customField2 ?? null
    this.customField3 = init.customField3 ?? null
    this.customField4 = init.customField4 ?? null
    this.customField5 = init.customField5 ?? null
    this.customField6 = init.customField6 ?? null
    this.customField7 = init.customField7 ?? null
    this.customField8 = init.customField8 ?? null
    this.customField9 = init.customField9 ?? null
    this.customField10 = init.customField10 ?? null
    this.periodName = init.periodName ?? null
    this.periodFromDate = init.periodFromDate ?? null
    this.periodToDate = init.periodToDate ?? null
    this.newIndex = init.newIndex ?? null
    this.oldIndex = init.oldIndex ?? null
    this.amountOfConsumption = init.amountOfConsumption ?? null
    this.waterUsed = init.waterUsed ?? null
    this.environment = init.environment ?? null
    this.environmmentFeeAmount = init.environmmentFeeAmount ?? null
    this.clockInfos = init.clockInfos ?? null
    this.checkIn = init.checkIn ?? null
    this.checkOut = init.checkOut ?? null
    this.exciseTaxRate = init.exciseTaxRate ?? null
    this.serviceFeeRate = init.serviceFeeRate ?? null
    this.serviceAmountOc = init.serviceAmountOc ?? null
    this.serviceAmount = init.serviceAmount ?? null
    this.exciseTaxAmountOc = init.exciseTaxAmountOc ?? null
    this.exciseTaxAmount = init.exciseTaxAmount ?? null
    this.accountObjectIdentificationNumber = init.accountObjectIdentificationNumber ?? null
    this.referenceType = init.referenceType ?? null
    this.orgInvoiceType = init.orgInvoiceType ?? null
    this.orgInvTemplateNo = init.orgInvTemplateNo ?? null
    this.orgInvSeries = init.orgInvSeries ?? null
    this.orgInvNo = init.orgInvNo ?? null
    this.orgInvDate = init.orgInvDate ?? null
    this.invoiceNote = init.invoiceNote ?? null
    this.stockOutLegalName = init.stockOutLegalName ?? null
    this.stockOutTaxCode = init.stockOutTaxCode ?? null
    this.internalCommand = init.internalCommand ?? null
    this.stockOutAddress = init.stockOutAddress ?? null
    this.transporterName = init.transporterName ?? null
    this.transport = init.transport ?? null
    this.stockOutFullName = init.stockOutFullName ?? null
    this.transportContractCode = init.transportContractCode ?? null
    this.stockInLegalName = init.stockInLegalName ?? null
    this.stockInTaxCode = init.stockInTaxCode ?? null
    this.stockInFullName = init.stockInFullName ?? null
    this.stockInAddress = init.stockInAddress ?? null
    this.contractCode = init.contractCode ?? null
    this.contractDate = init.contractDate ?? null
    this.internalCommandNo = init.internalCommandNo ?? null
    this.internalCommandOwner = init.internalCommandOwner ?? null
    this.internalCommandDate = init.internalCommandDate ?? null
    this.journalMemo = init.journalMemo ?? null
    this.stockTotalAmountOc = init.stockTotalAmountOc ?? null
    this.stockTotalAmount = init.stockTotalAmount ?? null
    this.originalInvoiceDetail = init.originalInvoiceDetail ?? null
    this.taxRateInfo = init.taxRateInfo ?? null
    this.optionUserDefined = init.optionUserDefined ?? null
    this.otherInfo = init.otherInfo ?? null
    this.feeInfo = init.feeInfo ?? null
  }

  static fromJson(json: Record<string, unknown>): MeInvoiceInvoiceData {
    return new MeInvoiceInvoiceData({
      refId: J.readString(json, 'RefID'),
      invSeries: J.readString(json, 'InvSeries'),
      invDate: J.readString(json, 'InvDate'),
      currencyCode: J.readString(json, 'CurrencyCode'),
      exchangeRate: J.readDouble(json, 'ExchangeRate'),
      paymentMethodName: J.readString(json, 'PaymentMethodName'),
      isInvoiceSummary: J.readBool(json, 'IsInvoiceSummary'),
      isSendEmail: J.readBool(json, 'IsSendEmail'),
      receiverName: J.readString(json, 'ReceiverName'),
      receiverEmail: J.readString(json, 'ReceiverEmail'),
      sellerShopCode: J.readString(json, 'SellerShopCode'),
      sellerShopName: J.readString(json, 'SellerShopName'),
      isInvoiceCalculatingMachine: J.readBool(json, 'IsInvoiceCalculatingMachine'),
      buyerCode: J.readString(json, 'BuyerCode'),
      buyerLegalName: J.readString(json, 'BuyerLegalName'),
      buyerTaxCode: J.readString(json, 'BuyerTaxCode'),
      buyerAddress: J.readString(json, 'BuyerAddress'),
      buyerFullName: J.readString(json, 'BuyerFullName'),
      buyerPhoneNumber: J.readString(json, 'BuyerPhoneNumber'),
      buyerEmail: J.readString(json, 'BuyerEmail'),
      buyerBankAccount: J.readString(json, 'BuyerBankAccount'),
      buyerBankName: J.readString(json, 'BuyerBankName'),
      buyerIdNumber: J.readString(json, 'BuyerIDNumber'),
      buyerPassport: J.readString(json, 'BuyerPassport'),
      buyerBudgetCode: J.readString(json, 'BuyerBudgetCode'),
      totalSaleAmountOc: J.readDouble(json, 'TotalSaleAmountOC'),
      totalSaleAmount: J.readDouble(json, 'TotalSaleAmount'),
      totalDiscountAmountOc: J.readDouble(json, 'TotalDiscountAmountOC'),
      totalDiscountAmount: J.readDouble(json, 'TotalDiscountAmount'),
      totalAmountWithoutVatOc: J.readDouble(json, 'TotalAmountWithoutVATOC'),
      totalAmountWithoutVat: J.readDouble(json, 'TotalAmountWithoutVAT'),
      totalVatAmountOc: J.readDouble(json, 'TotalVATAmountOC'),
      totalVatAmount: J.readDouble(json, 'TotalVATAmount'),
      totalAmountOc: J.readDouble(json, 'TotalAmountOC'),
      totalAmount: J.readDouble(json, 'TotalAmount'),
      totalAmountInWords: J.readString(json, 'TotalAmountInWords'),
      totalAmountInWordsByEng: J.readString(json, 'TotalAmountInWordsByENG'),
      totalAmountInWordsUnsignNormalVn: J.readString(json, 'TotalAmountInWordsUnsignNormalVN'),
      customField1: J.readString(json, 'CustomField1'),
      customField2: J.readString(json, 'CustomField2'),
      customField3: J.readString(json, 'CustomField3'),
      customField4: J.readString(json, 'CustomField4'),
      customField5: J.readString(json, 'CustomField5'),
      customField6: J.readString(json, 'CustomField6'),
      customField7: J.readString(json, 'CustomField7'),
      customField8: J.readString(json, 'CustomField8'),
      customField9: J.readString(json, 'CustomField9'),
      customField10: J.readString(json, 'CustomField10'),
      periodName: J.readString(json, 'PeriodName'),
      periodFromDate: J.readDateTime(json, 'PeriodFromDate'),
      periodToDate: J.readDateTime(json, 'PeriodToDate'),
      newIndex: J.readDouble(json, 'NewIndex'),
      oldIndex: J.readDouble(json, 'OldIndex'),
      amountOfConsumption: J.readDouble(json, 'AmountOfConsumption'),
      waterUsed: J.readDouble(json, 'WaterUsed'),
      environment: J.readDouble(json, 'Environment'),
      environmmentFeeAmount: J.readDouble(json, 'EnvironmmentFeeAmount'),
      clockInfos: parseList(json['ClockInfos'], MeInvoiceClockInfo.fromJson),
      checkIn: J.readDateTime(json, 'CheckIn'),
      checkOut: J.readDateTime(json, 'CheckOut'),
      exciseTaxRate: J.readDouble(json, 'ExciseTaxRate'),
      serviceFeeRate: J.readDouble(json, 'ServiceFeeRate'),
      serviceAmountOc: J.readDouble(json, 'ServiceAmountOC'),
      serviceAmount: J.readDouble(json, 'ServiceAmount'),
      exciseTaxAmountOc: J.readDouble(json, 'ExciseTaxAmountOC'),
      exciseTaxAmount: J.readDouble(json, 'ExciseTaxAmount'),
      accountObjectIdentificationNumber: J.readString(json, 'AccountObjectIdentificationNumber'),
      referenceType: J.readInt(json, 'ReferenceType'),
      orgInvoiceType: J.readInt(json, 'OrgInvoiceType'),
      orgInvTemplateNo: J.readString(json, 'OrgInvTemplateNo'),
      orgInvSeries: J.readString(json, 'OrgInvSeries'),
      orgInvNo: J.readString(json, 'OrgInvNo'),
      orgInvDate: J.readString(json, 'OrgInvDate'),
      invoiceNote: J.readString(json, 'InvoiceNote'),
      stockOutLegalName: J.readString(json, 'StockOutLegalName'),
      stockOutTaxCode: J.readString(json, 'StockOutTaxCode'),
      internalCommand: J.readString(json, 'InternalCommand'),
      stockOutAddress: J.readString(json, 'StockOutAddress'),
      transporterName: J.readString(json, 'TransporterName'),
      transport: J.readString(json, 'Transport'),
      stockOutFullName: J.readString(json, 'StockOutFullName'),
      transportContractCode: J.readString(json, 'TransportContractCode'),
      stockInLegalName: J.readString(json, 'StockInLegalName'),
      stockInTaxCode: J.readString(json, 'StockInTaxCode'),
      stockInFullName: J.readString(json, 'StockInFullName'),
      stockInAddress: J.readString(json, 'StockInAddress'),
      contractCode: J.readString(json, 'ContractCode'),
      contractDate: J.readDateTime(json, 'ContractDate'),
      internalCommandNo: J.readString(json, 'InternalCommandNo'),
      internalCommandOwner: J.readString(json, 'InternalCommandOwner'),
      internalCommandDate: J.readDateTime(json, 'InternalCommandDate'),
      journalMemo: J.readString(json, 'JournalMemo'),
      stockTotalAmountOc: J.readDouble(json, 'StockTotalAmountOC'),
      stockTotalAmount: J.readDouble(json, 'StockTotalAmount'),
      originalInvoiceDetail: parseList(json['OriginalInvoiceDetail'], MeInvoiceOriginalInvoiceDetail.fromJson),
      taxRateInfo: parseList(json['TaxRateInfo'], MeInvoiceTaxRateInfo.fromJson),
      optionUserDefined: (() => { const m = J.asMap(json['OptionUserDefined']); return m === null ? null : MeInvoiceOptionUserDefined.fromJson(m) })(),
      otherInfo: parseList(json['OtherInfo'], MeInvoiceOtherInfo.fromJson),
      feeInfo: parseList(json['FeeInfo'], MeInvoiceFeeInfo.fromJson),
    })
  }

  toJson(): Record<string, unknown> {
    const map: Record<string, unknown> = {}
    J.writeIfPresent(map, 'RefID', this.refId)
    J.writeIfPresent(map, 'InvSeries', this.invSeries)
    J.writeIfPresent(map, 'InvDate', this.invDate)
    J.writeIfPresent(map, 'CurrencyCode', this.currencyCode)
    J.writeIfPresent(map, 'ExchangeRate', this.exchangeRate)
    J.writeIfPresent(map, 'PaymentMethodName', this.paymentMethodName)
    J.writeIfPresent(map, 'IsInvoiceSummary', this.isInvoiceSummary)
    J.writeIfPresent(map, 'IsSendEmail', this.isSendEmail)
    J.writeIfPresent(map, 'ReceiverName', this.receiverName)
    J.writeIfPresent(map, 'ReceiverEmail', this.receiverEmail)
    J.writeIfPresent(map, 'SellerShopCode', this.sellerShopCode)
    J.writeIfPresent(map, 'SellerShopName', this.sellerShopName)
    J.writeIfPresent(map, 'IsInvoiceCalculatingMachine', this.isInvoiceCalculatingMachine)
    J.writeIfPresent(map, 'BuyerCode', this.buyerCode)
    J.writeIfPresent(map, 'BuyerLegalName', this.buyerLegalName)
    J.writeIfPresent(map, 'BuyerTaxCode', this.buyerTaxCode)
    J.writeIfPresent(map, 'BuyerAddress', this.buyerAddress)
    J.writeIfPresent(map, 'BuyerFullName', this.buyerFullName)
    J.writeIfPresent(map, 'BuyerPhoneNumber', this.buyerPhoneNumber)
    J.writeIfPresent(map, 'BuyerEmail', this.buyerEmail)
    J.writeIfPresent(map, 'BuyerBankAccount', this.buyerBankAccount)
    J.writeIfPresent(map, 'BuyerBankName', this.buyerBankName)
    J.writeIfPresent(map, 'BuyerIDNumber', this.buyerIdNumber)
    J.writeIfPresent(map, 'BuyerPassport', this.buyerPassport)
    J.writeIfPresent(map, 'BuyerBudgetCode', this.buyerBudgetCode)
    J.writeIfPresent(map, 'TotalSaleAmountOC', this.totalSaleAmountOc)
    J.writeIfPresent(map, 'TotalSaleAmount', this.totalSaleAmount)
    J.writeIfPresent(map, 'TotalDiscountAmountOC', this.totalDiscountAmountOc)
    J.writeIfPresent(map, 'TotalDiscountAmount', this.totalDiscountAmount)
    J.writeIfPresent(map, 'TotalAmountWithoutVATOC', this.totalAmountWithoutVatOc)
    J.writeIfPresent(map, 'TotalAmountWithoutVAT', this.totalAmountWithoutVat)
    J.writeIfPresent(map, 'TotalVATAmountOC', this.totalVatAmountOc)
    J.writeIfPresent(map, 'TotalVATAmount', this.totalVatAmount)
    J.writeIfPresent(map, 'TotalAmountOC', this.totalAmountOc)
    J.writeIfPresent(map, 'TotalAmount', this.totalAmount)
    J.writeIfPresent(map, 'TotalAmountInWords', this.totalAmountInWords)
    J.writeIfPresent(map, 'TotalAmountInWordsByENG', this.totalAmountInWordsByEng)
    J.writeIfPresent(map, 'TotalAmountInWordsUnsignNormalVN', this.totalAmountInWordsUnsignNormalVn)
    J.writeIfPresent(map, 'CustomField1', this.customField1)
    J.writeIfPresent(map, 'CustomField2', this.customField2)
    J.writeIfPresent(map, 'CustomField3', this.customField3)
    J.writeIfPresent(map, 'CustomField4', this.customField4)
    J.writeIfPresent(map, 'CustomField5', this.customField5)
    J.writeIfPresent(map, 'CustomField6', this.customField6)
    J.writeIfPresent(map, 'CustomField7', this.customField7)
    J.writeIfPresent(map, 'CustomField8', this.customField8)
    J.writeIfPresent(map, 'CustomField9', this.customField9)
    J.writeIfPresent(map, 'CustomField10', this.customField10)
    J.writeIfPresent(map, 'PeriodName', this.periodName)
    J.writeIfPresent(map, 'PeriodFromDate', this.periodFromDate?.toISOString())
    J.writeIfPresent(map, 'PeriodToDate', this.periodToDate?.toISOString())
    J.writeIfPresent(map, 'NewIndex', this.newIndex)
    J.writeIfPresent(map, 'OldIndex', this.oldIndex)
    J.writeIfPresent(map, 'AmountOfConsumption', this.amountOfConsumption)
    J.writeIfPresent(map, 'WaterUsed', this.waterUsed)
    J.writeIfPresent(map, 'Environment', this.environment)
    J.writeIfPresent(map, 'EnvironmmentFeeAmount', this.environmmentFeeAmount)
    J.writeIfPresent(map, 'CheckIn', this.checkIn?.toISOString())
    J.writeIfPresent(map, 'CheckOut', this.checkOut?.toISOString())
    J.writeIfPresent(map, 'ExciseTaxRate', this.exciseTaxRate)
    J.writeIfPresent(map, 'ServiceFeeRate', this.serviceFeeRate)
    J.writeIfPresent(map, 'ServiceAmountOC', this.serviceAmountOc)
    J.writeIfPresent(map, 'ServiceAmount', this.serviceAmount)
    J.writeIfPresent(map, 'ExciseTaxAmountOC', this.exciseTaxAmountOc)
    J.writeIfPresent(map, 'ExciseTaxAmount', this.exciseTaxAmount)
    J.writeIfPresent(map, 'AccountObjectIdentificationNumber', this.accountObjectIdentificationNumber)
    J.writeIfPresent(map, 'ReferenceType', this.referenceType)
    J.writeIfPresent(map, 'OrgInvoiceType', this.orgInvoiceType)
    J.writeIfPresent(map, 'OrgInvTemplateNo', this.orgInvTemplateNo)
    J.writeIfPresent(map, 'OrgInvSeries', this.orgInvSeries)
    J.writeIfPresent(map, 'OrgInvNo', this.orgInvNo)
    J.writeIfPresent(map, 'OrgInvDate', this.orgInvDate)
    J.writeIfPresent(map, 'InvoiceNote', this.invoiceNote)
    J.writeIfPresent(map, 'StockOutLegalName', this.stockOutLegalName)
    J.writeIfPresent(map, 'StockOutTaxCode', this.stockOutTaxCode)
    J.writeIfPresent(map, 'InternalCommand', this.internalCommand)
    J.writeIfPresent(map, 'StockOutAddress', this.stockOutAddress)
    J.writeIfPresent(map, 'TransporterName', this.transporterName)
    J.writeIfPresent(map, 'Transport', this.transport)
    J.writeIfPresent(map, 'StockOutFullName', this.stockOutFullName)
    J.writeIfPresent(map, 'TransportContractCode', this.transportContractCode)
    J.writeIfPresent(map, 'StockInLegalName', this.stockInLegalName)
    J.writeIfPresent(map, 'StockInTaxCode', this.stockInTaxCode)
    J.writeIfPresent(map, 'StockInFullName', this.stockInFullName)
    J.writeIfPresent(map, 'StockInAddress', this.stockInAddress)
    J.writeIfPresent(map, 'ContractCode', this.contractCode)
    J.writeIfPresent(map, 'ContractDate', this.contractDate?.toISOString())
    J.writeIfPresent(map, 'InternalCommandNo', this.internalCommandNo)
    J.writeIfPresent(map, 'InternalCommandOwner', this.internalCommandOwner)
    J.writeIfPresent(map, 'InternalCommandDate', this.internalCommandDate?.toISOString())
    J.writeIfPresent(map, 'JournalMemo', this.journalMemo)
    J.writeIfPresent(map, 'StockTotalAmountOC', this.stockTotalAmountOc)
    J.writeIfPresent(map, 'StockTotalAmount', this.stockTotalAmount)
    if (this.clockInfos !== null && this.clockInfos.length > 0) map['ClockInfos'] = this.clockInfos.map((e) => e.toJson())
    if (this.originalInvoiceDetail !== null && this.originalInvoiceDetail.length > 0) map['OriginalInvoiceDetail'] = this.originalInvoiceDetail.map((e) => e.toJson())
    if (this.taxRateInfo !== null && this.taxRateInfo.length > 0) map['TaxRateInfo'] = this.taxRateInfo.map((e) => e.toJson())
    if (this.optionUserDefined !== null) map['OptionUserDefined'] = this.optionUserDefined.toJson()
    if (this.otherInfo !== null && this.otherInfo.length > 0) map['OtherInfo'] = this.otherInfo.map((e) => e.toJson())
    if (this.feeInfo !== null && this.feeInfo.length > 0) map['FeeInfo'] = this.feeInfo.map((e) => e.toJson())
    return map
  }
}

function parseList<T>(raw: unknown, fromJson: (m: Record<string, unknown>) => T): T[] | null {
  const list = J.asList(raw)
  if (list.length === 0) return null
  const out: T[] = []
  for (const item of list) {
    const m = J.asMap(item)
    if (m !== null) out.push(fromJson(m))
  }
  return out
}
