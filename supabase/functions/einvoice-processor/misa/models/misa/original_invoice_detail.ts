import { MeInvoiceJsonHelpers as J } from '../../internal/json_helpers.ts'

export interface MeInvoiceOriginalInvoiceDetailInit {
  itemType?: number | null
  sortOrder?: number | null
  lineNumber?: number | null
  itemCode?: string | null
  itemName?: string | null
  unitName?: string | null
  expiryDate?: Date | null
  chassisNumber?: string | null
  engineNumber?: string | null
  lotNo?: string | null
  quantity?: number | null
  unitPrice?: number | null
  amountOc?: number | null
  amount?: number | null
  discountRate?: number | null
  discountAmountOc?: number | null
  discountAmount?: number | null
  amountWithoutVatOc?: number | null
  amountWithoutVat?: number | null
  vatRateName?: string | null
  vatAmountOc?: number | null
  vatAmount?: number | null
  wageAmount?: number | null
  wageAmountOc?: number | null
  wagePriceAmount?: number | null
  wagePriceDiscountAmount?: number | null
  wageDiscountAmountOc?: number | null
  inWard?: number | null
  exciseTaxAmountOc?: number | null
  exciseTaxAmount?: number | null
  exciseTaxRate?: number | null
  unitPriceAfterExciseVat?: number | null
  amountAfterExciseTaxOc?: number | null
  amountAfterExciseTax?: number | null
  serviceAmountOc?: number | null
  serviceAmount?: number | null
  serviceFeeRate?: number | null
  typicalItem?: number | null
  fieldName?: string | null
  fieldValue?: string | null
}

export class MeInvoiceOriginalInvoiceDetail {
  readonly itemType: number | null
  readonly sortOrder: number | null
  readonly lineNumber: number | null
  readonly itemCode: string | null
  readonly itemName: string | null
  readonly unitName: string | null
  readonly expiryDate: Date | null
  readonly chassisNumber: string | null
  readonly engineNumber: string | null
  readonly lotNo: string | null
  readonly quantity: number | null
  readonly unitPrice: number | null
  readonly amountOc: number | null
  readonly amount: number | null
  readonly discountRate: number | null
  readonly discountAmountOc: number | null
  readonly discountAmount: number | null
  readonly amountWithoutVatOc: number | null
  readonly amountWithoutVat: number | null
  readonly vatRateName: string | null
  readonly vatAmountOc: number | null
  readonly vatAmount: number | null
  readonly wageAmount: number | null
  readonly wageAmountOc: number | null
  readonly wagePriceAmount: number | null
  readonly wagePriceDiscountAmount: number | null
  readonly wageDiscountAmountOc: number | null
  readonly inWard: number | null
  readonly exciseTaxAmountOc: number | null
  readonly exciseTaxAmount: number | null
  readonly exciseTaxRate: number | null
  readonly unitPriceAfterExciseVat: number | null
  readonly amountAfterExciseTaxOc: number | null
  readonly amountAfterExciseTax: number | null
  readonly serviceAmountOc: number | null
  readonly serviceAmount: number | null
  readonly serviceFeeRate: number | null
  readonly typicalItem: number | null
  readonly fieldName: string | null
  readonly fieldValue: string | null
  constructor(init: MeInvoiceOriginalInvoiceDetailInit = {}) {
    this.itemType = init.itemType ?? null
    this.sortOrder = init.sortOrder ?? null
    this.lineNumber = init.lineNumber ?? null
    this.itemCode = init.itemCode ?? null
    this.itemName = init.itemName ?? null
    this.unitName = init.unitName ?? null
    this.expiryDate = init.expiryDate ?? null
    this.chassisNumber = init.chassisNumber ?? null
    this.engineNumber = init.engineNumber ?? null
    this.lotNo = init.lotNo ?? null
    this.quantity = init.quantity ?? null
    this.unitPrice = init.unitPrice ?? null
    this.amountOc = init.amountOc ?? null
    this.amount = init.amount ?? null
    this.discountRate = init.discountRate ?? null
    this.discountAmountOc = init.discountAmountOc ?? null
    this.discountAmount = init.discountAmount ?? null
    this.amountWithoutVatOc = init.amountWithoutVatOc ?? null
    this.amountWithoutVat = init.amountWithoutVat ?? null
    this.vatRateName = init.vatRateName ?? null
    this.vatAmountOc = init.vatAmountOc ?? null
    this.vatAmount = init.vatAmount ?? null
    this.wageAmount = init.wageAmount ?? null
    this.wageAmountOc = init.wageAmountOc ?? null
    this.wagePriceAmount = init.wagePriceAmount ?? null
    this.wagePriceDiscountAmount = init.wagePriceDiscountAmount ?? null
    this.wageDiscountAmountOc = init.wageDiscountAmountOc ?? null
    this.inWard = init.inWard ?? null
    this.exciseTaxAmountOc = init.exciseTaxAmountOc ?? null
    this.exciseTaxAmount = init.exciseTaxAmount ?? null
    this.exciseTaxRate = init.exciseTaxRate ?? null
    this.unitPriceAfterExciseVat = init.unitPriceAfterExciseVat ?? null
    this.amountAfterExciseTaxOc = init.amountAfterExciseTaxOc ?? null
    this.amountAfterExciseTax = init.amountAfterExciseTax ?? null
    this.serviceAmountOc = init.serviceAmountOc ?? null
    this.serviceAmount = init.serviceAmount ?? null
    this.serviceFeeRate = init.serviceFeeRate ?? null
    this.typicalItem = init.typicalItem ?? null
    this.fieldName = init.fieldName ?? null
    this.fieldValue = init.fieldValue ?? null
  }

