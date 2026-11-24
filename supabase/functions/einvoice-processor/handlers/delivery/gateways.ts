import type {
  DeliveryProviderContext,
  DeliveryResultEvidence,
  ObservationKind,
} from './outcomes.ts'
import type { DeliveryProvider } from './delivery_provider.ts'
import type { DeliveryObservationProvider } from './delivery_observation_provider.ts'

export interface DeliveryAttemptContext {
  tenantId: string
  deliveryId: string
  retryCount: number
  deliveryVersion: number
  providerConnectionId: string
  providerTransactionId: string
  invoiceSeries: string
  recipientEmail: string
  recipientName: string | null
}

export type PrepareResult =
  | { action: 'CALL_PROVIDER'; deliveryVersion: number; providerContext: DeliveryProviderContext }
  | { action: 'SKIP' }
  | { action: 'RECORD_UNKNOWN'; deliveryVersion: number }

export interface DeliveryResultRecord {
  tenantId: string
  deliveryId: string
  retryCount: number
  expectedDeliveryVersion: number
  evidence: DeliveryResultEvidence
}

export interface ReconciliationContext {
  tenantId: string
  reconciliationCaseId: string
  deliveryId: string
  providerConnectionId: string
  supportsDeliveryResultObservation: boolean
  checkSequence: number
  caseVersion: number
  providerDeliveryReference: string | null
}

export interface ReconciliationCheckRecord {
  tenantId: string
  reconciliationCaseId: string
  expectedCaseVersion: number
  checkSequence: number
  kind: ObservationKind
  providerReference?: string | null
  safeCode?: string | null
}

export interface DeliveryGateway {
  loadAttemptContext(
    tenantId: string,
    deliveryId: string,
    retryCount: number,
  ): Promise<DeliveryAttemptContext | null>
  prepareProviderCall(
    tenantId: string,
    deliveryId: string,
    retryCount: number,
    requestReference: string,
  ): Promise<PrepareResult>
  recordResult(r: DeliveryResultRecord): Promise<void>
  recordCommandDeadLetter(
    tenantId: string,
    deliveryId: string,
    retryCount: number,
    safeFailureCode: string,
  ): Promise<void>
  loadReconciliationContext(
    tenantId: string,
    reconciliationCaseId: string,
    checkSequence: number,
  ): Promise<ReconciliationContext | null>
  recordReconciliationCheck(r: ReconciliationCheckRecord): Promise<void>
}

export interface DeliveryDeps {
  provider: DeliveryProvider
  observation: DeliveryObservationProvider
  gateway: DeliveryGateway
}
