import { assert, assertEquals, assertFalse, assertStringIncludes } from 'jsr:@std/assert@1'
import { MeInvoiceClient } from './me_invoice_client.ts'
import { MeInvoicePublishErrorCodes } from './me_invoice_publish_error_codes.ts'
import { DEFAULT_REQUEST_TIMEOUT_MS, type MeInvoiceConfig, TEST_BASE_URL } from './models/me_invoice_config.ts'
import { MeInvoiceSignType } from './models/me_invoice_sign_type.ts'
import { MeInvoiceInvoiceData } from './models/misa/invoice_data.ts'
import { MeInvoiceOriginalInvoiceDetail } from './models/misa/original_invoice_detail.ts'
import { MeInvoiceTaxRateInfo } from './models/misa/tax_rate_info.ts'
import { MeInvoicePublishRequest } from './models/requests/invoice_publish_request.ts'
import {
  MeInvoiceDownloadDataType,
  MeInvoiceInvoiceQuery,
  MeInvoiceStatusInputType,
} from './models/requests/invoice_query.ts'
import { MeInvoiceSendEmailData, MeInvoiceSendEmailRequest } from './models/requests/send_email_request.ts'
import { MeInvoiceSendEmailResponseKind } from './models/responses/send_email_result.ts'
import { inOneDay, jsonResponse, mockFetch, textResponse } from './test_support.ts'

function samplePublishRequest(refId = 'ref-9'): MeInvoicePublishRequest {
  return new MeInvoicePublishRequest(MeInvoiceSignType.hsmWithCks, [
    new MeInvoiceInvoiceData({
      refId,
      invSeries: '1C25TYY',
      invDate: '2026-08-01',
      buyerLegalName: 'Buyer',
      buyerAddress: 'Address',
      totalSaleAmountOc: 100,
      totalSaleAmount: 100,
      totalAmountWithoutVatOc: 100,
      totalAmountWithoutVat: 100,
      totalVatAmountOc: 10,
      totalVatAmount: 10,
      totalDiscountAmountOc: 0,
      totalDiscountAmount: 0,
      totalAmountOc: 110,
      totalAmount: 110,
      totalAmountInWords: 'One hundred ten',
      originalInvoiceDetail: [
        new MeInvoiceOriginalInvoiceDetail({
          itemType: 1,
          lineNumber: 1,
          sortOrder: 1,
          itemName: 'Svc',
          quantity: 1,
          unitPrice: 100,
          amountOc: 100,
          amount: 100,
          amountWithoutVatOc: 100,
          amountWithoutVat: 100,
          vatRateName: '10%',
          vatAmountOc: 10,
          vatAmount: 10,
        }),
      ],
      taxRateInfo: [new MeInvoiceTaxRateInfo({ vatRateName: '10%', amountWithoutVatOc: 100, vatAmountOc: 10 })],
    }),
  ])
}

const config: MeInvoiceConfig = {
  baseUrl: 'https://example.test/api/integration',
  appId: 'app-id',
  taxCode: '0100000000',
  username: 'user',
  password: 'secret',
}

const tokenOk = (tok = 'tok') => jsonResponse({ Success: true, Data: tok })
const slow = () =>
  mockFetch(async () => {
    await new Promise((r) => setTimeout(r, 20))
    return textResponse('{}', 200)
  })

Deno.test('MeInvoiceClient soft-fail missing app id does not call network', async () => {
  let calls = 0
  const client = new MeInvoiceClient(
    { baseUrl: TEST_BASE_URL, appId: null, taxCode: '0123456789', username: 'u', password: 'p' },
    mockFetch(() => {
      calls++
      return textResponse('{}', 200)
    }),
  )
  const result = await client.listInvoiceTemplates({ invoiceWithCode: true })
  assertFalse(result.isSuccess)
  assertEquals(result.error, 'missing_MISA_MEINVOICE_APP_ID')
  assertEquals(calls, 0)
})

Deno.test('MeInvoiceClient soft-fail empty password soft-fails', async () => {
  const client = new MeInvoiceClient({
    baseUrl: TEST_BASE_URL,
    appId: 'app',
    taxCode: '0123456789',
    username: 'u',
    password: '',
  })
  const result = await client.publish(samplePublishRequest())
  assertEquals(result.error, 'missing_MISA_MEINVOICE_PASSWORD')
})

Deno.test('MeInvoiceClient HTTP request timeout defaults to 60 seconds', () => {
  assertEquals(config.requestTimeoutMs ?? DEFAULT_REQUEST_TIMEOUT_MS, 60_000)
})

Deno.test({
  name: 'MeInvoiceClient HTTP API timeout maps to stable network timeout code',
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    const client = new MeInvoiceClient(
      {
        baseUrl: 'https://example.test/api/integration',
        accessToken: 'seeded-token',
        accessTokenExpiresAt: inOneDay(),
        requestTimeoutMs: 1,
      },
      slow(),
    )
    const result = await client.publish(samplePublishRequest())
    assertFalse(result.isSuccess)
    assertEquals(result.error, 'meinvoice_network_timeout')
  },
})

