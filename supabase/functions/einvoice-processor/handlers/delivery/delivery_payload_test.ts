import { assertEquals, assertThrows } from 'jsr:@std/assert@1'
import {
  parseDeliveryPayload,
  parseReconciliationPayload,
} from './delivery_payload.ts'

Deno.test('legacy SQL camelCase payload deserializes into canonical keys', () => {
  const payload = parseDeliveryPayload({
    tenantId: 'tenant',
    deliveryId: 'delivery',
    retryCount: 1,
  }, 'tenant')
  assertEquals(payload, {
    tenantId: 'tenant',
    deliveryId: 'delivery',
    retryCount: 1,
  })
})

Deno.test('conflicting aliases reject instead of selecting one identity', () => {
  assertThrows(
    () => {
      parseDeliveryPayload({
        tenant_id: 'tenant',
        tenantId: 'other',
        delivery_id: 'delivery',
        retry_count: 0,
      }, 'tenant')
    },
    Error,
    'Conflicting delivery identity aliases: tenant_id',
  )
})

for (const bad of [null, '', ' ', 12]) {
  Deno.test(`invalid identity ${bad} rejects with safe field error`, () => {
    assertThrows(
      () => {
        parseDeliveryPayload({
          tenant_id: 'tenant',
          delivery_id: bad,
          retry_count: 0,
        }, 'tenant')
      },
      Error,
      'Invalid or missing delivery identity: delivery_id',
    )
  })
}

for (const bad of [null, '0', -1, 3, 1.5]) {
  Deno.test(`invalid retry count ${bad} rejects`, () => {
    assertThrows(
      () => {
        parseDeliveryPayload({
          tenant_id: 'tenant',
          delivery_id: 'delivery',
          retry_count: bad,
        }, 'tenant')
      },
      Error,
      'Invalid or missing delivery identity: retry_count',
    )
  })
}

Deno.test('SendInvoiceEmailCommand serializes tenant, delivery and retry count', () => {
  const parsed = parseDeliveryPayload({
    tenant_id: 'tenant-1',
    delivery_id: 'del-1',
    retry_count: 0,
  }, 'tenant-1')

  assertEquals(Object.keys(parsed).sort(), ['deliveryId', 'retryCount', 'tenantId'])
  assertEquals(parsed.retryCount, 0)
  assertEquals('recipient_email' in parsed, false)
  assertEquals('password' in parsed, false)
  assertEquals('access_token' in parsed, false)
})

Deno.test('SendInvoiceEmailCommand round-trips through fromJson without credentials', () => {
  const original = {
    tenantId: 'tenant-1',
    deliveryId: 'del-1',
    retryCount: 2,
  }
  const serialized = {
    tenant_id: original.tenantId,
    delivery_id: original.deliveryId,
    retry_count: original.retryCount,
  }
  const restored = parseDeliveryPayload(serialized, 'tenant-1')

  assertEquals(restored.tenantId, original.tenantId)
  assertEquals(restored.deliveryId, original.deliveryId)
  assertEquals(restored.retryCount, original.retryCount)
})

Deno.test('ReconcileInvoiceDeliveryCommand serializes only tenant, case id, and check sequence', () => {
  const parsed = parseReconciliationPayload({
    tenant_id: 'tenant-1',
    reconciliation_case_id: 'case-1',
    check_sequence: 1,
  })

  assertEquals(Object.keys(parsed).sort(), ['checkSequence', 'reconciliationCaseId'])
  assertEquals('recipient_email' in parsed, false)
  assertEquals('getStatus' in parsed, false)
})

Deno.test('ReconcileInvoiceDeliveryCommand round-trips through fromJson', () => {
  const serialized = {
    tenant_id: 'tenant-1',
    reconciliation_case_id: 'case-1',
    check_sequence: 3,
  }
  const restored = parseReconciliationPayload(serialized)

  assertEquals(restored.reconciliationCaseId, 'case-1')
  assertEquals(restored.checkSequence, 3)
})

Deno.test('reconciliation payload reads camelCase keys written by SQL', () => {
  const parsed = parseReconciliationPayload({
    tenantId: 't',
    reconciliationCaseId: 'case-1',
    checkSequence: 2,
  })
  assertEquals(parsed, {
    reconciliationCaseId: 'case-1',
    checkSequence: 2,
  })
})
