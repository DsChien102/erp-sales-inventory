import {
  type MeInvoiceInvoiceStatus,
  MeInvoicePublishErrorCodes,
  type MeInvoiceResult,
} from '../../misa/mod.ts'
import type { IssuanceStatusOutcome } from './outcomes.ts'

function hasText(value: string | null | undefined): value is string {
  return typeof value === 'string' && value.trim().length > 0
}

function classifyError(options: {
  error: string
  idempotencyKey: string
  payloadHash: string
}): IssuanceStatusOutcome {
  const { error, idempotencyKey, payloadHash } = options
  const parts = error.split(':')
  const code = parts[0].trim()
  const message = parts.length > 1 ? parts.slice(1).join(':').trim() : code

  if (MeInvoicePublishErrorCodes.isDefiniteFailure(code)) {
    return {
      kind: 'definiteFailure',
      evidence: {
        kind: 'definiteFailure',
        idempotencyKey,
        payloadHash,
        providerCode: code,
        providerMessage: message,
      },
    }
  }

  return {
    kind: 'undetermined',
    reasonCode: code,
  }
}

/**
 * Classifies raw MISA getStatus responses into closed IssuanceStatusOutcome.
 *
 * Invariants:
 * - Never infers definite failure from network/parse/transport errors.
 * - Only terminal rejection codes (definiteFailureCodes) become definite failure.
 * - Returns success only when invoice number, series, and provider reference are present.
 * - Returns pending when status indicates still processing.
 * - Returns undetermined on transport errors, malformed responses, or unrecognized results.
 */
export function classifyIssuanceStatus(options: {
  statusResult: MeInvoiceResult<MeInvoiceInvoiceStatus[]>
  idempotencyKey: string
  payloadHash: string
}): IssuanceStatusOutcome {
  const { statusResult, idempotencyKey, payloadHash } = options

  if (!statusResult.isSuccess) {
    const error = statusResult.error ?? 'unknown_error'
    return classifyError({
      error,
      idempotencyKey,
      payloadHash,
    })
  }

  const statuses = statusResult.data
  if (statuses == null || statuses.length === 0) {
    return {
      kind: 'undetermined',
      reasonCode: 'STATUS_EMPTY_DATA',
    }
  }

  const item = statuses[0]

  // PublishStatus == 1 indicates published / issued in MISA meInvoice API.
  if (
    item.publishStatus === 1 &&
    hasText(item.invNo) &&
    hasText(item.invSeries) &&
    hasText(item.transactionId)
  ) {
    const issuedAt = item.publishedTime ?? new Date()
    return {
      kind: 'success',
      evidence: {
        kind: 'success',
        idempotencyKey,
        payloadHash,
        providerReference: item.transactionId,
        invoiceNumber: item.invNo,
        invoiceSeries: item.invSeries,
        issuedAt,
      },
    }
  }

  // Check if item contains an explicit definite failure code.
  if (hasText(item.invoiceCode) && MeInvoicePublishErrorCodes.isDefiniteFailure(item.invoiceCode)) {
    return {
      kind: 'definiteFailure',
      evidence: {
        kind: 'definiteFailure',
        idempotencyKey,
        payloadHash,
        providerCode: item.invoiceCode,
        providerMessage: item.invoiceCode,
      },
    }
  }

  // Pending / still processing (e.g. PublishStatus == 0 or other intermediate states)
  if (item.publishStatus === 0 || item.publishStatus == null) {
    return { kind: 'pending' }
  }

  // Default fallback for ambiguous states
  return { kind: 'pending' }
}

