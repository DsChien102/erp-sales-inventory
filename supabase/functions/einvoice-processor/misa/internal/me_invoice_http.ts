import { MeInvoiceResult } from '../models/me_invoice_result.ts'
import type { MeInvoiceApiResponse } from '../models/responses/api_response.ts'
import { MeInvoiceApiResponseParser } from './api_response_parser.ts'
import { MeInvoiceErrorMapper } from './error_mapper.ts'
import { MeInvoiceAuth, MeInvoiceAuthException } from './me_invoice_auth.ts'
import { type FetchLike, TimeoutException, withTimeout } from './timeout.ts'

export type { FetchLike } from './timeout.ts'

/** Low-level authenticated HTTP helper for meInvoice. */
export class MeInvoiceHttp {
  readonly auth: MeInvoiceAuth
  readonly #fetch: FetchLike
  readonly #requestTimeoutMs: number

  constructor(opts: { auth: MeInvoiceAuth; fetchFn: FetchLike; requestTimeoutMs: number }) {
    this.auth = opts.auth
    this.#fetch = opts.fetchFn
    this.#requestTimeoutMs = opts.requestTimeoutMs
  }

  get(path: string, opts: { query?: Record<string, string> | null } = {}): Promise<MeInvoiceResult<MeInvoiceApiResponse>> {
    return this.#send(async (signal) => {
      const token = await this.auth.getToken()
      return this.#fetch(this.#uri(path, opts.query), {
        method: 'GET',
        headers: this.#headers(token.value),
        signal,
      })
    })
  }

  postJson(
    path: string,
    opts: { body?: unknown; query?: Record<string, string> | null; extraHeaders?: Record<string, string> | null } = {},
  ): Promise<MeInvoiceResult<MeInvoiceApiResponse>> {
    return this.#send(async (signal) => {
      const token = await this.auth.getToken()
      return this.#fetch(this.#uri(path, opts.query), {
        method: 'POST',
        headers: this.#headers(token.value, opts.extraHeaders),
        body: opts.body == null ? undefined : JSON.stringify(opts.body),
        signal,
      })
    })
  }

  postRaw(
    path: string,
    opts: { body: string; query?: Record<string, string> | null; extraHeaders?: Record<string, string> | null },
  ): Promise<MeInvoiceResult<MeInvoiceApiResponse>> {
    return this.#send(async (signal) => {
      const token = await this.auth.getToken()
      return this.#fetch(this.#uri(path, opts.query), {
        method: 'POST',
        headers: this.#headers(token.value, opts.extraHeaders),
        body: opts.body,
        signal,
      })
    })
  }

  async #send(request: (signal: AbortSignal) => Promise<Response>): Promise<MeInvoiceResult<MeInvoiceApiResponse>> {
    try {
      const attempt = () =>
        withTimeout(this.#requestTimeoutMs, async (signal) => {
          const response = await request(signal)
          return { status: response.status, body: await response.text() }
        })
      let response = await attempt()
      if (MeInvoiceErrorMapper.tryReadErrorCode(response.body) === MeInvoiceErrorMapper.tokenExpiredCode) {
        await this.auth.getToken({ forceRefresh: true })
        response = await attempt()
      }
      if (response.status < 200 || response.status >= 300) {
        return MeInvoiceErrorMapper.fromHttp({ statusCode: response.status, body: response.body })
      }
      return MeInvoiceApiResponseParser.parse(response.body)
    } catch (e) {
      if (e instanceof MeInvoiceAuthException) return MeInvoiceResult.failed(e.message)
      if (e instanceof TimeoutException) return MeInvoiceResult.failed('meinvoice_network_timeout')
      return MeInvoiceResult.failed(`meinvoice_network: ${e}`)
    }
  }

  #uri(path: string, query?: Record<string, string> | null): string {
    const base = this.auth.baseUrl
    const root = base.endsWith('/') ? base.substring(0, base.length - 1) : base
    const normalized = path.startsWith('/') ? path : `/${path}`
    const url = new URL(`${root}${normalized}`)
    if (query) {
      url.search = ''
      for (const [k, v] of Object.entries(query)) url.searchParams.set(k, v)
    }
    return url.toString()
  }

  #headers(token: string, extra?: Record<string, string> | null): Record<string, string> {
    return { 'Content-Type': 'application/json', Authorization: `Bearer ${token}`, ...(extra ?? {}) }
  }
}
