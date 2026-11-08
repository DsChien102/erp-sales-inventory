import { assertEquals } from 'jsr:@std/assert@1'
import { authorizeRequest, CORS_HEADERS, jsonResponse, preflightResponse, readJwtRole } from './auth.ts'

const UUID = '3f2b7a52-6c1e-4d3a-9a0e-0d6f7a1c2b3d'

const b64url = (o: unknown) =>
  btoa(JSON.stringify(o)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')

Deno.test('GET is rejected with 405', () => {
  assertEquals(authorizeRequest('GET', 'service_role', {}), { ok: false, status: 405, error: 'method_not_allowed' })
})

Deno.test('service_role with empty body scans all tenants', () => {
  assertEquals(authorizeRequest('POST', 'service_role', {}), { ok: true, tenantId: null })
})

Deno.test('authenticated without tenant_id is 403', () => {
  assertEquals(authorizeRequest('POST', 'authenticated', {}), { ok: false, status: 403, error: 'service_role_required' })
})

Deno.test('authenticated with tenant_id is allowed', () => {
  assertEquals(authorizeRequest('POST', 'authenticated', { tenant_id: UUID }), { ok: true, tenantId: UUID })
})

Deno.test('invalid tenant_id is 400', () => {
  assertEquals(authorizeRequest('POST', 'service_role', { tenant_id: 'abc' }), { ok: false, status: 400, error: 'invalid_tenant_id' })
  assertEquals(authorizeRequest('POST', 'service_role', { tenant_id: 5 }), { ok: false, status: 400, error: 'invalid_tenant_id' })
})

Deno.test('null body is treated as {}', () => {
  assertEquals(authorizeRequest('POST', 'service_role', null), { ok: true, tenantId: null })
  assertEquals(authorizeRequest('POST', null, null), { ok: false, status: 403, error: 'service_role_required' })
})

Deno.test('readJwtRole decodes the role claim', () => {
  const jwt = `${b64url({ alg: 'HS256' })}.${b64url({ role: 'service_role' })}.sig`
  assertEquals(readJwtRole(`Bearer ${jwt}`), 'service_role')
})

Deno.test('readJwtRole returns null for garbage or missing Bearer', () => {
  assertEquals(readJwtRole(null), null)
  assertEquals(readJwtRole('Bearer garbage'), null)
  assertEquals(readJwtRole('Bearer a.b.c'), null)
  assertEquals(readJwtRole(`${b64url({})}.${b64url({ role: 'service_role' })}.sig`), null)
  assertEquals(readJwtRole('Bearer sb_secret_abc'), null)
})

Deno.test('OPTIONS preflight returns 204 with CORS headers', () => {
  const res = preflightResponse('OPTIONS')!
  assertEquals(res.status, 204)
  assertEquals(res.headers.get('Access-Control-Allow-Origin'), '*')
  assertEquals(res.headers.get('Access-Control-Allow-Methods'), 'POST, OPTIONS')
  assertEquals(res.headers.get('Access-Control-Allow-Headers'), 'authorization, x-client-info, apikey, content-type')
})

Deno.test('non-OPTIONS requests are not preflight', () => {
  assertEquals(preflightResponse('POST'), null)
  assertEquals(preflightResponse('GET'), null)
})

Deno.test('json responses carry CORS headers', async () => {
  const res = jsonResponse({ error: 'service_role_required' }, 403)
  assertEquals(res.status, 403)
  assertEquals(res.headers.get('Content-Type'), 'application/json')
  for (const [k, v] of Object.entries(CORS_HEADERS)) assertEquals(res.headers.get(k), v)
  assertEquals(await res.json(), { error: 'service_role_required' })
})
