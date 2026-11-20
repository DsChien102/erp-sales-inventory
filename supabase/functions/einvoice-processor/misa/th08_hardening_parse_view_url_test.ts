import { assertEquals, assertStringIncludes } from 'jsr:@std/assert@1'
import { MeInvoiceApiResponseParser } from './internal/api_response_parser.ts'
import { MeInvoiceClient } from './me_invoice_client.ts'
import { MeInvoiceViewUrlPolicy } from './me_invoice_view_url_policy.ts'
import { TEST_BASE_URL } from './models/me_invoice_config.ts'
import { MeInvoiceInvoiceQuery } from './models/requests/invoice_query.ts'
import { inOneDay, jsonResponse, mockFetch } from './test_support.ts'

function clientReturning(data: unknown) {
  return new MeInvoiceClient(
    { baseUrl: TEST_BASE_URL, accessToken: 'test-token', accessTokenExpiresAt: inOneDay() },
    mockFetch(() => jsonResponse({ Success: true, Data: data })),
  )
}

Deno.test('th08_hardening_parse — parseDataString fail-closed accepts non-empty string', () => {
  assertEquals(
    MeInvoiceApiResponseParser.parseDataString('https://meinvoice.vn/viewer/a'),
    'https://meinvoice.vn/viewer/a',
  )
})

Deno.test('th08_hardening_parse — parseDataString fail-closed empty string becomes null', () => {
  assertEquals(MeInvoiceApiResponseParser.parseDataString(''), null)
  assertEquals(MeInvoiceApiResponseParser.parseDataString('   '), null)
})

Deno.test('th08_hardening_parse — parseDataString fail-closed object is not coerced via toString', () => {
  assertEquals(MeInvoiceApiResponseParser.parseDataString({ url: 'https://x' }), null)
})

Deno.test('th08_hardening_parse — parseDataString fail-closed list is not coerced via toString', () => {
  assertEquals(MeInvoiceApiResponseParser.parseDataString(['https://meinvoice.vn/x']), null)
})

Deno.test('th08_hardening_parse — parseDataString fail-closed number is not coerced via toString', () => {
  assertEquals(MeInvoiceApiResponseParser.parseDataString(42), null)
})

Deno.test('th08_hardening_parse — HTTPS view URL allowlist accepts absolute https meinvoice.vn host', () => {
  for (const u of [
    'https://meinvoice.vn/viewer/preview-1',
    'https://api.meinvoice.vn/viewer/x',
    'https://testapi.meinvoice.vn/viewer/x',
  ]) {
    assertEquals(MeInvoiceViewUrlPolicy.tryParse(u), u)
  }
})

Deno.test('th08_hardening_parse — HTTPS view URL allowlist rejects empty, http, relative and foreign hosts', () => {
  assertEquals(MeInvoiceViewUrlPolicy.tryParse(''), null)
  assertEquals(MeInvoiceViewUrlPolicy.tryParse('http://meinvoice.vn/x'), null)
  assertEquals(MeInvoiceViewUrlPolicy.tryParse('/viewer/relative'), null)
  assertEquals(MeInvoiceViewUrlPolicy.tryParse('https://evil.example/viewer'), null)
  assertEquals(MeInvoiceViewUrlPolicy.tryParse('javascript:alert(1)'), null)
})

Deno.test('th08_hardening_parse — previewPublished client rejects non-string Data without false success', async () => {
  const result = await clientReturning({ url: 'https://meinvoice.vn/x' }).previewPublished({
    transactionIds: ['tx-1'],
    companyTaxCode: '0101234567',
  })
  assertEquals(result.isSuccess, false)
  assertEquals(result.error, 'meinvoice_preview_invalid_data')
})

Deno.test('th08_hardening_parse — previewPublished client rejects http URL on allowlisted host', async () => {
  const result = await clientReturning('http://meinvoice.vn/viewer/x').previewPublished({
    transactionIds: ['tx-1'],
    companyTaxCode: '0101234567',
  })
  assertEquals(result.isSuccess, false)
  assertEquals(result.error, 'meinvoice_preview_invalid_url')
})

Deno.test('th08_hardening_parse — previewPublished client sends classification query flags when provided', async () => {
  let requested: URL | undefined
  const client = new MeInvoiceClient(
    { baseUrl: TEST_BASE_URL, accessToken: 'test-token', accessTokenExpiresAt: inOneDay() },
    mockFetch((req) => {
      requested = req.url
      return jsonResponse({ Success: true, Data: 'https://meinvoice.vn/viewer/ok' })
    }),
  )
  const result = await client.previewPublished({
    transactionIds: ['tx-1'],
    companyTaxCode: '0101234567',
    query: MeInvoiceInvoiceQuery.fromInvSeries('2C26MYY'),
  })
  assertEquals(result.isSuccess, true)
  assertStringIncludes(requested!.pathname, '/invoice/publishview')
  assertEquals(requested!.searchParams.get('invoiceWithCode'), 'true')
  assertEquals(requested!.searchParams.get('invoiceCalcu'), 'true')
})

Deno.test('th08_hardening_parse — previewPublished client accepts https meinvoice viewer URL', async () => {
  const result = await clientReturning('https://meinvoice.vn/viewer/ok').previewPublished({
    transactionIds: ['tx-1'],
    companyTaxCode: '0101234567',
  })
  assertEquals(result.isSuccess, true)
  assertEquals(result.data, 'https://meinvoice.vn/viewer/ok')
})
