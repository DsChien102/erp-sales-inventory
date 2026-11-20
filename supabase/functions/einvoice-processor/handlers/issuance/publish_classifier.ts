import {
  MeInvoicePublishErrorCodes,
  type MeInvoicePublishInvoiceResultItem,
  type MeInvoiceResult,
} from '../../misa/mod.ts'
import {
  PUBLISH_UNDETERMINED_REASON,
  type PublishOutcome,
  type SafeProviderEvidence,
} from './outcomes.ts'

function hasText(value: string | null | undefined): value is string {
  return typeof value === 'string' && value.trim().length > 0
}

function safeMessage(item: MeInvoicePublishInvoiceResultItem): string {
  const description = item.descriptionErrorCode?.trim()
  if (description != null && description.length > 0) {
    return description.length <= 200 ? description : `${description.slice(0, 200)}…`
  }
  return item.errorCode ?? 'provider_error'
}

function safeEvidence(item: MeInvoicePublishInvoiceResultItem): SafeProviderEvidence {
  return {
    refId: item.refId ?? null,
    transactionId: item.transactionId ?? null,
    invoiceNumber: item.invNo ?? null,
    invoiceSeries: item.invSeries ?? null,
    providerCode: item.errorCode ?? null,
    providerMessage: safeMessage(item),
  }
}

function resolveIssuedAt(canonicalInvoice: Record<string, unknown>): Date {
  const invDate = canonicalInvoice['invDate']
  if (typeof invDate === 'string' && invDate.length > 0) {
    const parts = invDate.split('-')
    if (parts.length === 3) {
      const year = parseInt(parts[0], 10)
      const month = parseInt(parts[1], 10)
      const day = parseInt(parts[2], 10)
      if (!Number.isNaN(year) && !Number.isNaN(month) && !Number.isNaN(day)) {
        return new Date(Date.UTC(year, month - 1, day))
      }
    }
    const parsed = new Date(invDate)
    if (!Number.isNaN(parsed.getTime())) {
      return parsed
    }
  }
  return new Date()
}

function isEnvelopeDefiniteFailure(error: string): boolean {
  const code = error.split(':')[0].trim()
  return MeInvoicePublishErrorCodes.isPublishRejection(code)
}

function classifyTransportOrEnvelopeFailure(options: {
  idempotencyKey: string
  error: string
}): PublishOutcome {
  const { idempotencyKey, error } = options
  const normalized = error.toLowerCase()

  if (
    normalized.includes('timeout') ||
    normalized.includes('meinvoice_network') ||
    normalized.includes('connection')
  ) {
    return {
      kind: 'undetermined',
      reasonCode: 'PROVIDER_TIMEOUT',
      safeProviderEvidence: { refId: idempotencyKey },
    }
  }

  if (
    normalized.includes('meinvoice_invalid_response') ||
    normalized.includes('not a json object')
  ) {
    return {
      kind: 'undetermined',
      reasonCode: 'PROVIDER_MALFORMED_RESPONSE',
      safeProviderEvidence: { refId: idempotencyKey },
    }
  }

  if (isEnvelopeDefiniteFailure(error)) {
    const parts = error.split(':')
    const code = parts[0].trim()
    const message = parts.length > 1 ? parts.slice(1).join(':').trim() : code
    return {
      kind: 'definiteFailure',
      providerCode: code,
      providerMessage: message,
      safeProviderEvidence: {
        refId: idempotencyKey,
        providerCode: code,
        providerMessage: message,
      },
    }
  }

  return {
    kind: 'undetermined',
    reasonCode: 'PROVIDER_TRANSPORT_ERROR',
    safeProviderEvidence: { refId: idempotencyKey },
  }
}

export function classifyPublish(options: {
  idempotencyKey: string
  result: MeInvoiceResult<MeInvoicePublishInvoiceResultItem[]>
  canonicalInvoice: Record<string, unknown>
}): PublishOutcome {
  const { idempotencyKey, result, canonicalInvoice } = options

  if (!result.isSuccess) {
    return classifyTransportOrEnvelopeFailure({
      idempotencyKey,
      error: result.error ?? 'meinvoice_unknown_error',
    })
  }

  const items = result.data ?? []
  if (items.length === 0) {
    return {
      kind: 'undetermined',
      reasonCode: 'PROVIDER_EMPTY_RESULT',
      safeProviderEvidence: { refId: idempotencyKey },
    }
  }

  const item = items[0]

  if (MeInvoicePublishErrorCodes.isDuplicateRefId(item.errorCode)) {
    return {
      kind: 'undetermined',
      reasonCode: PUBLISH_UNDETERMINED_REASON.duplicateInvoiceRefId,
      safeProviderEvidence: safeEvidence(item),
    }
  }

  if (MeInvoicePublishErrorCodes.isRetryableProviderRejection(item.errorCode)) {
    return {
      kind: 'retryableRejection',
      providerCode: item.errorCode!,
      providerMessage: safeMessage(item),
      retryAfterSeconds: 5,
      safeProviderEvidence: safeEvidence(item),
    }
  }

  if (MeInvoicePublishErrorCodes.isReconcileFirstDuplicate(item.errorCode)) {
    return {
      kind: 'undetermined',
      reasonCode: PUBLISH_UNDETERMINED_REASON.invoiceDuplicatedReconcileFirst,
      safeProviderEvidence: safeEvidence(item),
    }
  }

  if (item.refId != null && item.refId.length > 0 && item.refId !== idempotencyKey) {
    return {
      kind: 'undetermined',
      reasonCode: 'PROVIDER_UNCORRELATED_RESPONSE',
      safeProviderEvidence: safeEvidence(item),
    }
  }

  if (
    item.isSuccess &&
    hasText(item.transactionId) &&
    hasText(item.invNo) &&
    hasText(item.invSeries)
  ) {
    return {
      kind: 'success',
      providerReference: item.transactionId,
      invoiceNumber: item.invNo,
      invoiceSeries: item.invSeries,
      issuedAt: resolveIssuedAt(canonicalInvoice),
      safeProviderEvidence: safeEvidence(item),
    }
  }

  if (!item.isSuccess && MeInvoicePublishErrorCodes.isPublishRejection(item.errorCode)) {
    return {
      kind: 'definiteFailure',
      providerCode: item.errorCode!,
      providerMessage: safeMessage(item),
      safeProviderEvidence: safeEvidence(item),
    }
  }

  if (!item.isSuccess) {
    return {
      kind: 'undetermined',
      reasonCode: 'PROVIDER_ITEM_ERROR',
      safeProviderEvidence: safeEvidence(item),
    }
  }

  return {
    kind: 'undetermined',
    reasonCode: 'PROVIDER_INCOMPLETE_SUCCESS',
    safeProviderEvidence: safeEvidence(item),
  }
}