Deno.test({
  name: 'MeInvoiceClient HTTP authentication timeout maps to stable network timeout code',
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    const client = new MeInvoiceClient({ ...config, requestTimeoutMs: 1 }, slow())
    const result = await client.obtainAccessToken({ forceLogin: true })
    assertFalse(result.isSuccess)
    assertEquals(result.error, 'meinvoice_network_timeout')
  },
})

Deno.test('MeInvoiceClient HTTP token rejection preserves only the safe MISA error code', async () => {
  const fetchFn = mockFetch((req) => {
    assertEquals(req.url.pathname, '/api/integration/auth/token')
    return jsonResponse({ Success: false, ErrorCode: 'InvalidAppID', Errors: [], Data: null })
  })
  const client = new MeInvoiceClient(config, fetchFn)
  const result = await client.obtainAccessToken({ forceLogin: true })
  assertFalse(result.isSuccess)
  assertEquals(result.error, 'meinvoice_auth_rejected:InvalidAppID')
  assertFalse(result.error!.includes('"Success"'))
})

Deno.test('MeInvoiceClient HTTP token rejection prefers the detailed safe auth error', async () => {
  const fetchFn = mockFetch(() =>
    jsonResponse({ Success: false, ErrorCode: 'UnAuthorize', Errors: ['WrongPassWord'], Data: null })
  )
  const client = new MeInvoiceClient(config, fetchFn)
  const result = await client.obtainAccessToken({ forceLogin: true })
  assertEquals(result.error, 'meinvoice_auth_rejected:WrongPassWord')
})

Deno.test('MeInvoiceClient HTTP seeded bearer skips /auth/token', async () => {
  let authCalls = 0
  const fetchFn = mockFetch((req) => {
    if (req.url.pathname.endsWith('/auth/token')) {
      authCalls++
      return textResponse('should not login', 500)
    }
    assertEquals(req.headers['authorization'], 'Bearer seeded-token')
    return jsonResponse({ Success: true, Data: [] })
  })
  const client = new MeInvoiceClient(
    { baseUrl: 'https://example.test/api/integration', accessToken: 'seeded-token', accessTokenExpiresAt: inOneDay() },
    fetchFn,
  )
  const result = await client.listInvoiceTemplates({ invoiceWithCode: true })
  assert(result.isSuccess)
  assertEquals(authCalls, 0)
})

Deno.test('MeInvoiceClient HTTP listInvoiceTemplates maps wire payload', async () => {
  const fetchFn = mockFetch((req) => {
    if (req.url.pathname.endsWith('/auth/token')) return tokenOk('token-1')
    assertEquals(req.method, 'GET')
    assertEquals(req.url.pathname, '/api/integration/invoice/templates')
    assertEquals(req.headers['authorization'], 'Bearer token-1')
    assertEquals(req.url.searchParams.get('invoiceWithCode'), 'true')
    assertEquals(req.url.searchParams.get('ticket'), 'false')
    return jsonResponse({
      Success: true,
      Data: JSON.stringify([{
        IPTemplateID: 'tpl-1',
        CompanyID: 15388,
        TemplateName: 'GTGT',
        InvTemplateNo: '1',
        InvSeries: '1C25TYY',
        OrgInvSeries: '1KTYY',
        CreatedDate: '2024-01-15T10:00:00+07:00',
        ModifiedDate: '2024-06-01T08:30:00+07:00',
        Inactive: false,
        IsInheritFromOldTemplate: true,
        IsSendSummary: false,
        IsTemplatePetrol: false,
        IsMoreVATRate: true,
      }]),
    })
  })
  const client = new MeInvoiceClient(config, fetchFn)
  const result = await client.listInvoiceTemplates({ invoiceWithCode: true })
  assert(result.isSuccess)
  assertEquals(result.data!.length, 1)
  const t = result.data![0]
  assertEquals(t.ipTemplateId, 'tpl-1')
  assertEquals(t.companyId, 15388)
  assertEquals(t.invSeries, '1C25TYY')
  assertEquals(t.orgInvSeries, '1KTYY')
  assert(t.createdDate !== null)
  assert(t.modifiedDate !== null)
  assertEquals(t.inactive, false)
  assertEquals(t.isInheritFromOldTemplate, true)
  assertEquals(t.isSendSummary, false)
  assertEquals(t.isTemplatePetrol, false)
  assertEquals(t.isMoreVatRate, true)
})

