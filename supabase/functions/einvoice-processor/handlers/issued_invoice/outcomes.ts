export type DocumentType = 'PDF' | 'XML'
export type DocumentStatus = 'PENDING' | 'AVAILABLE' | 'FAILED' | 'CHECK_REQUIRED'
export type FailureSource = 'PROVIDER' | 'INTERNAL'

export interface ProviderContext {
  tenantId: string
  providerConnectionId: string
  electronicInvoiceId: string
  providerInvoiceReference: string
  invoiceSeries: string
  operationId: string
  documentType?: DocumentType | null
}

export type OfficialViewOutcome =
  | { kind: 'success'; viewerUrl: string; expiresAt: Date; providerReference: string | null }
  | { kind: 'checkRequired'; safeErrorCode: string; providerReference: string | null }
  | { kind: 'definiteFailure'; failureCode: string; failureMessage: string | null; providerReference: string | null }
  | { kind: 'ambiguous'; safeErrorCode: string }

export type DocumentOutcome =
  | { kind: 'success'; bytes: Uint8Array; providerReference: string | null }
  | { kind: 'checkRequired'; safeErrorCode: string; providerReference: string | null }
  | { kind: 'definiteFailure'; failureCode: string; failureMessage: string | null }
  | { kind: 'ambiguous'; safeErrorCode: string }

export type ObservationOutcome =
  | {
      kind: 'found'
      providerStateCode: string
      safeDescription: string
      observedAt: Date
      detailsSnapshot: Record<string, unknown>
      providerReference: string | null
    }
  | {
      kind: 'notFound' | 'mismatch'
      providerStateCode: string
      safeDescription: string
      observedAt: Date
      providerReference: string | null
    }
  | { kind: 'ambiguous'; safeErrorCode: string }

export const OFFICIAL_VIEW_LEASE_MINUTES = 5

export const OBSERVATION_DETAIL_KEYS = [
  'publishStatus',
  'eInvoiceStatus',
  'referenceType',
  'sendTaxStatus',
  'invoiceCode',
  'invNo',
  'invSeries',
  'publishedTime',
  'transactionId',
] as const

