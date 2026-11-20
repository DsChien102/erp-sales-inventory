import { assertEquals, assertRejects } from 'jsr:@std/assert@1'
import type { CommandContext } from '../../queue/types.ts'
import { cmd } from '../../queue/test_support.ts'
import {
  startAutoIssuance,
  reevaluateAutoIssuance,
  createStartAutoIssuanceHandler,
  createReevaluateAutoIssuanceHandler,
} from './auto_issuance.ts'
import { FakeAutomationGateway } from './fake_gateways.ts'
import { autoIssuanceIdempotencyKey } from './idempotency_keys.ts'

const validKey = 'a6547397-1158-5873-a825-9ee320d9fcc5'

Deno.test('StartAutoIssuanceCommandValidator accepts valid command', async () => {
  const gateway = new FakeAutomationGateway()
  await startAutoIssuance(gateway, {
    tenantId: 'tenant-1',
    salesOrderId: 'order-1',
    triggerKey: 'sales_order_finalized.v1:event-1:order-1:sales-v17',
    idempotencyKey: validKey,
  })
  assertEquals(gateway.startIssuanceCalls.length, 1)
})

Deno.test('StartAutoIssuanceCommandValidator rejects empty tenantId', async () => {
  const gateway = new FakeAutomationGateway()
  await assertRejects(
    () =>
      startAutoIssuance(gateway, {
        tenantId: '   ',
        salesOrderId: 'order-1',
        triggerKey: 'sales_order_finalized.v1:event-1:order-1:sales-v17',
        idempotencyKey: validKey,
      }),
    Error,
    'tenantId is required',
  )
  assertEquals(gateway.startIssuanceCalls.length, 0)
})

Deno.test('StartAutoIssuanceCommandValidator rejects empty salesOrderId', async () => {
  const gateway = new FakeAutomationGateway()
  await assertRejects(
    () =>
      startAutoIssuance(gateway, {
        tenantId: 'tenant-1',
        salesOrderId: '',
        triggerKey: 'sales_order_finalized.v1:event-1:order-1:sales-v17',
        idempotencyKey: validKey,
      }),
    Error,
    'salesOrderId is required',
  )
  assertEquals(gateway.startIssuanceCalls.length, 0)
})

Deno.test('StartAutoIssuanceCommandValidator rejects empty triggerKey', async () => {
  const gateway = new FakeAutomationGateway()
  await assertRejects(
    () =>
      startAutoIssuance(gateway, {
        tenantId: 'tenant-1',
        salesOrderId: 'order-1',
        triggerKey: ' ',
        idempotencyKey: validKey,
      }),
    Error,
    'triggerKey is required',
  )
  assertEquals(gateway.startIssuanceCalls.length, 0)
})

Deno.test('StartAutoIssuanceCommandValidator rejects non-UUID idempotencyKey', async () => {
  const gateway = new FakeAutomationGateway()
  await assertRejects(
    () =>
      startAutoIssuance(gateway, {
        tenantId: 'tenant-1',
        salesOrderId: 'order-1',
        triggerKey: 'sales_order_finalized.v1:event-1:order-1:sales-v17',
        idempotencyKey: 'not-a-uuid',
      }),
    Error,
    'idempotencyKey must be a canonical UUID',
  )
  assertEquals(gateway.startIssuanceCalls.length, 0)
})

Deno.test('ReevaluateAutoIssuanceCommandValidator accepts valid command', async () => {
  const gateway = new FakeAutomationGateway()
  await reevaluateAutoIssuance(gateway, {
    tenantId: 'tenant-1',
    processId: 'proc-1',
    sourceEventId: 'evt-100',
  })
  assertEquals(gateway.reevaluateCalls.length, 1)
})

Deno.test('ReevaluateAutoIssuanceCommandValidator rejects empty tenantId', async () => {
  const gateway = new FakeAutomationGateway()
  await assertRejects(
    () =>
      reevaluateAutoIssuance(gateway, {
        tenantId: '  ',
        processId: 'proc-1',
        sourceEventId: 'evt-100',
      }),
    Error,
    'tenantId is required',
  )
  assertEquals(gateway.reevaluateCalls.length, 0)
})

