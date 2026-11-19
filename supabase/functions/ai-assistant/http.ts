// Chép từ einvoice-processor/auth.ts (không import chéo function).
export const CORS_HEADERS: Readonly<Record<string, string>> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-c45-app',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

export function preflightResponse(method: string): Response | null {
  return method === 'OPTIONS' ? new Response(null, { status: 204, headers: CORS_HEADERS }) : null
}

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  })
}
