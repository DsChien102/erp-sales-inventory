import { assertEquals } from 'jsr:@std/assert@1'
import {
  InvoiceDocumentContentPolicy,
  isZip,
  validateDocumentContent,
} from './document_content_policy.ts'

Deno.test('accepts PDF signature and rejects empty or non-PDF bytes', () => {
  assertEquals(
    validateDocumentContent('PDF', new Uint8Array([0x25, 0x50, 0x44, 0x46, 0x2D])),
    null,
  )
  assertEquals(
    validateDocumentContent('PDF', new Uint8Array([1, 2, 3])),
    'DOCUMENT_CONTENT_INVALID',
  )
})

Deno.test('accepts XML prefix and rejects empty bytes', () => {
  const enc = new TextEncoder()
  assertEquals(
    validateDocumentContent('XML', enc.encode('<?xml version="1.0"?>')),
    null,
  )
  assertEquals(
    validateDocumentContent(
      'XML',
      new Uint8Array([0xEF, 0xBB, 0xBF, 0x3C, 0x3F, 0x78, 0x6D, 0x6C]),
    ),
    null,
  )
  assertEquals(
    validateDocumentContent('XML', enc.encode('\r\n   <HDon>')),
    null,
  )
  assertEquals(
    validateDocumentContent(
      'XML',
      new Uint8Array([0x50, 0x4B, 0x03, 0x04, 0x00, 0x00]),
    ),
    null,
  )
  assertEquals(
    validateDocumentContent('XML', new Uint8Array([])),
    'DOCUMENT_CONTENT_INVALID',
  )
})

Deno.test('document content policy accepts zipped XML', () => {
  const zipBytes = new Uint8Array([0x50, 0x4B, 0x03, 0x04, 0x14, 0x00])
  assertEquals(isZip(zipBytes), true)
  assertEquals(InvoiceDocumentContentPolicy.isZip(zipBytes), true)
  assertEquals(validateDocumentContent('XML', zipBytes), null)
  assertEquals(
    InvoiceDocumentContentPolicy.validate({ type: 'XML', bytes: zipBytes }),
    null,
  )
})

