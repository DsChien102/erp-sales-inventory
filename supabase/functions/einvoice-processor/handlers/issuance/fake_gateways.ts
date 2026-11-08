import { CanonicalValidationFault } from './errors.ts'
import type {
  IssuanceGateways,
  IssuanceResultGateway,
  LeaseAcquireOutcome,
  PreviewResultStore,
  PublishPreparationAction,
  PublishSeriesLeaseGateway,
  ReconciliationGateway,
  ReconciliationPollContext,
} from './gateways.ts'
import type { IssuanceProvider } from './issuance_provider.ts'
import type {
  IssuanceResultEvidence,
  IssuanceStatusOutcome,
  PreviewOutcome,
  PublishOutcome,
  StatusLookup,
} from './outcomes.ts'

export class FakePreviewResultStore implements PreviewResultStore {
  readonly stored: Array<{
    tenantId: string
    salesOrderId: string
    requestId: string
    status: 'READY' | 'FAILED'
    viewerRef?: string
    failureCode?: string
    failureMessage?: string | null
    failureSource?: 'PROVIDER' | 'INTERNAL'
  }> = []

  store(input: {
    tenantId: string
    salesOrderId: string
    requestId: string
    status: 'READY' | 'FAILED'
    viewerRef?: string
    failureCode?: string
    failureMessage?: string | null
    failureSource?: 'PROVIDER' | 'INTERNAL'
  }): Promise<void> {
    this.stored.push(input)
    return Promise.resolve()
  }
}

export class FakeIssuanceResultGateway implements IssuanceResultGateway {
  preparationAction: PublishPreparationAction = 'CALL_PROVIDER'
  readonly prepareCalls: Array<{
    tenantId: string
    attemptId: string
    idempotencyKey: string
    payloadHash: string
    canonicalInvoice: Record<string, unknown>
  }> = []
  readonly markProviderCallStartedCalls: Array<{ tenantId: string; attemptId: string }> = []
  readonly successCalls: Array<{
    tenantId: string
    attemptId: string
    evidence: Extract<IssuanceResultEvidence, { kind: 'success' }>
  }> = []
  readonly definiteFailureCalls: Array<{
    tenantId: string
    attemptId: string
    evidence: Extract<IssuanceResultEvidence, { kind: 'definiteFailure' }>
  }> = []
  readonly undeterminedCalls: Array<{
    tenantId: string
    attemptId: string
    evidence: Extract<IssuanceResultEvidence, { kind: 'undetermined' }>
  }> = []
  readonly retryableRejectionCalls: Array<{
    tenantId: string
    attemptId: string
    sourceCommandId: string
    evidence: Extract<IssuanceResultEvidence, { kind: 'retryableProviderRejection' }>
    retryAfterSeconds: number
  }> = []
  readonly commandIntegrityCalls: Array<{ tenantId: string; attemptId: string; reasonCode: string }> = []
  readonly publishDeadLetterCalls: Array<{ tenantId: string; attemptId: string; reasonCode: string }> = []
  get deadLetterCalls(): Array<{ tenantId: string; attemptId: string; reasonCode: string }> {
    return this.publishDeadLetterCalls
  }

  preparePublish(i: {
    tenantId: string
    attemptId: string
    idempotencyKey: string
    payloadHash: string
    canonicalInvoice: Record<string, unknown>
  }): Promise<PublishPreparationAction> {
    this.prepareCalls.push(i)
    return Promise.resolve(this.preparationAction)
  }

  markProviderCallStarted(tenantId: string, attemptId: string): Promise<void> {
    this.markProviderCallStartedCalls.push({ tenantId, attemptId })
    return Promise.resolve()
  }

  recordSuccess(
    tenantId: string,
    attemptId: string,
    e: Extract<IssuanceResultEvidence, { kind: 'success' }>,
  ): Promise<void> {
    this.successCalls.push({ tenantId, attemptId, evidence: e })
    return Promise.resolve()
  }

  recordDefiniteFailure(
    tenantId: string,
    attemptId: string,
    e: Extract<IssuanceResultEvidence, { kind: 'definiteFailure' }>,
  ): Promise<void> {
    this.definiteFailureCalls.push({ tenantId, attemptId, evidence: e })
    return Promise.resolve()
  }

  recordUndetermined(
    tenantId: string,
    attemptId: string,
    e: Extract<IssuanceResultEvidence, { kind: 'undetermined' }>,
  ): Promise<void> {
    this.undeterminedCalls.push({ tenantId, attemptId, evidence: e })
    return Promise.resolve()
  }

  recordRetryableProviderRejection(i: {
    tenantId: string
    attemptId: string
    sourceCommandId: string
    evidence: Extract<IssuanceResultEvidence, { kind: 'retryableProviderRejection' }>
    retryAfterSeconds: number
  }): Promise<void> {
    this.retryableRejectionCalls.push(i)
    return Promise.resolve()
  }

  recordCommandIntegrityFailure(tenantId: string, attemptId: string, reasonCode: string): Promise<void> {
    this.commandIntegrityCalls.push({ tenantId, attemptId, reasonCode })
    return Promise.resolve()
  }

  recordPublishCommandDeadLetter(tenantId: string, attemptId: string, reasonCode: string): Promise<void> {
    this.publishDeadLetterCalls.push({ tenantId, attemptId, reasonCode })
    return Promise.resolve()
  }
}

