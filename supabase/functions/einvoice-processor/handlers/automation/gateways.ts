export interface AutoIssuanceStartRequest {
  tenantId: string
  salesOrderId: string
  triggerKey: string
  idempotencyKey: string
}

export interface AutoIssuanceReevaluationRequest {
  tenantId: string
  processId: string
  sourceEventId: string
}

export interface AutoIssuanceResult {
  started: boolean
  skipped: boolean
  processId: string
  attemptId: string | null
  status: string
  reason: string | null
}

export interface AutoDeliveryStartRequest {
  tenantId: string
  electronicInvoiceId: string
  triggerId: string
  idempotencyKey: string
}

export interface AutoDeliveryResult {
  disposition: 'started' | 'skipped'
  deliveryId: string | null
  skipReason: string | null
}

export interface AutomationGateway {
  startAutoIssuance(r: AutoIssuanceStartRequest): Promise<AutoIssuanceResult>
  reevaluateAutoIssuance(r: AutoIssuanceReevaluationRequest): Promise<AutoIssuanceResult>
  startAutoDelivery(r: AutoDeliveryStartRequest): Promise<AutoDeliveryResult>
}

export interface AutomationDeps {
  gateway: AutomationGateway
}

