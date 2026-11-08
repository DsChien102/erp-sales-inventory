import { DocumentType } from './outcomes.ts'

export const MAX_BYTES = 20 * 1024 * 1024

export function isZip(bytes: Uint8Array): boolean {
  return (
    bytes.length >= 4 &&
    bytes[0] === 0x50 &&
    bytes[1] === 0x4B &&
    bytes[2] === 0x03 &&
    bytes[3] === 0x04
  )
}

function looksLikeXml(bytes: Uint8Array): boolean {
  if (bytes.length === 0) return false

  // ZIP archive container support (MISA may package XML invoice into zip)
  if (isZip(bytes)) {
    return true
  }

  let offset = 0
  // Strip UTF-8 BOM: EF BB BF
  if (
    bytes.length >= 3 &&
    bytes[0] === 0xEF &&
    bytes[1] === 0xBB &&
    bytes[2] === 0xBF
  ) {
    offset = 3
  } else if (
    bytes.length >= 2 &&
    ((bytes[0] === 0xFE && bytes[1] === 0xFF) ||
      (bytes[0] === 0xFF && bytes[1] === 0xFE))
  ) {
    // Strip UTF-16 BOM
    offset = 2
  }

  // Skip leading whitespace (space, tab, CR, LF, null)
  while (
    offset < bytes.length &&
    (bytes[offset] === 0x20 ||
      bytes[offset] === 0x09 ||
      bytes[offset] === 0x0D ||
      bytes[offset] === 0x0A ||
      bytes[offset] === 0x00)
  ) {
    offset++
  }

  if (offset >= bytes.length) return false

  // XML starts with '<' (ASCII 0x3C)
  return bytes[offset] === 0x3C
}

export function validateDocumentContent(
  type: DocumentType,
  bytes: Uint8Array,
): string | null {
  if (bytes.length === 0 || bytes.length > MAX_BYTES) {
    return 'DOCUMENT_CONTENT_INVALID'
  }
  if (type === 'PDF') {
    return bytes.length >= 5 &&
        bytes[0] === 0x25 &&
        bytes[1] === 0x50 &&
        bytes[2] === 0x44 &&
        bytes[3] === 0x46 &&
        bytes[4] === 0x2D
      ? null
      : 'DOCUMENT_CONTENT_INVALID'
  }
  if (type === 'XML') {
    return looksLikeXml(bytes) ? null : 'DOCUMENT_CONTENT_INVALID'
  }
  return 'DOCUMENT_CONTENT_INVALID'
}

export const InvoiceDocumentContentPolicy = {
  maxBytes: MAX_BYTES,
  validate(opts: { type: DocumentType; bytes: Uint8Array }): string | null {
    return validateDocumentContent(opts.type, opts.bytes)
  },
  isZip(bytes: Uint8Array): boolean {
    return isZip(bytes)
  },
}

