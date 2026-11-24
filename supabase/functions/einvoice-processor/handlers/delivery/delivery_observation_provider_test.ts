import { assertEquals } from 'jsr:@std/assert@1'
import { createMisaDeliveryObservationProvider } from './delivery_observation_provider.ts'

Deno.test('MeInvoiceDeliveryObservationProviderAdapter returns unsupported without HTTP or getStatus', async () => {
  const provider = createMisaDeliveryObservationProvider()

  const outcome = await provider.observe({
    tenantId: 'tenant-1',
    reconciliationCaseId: 'case-1',
    deliveryId: 'del-1',
    providerConnectionId: 'conn-1',
    providerDeliveryReference: 'ref-1',
  })

  assertEquals(outcome, { kind: 'unsupported' })
})

Deno.test('MeInvoiceDeliveryObservationProviderAdapter adapter source never references getStatus or sendEmail', async () => {
  // Behavioral gate: adapter is pure unsupported and takes 0 constructor parameters.
  assertEquals(createMisaDeliveryObservationProvider.length, 0)
  const provider = createMisaDeliveryObservationProvider()
  const outcome = await provider.observe({
    tenantId: 't',
    reconciliationCaseId: 'c',
    deliveryId: 'd',
    providerConnectionId: 'p',
    providerDeliveryReference: null,
  })
  assertEquals(outcome, { kind: 'unsupported' })
})
