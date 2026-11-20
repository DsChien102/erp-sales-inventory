import { assertEquals } from 'jsr:@std/assert@1'
import { runInvocation } from '../../queue/processor.ts'
import { cmd, FakeQueueRpc } from '../../queue/test_support.ts'
import { createIssuedInvoiceDeadLetters } from './dead_letters.ts'
import { createDocumentStorage } from './document_storage.ts'
import { ProviderCallAmbiguousError } from './errors.ts'
import { FakeDocumentBucket } from './fake_bucket.ts'
import {
  FakeIssuedInvoiceGateway,
  FakeIssuedInvoiceProvider,
} from './fake_gateways.ts'
import { createDownloadInvoiceDocumentHandler } from './download_invoice_document.ts'
import { createFetchOfficialViewHandler } from './fetch_official_view.ts'

Deno.test('official view failure on second attempt fails the command and records CHECK_REQUIRED', async () => {
  const gateway = new FakeIssuedInvoiceGateway()
  gateway.officialViewContext = {
    tenantId: 'tenant-1',
    electronicInvoiceId: 'ei-1',
    requestId: 'req-1',
    status: 'PENDING',
    providerConnectionId: 'conn-1',
    providerInvoiceReference: 'ref-1',
    invoiceSeries: '1C26TYY',
  }
  const provider = new FakeIssuedInvoiceProvider()
  provider.officialError = new ProviderCallAmbiguousError(
    'PROVIDER_TIMEOUT',
    'Connection timed out',
  )
  const bucket = new FakeDocumentBucket()
  const storage = createDocumentStorage(bucket)

  const handlers = {
    'einvoice.fetch_official_view': createFetchOfficialViewHandler({
      gateway,
      provider,
      storage,
    }),
  }
  const deadLetters = createIssuedInvoiceDeadLetters(gateway)
  const rpc = new FakeQueueRpc()
  rpc.batches = [[{
    ...cmd('einvoice.fetch_official_view', 1),
    payload: {
      electronic_invoice_id: 'ei-1',
      request_id: 'req-1',
    },
  }]]

  await runInvocation({ rpc, handlers, deadLetters }, 'tenant-1')

  assertEquals(rpc.count('fail'), 1)
  assertEquals(rpc.count('retryOrDeadLetter'), 0)
  assertEquals(gateway.officialViewResults.length, 1)
  const res = gateway.officialViewResults[0]
  assertEquals(res.status, 'CHECK_REQUIRED')
  assertEquals(res.failureCode, 'PROVIDER_RESULT_UNDETERMINED')
  assertEquals(res.failureSource, 'INTERNAL')
})

Deno.test('document failure on first attempt is retried without dead-letter', async () => {
  const gateway = new FakeIssuedInvoiceGateway()
  gateway.documentContext = {
    tenantId: 'tenant-1',
    electronicInvoiceId: 'ei-1',
    documentType: 'PDF',
    requestId: 'req-1',
    status: 'PENDING',
    providerConnectionId: 'conn-1',
    providerInvoiceReference: 'ref-1',
    invoiceSeries: '1C26TYY',
  }
  const provider = new FakeIssuedInvoiceProvider()
  provider.documentError = new ProviderCallAmbiguousError(
    'PROVIDER_TIMEOUT',
    'Connection timed out',
  )
  const bucket = new FakeDocumentBucket()
  const storage = createDocumentStorage(bucket)

  const handlers = {
    'einvoice.download_invoice_document': createDownloadInvoiceDocumentHandler({
      gateway,
      provider,
      storage,
    }),
  }
  const deadLetters = createIssuedInvoiceDeadLetters(gateway)
  const rpc = new FakeQueueRpc()
  rpc.batches = [[{
    ...cmd('einvoice.download_invoice_document', 0),
    payload: {
      electronic_invoice_id: 'ei-1',
      document_type: 'PDF',
      request_id: 'req-1',
    },
  }]]

  await runInvocation({ rpc, handlers, deadLetters }, 'tenant-1')

  assertEquals(rpc.count('retryOrDeadLetter'), 1)
  assertEquals(rpc.count('fail'), 0)
  assertEquals(gateway.documentResults.length, 0)
})

Deno.test('document storage error on third attempt fails and records CHECK_REQUIRED', async () => {
  const gateway = new FakeIssuedInvoiceGateway()
  gateway.documentContext = {
    tenantId: 'tenant-1',
    electronicInvoiceId: 'ei-1',
    documentType: 'PDF',
    requestId: 'req-1',
    status: 'PENDING',
    providerConnectionId: 'conn-1',
    providerInvoiceReference: 'ref-1',
    invoiceSeries: '1C26TYY',
  }
  const provider = new FakeIssuedInvoiceProvider()
  provider.documentOutcome = {
    kind: 'success',
    bytes: new TextEncoder().encode('%PDF-1.4 test'),
    providerReference: 'ref-1',
  }
  const bucket = new FakeDocumentBucket()
  bucket.shouldThrowOnUpload = new Error('SYSTEM_ERROR: storage upload failed')
  const storage = createDocumentStorage(bucket)

  const handlers = {
    'einvoice.download_invoice_document': createDownloadInvoiceDocumentHandler({
      gateway,
      provider,
      storage,
    }),
  }
  const deadLetters = createIssuedInvoiceDeadLetters(gateway)
  const rpc = new FakeQueueRpc()
  rpc.batches = [[{
    ...cmd('einvoice.download_invoice_document', 2),
    payload: {
      electronic_invoice_id: 'ei-1',
      document_type: 'PDF',
      request_id: 'req-1',
    },
  }]]

  await runInvocation({ rpc, handlers, deadLetters }, 'tenant-1')

  assertEquals(rpc.count('fail'), 1)
  assertEquals(rpc.count('retryOrDeadLetter'), 0)
  assertEquals(gateway.documentResults.length, 1)
  const res = gateway.documentResults[0]
  assertEquals(res.status, 'CHECK_REQUIRED')
  assertEquals(res.failureCode, 'PROVIDER_RESULT_UNDETERMINED')
  assertEquals(res.failureSource, 'INTERNAL')
})

