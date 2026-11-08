import { ProviderCallAmbiguousError } from './errors.ts'

export function isTransportAmbiguous(error: string): boolean {
  const normalized = error.toLowerCase()
  return (
    normalized.includes('timeout') ||
    normalized.includes('meinvoice_network') ||
    normalized.includes('connection') ||
    normalized.includes('meinvoice_5xx') ||
    normalized.includes('unavailable') ||
    normalized.includes('rate_limited') ||
    normalized.includes('429')
  )
}

export function isAuthOrConfigRejection(error: string): boolean {
  const normalized = error.toLowerCase()
  return (
    normalized.includes('missing credential') ||
    normalized.includes('missing_misa') ||
    normalized.includes('tokenexpired') ||
    normalized.includes('auth') ||
    normalized.includes('unauthorized') ||
    normalized.includes('forbidden')
  )
}

export function isEmptyProviderPayload(error: string): boolean {
  const normalized = error.toLowerCase()
  return (
    normalized.includes('empty_data') ||
    normalized.includes('empty_or_invalid')
  )
}

export function safeErrorCode(error: string): string {
  const trimmed = error.trim()
  const separator = trimmed.indexOf(':')
  const candidate = separator >= 0 ? trimmed.substring(0, separator).trim() : trimmed
  const match = candidate.match(/^[A-Za-z][A-Za-z0-9_]{0,63}/)
  return match ? match[0] : 'UNKNOWN_PROVIDER_FAILURE'
}

export function throwIfTransportAmbiguous(error: string): void {
  if (isTransportAmbiguous(error)) {
    throw new ProviderCallAmbiguousError(safeErrorCode(error), error)
  }
}

