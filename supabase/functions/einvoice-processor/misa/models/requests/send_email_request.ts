import { MeInvoiceJsonHelpers as J } from '../../internal/json_helpers.ts'

/** One email entry in §10 send email request. */
export class MeInvoiceSendEmailData {
  constructor(
    readonly transactionId: string,
    readonly receiverName: string | null = null,
    readonly receiverEmail: string | null = null,
    readonly ccEmail: string | null = null,
    readonly replyEmail: string | null = null,
  ) {}

  toJson(): Record<string, unknown> {
    const map: Record<string, unknown> = { TransactionID: this.transactionId }
    J.writeStringIfPresent(map, 'ReceiverName', this.receiverName)
    J.writeStringIfPresent(map, 'ReceiverEmail', this.receiverEmail)
    J.writeStringIfPresent(map, 'CCEmail', this.ccEmail)
    J.writeStringIfPresent(map, 'ReplyEmail', this.replyEmail)
    return map
  }
}

/** POST `/invoice/sendemail` body (§10). */
export class MeInvoiceSendEmailRequest {
  constructor(
    readonly sendEmailDatas: MeInvoiceSendEmailData[],
    readonly isInvoiceCode: boolean,
    readonly isInvoiceCalculatingMachine: boolean,
  ) {}

  toJson(): Record<string, unknown> {
    return {
      SendEmailDatas: this.sendEmailDatas.map((e) => e.toJson()),
      IsInvoiceCode: this.isInvoiceCode,
      IsInvoiceCalculatingMachine: this.isInvoiceCalculatingMachine,
    }
  }
}
