import { assertEquals } from 'jsr:@std/assert@1'
import { runInvocation } from '../../queue/processor.ts'
import { cmd, FakeQueueRpc } from '../../queue/test_support.ts'
import { createStartAutoIssuanceHandler } from './auto_issuance.ts'
import { FakeAutomationGateway } from './fake_gateways.ts'

Deno.test('skipped auto issuance completes the command', async () => {
  const rpc = new FakeQueueRpc()
  rpc.batches = [
    [
      {
        ...cmd('einvoice.start_auto_issuance', 0),
        payload: {
          tenant_id: 'tenant-1',
          sales_order_id: 'order-1',
          source_version: '1',
        },
      },
    ],
  ]

  const gateway = new FakeAutomationGateway()
  gateway.startIssuanceResult = {
    started: false,
    skipped: true,
    processId: 'proc-1',
    attemptId: null,
    status: 'SKIPPED',
    reason: 'AUTOMATION_POLICY_DISABLED',
  }

  const handler = createStartAutoIssuanceHandler({ gateway })

  await runInvocation(
    {
      rpc,
      handlers: { 'einvoice.start_auto_issuance': handler },
      deadLetters: {},
    },
    'tenant-1',
  )

  assertEquals(rpc.count('complete'), 1)
  assertEquals(rpc.count('retryOrDeadLetter'), 0)
})

