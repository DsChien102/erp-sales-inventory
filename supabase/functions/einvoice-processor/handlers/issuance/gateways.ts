import type { IssuanceResultEvidence } from './outcomes.ts'

export interface PreviewResultStore {
  store(input: {
    tenantId: string
    salesOrderId: string
    requestId: string
    status: 'READY' | 'FAILED'
    viewerRef?: string
    failureCode?: string
    failureMessage?: string | null
    failureSource?: 'PROVIDER' | 'INTERNAL'
  }): Promise<void>
}

export type PublishPreparationAction = 'CALL_PROVIDER' | 'RECONCILE_ONLY' | 'SKIP'

export interface IssuanceResultGateway {
  preparePublish(i: {
    tenantId: string
    attemptId: string
    idempotencyKey: string
    payloadHash: string
    canonicalInvoice: Record<string, unknown>
  }): Promise<PublishPreparationAction>
  markProviderCallStarted(tenantId: string, attemptId: string): Promise<void>
  recordSuccess(
    tenantId: string,
    attemptId: string,
    e: Extract<IssuanceResultEvidence, { kind: 'success' }>,
  ): Promise<void>
  recordDefiniteFailure(
    tenantId: string,
    attemptId: string,
    e: Extract<IssuanceResultEvidence, { kind: 'definiteFailure' }>,
  ): Promise<void>
  recordUndetermined(
    tenantId: string,
    attemptId: string,
    e: Extract<IssuanceResultEvidence, { kind: 'undetermined' }>,
  ): Promise<void>
  recordRetryableProviderRejection(i: {
    tenantId: string
    attemptId: string
    sourceCommandId: string
    evidence: Extract<IssuanceResultEvidence, { kind: 'retryableProviderRejection' }>
    retryAfterSeconds: number
  }): Promise<void>
  recordCommandIntegrityFailure(tenantId: string, attemptId: string, reasonCode: string): Promise<void>
  recordPublishCommandDeadLetter(tenantId: string, attemptId: string, reasonCode: string): Promise<void>
}

export type LeaseAcquireOutcome =
  | { kind: 'acquired'; providerConnectionId: string; invoiceSeries: string; leaseVersion: number }
  | { kind: 'busy'; retryAfterSeconds: number }

export interface PublishSeriesLeaseGateway {
  tryAcquire(tenantId: string, attemptId: string, ownerToken: string): Promise<LeaseAcquireOutcome>
  release(i: {
    tenantId: string
    providerConnectionId: string
    invoiceSeries: string
    ownerToken: string
    leaseVersion: number
  }): Promise<void>
}

export interface ReconciliationPollContext {
  caseId: string
  attemptId: string
  claimToken: string
  idempotencyKey: string
  payloadHash: string
  invoiceSeries: string
  providerReference: string | null
  reconciliationReasonCode: string | null
  checkSequence: number
  maxChecks: number
}

export interface ReconciliationGateway {
  claim(tenantId: string, caseId: string, workerId: string): Promise<ReconciliationPollContext | null>
  recordPendingCheck(i: {
    tenantId: string
    caseId: string
    claimToken: string
    nextDelaySeconds: number
    checkSequence: number
  }): Promise<void>
  resolve(i: {
    tenantId: string
    caseId: string
    outcome: 'SUCCESS' | 'FAILURE' | 'PUBLISH_RETRY_SCHEDULED' | 'UNRESOLVED'
    evidence?: Record<string, unknown>
  }): Promise<void>
}

export interface IssuanceGateways {
  preview: PreviewResultStore
  results: IssuanceResultGateway
  lease: PublishSeriesLeaseGateway
  reconciliation: ReconciliationGateway
}

