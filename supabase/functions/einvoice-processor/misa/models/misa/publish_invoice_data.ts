import { MeInvoiceJsonHelpers as J } from '../../internal/json_helpers.ts'

export interface MeInvoicePublishInvoiceDataInit {
  refId?: string | null
  transactionId?: string | null
  invSeries?: string | null
  invoiceData?: string | null
  isInvoiceCalculatingMachine?: boolean | null
  isSendEmail?: boolean | null
  receiverName?: string | null
  receiverEmail?: string | null
}

export class MeInvoicePublishInvoiceData {
  readonly refId: string | null
  readonly transactionId: string | null
  readonly invSeries: string | null
  readonly invoiceData: string | null
  readonly isInvoiceCalculatingMachine: boolean | null
  readonly isSendEmail: boolean | null
  readonly receiverName: string | null
  readonly receiverEmail: string | null
  constructor(init: MeInvoicePublishInvoiceDataInit = {}) {
    this.refId = init.refId ?? null
    this.transactionId = init.transactionId ?? null
    this.invSeries = init.invSeries ?? null
    this.invoiceData = init.invoiceData ?? null
    this.isInvoiceCalculatingMachine = init.isInvoiceCalculatingMachine ?? null
    this.isSendEmail = init.isSendEmail ?? null
    this.receiverName = init.receiverName ?? null
    this.receiverEmail = init.receiverEmail ?? null
  }

  static fromJson(json: Record<string, unknown>): MeInvoicePublishInvoiceData {
    return new MeInvoicePublishInvoiceData({
      refId: J.readString(json, 'RefID'),
      transactionId: J.readString(json, 'TransactionID'),
      invSeries: J.readString(json, 'InvSeries'),
      invoiceData: J.readString(json, 'InvoiceData'),
      isInvoiceCalculatingMachine: J.readBool(json, 'IsInvoiceCalculatingMachine'),
      isSendEmail: J.readBool(json, 'IsSendEmail'),
      receiverName: J.readString(json, 'ReceiverName'),
      receiverEmail: J.readString(json, 'ReceiverEmail'),
    })
  }

  toJson(): Record<string, unknown> {
    const map: Record<string, unknown> = {}
    J.writeIfPresent(map, 'RefID', this.refId)
    J.writeIfPresent(map, 'TransactionID', this.transactionId)
    J.writeIfPresent(map, 'InvSeries', this.invSeries)
    J.writeIfPresent(map, 'InvoiceData', this.invoiceData)
    J.writeIfPresent(map, 'IsInvoiceCalculatingMachine', this.isInvoiceCalculatingMachine)
    J.writeIfPresent(map, 'IsSendEmail', this.isSendEmail)
    J.writeIfPresent(map, 'ReceiverName', this.receiverName)
    J.writeIfPresent(map, 'ReceiverEmail', this.receiverEmail)
    return map
  }
}
