import type {
  AutomationGateway,
  AutoIssuanceStartRequest,
  AutoIssuanceReevaluationRequest,
  AutoIssuanceResult,
  AutoDeliveryStartRequest,
  AutoDeliveryResult,
} from './gateways.ts'

export class FakeAutomationGateway implements AutomationGateway {
  startIssuanceCalls: AutoIssuanceStartRequest[] = []
  reevaluateCalls: AutoIssuanceReevaluationRequest[] = []
  startDeliveryCalls: AutoDeliveryStartRequest[] = []

  startIssuanceResult: AutoIssuanceResult = {
    started: true,
    skipped: false,
    processId: 'proc-default',
    attemptId: 'att-default',
    status: 'ATTEMPT_STARTED',
    reason: null,
  }

  reevaluateResult: AutoIssuanceResult = {
    started: true,
    skipped: false,
    processId: 'proc-default',
    attemptId: 'att-default',
    status: 'ATTEMPT_STARTED',
    reason: null,
  }

  startDeliveryResult: AutoDeliveryResult = {
    disposition: 'started',
    deliveryId: 'del-default',
    skipReason: null,
  }

  throwOnStartIssuance?: Error
  throwOnReevaluate?: Error
  throwOnStartDelivery?: Error

  startAutoIssuance(r: AutoIssuanceStartRequest): Promise<AutoIssuanceResult> {
    if (this.throwOnStartIssuance) return Promise.reject(this.throwOnStartIssuance)
    this.startIssuanceCalls.push(r)
    return Promise.resolve(this.startIssuanceResult)
  }

  reevaluateAutoIssuance(r: AutoIssuanceReevaluationRequest): Promise<AutoIssuanceResult> {
    if (this.throwOnReevaluate) return Promise.reject(this.throwOnReevaluate)
    this.reevaluateCalls.push(r)
    return Promise.resolve(this.reevaluateResult)
  }

  startAutoDelivery(r: AutoDeliveryStartRequest): Promise<AutoDeliveryResult> {
    if (this.throwOnStartDelivery) return Promise.reject(this.throwOnStartDelivery)
    this.startDeliveryCalls.push(r)
    return Promise.resolve(this.startDeliveryResult)
  }
}

