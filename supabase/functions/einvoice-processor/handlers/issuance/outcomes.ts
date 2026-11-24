export type PreviewOutcome =
  | { kind: 'success'; viewerRef: string }
  | { kind: 'providerUnavailable' }
  | { kind: 'invalidData'; detail: string | null }
  | { kind: 'authFailed' }

export interface SafeProviderEvidence {
  refId?: string | null
  transactionId?: string | null
  invoiceNumber?: string | null
  invoiceSeries?: string | null
  providerCode?: string | null
  providerMessage?: string | null
}

export type PublishOutcome =
  | { kind: 'success'; providerReference: string; invoiceNumber: string; invoiceSeries: string; issuedAt: Date; safeProviderEvidence: SafeProviderEvidence }
  | { kind: 'definiteFailure'; providerCode: string; providerMessage: string; safeProviderEvidence: SafeProviderEvidence }
  | { kind: 'retryableRejection'; providerCode: string; providerMessage: string; retryAfterSeconds: number; safeProviderEvidence: SafeProviderEvidence }
  | { kind: 'undetermined'; reasonCode: string; safeProviderEvidence: SafeProviderEvidence }

export type IssuanceResultEvidence =
  | { kind: 'success'; idempotencyKey: string; payloadHash: string; providerReference: string; invoiceNumber: string; invoiceSeries: string; issuedAt: Date }
  | { kind: 'definiteFailure'; idempotencyKey: string; payloadHash: string; providerCode: string; providerMessage: string }
  | { kind: 'undetermined'; idempotencyKey: string; payloadHash: string; reasonCode: string }
  | { kind: 'retryableProviderRejection'; idempotencyKey: string; payloadHash: string; providerCode: string; providerMessage: string }

export type IssuanceStatusOutcome =
  | { kind: 'success'; evidence: Extract<IssuanceResultEvidence, { kind: 'success' }> }
  | { kind: 'definiteFailure'; evidence: Extract<IssuanceResultEvidence, { kind: 'definiteFailure' }> }
  | { kind: 'pending' }
  | { kind: 'undetermined'; reasonCode: string }

export type StatusLookup = 'providerTransactionId' | 'refId'

export const PUBLISH_UNDETERMINED_REASON = {
  duplicateInvoiceRefId: 'DUPLICATE_INVOICE_REF_ID',
  invoiceDuplicatedReconcileFirst: 'INVOICE_DUPLICATED_RECONCILE_FIRST',
} as const

export const MISA_PUBLISH_PROVIDER_CODES = {
  invoiceNumberNotContinuous: 'InvoiceNumberNotCotinuous',
  invoiceDuplicated: 'InvoiceDuplicated',
} as const

export const RECONCILIATION_MAX_CHECKS = 5

export function delayBeforeCheckSeconds(checkSequence: number): number {
  if (checkSequence < 1 || checkSequence > RECONCILIATION_MAX_CHECKS) {
    throw new RangeError(
      `checkSequence must be between 1 and ${RECONCILIATION_MAX_CHECKS} inclusive (got ${checkSequence})`,
    )
  }
  switch (checkSequence) {
    case 1:
      return 30
    case 2:
      return 120
    case 3:
      return 600
    case 4:
      return 1800
    case 5:
      return 7200
    default:
      throw new RangeError(`checkSequence must be between 1 and ${RECONCILIATION_MAX_CHECKS}`)
  }
}

export function shouldMarkUnresolved(completedChecks: number): boolean {
  return completedChecks >= RECONCILIATION_MAX_CHECKS
}

export const MIN_INVOICE_NUMBER_NOT_CONTINUOUS_BACKOFF_SECONDS = 5

