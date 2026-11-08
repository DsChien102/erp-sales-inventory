import { assertEquals } from 'jsr:@std/assert@1'
import type { ClaimedCommand } from '../../queue/types.ts'
import { buildDeadLetters, type HandlerDeps } from '../registry.ts'
import { createIssuedInvoiceDeadLetters } from './dead_letters.ts'
import { FakeIssuedInvoiceGateway } from './fake_gateways.ts'
import type { DocumentContext, OfficialViewContext } from './gateways.ts'

function cmd(
  commandType: string,
  payload: Record<string, unknown>,
  id = 'cmd-1',
): ClaimedCommand {
  return {
    commandId: id,
    commandType,
    payload,
    sourceEventId: null,
    enqueuedAt: '2026-11-08T00:00:00Z',
    claimToken: 'tok-1',
    retryCount: 1,
  }
}

function pendingOfficialContext(
  over: Partial<OfficialViewContext> = {},
): OfficialViewContext {
  return {
    tenantId: 'tenant-1',
    electronicInvoiceId: 'ei-1',
    requestId: 'req-1',
    status: 'PENDING',
    providerConnectionId: 'conn-1',
    providerInvoiceReference: 'ref-1',
    invoiceSeries: '1C26TYY',
    ...over,
  }
}

function pendingDocContext(
  over: Partial<DocumentContext> = {},
): DocumentContext {
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

Deno.test('official view dead letter records CHECK_REQUIRED for pending operation', async () => {
  const gateway = new FakeIssuedInvoiceGateway()
  gateway.officialViewContext = pendingOfficialContext()
  const deadLetters = createIssuedInvoiceDeadLetters(gateway)

  const handler = deadLetters['einvoice.fetch_official_view']
  await handler({
    tenantId: 'tenant-1',
    command: cmd('einvoice.fetch_official_view', {
      electronic_invoice_id: 'ei-1',
      request_id: 'req-1',
    }),
    error: new Error('Transport timed out'),
  })

  assertEquals(gateway.officialViewResults.length, 1)
  const result = gateway.officialViewResults[0]
  assertEquals(result.status, 'CHECK_REQUIRED')
  assertEquals(result.failureCode, 'PROVIDER_RESULT_UNDETERMINED')
  assertEquals(result.failureMessage, 'Error: Transport timed out')
  assertEquals(result.failureSource, 'INTERNAL')
})

Deno.test('official view dead letter skips when operation already settled', async () => {
  const gateway = new FakeIssuedInvoiceGateway()
  gateway.officialViewContext = pendingOfficialContext({ status: 'AVAILABLE' })
  const deadLetters = createIssuedInvoiceDeadLetters(gateway)

  const handler = deadLetters['einvoice.fetch_official_view']
  await handler({
    tenantId: 'tenant-1',
    command: cmd('einvoice.fetch_official_view', {
      electronic_invoice_id: 'ei-1',
      request_id: 'req-1',
    }),
    error: new Error('Failed'),
  })

  assertEquals(gateway.officialViewResults.length, 0)
})

Deno.test('document dead letter records CHECK_REQUIRED for pending operation', async () => {
  const gateway = new FakeIssuedInvoiceGateway()
  gateway.documentContext = pendingDocContext({ documentType: 'XML' })
  const deadLetters = createIssuedInvoiceDeadLetters(gateway)

  const handler = deadLetters['einvoice.download_invoice_document']
  await handler({
    tenantId: 'tenant-1',
    command: cmd('einvoice.download_invoice_document', {
      electronic_invoice_id: 'ei-1',
      document_type: 'XML',
      request_id: 'req-doc-1',
    }),
    error: new Error('Download failed'),
  })

  assertEquals(gateway.documentResults.length, 1)
  const result = gateway.documentResults[0]
  assertEquals(result.status, 'CHECK_REQUIRED')
  assertEquals(result.documentType, 'XML')
  assertEquals(result.failureCode, 'PROVIDER_RESULT_UNDETERMINED')
  assertEquals(result.failureMessage, 'Error: Download failed')
  assertEquals(result.failureSource, 'INTERNAL')
})

Deno.test('document dead letter skips unknown document type', async () => {
  const gateway = new FakeIssuedInvoiceGateway()
  const deadLetters = createIssuedInvoiceDeadLetters(gateway)

  const handler = deadLetters['einvoice.download_invoice_document']
  await handler({
    tenantId: 'tenant-1',
    command: cmd('einvoice.download_invoice_document', {
      electronic_invoice_id: 'ei-1',
      document_type: 'DOCX',
      request_id: 'req-doc-1',
    }),
    error: new Error('Unknown'),
  })

  assertEquals(gateway.loadDocumentCalls.length, 0)
  assertEquals(gateway.documentResults.length, 0)
})

Deno.test('registers dead letters for issuance and issued invoice commands', () => {
  const gateway = new FakeIssuedInvoiceGateway()
  const deps = {
    issuance: {
      provider: {} as never,
      gateways: {
        results: { recordDeadLetter: () => Promise.resolve() } as never,
      } as never,
    },
    issuedInvoice: {
      gateway,
      provider: {} as never,
      storage: {} as never,
    },
  } as unknown as HandlerDeps

  const deadLetters = buildDeadLetters(deps)
  assertEquals(Object.keys(deadLetters).sort(), [
    'einvoice.download_invoice_document',
    'einvoice.fetch_official_view',
    'einvoice.preview_invoice',
    'einvoice.publish_invoice',
  ])
})

