import { assertEquals, assertRejects } from 'jsr:@std/assert@1'
import type { CommandContext } from '../../queue/types.ts'
import { cmd } from '../../queue/test_support.ts'
import {
  startAutoDelivery,
  createStartAutoDeliveryHandler,
} from './auto_delivery.ts'
import { FakeAutomationGateway } from './fake_gateways.ts'
import { autoDeliveryIdempotencyKey } from './idempotency_keys.ts'

const validKey = 'a6547397-1158-5873-a825-9ee320d9fcc5'

Deno.test('StartAutoDeliveryCommandValidator accepts valid command', async () => {
  const gateway = new FakeAutomationGateway()
  await startAutoDelivery(gateway, {
    tenantId: 'tenant-1',
    electronicInvoiceId: 'ei-1',
    triggerId: 'event-1',
    idempotencyKey: validKey,
  })
  assertEquals(gateway.startDeliveryCalls.length, 1)
})

Deno.test('StartAutoDeliveryCommandValidator rejects empty tenantId', async () => {
  const gateway = new FakeAutomationGateway()
  await assertRejects(
    () =>
      startAutoDelivery(gateway, {
        tenantId: '   ',
        electronicInvoiceId: 'ei-1',
        triggerId: 'event-1',
        idempotencyKey: validKey,
      }),
    Error,
    'tenantId is required',
  )
  assertEquals(gateway.startDeliveryCalls.length, 0)
})

Deno.test('StartAutoDeliveryCommandValidator rejects empty electronicInvoiceId', async () => {
  const gateway = new FakeAutomationGateway()
  await assertRejects(
    () =>
      startAutoDelivery(gateway, {
        tenantId: 'tenant-1',
        electronicInvoiceId: '',
        triggerId: 'event-1',
        idempotencyKey: validKey,
      }),
    Error,
    'electronicInvoiceId is required',
  )
  assertEquals(gateway.startDeliveryCalls.length, 0)
})

Deno.test('StartAutoDeliveryCommandValidator rejects empty triggerId', async () => {
  const gateway = new FakeAutomationGateway()
  await assertRejects(
    () =>
      startAutoDelivery(gateway, {
        tenantId: 'tenant-1',
        electronicInvoiceId: 'ei-1',
        triggerId: ' ',
        idempotencyKey: validKey,
      }),
    Error,
    'triggerId is required',
  )
  assertEquals(gateway.startDeliveryCalls.length, 0)
})

Deno.test('StartAutoDeliveryCommandValidator rejects non-UUID idempotencyKey', async () => {
  const gateway = new FakeAutomationGateway()
  await assertRejects(
    () =>
      startAutoDelivery(gateway, {
        tenantId: 'tenant-1',
        electronicInvoiceId: 'ei-1',
        triggerId: 'event-1',
        idempotencyKey: 'not-a-uuid',
      }),
    Error,
    'idempotencyKey must be a canonical UUID',
  )
  assertEquals(gateway.startDeliveryCalls.length, 0)
})

Deno.test('StartAutoDeliveryCommandHandler forwards stable auto identity to gateway', async () => {
  const gateway = new FakeAutomationGateway()
  gateway.startDeliveryResult = {
    disposition: 'started',
    deliveryId: 'del-1',
    skipReason: null,
  }

  const result = await startAutoDelivery(gateway, {
    tenantId: 'tenant-1',
    electronicInvoiceId: 'ei-1',
    triggerId: 'event-1',
    idempotencyKey: validKey,
  })

  assertEquals(result.disposition, 'started')
  assertEquals(result.deliveryId, 'del-1')
  assertEquals(gateway.startDeliveryCalls.length, 1)
  const req = gateway.startDeliveryCalls[0]
  assertEquals(req.tenantId, 'tenant-1')
  assertEquals(req.electronicInvoiceId, 'ei-1')
  assertEquals(req.triggerId, 'event-1')
  assertEquals(req.idempotencyKey, validKey)
})

Deno.test('StartAutoDeliveryCommandHandler preserves caller idempotency key without regenerating', async () => {
  const gateway = new FakeAutomationGateway()
  await startAutoDelivery(gateway, {
    tenantId: 'tenant-1',
    electronicInvoiceId: 'ei-1',
    triggerId: 'event-1',
    idempotencyKey: validKey,
  })

  assertEquals(gateway.startDeliveryCalls[0].idempotencyKey, validKey)
})

Deno.test('StartAutoDeliveryCommandHandler policy-off is a successful skip, not an exception', async () => {
  const gateway = new FakeAutomationGateway()
  gateway.startDeliveryResult = {
    disposition: 'skipped',
    deliveryId: null,
    skipReason: 'POLICY_OFF',
  }

  const result = await startAutoDelivery(gateway, {
    tenantId: 'tenant-1',
    electronicInvoiceId: 'ei-1',
    triggerId: 'event-1',
    idempotencyKey: validKey,
  })

  assertEquals(result.disposition, 'skipped')
  assertEquals(result.skipReason, 'POLICY_OFF')
  assertEquals(result.deliveryId, null)
})

Deno.test('ElectronicInvoiceRegisteredIntegrationEventHandler dispatches StartAutoDeliveryCommand with event id as triggerId', async () => {
  const gateway = new FakeAutomationGateway()
  const handler = createStartAutoDeliveryHandler({ gateway })

  const ctx: CommandContext = {
    tenantId: 'tenant-1',
    command: {
      ...cmd('einvoice.start_auto_delivery', 0),
      commandId: 'event-001',
      payload: {
        tenant_id: 'tenant-1',
        electronic_invoice_id: 'ei-99',
      },
    },
    attemptNumber: 1,
  }

  await handler(ctx)

  assertEquals(gateway.startDeliveryCalls.length, 1)
  const req = gateway.startDeliveryCalls[0]
  assertEquals(req.tenantId, 'tenant-1')
  assertEquals(req.electronicInvoiceId, 'ei-99')
  assertEquals(req.triggerId, 'event-001')
  const expectedKey = await autoDeliveryIdempotencyKey({
    tenantId: 'tenant-1',
    electronicInvoiceId: 'ei-99',
  })
  assertEquals(req.idempotencyKey, expectedKey)
})

Deno.test('ElectronicInvoiceRegisteredIntegrationEventHandler duplicate registered events derive the same UUIDv5 auto key', async () => {
  const gateway = new FakeAutomationGateway()
  const handler = createStartAutoDeliveryHandler({ gateway })

  const ctxA: CommandContext = {
    tenantId: 'tenant-1',
    command: {
      ...cmd('einvoice.start_auto_delivery', 0),
      commandId: 'event-a',
      payload: {
        tenant_id: 'tenant-1',
        electronic_invoice_id: 'ei-99',
      },
    },
    attemptNumber: 1,
  }

  const ctxB: CommandContext = {
    tenantId: 'tenant-1',
    command: {
      ...cmd('einvoice.start_auto_delivery', 0),
      commandId: 'event-b',
      payload: {
        tenant_id: 'tenant-1',
        electronic_invoice_id: 'ei-99',
      },
    },
    attemptNumber: 1,
  }

  await handler(ctxA)
  await handler(ctxB)

  assertEquals(gateway.startDeliveryCalls.length, 2)
  assertEquals(
    gateway.startDeliveryCalls[0].idempotencyKey,
    gateway.startDeliveryCalls[1].idempotencyKey,
  )
  assertEquals(gateway.startDeliveryCalls[0].triggerId, 'event-a')
  assertEquals(gateway.startDeliveryCalls[1].triggerId, 'event-b')
})
