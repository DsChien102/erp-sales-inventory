import { OBSERVATION_DETAIL_KEYS } from './outcomes.ts'
import type { IssuedInvoiceGateway } from './gateways.ts'

export interface RecordProviderObservationInput {
  tenantId: string
  electronicInvoiceId: string
  providerStateCode: string
  safeDescription?: string | null
  providerReference?: string | null
  observedAt: Date
  deduplicationKey: string
  detailsSnapshot: Record<string, unknown>
  correlationId: string
}

export async function recordProviderObservation(
  gateway: IssuedInvoiceGateway,
  input: RecordProviderObservationInput,
): Promise<void> {
  if (!input.tenantId || input.tenantId.trim() === '') {
    throw new Error('tenantId is required')
  }
  if (!input.electronicInvoiceId || input.electronicInvoiceId.trim() === '') {
    throw new Error('electronicInvoiceId is required')
  }
  if (!input.providerStateCode || input.providerStateCode.trim() === '') {
    throw new Error('providerStateCode is required')
  }
  if (!input.deduplicationKey || input.deduplicationKey.trim() === '') {
    throw new Error('deduplicationKey is required')
  }
  if (!input.correlationId || input.correlationId.trim() === '') {
    throw new Error('correlationId is required')
  }

  for (const key of Object.keys(input.detailsSnapshot)) {
    if (
      !OBSERVATION_DETAIL_KEYS.includes(
        key as typeof OBSERVATION_DETAIL_KEYS[number],
      )
    ) {
      throw new Error(`detailsSnapshot key not allowed: ${key}`)
    }
  }

  await gateway.recordProviderObservation(input)
}