Deno.test('ReevaluateAutoIssuanceCommandValidator rejects empty processId', async () => {
  const gateway = new FakeAutomationGateway()
  await assertRejects(
    () =>
      reevaluateAutoIssuance(gateway, {
        tenantId: 'tenant-1',
        processId: '',
        sourceEventId: 'evt-100',
      }),
    Error,
    'processId is required',
  )
  assertEquals(gateway.reevaluateCalls.length, 0)
})

Deno.test('ReevaluateAutoIssuanceCommandValidator rejects empty sourceEventId', async () => {
  const gateway = new FakeAutomationGateway()
  await assertRejects(
    () =>
      reevaluateAutoIssuance(gateway, {
        tenantId: 'tenant-1',
        processId: 'proc-1',
        sourceEventId: '   ',
      }),
    Error,
    'sourceEventId is required',
  )
  assertEquals(gateway.reevaluateCalls.length, 0)
})

Deno.test('StartAutoIssuanceCommandHandler scn_e02_u03_fr01_01 forwards stable trigger identity', async () => {
  const gateway = new FakeAutomationGateway()
  gateway.startIssuanceResult = {
    started: true,
    skipped: false,
    processId: 'proc-1',
    attemptId: 'att-1',
    status: 'ATTEMPT_STARTED',
    reason: null,
  }

  const result = await startAutoIssuance(gateway, {
    tenantId: 'tenant-1',
    salesOrderId: 'order-1',
    triggerKey: 'sales_order_finalized.v1:event-1:order-1:sales-v17',
    idempotencyKey: validKey,
  })

  assertEquals(result.started, true)
  assertEquals(result.skipped, false)
  assertEquals(gateway.startIssuanceCalls.length, 1)
  const req = gateway.startIssuanceCalls[0]
  assertEquals(req.tenantId, 'tenant-1')
  assertEquals(req.salesOrderId, 'order-1')
  assertEquals(req.triggerKey, 'sales_order_finalized.v1:event-1:order-1:sales-v17')
  assertEquals(req.idempotencyKey, validKey)
})

Deno.test('StartAutoIssuanceCommandHandler policy-off is a successful skip, not an exception', async () => {
  const gateway = new FakeAutomationGateway()
  gateway.startIssuanceResult = {
    started: false,
    skipped: true,
    processId: 'proc-1',
    attemptId: null,
    status: 'SKIPPED',
    reason: 'POLICY_OFF',
  }

  const result = await startAutoIssuance(gateway, {
    tenantId: 'tenant-1',
    salesOrderId: 'order-1',
    triggerKey: 'sales_order_finalized.v1:event-1:order-1:sales-v17',
    idempotencyKey: validKey,
  })

  assertEquals(result.started, false)
  assertEquals(result.skipped, true)
  assertEquals(result.reason, 'POLICY_OFF')
})

Deno.test('StartAutoIssuanceCommandHandler auto_issue_skipped_not_ready returns skipped with reason', async () => {
  const gateway = new FakeAutomationGateway()
  gateway.startIssuanceResult = {
    started: false,
    skipped: true,
    processId: 'proc-1',
    attemptId: null,
    status: 'SKIPPED',
    reason: 'NOT_READY',
  }

  const result = await startAutoIssuance(gateway, {
    tenantId: 'tenant-1',
    salesOrderId: 'order-1',
    triggerKey: 'sales_order_finalized.v1:event-1:order-1:sales-v17',
    idempotencyKey: validKey,
  })

  assertEquals(result.started, false)
  assertEquals(result.skipped, true)
  assertEquals(result.reason, 'NOT_READY')
})

Deno.test('StartAutoIssuanceCommandHandler duplicate trigger replay returns skipped duplicate result', async () => {
  const gateway = new FakeAutomationGateway()
  gateway.startIssuanceResult = {
    started: false,
    skipped: true,
    processId: 'proc-1',
    attemptId: null,
    status: 'SKIPPED',
    reason: 'DUPLICATE_TRIGGER',
  }

  const result = await startAutoIssuance(gateway, {
    tenantId: 'tenant-1',
    salesOrderId: 'order-1',
    triggerKey: 'sales_order_finalized.v1:event-1:order-1:sales-v17',
    idempotencyKey: validKey,
  })

  assertEquals(result.started, false)
  assertEquals(result.skipped, true)
  assertEquals(result.reason, 'DUPLICATE_TRIGGER')
})

