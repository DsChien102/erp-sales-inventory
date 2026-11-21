import { assertEquals } from 'jsr:@std/assert@1'
import { buildHandlers, type HandlerDeps } from './registry.ts'
import { FakeAutomationGateway } from './automation/fake_gateways.ts'
import { FakeIssuanceGateways, FakeIssuanceProvider } from './issuance/fake_gateways.ts'
import { PUBLISH_DISABLED_REASON } from './issuance/publish_invoice.ts'
import type { CommandContext } from '../queue/types.ts'

Deno.test('registry registers automation command types', () => {
  const handlers = buildHandlers({
    env: { publishEnabled: false },
    automation: { gateway: new FakeAutomationGateway() },
  } as unknown as HandlerDeps)

  assertEquals(typeof handlers['einvoice.start_auto_issuance'], 'function')
  assertEquals(typeof handlers['einvoice.reevaluate_auto_issuance'], 'function')
  assertEquals(typeof handlers['einvoice.start_auto_delivery'], 'function')
})

Deno.test('registry wires MISA_MEINVOICE_PUBLISH_ENABLED=false into the publish handler', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  const handlers = buildHandlers({
    env: { appId: 'app', baseUrl: 'https://api.meinvoice.vn/api/integration', emailDeliveryEnabled: false, publishEnabled: false },
    issuance: { provider, gateways },
    automation: { gateway: new FakeAutomationGateway() },
  } as unknown as HandlerDeps)

  const ctx: CommandContext = {
    tenantId: 'tenant-1',
    attemptNumber: 1,
    command: {
      commandId: 'cmd-1',
      commandType: 'einvoice.publish_invoice',
      payload: {
        tenant_id: 'tenant-1',
        attempt_id: 'att-1',
        canonical_invoice: { invSeries: '1C25TYY' },
        payload_hash: 'hash-1',
        idempotency_key: 'key-1',
      },
      sourceEventId: null,
      enqueuedAt: '2026-11-20T00:00:00Z',
      claimToken: 'tok-1',
      retryCount: 0,
    },
  }
  await handlers['einvoice.publish_invoice'](ctx)

  assertEquals(provider.publishCalls.length, 0)
  assertEquals(gateways.results.deadLetterCalls.map((c) => c.reasonCode), [PUBLISH_DISABLED_REASON])
})
