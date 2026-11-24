import { ProviderUnavailableError } from '../queue/errors.ts'
import type { CommandHandler } from '../queue/types.ts'
import { resolveEndpointCapabilities } from './endpoint_capabilities.ts'
import type { TenantMisaClientFactory } from './misa_client_factory.ts'
import type { MisaEnv } from './misa_env.ts'
import { mergeAndDedupe, type ProviderTemplateRef, tryCreateTemplateRef } from './template_ref.ts'

export interface ConnectionRecorder {
  /** Real implementation: rpc('record_connection_verified', {...}). */
  record(input: {
    tenantId: string
    connectionId: string
    expectedConnectionVersion: number
    status: 'CONNECTED' | 'RECONNECT_REQUIRED'
    capabilities?: Record<string, unknown>
    verifiedAt?: string
    correlationId?: string
  }): Promise<void>
}

export interface SyncCapabilitiesDeps {
  clients: TenantMisaClientFactory
  recorder: ConnectionRecorder
  env: MisaEnv
  now?: () => Date
  log?: (event: string, data: Record<string, unknown>) => void
}

const defaultLog = (event: string, data: Record<string, unknown>) =>
  console.log(JSON.stringify({ event, ...data }))

export const SYNC_CAPABILITIES = 'einvoice.sync_capabilities'

/** Port of SyncProviderCapabilitiesCommandHandler + MeInvoiceProviderAdapter.authenticateAndListTemplates. */
export function createSyncCapabilitiesHandler(deps: SyncCapabilitiesDeps): CommandHandler {
  const now = deps.now ?? (() => new Date())
  const log = deps.log ?? defaultLog

  return async (ctx) => {
    const payload = ctx.command.payload
    const connectionId = payload['connection_id']
    if (typeof connectionId !== 'string' || connectionId === '') throw new Error('missing_connection_id')
    const rawVersion = payload['expected_connection_version']
    const expectedConnectionVersion = typeof rawVersion === 'number' ? rawVersion : -1
    const rawCorrelation = payload['correlation_id']
    const correlationId = typeof rawCorrelation === 'string' && rawCorrelation !== '' ? rawCorrelation : undefined
    const tenantId = ctx.tenantId

    const reconnectRequired = () =>
      deps.recorder.record({
        tenantId,
        connectionId,
        expectedConnectionVersion,
        status: 'RECONNECT_REQUIRED',
        correlationId,
      })

    const resolved = await deps.clients.getForTenant(tenantId)
    if (resolved === null) {
      await reconnectRequired()
      return
    }
    const { client, baseUrl } = resolved
    // Same order as the Dart adapter: reject a non-HTTPS endpoint before any login.
    const endpointCaps = resolveEndpointCapabilities(baseUrl, deps.env.emailDeliveryEnabled)

    const fail = async (stage: 'token' | 'templates', error: string, checkMissingCredential: boolean) => {
      deps.clients.invalidate(tenantId)
      log('misa_verification_failed', { tenantId, stage, reason: safeFailureReason(error) })
      const lower = error.toLowerCase()
      if (checkMissingCredential && lower.includes('missing credential')) {
        await reconnectRequired()
        return
      }
      if (lower.includes('unavailable') || lower.includes('timeout')) throw new ProviderUnavailableError()
      await reconnectRequired()
    }

    const token = await client.obtainAccessToken({ forceLogin: true })
    if (!token.isSuccess) return await fail('token', token.error ?? '', true)

    const withCode = await client.listInvoiceTemplates({ invoiceWithCode: true })
    if (!withCode.isSuccess) return await fail('templates', withCode.error ?? '', false)

    const withoutCode = await client.listInvoiceTemplates({ invoiceWithCode: false })
    if (!withoutCode.isSuccess) return await fail('templates', withoutCode.error ?? '', false)

    const mapped: ProviderTemplateRef[] = []
    for (const template of [...(withCode.data ?? []), ...(withoutCode.data ?? [])]) {
      if (template.inactive) continue
      const ref = tryCreateTemplateRef({
        templateId: template.ipTemplateId,
        name: template.templateName,
        invoiceSeries: template.invSeries,
        isSendSummary: template.isSendSummary,
        serial: template.invTemplateNo,
        isAvailable: !template.inactive,
      })
      if (ref !== null) mapped.push(ref)
    }
    const templates = mergeAndDedupe(mapped)

    const verifiedAt = now().toISOString()
    await deps.recorder.record({
      tenantId,
      connectionId,
      expectedConnectionVersion,
      status: 'CONNECTED',
      verifiedAt,
      correlationId,
      capabilities: {
        supports_email_delivery: endpointCaps.supportsEmailDelivery,
        supports_preview: endpointCaps.supportsPreview,
        // Current MISA has no delivery-result observation API.
        supports_delivery_result_observation: false,
        template_count: templates.length,
        supported_document_types: endpointCaps.supportedDocumentTypes,
        templates: templates.map((t) => ({
          template_id: t.templateId,
          name: t.name,
          serial: t.serial,
          symbol: t.invoiceSeries,
          invoice_series: t.invoiceSeries,
          invoice_with_code: t.invoiceWithCode,
          is_mtt: t.isMtt,
          is_send_summary: t.isSendSummary,
          is_available: t.isAvailable,
        })),
        synced_at: verifiedAt,
      },
    })
  }
}

/** Reduces a client error to a short safe code (never echoes secrets). */
export function safeFailureReason(error: string): string {
  const trimmed = error.trim()
  const lower = trimmed.toLowerCase()
  if (lower.includes('timeout')) return 'TIMEOUT'
  if (lower.includes('unavailable')) return 'PROVIDER_UNAVAILABLE'

  const rejectedPrefix = 'meinvoice_auth_rejected:'
  if (trimmed.startsWith(rejectedPrefix)) return safeCode(trimmed.substring(rejectedPrefix.length))

  const separator = trimmed.indexOf(':')
  if (separator >= 0 && separator + 1 < trimmed.length) {
    const suffixCode = safeCode(trimmed.substring(separator + 1))
    if (suffixCode !== 'UNKNOWN_PROVIDER_FAILURE') return suffixCode
  }
  return safeCode(trimmed)
}

function safeCode(candidate: string): string {
  const match = /^[A-Za-z][A-Za-z0-9_]{0,63}/.exec(candidate.trim())
  return match?.[0] ?? 'UNKNOWN_PROVIDER_FAILURE'
}
