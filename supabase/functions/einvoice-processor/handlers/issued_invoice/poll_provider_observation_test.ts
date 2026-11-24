import { assertEquals, assertRejects } from 'jsr:@std/assert@1'
import type { ClaimedCommand, CommandContext } from '../../queue/types.ts'
import { createDocumentStorage } from './document_storage.ts'
import { FakeDocumentBucket } from './fake_bucket.ts'
import {
  FakeIssuedInvoiceGateway,
  FakeIssuedInvoiceProvider,
} from './fake_gateways.ts'
import type { ObservationContext } from './gateways.ts'
import { createPollProviderObservationHandler } from './poll_provider_observation.ts'
import { ProviderCallAmbiguousError } from './errors.ts'

function makeCtx(payload: Record<string, unknown>, id = 'cmd-obs-1', tenantId = 'tenant-1'): CommandContext {
  const command: ClaimedCommand = {
    commandId: id,
    commandType: 'einvoice.poll_provider_observation',
    payload,
    sourceEventId: null,
    enqueuedAt: '2026-11-08T00:00:00Z',
    claimToken: 'tok-1',
    retryCount: 0,
  }
  return { tenantId, command, attemptNumber: 1 }
}

function pendingContext(over: Partial<ObservationContext> = {}): ObservationContext {
  return {
    commandId: 'cmd-obs-1',
    tenantId: 'tenant-1',
    electronicInvoiceId: 'ei-1',
    providerConnectionId: 'conn-1',
    providerInvoiceReference: 'ref-1',
    invoiceSeries: '1C26TYY',
    triggerId: 'trigger-1',
    correlationId: 'corr-1',
    ...over,
  }
}

Deno.test('PollProviderObservationCommand rejects blank triggerId', async () => {
  const gateway = new FakeIssuedInvoiceGateway()
  const provider = new FakeIssuedInvoiceProvider()
  const storage = createDocumentStorage(new FakeDocumentBucket())
  const handler = createPollProviderObservationHandler({ gateway, provider, storage })

  await assertRejects(
    () => handler(makeCtx({
      tenant_id: 'tenant-1',
      provider_connection_id: 'conn-1',
      electronic_invoice_id: 'ei-1',
      trigger_id: '  ',
      correlation_id: 'corr-1',
    })),
    Error,
    'trigger_id must not be blank',
  )

  assertEquals(gateway.loadObservationCalls.length, 0)
})

Deno.test('poll observation records found fact with command-scoped deduplication key', async () => {
  const gateway = new FakeIssuedInvoiceGateway()
  gateway.observationContext = pendingContext()
  const provider = new FakeIssuedInvoiceProvider()
  const observedAt = new Date(Date.UTC(2026, 7, 31, 9))
  provider.observationOutcome = {
    kind: 'found',
    providerStateCode: 'PS_1_ES_2',
    safeDescription: 'PUBLISHED',
    observedAt,
    detailsSnapshot: { publishStatus: 1, eInvoiceStatus: 2 },
    providerReference: 'tx-1',
  }
  const storage = createDocumentStorage(new FakeDocumentBucket())
  const handler = createPollProviderObservationHandler({ gateway, provider, storage })

  await handler(makeCtx({
    trigger_id: 'trigger-1',
  }, 'cmd-obs-42'))

  assertEquals(gateway.observationRecords.length, 1)
  const rec = gateway.observationRecords[0]
  assertEquals(rec.electronicInvoiceId, 'ei-1')
  assertEquals(rec.providerStateCode, 'PS_1_ES_2')
  assertEquals(rec.safeDescription, 'PUBLISHED')
  assertEquals(rec.deduplicationKey, 'provider_observation:cmd-obs-42')
  assertEquals(rec.correlationId, 'corr-1')
  assertEquals(rec.detailsSnapshot, { publishStatus: 1, eInvoiceStatus: 2 })
})

Deno.test('poll observation does not record when MISA is ambiguous', async () => {
  const gateway = new FakeIssuedInvoiceGateway()
  gateway.observationContext = pendingContext()
  const provider = new FakeIssuedInvoiceProvider()
  provider.observationError = new ProviderCallAmbiguousError(
    'PROVIDER_TIMEOUT',
    'Provider timed out',
  )
  const storage = createDocumentStorage(new FakeDocumentBucket())
  const handler = createPollProviderObservationHandler({ gateway, provider, storage })

  await assertRejects(
    () => handler(makeCtx({ trigger_id: 'trigger-1' })),
    Error,
    'PROVIDER_TIMEOUT',
  )

  assertEquals(gateway.observationRecords.length, 0)
})

Deno.test('poll observation returns quietly when context is missing', async () => {
  const gateway = new FakeIssuedInvoiceGateway()
  gateway.observationContext = null
  const provider = new FakeIssuedInvoiceProvider()
  const storage = createDocumentStorage(new FakeDocumentBucket())
  const handler = createPollProviderObservationHandler({ gateway, provider, storage })

  await handler(makeCtx({ trigger_id: 'trigger-1' }))

  assertEquals(provider.observeCalls, 0)
  assertEquals(gateway.observationRecords.length, 0)
})
