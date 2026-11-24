import type { FetchLike } from './internal/timeout.ts'

export interface MockRequest {
  url: URL
  method: string
  headers: Record<string, string>
  body: string
}

/** Counterpart of Dart `MockClient`: handler gets a parsed request, returns a Response (or throws). */
export function mockFetch(handler: (req: MockRequest) => Promise<Response> | Response): FetchLike {
  return async (input, init) => {
    const url = new URL(typeof input === 'string' ? input : input instanceof URL ? input.toString() : input.url)
    const headers: Record<string, string> = {}
    new Headers(init?.headers).forEach((v, k) => {
      headers[k.toLowerCase()] = v
    })
    const body = typeof init?.body === 'string' ? init.body : ''
    return await handler({ url, method: init?.method ?? 'GET', headers, body })
  }
}

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status })
}

export function textResponse(body: string, status = 200): Response {
  return new Response(body, { status })
}

export const inOneDay = (): Date => new Date(Date.now() + 24 * 60 * 60 * 1000)
