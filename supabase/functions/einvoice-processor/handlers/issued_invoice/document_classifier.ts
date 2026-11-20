import {
  MeInvoiceInvoiceDataPublished,
  MeInvoiceResult,
} from '../../misa/mod.ts'
import { validateDocumentContent } from './document_content_policy.ts'
import { DocumentOutcome, DocumentType } from './outcomes.ts'
import {
  isAuthOrConfigRejection,
  isEmptyProviderPayload,
  safeErrorCode,
  throwIfTransportAmbiguous,
} from './provider_call_support.ts'

export function classifyDocument(input: {
  result: MeInvoiceResult<MeInvoiceInvoiceDataPublished[]>
  documentType: DocumentType
  providerInvoiceReference: string
}): DocumentOutcome {
  const { result, documentType, providerInvoiceReference } = input
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
      }
    }
    return {
      kind: 'checkRequired',
      safeErrorCode: safeErrorCode(error),
      providerReference: providerInvoiceReference,
    }
  }

  const items = result.data
  if (items === null || items.length === 0) {
    return {
      kind: 'definiteFailure',
      failureCode: 'DOCUMENT_UNAVAILABLE',
      failureMessage: null,
    }
  }

  const item = items[0]
  if (
    item.transactionId.trim() !== '' &&
    item.transactionId !== providerInvoiceReference
  ) {
    return {
      kind: 'checkRequired',
      safeErrorCode: 'PROVIDER_IDENTITY_MISMATCH',
      providerReference: providerInvoiceReference,
    }
  }

  const bytes = item.bytes ?? new Uint8Array(0)
  if (bytes.length === 0) {
    return {
      kind: 'definiteFailure',
      failureCode: 'DOCUMENT_UNAVAILABLE',
      failureMessage: null,
    }
  }

  const validationError = validateDocumentContent(documentType, bytes)
  if (validationError !== null) {
    return {
      kind: 'checkRequired',
      safeErrorCode: validationError,
      providerReference: providerInvoiceReference,
    }
  }

  return {
    kind: 'success',
    bytes,
    providerReference: providerInvoiceReference,
  }
}

