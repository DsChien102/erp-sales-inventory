import { assertEquals, assertThrows } from 'jsr:@std/assert@1'
import { resolveEndpointCapabilities } from './endpoint_capabilities.ts'

const TEST = 'https://testapi.meinvoice.vn/api/integration'
const PROD = 'https://api.meinvoice.vn/api/integration'

Deno.test('MeInvoiceEndpointCapabilities testapi.meinvoice.vn never advertises emailDelivery even when enabled', () => {
  const caps = resolveEndpointCapabilities(TEST, true)
  assertEquals(caps.supportsEmailDelivery, false)
  assertEquals(new Set(caps.supportedDocumentTypes), new Set(['PDF', 'XML']))
})

Deno.test('MeInvoiceEndpointCapabilities api.meinvoice.vn Product host allows emailDelivery only when enabled', () => {
  assertEquals(resolveEndpointCapabilities(PROD, true).supportsEmailDelivery, true)
  assertEquals(resolveEndpointCapabilities(PROD, false).supportsEmailDelivery, false)
})

Deno.test('MeInvoiceEndpointCapabilities always advertises PDF and XML support', () => {
  const caps = resolveEndpointCapabilities(TEST, false)
  assertEquals(caps.supportedDocumentTypes.includes('PDF'), true)
  assertEquals(caps.supportedDocumentTypes.includes('XML'), true)
})

Deno.test('MeInvoiceEndpointCapabilities always advertises unpublished preview support', () => {
  assertEquals(resolveEndpointCapabilities(TEST, false).supportsPreview, true)
  assertEquals(resolveEndpointCapabilities(PROD, true).supportsPreview, true)
})

Deno.test('MeInvoiceEndpointCapabilities rejects non-HTTPS base URLs', () => {
  assertThrows(() => resolveEndpointCapabilities('http://api.meinvoice.vn/api/integration', true), Error, 'HTTPS')
})
