import { assertEquals } from 'jsr:@std/assert@1'
import { buildHandlers, type HandlerDeps } from './registry.ts'
import { FakeAutomationGateway } from './automation/fake_gateways.ts'

Deno.test('registry registers automation command types', () => {
  const handlers = buildHandlers({
    automation: { gateway: new FakeAutomationGateway() },
  } as unknown as HandlerDeps)

  assertEquals(typeof handlers['einvoice.start_auto_issuance'], 'function')
  assertEquals(typeof handlers['einvoice.reevaluate_auto_issuance'], 'function')
  assertEquals(typeof handlers['einvoice.start_auto_delivery'], 'function')
})