export class FakePublishSeriesLeaseGateway implements PublishSeriesLeaseGateway {
  leaseOutcome: LeaseAcquireOutcome = {
    kind: 'acquired',
    providerConnectionId: 'conn-1',
    invoiceSeries: '1C25TYY',
    leaseVersion: 1,
  }
  readonly acquireCalls: Array<{ tenantId: string; attemptId: string; ownerToken: string }> = []
  readonly releaseCalls: Array<{
    tenantId: string
    providerConnectionId: string
    invoiceSeries: string
    ownerToken: string
    leaseVersion: number
  }> = []

  tryAcquire(tenantId: string, attemptId: string, ownerToken: string): Promise<LeaseAcquireOutcome> {
    this.acquireCalls.push({ tenantId, attemptId, ownerToken })
    return Promise.resolve(this.leaseOutcome)
  }

  release(i: {
    tenantId: string
    providerConnectionId: string
    invoiceSeries: string
    ownerToken: string
    leaseVersion: number
  }): Promise<void> {
    this.releaseCalls.push(i)
    return Promise.resolve()
  }
}

export class FakeReconciliationGateway implements ReconciliationGateway {
  claimContext: ReconciliationPollContext | null = null
  readonly claimCalls: Array<{ tenantId: string; caseId: string; workerId: string }> = []
  readonly pendingCheckCalls: Array<{
    tenantId: string
    caseId: string
    claimToken: string
    nextDelaySeconds: number
    checkSequence: number
  }> = []
  readonly resolveCalls: Array<{
    tenantId: string
    caseId: string
    outcome: 'SUCCESS' | 'FAILURE' | 'PUBLISH_RETRY_SCHEDULED' | 'UNRESOLVED'
    evidence?: Record<string, unknown>
  }> = []

  claim(tenantId: string, caseId: string, workerId: string): Promise<ReconciliationPollContext | null> {
    this.claimCalls.push({ tenantId, caseId, workerId })
    return Promise.resolve(this.claimContext)
  }

  recordPendingCheck(i: {
    tenantId: string
    caseId: string
    claimToken: string
    nextDelaySeconds: number
    checkSequence: number
  }): Promise<void> {
    this.pendingCheckCalls.push(i)
    return Promise.resolve()
  }

  resolve(i: {
    tenantId: string
    caseId: string
    outcome: 'SUCCESS' | 'FAILURE' | 'PUBLISH_RETRY_SCHEDULED' | 'UNRESOLVED'
    evidence?: Record<string, unknown>
  }): Promise<void> {
    this.resolveCalls.push(i)
    return Promise.resolve()
  }
}

export class FakeIssuanceGateways implements IssuanceGateways {
  preview = new FakePreviewResultStore()
  results = new FakeIssuanceResultGateway()
  lease = new FakePublishSeriesLeaseGateway()
  reconciliation = new FakeReconciliationGateway()
}

export class FakeIssuanceProvider implements IssuanceProvider {
  previewOutcome: PreviewOutcome = {
    kind: 'success',
    viewerRef: 'https://viewer/1',
  }
  publishOutcome: PublishOutcome = {
    kind: 'success',
    providerReference: 'tx-success-1',
    invoiceNumber: '0000042',
    invoiceSeries: '1C25TYY',
    issuedAt: new Date(Date.UTC(2026, 7, 1)),
    safeProviderEvidence: { refId: 'attempt-key-42' },
  }
  statusOutcome: IssuanceStatusOutcome = { kind: 'pending' }

  throwOnValidate = false
  throwOnPreview: Error | null = null
  throwOnPublish: Error | null = null
  throwOnGetStatus: Error | null = null

  validateCalls = 0
  lastCanonical: Record<string, unknown> | null = null
  readonly previewCalls: Array<{ tenantId: string; canonicalInvoice: Record<string, unknown> }> = []
  readonly publishCalls: Array<{ tenantId: string; canonicalInvoice: Record<string, unknown>; idempotencyKey: string }> = []
  readonly getStatusCalls: Array<{
    tenantId: string
    statusLookupKey: string
    invoiceSeries: string
    idempotencyKey: string
    payloadHash: string
    statusLookup: StatusLookup
  }> = []

  validateCanonical(canonicalInvoice: Record<string, unknown>): void {
    this.validateCalls++
    this.lastCanonical = canonicalInvoice
    if (this.throwOnValidate) {
      throw new CanonicalValidationFault('CANONICAL_MISSING_buyerLegalName', 'Missing buyer name')
    }
  }

  previewUnpublished(tenantId: string, canonicalInvoice: Record<string, unknown>): Promise<PreviewOutcome> {
    this.previewCalls.push({ tenantId, canonicalInvoice })
    this.lastCanonical = canonicalInvoice
    if (this.throwOnPreview) return Promise.reject(this.throwOnPreview)
    return Promise.resolve(this.previewOutcome)
  }

  publish(tenantId: string, canonicalInvoice: Record<string, unknown>, idempotencyKey: string): Promise<PublishOutcome> {
    this.publishCalls.push({ tenantId, canonicalInvoice, idempotencyKey })
    this.lastCanonical = canonicalInvoice
    if (this.throwOnPublish) return Promise.reject(this.throwOnPublish)
    return Promise.resolve(this.publishOutcome)
  }

  getStatus(input: {
    tenantId: string
    statusLookupKey: string
    invoiceSeries: string
    idempotencyKey: string
    payloadHash: string
    statusLookup: StatusLookup
  }): Promise<IssuanceStatusOutcome> {
    this.getStatusCalls.push(input)
    if (this.throwOnGetStatus) return Promise.reject(this.throwOnGetStatus)
    return Promise.resolve(this.statusOutcome)
  }
}
