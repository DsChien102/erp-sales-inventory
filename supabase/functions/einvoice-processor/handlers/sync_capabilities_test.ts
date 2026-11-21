import { assert, assertEquals, assertRejects } from 'jsr:@std/assert@1'
import { FakeMeInvoiceClient, FakeMeInvoiceScenario, MeInvoiceClient, MeInvoiceResult, MeInvoiceTemplate } from '../misa/mod.ts'
import type { MeInvoiceConfig } from '../misa/mod.ts'
import { jsonResponse, mockFetch, textResponse } from '../misa/test_support.ts'
import { ProviderUnavailableError } from '../queue/errors.ts'
import type { CommandContext } from '../queue/types.ts'
import { type CredentialsRow, TenantMisaClientFactory } from './misa_client_factory.ts'
import type { MisaEnv } from './misa_env.ts'
import { type ConnectionRecorder, createSyncCapabilitiesHandler, safeFailureReason } from './sync_capabilities.ts'

type Recorded = Parameters<ConnectionRecorder['record']>[0]

const TEST_URL = 'https://testapi.meinvoice.vn/api/integration'
const PROD_URL = 'https://api.meinvoice.vn/api/integration'
const FIXED_NOW = new Date('2026-11-08T01:02:03.000Z')

const creds = (over: Partial<CredentialsRow> = {}): CredentialsRow => ({
  username: 'misa_user',
  password: 'secret',
  tax_code: '0100000000',
  base_url: TEST_URL,
  ...over,
})

function ctx(payload: Record<string, unknown> = {}, tenantId = 'tenant-1'): CommandContext {
  return {
    tenantId,
    attemptNumber: 1,
    command: {
      commandId: 'c1',
      commandType: 'einvoice.sync_capabilities',
      payload: { tenant_id: tenantId, connection_id: 'conn-1', expected_connection_version: 7, ...payload },
      sourceEventId: null,
      enqueuedAt: '2026-11-08T00:00:00Z',
      claimToken: 'tok',
      retryCount: 0,
    },
  }
}

class ScriptedClient extends FakeMeInvoiceClient {
  constructor(
    private withCode: MeInvoiceResult<MeInvoiceTemplate[]>,
    private withoutCode: MeInvoiceResult<MeInvoiceTemplate[]> = MeInvoiceResult.ok([]),
    private token: MeInvoiceResult<{ value: string; expiresAt: Date }> | null = null,
  ) {
    super()
  }
  override listInvoiceTemplates(opts: { invoiceWithCode: boolean }) {
    return Promise.resolve(opts.invoiceWithCode ? this.withCode : this.withoutCode)
  }
  override obtainAccessToken() {
    return this.token ? Promise.resolve(this.token) : super.obtainAccessToken()
  }
}

const tpl = (id: string, series: string, over: Record<string, unknown> = {}) =>
  new MeInvoiceTemplate({ ipTemplateId: id, templateName: `Mẫu ${id}`, invTemplateNo: '1/001', invSeries: series, ...over })

function setup(opts: {
  client?: FakeMeInvoiceClient | null
  row?: CredentialsRow | null
  envOver?: Partial<MisaEnv>
  logs?: [string, Record<string, unknown>][]
}) {
  const env: MisaEnv = { appId: 'app', baseUrl: TEST_URL, emailDeliveryEnabled: false, publishEnabled: false, ...opts.envOver }
  const records: Recorded[] = []
  const created: MeInvoiceConfig[] = []
  const row = opts.row === undefined ? creds() : opts.row
  const clients = new TenantMisaClientFactory(env, { read: () => Promise.resolve(row) }, (c) => {
    created.push(c)
    return opts.client ?? new FakeMeInvoiceClient()
  })
  const handler = createSyncCapabilitiesHandler({
    clients,
    env,
    now: () => FIXED_NOW,
    recorder: { record: (i) => { records.push(i); return Promise.resolve() } },
    log: (e, d) => opts.logs?.push([e, d]),
  })
  return { handler, records, created, clients }
}

Deno.test('SyncProviderCapabilitiesCommandHandler records connected on MISA success', async () => {
  const client = new ScriptedClient(MeInvoiceResult.ok([tpl('tpl-1', '1C26TAA'), tpl('tpl-2', '1C26TAB')]))
  const { handler, records } = setup({ client })
  await handler(ctx())
  const r = records[0]
  assertEquals(r.status, 'CONNECTED')
  assertEquals(r.expectedConnectionVersion, 7)
  const caps = r.capabilities as Record<string, unknown> & { templates: Record<string, unknown>[] }
  assertEquals(caps.template_count, 2)
  assertEquals(caps.templates.length, 2)
  assertEquals(caps.templates[0].name, 'Mẫu tpl-1')
  assertEquals(caps.supports_delivery_result_observation, false)
  assertEquals(caps.supports_preview, true)
})

