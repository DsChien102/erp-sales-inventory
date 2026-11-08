import { assertEquals } from 'jsr:@std/assert@1'
import { MeInvoiceClient } from './me_invoice_client.ts'
import { MeInvoiceSendEmailData, MeInvoiceSendEmailRequest } from './models/requests/send_email_request.ts'
import { MeInvoiceSendEmailResponseKind } from './models/responses/send_email_result.ts'
import { inOneDay, jsonResponse, mockFetch } from './test_support.ts'

function send(envelope: Record<string, unknown>) {
  const client = new MeInvoiceClient(
    {
      baseUrl: 'https://example.test/api/integration',
      accessToken: 'test-token',
      accessTokenExpiresAt: inOneDay(),
    },
    mockFetch(() => jsonResponse(envelope)),
  )
  return client.sendEmail(new MeInvoiceSendEmailRequest([new MeInvoiceSendEmailData('tx')], true, false))
}

Deno.test('th08_s5 accepts official empty-data send-email acknowledgement', async () => {
  const result = await send({
    success: true,
    errorCode: null,
    descriptionErrorCode: null,
    errors: [],
    data: '',
    customData: null,
  })
  assertEquals(result.isSuccess, true)
  assertEquals(result.data!.kind, MeInvoiceSendEmailResponseKind.envelopeAcknowledgement)
  assertEquals(result.data!.items.length, 0)
})

Deno.test('th08_s5 whitespace-only data is envelope acknowledgement', async () => {
  const result = await send({ success: true, errors: [], data: '   \n\t' })
  assertEquals(result.isSuccess, true)
  assertEquals(result.data!.kind, MeInvoiceSendEmailResponseKind.envelopeAcknowledgement)
})

Deno.test('th08_s5 success=false with empty data is failure', async () => {
  const result = await send({ success: false, errors: [], data: '' })
  assertEquals(result.isSuccess, false)
})

Deno.test('th08_s5 success=true with non-empty errors is failure', async () => {
  const result = await send({ success: true, errors: ['rejected'], data: '' })
  assertEquals(result.isSuccess, false)
  assertEquals(result.error, 'meinvoice_send_email_invalid_response')
})

for (const encoded of [false, true]) {
  for (const status of [0, 1, 2, 3, 4]) {
    Deno.test(`preserves status ${status} and references in encoded=${encoded} data`, async () => {
      const data = [{ TransactionID: 'tx', RefID: 'ref', RefDetailID: 'detail', SendEmailStatus: status, ErrorCode: '' }]
      const result = await send({ success: true, data: encoded ? JSON.stringify(data) : data })
      assertEquals(result.isSuccess, true)
      assertEquals(result.data!.kind, MeInvoiceSendEmailResponseKind.itemized)
      assertEquals(result.data!.items[0].transactionId, 'tx')
      assertEquals(result.data!.items[0].refId, 'ref')
      assertEquals(result.data!.items[0].refDetailId, 'detail')
      assertEquals(result.data!.items[0].sendEmailStatus, status)
      assertEquals(result.data!.items[0].errorCode, '')
    })
  }
}

const malformed: unknown[] = [
  null,
  true,
  [],
  '{}',
  '[',
  [42],
  [{ TransactionID: 'tx', SendEmailStatus: 3.4 }],
  [{ TransactionID: 12, SendEmailStatus: 3 }],
  { TransactionID: 'tx' },
  42,
]
for (const data of malformed) {
  Deno.test(`malformed data cannot become successful: ${JSON.stringify(data)}`, async () => {
    const result = await send({ success: true, data })
    assertEquals(result.isSuccess, false)
    assertEquals(result.error, 'meinvoice_send_email_invalid_response')
  })
}

Deno.test('false envelope with status 3 is not successful', async () => {
  const result = await send({ success: false, data: [{ TransactionID: 'tx', SendEmailStatus: 3 }] })
  assertEquals(result.isSuccess, false)
})

Deno.test('envelope errors with status 3 are not successful', async () => {
  const result = await send({ success: true, errors: ['rejected'], data: [{ TransactionID: 'tx', SendEmailStatus: 3 }] })
  assertEquals(result.isSuccess, false)
})
