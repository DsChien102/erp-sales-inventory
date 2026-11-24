import type { CommandContext, CommandHandler } from '../../queue/types.ts'
import { ProviderCallAmbiguousError } from './errors.ts'
import type { IssuedInvoiceDeps } from './gateways.ts'
import type { OfficialViewOutcome } from './outcomes.ts'

export function createFetchOfficialViewHandler(
  deps: IssuedInvoiceDeps,
): CommandHandler {
  return async (ctx: CommandContext): Promise<void> => {
    const payload = ctx.command.payload
    const tenantId = typeof payload.tenant_id === 'string' && payload.tenant_id.trim() !== ''
      ? payload.tenant_id
      : ctx.tenantId
    const electronicInvoiceId = String(payload.electronic_invoice_id ?? '').trim()
    const requestId = String(payload.request_id ?? '').trim()

    if (!electronicInvoiceId) {
      throw new Error('fetch_official_view payload missing electronic_invoice_id')
    }
    if (!requestId) {
      throw new Error('fetch_official_view payload missing request_id')
    }

    const context = await deps.gateway.loadOfficialViewContext(
      tenantId,
      electronicInvoiceId,
      requestId,
    )
    if (!context || context.status !== 'PENDING') {
      return
    }

    let outcome: OfficialViewOutcome
    try {
      outcome = await deps.provider.fetchOfficialView({
        tenantId: context.tenantId,
        providerConnectionId: context.providerConnectionId,
        electronicInvoiceId: context.electronicInvoiceId,
        providerInvoiceReference: context.providerInvoiceReference,
        invoiceSeries: context.invoiceSeries,
        operationId: context.requestId,
      })
    } catch (error) {
      if (error instanceof ProviderCallAmbiguousError) {
        throw new Error(error.safeErrorCode)
      }
      throw error
    }

    switch (outcome.kind) {
      case 'success':
        await deps.gateway.recordOfficialViewResult({
          tenantId,
          electronicInvoiceId: context.electronicInvoiceId,
          requestId: context.requestId,
          status: 'AVAILABLE',
          viewerUrl: outcome.viewerUrl,
          expiresAt: outcome.expiresAt,
        })
        break
      case 'checkRequired':
        await deps.gateway.recordOfficialViewResult({
          tenantId,
          electronicInvoiceId: context.electronicInvoiceId,
          requestId: context.requestId,
          status: 'CHECK_REQUIRED',
          failureCode: outcome.safeErrorCode,
          failureSource: 'PROVIDER',
        })
        break
      case 'definiteFailure':
        await deps.gateway.recordOfficialViewResult({
          tenantId,
          electronicInvoiceId: context.electronicInvoiceId,
          requestId: context.requestId,
          status: 'FAILED',
          failureCode: outcome.failureCode,
          failureMessage: outcome.failureMessage,
          failureSource: 'PROVIDER',
        })
        break
      case 'ambiguous':
        throw new Error(outcome.safeErrorCode)
    }
  }
}