Deno.test('SyncProviderCapabilitiesCommandHandler records supportsPreview when MISA advertises it', async () => {
  const { handler, records } = setup({ client: new ScriptedClient(MeInvoiceResult.ok([])) })
  await handler(ctx())
  assertEquals((records[0].capabilities as Record<string, unknown>).supports_preview, true)
})

Deno.test('SyncProviderCapabilitiesCommandHandler MISA capability sync never advertises delivery-result observation', async () => {
  const { handler, records } = setup({ client: new ScriptedClient(MeInvoiceResult.ok([])), envOver: { baseUrl: PROD_URL, emailDeliveryEnabled: true }, row: creds({ base_url: PROD_URL }) })
  await handler(ctx())
  const caps = records[0].capabilities as Record<string, unknown>
  assertEquals(caps.supports_email_delivery, true)
  assertEquals(caps.supports_delivery_result_observation, false)
})

Deno.test('SyncProviderCapabilitiesCommandHandler soft-fails auth without throwing', async () => {
  const client = new ScriptedClient(MeInvoiceResult.ok([]), MeInvoiceResult.ok([]), MeInvoiceResult.failed('meinvoice_auth_rejected:WrongPassWord'))
  const { handler, records } = setup({ client })
  await handler(ctx({ expected_connection_version: 8 }))
  assertEquals(records[0].status, 'RECONNECT_REQUIRED')
  assertEquals(records[0].expectedConnectionVersion, 8)
  assertEquals(records[0].capabilities, undefined)
})

Deno.test('SyncProviderCapabilitiesCommandHandler provider unavailable throws so queue schedules a retry', async () => {
  const client = new ScriptedClient(MeInvoiceResult.ok([]), MeInvoiceResult.ok([]), MeInvoiceResult.failed('meinvoice_network_timeout'))
  const { handler, records } = setup({ client })
  await assertRejects(() => handler(ctx({ expected_connection_version: 9 })), ProviderUnavailableError)
  assertEquals(records.length, 0)
})

Deno.test('th08_hardening_capability_01 — dual template fetch fetches invoiceWithCode true and false, classifies MTT, keeps IsSendSummary', async () => {
  const requestedWithCode: boolean[] = []
  const t = (id: string, name: string, series: string, isSendSummary: boolean) => ({
    IPTemplateID: id, TemplateName: name, InvTemplateNo: '1', InvSeries: series, Inactive: false, IsSendSummary: isSendSummary,
  })
  const fetchFn = mockFetch((req) => {
    if (req.url.pathname.endsWith('/auth/token')) return jsonResponse({ Success: true, Data: 'token-1' })
    if (req.url.pathname.endsWith('/invoice/templates')) {
      const withCode = req.url.searchParams.get('invoiceWithCode') === 'true'
      requestedWithCode.push(withCode)
      const data = withCode
        ? [t('tpl-c', 'Có mã', '1C26TYY', false), t('tpl-mtt', 'MTT', '2C26MYY', false)]
        : [t('tpl-k', 'Không mã', '1K26TYY', true), t('tpl-c-dup', 'Dup', '1C26TYY', false)]
      return jsonResponse({ Success: true, Data: JSON.stringify(data) })
    }
    return textResponse('Not Found', 404)
  })
  const env: MisaEnv = { appId: 'app-id', baseUrl: TEST_URL, emailDeliveryEnabled: false, publishEnabled: false }
  const records: Recorded[] = []
  const clients = new TenantMisaClientFactory(env, { read: () => Promise.resolve(creds()) }, (c) => new MeInvoiceClient(c, fetchFn))
  const handler = createSyncCapabilitiesHandler({ clients, env, now: () => FIXED_NOW, recorder: { record: (i) => { records.push(i); return Promise.resolve() } } })
  await handler(ctx())

  assertEquals(records[0].status, 'CONNECTED')
  assertEquals(new Set(requestedWithCode), new Set([true, false]))
  assertEquals(requestedWithCode.length, 2)
  const templates = (records[0].capabilities as { templates: Record<string, unknown>[] }).templates
  assertEquals(templates.length, 3)
  assertEquals(new Set(templates.map((x) => x.invoice_series)), new Set(['1C26TYY', '1K26TYY', '2C26MYY']))
  const mtt = templates.find((x) => x.template_id === 'tpl-mtt')!
  assertEquals(mtt.is_mtt, true)
  assertEquals(mtt.invoice_with_code, true)
  const noCode = templates.find((x) => x.template_id === 'tpl-k')!
  assertEquals(noCode.invoice_with_code, false)
  assertEquals(noCode.is_send_summary, true)
  assertEquals(noCode.is_mtt, false)
})

