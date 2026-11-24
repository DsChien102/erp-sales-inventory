import { assertEquals, assertRejects } from 'jsr:@std/assert@1'
import { maxAttemptsFor } from '../../queue/attempt_policy.ts'
import { runInvocation } from '../../queue/processor.ts'
import { cmd, FakeQueueRpc } from '../../queue/test_support.ts'
import type { ClaimedCommand } from '../../queue/types.ts'
import { createDeliveryDeadLetters } from './dead_letters.ts'
import {
  FakeDeliveryGateway,
  FakeDeliveryObservationProvider,
  FakeDeliveryProvider,
} from './fake_gateways.ts'
import { createSendInvoiceEmailHandler } from './send_invoice_email.ts'

Deno.test('Einvoice S5 delivery dead-letter attempt policy is max-three for send_invoice_email', () => {
  assertEquals(maxAttemptsFor('einvoice.send_invoice_email'), 3)
})

Deno.test(
  'Einvoice S5 delivery dead-letter DeliveryCommandDeadLetterHandler records WORKER_EXHAUSTED_BEFORE_DISPATCH',
  async () => {
    const gateway = new FakeDeliveryGateway()
    const deadLetters = createDeliveryDeadLetters(gateway)

    const command: ClaimedCommand = {
      commandId: 'cmd-1',
      commandType: 'einvoice.send_invoice_email',
      payload: {
        delivery_id: 'del-queued-1',
        retry_count: 0,
      },
      enqueuedAt: '2026-09-02T00:00:00Z',
      claimToken: 'tok-1',
      retryCount: 3,
      sourceEventId: null,
    }

    await deadLetters['einvoice.send_invoice_email']({
      tenantId: 'tenant-1',
      command,
      error: new Error('exhausted'),
    })

    assertEquals(gateway.deadLetters.length, 1)
    assertEquals(gateway.deadLetters[0].deliveryId, 'del-queued-1')
    assertEquals(gateway.deadLetters[0].retryCount, 0)
    assertEquals(
      gateway.deadLetters[0].safeFailureCode,
      'WORKER_EXHAUSTED_BEFORE_DISPATCH',
    )
  },
)

Deno.test(
  'Einvoice S5 delivery dead-letter legacy camelCase dead-letter identifies attempt after deserialize error',
  async () => {
    const gateway = new FakeDeliveryGateway()
    const deadLetters = createDeliveryDeadLetters(gateway)

    const command: ClaimedCommand = {
      commandId: 'cmd-1',
      commandType: 'einvoice.send_invoice_email',
      payload: {
        tenantId: 'tenant-1',
        deliveryId: 'del-1',
        retryCount: 1,
      },
      enqueuedAt: '2026-09-02T00:00:00Z',
      claimToken: 'tok',
      retryCount: 3,
      sourceEventId: null,
    }

    await deadLetters['einvoice.send_invoice_email']({
      tenantId: 'tenant-1',
      command,
      error: new Error('deserialization'),
    })

    assertEquals(gateway.deadLetters.length, 1)
    assertEquals(gateway.deadLetters[0].retryCount, 1)
  },
)

Deno.test(
  'Einvoice S5 delivery dead-letter max-three exhaustion invokes delivery dead-letter once (SQL classifies QUEUED vs SUBMITTED)',
  async () => {
    const rpc = new FakeQueueRpc()
    rpc.batches = [
      [
        {
          ...cmd('einvoice.send_invoice_email', 2),
          payload: {
            tenant_id: 'tenant-1',
            delivery_id: 'del-1',
            retry_count: 0,
          },
        },
      ],
    ]

    const gateway = new FakeDeliveryGateway()
    gateway.throwOnLoadAttempt = true
    const provider = new FakeDeliveryProvider()
    const observation = new FakeDeliveryObservationProvider()
    const handler = createSendInvoiceEmailHandler({
      gateway,
      provider,
      observation,
    })
    const deadLetters = createDeliveryDeadLetters(gateway)

    await runInvocation(
      {
        rpc,
        handlers: { 'einvoice.send_invoice_email': handler },
        deadLetters,
      },
      'tenant-1',
    )

    assertEquals(rpc.count('fail'), 1)
    assertEquals(rpc.count('retryOrDeadLetter'), 0)
    assertEquals(gateway.deadLetters.length, 1)
    assertEquals(
      gateway.deadLetters[0].safeFailureCode,
      'WORKER_EXHAUSTED_BEFORE_DISPATCH',
    )
  },
)

