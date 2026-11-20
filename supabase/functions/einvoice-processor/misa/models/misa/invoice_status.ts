import { MeInvoiceJsonHelpers as J } from '../../internal/json_helpers.ts'

export interface MeInvoiceInvoiceStatusInit {
  refId?: string | null
  invSeries?: string | null
  invTempl?: string | null
  buyerName?: string | null
  buyerTaxCode?: string | null
  buyerCode?: string | null
  buyerFullName?: string | null
  transactionId?: string | null
  publishStatus?: number | null
  eInvoiceStatus?: number | null
  referenceType?: number | null
  invoiceCode?: string | null
  sourceType?: string | null
  sendTaxStatus?: number | null
  publishedTime?: Date | null
  invNo?: string | null
}

export class MeInvoiceInvoiceStatus {
  readonly refId: string | null
  readonly invSeries: string | null
  readonly invTempl: string | null
  readonly buyerName: string | null
  readonly buyerTaxCode: string | null
  readonly buyerCode: string | null
  readonly buyerFullName: string | null
  readonly transactionId: string | null
  readonly publishStatus: number | null
  readonly eInvoiceStatus: number | null
  readonly referenceType: number | null
  readonly invoiceCode: string | null
  readonly sourceType: string | null
  readonly sendTaxStatus: number | null
  readonly publishedTime: Date | null
  readonly invNo: string | null
  constructor(init: MeInvoiceInvoiceStatusInit = {}) {
    this.refId = init.refId ?? null
    this.invSeries = init.invSeries ?? null
    this.invTempl = init.invTempl ?? null
    this.buyerName = init.buyerName ?? null
    this.buyerTaxCode = init.buyerTaxCode ?? null
    this.buyerCode = init.buyerCode ?? null
    this.buyerFullName = init.buyerFullName ?? null
    this.transactionId = init.transactionId ?? null
    this.publishStatus = init.publishStatus ?? null
    this.eInvoiceStatus = init.eInvoiceStatus ?? null
    this.referenceType = init.referenceType ?? null
    this.invoiceCode = init.invoiceCode ?? null
    this.sourceType = init.sourceType ?? null
    this.sendTaxStatus = init.sendTaxStatus ?? null
    this.publishedTime = init.publishedTime ?? null
    this.invNo = init.invNo ?? null
  }

  static fromJson(json: Record<string, unknown>): MeInvoiceInvoiceStatus {
    return new MeInvoiceInvoiceStatus({
      refId: J.readString(json, 'RefID'),
      invSeries: J.readString(json, 'InvSeries'),
      invTempl: J.readString(json, 'InvTempl'),
      buyerName: J.readString(json, 'BuyerName'),
      buyerTaxCode: J.readString(json, 'BuyerTaxCode'),
      buyerCode: J.readString(json, 'BuyerCode'),
      buyerFullName: J.readString(json, 'BuyerFullName'),
      transactionId: J.readString(json, 'TransactionID'),
      publishStatus: J.readInt(json, 'PublishStatus'),
      eInvoiceStatus: J.readInt(json, 'EInvoiceStatus'),
      referenceType: J.readInt(json, 'ReferenceType'),
      invoiceCode: J.readString(json, 'InvoiceCode'),
      sourceType: J.readString(json, 'SourceType'),
      sendTaxStatus: typeof json['SendTaxStatus'] === 'number' ? json['SendTaxStatus'] : null,
      publishedTime: J.readDateTime(json, 'PublishedTime'),
      invNo: J.readString(json, 'InvNo'),
    })
  }

  toJson(): Record<string, unknown> {
    const map: Record<string, unknown> = {}
    J.writeIfPresent(map, 'RefID', this.refId)
    J.writeIfPresent(map, 'InvSeries', this.invSeries)
    J.writeIfPresent(map, 'InvTempl', this.invTempl)
    J.writeIfPresent(map, 'BuyerName', this.buyerName)
    J.writeIfPresent(map, 'BuyerTaxCode', this.buyerTaxCode)
    J.writeIfPresent(map, 'BuyerCode', this.buyerCode)
    J.writeIfPresent(map, 'BuyerFullName', this.buyerFullName)
    J.writeIfPresent(map, 'TransactionID', this.transactionId)
    J.writeIfPresent(map, 'PublishStatus', this.publishStatus)
    J.writeIfPresent(map, 'EInvoiceStatus', this.eInvoiceStatus)
    J.writeIfPresent(map, 'ReferenceType', this.referenceType)
    J.writeIfPresent(map, 'InvoiceCode', this.invoiceCode)
    J.writeIfPresent(map, 'SourceType', this.sourceType)
    J.writeIfPresent(map, 'SendTaxStatus', this.sendTaxStatus)
    J.writeIfPresent(map, 'PublishedTime', this.publishedTime?.toISOString())
    J.writeIfPresent(map, 'InvNo', this.invNo)
    return map
  }
}
