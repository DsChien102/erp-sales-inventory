/**
 * Connection settings for MeInvoiceClient.
 *
 * Auth modes: login (appId, taxCode, username, password) or Bearer (accessToken).
 */
export interface MeInvoiceConfig {
  baseUrl: string
  appId?: string | null
  taxCode?: string | null
  username?: string | null
  password?: string | null
  /** Pre-issued Bearer (from smoke token file or tenant token cache). */
  accessToken?: string | null
  accessTokenExpiresAt?: Date | null
  /** Upper bound for authentication and API requests (ms). */
  requestTimeoutMs?: number
}

export const TEST_BASE_URL = 'https://testapi.meinvoice.vn/api/integration'
export const PROD_BASE_URL = 'https://api.meinvoice.vn/api/integration'
/** MISA documents Bearer validity ~14 days; avoid login-per-request. */
export const DEFAULT_TOKEN_TTL_MS = 14 * 24 * 60 * 60 * 1000
/** MISA recommends refreshing token every 7 days. */
export const RECOMMENDED_TOKEN_TTL_MS = 7 * 24 * 60 * 60 * 1000
export const DEFAULT_REQUEST_TIMEOUT_MS = 60_000

export function hasBearerToken(c: MeInvoiceConfig): boolean {
  return c.accessToken != null && c.accessToken.trim() !== ''
}

export function hasLoginCredentials(c: MeInvoiceConfig): boolean {
  return !!c.appId && !!c.taxCode && !!c.username && !!c.password
}

/** Returns a stable error code when neither bearer nor login is usable. */
export function missingCredentialError(c: MeInvoiceConfig): string | null {
  if (c.baseUrl === '') return 'missing_MISA_MEINVOICE_BASE_URL'
  if (hasBearerToken(c)) return null
  if (!c.appId) return 'missing_MISA_MEINVOICE_APP_ID'
  if (!c.taxCode) return 'missing_MISA_MEINVOICE_TAX_CODE'
  if (!c.username) return 'missing_MISA_MEINVOICE_USERNAME'
  if (!c.password) return 'missing_MISA_MEINVOICE_PASSWORD'
  return null
}

export function hasCredentials(c: MeInvoiceConfig): boolean {
  return missingCredentialError(c) === null
}
