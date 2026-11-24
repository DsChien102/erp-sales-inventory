import {
  type MeInvoiceInvoiceData,
  MeInvoiceInvoiceQuery,
  MeInvoiceStatusInputType,
  MeInvoiceViewUrlPolicy,
} from '../../misa/mod.ts'
import type { TenantMisaClientFactory } from '../misa_client_factory.ts'
import { safeFailureReason } from '../sync_capabilities.ts'
import {
  toPreviewInvoice,
  toPublishRequest,
  validateCanonical,
} from './canonical_mapper.ts'
import { CanonicalValidationFault } from './errors.ts'
import { classifyIssuanceStatus } from './issuance_status_classifier.ts'
import type {
  IssuanceStatusOutcome,
  PreviewOutcome,
  PublishOutcome,
  StatusLookup,
} from './outcomes.ts'
import { classifyPublish } from './publish_classifier.ts'

export interface IssuanceProvider {
  previewUnpublished(tenantId: string, canonicalInvoice: Record<string, unknown>): Promise<PreviewOutcome>
  validateCanonical(canonicalInvoice: Record<string, unknown>): void
  publish(tenantId: string, canonicalInvoice: Record<string, unknown>, idempotencyKey: string): Promise<PublishOutcome>
  getStatus(input: {
    tenantId: string
    statusLookupKey: string
    invoiceSeries: string
    idempotencyKey: string
    payloadHash: string
    statusLookup: StatusLookup
  }): Promise<IssuanceStatusOutcome>
}

export function safePreviewFailureDetail(message: string): string | null {
  const trimmed = message.trim()
  if (trimmed.length === 0) return null
  const prefix = 'InvalidInvoiceData:'
  if (trimmed.startsWith(prefix)) {
    const rest = trimmed.slice(prefix.length).trim()
    if (rest.length === 0 || rest === 'InvalidInvoiceData') return null
    return rest.length <= 180 ? rest : `${rest.slice(0, 180)}…`
  }
  const colon = trimmed.indexOf(':')
  if (colon > 0 && colon + 1 < trimmed.length) {
    const rest = trimmed.slice(colon + 1).trim()
    if (rest.length > 0) {
      return rest.length <= 180 ? rest : `${rest.slice(0, 180)}…`
    }
  }
  return null
}

export function createIssuanceProvider(deps: {
  clients: TenantMisaClientFactory
  log?: (event: string, data: Record<string, unknown>) => void
}): IssuanceProvider {
  return {
    validateCanonical(canonicalInvoice: Record<string, unknown>): void {
      validateCanonical(canonicalInvoice)
    },

    async previewUnpublished(tenantId: string, canonicalInvoice: Record<string, unknown>): Promise<PreviewOutcome> {
      const tenantClient = await deps.clients.getForTenant(tenantId)
      if (tenantClient === null) {
        return { kind: 'authFailed' }
      }

      let invoice: MeInvoiceInvoiceData
      try {
        invoice = toPreviewInvoice(canonicalInvoice)
      } catch (fault) {
        if (fault instanceof CanonicalValidationFault) {
          deps.log?.('misa_preview_canonical_invalid', { tenantId, reasonCode: fault.reasonCode })
          return { kind: 'invalidData', detail: fault.reasonCode }
        }
        throw fault
      }

      const result = await tenantClient.client.previewUnpublished(invoice)
      if (!result.isSuccess) {
        const message = result.error ?? ''
        const reason = safeFailureReason(message)
        const detail = safePreviewFailureDetail(message)
        deps.log?.('misa_preview_failed', { tenantId, reason, ...(detail ? { detail } : {}) })

        const lower = message.toLowerCase()
        if (lower.includes('unavailable') || lower.includes('timeout')) {
          return { kind: 'providerUnavailable' }
        }
        if (
          message === 'meinvoice_preview_invalid_url' ||
          message === 'meinvoice_preview_invalid_data' ||
          message === 'meinvoice_preview_empty_data'
        ) {
          return { kind: 'invalidData', detail: message }
        }
        if (reason === 'InvalidInvoiceData') {
          return { kind: 'invalidData', detail: detail ?? reason }
        }
        return { kind: 'authFailed' }
      }

      const viewerRef = result.data ? MeInvoiceViewUrlPolicy.tryParse(result.data) : null
      if (viewerRef === null) {
        return { kind: 'invalidData', detail: 'meinvoice_preview_invalid_url' }
      }
      return { kind: 'success', viewerRef }
    },

    async publish(tenantId: string, canonicalInvoice: Record<string, unknown>, idempotencyKey: string): Promise<PublishOutcome> {
      const tenantClient = await deps.clients.getForTenant(tenantId)
      if (tenantClient === null) {
        return {
          kind: 'undetermined',
          reasonCode: 'PROVIDER_AUTH_FAILED',
          safeProviderEvidence: { refId: idempotencyKey },
        }
      }

      const request = toPublishRequest({ canonicalInvoice, idempotencyKey })
      const result = await tenantClient.client.publish(request)
      return classifyPublish({
        idempotencyKey,
        result,
        canonicalInvoice,
      })
    },

    async getStatus(input: {
      tenantId: string
      statusLookupKey: string
      invoiceSeries: string
      idempotencyKey: string
      payloadHash: string
      statusLookup: StatusLookup
    }): Promise<IssuanceStatusOutcome> {
      const query = MeInvoiceInvoiceQuery.tryFromInvSeries(input.invoiceSeries)
      if (query === null) {
        return {
          kind: 'undetermined',
          reasonCode: 'INVOICE_SERIES_INVALID',
        }
      }

      const tenantClient = await deps.clients.getForTenant(input.tenantId)
      if (tenantClient === null) {
        return {
          kind: 'undetermined',
          reasonCode: 'PROVIDER_AUTH_FAILED',
        }
      }

      const inputType = input.statusLookup === 'refId'
        ? MeInvoiceStatusInputType.refId
        : MeInvoiceStatusInputType.transactionId

      const statusResult = await tenantClient.client.getStatus({
        ids: [input.statusLookupKey],
        inputType,
        query,
      })

      return classifyIssuanceStatus({
        statusResult,
        idempotencyKey: input.idempotencyKey,
        payloadHash: input.payloadHash,
      })
    },
  }
}

