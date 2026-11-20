import { MeInvoiceResult } from '../models/me_invoice_result.ts'

const AUTH_ERROR_CODES = new Set([
  'InvalidAppID',
  'InactiveAppID',
  'TaxCodeNotExist',
  'InactiveTaxCode',
  'UserNotExist',
  'WrongPassWord',
  'InactiveUser',
  'MisaIdError',
  'TwoFactorAuthen',
  'UnAuthorize',
])

function truncate(value: string, max = 200): string {
  return value.length <= max ? value : `${value.substring(0, max)}…`
}

function isObj(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null && !Array.isArray(v)
}

/** Maps HTTP / vendor error payloads to MeInvoiceResult failures. */
export const MeInvoiceErrorMapper = {
  tokenExpiredCode: 'TokenExpiredCode',

  fromHttp<T>(opts: { statusCode: number; body: string }): MeInvoiceResult<T> {
    if (opts.statusCode === 429) {
      return MeInvoiceResult.failed<T>('meinvoice_429_rate_limited', { rateLimited: true })
    }
    const vendorCode = MeInvoiceErrorMapper.tryReadErrorCode(opts.body)
    if (vendorCode === 'TokenExpiredCode') {
      return MeInvoiceResult.failed<T>('TokenExpiredCode')
    }
    const message = vendorCode ?? truncate(opts.body)
    return MeInvoiceResult.failed<T>(`meinvoice_${opts.statusCode}: ${message}`)
  },

  fromVendorPayload<T>(map: Record<string, unknown>): MeInvoiceResult<T> {
    const codeRaw = map['ErrorCode'] ?? map['errorCode'] ?? map['code']
    const code = codeRaw === null || codeRaw === undefined ? null : String(codeRaw)
    const message = String(
      map['ErrorMessage'] ?? map['descriptionErrorCode'] ?? map['Errors'] ?? map['errors'] ??
        code ?? 'vendor_error',
    )
    if (code === 'TokenExpiredCode' || message.includes('TokenExpiredCode')) {
      return MeInvoiceResult.failed<T>('TokenExpiredCode')
    }
    return MeInvoiceResult.failed<T>(code === null || code === '' ? message : `${code}: ${message}`)
  },

  tryReadErrorCode(body: string): string | null {
    try {
      const decoded = JSON.parse(body)
      if (isObj(decoded)) {
        const code = decoded['ErrorCode'] ?? decoded['errorCode']
        if (typeof code === 'string' && code !== '') return code
      }
    } catch {
      // ignore parse errors
    }
    return null
  },

  /**
   * Reads the most specific documented authentication code without exposing
   * MISA's full response body.
   */
  tryReadAuthErrorCode(body: string): string | null {
    try {
      const decoded = JSON.parse(body)
      if (!isObj(decoded)) return null
      const errors = decoded['Errors'] ?? decoded['errors']
      if (Array.isArray(errors)) {
        for (const error of errors) {
          const text = error === null || error === undefined ? '' : String(error)
          for (const code of AUTH_ERROR_CODES) {
            if (code !== 'UnAuthorize' && text.includes(code)) return code
          }
        }
      }
      const outer = decoded['ErrorCode'] ?? decoded['errorCode']
      const outerCode = outer === null || outer === undefined ? null : String(outer)
      return outerCode !== null && AUTH_ERROR_CODES.has(outerCode) ? outerCode : null
    } catch {
      return null
    }
  },
}