Deno.test(
  'Einvoice S5 reconciliation registration exhausted reconcile dead-letter records unsupported UNRESOLVED attention path',
  async () => {
    const gateway = new FakeDeliveryGateway()
    gateway.reconciliationContext = {
      tenantId: 'tenant-1',
      reconciliationCaseId: 'case-1',
      deliveryId: 'del-1',
      providerConnectionId: 'conn-1',
      supportsDeliveryResultObservation: false,
      checkSequence: 1,
      caseVersion: 0,
      providerDeliveryReference: null,
    }
    const deadLetters = createDeliveryDeadLetters(gateway)

    const command: ClaimedCommand = {
      commandId: 'cmd-reconcile-1',
      commandType: 'einvoice.reconcile_invoice_delivery',
      payload: {
        reconciliation_case_id: 'case-1',
        check_sequence: 1,
      },
      enqueuedAt: '2026-09-02T00:00:00Z',
      claimToken: 'tok-1',
      retryCount: 3,
      sourceEventId: null,
    }

    await deadLetters['einvoice.reconcile_invoice_delivery']({
      tenantId: 'tenant-1',
      command,
      error: new Error('worker exhausted'),
    })

    assertEquals(gateway.checks.length, 1)
    const check = gateway.checks[0]
    assertEquals(check.kind, 'UNSUPPORTED')
    assertEquals(check.safeCode, 'DELIVERY_RECONCILIATION_WORKER_EXHAUSTED')
    assertEquals(check.reconciliationCaseId, 'case-1')
  },
)

Deno.test(
  'Einvoice S5 reconciliation registration reconcile dead-letter skips when loadContext returns null (not PENDING)',
  async () => {
    const gateway = new FakeDeliveryGateway()
    gateway.reconciliationContext = null
    const deadLetters = createDeliveryDeadLetters(gateway)

    const command: ClaimedCommand = {
      commandId: 'cmd-reconcile-2',
      commandType: 'einvoice.reconcile_invoice_delivery',
      payload: {
        reconciliation_case_id: 'case-2',
        check_sequence: 2,
      },
      enqueuedAt: '2026-09-02T00:00:00Z',
      claimToken: 'tok-2',
      retryCount: 3,
      sourceEventId: null,
    }

    await deadLetters['einvoice.reconcile_invoice_delivery']({
      tenantId: 'tenant-1',
      command,
      error: new Error('worker exhausted'),
    })

    assertEquals(gateway.checks.length, 0)
  },
)

Deno.test('reconcile dead letter reads camelCase payload written by SQL', async () => {
  const gateway = new FakeDeliveryGateway()
  gateway.reconciliationContext = {
    tenantId: 'tenant-1',
    reconciliationCaseId: 'case-1',
    deliveryId: 'del-1',
    providerConnectionId: 'conn-1',
    supportsDeliveryResultObservation: false,
    checkSequence: 2,
    caseVersion: 4,
    providerDeliveryReference: null,
  }
  const deadLetters = createDeliveryDeadLetters(gateway)

  const command: ClaimedCommand = {
    commandId: 'cmd-reconcile-3',
    commandType: 'einvoice.reconcile_invoice_delivery',
    payload: {
      tenantId: 'tenant-1',
      reconciliationCaseId: 'case-1',
      checkSequence: 2,
    },
    enqueuedAt: '2026-09-02T00:00:00Z',
    claimToken: 'tok-3',
    retryCount: 3,
    sourceEventId: null,
  }

  await deadLetters['einvoice.reconcile_invoice_delivery']({
    tenantId: 'tenant-1',
    command,
    error: new Error('exhausted'),
  })

  assertEquals(gateway.checks.length, 1)
  const check = gateway.checks[0]
  assertEquals(check.kind, 'UNSUPPORTED')
  assertEquals(check.safeCode, 'DELIVERY_RECONCILIATION_WORKER_EXHAUSTED')
  assertEquals(check.expectedCaseVersion, 4)
})

Deno.test('delivery dead letter rejects tenant mismatch', async () => {
  const gateway = new FakeDeliveryGateway()
  const deadLetters = createDeliveryDeadLetters(gateway)

  const command: ClaimedCommand = {
    commandId: 'cmd-4',
    commandType: 'einvoice.send_invoice_email',
    payload: {
      tenant_id: 'tenant-2',
      delivery_id: 'del-1',
      retry_count: 0,
    },
    enqueuedAt: '2026-09-02T00:00:00Z',
    claimToken: 'tok-4',
    retryCount: 3,
    sourceEventId: null,
  }

  await assertRejects(
    () =>
      deadLetters['einvoice.send_invoice_email']({
        tenantId: 'tenant-1',
        command,
        error: new Error('exhausted'),
      }),
    Error,
    'Delivery tenant does not match claimed tenant',
  )

  assertEquals(gateway.deadLetters.length, 0)
})
