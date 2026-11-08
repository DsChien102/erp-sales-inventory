import { MeInvoiceResult } from '../models/me_invoice_result.ts'
import { MeInvoiceApiResponse } from '../models/responses/api_response.ts'
import type { MeInvoicePublishInvoiceResultItem } from '../models/responses/publish_invoice_result.ts'
import { MeInvoiceErrorMapper } from './error_mapper.ts'
import { MeInvoiceJsonHelpers as J } from './json_helpers.ts'

/** Parses MISA HTTP JSON into MeInvoiceApiResponse and validates errors. */
export const MeInvoiceApiResponseParser = {
  parse(body: string): MeInvoiceResult<MeInvoiceApiResponse> {
    try {
      const decoded = JSON.parse(body)
      if (typeof decoded !== 'object' || decoded === null || Array.isArray(decoded)) {
        return MeInvoiceResult.failed('meinvoice_invalid_response: not a JSON object')
      }
      const map = decoded as Record<string, unknown>
      const envelope = MeInvoiceApiResponse.fromJson(map)
      if (!envelope.success) return MeInvoiceErrorMapper.fromVendorPayload(map)
      if (envelope.errorCode !== null && envelope.errorCode !== '') {
        return MeInvoiceErrorMapper.fromVendorPayload(map)
      }
      return MeInvoiceResult.ok(envelope)
    } catch (e) {
      return MeInvoiceResult.failed(`meinvoice_invalid_response: ${e}`)
    }
  },

  /** Returns the first publish-item error string, if any. */
  firstPublishItemError(items: MeInvoicePublishInvoiceResultItem[] | null | undefined): string | null {
    if (!items) return null
    for (const item of items) {
      if (!item.isSuccess) {
        const code = item.errorCode ?? 'publish_item_error'
        const desc = item.descriptionErrorCode
        if (desc !== null && desc !== '') return `${code}: ${desc}`
        return code
      }
    }
    return null
  },

  parseDataList<T>(data: unknown, fromJson: (json: Record<string, unknown>) => T): T[] {
    const out: T[] = []
    for (const item of J.asList(data)) {
      const m = J.asMap(item)
      if (m !== null) out.push(fromJson(m))
    }
    return out
  },

  parseDataString(data: unknown): string | null {
    if (typeof data !== 'string') return null
    const trimmed = data.trim()
    return trimmed === '' ? null : trimmed
  },
}
