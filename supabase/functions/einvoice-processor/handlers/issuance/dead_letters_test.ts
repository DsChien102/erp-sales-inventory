import { assertEquals } from 'jsr:@std/assert@1'
import { createIssuanceDeadLetters } from './dead_letters.ts'
import { buildDeadLetters, type HandlerDeps } from '../registry.ts'
import { FakeIssuanceGateways, FakeIssuanceProvider } from './fake_gateways.ts'
import { CanonicalInvoiceIntegrityError } from './errors.ts'
import { cmd } from '../../queue/test_support.ts'

Deno.test('preview dead letter records FAILED with INTERNAL source', async () => {
  const gateways = new FakeIssuanceGateways()
  const handlers = createIssuanceDeadLetters(gateways)
  const deadLetter = handlers['einvoice.preview_invoice']

  await deadLetter({
    tenantId: 'tenant-1',
    command: {
      ...cmd('einvoice.preview_invoice'),
      payload: { sales_order_id: 'order-1', preview_request_id: 'req-1' },
    },
    error: new Error('PROVIDER_UNAVAILABLE'),
  })

  assertEquals(gateways.preview.stored.length, 1)
  assertEquals(gateways.preview.stored[0].status, 'FAILED')
  assertEquals(gateways.preview.stored[0].failureCode, 'PROVIDER_UNAVAILABLE')
  assertEquals(gateways.preview.stored[0].failureSource, 'INTERNAL')
  assertEquals(gateways.preview.stored[0].requestId, 'req-1')
  assertEquals(gateways.preview.stored[0].salesOrderId, 'order-1')
})

Deno.test('preview dead letter ignores a payload without request id or sales order id', async () => {
  const gateways = new FakeIssuanceGateways()
  const handlers = createIssuanceDeadLetters(gateways)
  const deadLetter = handlers['einvoice.preview_invoice']

  await deadLetter({
    tenantId: 'tenant-1',
    command: {
      ...cmd('einvoice.preview_invoice'),
      payload: { sales_order_id: 'order-1' },
    },
    error: new Error('PROVIDER_UNAVAILABLE'),
  })

  assertEquals(gateways.preview.stored.length, 0)
})

Deno.test('publish dead letter with CanonicalInvoiceIntegrityError marks command integrity failure', async () => {
  const gateways = new FakeIssuanceGateways()
  const handlers = createIssuanceDeadLetters(gateways)
  const deadLetter = handlers['einvoice.publish_invoice']

  const integrityError = new CanonicalInvoiceIntegrityError(
    'att-integrity-1',
    'COMMAND_INTEGRITY',
    'CANONICAL_INVALID: missing buyerLegalName',
  )

  await deadLetter({
    tenantId: 'tenant-1',
    command: {
      ...cmd('einvoice.publish_invoice', 2),
      payload: { attempt_id: 'att-integrity-1' },
    },
    error: integrityError,
  })

  assertEquals(gateways.results.commandIntegrityCalls.length, 1)
  assertEquals(gateways.results.commandIntegrityCalls[0].tenantId, 'tenant-1')
  assertEquals(gateways.results.commandIntegrityCalls[0].attemptId, 'att-integrity-1')
  assertEquals(gateways.results.commandIntegrityCalls[0].reasonCode, 'COMMAND_INTEGRITY')
  assertEquals(gateways.results.deadLetterCalls.length, 0)
})

Deno.test('publish dead letter with generic error records publish command dead letter', async () => {
  const gateways = new FakeIssuanceGateways()
  const handlers = createIssuanceDeadLetters(gateways)
  const deadLetter = handlers['einvoice.publish_invoice']

  const genericError = new Error('DB error marking provider call started')

  await deadLetter({
    tenantId: 'tenant-1',
    command: {
      ...cmd('einvoice.publish_invoice', 2),
      payload: { attempt_id: 'att-generic-1' },
    },
    error: genericError,
  })

  assertEquals(gateways.results.deadLetterCalls.length, 1)
  assertEquals(gateways.results.deadLetterCalls[0].tenantId, 'tenant-1')
  assertEquals(gateways.results.deadLetterCalls[0].attemptId, 'att-generic-1')
  assertEquals(gateways.results.deadLetterCalls[0].reasonCode, 'Error: DB error marking provider call started')
  assertEquals(gateways.results.commandIntegrityCalls.length, 0)
})

Deno.test('registers dead letters for preview and publish', () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  const deps = {
    issuance: { provider, gateways },
  } as unknown as HandlerDeps

  const deadLetters = buildDeadLetters(deps)
  assertEquals(Object.keys(deadLetters).sort(), [
    'einvoice.preview_invoice',
    'einvoice.publish_invoice',
  ])
})
