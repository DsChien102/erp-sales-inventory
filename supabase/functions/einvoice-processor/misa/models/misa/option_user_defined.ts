import { MeInvoiceJsonHelpers as J } from '../../internal/json_helpers.ts'

export interface MeInvoiceOptionUserDefinedInit {
  mainCurrency?: string | null
  quantityDecimalDigits?: string | null
  unitPriceOcDecimalDigits?: string | null
  unitPriceDecimalDigits?: string | null
  amountOcDecimalDigits?: string | null
  amountDecimalDigits?: string | null
  coefficientDecimalDigits?: string | null
  exchangRateDecimalDigits?: string | null
}

export class MeInvoiceOptionUserDefined {
  readonly mainCurrency: string | null
  readonly quantityDecimalDigits: string | null
  readonly unitPriceOcDecimalDigits: string | null
  readonly unitPriceDecimalDigits: string | null
  readonly amountOcDecimalDigits: string | null
  readonly amountDecimalDigits: string | null
  readonly coefficientDecimalDigits: string | null
  readonly exchangRateDecimalDigits: string | null
  constructor(init: MeInvoiceOptionUserDefinedInit = {}) {
    this.mainCurrency = init.mainCurrency ?? null
    this.quantityDecimalDigits = init.quantityDecimalDigits ?? null
    this.unitPriceOcDecimalDigits = init.unitPriceOcDecimalDigits ?? null
    this.unitPriceDecimalDigits = init.unitPriceDecimalDigits ?? null
    this.amountOcDecimalDigits = init.amountOcDecimalDigits ?? null
    this.amountDecimalDigits = init.amountDecimalDigits ?? null
    this.coefficientDecimalDigits = init.coefficientDecimalDigits ?? null
    this.exchangRateDecimalDigits = init.exchangRateDecimalDigits ?? null
  }

  static fromJson(json: Record<string, unknown>): MeInvoiceOptionUserDefined {
    return new MeInvoiceOptionUserDefined({
      mainCurrency: J.readString(json, 'MainCurrency'),
      quantityDecimalDigits: J.readString(json, 'QuantityDecimalDigits'),
      unitPriceOcDecimalDigits: J.readString(json, 'UnitPriceOCDecimalDigits'),
      unitPriceDecimalDigits: J.readString(json, 'UnitPriceDecimalDigits'),
      amountOcDecimalDigits: J.readString(json, 'AmountOCDecimalDigits'),
      amountDecimalDigits: J.readString(json, 'AmountDecimalDigits'),
      coefficientDecimalDigits: J.readString(json, 'CoefficientDecimalDigits'),
      exchangRateDecimalDigits: J.readString(json, 'ExchangRateDecimalDigits'),
    })
  }

  toJson(): Record<string, unknown> {
    const map: Record<string, unknown> = {}
    J.writeIfPresent(map, 'MainCurrency', this.mainCurrency)
    J.writeIfPresent(map, 'QuantityDecimalDigits', this.quantityDecimalDigits)
    J.writeIfPresent(map, 'UnitPriceOCDecimalDigits', this.unitPriceOcDecimalDigits)
    J.writeIfPresent(map, 'UnitPriceDecimalDigits', this.unitPriceDecimalDigits)
    J.writeIfPresent(map, 'AmountOCDecimalDigits', this.amountOcDecimalDigits)
    J.writeIfPresent(map, 'AmountDecimalDigits', this.amountDecimalDigits)
    J.writeIfPresent(map, 'CoefficientDecimalDigits', this.coefficientDecimalDigits)
    J.writeIfPresent(map, 'ExchangRateDecimalDigits', this.exchangRateDecimalDigits)
    return map
  }
}
