import { assertEquals, assertRejects } from 'jsr:@std/assert@1'
import { FakeDeliveryGateway } from './fake_gateways.ts'
import type { DeliveryResultRecord } from './gateways.ts'
import { recordDeliveryResult } from './record_delivery_result.ts'

Deno.test('RecordDeliveryResultCommandValidator accepts typed evidence command', async () => {
  const gateway = new FakeDeliveryGateway()
  const record: DeliveryResultRecord = {
    tenantId: 'tenant-1',
    deliveryId: 'del-1',
    retryCount: 0,
    expectedDeliveryVersion: 1,
    evidence: {
      kind: 'SUCCESS',
      providerReference: 'misa-tx-1',
    },
  }

  await recordDeliveryResult(gateway, record)
  assertEquals(gateway.results.length, 1)
  assertEquals(gateway.results[0], record)
})

Deno.test('RecordDeliveryResultCommandValidator rejects retryCount outside 0-2', async () => {
  const gateway = new FakeDeliveryGateway()
  const record: DeliveryResultRecord = {
    tenantId: 'tenant-1',
    deliveryId: 'del-1',
    retryCount: 3,
    expectedDeliveryVersion: 1,
    evidence: {
      kind: 'UNDETERMINED',
      safeCode: 'PROVIDER_TIMEOUT',
    },
  }

  await assertRejects(
    () => recordDeliveryResult(gateway, record),
    Error,
    'retryCount must be between 0 and 2',
  )
  assertEquals(gateway.results.length, 0)
})

Deno.test('RecordDeliveryResultCommandHandler forwards DeliveryResultRecord to gateway', async () => {
  const gateway = new FakeDeliveryGateway()
  const record: DeliveryResultRecord = {
    tenantId: 'tenant-1',
    deliveryId: 'del-1',
    retryCount: 1,
    expectedDeliveryVersion: 3,
    evidence: {
      kind: 'RETRYABLE_FAILURE',
      safeCode: 'HTTP_429',
    },
  }

  await recordDeliveryResult(gateway, record)

  assertEquals(gateway.results.length, 1)
  const last = gateway.results[0]
  assertEquals(last.tenantId, 'tenant-1')
  assertEquals(last.deliveryId, 'del-1')
  assertEquals(last.retryCount, 1)
  assertEquals(last.expectedDeliveryVersion, 3)
  assertEquals(last.evidence.kind, 'RETRYABLE_FAILURE')
  assertEquals(last.evidence.safeCode, 'HTTP_429')
})
