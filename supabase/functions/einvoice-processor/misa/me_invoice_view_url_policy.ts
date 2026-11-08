/** Fail-closed HTTPS viewer URL policy for MISA preview/official view links. */
export const MeInvoiceViewUrlPolicy = {
  /** Returns the trimmed URL when it is an absolute HTTPS URL on an approved MISA host. */
  tryParse(raw: string | null | undefined): string | null {
    if (raw == null) return null
    const trimmed = raw.trim()
    if (trimmed === '') return null
    let uri: URL
    try {
      uri = new URL(trimmed)
    } catch {
      return null
    }
    if (uri.protocol.toLowerCase() !== 'https:' || uri.hostname === '') return null
    if (!isAllowedHost(uri.hostname)) return null
    return trimmed
  },
}

function isAllowedHost(host: string): boolean {
  const n = host.toLowerCase()
  return n === 'meinvoice.vn' || n.endsWith('.meinvoice.vn')
}
