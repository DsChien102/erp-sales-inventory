import { RECOMMENDED_TOKEN_TTL_MS, DEFAULT_REQUEST_TIMEOUT_MS } from '../models/me_invoice_config.ts'
import { MeInvoiceErrorMapper } from './error_mapper.ts'
import { type FetchLike, TimeoutException, withTimeout } from './timeout.ts'

const SKEW_MS = 60_000

/** Cached access token for meInvoice API. */
export class MeInvoiceAuthToken {
  constructor(readonly value: string, readonly expiresAt: Date) {}

  isExpired(opts: { now?: Date; skewMs?: number } = {}): boolean {
    const clock = opts.now ?? new Date()
    const skew = opts.skewMs ?? SKEW_MS
    return !(clock.getTime() < this.expiresAt.getTime() - skew)
  }
}

/** Thrown when login / refresh fails hard. */
export class MeInvoiceAuthException extends Error {
  constructor(override readonly message: string) {
    super(message)
    this.name = 'MeInvoiceAuthException'
  }

  override toString(): string {
    return `MeInvoiceAuthException(${this.message})`
  }
}

export interface MeInvoiceAuthOptions {
  baseUrl: string
  appId?: string | null
  taxCode?: string | null
  username?: string | null
  password?: string | null
  fetchFn: FetchLike
  initialToken?: MeInvoiceAuthToken | null
  defaultTtlMs?: number
  requestTimeoutMs?: number
  /** Clock used for newly minted tokens (tests). */
  now?: () => Date
}

/**
 * Obtains and caches Bearer tokens; supports one refresh on expiry.
 * Calling /auth/token on every invoice risks MISA IP blocks.
 */
export class MeInvoiceAuth {
  readonly baseUrl: string
  readonly appId: string | null
  readonly taxCode: string | null
  readonly username: string | null
  readonly password: string | null
  readonly #fetch: FetchLike
  readonly #defaultTtlMs: number
  readonly #requestTimeoutMs: number
  readonly #now: () => Date
  #cached: MeInvoiceAuthToken | null

  constructor(o: MeInvoiceAuthOptions) {
    this.baseUrl = o.baseUrl
    this.appId = o.appId ?? null
    this.taxCode = o.taxCode ?? null
    this.username = o.username ?? null
    this.password = o.password ?? null
    this.#fetch = o.fetchFn
    this.#defaultTtlMs = o.defaultTtlMs ?? RECOMMENDED_TOKEN_TTL_MS
    this.#requestTimeoutMs = o.requestTimeoutMs ?? DEFAULT_REQUEST_TIMEOUT_MS
    this.#now = o.now ?? (() => new Date())
    this.#cached = o.initialToken ?? null
  }

  get cachedToken(): MeInvoiceAuthToken | null {
    return this.#cached
  }

  /** Seeds or replaces the in-memory cache. */
  seed(token: MeInvoiceAuthToken): void {
    this.#cached = token
  }

  /** Clears cache (e.g. after TokenExpiredCode). */
  invalidate(): void {
    this.#cached = null
  }

  get canLogin(): boolean {
    return !!this.appId && !!this.taxCode && !!this.username && !!this.password
  }

  async getToken(opts: { forceRefresh?: boolean } = {}): Promise<MeInvoiceAuthToken> {
    const forceRefresh = opts.forceRefresh ?? false
    const cached = this.#cached
    if (!forceRefresh && cached !== null && !cached.isExpired({ now: this.#now() })) {
      return cached
    }
    if (forceRefresh && cached !== null) {
      const refreshed = await this.#tryRefresh(cached.value)
      if (refreshed !== null) {
        this.#cached = refreshed
        return refreshed
      }
    }
    if (!this.canLogin) {
      throw new MeInvoiceAuthException(
        cached !== null && cached.isExpired({ now: this.#now() })
          ? 'meinvoice_token_expired_relogin'
          : 'meinvoice_token_missing_relogin',
      )
    }
    const minted = await this.#login()
    this.#cached = minted
    return minted
  }

  async #tryRefresh(oldToken: string): Promise<MeInvoiceAuthToken | null> {
    const res = await this.#post(`${this.baseUrl}/auth/refreshtoken`, oldToken)
    if (res.status < 200 || res.status >= 300) return null
    return this.#parseTokenResponse(await res.text())
  }

  async #login(): Promise<MeInvoiceAuthToken> {
    const res = await this.#post(
      `${this.baseUrl}/auth/token`,
      JSON.stringify({
        appid: this.appId,
        taxcode: this.taxCode,
        username: this.username,
        password: this.password,
      }),
    )
    const text = await res.text()
    if (res.status < 200 || res.status >= 300) {
      const vendorCode = MeInvoiceErrorMapper.tryReadAuthErrorCode(text)
      throw new MeInvoiceAuthException(`meinvoice_auth_http_${res.status}:${vendorCode ?? 'request_failed'}`)
    }
    const token = this.#parseTokenResponse(text)
    if (token === null) {
      const vendorCode = MeInvoiceErrorMapper.tryReadAuthErrorCode(text)
      throw new MeInvoiceAuthException(
        vendorCode === null ? 'meinvoice_auth_invalid_response' : `meinvoice_auth_rejected:${vendorCode}`,
      )
    }
    return token
  }

  async #post(url: string, body: string): Promise<Response> {
    try {
      return await withTimeout(this.#requestTimeoutMs, (signal) =>
        this.#fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body,
          signal,
        }))
    } catch (e) {
      if (e instanceof TimeoutException) throw new MeInvoiceAuthException('meinvoice_network_timeout')
      throw e
    }
  }

  #parseTokenResponse(body: string): MeInvoiceAuthToken | null {
    try {
      const decoded = JSON.parse(body)
      if (typeof decoded !== 'object' || decoded === null || Array.isArray(decoded)) return null
      const success = decoded['Success'] ?? decoded['success']
      if (success === false) return null
      const data = decoded['Data'] ?? decoded['data']
      if (typeof data !== 'string' || data === '') return null
      return new MeInvoiceAuthToken(data, new Date(this.#now().getTime() + this.#defaultTtlMs))
    } catch {
      return null
    }
  }
}
