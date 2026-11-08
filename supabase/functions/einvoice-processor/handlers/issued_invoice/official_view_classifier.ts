import { MeInvoiceResult, MeInvoiceViewUrlPolicy } from '../../misa/mod.ts'
import { OFFICIAL_VIEW_LEASE_MINUTES, OfficialViewOutcome } from './outcomes.ts'
import {
  isAuthOrConfigRejection,
  isEmptyProviderPayload,
  safeErrorCode,
  throwIfTransportAmbiguous,
} from './provider_call_support.ts'

export function classifyOfficialView(input: {
  result: MeInvoiceResult<string>
  providerInvoiceReference: string
  now: Date
}): OfficialViewOutcome {
  const { result, providerInvoiceReference, now } = input
  if (!result.isSuccess) {
    const error = result.error ?? 'unknown_error'
    throwIfTransportAmbiguous(error)
    if (isAuthOrConfigRejection(error)) {
      return {
        kind: 'checkRequired',
        safeErrorCode: 'PROVIDER_AUTH_FAILED',
        providerReference: providerInvoiceReference,
      }
    }
    if (isEmptyProviderPayload(error)) {
      return {
        kind: 'definiteFailure',
        failureCode: 'DOCUMENT_UNAVAILABLE',
        failureMessage: null,
        providerReference: providerInvoiceReference,
      }
    }
    return {
      kind: 'checkRequired',
      safeErrorCode: safeErrorCode(error),
      providerReference: providerInvoiceReference,
    }
  }

  const viewerUrl = MeInvoiceViewUrlPolicy.tryParse(result.data)
  if (viewerUrl === null) {
    return {
      kind: 'definiteFailure',
      failureCode: 'DOCUMENT_UNAVAILABLE',
      failureMessage: null,
      providerReference: null,
    }
  }

  const expiresAt = new Date(
    now.getTime() + OFFICIAL_VIEW_LEASE_MINUTES * 60 * 1000,
  )
  return {
    kind: 'success',
    viewerUrl,
    expiresAt,
    providerReference: providerInvoiceReference,
  }
}

