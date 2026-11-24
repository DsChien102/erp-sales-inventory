import {
  MeInvoicePublishErrorCodes,
  type MeInvoiceResult,
  type MeInvoiceSendEmailResponse,
  MeInvoiceSendEmailResponseKind,
} from '../../misa/mod.ts'
import { safeErrorCode } from '../issued_invoice/provider_call_support.ts'
import type { DeliveryProviderOutcome } from './outcomes.ts'

const DEFINITE_AUTH_OR_CREDENTIAL_CODES = new Set<string>([
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
  'TokenExpiredCode',
  'missing_MISA_MEINVOICE_APP_ID',
])

export function classifyDelivery(
  result: MeInvoiceResult<MeInvoiceSendEmailResponse>,
  transactionId: string,
): DeliveryProviderOutcome {
  if (result.rateLimited || isRateLimited(result.error)) {
    return {
      kind: 'retryableFailure',
      safeErrorCode: safeErrorCode(result.error ?? 'RATE_LIMITED'),
    }
  }

  if (result.isSuccess) {
    const response = result.data
    if (!response) {
      return {
        kind: 'undetermined',
        safeErrorCode: 'PROVIDER_UNEXPECTED_SUCCESS_SHAPE',
      }
    }

    if (response.kind === MeInvoiceSendEmailResponseKind.envelopeAcknowledgement) {
      return { kind: 'succeeded', providerReference: null }
    }

    const items = response.items ?? []
    if (
      transactionId.length === 0 ||
      items.length !== 1 ||
      items[0].transactionId !== transactionId
    ) {
      return {
        kind: 'undetermined',
        safeErrorCode: 'PROVIDER_UNEXPECTED_SUCCESS_SHAPE',
      }
    }

    const item = items[0]
    if (item.sendEmailStatus === 3 && (!item.errorCode || item.errorCode.trim().length === 0)) {
      return { kind: 'succeeded', providerReference: null }
    }

    if (item.sendEmailStatus === 2) {
      return {
        kind: 'definiteFailure',
        safeErrorCode: safeErrorCode(item.errorCode ?? 'PROVIDER_EMAIL_FAILED'),
      }
    }

    return {
      kind: 'undetermined',
      safeErrorCode: 'PROVIDER_EMAIL_NOT_CONFIRMED',
    }
  }

  const error = result.error ?? 'unknown_error'
  const code = safeErrorCode(error)

  if (isAmbiguousTransport(error)) {
    return { kind: 'undetermined', safeErrorCode: code }
  }

  if (isDefiniteAuthOrCredential(code, error)) {
    return { kind: 'definiteFailure', safeErrorCode: 'PROVIDER_AUTH_FAILED' }
  }

  if (MeInvoicePublishErrorCodes.isDefiniteFailure(code)) {
    return { kind: 'definiteFailure', safeErrorCode: code }
  }

  return { kind: 'undetermined', safeErrorCode: code }
}

function isRateLimited(error?: string | null): boolean {
  if (!error) return false
  const normalized = error.toLowerCase()
  return normalized.includes('rate_limited') || normalized.includes('429')
}

function isAmbiguousTransport(error: string): boolean {
  const normalized = error.toLowerCase()
  return (
    normalized.includes('timeout') ||
    normalized.includes('meinvoice_network') ||
    normalized.includes('connection') ||
    normalized.includes('meinvoice_5xx') ||
    normalized.includes('unavailable') ||
    normalized.includes('meinvoice_invalid_response') ||
    normalized.includes('not a json object') ||
    normalized.includes('malformed')
  )
}

function isDefiniteAuthOrCredential(code: string, error: string): boolean {
  if (DEFINITE_AUTH_OR_CREDENTIAL_CODES.has(code)) {
    return true
  }
  const vendorToken = vendorTokenAfterColon(error)
  return vendorToken !== null && DEFINITE_AUTH_OR_CREDENTIAL_CODES.has(vendorToken)
}

function vendorTokenAfterColon(error: string): string | null {
  const separator = error.indexOf(':')
  if (separator < 0) return null
  const after = error.substring(separator + 1).trim()
  if (after.length === 0) return null
  const match = after.match(/^[A-Za-z][A-Za-z0-9_]{0,63}/)
  return match ? match[0] : null
}
