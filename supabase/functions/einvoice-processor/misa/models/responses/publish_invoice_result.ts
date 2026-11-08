import { MeInvoiceJsonHelpers as J } from '../../internal/json_helpers.ts'

/** One item in `publishInvoiceResult[]` (§6 publish response). */
export class MeInvoicePublishInvoiceResultItem {
  constructor(
    readonly init: {
      refId?: string | null
      transactionId?: string | null
      invSeries?: string | null
      invNo?: string | null
      errorCode?: string | null
      descriptionErrorCode?: string | null
    } = {},
  ) {}
  get refId(): string | null { return this.init.refId ?? null }
  get transactionId(): string | null { return this.init.transactionId ?? null }
  get invSeries(): string | null { return this.init.invSeries ?? null }
  get invNo(): string | null { return this.init.invNo ?? null }
  get errorCode(): string | null { return this.init.errorCode ?? null }
  get descriptionErrorCode(): string | null { return this.init.descriptionErrorCode ?? null }

  get isSuccess(): boolean {
    return this.errorCode === null || this.errorCode === ''
  }

  static fromJson(json: Record<string, unknown>): MeInvoicePublishInvoiceResultItem {
    return new MeInvoicePublishInvoiceResultItem({
      refId: J.readString(json, 'RefID'),
      transactionId: J.readString(json, 'TransactionID'),
      invSeries: J.readString(json, 'InvSeries'),
      invNo: J.readString(json, 'InvNo'),
      errorCode: J.readString(json, 'ErrorCode'),
      descriptionErrorCode: J.readString(json, 'DescriptionErrorCode'),
    })
  }

  toJson(): Record<string, unknown> {
    const map: Record<string, unknown> = {}
    J.writeStringIfPresent(map, 'RefID', this.refId)
    J.writeStringIfPresent(map, 'TransactionID', this.transactionId)
    J.writeStringIfPresent(map, 'InvSeries', this.invSeries)
    J.writeStringIfPresent(map, 'InvNo', this.invNo)
    J.writeStringIfPresent(map, 'ErrorCode', this.errorCode)
    J.writeStringIfPresent(map, 'DescriptionErrorCode', this.descriptionErrorCode)
    return map
  }
}