  static fromJson(json: Record<string, unknown>): MeInvoiceOriginalInvoiceDetail {
    return new MeInvoiceOriginalInvoiceDetail({
      itemType: J.readInt(json, 'ItemType'),
      sortOrder: J.readInt(json, 'SortOrder'),
      lineNumber: J.readInt(json, 'LineNumber'),
      itemCode: J.readString(json, 'ItemCode'),
      itemName: J.readString(json, 'ItemName'),
      unitName: J.readString(json, 'UnitName'),
      expiryDate: J.readDateTime(json, 'ExpiryDate'),
      chassisNumber: J.readString(json, 'ChassisNumber'),
      engineNumber: J.readString(json, 'EngineNumber'),
      lotNo: J.readString(json, 'LotNo'),
      quantity: J.readDouble(json, 'Quantity'),
      unitPrice: J.readDouble(json, 'UnitPrice'),
      amountOc: J.readDouble(json, 'AmountOC'),
      amount: J.readDouble(json, 'Amount'),
      discountRate: J.readDouble(json, 'DiscountRate'),
      discountAmountOc: J.readDouble(json, 'DiscountAmountOC'),
      discountAmount: J.readDouble(json, 'DiscountAmount'),
      amountWithoutVatOc: J.readDouble(json, 'AmountWithoutVATOC'),
      amountWithoutVat: J.readDouble(json, 'AmountWithoutVAT'),
      vatRateName: J.readString(json, 'VATRateName'),
      vatAmountOc: J.readDouble(json, 'VATAmountOC'),
      vatAmount: J.readDouble(json, 'VATAmount'),
      wageAmount: J.readDouble(json, 'WageAmount'),
      wageAmountOc: J.readDouble(json, 'WageAmountOC'),
      wagePriceAmount: J.readDouble(json, 'WagePriceAmount'),
      wagePriceDiscountAmount: J.readDouble(json, 'WagePriceDiscountAmount'),
      wageDiscountAmountOc: J.readDouble(json, 'WageDiscountAmountOC'),
      inWard: J.readDouble(json, 'InWard'),
      exciseTaxAmountOc: J.readDouble(json, 'ExciseTaxAmountOC'),
      exciseTaxAmount: J.readDouble(json, 'ExciseTaxAmount'),
      exciseTaxRate: J.readDouble(json, 'ExciseTaxRate'),
      unitPriceAfterExciseVat: J.readDouble(json, 'UnitPriceAfterExciseVAT'),
      amountAfterExciseTaxOc: J.readDouble(json, 'AmountAfterExciseTaxOC'),
      amountAfterExciseTax: J.readDouble(json, 'AmountAfterExciseTax'),
      serviceAmountOc: J.readDouble(json, 'ServiceAmountOC'),
      serviceAmount: J.readDouble(json, 'ServiceAmount'),
      serviceFeeRate: J.readDouble(json, 'ServiceFeeRate'),
      typicalItem: J.readInt(json, 'TypicalItem'),
      fieldName: J.readString(json, 'FieldName'),
      fieldValue: J.readString(json, 'FieldValue'),
    })
  }

