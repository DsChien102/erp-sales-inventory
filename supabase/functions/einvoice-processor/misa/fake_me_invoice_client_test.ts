import { assert, assertEquals, assertFalse } from 'jsr:@std/assert@1'
import { FakeMeInvoiceClient, FakeMeInvoiceScenario } from './fake_me_invoice_client.ts'
import {
  MeInvoiceDownloadDataType,
  MeInvoiceInvoiceData,
  MeInvoiceInvoiceDataPublished,
  MeInvoiceInvoiceQuery,
  MeInvoiceInvoiceStatus,
  MeInvoiceOriginalInvoiceDetail,
  MeInvoiceResult,
  MeInvoicePublishRequest,
  MeInvoiceSendEmailData,
  MeInvoiceSendEmailRequest,
  MeInvoiceSendEmailResponseKind,
  MeInvoiceSignType,
  MeInvoiceStatusInputType,
  MeInvoiceTaxRateInfo,
} from './mod.ts'

function sampleInvoice(refId = 'r1'): MeInvoiceInvoiceData {
  return new MeInvoiceInvoiceData({
    refId,
    invSeries: '1C25TYY',
    invDate: '2026-01-01',
    buyerLegalName: 'Buyer',
    buyerAddress: 'Address',
    totalAmountWithoutVatOc: 1000,
    totalVatAmountOc: 100,
    totalDiscountAmountOc: 0,
    totalAmountOc: 1100,
    totalAmountInWords: 'One thousand one hundred',
    originalInvoiceDetail: [
      new MeInvoiceOriginalInvoiceDetail({
        itemType: 1,
        lineNumber: 1,
        sortOrder: 1,
        itemName: 'A',
        quantity: 1,
        unitPrice: 1000,
        amountOc: 1000,
        amountWithoutVatOc: 1000,
        vatRateName: '10%',
      }),
    ],
    taxRateInfo: [new MeInvoiceTaxRateInfo({ vatRateName: '10%', amountWithoutVatOc: 1000, vatAmountOc: 100 })],
  })
}

const q = () => new MeInvoiceInvoiceQuery(true)
const email = () =>
  new MeInvoiceSendEmailRequest([new MeInvoiceSendEmailData('tx-1', null, 'buyer@example.com')], true, false)

Deno.test('FakeMeInvoiceClient ok scenario returns templates and publish', async () => {
  const client = new FakeMeInvoiceClient()
  const templates = await client.listInvoiceTemplates({ invoiceWithCode: true })
  assert(templates.isSuccess)
  assert(templates.data!.length > 0)
  const published = await client.publish(new MeInvoicePublishRequest(MeInvoiceSignType.hsmWithCks, [sampleInvoice()]))
  assert(published.isSuccess)
  assertEquals(published.data![0].transactionId, 'tx-fake-1')
  assertEquals(client.publishCount, 1)
  assertEquals(client.lastPublishRequest?.invoiceData[0].refId, 'r1')
})

Deno.test('FakeMeInvoiceClient ok sendEmail returns status 3 for requested invoice', async () => {
  const client = new FakeMeInvoiceClient()
  const result = await client.sendEmail(email())
  assert(result.isSuccess)
  assertEquals(result.data!.kind, MeInvoiceSendEmailResponseKind.itemized)
  assertEquals(result.data!.items[0].transactionId, 'tx-1')
  assertEquals(result.data!.items[0].sendEmailStatus, 3)
  assertEquals(client.sendEmailCount, 1)
  assertEquals(client.lastSendEmailRequest?.sendEmailDatas[0].transactionId, 'tx-1')
})

Deno.test('FakeMeInvoiceClient enqueueSendEmailEnvelopeAcknowledgement returns Product shape', async () => {
  const client = new FakeMeInvoiceClient()
  client.enqueueSendEmailEnvelopeAcknowledgement()
  const result = await client.sendEmail(email())
  assert(result.isSuccess)
  assertEquals(result.data!.kind, MeInvoiceSendEmailResponseKind.envelopeAcknowledgement)
  assertEquals(result.data!.items.length, 0)
})

