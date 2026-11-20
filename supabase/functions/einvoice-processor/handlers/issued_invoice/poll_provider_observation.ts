import type { CommandContext, CommandHandler } from '../../queue/types.ts'
import { ProviderCallAmbiguousError } from './errors.ts'
import type { IssuedInvoiceDeps } from './gateways.ts'
import type { ObservationOutcome } from './outcomes.ts'
import { recordProviderObservation } from './record_provider_observation.ts'

export function createPollProviderObservationHandler(
  deps: IssuedInvoiceDeps,
): CommandHandler {
  return async (ctx: CommandContext): Promise<void> => {
    const payload = ctx.command.payload
    const tenantId = typeof payload.tenant_id === 'string' && payload.tenant_id.trim() !== ''
      ? payload.tenant_id
      : ctx.tenantId
    const triggerId = String(payload.trigger_id ?? '').trim()

    if (!triggerId) {
      throw new Error('trigger_id must not be blank')
    }

    const context = await deps.gateway.loadObservationContext(
      tenantId,
      ctx.command.commandId,
    )
    if (!context) {
      return
    }

    let outcome: ObservationOutcome
    try {
      outcome = await deps.provider.observe({
        tenantId: context.tenantId,
        providerConnectionId: context.providerConnectionId,
        electronicInvoiceId: context.electronicInvoiceId,
        providerInvoiceReference: context.providerInvoiceReference,
        invoiceSeries: context.invoiceSeries,
        operationId: context.commandId,
      })
    } catch (error) {
      if (error instanceof ProviderCallAmbiguousError) {
        throw new Error(error.safeErrorCode)
      }
      throw error
    }

    switch (outcome.kind) {
      case 'ambiguous':
        throw new Error(outcome.safeErrorCode)
      case 'found':
        await recordProviderObservation(deps.gateway, {
          tenantId,
          electronicInvoiceId: context.electronicInvoiceId,
          providerStateCode: outcome.providerStateCode,
          safeDescription: outcome.safeDescription,
          providerReference: outcome.providerReference,
          observedAt: outcome.observedAt,
          deduplicationKey: `provider_observation:${ctx.command.commandId}`,
          detailsSnapshot: outcome.detailsSnapshot,
          correlationId: context.correlationId,
        })
        break
      case 'notFound':
      case 'mismatch':
        await recordProviderObservation(deps.gateway, {
          tenantId,
          electronicInvoiceId: context.electronicInvoiceId,
          providerStateCode: outcome.providerStateCode,
          safeDescription: outcome.safeDescription,
          providerReference: outcome.providerReference,
          observedAt: outcome.observedAt,
          deduplicationKey: `provider_observation:${ctx.command.commandId}`,
          detailsSnapshot: {},
          correlationId: context.correlationId,
        })
        break
    }
  }
}

