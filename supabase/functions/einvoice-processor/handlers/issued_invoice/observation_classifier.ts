import {
  MeInvoiceInvoiceStatus,
  MeInvoiceResult,
} from '../../misa/mod.ts'
import { OBSERVATION_DETAIL_KEYS, ObservationOutcome } from './outcomes.ts'
import {
  safeErrorCode,
  throwIfTransportAmbiguous,
} from './provider_call_support.ts'

function hasText(val: string | null | undefined): val is string {
  return typeof val === 'string' && val.trim().length > 0
}

function providerStateCode(item: MeInvoiceInvoiceStatus): string {
  const publish = item.publishStatus
  const eInvoice = item.eInvoiceStatus
  const publishLabel =
    publish === null || publish === undefined ? 'UNKNOWN' : `PS_${publish}`
  const eInvoiceLabel =
    eInvoice === null || eInvoice === undefined ? 'UNKNOWN' : `ES_${eInvoice}`
  return `${publishLabel}_${eInvoiceLabel}`
}

function safeDescription(item: MeInvoiceInvoiceStatus): string {
  switch (item.publishStatus) {
    case 0:
      return 'NOT_PUBLISHED'
    case 1:
      return 'PUBLISHED'
    case null:
    case undefined:
      return 'UNKNOWN_PUBLISH_STATUS'
    default:
      return `UNKNOWN_${item.publishStatus}`
  }
}

function detailsSnapshot(item: MeInvoiceInvoiceStatus): Record<string, unknown> {
  const snapshot: Record<string, unknown> = {}
  if (item.publishStatus !== null && item.publishStatus !== undefined) {
    snapshot.publishStatus = item.publishStatus
  }
  if (item.eInvoiceStatus !== null && item.eInvoiceStatus !== undefined) {
    snapshot.eInvoiceStatus = item.eInvoiceStatus
  }
  if (item.referenceType !== null && item.referenceType !== undefined) {
    snapshot.referenceType = item.referenceType
  }
  if (item.sendTaxStatus !== null && item.sendTaxStatus !== undefined) {
    snapshot.sendTaxStatus = item.sendTaxStatus
  }
  if (hasText(item.invoiceCode)) {
    snapshot.invoiceCode = item.invoiceCode
  }
  if (hasText(item.invNo)) {
    snapshot.invNo = item.invNo
  }
  if (hasText(item.invSeries)) {
    snapshot.invSeries = item.invSeries
  }
  if (item.publishedTime instanceof Date) {
    snapshot.publishedTime = item.publishedTime.toISOString()
  }
  if (hasText(item.transactionId)) {
    snapshot.transactionId = item.transactionId
  }
  // Sanity check all keys against OBSERVATION_DETAIL_KEYS
  for (const k of Object.keys(snapshot)) {
    if (!OBSERVATION_DETAIL_KEYS.includes(k as typeof OBSERVATION_DETAIL_KEYS[number])) {
      throw new Error(`Disallowed detail key: ${k}`)
    }
  }
  return snapshot
}

export function classifyObservation(input: {
  result: MeInvoiceResult<MeInvoiceInvoiceStatus[]>
  providerInvoiceReference: string
  now: Date
}): ObservationOutcome {
  const { result, providerInvoiceReference, now } = input
  if (!result.isSuccess) {
    const error = result.error ?? 'unknown_error'
    throwIfTransportAmbiguous(error)
    return {
      kind: 'ambiguous',
      safeErrorCode: safeErrorCode(error),
    }
  }

  const statuses = result.data
  if (statuses === null || statuses.length === 0) {
    return {
      kind: 'notFound',
      providerStateCode: 'NOT_FOUND',
      safeDescription: 'PROVIDER_STATUS_NOT_FOUND',
      observedAt: now,
      providerReference: providerInvoiceReference,
    }
  }

  const item = statuses[0]
  if (hasText(item.transactionId) && item.transactionId !== providerInvoiceReference) {
    return {
      kind: 'mismatch',
      providerStateCode: 'MISMATCH',
      safeDescription: 'PROVIDER_IDENTITY_MISMATCH',
      observedAt: now,
      providerReference: providerInvoiceReference,
    }
  }

  const observedAt = item.publishedTime ?? now
  return {
    kind: 'found',
    providerStateCode: providerStateCode(item),
    safeDescription: safeDescription(item),
    observedAt,
    detailsSnapshot: detailsSnapshot(item),
    providerReference: item.transactionId ?? providerInvoiceReference,
  }
}