Deno.test('th08_hardening_capability_01 — dual template fetch skips malformed InvSeries and keeps valid templates', async () => {
  const client = new ScriptedClient(MeInvoiceResult.ok([tpl('tpl-ok', '1C26TYY'), tpl('tpl-bad', 'BAD'), tpl('tpl-off', '1C26TYZ', { inactive: true })]))
  const { handler, records } = setup({ client })
  await handler(ctx())
  const templates = (records[0].capabilities as { templates: Record<string, unknown>[] }).templates
  assertEquals(templates.length, 1)
  assertEquals(templates[0].template_id, 'tpl-ok')
})

Deno.test('capabilities JSON uses the keys the app reads', async () => {
  const client = new ScriptedClient(MeInvoiceResult.ok([tpl('tpl-1', '1C26TAA')]))
  const { handler, records } = setup({ client })
  await handler(ctx({ correlation_id: 'corr-1' }))
  const caps = records[0].capabilities as Record<string, unknown> & { templates: Record<string, unknown>[] }
  assertEquals(Object.keys(caps).sort(), [
    'supports_email_delivery', 'supports_preview', 'supports_delivery_result_observation',
    'template_count', 'supported_document_types', 'templates', 'synced_at',
  ].sort())
  assertEquals(Object.keys(caps.templates[0]).sort(), [
    'template_id', 'name', 'serial', 'symbol', 'invoice_series', 'invoice_with_code', 'is_mtt', 'is_send_summary', 'is_available',
  ].sort())
  assertEquals(caps.templates[0].symbol, caps.templates[0].invoice_series)
  assertEquals(caps.synced_at, FIXED_NOW.toISOString())
  assertEquals(records[0].verifiedAt, FIXED_NOW.toISOString())
  assertEquals(records[0].correlationId, 'corr-1')
  assertEquals(caps.supported_document_types, ['PDF', 'XML'])
})

Deno.test('missing credentials row records RECONNECT_REQUIRED', async () => {
  const { handler, records } = setup({ row: null })
  await handler(ctx())
  assertEquals(records.map((r) => r.status), ['RECONNECT_REQUIRED'])
})

Deno.test('missing expected_connection_version defaults to -1', async () => {
  const { handler, records } = setup({ client: new ScriptedClient(MeInvoiceResult.ok([])) })
  const c = ctx()
  delete c.command.payload['expected_connection_version']
  await handler(c)
  assertEquals(records[0].expectedConnectionVersion, -1)
})

Deno.test('missing connection_id throws', async () => {
  const { handler } = setup({})
  const c = ctx()
  delete c.command.payload['connection_id']
  await assertRejects(() => handler(c), Error, 'missing_connection_id')
})

Deno.test('safeFailureReason never echoes secrets', () => {
  assertEquals(safeFailureReason('meinvoice_auth_rejected:InvalidPassword secret=abc'), 'InvalidPassword')
  assertEquals(safeFailureReason('request timeout'), 'TIMEOUT')
  assertEquals(safeFailureReason('service unavailable'), 'PROVIDER_UNAVAILABLE')
  assertEquals(safeFailureReason('!!!'), 'UNKNOWN_PROVIDER_FAILURE')
})

Deno.test('email delivery requires flag and production host', async () => {
  const { handler, records } = setup({
    client: new ScriptedClient(MeInvoiceResult.ok([])),
    envOver: { emailDeliveryEnabled: true },
  })
  await handler(ctx())
  assertEquals((records[0].capabilities as Record<string, unknown>).supports_email_delivery, false)
})

Deno.test('failure logs reason code only, no secrets, and drops the cached client', async () => {
  const logs: [string, Record<string, unknown>][] = []
  const client = new ScriptedClient(MeInvoiceResult.ok([]), MeInvoiceResult.ok([]), MeInvoiceResult.failed('meinvoice_auth_rejected:WrongPassWord'))
  const { handler, created } = setup({ client, logs })
  await handler(ctx())
  await handler(ctx())
  assertEquals(created.length, 2) // invalidated after the failure
  assertEquals(logs[0][0], 'misa_verification_failed')
  assertEquals(logs[0][1].reason, 'WrongPassWord')
  assertEquals(logs[0][1].stage, 'token')
  assert(!JSON.stringify(logs).includes('secret'))
})

Deno.test('fake client scenario failed (5xx) at templates is auth failure not unavailable', async () => {
  const client = new FakeMeInvoiceClient({ scenario: FakeMeInvoiceScenario.failed })
  const { handler, records } = setup({ client })
  await handler(ctx())
  assertEquals(records[0].status, 'RECONNECT_REQUIRED')
})
