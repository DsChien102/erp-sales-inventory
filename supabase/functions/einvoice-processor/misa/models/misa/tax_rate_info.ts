import { MeInvoiceJsonHelpers as J } from '../../internal/json_helpers.ts'

export interface MeInvoiceTaxRateInfoInit {
  vatRateName?: string | null
  amountWithoutVatOc?: number | null
  vatAmountOc?: number | null
}

export class MeInvoiceTaxRateInfo {
  readonly vatRateName: string | null
  readonly amountWithoutVatOc: number | null
  readonly vatAmountOc: number | null
  constructor(init: MeInvoiceTaxRateInfoInit = {}) {
    this.vatRateName = init.vatRateName ?? null
    this.amountWithoutVatOc = init.amountWithoutVatOc ?? null
    this.vatAmountOc = init.vatAmountOc ?? null
  }

  static fromJson(json: Record<string, unknown>): MeInvoiceTaxRateInfo {
    return new MeInvoiceTaxRateInfo({
      vatRateName: J.readString(json, 'VATRateName'),
      amountWithoutVatOc: J.readDouble(json, 'AmountWithoutVATOC'),
      vatAmountOc: J.readDouble(json, 'VATAmountOC'),
    })
  }

  toJson(): Record<string, unknown> {
    const map: Record<string, unknown> = {}
    J.writeIfPresent(map, 'VATRateName', this.vatRateName)
    J.writeIfPresent(map, 'AmountWithoutVATOC', this.amountWithoutVatOc)
    J.writeIfPresent(map, 'VATAmountOC', this.vatAmountOc)
    return map
  }
}
