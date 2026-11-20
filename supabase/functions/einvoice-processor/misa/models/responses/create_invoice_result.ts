import { MeInvoiceJsonHelpers as J } from '../../internal/json_helpers.ts'

/** One item in `createInvoiceResult[]` (§5.1 USB/XML flow). */
export class MeInvoiceCreateInvoiceResultItem {
  constructor(
    readonly init: {
      refId?: string | null
      transactionId?: string | null
      invSeries?: string | null
      invoiceData?: string | null
      errorCode?: string | null
      descriptionErrorCode?: string | null
    } = {},
  ) {}
  get refId(): string | null { return this.init.refId ?? null }
  get transactionId(): string | null { return this.init.transactionId ?? null }
  get invSeries(): string | null { return this.init.invSeries ?? null }
  get invoiceData(): string | null { return this.init.invoiceData ?? null }
  get errorCode(): string | null { return this.init.errorCode ?? null }
  get descriptionErrorCode(): string | null { return this.init.descriptionErrorCode ?? null }

  get isSuccess(): boolean {
    return this.errorCode === null || this.errorCode === ''
  }

  static fromJson(json: Record<string, unknown>): MeInvoiceCreateInvoiceResultItem {
    return new MeInvoiceCreateInvoiceResultItem({
      refId: J.readString(json, 'RefID'),
      transactionId: J.readString(json, 'TransactionID'),
      invSeries: J.readString(json, 'InvSeries'),
      invoiceData: J.readString(json, 'InvoiceData'),
      errorCode: J.readString(json, 'ErrorCode'),
      descriptionErrorCode: J.readString(json, 'DescriptionErrorCode'),
    })
  }

  toJson(): Record<string, unknown> {
    const map: Record<string, unknown> = {}
    J.writeStringIfPresent(map, 'RefID', this.refId)
    J.writeStringIfPresent(map, 'TransactionID', this.transactionId)
    J.writeStringIfPresent(map, 'InvSeries', this.invSeries)
    J.writeStringIfPresent(map, 'InvoiceData', this.invoiceData)
    J.writeStringIfPresent(map, 'ErrorCode', this.errorCode)
    J.writeStringIfPresent(map, 'DescriptionErrorCode', this.descriptionErrorCode)
    return map
  }
}
