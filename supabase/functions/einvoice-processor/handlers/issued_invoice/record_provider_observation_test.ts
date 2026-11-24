import { assertEquals, assertRejects } from 'jsr:@std/assert@1'
import { FakeIssuedInvoiceGateway } from './fake_gateways.ts'
import { recordProviderObservation } from './record_provider_observation.ts'

Deno.test('RecordProviderObservationCommandHandler delegates typed record to command gateway', async () => {
  const gateway = new FakeIssuedInvoiceGateway()
  const observedAt = new Date(Date.UTC(2026, 7, 31, 9))

  await recordProviderObservation(gateway, {
    tenantId: 'tenant-1',
    electronicInvoiceId: 'invoice-1',
    providerStateCode: 'NOT_FOUND',
    safeDescription: 'PROVIDER_STATUS_NOT_FOUND',
    providerReference: 'tx-1',
    observedAt,
    deduplicationKey: 'provider_observation:cmd-1',
    detailsSnapshot: { transactionId: 'tx-1' },
    correlationId: 'corr-1',
  })

  assertEquals(gateway.observationRecords.length, 1)
  const record = gateway.observationRecords[0]
  assertEquals(record.electronicInvoiceId, 'invoice-1')
  assertEquals(record.providerStateCode, 'NOT_FOUND')
  assertEquals(record.safeDescription, 'PROVIDER_STATUS_NOT_FOUND')
  assertEquals(record.deduplicationKey, 'provider_observation:cmd-1')
  assertEquals(record.correlationId, 'corr-1')
})

Deno.test('RecordProviderObservationCommandValidator rejects blank correlation id', async () => {
  const gateway = new FakeIssuedInvoiceGateway()

  await assertRejects(
    () =>
      recordProviderObservation(gateway, {
        tenantId: 'tenant-1',
        electronicInvoiceId: 'invoice-1',
        providerStateCode: 'PS_1_ES_2',
        observedAt: new Date(Date.UTC(2026, 7, 31, 9)),
        deduplicationKey: 'provider_observation:cmd-1',
        detailsSnapshot: {},
        correlationId: '  ',
      }),
    Error,
    'correlationId is required',
  )
})

Deno.test('RecordProviderObservationCommandValidator rejects non-allow-listed details snapshot keys', async () => {
  const gateway = new FakeIssuedInvoiceGateway()

  await assertRejects(
    () =>
      recordProviderObservation(gateway, {
        tenantId: 'tenant-1',
        electronicInvoiceId: 'invoice-1',
        providerStateCode: 'PS_1_ES_2',
        observedAt: new Date(Date.UTC(2026, 7, 31, 9)),
        deduplicationKey: 'provider_observation:cmd-1',
        detailsSnapshot: { rawPayload: 'secret' },
        correlationId: 'corr-1',
      }),
    Error,
    'detailsSnapshot key not allowed: rawPayload',
  )
})