  toJson(): Record<string, unknown> {
    const map: Record<string, unknown> = {}
    J.writeIfPresent(map, 'ItemType', this.itemType)
    J.writeIfPresent(map, 'SortOrder', this.sortOrder)
    J.writeIfPresent(map, 'LineNumber', this.lineNumber)
    J.writeIfPresent(map, 'ItemCode', this.itemCode)
    J.writeIfPresent(map, 'ItemName', this.itemName)
    J.writeIfPresent(map, 'UnitName', this.unitName)
    J.writeIfPresent(map, 'ExpiryDate', this.expiryDate?.toISOString())
    J.writeIfPresent(map, 'ChassisNumber', this.chassisNumber)
    J.writeIfPresent(map, 'EngineNumber', this.engineNumber)
    J.writeIfPresent(map, 'LotNo', this.lotNo)
    J.writeIfPresent(map, 'Quantity', this.quantity)
    J.writeIfPresent(map, 'UnitPrice', this.unitPrice)
    J.writeIfPresent(map, 'AmountOC', this.amountOc)
    J.writeIfPresent(map, 'Amount', this.amount)
    J.writeIfPresent(map, 'DiscountRate', this.discountRate)
    J.writeIfPresent(map, 'DiscountAmountOC', this.discountAmountOc)
    J.writeIfPresent(map, 'DiscountAmount', this.discountAmount)
    J.writeIfPresent(map, 'AmountWithoutVATOC', this.amountWithoutVatOc)
    J.writeIfPresent(map, 'AmountWithoutVAT', this.amountWithoutVat)
    J.writeIfPresent(map, 'VATRateName', this.vatRateName)
    J.writeIfPresent(map, 'VATAmountOC', this.vatAmountOc)
    J.writeIfPresent(map, 'VATAmount', this.vatAmount)
    J.writeIfPresent(map, 'WageAmount', this.wageAmount)
    J.writeIfPresent(map, 'WageAmountOC', this.wageAmountOc)
    J.writeIfPresent(map, 'WagePriceAmount', this.wagePriceAmount)
    J.writeIfPresent(map, 'WagePriceDiscountAmount', this.wagePriceDiscountAmount)
    J.writeIfPresent(map, 'WageDiscountAmountOC', this.wageDiscountAmountOc)
    J.writeIfPresent(map, 'InWard', this.inWard)
    J.writeIfPresent(map, 'ExciseTaxAmountOC', this.exciseTaxAmountOc)
    J.writeIfPresent(map, 'ExciseTaxAmount', this.exciseTaxAmount)
    J.writeIfPresent(map, 'ExciseTaxRate', this.exciseTaxRate)
    J.writeIfPresent(map, 'UnitPriceAfterExciseVAT', this.unitPriceAfterExciseVat)
    J.writeIfPresent(map, 'AmountAfterExciseTaxOC', this.amountAfterExciseTaxOc)
    J.writeIfPresent(map, 'AmountAfterExciseTax', this.amountAfterExciseTax)
    J.writeIfPresent(map, 'ServiceAmountOC', this.serviceAmountOc)
    J.writeIfPresent(map, 'ServiceAmount', this.serviceAmount)
    J.writeIfPresent(map, 'ServiceFeeRate', this.serviceFeeRate)
    J.writeIfPresent(map, 'TypicalItem', this.typicalItem)
    J.writeIfPresent(map, 'FieldName', this.fieldName)
    J.writeIfPresent(map, 'FieldValue', this.fieldValue)
    return map
  }
}
