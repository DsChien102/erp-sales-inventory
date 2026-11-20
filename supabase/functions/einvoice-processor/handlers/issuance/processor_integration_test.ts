import { assertEquals } from 'jsr:@std/assert@1'
import { runInvocation } from '../../queue/processor.ts'
import { FakeQueueRpc, cmd } from '../../queue/test_support.ts'
import { createIssuanceDeadLetters } from './dead_letters.ts'
import { FakeIssuanceGateways, FakeIssuanceProvider } from './fake_gateways.ts'
import { createPublishInvoiceHandler } from './publish_invoice.ts'

const validPayload = {
  tenant_id: 'tenant-1',
  attempt_id: 'att-1',
  idempotency_key: '88d18970-380a-4138-bbce-e25049ca9e3c',
  payload_hash: 'hash-1',
  canonical_invoice: {
    refId: 'ref-1',
    invSeries: '1C26TYY',
    totalAmount: 100,
    originalInvoiceDetail: [{}],
  },
}

Deno.test('publish lease busy reschedules by retry_after without consuming an attempt', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  gateways.lease.leaseOutcome = { kind: 'busy', retryAfterSeconds: 17 }

  const handlers = {
    'einvoice.publish_invoice': createPublishInvoiceHandler({ provider, gateways }),
  }
  const deadLetters = createIssuanceDeadLetters(gateways)
  const rpc = new FakeQueueRpc()
  rpc.batches = [[{ ...cmd('einvoice.publish_invoice', 0), payload: validPayload }]]

  await runInvocation({ rpc, handlers, deadLetters }, 'tenant-1')

  assertEquals(rpc.count('reschedule'), 1)
  assertEquals(rpc.calls.find((c) => c[0] === 'reschedule'), ['reschedule', 'tenant-1', 'c1', 17])
  assertEquals(rpc.count('retryOrDeadLetter'), 0)
  assertEquals(rpc.count('fail'), 0)
  assertEquals(gateways.results.deadLetterCalls.length, 0)
})

Deno.test('publish retryable rejection completes the command without dead-letter', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  gateways.lease.leaseOutcome = {
    kind: 'acquired',
    providerConnectionId: 'c1',
    invoiceSeries: '1C26TYY',
    leaseVersion: 1,
  }
  provider.publishOutcome = {
    kind: 'retryableRejection',
    providerCode: 'InvoiceNumberNotCotinuous',
    providerMessage: 'Number not continuous',
    retryAfterSeconds: 5,
    safeProviderEvidence: {
      refId: '88d18970-380a-4138-bbce-e25049ca9e3c',
    },
  }

  const handlers = {
    'einvoice.publish_invoice': createPublishInvoiceHandler({ provider, gateways }),
  }
  const deadLetters = createIssuanceDeadLetters(gateways)
  const rpc = new FakeQueueRpc()
  rpc.batches = [[{ ...cmd('einvoice.publish_invoice', 0), payload: validPayload }]]

  await runInvocation({ rpc, handlers, deadLetters }, 'tenant-1')

  assertEquals(gateways.results.retryableRejectionCalls.length, 1)
  assertEquals(rpc.count('complete'), 1)
  assertEquals(gateways.results.deadLetterCalls.length, 0)
  assertEquals(rpc.count('retryOrDeadLetter'), 0)
})

Deno.test('publish failure on third attempt dead-letters to recordPublishCommandDeadLetter', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  gateways.lease.leaseOutcome = {
    kind: 'acquired',
    providerConnectionId: 'c1',
    invoiceSeries: '1C26TYY',
    leaseVersion: 1,
  }
  provider.throwOnPublish = new Error('DB error or network failure')

  const handlers = {
    'einvoice.publish_invoice': createPublishInvoiceHandler({ provider, gateways }),
  }
  const deadLetters = createIssuanceDeadLetters(gateways)
  const rpc = new FakeQueueRpc()
  rpc.disposition = 'DEAD_LETTER'
  rpc.batches = [[{ ...cmd('einvoice.publish_invoice', 2), payload: validPayload }]]

  await runInvocation({ rpc, handlers, deadLetters }, 'tenant-1')

  assertEquals(gateways.results.deadLetterCalls.length, 1)
  assertEquals(gateways.results.deadLetterCalls[0].attemptId, 'att-1')
  assertEquals(
    gateways.results.deadLetterCalls[0].reasonCode.includes('DB error or network failure'),
    true,
  )
})
