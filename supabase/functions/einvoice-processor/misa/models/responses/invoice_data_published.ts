import { MeInvoiceJsonHelpers as J } from '../../internal/json_helpers.ts'

function decodeBase64(text: string): Uint8Array | null {
  try {
    const bin = atob(text)
    const out = new Uint8Array(bin.length)
    for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i)
    return out
  } catch {
    return null
  }
}

/** Download item from §8 (`InvoiceDataPublished`). */
export class MeInvoiceInvoiceDataPublished {
  constructor(
    readonly transactionId: string,
    readonly data: string | null = null,
    readonly bytes: Uint8Array | null = null,
    /** Non-document fields of the provider item, clipped. Never contains document content. */
    readonly diagnostics: string | null = null,
  ) {}

  static fromJson(json: Record<string, unknown>): MeInvoiceInvoiceDataPublished {
    const rawData = J.readString(json, 'Data')
    let bytes: Uint8Array | null = null
    if (rawData !== null && rawData !== '') {
      const trimmed = rawData.trim()
      if (trimmed.startsWith('<')) {
        // MISA returns raw XML text for invoice documents (not base64 encoded).
        bytes = new TextEncoder().encode(rawData)
      } else {
        bytes = decodeBase64(trimmed) ?? new TextEncoder().encode(rawData)
      }
    }
    return new MeInvoiceInvoiceDataPublished(
      J.readString(json, 'TransactionID') ?? '',
      rawData,
      bytes,
      diagnostics(json),
    )
  }

  toJson(): Record<string, unknown> {
    const map: Record<string, unknown> = { TransactionID: this.transactionId }
    J.writeStringIfPresent(map, 'Data', this.data)
    return map
  }
}

function diagnostics(json: Record<string, unknown>): string | null {
  const parts: string[] = []
  for (const [key, value] of Object.entries(json)) {
    if (key.toLowerCase() === 'data') continue
    const text = `${value ?? ''}`
    parts.push(`${key}=${text.length <= 120 ? text : `${text.substring(0, 120)}…`}`)
  }
  return parts.length === 0 ? null : parts.join(' ')
}
