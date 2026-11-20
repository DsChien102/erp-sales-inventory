import { assertEquals, assertNotEquals, assertMatch } from 'jsr:@std/assert@1'
import {
  SALES_ORDER_FINALIZED_EVENT_TYPE,
  AUTO_ISSUANCE_NAMESPACE,
  AUTO_DELIVERY_NAMESPACE,
  autoIssuanceTriggerKey,
  autoIssuanceIdempotencyKey,
  autoDeliveryIdempotencyKey,
} from './idempotency_keys.ts'

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i

Deno.test('AutoIssuanceIdempotencyKey generates canonical trigger key from event type, order, and version', () => {
  const key = autoIssuanceTriggerKey({
    eventType: SALES_ORDER_FINALIZED_EVENT_TYPE,
    eventId: 'evt-123',
    salesOrderId: 'order-456',
    sourceVersion: '1',
  })

  assertEquals(key, 'sales_order_finalized.v1:evt-123:order-456:1')
})

Deno.test('AutoIssuanceIdempotencyKey generates valid canonical UUIDv5 for idempotency key', async () => {
  const key = await autoIssuanceIdempotencyKey({
    tenantId: 'tenant-1',
    salesOrderId: 'order-456',
    sourceVersion: 'sales-v17',
  })

  assertMatch(key, UUID_REGEX)
  assertEquals(key.charAt(14), '5')
})

Deno.test('AutoIssuanceIdempotencyKey is deterministic for identical inputs', async () => {
  const key1 = await autoIssuanceIdempotencyKey({
    tenantId: 'tenant-1',
    salesOrderId: 'order-456',
    sourceVersion: 'sales-v17',
  })
  const key2 = await autoIssuanceIdempotencyKey({
    tenantId: 'tenant-1',
    salesOrderId: 'order-456',
    sourceVersion: 'sales-v17',
  })

  assertEquals(key1, key2)
})

Deno.test('AutoIssuanceIdempotencyKey changes when sourceVersion changes', async () => {
  const keyV1 = await autoIssuanceIdempotencyKey({
    tenantId: 'tenant-1',
    salesOrderId: 'order-456',
    sourceVersion: 'sales-v1',
  })
  const keyV2 = await autoIssuanceIdempotencyKey({
    tenantId: 'tenant-1',
    salesOrderId: 'order-456',
    sourceVersion: 'sales-v2',
  })

  assertNotEquals(keyV1, keyV2)
})

Deno.test('AutoIssuanceIdempotencyKey changes when salesOrderId changes', async () => {
  const key1 = await autoIssuanceIdempotencyKey({
    tenantId: 'tenant-1',
    salesOrderId: 'order-1',
    sourceVersion: 'sales-v1',
  })
  const key2 = await autoIssuanceIdempotencyKey({
    tenantId: 'tenant-1',
    salesOrderId: 'order-2',
    sourceVersion: 'sales-v1',
  })

  assertNotEquals(key1, key2)
})

Deno.test('AutoIssuanceIdempotencyKey changes when tenantId changes', async () => {
  const key1 = await autoIssuanceIdempotencyKey({
    tenantId: 'tenant-1',
    salesOrderId: 'order-1',
    sourceVersion: 'sales-v1',
  })
  const key2 = await autoIssuanceIdempotencyKey({
    tenantId: 'tenant-2',
    salesOrderId: 'order-1',
    sourceVersion: 'sales-v1',
  })

  assertNotEquals(key1, key2)
})

Deno.test('AutoDeliveryIdempotencyKey uses frozen namespace and pipe-separated seed', async () => {
  const key = await autoDeliveryIdempotencyKey({
    tenantId: 'tenant-1',
    electronicInvoiceId: 'ei-1',
  })

  const keySame = await autoDeliveryIdempotencyKey({
    tenantId: 'tenant-1',
    electronicInvoiceId: 'ei-1',
  })
  assertEquals(key, keySame)

  const keyDiff = await autoDeliveryIdempotencyKey({
    tenantId: 'tenant-1',
    electronicInvoiceId: 'ei-2',
  })
  assertNotEquals(key, keyDiff)

  assertEquals(AUTO_DELIVERY_NAMESPACE, '9d4c1d80-8d2c-5f2a-8b86-ff34c8a8e275')
  assertEquals(AUTO_ISSUANCE_NAMESPACE, '6ba7b811-9dad-11d1-80b4-00c04fd430c8')
})

Deno.test('auto issuance idempotency key matches uuid package vector', async () => {
  const key = await autoIssuanceIdempotencyKey({
    tenantId: 'tenant-1',
    salesOrderId: 'order-456',
    sourceVersion: 'sales-v17',
  })

  assertEquals(key, 'c1ccac1b-df81-519e-a2f5-e4333a17c8d2')
})

Deno.test('auto delivery idempotency key matches uuid package vector', async () => {
  const key = await autoDeliveryIdempotencyKey({
    tenantId: 'tenant-1',
    electronicInvoiceId: 'ei-1',
  })

  assertEquals(key, '214c3038-4c3f-51e0-a7c2-b675ea0fe14b')
})

