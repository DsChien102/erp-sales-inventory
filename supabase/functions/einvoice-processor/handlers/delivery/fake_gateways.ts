import type {
  DeliveryAttemptContext,
  DeliveryGateway,
  DeliveryResultRecord,
  PrepareResult,
  ReconciliationCheckRecord,
  ReconciliationContext,
} from './gateways.ts'
import type {
  DeliveryObservationContext,
  DeliveryObservationOutcome,
  DeliveryProviderContext,
  DeliveryProviderOutcome,
} from './outcomes.ts'
import type { DeliveryObservationProvider } from './delivery_observation_provider.ts'
import type { DeliveryProvider } from './delivery_provider.ts'

export class FakeDeliveryGateway implements DeliveryGateway {
  attemptContext: DeliveryAttemptContext | null = null
  prepareResult: PrepareResult = { action: 'SKIP' }
  reconciliationContext: ReconciliationContext | null = null
  throwOnRecord = false
  throwOnLoadAttempt = false
  throwOnLoadReconciliation = false
  throwOnLoadReconciliationOnce = false

  readonly calls: { method: string; args: unknown[] }[] = []
  readonly prepareCalls: {
    tenantId: string
    deliveryId: string
    retryCount: number
    requestReference: string
  }[] = []
  readonly results: DeliveryResultRecord[] = []
  readonly deadLetters: {
    tenantId: string
    deliveryId: string
    retryCount: number
    safeFailureCode: string
  }[] = []
  readonly checks: ReconciliationCheckRecord[] = []

  loadAttemptContext(
    tenantId: string,
    deliveryId: string,
    retryCount: number,
  ): Promise<DeliveryAttemptContext | null> {
    this.calls.push({ method: 'loadAttemptContext', args: [tenantId, deliveryId, retryCount] })
    if (this.throwOnLoadAttempt) {
      return Promise.reject(new Error('loadAttemptContext failed'))
    }
    return Promise.resolve(this.attemptContext)
  }

  prepareProviderCall(
    tenantId: string,
    deliveryId: string,
    retryCount: number,
    requestReference: string,
  ): Promise<PrepareResult> {
    this.calls.push({
      method: 'prepareProviderCall',
      args: [tenantId, deliveryId, retryCount, requestReference],
    })
    this.prepareCalls.push({ tenantId, deliveryId, retryCount, requestReference })
    return Promise.resolve(this.prepareResult)
  }

  recordResult(r: DeliveryResultRecord): Promise<void> {
    this.calls.push({ method: 'recordResult', args: [r] })
    this.results.push(r)
    if (this.throwOnRecord) {
      return Promise.reject(new Error('recordResult failed'))
    }
    return Promise.resolve()
  }

  recordCommandDeadLetter(
    tenantId: string,
    deliveryId: string,
    retryCount: number,
    safeFailureCode: string,
  ): Promise<void> {
    this.calls.push({
      method: 'recordCommandDeadLetter',
      args: [tenantId, deliveryId, retryCount, safeFailureCode],
    })
    this.deadLetters.push({ tenantId, deliveryId, retryCount, safeFailureCode })
    return Promise.resolve()
  }

  loadReconciliationContext(
    tenantId: string,
    reconciliationCaseId: string,
    checkSequence: number,
  ): Promise<ReconciliationContext | null> {
    this.calls.push({
      method: 'loadReconciliationContext',
      args: [tenantId, reconciliationCaseId, checkSequence],
    })
    if (this.throwOnLoadReconciliationOnce) {
      this.throwOnLoadReconciliationOnce = false
      return Promise.reject(new Error('load failed'))
    }
    if (this.throwOnLoadReconciliation) {
      return Promise.reject(new Error('loadReconciliationContext failed'))
    }
    return Promise.resolve(this.reconciliationContext)
  }

  recordReconciliationCheck(r: ReconciliationCheckRecord): Promise<void> {
    this.calls.push({ method: 'recordReconciliationCheck', args: [r] })
    this.checks.push(r)
    return Promise.resolve()
  }
}

export class FakeDeliveryProvider implements DeliveryProvider {
  outcome: DeliveryProviderOutcome = { kind: 'succeeded', providerReference: 'default-ref' }
  throwOnSend = false
  sendCalls = 0
  lastContext: DeliveryProviderContext | null = null

  sendEmail(ctx: DeliveryProviderContext): Promise<DeliveryProviderOutcome> {
    this.sendCalls++
    this.lastContext = ctx
    if (this.throwOnSend) {
      return Promise.reject(new Error('sendEmail failed'))
    }
    return Promise.resolve(this.outcome)
  }
}

export class FakeDeliveryObservationProvider implements DeliveryObservationProvider {
  outcome: DeliveryObservationOutcome = { kind: 'unsupported' }
  observeCalls = 0
  lastContext: DeliveryObservationContext | null = null

  observe(ctx: DeliveryObservationContext): Promise<DeliveryObservationOutcome> {
    this.observeCalls++
    this.lastContext = ctx
    return Promise.resolve(this.outcome)
  }
}
