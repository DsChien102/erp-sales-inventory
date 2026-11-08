export interface DeliveryCommandPayload {
  tenantId: string
  deliveryId: string
  retryCount: number
}

export interface ReconciliationCommandPayload {
  reconciliationCaseId: string | null
  checkSequence: number
}

export function parseDeliveryPayload(
  payload: Record<string, unknown>,
  claimedTenantId: string,
): DeliveryCommandPayload {
  const hasTenantSnake = Object.prototype.hasOwnProperty.call(payload, 'tenant_id')
  const hasTenantCamel = Object.prototype.hasOwnProperty.call(payload, 'tenantId')

  let tenantId: string
  if (!hasTenantSnake && !hasTenantCamel) {
    tenantId = claimedTenantId
  } else {
    tenantId = parseIdentity(payload, 'tenant_id', 'tenantId')
    if (tenantId !== claimedTenantId) {
      throw new Error('Delivery tenant does not match claimed tenant')
    }
  }

  const deliveryId = parseIdentity(payload, 'delivery_id', 'deliveryId')
  const retryCount = parseRetryCount(payload)

  return { tenantId, deliveryId, retryCount }
}

function parseIdentity(
  json: Record<string, unknown>,
  key: string,
  legacy: string,
): string {
  const hasKey = Object.prototype.hasOwnProperty.call(json, key)
  const hasLegacy = Object.prototype.hasOwnProperty.call(json, legacy)

  if (hasKey && hasLegacy && json[key] !== json[legacy]) {
    throw new Error(`Conflicting delivery identity aliases: ${key}`)
  }

  const value = hasKey ? json[key] : json[legacy]
  if (typeof value !== 'string' || value.trim().length === 0 || value !== value.trim()) {
    throw new Error(`Invalid or missing delivery identity: ${key}`)
  }

  return value
}

function parseRetryCount(json: Record<string, unknown>): number {
  const key = 'retry_count'
  const legacy = 'retryCount'
  const hasKey = Object.prototype.hasOwnProperty.call(json, key)
  const hasLegacy = Object.prototype.hasOwnProperty.call(json, legacy)

  if (hasKey && hasLegacy && json[key] !== json[legacy]) {
    throw new Error(`Conflicting delivery identity aliases: ${key}`)
  }

  const value = hasKey ? json[key] : json[legacy]
  if (typeof value !== 'number' || !Number.isInteger(value) || value < 0 || value > 2) {
    throw new Error(`Invalid or missing delivery identity: ${key}`)
  }

  return value
}

export function parseReconciliationPayload(
  payload: Record<string, unknown>,
): ReconciliationCommandPayload {
  const rawCaseId = payload['reconciliation_case_id'] ?? payload['reconciliationCaseId']
  let reconciliationCaseId: string | null = null
  if (typeof rawCaseId === 'string' && rawCaseId.trim().length > 0) {
    reconciliationCaseId = rawCaseId.trim()
  }

  const rawSeq = payload['check_sequence'] ?? payload['checkSequence']
  let checkSequence = 1
  if (typeof rawSeq === 'number' && !Number.isNaN(rawSeq)) {
    checkSequence = Math.trunc(rawSeq)
  } else if (typeof rawSeq === 'string') {
    const parsed = parseInt(rawSeq, 10)
    checkSequence = Number.isNaN(parsed) ? 1 : parsed
  }

  return { reconciliationCaseId, checkSequence }
}
