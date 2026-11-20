import { MeInvoiceJsonHelpers as J } from '../../internal/json_helpers.ts'

export interface MeInvoiceFeeInfoInit {
  feeName?: string | null
  feeAmountOc?: number | null
}

export class MeInvoiceFeeInfo {
  readonly feeName: string | null
  readonly feeAmountOc: number | null
  constructor(init: MeInvoiceFeeInfoInit = {}) {
    this.feeName = init.feeName ?? null
    this.feeAmountOc = init.feeAmountOc ?? null
  }

  static fromJson(json: Record<string, unknown>): MeInvoiceFeeInfo {
    return new MeInvoiceFeeInfo({
      feeName: J.readString(json, 'FeeName'),
      feeAmountOc: J.readDouble(json, 'FeeAmountOC'),
    })
  }

  toJson(): Record<string, unknown> {
    const map: Record<string, unknown> = {}
    J.writeIfPresent(map, 'FeeName', this.feeName)
    J.writeIfPresent(map, 'FeeAmountOC', this.feeAmountOc)
    return map
  }
}
