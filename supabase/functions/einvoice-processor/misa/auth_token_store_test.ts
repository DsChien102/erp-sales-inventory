import { assertEquals, assertRejects } from 'jsr:@std/assert@1'
import { MeInvoiceAuth, MeInvoiceAuthException, MeInvoiceAuthToken } from './internal/me_invoice_auth.ts'
import { DEFAULT_TOKEN_TTL_MS, RECOMMENDED_TOKEN_TTL_MS } from './models/me_invoice_config.ts'
import { jsonResponse, mockFetch, textResponse } from './test_support.ts'

const BASE = 'https://example.test/api/integration'
const DAY = 24 * 60 * 60 * 1000

Deno.test('MeInvoiceAuth caches token across getToken calls', async () => {
  let loginCalls = 0
  const fetchFn = mockFetch((req) => {
    assertEquals(req.url.pathname.endsWith('/auth/token'), true)
    loginCalls++
    return jsonResponse({ Success: true, Data: 'cached-token' })
  })
  const auth = new MeInvoiceAuth({ baseUrl: BASE, appId: 'a', taxCode: 't', username: 'u', password: 'p', fetchFn })
  const first = await auth.getToken()
  const second = await auth.getToken()
  assertEquals(first.value, 'cached-token')
  assertEquals(second.value, 'cached-token')
  assertEquals(loginCalls, 1)
})

Deno.test('MeInvoiceAuth forceRefresh uses refreshtoken then falls back to login', async () => {
  let loginCalls = 0
  let refreshCalls = 0
  const fetchFn = mockFetch((req) => {
    if (req.url.pathname.endsWith('/auth/token')) {
      loginCalls++
      return jsonResponse({ Success: true, Data: `login-${loginCalls}` })
    }
    if (req.url.pathname.endsWith('/auth/refreshtoken')) {
      refreshCalls++
      return textResponse('nope', 500)
    }
    return textResponse('unexpected', 500)
  })
  const auth = new MeInvoiceAuth({ baseUrl: BASE, appId: 'a', taxCode: 't', username: 'u', password: 'p', fetchFn })
  await auth.getToken()
  const refreshed = await auth.getToken({ forceRefresh: true })
  assertEquals(refreshCalls, 1)
  assertEquals(loginCalls, 2)
  assertEquals(refreshed.value, 'login-2')
})

Deno.test('MeInvoiceAuth seeded token is reused without login', async () => {
  let loginCalls = 0
  const fetchFn = mockFetch(() => {
    loginCalls++
    return textResponse('nope', 500)
  })
  const auth = new MeInvoiceAuth({
    baseUrl: BASE,
    fetchFn,
    initialToken: new MeInvoiceAuthToken('seed', new Date(Date.now() + DAY)),
  })
  const token = await auth.getToken()
  assertEquals(token.value, 'seed')
  assertEquals(loginCalls, 0)
})

Deno.test('MeInvoiceAuth expired bearer without login credentials fails', async () => {
  const auth = new MeInvoiceAuth({
    baseUrl: BASE,
    fetchFn: mockFetch(() => textResponse('{}', 200)),
    initialToken: new MeInvoiceAuthToken('old', new Date(Date.now() - 60 * 60 * 1000)),
  })
  const e = await assertRejects(() => auth.getToken(), MeInvoiceAuthException)
  assertEquals(e.message, 'meinvoice_token_expired_relogin')
})

Deno.test('MeInvoiceAuth isExpired respects skew', () => {
  const token = new MeInvoiceAuthToken('t', new Date(Date.UTC(2026, 0, 1, 12)))
  assertEquals(token.isExpired({ now: new Date(Date.UTC(2026, 0, 1, 11, 58)) }), false)
  assertEquals(token.isExpired({ now: new Date(Date.UTC(2026, 0, 1, 11, 59, 30)) }), true)
})

Deno.test('MeInvoiceAuth defaultTokenTtl is 14 days and recommendedTokenTtl is 7 days', () => {
  assertEquals(DEFAULT_TOKEN_TTL_MS, 14 * DAY)
  assertEquals(RECOMMENDED_TOKEN_TTL_MS, 7 * DAY)
})

Deno.test('MeInvoiceAuth newly minted token defaults to 7 days TTL (recommendedTokenTtl)', async () => {
  const fetchFn = mockFetch(() => jsonResponse({ Success: true, Data: 'token-7d' }))
  const auth = new MeInvoiceAuth({ baseUrl: BASE, appId: 'a', taxCode: 't', username: 'u', password: 'p', fetchFn })
  const token = await auth.getToken()
  assertEquals(token.value, 'token-7d')
  const diffDays = Math.trunc((token.expiresAt.getTime() - Date.now()) / DAY)
  assertEquals(diffDays >= 6, true)
  assertEquals(diffDays <= 7, true)
})

Deno.test('MeInvoiceAuth token automatically re-logins after 7 days expiry', async () => {
  let loginCount = 0
  const fetchFn = mockFetch(() => {
    loginCount++
    return jsonResponse({ Success: true, Data: `token-${loginCount}` })
  })
  const auth = new MeInvoiceAuth({ baseUrl: BASE, appId: 'a', taxCode: 't', username: 'u', password: 'p', fetchFn })
  const first = await auth.getToken()
  assertEquals(first.value, 'token-1')
  assertEquals(loginCount, 1)

  // Verify still valid right before 7 days
  assertEquals(first.isExpired({ now: new Date(Date.now() + 6 * DAY) }), false)
  // Verify expired at 7 days
  assertEquals(first.isExpired({ now: new Date(Date.now() + 7 * DAY + 60_000) }), true)

  // Simulating expiry in cache to verify seamless re-login
  auth.seed(new MeInvoiceAuthToken('old-token', new Date(Date.now() - 5 * 60_000)))
  const refreshed = await auth.getToken()
  assertEquals(refreshed.value, 'token-2')
  assertEquals(loginCount, 2)
})