Deno.test('MeInvoiceClient HTTP publish sends SignType envelope and parses publishInvoiceResult', async () => {
  const fetchFn = mockFetch((req) => {
    if (req.url.pathname.endsWith('/auth/token')) return tokenOk()
    assertEquals(req.method, 'POST')
    assertEquals(req.url.pathname, '/api/integration/invoice')
    const body = JSON.parse(req.body)
    assertEquals(body['SignType'], 2)
    assertEquals(body['PublishInvoiceData'], null)
    assertEquals(body['InvoiceData'].length, 1)
    assertEquals(body['InvoiceData'][0]['RefID'], 'ref-9')
    assertEquals(body['InvoiceData'][0]['BuyerLegalName'], 'Buyer')
    return jsonResponse({
      success: true,
      publishInvoiceResult: [{ RefID: 'ref-9', TransactionID: 'tx-9', InvNo: '0000009' }],
    })
  })
  const client = new MeInvoiceClient(config, fetchFn)
  const result = await client.publish(samplePublishRequest())
  assert(result.isSuccess)
  assertEquals(result.data![0].transactionId, 'tx-9')
  assertEquals(result.data![0].invNo, '0000009')
})

Deno.test('MeInvoiceClient HTTP getStatus returns failed when data list is empty', async () => {
  const fetchFn = mockFetch((req) => {
    if (req.url.pathname.endsWith('/auth/token')) return tokenOk()
    if (req.url.pathname.endsWith('/invoice/status')) return jsonResponse({ success: true, data: [] })
    return textResponse('unexpected', 500)
  })
  const client = new MeInvoiceClient(config, fetchFn)
  const result = await client.getStatus({
    ids: ['tx-1'],
    inputType: MeInvoiceStatusInputType.transactionId,
    query: new MeInvoiceInvoiceQuery(true),
  })
  assertFalse(result.isSuccess)
  assertEquals(result.error, 'meinvoice_status_empty_data')
})

Deno.test('MeInvoiceClient HTTP getStatus and download use array body and query params', async () => {
  const fetchFn = mockFetch((req) => {
    if (req.url.pathname.endsWith('/auth/token')) return tokenOk()
    if (req.url.pathname.endsWith('/invoice/status')) {
      assertEquals(JSON.parse(req.body), ['tx-1'])
      assertEquals(req.url.searchParams.get('inputType'), '1')
      assertEquals(req.url.searchParams.get('invoiceWithCode'), 'true')
      return jsonResponse({ success: true, data: [{ TransactionID: 'tx-1', PublishStatus: 2, InvNo: '0000001' }] })
    }
    if (req.url.pathname.endsWith('/invoice/download')) {
      assertEquals(JSON.parse(req.body), ['tx-1'])
      assertEquals(req.url.searchParams.get('downloadDataType'), 'pdf')
      return jsonResponse({ success: true, data: [{ TransactionID: 'tx-1', Data: 'ZmFrZQ==' }] })
    }
    return textResponse('unexpected', 500)
  })
  const client = new MeInvoiceClient(config, fetchFn)
  const query = new MeInvoiceInvoiceQuery(true)
  const status = await client.getStatus({ ids: ['tx-1'], inputType: MeInvoiceStatusInputType.transactionId, query })
  assert(status.isSuccess)
  assertEquals(status.data![0].publishStatus, 2)
  const download = await client.download({
    transactionIds: ['tx-1'],
    query,
    downloadDataType: MeInvoiceDownloadDataType.pdf,
  })
  assert(download.isSuccess)
  assert(download.data![0].bytes !== null && download.data![0].bytes!.length > 0)
})

Deno.test('MeInvoiceClient HTTP download rejects more than 50 ids', async () => {
  const client = new MeInvoiceClient(config, mockFetch(() => textResponse('{}', 200)))
  const ids = Array.from({ length: 51 }, (_, i) => `tx-${i}`)
  const result = await client.download({
    transactionIds: ids,
    query: new MeInvoiceInvoiceQuery(true),
    downloadDataType: MeInvoiceDownloadDataType.xml,
  })
  assertEquals(result.error, 'meinvoice_too_many_transaction_ids')
})

Deno.test('MeInvoiceClient HTTP rate limit maps to rateLimited', async () => {
  const fetchFn = mockFetch((req) => {
    if (req.url.pathname.endsWith('/auth/token')) return tokenOk()
    return textResponse('slow down', 429)
  })
  const client = new MeInvoiceClient(config, fetchFn)
  const result = await client.listInvoiceTemplates({ invoiceWithCode: false })
  assertEquals(result.rateLimited, true)
  assertEquals(result.error, 'meinvoice_429_rate_limited')
})

