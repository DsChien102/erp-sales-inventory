import {
  MeInvoiceInvoiceQuery,
  MeInvoiceSendEmailData,
  MeInvoiceSendEmailRequest,
} from '../../misa/mod.ts'
import type { TenantMisaClientFactory } from '../misa_client_factory.ts'
import { classifyDelivery } from './delivery_classifier.ts'
import type {
  DeliveryProviderContext,
  DeliveryProviderOutcome,
} from './outcomes.ts'

export interface DeliveryProvider {
  sendEmail(ctx: DeliveryProviderContext): Promise<DeliveryProviderOutcome>
}

export function createDeliveryProvider(deps: {
  clients: TenantMisaClientFactory
  log?: (event: string, data: Record<string, unknown>) => void
}): DeliveryProvider {
  return {
    async sendEmail(ctx: DeliveryProviderContext): Promise<DeliveryProviderOutcome> {
      const query = MeInvoiceInvoiceQuery.tryFromInvSeries(ctx.invoiceSeries)
      if (query === null) {
        return {
          kind: 'definiteFailure',
          safeErrorCode: 'INVOICE_SERIES_INVALID',
        }
      }

      const tenantClient = await deps.clients.getForTenant(ctx.tenantId)
      if (tenantClient === null) {
        return {
          kind: 'definiteFailure',
          safeErrorCode: 'PROVIDER_AUTH_FAILED',
        }
      }

      const request = new MeInvoiceSendEmailRequest(
        [
          new MeInvoiceSendEmailData(
            ctx.providerTransactionId,
            ctx.recipientName,
            ctx.recipientEmail,
          ),
        ],
        query.invoiceWithCode,
        query.invoiceCalcu,
      )

      const result = await tenantClient.client.sendEmail(request)
      const outcome = classifyDelivery(result, ctx.providerTransactionId)

      const resolved: DeliveryProviderOutcome = outcome.kind === 'succeeded'
        ? { kind: 'succeeded', providerReference: ctx.providerTransactionId }
        : outcome

      deps.log?.('einvoice_email_provider_result', {
        tenantId: ctx.tenantId,
        providerTransactionId: ctx.providerTransactionId,
        outcomeKind: resolved.kind === 'succeeded'
          ? 'succeeded'
          : resolved.kind === 'definiteFailure'
          ? 'definite_failure'
          : resolved.kind === 'retryableFailure'
          ? 'retryable_failure'
          : 'undetermined',
        safeCode: resolved.kind === 'succeeded' ? null : resolved.safeErrorCode,
      })

      return resolved
    },
  }
}
