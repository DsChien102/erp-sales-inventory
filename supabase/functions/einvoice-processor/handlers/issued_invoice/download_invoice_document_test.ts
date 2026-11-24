import { assertEquals, assertRejects } from 'jsr:@std/assert@1'
import type { ClaimedCommand, CommandContext } from '../../queue/types.ts'
import { createDocumentStorage, sha256Hex } from './document_storage.ts'
import { FakeDocumentBucket } from './fake_bucket.ts'
import {
  FakeIssuedInvoiceGateway,
  FakeIssuedInvoiceProvider,
} from './fake_gateways.ts'
import { createDownloadInvoiceDocumentHandler } from './download_invoice_document.ts'
import type { DocumentContext } from './gateways.ts'

function makeCtx(payload: Record<string, unknown>, id = 'cmd-1', tenantId = 'tenant-1'): CommandContext {
  const command: ClaimedCommand = {
    commandId: id,
    commandType: 'einvoice.download_invoice_document',
    payload,
    sourceEventId: null,
    enqueuedAt: '2026-11-08T00:00:00Z',
    claimToken: 'tok-1',
    retryCount: 0,
  }
  return { tenantId, command, attemptNumber: 1 }
}

function pendingContext(over: Partial<DocumentContext> = {}): DocumentContext {
  return {
    tenantId: 'tenant-1',
    electronicInvoiceId: 'ei-1',
    documentType: 'PDF',
    requestId: 'req-doc-1',
    status: 'PENDING',
    providerConnectionId: 'conn-1',
    providerInvoiceReference: 'ref-1',
    invoiceSeries: '1C26TYY',
    ...over,
  }
}

Deno.test('DownloadInvoiceDocumentCommand round-trips document type wire values', async () => {
  const gateway = new FakeIssuedInvoiceGateway()
  gateway.documentContext = pendingContext({ documentType: 'XML' })
  const provider = new FakeIssuedInvoiceProvider()
  provider.documentOutcome = {
    kind: 'success',
    bytes: new TextEncoder().encode('<HDon/>'),
    providerReference: 'ref-1',
  }
  const storage = createDocumentStorage(new FakeDocumentBucket())
  const handler = createDownloadInvoiceDocumentHandler({ gateway, provider, storage })

  await handler(makeCtx({
    electronic_invoice_id: 'ei-1',
    document_type: 'xml',
    request_id: 'req-doc-1',
  }))

  assertEquals(gateway.loadDocumentCalls, [{
    tenantId: 'tenant-1',
    electronicInvoiceId: 'ei-1',
    documentType: 'XML',
    requestId: 'req-doc-1',
  }])
})

Deno.test('DownloadInvoiceDocumentCommandHandler MISA ambiguous throws and does not record a result', async () => {
  const gateway = new FakeIssuedInvoiceGateway()
  gateway.documentContext = pendingContext()
  const provider = new FakeIssuedInvoiceProvider()
  provider.documentOutcome = {
    kind: 'ambiguous',
    safeErrorCode: 'PROVIDER_TIMEOUT',
  }
  const storage = createDocumentStorage(new FakeDocumentBucket())
  const handler = createDownloadInvoiceDocumentHandler({ gateway, provider, storage })

  await assertRejects(
    () => handler(makeCtx({
      electronic_invoice_id: 'ei-1',
      document_type: 'PDF',
      request_id: 'req-doc-1',
    })),
    Error,
    'PROVIDER_TIMEOUT',
  )

  assertEquals(gateway.documentResults.length, 0)
})

Deno.test('DownloadInvoiceDocumentCommandHandler MISA definite failure records a provider failure source', async () => {
  const gateway = new FakeIssuedInvoiceGateway()
  gateway.documentContext = pendingContext()
  const provider = new FakeIssuedInvoiceProvider()
  provider.documentOutcome = {
    kind: 'definiteFailure',
    failureCode: 'DOCUMENT_EMPTY',
    failureMessage: 'Provider returned no bytes',
  }
  const storage = createDocumentStorage(new FakeDocumentBucket())
  const handler = createDownloadInvoiceDocumentHandler({ gateway, provider, storage })

  await handler(makeCtx({
    electronic_invoice_id: 'ei-1',
    document_type: 'PDF',
    request_id: 'req-doc-1',
  }))

  assertEquals(gateway.documentResults.length, 1)
  const result = gateway.documentResults[0]
  assertEquals(result.status, 'FAILED')
  assertEquals(result.failureSource, 'PROVIDER')
  assertEquals(result.failureCode, 'DOCUMENT_EMPTY')
  assertEquals(result.failureMessage, 'Provider returned no bytes')
})

Deno.test('download stores document then records AVAILABLE with storage reference and checksum', async () => {
  const gateway = new FakeIssuedInvoiceGateway()
  gateway.documentContext = pendingContext()
  const provider = new FakeIssuedInvoiceProvider()
  const bytes = new TextEncoder().encode('%PDF-1.4 test')
  const checksum = await sha256Hex(bytes)
  provider.documentOutcome = {
    kind: 'success',
    bytes,
    providerReference: 'tx-1',
  }
  const bucket = new FakeDocumentBucket()
  const storage = createDocumentStorage(bucket)
  const handler = createDownloadInvoiceDocumentHandler({ gateway, provider, storage })

  await handler(makeCtx({
    electronic_invoice_id: 'ei-1',
    document_type: 'PDF',
    request_id: 'req-doc-1',
  }))

  const expectedPath = `tenant-1/ei-1/pdf/v1/${checksum}.pdf`
  assertEquals(bucket.objects.has(expectedPath), true)
  assertEquals(gateway.documentResults.length, 1)
  const result = gateway.documentResults[0]
  assertEquals(result.status, 'AVAILABLE')
  assertEquals(result.storageReference, expectedPath)
  assertEquals(result.checksum, checksum)
})

Deno.test('download rejects unknown document type before loading context', async () => {
  const gateway = new FakeIssuedInvoiceGateway()
  const provider = new FakeIssuedInvoiceProvider()
  const storage = createDocumentStorage(new FakeDocumentBucket())
  const handler = createDownloadInvoiceDocumentHandler({ gateway, provider, storage })

  await assertRejects(
    () => handler(makeCtx({
      electronic_invoice_id: 'ei-1',
      document_type: 'DOCX',
      request_id: 'req-doc-1',
    })),
    Error,
    'Unknown document type: DOCX',
  )

  assertEquals(gateway.loadDocumentCalls.length, 0)
})
