import { assertEquals } from 'jsr:@std/assert@1'
import { runInvocation } from '../../queue/processor.ts'
import { cmd, FakeQueueRpc } from '../../queue/test_support.ts'
import { createDeliveryDeadLetters } from './dead_letters.ts'
import {
  FakeDeliveryGateway,
  FakeDeliveryObservationProvider,
  FakeDeliveryProvider,
} from './fake_gateways.ts'
import { createReconcileInvoiceDeliveryHandler } from './reconcile_invoice_delivery.ts'

Deno.test(
  'reconcile exhaustion on third attempt fails and records UNSUPPORTED for camelCase payload',
  async () => {
    const rpc = new FakeQueueRpc()
    rpc.batches = [
      [
        {
          ...cmd('einvoice.reconcile_invoice_delivery', 2),
          payload: {
            tenantId: 'tenant-1',
            reconciliationCaseId: 'case-1',
            checkSequence: 2,
          },
        },
      ],
    ]

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
    gateway.throwOnLoadReconciliationOnce = true

    const provider = new FakeDeliveryProvider()
    const observation = new FakeDeliveryObservationProvider()
    const handler = createReconcileInvoiceDeliveryHandler({
      gateway,
      provider,
      observation,
    })
    const deadLetters = createDeliveryDeadLetters(gateway)

    await runInvocation(
      {
        rpc,
        handlers: { 'einvoice.reconcile_invoice_delivery': handler },
        deadLetters,
      },
      'tenant-1',
    )

    assertEquals(rpc.count('fail'), 1)
    assertEquals(gateway.checks.length, 1)
    assertEquals(
      gateway.checks[0].safeCode,
      'DELIVERY_RECONCILIATION_WORKER_EXHAUSTED',
    )
    assertEquals(gateway.checks[0].expectedCaseVersion, 4)
  },
)
