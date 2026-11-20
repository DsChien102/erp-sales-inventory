import type { FailureSource } from '../issued_invoice/outcomes.ts'

export type DeliveryResultKind = 'SUCCESS' | 'DEFINITE_FAILURE' | 'RETRYABLE_FAILURE' | 'UNDETERMINED'
export type ObservationKind = 'SUCCESS' | 'DEFINITE_FAILURE' | 'UNDETERMINED' | 'UNSUPPORTED'

export interface DeliveryResultEvidence {
  kind: DeliveryResultKind
  providerReference?: string | null
  safeCode?: string | null
  failureSource?: FailureSource | null
}

export interface DeliveryProviderContext {
  tenantId: string
  providerConnectionId: string
  providerTransactionId: string
  invoiceSeries: string
  recipientEmail: string
  recipientName: string | null
}

export type DeliveryProviderOutcome =
  | { kind: 'succeeded'; providerReference: string | null }
  | { kind: 'definiteFailure' | 'retryableFailure' | 'undetermined'; safeErrorCode: string }

export interface DeliveryObservationContext {
  tenantId: string
  reconciliationCaseId: string
  deliveryId: string
  providerConnectionId: string
  providerDeliveryReference: string | null
}

export type DeliveryObservationOutcome =
  | { kind: 'succeeded'; providerReference: string | null }
  | { kind: 'definiteFailure' | 'undetermined'; safeCode: string }
  | { kind: 'unsupported' }