Deno.test('FakeMeInvoiceClient failed and rateLimited scenarios', async () => {
  const client = new FakeMeInvoiceClient({ scenario: FakeMeInvoiceScenario.failed })
  let result = await client.getStatus({ ids: ['tx'], inputType: MeInvoiceStatusInputType.transactionId, query: q() })
  assertEquals(result.error, 'meinvoice_5xx')
  client.scenario = FakeMeInvoiceScenario.rateLimited
  result = await client.getStatus({ ids: ['tx'], inputType: MeInvoiceStatusInputType.transactionId, query: q() })
  assertEquals(result.rateLimited, true)
})

Deno.test('FakeMeInvoiceClient missingCredentials scenario', async () => {
  const client = new FakeMeInvoiceClient({ scenario: FakeMeInvoiceScenario.missingCredentials })
  const result = await client.download({
    transactionIds: ['tx'],
    query: q(),
    downloadDataType: MeInvoiceDownloadDataType.xml,
  })
  assertEquals(result.error, 'missing_MISA_MEINVOICE_APP_ID')
})

Deno.test('FakeMeInvoiceClient tokenExpiredThenOk fails once then succeeds', async () => {
  const client = new FakeMeInvoiceClient({ scenario: FakeMeInvoiceScenario.tokenExpiredThenOk })
  const first = await client.listInvoiceTemplates({ invoiceWithCode: true })
  assertEquals(first.error, 'TokenExpiredCode')
  const second = await client.listInvoiceTemplates({ invoiceWithCode: true })
  assert(second.isSuccess)
})

Deno.test('FakeMeInvoiceClient previewPublished and download queues are FIFO', async () => {
  const client = new FakeMeInvoiceClient()
  client.enqueuePreviewPublishedResult(MeInvoiceResult.ok('https://preview/queued'))
  const bytes = new TextEncoder().encode('%PDF')
  client.enqueueDownloadResult(MeInvoiceResult.ok([new MeInvoiceInvoiceDataPublished('tx-1', '%PDF', bytes)]))
  const preview = await client.previewPublished({ transactionIds: ['tx-1'], companyTaxCode: '0100109106' })
  assertEquals(preview.data, 'https://preview/queued')
  const download = await client.download({
    transactionIds: ['tx-1'],
    query: q(),
    downloadDataType: MeInvoiceDownloadDataType.pdf,
  })
  assert(download.isSuccess)
  assertEquals(download.data![0].bytes, bytes)
})

Deno.test('FakeMeInvoiceClient getStatusQueue FIFO overrides scenario and pops sequentially', async () => {
  const client = new FakeMeInvoiceClient({
    scenario: FakeMeInvoiceScenario.ok,
    getStatusQueue: [
      MeInvoiceResult.ok([new MeInvoiceInvoiceStatus({ refId: 'r1', transactionId: 'tx-1', publishStatus: 0 })]),
      MeInvoiceResult.failed('meinvoice_network_timeout'),
    ],
  })
  const call = () => client.getStatus({ ids: ['r1'], inputType: MeInvoiceStatusInputType.refId, query: q() })

  const first = await call()
  assert(first.isSuccess)
  assertEquals(first.data![0].publishStatus, 0)

  const second = await call()
  assertFalse(second.isSuccess)
  assertEquals(second.error, 'meinvoice_network_timeout')

  // Now queue is empty, falls back to scenario (ok)
  const third = await call()
  assert(third.isSuccess)
  assertEquals(third.data![0].publishStatus, 1)

  // Dynamically enqueue
  client.enqueueGetStatusResult(
    MeInvoiceResult.ok([
      new MeInvoiceInvoiceStatus({ refId: 'r1', transactionId: 'tx-dynamic', publishStatus: 1, invNo: '999' }),
    ]),
  )
  const fourth = await call()
  assert(fourth.isSuccess)
  assertEquals(fourth.data![0].invNo, '999')
})