Deno.test('MeInvoiceClient HTTP publish returns item-level DuplicateInvoiceRefID without failing envelope', async () => {
  const fetchFn = mockFetch((req) => {
    if (req.url.pathname.endsWith('/auth/token')) return tokenOk()
    assertEquals(req.url.pathname, '/api/integration/invoice')
    return jsonResponse({
      success: true,
      publishInvoiceResult: [{
        RefID: 'ref-9',
        TransactionID: 'tx-dup',
        InvNo: '0000123',
        ErrorCode: MeInvoicePublishErrorCodes.duplicateInvoiceRefId,
        DescriptionErrorCode: 'RefID already exists',
      }],
    })
  })
  const client = new MeInvoiceClient(config, fetchFn)
  const result = await client.publish(samplePublishRequest())
  assert(result.isSuccess)
  assertEquals(result.data!.length, 1)
  assertEquals(result.data![0].errorCode, MeInvoicePublishErrorCodes.duplicateInvoiceRefId)
  assertEquals(result.data![0].invNo, '0000123')
})

Deno.test('MeInvoiceClient HTTP publish returns item-level definite failure without envelope failure', async () => {
  const fetchFn = mockFetch((req) => {
    if (req.url.pathname.endsWith('/auth/token')) return tokenOk()
    return jsonResponse({
      success: true,
      publishInvoiceResult: [{
        RefID: 'ref-9',
        ErrorCode: 'InvalidInvSeries',
        DescriptionErrorCode: 'Invalid invoice series',
      }],
    })
  })
  const client = new MeInvoiceClient(config, fetchFn)
  const result = await client.publish(samplePublishRequest())
  assert(result.isSuccess)
  assertEquals(result.data![0].errorCode, 'InvalidInvSeries')
})

Deno.test('MeInvoiceClient HTTP publish malformed JSON body returns invalid response error', async () => {
  const fetchFn = mockFetch((req) => {
    if (req.url.pathname.endsWith('/auth/token')) return tokenOk()
    return textResponse('<<not-json>>', 200)
  })
  const client = new MeInvoiceClient(config, fetchFn)
  const result = await client.publish(samplePublishRequest())
  assertFalse(result.isSuccess)
  assertStringIncludes(result.error!, 'meinvoice_invalid_response')
  assert(result.error!.startsWith('meinvoice_invalid_response'))
})

Deno.test('MeInvoiceClient HTTP publish network failure returns meinvoice_network error', async () => {
  const fetchFn = mockFetch((req) => {
    if (req.url.pathname.endsWith('/auth/token')) return tokenOk()
    throw new Error('Connection reset by peer')
  })
  const client = new MeInvoiceClient(config, fetchFn)
  const result = await client.publish(samplePublishRequest())
  assertFalse(result.isSuccess)
  assert(result.error!.startsWith('meinvoice_network'))
})

Deno.test('MeInvoiceClient HTTP sendEmail success preserves per-invoice result', async () => {
  const fetchFn = mockFetch((req) => {
    if (req.url.pathname.endsWith('/auth/token')) return tokenOk()
    assert(req.url.pathname.endsWith('/invoice/sendemail'))
    assertEquals(req.method, 'POST')
    return jsonResponse({ Success: true, Data: [{ TransactionID: 'tx-send-1', SendEmailStatus: 3 }] })
  })
  const client = new MeInvoiceClient(config, fetchFn)
  const result = await client.sendEmail(
    new MeInvoiceSendEmailRequest([new MeInvoiceSendEmailData('tx-send-1', null, 'buyer@example.com')], true, false),
  )
  assert(result.isSuccess)
  assertEquals(result.data!.kind, MeInvoiceSendEmailResponseKind.itemized)
  assertEquals(result.data!.items[0].transactionId, 'tx-send-1')
  assertEquals(result.data!.items[0].sendEmailStatus, 3)
})

Deno.test('MeInvoiceClient HTTP token expired triggers refresh then retries', async () => {
  let authCalls = 0
  let refreshCalls = 0
  let templateCalls = 0
  const fetchFn = mockFetch((req) => {
    if (req.url.pathname.endsWith('/auth/token')) {
      authCalls++
      return tokenOk('token-old')
    }
    if (req.url.pathname.endsWith('/auth/refreshtoken')) {
      refreshCalls++
      assertEquals(req.body, 'token-old')
      return tokenOk('token-new')
    }
    if (req.url.pathname.endsWith('/invoice/templates')) {
      templateCalls++
      if (templateCalls === 1) {
        assertEquals(req.headers['authorization'], 'Bearer token-old')
        return jsonResponse({ Success: false, ErrorCode: 'TokenExpiredCode' })
      }
      assertEquals(req.headers['authorization'], 'Bearer token-new')
      return jsonResponse({ Success: true, Data: [] })
    }
    return textResponse('unexpected', 500)
  })
  const client = new MeInvoiceClient(config, fetchFn)
  const result = await client.listInvoiceTemplates({ invoiceWithCode: true })
  assert(result.isSuccess)
  assertEquals(authCalls, 1)
  assertEquals(refreshCalls, 1)
  assertEquals(templateCalls, 2)
})
