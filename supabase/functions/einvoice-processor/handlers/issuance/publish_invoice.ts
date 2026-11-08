import { PublishSeriesLeaseBusyError } from '../../queue/errors.ts'
import type { CommandContext, CommandHandler } from '../../queue/types.ts'
import { CanonicalInvoiceIntegrityError } from './errors.ts'
import type { IssuanceGateways } from './gateways.ts'
import type { IssuanceProvider } from './issuance_provider.ts'

export function createPublishInvoiceHandler(deps: {
  provider: IssuanceProvider
  gateways: IssuanceGateways
}): CommandHandler {
  return async (ctx: CommandContext): Promise<void> => {
    const payload = ctx.command.payload
    const tenantId = payload['tenant_id']
    const attemptId = payload['attempt_id']
    const canonicalInvoice = payload['canonical_invoice']
    const payloadHash = payload['payload_hash']
    const idempotencyKey = payload['idempotency_key']

    if (typeof tenantId !== 'string' || tenantId.trim().length === 0) {
      throw new Error('PublishInvoiceCommand payload missing tenant_id')
    }
    if (typeof attemptId !== 'string' || attemptId.trim().length === 0) {
      throw new Error('PublishInvoiceCommand payload missing attempt_id')
    }
    if (typeof canonicalInvoice !== 'object' || canonicalInvoice === null || Array.isArray(canonicalInvoice)) {
      throw new Error('PublishInvoiceCommand payload missing canonical_invoice')
    }
    if (typeof payloadHash !== 'string' || payloadHash.trim().length === 0) {
      throw new Error('PublishInvoiceCommand payload missing payload_hash')
    }
    if (typeof idempotencyKey !== 'string' || idempotencyKey.trim().length === 0) {
      throw new Error('PublishInvoiceCommand payload missing idempotency_key')
    }

    try {
      deps.provider.validateCanonical(canonicalInvoice as Record<string, unknown>)
    } catch (error) {
      if (error instanceof CanonicalInvoiceIntegrityError) {
        throw error
      }
      throw new CanonicalInvoiceIntegrityError(
        attemptId,
        'COMMAND_INTEGRITY',
        error instanceof Error ? error.message : String(error),
      )
    }

    const leaseOutcome = await deps.gateways.lease.tryAcquire(tenantId, attemptId, ctx.command.commandId)
    if (leaseOutcome.kind === 'busy') {
      throw new PublishSeriesLeaseBusyError(leaseOutcome.retryAfterSeconds)
    }

    const { providerConnectionId, invoiceSeries, leaseVersion } = leaseOutcome
    try {
      const action = await deps.gateways.results.preparePublish({
        tenantId,
        attemptId,
        idempotencyKey,
        payloadHash,
        canonicalInvoice: canonicalInvoice as Record<string, unknown>,
      })

      if (action === 'SKIP') {
        return
      }

      if (action === 'RECONCILE_ONLY') {
        await deps.gateways.results.recordUndetermined(tenantId, attemptId, {
          kind: 'undetermined',
          idempotencyKey,
          payloadHash,
          reasonCode: 'DISPATCH_STATE_UNCERTAIN',
        })
        return
      }

      await deps.gateways.results.markProviderCallStarted(tenantId, attemptId)

      const outcome = await deps.provider.publish(
        tenantId,
        canonicalInvoice as Record<string, unknown>,
        idempotencyKey,
      )

      switch (outcome.kind) {
        case 'success':
          await deps.gateways.results.recordSuccess(tenantId, attemptId, {
            kind: 'success',
            idempotencyKey,
            payloadHash,
            providerReference: outcome.providerReference,
            invoiceNumber: outcome.invoiceNumber,
            invoiceSeries: outcome.invoiceSeries,
            issuedAt: outcome.issuedAt,
          })
          break
        case 'definiteFailure':
          await deps.gateways.results.recordDefiniteFailure(tenantId, attemptId, {
            kind: 'definiteFailure',
            idempotencyKey,
            payloadHash,
            providerCode: outcome.providerCode,
            providerMessage: outcome.providerMessage,
          })
          break
        case 'retryableRejection':
          await deps.gateways.results.recordRetryableProviderRejection({
            tenantId,
            attemptId,
            sourceCommandId: ctx.command.commandId,
            evidence: {
              kind: 'retryableProviderRejection',
              idempotencyKey,
              payloadHash,
              providerCode: outcome.providerCode,
              providerMessage: outcome.providerMessage,
            },
            retryAfterSeconds: outcome.retryAfterSeconds,
          })
          break
        case 'undetermined':
          await deps.gateways.results.recordUndetermined(tenantId, attemptId, {
            kind: 'undetermined',
            idempotencyKey,
            payloadHash,
            reasonCode: outcome.reasonCode,
          })
          break
      }
    } finally {
      await deps.gateways.lease.release({
        tenantId,
        providerConnectionId,
        invoiceSeries,
        ownerToken: ctx.command.commandId,
        leaseVersion,
      })
    }
  }
}

