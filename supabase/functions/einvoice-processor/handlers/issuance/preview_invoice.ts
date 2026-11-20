import { ProviderUnavailableError } from '../../queue/errors.ts'
import type { CommandContext, CommandHandler } from '../../queue/types.ts'
import type { IssuanceGateways } from './gateways.ts'
import type { IssuanceProvider } from './issuance_provider.ts'

export function createPreviewInvoiceHandler(deps: {
  provider: IssuanceProvider
  gateways: IssuanceGateways
}): CommandHandler {
  return async (ctx: CommandContext): Promise<void> => {
    const payload = ctx.command.payload
    const tenantId = payload['tenant_id']
    const salesOrderId = payload['sales_order_id']
    const previewRequestId = payload['preview_request_id']
    const canonicalInvoice = payload['canonical_invoice']

    if (typeof tenantId !== 'string' || tenantId.trim().length === 0) {
      throw new Error('PreviewInvoiceCommand payload missing tenant_id')
    }
    if (typeof salesOrderId !== 'string' || salesOrderId.trim().length === 0) {
      throw new Error('PreviewInvoiceCommand payload missing sales_order_id')
    }
    if (typeof previewRequestId !== 'string' || previewRequestId.trim().length === 0) {
      throw new Error('PreviewInvoiceCommand payload missing preview_request_id')
    }
    if (typeof canonicalInvoice !== 'object' || canonicalInvoice === null || Array.isArray(canonicalInvoice)) {
      throw new Error('PreviewInvoiceCommand payload missing canonical_invoice')
    }

    const canonical: Record<string, unknown> = { ...(canonicalInvoice as Record<string, unknown>) }
    if (canonical['refId'] == null) {
      canonical['refId'] = previewRequestId
    }

    const outcome = await deps.provider.previewUnpublished(tenantId, canonical)

    if (outcome.kind === 'success') {
      await deps.gateways.preview.store({
        tenantId,
        salesOrderId,
        requestId: previewRequestId,
        status: 'READY',
        viewerRef: outcome.viewerRef,
      })
      return
    }

    if (outcome.kind === 'providerUnavailable') {
      throw new ProviderUnavailableError()
    }

    await deps.gateways.preview.store({
      tenantId,
      salesOrderId,
      requestId: previewRequestId,
      status: 'FAILED',
      failureCode: outcome.kind === 'invalidData' ? 'PROVIDER_REJECTED_INVOICE_DATA' : 'PROVIDER_AUTH_FAILED',
      failureMessage: outcome.kind === 'invalidData' ? outcome.detail : null,
      failureSource: 'PROVIDER',
    })
  }
}
