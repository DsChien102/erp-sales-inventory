import { assert, assertEquals, assertNotStrictEquals, assertStrictEquals, assertThrows } from 'jsr:@std/assert@1'
import { FakeMeInvoiceClient } from '../misa/mod.ts'
import type { MeInvoiceConfig } from '../misa/mod.ts'
import { type CredentialsRow, TenantMisaClientFactory } from './misa_client_factory.ts'
import { readMisaEnv } from './misa_env.ts'

const env = { appId: 'app', baseUrl: 'https://testapi.meinvoice.vn/api/integration', emailDeliveryEnabled: false, publishEnabled: false }

function setup(row: CredentialsRow | null) {
  const holder = { row }
  const created: MeInvoiceConfig[] = []
  const factory = new TenantMisaClientFactory(
    env,
    { read: () => Promise.resolve(holder.row) },
    (c) => {
      created.push(c)
      return new FakeMeInvoiceClient()
    },
  )
  return { holder, created, factory }
}

const row = (over: Partial<CredentialsRow> = {}): CredentialsRow => ({
  username: 'u',
  password: 'p',
  tax_code: '0100000000',
  base_url: null,
  ...over,
})

Deno.test('misa_client_factory reuses client for same config', async () => {
  const { factory, created } = setup(row())
  const a = await factory.getForTenant('t1')
  const b = await factory.getForTenant('t1')
  assertStrictEquals(a!.client, b!.client)
  assertEquals(created.length, 1)
})

Deno.test('misa_client_factory new client after password change', async () => {
  const { factory, holder, created } = setup(row())
  const a = await factory.getForTenant('t1')
  holder.row = row({ password: 'p2' })
  const b = await factory.getForTenant('t1')
  assertNotStrictEquals(a!.client, b!.client)
  assertEquals(created.length, 2)
})

Deno.test('misa_client_factory invalidate drops cached client', async () => {
  const { factory } = setup(row())
  const a = await factory.getForTenant('t1')
  factory.invalidate('t1')
  const b = await factory.getForTenant('t1')
  assertNotStrictEquals(a!.client, b!.client)
})

Deno.test('misa_client_factory base_url null falls back to env', async () => {
  const { factory, created } = setup(row())
  const r = await factory.getForTenant('t1')
  assertEquals(r!.baseUrl, env.baseUrl)
  assertEquals(created[0].baseUrl, env.baseUrl)
  assertEquals(created[0].appId, 'app')
})

Deno.test('misa_client_factory returns null without credentials row', async () => {
  const { factory } = setup(null)
  assertEquals(await factory.getForTenant('t1'), null)
})

Deno.test('misa_client_factory getForTenant returns tax code from credentials row', async () => {
  const { factory } = setup(row({ tax_code: '0101234567' }))
  const first = await factory.getForTenant('t1')
  assertEquals(first?.taxCode, '0101234567')

  // Reused client branch also returns tax code
  const second = await factory.getForTenant('t1')
  assertEquals(second?.taxCode, '0101234567')
  assertStrictEquals(first?.client, second?.client)
})

Deno.test('readMisaEnv missing app id throws missing_MISA_MEINVOICE_APP_ID', () => {
  assertThrows(() => readMisaEnv(() => undefined), Error, 'missing_MISA_MEINVOICE_APP_ID')
  assertThrows(
    () => readMisaEnv((k) => (k === 'MISA_MEINVOICE_APP_ID' ? 'a' : undefined)),
    Error,
    'missing_MISA_MEINVOICE_BASE_URL',
  )
})

Deno.test('readMisaEnv "1" sets the email flag', () => {
  const get = (flag?: string) => (k: string) =>
    ({ MISA_MEINVOICE_APP_ID: 'a', MISA_MEINVOICE_BASE_URL: 'https://x', MISA_MEINVOICE_EMAIL_DELIVERY_ENABLED: flag })[k]
  assert(readMisaEnv(get('1')).emailDeliveryEnabled)
  assert(readMisaEnv(get(' TRUE ')).emailDeliveryEnabled)
  assertEquals(readMisaEnv(get(undefined)).emailDeliveryEnabled, false)
  assertEquals(readMisaEnv(get('no')).emailDeliveryEnabled, false)
})

Deno.test('readMisaEnv publish flag is off unless explicitly true / 1', () => {
  const get = (flag?: string) => (k: string) =>
    ({ MISA_MEINVOICE_APP_ID: 'a', MISA_MEINVOICE_BASE_URL: 'https://x', MISA_MEINVOICE_PUBLISH_ENABLED: flag })[k]
  assertEquals(readMisaEnv(get(undefined)).publishEnabled, false)
  assertEquals(readMisaEnv(get('')).publishEnabled, false)
  assertEquals(readMisaEnv(get('false')).publishEnabled, false)
  assertEquals(readMisaEnv(get('yes')).publishEnabled, false)
  assert(readMisaEnv(get('1')).publishEnabled)
  assert(readMisaEnv(get(' TRUE ')).publishEnabled)
})