Deno.test('ReevaluateAutoIssuanceCommandHandler forwards tenantId, processId, sourceEventId to gateway reevaluate', async () => {
  const gateway = new FakeAutomationGateway()
  const result = await reevaluateAutoIssuance(gateway, {
    tenantId: 'tenant-1',
    processId: 'proc-1',
    sourceEventId: 'evt-100',
  })

  assertEquals(result.started, true)
  assertEquals(gateway.reevaluateCalls.length, 1)
  const req = gateway.reevaluateCalls[0]
  assertEquals(req.tenantId, 'tenant-1')
  assertEquals(req.processId, 'proc-1')
  assertEquals(req.sourceEventId, 'evt-100')
})

Deno.test('ReevaluateAutoIssuanceCommandHandler returns skipped when process is still blocked or unchanged', async () => {
  const gateway = new FakeAutomationGateway()
  gateway.reevaluateResult = {
    started: false,
    skipped: true,
    processId: 'proc-1',
    attemptId: null,
    status: 'PENDING_REEVALUATION',
    reason: 'STILL_BLOCKED',
  }

  const result = await reevaluateAutoIssuance(gateway, {
    tenantId: 'tenant-1',
    processId: 'proc-1',
    sourceEventId: 'evt-100',
  })

  assertEquals(result.started, false)
  assertEquals(result.skipped, true)
  assertEquals(result.processId, 'proc-1')
  assertEquals(result.status, 'PENDING_REEVALUATION')
  assertEquals(result.reason, 'STILL_BLOCKED')
})

Deno.test('SalesOrderFinalizedIntegrationEventHandler dispatches single StartAutoIssuanceCommand with deterministic keys', async () => {
  const gateway = new FakeAutomationGateway()
  const handler = createStartAutoIssuanceHandler({ gateway })

  const ctx: CommandContext = {
    tenantId: 'tenant-1',
    command: {
      ...cmd('einvoice.start_auto_issuance', 0),
      commandId: 'event-001',
      payload: {
        tenant_id: 'tenant-1',
        sales_order_id: 'order-123',
        source_version: '1',
      },
    },
    attemptNumber: 1,
  }

  await handler(ctx)

  assertEquals(gateway.startIssuanceCalls.length, 1)
  const req = gateway.startIssuanceCalls[0]
  assertEquals(req.tenantId, 'tenant-1')
  assertEquals(req.salesOrderId, 'order-123')
  assertEquals(req.triggerKey, 'sales_order_finalized.v1:event-001:order-123:1')
  const expectedKey = await autoIssuanceIdempotencyKey({
    tenantId: 'tenant-1',
    salesOrderId: 'order-123',
    sourceVersion: '1',
  })
  assertEquals(req.idempotencyKey, expectedKey)
  assertEquals(gateway.reevaluateCalls.length, 0)
})

Deno.test('reevaluate handler forwards payload fields', async () => {
  const gateway = new FakeAutomationGateway()
  const handler = createReevaluateAutoIssuanceHandler({ gateway })

  const ctx: CommandContext = {
    tenantId: 'tenant-1',
    command: {
      ...cmd('einvoice.reevaluate_auto_issuance', 0),
      commandId: 'cmd-999',
      payload: {
        tenant_id: 'tenant-1',
        process_id: 'proc-1',
        source_event_id: 'partner:p1:3',
      },
    },
    attemptNumber: 1,
  }

  await handler(ctx)

  assertEquals(gateway.reevaluateCalls.length, 1)
  assertEquals(gateway.reevaluateCalls[0], {
    tenantId: 'tenant-1',
    processId: 'proc-1',
    sourceEventId: 'partner:p1:3',
  })
})

Deno.test('start auto issuance handler rejects payload without sales_order_id before calling gateway', async () => {
  const gateway = new FakeAutomationGateway()
  const handler = createStartAutoIssuanceHandler({ gateway })

  const ctx: CommandContext = {
    tenantId: 'tenant-1',
    command: {
      ...cmd('einvoice.start_auto_issuance', 0),
      commandId: 'cmd-999',
      payload: {
        tenant_id: 'tenant-1',
        sales_order_id: '',
        source_version: '1',
      },
    },
    attemptNumber: 1,
  }

  await assertRejects(
    () => handler(ctx),
    Error,
    'Invalid or missing automation payload: sales_order_id',
  )
  assertEquals(gateway.startIssuanceCalls.length, 0)
})
