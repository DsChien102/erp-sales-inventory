import { assertEquals, assertRejects } from 'jsr:@std/assert@1'
import type { ClaimedCommand, CommandContext } from '../../queue/types.ts'
import {
  FakeDeliveryGateway,
  FakeDeliveryProvider,
} from './fake_gateways.ts'
import type { DeliveryAttemptContext, DeliveryDeps } from './gateways.ts'
import type { DeliveryProviderOutcome } from './outcomes.ts'
import { createSendInvoiceEmailHandler } from './send_invoice_email.ts'

function context(): DeliveryAttemptContext {
  return {
    tenantId: 'tenant-1',
    deliveryId: 'del-1',
    retryCount: 0,
    deliveryVersion: 1,
    providerConnectionId: 'conn-1',
    providerTransactionId: 'tx-inv-1',
    invoiceSeries: '1C25TYY',
    recipientEmail: 'buyer@test.com',
    recipientName: 'Buyer',
  }
}

function commandContext(payload: Record<string, unknown> = {
  tenant_id: 'tenant-1',
  delivery_id: 'del-1',
  retry_count: 0,
}): CommandContext {
  const command: ClaimedCommand = {
    commandId: 'cmd-1',
    commandType: 'einvoice.send_invoice_email',
    payload,
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

Deno.test('SendInvoiceEmailCommandHandler prepare branches skip never calls provider or records result', async () => {
  const gateway = new FakeDeliveryGateway()
  gateway.attemptContext = context()
  gateway.prepareResult = { action: 'SKIP' }
  const provider = new FakeDeliveryProvider()
  const deps: DeliveryDeps = {
    gateway,
    provider,
    observation: {} as never,
  }
  const handler = createSendInvoiceEmailHandler(deps)

  await handler(commandContext())

  assertEquals(provider.sendCalls, 0)
  assertEquals(gateway.results.length, 0)
})

Deno.test('SendInvoiceEmailCommandHandler prepare branches recordUnknown records undetermined without HTTP', async () => {
  const gateway = new FakeDeliveryGateway()
  gateway.attemptContext = context()
  gateway.prepareResult = {
    action: 'RECORD_UNKNOWN',
    deliveryVersion: 1,
  }
  const provider = new FakeDeliveryProvider()
  const deps: DeliveryDeps = {
    gateway,
    provider,
    observation: {} as never,
  }
  const handler = createSendInvoiceEmailHandler(deps)

  await handler(commandContext())

  assertEquals(provider.sendCalls, 0)
  assertEquals(gateway.results.length, 1)
  assertEquals(gateway.results[0].evidence.kind, 'UNDETERMINED')
  assertEquals(gateway.results[0].evidence.safeCode, 'DISPATCH_STATE_UNCERTAIN')
  assertEquals(gateway.results[0].evidence.failureSource, 'INTERNAL')
  assertEquals(gateway.results[0].retryCount, 0)
})

Deno.test('SendInvoiceEmailCommandHandler prepare branches callProvider calls provider once and records success', async () => {
  const gateway = new FakeDeliveryGateway()
  gateway.attemptContext = context()
  gateway.prepareResult = {
    action: 'CALL_PROVIDER',
    deliveryVersion: 1,
    providerContext: {
      tenantId: 'tenant-1',
      providerConnectionId: 'conn-1',
      providerTransactionId: 'tx-inv-1',
      invoiceSeries: '1C25TYY',
      recipientEmail: 'buyer@test.com',
      recipientName: 'Buyer',
    },
  }
  const provider = new FakeDeliveryProvider()
  provider.outcome = {
    kind: 'succeeded',
    providerReference: 'misa-email-1',
  }
  const deps: DeliveryDeps = {
    gateway,
    provider,
    observation: {} as never,
  }
  const handler = createSendInvoiceEmailHandler(deps)

  await handler(commandContext())

  assertEquals(provider.sendCalls, 1)
  assertEquals(gateway.results.length, 1)
  assertEquals(gateway.results[0].evidence.kind, 'SUCCESS')
  assertEquals(gateway.results[0].evidence.providerReference, 'misa-email-1')
  assertEquals(gateway.results[0].evidence.failureSource, null)
})

async function runOutcome(outcome: DeliveryProviderOutcome) {
  const gateway = new FakeDeliveryGateway()
  gateway.attemptContext = context()
  gateway.prepareResult = {
    action: 'CALL_PROVIDER',
    deliveryVersion: 2,
    providerContext: {
      tenantId: 'tenant-1',
      providerConnectionId: 'conn-1',
      providerTransactionId: 'tx-inv-1',
      invoiceSeries: '1C25TYY',
      recipientEmail: 'buyer@test.com',
      recipientName: 'Buyer',
    },
  }
  const provider = new FakeDeliveryProvider()
  provider.outcome = outcome
  const deps: DeliveryDeps = {
    gateway,
    provider,
    observation: {} as never,
  }
  const handler = createSendInvoiceEmailHandler(deps)

  await handler(commandContext())

  assertEquals(gateway.results.length, 1)
  return gateway.results[0]
}

Deno.test('SendInvoiceEmailCommandHandler provider outcomes maps definite failure evidence', async () => {
  const recorded = await runOutcome({
    kind: 'definiteFailure',
    safeErrorCode: 'AUTH_REJECTED',
  })
  assertEquals(recorded.evidence.kind, 'DEFINITE_FAILURE')
  assertEquals(recorded.evidence.safeCode, 'AUTH_REJECTED')
  assertEquals(recorded.evidence.failureSource, 'PROVIDER')
})

Deno.test('SendInvoiceEmailCommandHandler provider outcomes maps retryable failure evidence', async () => {
  const recorded = await runOutcome({
    kind: 'retryableFailure',
    safeErrorCode: 'HTTP_429',
  })
  assertEquals(recorded.evidence.kind, 'RETRYABLE_FAILURE')
  assertEquals(recorded.evidence.safeCode, 'HTTP_429')
  assertEquals(recorded.evidence.failureSource, 'PROVIDER')
})

Deno.test('SendInvoiceEmailCommandHandler provider outcomes maps undetermined evidence', async () => {
  const recorded = await runOutcome({
    kind: 'undetermined',
    safeErrorCode: 'PROVIDER_TIMEOUT',
  })
  assertEquals(recorded.evidence.kind, 'UNDETERMINED')
  assertEquals(recorded.evidence.safeCode, 'PROVIDER_TIMEOUT')
  assertEquals(recorded.evidence.failureSource, 'PROVIDER')
})

Deno.test('SendInvoiceEmailCommandHandler provider outcomes transport failure records undetermined internal evidence', async () => {
  const gateway = new FakeDeliveryGateway()
  gateway.attemptContext = context()
  gateway.prepareResult = {
    action: 'CALL_PROVIDER',
    deliveryVersion: 1,
    providerContext: {
      tenantId: 'tenant-1',
      providerConnectionId: 'conn-1',
      providerTransactionId: 'tx-inv-1',
      invoiceSeries: '1C25TYY',
      recipientEmail: 'buyer@test.com',
      recipientName: 'Buyer',
    },
  }
  const provider = new FakeDeliveryProvider()
  provider.throwOnSend = true
  const deps: DeliveryDeps = {
    gateway,
    provider,
    observation: {} as never,
  }
  const handler = createSendInvoiceEmailHandler(deps)

  await handler(commandContext())

  assertEquals(provider.sendCalls, 1)
  assertEquals(gateway.results.length, 1)
  assertEquals(gateway.results[0].evidence.kind, 'UNDETERMINED')
  assertEquals(gateway.results[0].evidence.safeCode, 'PROVIDER_TRANSPORT_FAILURE')
  assertEquals(gateway.results[0].evidence.failureSource, 'INTERNAL')
})

Deno.test('SendInvoiceEmailCommandHandler provider outcomes record failure rethrows and the next run records UNKNOWN', async () => {
  const gateway = new FakeDeliveryGateway()
  gateway.attemptContext = context()
  gateway.prepareResult = {
    action: 'CALL_PROVIDER',
    deliveryVersion: 1,
    providerContext: {
      tenantId: 'tenant-1',
      providerConnectionId: 'conn-1',
      providerTransactionId: 'tx-inv-1',
      invoiceSeries: '1C25TYY',
      recipientEmail: 'buyer@test.com',
      recipientName: 'Buyer',
    },
  }
  gateway.throwOnRecord = true
  const provider = new FakeDeliveryProvider()
  provider.outcome = {
    kind: 'succeeded',
    providerReference: 'misa-email-1',
  }
  const deps: DeliveryDeps = {
    gateway,
    provider,
    observation: {} as never,
  }
  const handler = createSendInvoiceEmailHandler(deps)

  await assertRejects(() => handler(commandContext()))
  assertEquals(provider.sendCalls, 1)
  assertEquals(gateway.results.length, 1)
  assertEquals(gateway.results[0].evidence.kind, 'SUCCESS')

  gateway.prepareResult = {
    action: 'RECORD_UNKNOWN',
    deliveryVersion: 2,
  }
  gateway.throwOnRecord = false
  await handler(commandContext())

  assertEquals(provider.sendCalls, 1)
  assertEquals(gateway.results.length, 2)
  assertEquals(gateway.results[1].evidence.kind, 'UNDETERMINED')
  assertEquals(gateway.results[1].evidence.safeCode, 'DISPATCH_STATE_UNCERTAIN')
  assertEquals(gateway.results[1].expectedDeliveryVersion, 2)
})

Deno.test('send handler passes provider call reference to prepare', async () => {
  const gateway = new FakeDeliveryGateway()
  gateway.attemptContext = context()
  gateway.prepareResult = { action: 'SKIP' }
  const provider = new FakeDeliveryProvider()
  const deps: DeliveryDeps = {
    gateway,
    provider,
    observation: {} as never,
  }
  const handler = createSendInvoiceEmailHandler(deps)

  await handler(commandContext())

  assertEquals(gateway.prepareCalls.length, 1)
  assertEquals(
    gateway.prepareCalls[0].requestReference,
    '7d99ddea-18d5-bea4-c874-7b0de44f56a5',
  )
})

Deno.test('send handler returns quietly when attempt context is missing', async () => {
  const gateway = new FakeDeliveryGateway()
  gateway.attemptContext = null
  const provider = new FakeDeliveryProvider()
  const deps: DeliveryDeps = {
    gateway,
    provider,
    observation: {} as never,
  }
  const handler = createSendInvoiceEmailHandler(deps)

  await handler(commandContext())

  assertEquals(gateway.prepareCalls.length, 0)
  assertEquals(provider.sendCalls, 0)
})

Deno.test('send handler rejects invalid payload before loading context', async () => {
  const gateway = new FakeDeliveryGateway()
  const provider = new FakeDeliveryProvider()
  const deps: DeliveryDeps = {
    gateway,
    provider,
    observation: {} as never,
  }
  const handler = createSendInvoiceEmailHandler(deps)

  await assertRejects(
    () =>
      handler(commandContext({
        tenant_id: 'tenant-1',
        delivery_id: 'del-1',
        retry_count: 3,
      })),
    Error,
    'Invalid or missing delivery identity: retry_count',
  )

  assertEquals(gateway.calls.length, 0)
})
