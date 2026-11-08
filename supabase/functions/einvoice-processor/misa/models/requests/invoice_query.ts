import { FormatException } from '../../internal/format_exception.ts'

/** Input type for `/invoice/status` (§11). */
export const MeInvoiceStatusInputType = {
  /** Lấy theo TransactionID. */
  transactionId: { name: 'transactionId', wireValue: 1 },
  /** Lấy theo RefID. */
  refId: { name: 'refId', wireValue: 2 },
} as const
export type MeInvoiceStatusInputType = (typeof MeInvoiceStatusInputType)[keyof typeof MeInvoiceStatusInputType]

/** Download format query param `downloadDataType` (§8). */
export const MeInvoiceDownloadDataType = {
  xml: { name: 'xml', wireValue: 'xml' },
  pdf: { name: 'pdf', wireValue: 'pdf' },
  all: { name: 'all', wireValue: 'All' },
} as const
export type MeInvoiceDownloadDataType = (typeof MeInvoiceDownloadDataType)[keyof typeof MeInvoiceDownloadDataType]

/** Shared query params for status/download/voucher-paper endpoints. */
export class MeInvoiceInvoiceQuery {
  constructor(readonly invoiceWithCode: boolean, readonly invoiceCalcu: boolean = false) {}

  /**
   * Derives query flags from invSeries per MISA §1.6.
   * Index 1: C = có mã, K = không mã. Index 4: M = MTT, T = thường.
   */
  static fromInvSeries(invSeries: string): MeInvoiceInvoiceQuery {
    const parsed = MeInvoiceInvoiceQuery.tryFromInvSeries(invSeries)
    if (parsed === null) {
      throw new FormatException(`Malformed MISA InvSeries (${invSeries})`)
    }
    return parsed
  }

  /** Returns null rather than inferring provider flags from malformed input. */
  static tryFromInvSeries(invSeries: string): MeInvoiceInvoiceQuery | null {
    const normalized = invSeries.trim().toUpperCase()
    if (normalized.length < 5) return null
    const typeChar = normalized[0]
    const codeChar = normalized[1]
    const usageChar = normalized[4]
    if (!['1', '2', '5', '6'].includes(typeChar) || !['C', 'K'].includes(codeChar) ||
      !['T', 'M'].includes(usageChar)) {
      return null
    }
    return new MeInvoiceInvoiceQuery(codeChar === 'C', usageChar === 'M')
  }

  toQueryParameters(opts: {
    inputType?: MeInvoiceStatusInputType | null
    downloadDataType?: MeInvoiceDownloadDataType | null
    converter?: string | null
    convertDate?: string | null
  } = {}): Record<string, string> {
    const out: Record<string, string> = {
      invoiceWithCode: String(this.invoiceWithCode),
      invoiceCalcu: String(this.invoiceCalcu),
    }
    if (opts.inputType) out['inputType'] = `${opts.inputType.wireValue}`
    if (opts.downloadDataType) out['downloadDataType'] = opts.downloadDataType.wireValue
    if (opts.converter != null) out['Converter'] = opts.converter
    if (opts.convertDate != null) out['ConvertDate'] = opts.convertDate
    return out
  }
}
