import { assertEquals } from 'jsr:@std/assert@1'
import type { ClaimedCommand, CommandContext } from '../../queue/types.ts'
import {
  FakeDeliveryGateway,
  FakeDeliveryObservationProvider,
} from './fake_gateways.ts'
import type { DeliveryDeps, ReconciliationContext } from './gateways.ts'
import { createReconcileInvoiceDeliveryHandler } from './reconcile_invoice_delivery.ts'

function context(over: Partial<ReconciliationContext> = {}): ReconciliationContext {
  return {
    tenantId: 'tenant-1',
    reconciliationCaseId: 'case-1',
    deliveryId: 'del-1',
    providerConnectionId: 'conn-1',
    supportsDeliveryResultObservation: false,
    checkSequence: 1,
    caseVersion: 0,
    providerDeliveryReference: null,
    ...over,
  }
}

function commandContext(checkSequence = 1): CommandContext {
  const command: ClaimedCommand = {
    commandId: 'cmd-reconcile-1',
    commandType: 'einvoice.reconcile_invoice_delivery',
    payload: {
      tenant_id: 'tenant-1',
      reconciliation_case_id: 'case-1',
      check_sequence: checkSequence,
    },
    sourceEventId: null,
    enqueuedAt: '2026-11-08T00:00:00Z',
    claimToken: 'tok-1',
    retryCount: 0,
  }
  return {
    tenantId: 'tenant-1',
    attemptNumber: 1,
    command,
  }
}

Deno.test('ReconcileInvoiceDeliveryCommandHandler missing or stale case is a no-op', async () => {
  const gateway = new FakeDeliveryGateway()
  gateway.reconciliationContext = null
  const observation = new FakeDeliveryObservationProvider()
  const deps: DeliveryDeps = {
    gateway,
    provider: {} as never,
    observation,
  }
  const handler = createReconcileInvoiceDeliveryHandler(deps)

  await handler(commandContext())

  assertEquals(observation.observeCalls, 0)
  assertEquals(gateway.checks.length, 0)
})

Deno.test(
  'ReconcileInvoiceDeliveryCommandHandler unsupported capability records unsupported without provider calls',
  async () => {
    const gateway = new FakeDeliveryGateway()
    gateway.reconciliationContext = context({
      supportsDeliveryResultObservation: false,
    })
    const observation = new FakeDeliveryObservationProvider()
    const deps: DeliveryDeps = {
      gateway,
      provider: {} as never,
      observation,
    }
    const handler = createReconcileInvoiceDeliveryHandler(deps)

    await handler(commandContext())

    assertEquals(observation.observeCalls, 0)
    assertEquals(gateway.checks.length, 1)
    const record = gateway.checks[0]
    assertEquals(record.kind, 'UNSUPPORTED')
    assertEquals(record.safeCode, 'DELIVERY_RESULT_OBSERVATION_UNSUPPORTED')
    assertEquals(record.checkSequence, 1)
    assertEquals(record.expectedCaseVersion, 0)
  },
)

Deno.test('ReconcileInvoiceDeliveryCommandHandler supported capability observes once and records the check', async () => {
  const gateway = new FakeDeliveryGateway()
  gateway.reconciliationContext = context({
    supportsDeliveryResultObservation: true,
  })
  const observation = new FakeDeliveryObservationProvider()
  observation.outcome = {
    kind: 'succeeded',
    providerReference: 'prov-del-1',
  }
  const deps: DeliveryDeps = {
    gateway,
    provider: {} as never,
    observation,
  }
  const handler = createReconcileInvoiceDeliveryHandler(deps)

  await handler(commandContext())

  assertEquals(observation.observeCalls, 1)
  assertEquals(observation.lastContext?.deliveryId, 'del-1')
  assertEquals(gateway.checks.length, 1)
  assertEquals(gateway.checks[0].kind, 'SUCCESS')
  assertEquals(gateway.checks[0].providerReference, 'prov-del-1')
})

Deno.test('ReconcileInvoiceDeliveryCommandHandler terminal definite failure records resolution check', async () => {
  const gateway = new FakeDeliveryGateway()
  gateway.reconciliationContext = context({
    supportsDeliveryResultObservation: true,
  })
  const observation = new FakeDeliveryObservationProvider()
  observation.outcome = {
    kind: 'definiteFailure',
    safeCode: 'PROVIDER_DELIVERY_REJECTED',
  }
  const deps: DeliveryDeps = {
    gateway,
    provider: {} as never,
    observation,
  }
  const handler = createReconcileInvoiceDeliveryHandler(deps)

  await handler(commandContext())

  assertEquals(gateway.checks.length, 1)
  assertEquals(gateway.checks[0].kind, 'DEFINITE_FAILURE')
  assertEquals(gateway.checks[0].safeCode, 'PROVIDER_DELIVERY_REJECTED')
})

Deno.test('ReconcileInvoiceDeliveryCommandHandler undetermined observation continues the same case', async () => {
  const gateway = new FakeDeliveryGateway()
  gateway.reconciliationContext = context({
    supportsDeliveryResultObservation: true,
    checkSequence: 2,
  })
  const observation = new FakeDeliveryObservationProvider()
  observation.outcome = {
    kind: 'undetermined',
    safeCode: 'PROVIDER_DELIVERY_PENDING',
  }
  const deps: DeliveryDeps = {
    gateway,
    provider: {} as never,
    observation,
  }
  const handler = createReconcileInvoiceDeliveryHandler(deps)

  await handler(commandContext(2))

  assertEquals(observation.observeCalls, 1)
  assertEquals(gateway.checks.length, 1)
  assertEquals(gateway.checks[0].kind, 'UNDETERMINED')
  assertEquals(gateway.checks[0].checkSequence, 2)
  assertEquals(gateway.checks[0].safeCode, 'PROVIDER_DELIVERY_PENDING')
})
