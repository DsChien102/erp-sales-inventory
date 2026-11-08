import { assertEquals, assertRejects } from 'jsr:@std/assert@1'
import type { ClaimedCommand, CommandContext } from '../../queue/types.ts'
import { createDocumentStorage } from './document_storage.ts'
import { FakeDocumentBucket } from './fake_bucket.ts'
import {
  FakeIssuedInvoiceGateway,
  FakeIssuedInvoiceProvider,
} from './fake_gateways.ts'
import { createFetchOfficialViewHandler } from './fetch_official_view.ts'
import type { OfficialViewContext } from './gateways.ts'

function makeCtx(payload: Record<string, unknown>, id = 'cmd-1', tenantId = 'tenant-1'): CommandContext {
  const command: ClaimedCommand = {
    commandId: id,
    commandType: 'einvoice.fetch_official_view',
    payload,
    sourceEventId: null,
    enqueuedAt: '2026-11-08T00:00:00Z',
    claimToken: 'tok-1',
    retryCount: 0,
  }
  return { tenantId, command, attemptNumber: 1 }
}

function pendingContext(over: Partial<OfficialViewContext> = {}): OfficialViewContext {
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

Deno.test('FetchOfficialInvoiceViewCommand round-trips without row id', async () => {
  const gateway = new FakeIssuedInvoiceGateway()
  gateway.officialViewContext = pendingContext()
  const provider = new FakeIssuedInvoiceProvider()
  const storage = createDocumentStorage(new FakeDocumentBucket())
  const handler = createFetchOfficialViewHandler({ gateway, provider, storage })

  await handler(makeCtx({
    tenant_id: 'tenant-1',
    electronic_invoice_id: 'ei-1',
    request_id: 'req-1',
    correlation_id: 'corr-1',
  }))

  assertEquals(gateway.loadOfficialViewCalls, [{
    tenantId: 'tenant-1',
    electronicInvoiceId: 'ei-1',
    requestId: 'req-1',
  }])
})

Deno.test('FetchOfficialInvoiceViewCommandHandler records AVAILABLE on success without an interaction log', async () => {
  const gateway = new FakeIssuedInvoiceGateway()
  gateway.officialViewContext = pendingContext()
  const provider = new FakeIssuedInvoiceProvider()
  provider.officialOutcome = {
    kind: 'success',
    viewerUrl: 'https://viewer.example/invoice',
    expiresAt: new Date(Date.UTC(2026, 7, 31, 9, 5)),
    providerReference: 'tx-1',
  }
  const storage = createDocumentStorage(new FakeDocumentBucket())
  const handler = createFetchOfficialViewHandler({ gateway, provider, storage })

  await handler(makeCtx({
    electronic_invoice_id: 'ei-1',
    request_id: 'req-1',
  }))

  assertEquals(provider.fetchOfficialViewCalls, 1)
  assertEquals(gateway.officialViewResults.length, 1)
  const result = gateway.officialViewResults[0]
  assertEquals(result.status, 'AVAILABLE')
  assertEquals(result.viewerUrl, 'https://viewer.example/invoice')
  assertEquals(result.requestId, 'req-1')
})

Deno.test('FetchOfficialInvoiceViewCommandHandler MISA ambiguous throws and does not record a result', async () => {
  const gateway = new FakeIssuedInvoiceGateway()
  gateway.officialViewContext = pendingContext()
  const provider = new FakeIssuedInvoiceProvider()
  provider.officialOutcome = {
    kind: 'ambiguous',
    safeErrorCode: 'PROVIDER_TIMEOUT',
  }
  const storage = createDocumentStorage(new FakeDocumentBucket())
  const handler = createFetchOfficialViewHandler({ gateway, provider, storage })

  await assertRejects(
    () => handler(makeCtx({ electronic_invoice_id: 'ei-1', request_id: 'req-1' })),
    Error,
    'PROVIDER_TIMEOUT',
  )

  assertEquals(gateway.officialViewResults.length, 0)
})

Deno.test('FetchOfficialInvoiceViewCommandHandler MISA definite failure records a provider failure source', async () => {
  const gateway = new FakeIssuedInvoiceGateway()
  gateway.officialViewContext = pendingContext()
  const provider = new FakeIssuedInvoiceProvider()
  provider.officialOutcome = {
    kind: 'definiteFailure',
    failureCode: 'INVOICE_NOT_FOUND',
    failureMessage: 'Invoice missing at provider',
    providerReference: null,
  }
  const storage = createDocumentStorage(new FakeDocumentBucket())
  const handler = createFetchOfficialViewHandler({ gateway, provider, storage })

  await handler(makeCtx({ electronic_invoice_id: 'ei-1', request_id: 'req-1' }))

  assertEquals(gateway.officialViewResults.length, 1)
  const result = gateway.officialViewResults[0]
  assertEquals(result.status, 'FAILED')
  assertEquals(result.failureSource, 'PROVIDER')
  assertEquals(result.failureCode, 'INVOICE_NOT_FOUND')
  assertEquals(result.failureMessage, 'Invoice missing at provider')
})

Deno.test('fetch official view skips when operation is no longer PENDING', async () => {
  const gateway = new FakeIssuedInvoiceGateway()
  gateway.officialViewContext = pendingContext({ status: 'AVAILABLE' })
  const provider = new FakeIssuedInvoiceProvider()
  const storage = createDocumentStorage(new FakeDocumentBucket())
  const handler = createFetchOfficialViewHandler({ gateway, provider, storage })

  await handler(makeCtx({ electronic_invoice_id: 'ei-1', request_id: 'req-1' }))

  assertEquals(provider.fetchOfficialViewCalls, 0)
  assertEquals(gateway.officialViewResults.length, 0)
})
