import { FormatException } from '../../internal/format_exception.ts'

/** Per-invoice result from MISA POST /invoice/sendemail. */
export class MeInvoiceSendEmailResultItem {
  constructor(
    readonly transactionId: string | null = null,
    readonly refId: string | null = null,
    readonly refDetailId: string | null = null,
    readonly sendEmailStatus: number | null = null,
    readonly errorCode: string | null = null,
  ) {}

  static fromJson(json: Record<string, unknown>): MeInvoiceSendEmailResultItem {
    const text = (key: string): string | null => {
      const value = json[key]
      if (value !== null && value !== undefined && typeof value !== 'string') {
        throw new FormatException(`Invalid ${key}`)
      }
      return (value as string | null | undefined) ?? null
    }
    const status = json['SendEmailStatus']
    if (status !== null && status !== undefined && !Number.isInteger(status)) {
      throw new FormatException('Invalid SendEmailStatus')
    }
    return new MeInvoiceSendEmailResultItem(
      text('TransactionID'),
      text('RefID'),
      text('RefDetailID'),
      (status as number | null | undefined) ?? null,
      text('ErrorCode'),
    )
  }
}

/** Closed shapes returned by MISA Product and compatible itemized hosts. */
export const MeInvoiceSendEmailResponseKind = {
  /** Official Product acknowledgement: `success=true`, empty `errors`, `data=""`. */
  envelopeAcknowledgement: 'envelopeAcknowledgement',
  /** Itemized per-invoice rows. */
  itemized: 'itemized',
} as const
export type MeInvoiceSendEmailResponseKind =
  (typeof MeInvoiceSendEmailResponseKind)[keyof typeof MeInvoiceSendEmailResponseKind]

/** Typed `/invoice/sendemail` success payload. */
export class MeInvoiceSendEmailResponse {
  private constructor(
    readonly kind: MeInvoiceSendEmailResponseKind,
    readonly items: readonly MeInvoiceSendEmailResultItem[],
  ) {}

  static envelopeAcknowledgement(): MeInvoiceSendEmailResponse {
    return new MeInvoiceSendEmailResponse(MeInvoiceSendEmailResponseKind.envelopeAcknowledgement, [])
  }

  static itemized(items: MeInvoiceSendEmailResultItem[]): MeInvoiceSendEmailResponse {
    return new MeInvoiceSendEmailResponse(MeInvoiceSendEmailResponseKind.itemized, Object.freeze([...items]))
  }
}
