/** Same CORS policy as `invitation-signup`: the web app calls `functions.invoke` (7-A1). */
export const CORS_HEADERS: Readonly<Record<string, string>> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

/** Browser preflight: `OPTIONS` → 204 with CORS headers; any other method → null. */
export function preflightResponse(method: string): Response | null {
  return method === 'OPTIONS' ? new Response(null, { status: 204, headers: CORS_HEADERS }) : null
}

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  })
}

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

export type AuthDecision =
  | { ok: true; tenantId: string | null }
  | { ok: false; status: 400 | 403 | 405; error: string }

/**
 * Reads the `role` claim of a Bearer JWT. The gateway (verify_jwt) already checked the
 * signature; this only decodes the payload. Non-JWT keys (e.g. `sb_secret_…`) yield null.
 */
export function readJwtRole(authorization: string | null): string | null {
  if (!authorization) return null
  const match = /^Bearer\s+(\S+)$/i.exec(authorization.trim())
  if (!match) return null
  const parts = match[1].split('.')
  if (parts.length !== 3) return null
  try {
    const b64 = parts[1].replace(/-/g, '+').replace(/_/g, '/')
    const json = new TextDecoder().decode(
      Uint8Array.from(atob(b64.padEnd(Math.ceil(b64.length / 4) * 4, '=')), (c) => c.charCodeAt(0)),
    )
    const payload = JSON.parse(json)
    return payload && typeof payload.role === 'string' ? payload.role : null
  } catch {
    return null
  }
}

/**
 * Without `tenant_id` (scan every tenant) only `service_role` may call. With `tenant_id`
 * any role may: the function only runs already-queued commands and returns no tenant data.
 */
export function authorizeRequest(method: string, role: string | null, body: unknown): AuthDecision {
  if (method !== 'POST') return { ok: false, status: 405, error: 'method_not_allowed' }
  const record = typeof body === 'object' && body !== null && !Array.isArray(body)
    ? body as Record<string, unknown>
    : {}
  const tenantId = record['tenant_id']
  if (tenantId !== undefined && tenantId !== null) {
    if (typeof tenantId !== 'string' || !UUID_PATTERN.test(tenantId)) {
      return { ok: false, status: 400, error: 'invalid_tenant_id' }
    }
    return { ok: true, tenantId }
  }
  if (role !== 'service_role') return { ok: false, status: 403, error: 'service_role_required' }
  return { ok: true, tenantId: null }
}
