import type { CommandContext, CommandHandler } from '../../queue/types.ts'
import type { IssuanceGateways } from './gateways.ts'
import type { IssuanceProvider } from './issuance_provider.ts'
import {
  delayBeforeCheckSeconds,
  MIN_INVOICE_NUMBER_NOT_CONTINUOUS_BACKOFF_SECONDS,
  MISA_PUBLISH_PROVIDER_CODES,
  PUBLISH_UNDETERMINED_REASON,
  shouldMarkUnresolved,
} from './outcomes.ts'
import { recordIssuanceResult } from './record_issuance_result.ts'

export function createPollIssuanceStatusHandler(deps: {
  provider: IssuanceProvider
  gateways: IssuanceGateways
}): CommandHandler {
  return async (ctx: CommandContext): Promise<void> => {
    const payload = ctx.command.payload
    const tenantId = payload['tenant_id']
    const caseId = payload['case_id']
    const attemptId = payload['attempt_id']
    const correlationId = payload['correlation_id']

    if (typeof tenantId !== 'string' || tenantId.trim().length === 0) {
      throw new Error('PollIssuanceStatusCommand payload missing tenant_id')
    }
    if (typeof caseId !== 'string' || caseId.trim().length === 0) {
      throw new Error('PollIssuanceStatusCommand payload missing case_id')
    }
    if (typeof attemptId !== 'string' || attemptId.trim().length === 0) {
      throw new Error('PollIssuanceStatusCommand payload missing attempt_id')
    }
    if (typeof correlationId !== 'string' || correlationId.trim().length === 0) {
      throw new Error('PollIssuanceStatusCommand payload missing correlation_id')
    }

    const context = await deps.gateways.reconciliation.claim(
      tenantId,
      caseId,
      correlationId,
    )

    if (context === null) {
      return
    }

    const reconcileDuplicate =
      context.reconciliationReasonCode ===
      PUBLISH_UNDETERMINED_REASON.invoiceDuplicatedReconcileFirst

    const providerReference = context.providerReference?.trim()
    if (!reconcileDuplicate && (!providerReference || providerReference.length === 0)) {
      await deps.gateways.reconciliation.resolve({
        tenantId,
        caseId,
        outcome: 'UNRESOLVED',
        evidence: {
          claim_token: context.claimToken,
          reason_code: 'MISSING_PROVIDER_TRANSACTION_ID',
        },
      })
      return
    }

    const statusLookup: 'providerTransactionId' | 'refId' = reconcileDuplicate
      ? 'refId'
      : 'providerTransactionId'
    const statusLookupKey = statusLookup === 'refId'
      ? context.idempotencyKey
      : providerReference!

    const outcome = await deps.provider.getStatus({
      tenantId,
      statusLookupKey,
      invoiceSeries: context.invoiceSeries,
      idempotencyKey: context.idempotencyKey,
      payloadHash: context.payloadHash,
      statusLookup,
    })

    switch (outcome.kind) {
      case 'success': {
        await recordIssuanceResult(deps.gateways.results, {
          tenantId,
          attemptId: context.attemptId,
          correlationId,
          evidence: outcome.evidence,
        })
        const issuedAtStr = outcome.evidence.issuedAt instanceof Date
          ? outcome.evidence.issuedAt.toISOString()
          : new Date(outcome.evidence.issuedAt).toISOString()
        await deps.gateways.reconciliation.resolve({
          tenantId,
          caseId,
          outcome: 'SUCCESS',
          evidence: {
            provider_reference: outcome.evidence.providerReference,
            invoice_number: outcome.evidence.invoiceNumber,
            invoice_series: outcome.evidence.invoiceSeries,
            issued_at: issuedAtStr,
          },
        })
        break
      }

      case 'definiteFailure': {
        await recordIssuanceResult(deps.gateways.results, {
          tenantId,
          attemptId: context.attemptId,
          correlationId,
          evidence: outcome.evidence,
        })
        await deps.gateways.reconciliation.resolve({
          tenantId,
          caseId,
          outcome: 'FAILURE',
          evidence: {
            provider_code: outcome.evidence.providerCode,
            provider_message: outcome.evidence.providerMessage,
          },
        })
        break
      }

      case 'pending': {
        const completedChecks = context.checkSequence
        if (shouldMarkUnresolved(completedChecks)) {
          await deps.gateways.reconciliation.resolve({
            tenantId,
            caseId,
            outcome: 'UNRESOLVED',
            evidence: {
              claim_token: context.claimToken,
              reason_code: 'POLL_MAX_CHECKS_EXCEEDED',
            },
          })
        } else {
          const nextSequence = completedChecks + 1
          const nextDelaySeconds = delayBeforeCheckSeconds(nextSequence)
          await deps.gateways.reconciliation.recordPendingCheck({
            tenantId,
            caseId,
            claimToken: context.claimToken,
            nextDelaySeconds,
            checkSequence: nextSequence,
          })
        }
        break
      }

      case 'undetermined': {
        if (
          reconcileDuplicate &&
          outcome.reasonCode === 'STATUS_EMPTY_DATA' &&
          shouldMarkUnresolved(context.checkSequence)
        ) {
          await deps.gateways.results.recordRetryableProviderRejection({
            tenantId,
            attemptId: context.attemptId,
            sourceCommandId: ctx.command.commandId,
            evidence: {
              kind: 'retryableProviderRejection',
              idempotencyKey: context.idempotencyKey,
              payloadHash: context.payloadHash,
              providerCode: MISA_PUBLISH_PROVIDER_CODES.invoiceDuplicated,
              providerMessage: 'definitive-not-found after reconcile-first polls',
            },
            retryAfterSeconds: MIN_INVOICE_NUMBER_NOT_CONTINUOUS_BACKOFF_SECONDS,
          })
          await deps.gateways.reconciliation.resolve({
            tenantId,
            caseId,
            outcome: 'PUBLISH_RETRY_SCHEDULED',
            evidence: { provider_code: MISA_PUBLISH_PROVIDER_CODES.invoiceDuplicated },
          })
          return
        }

        const completedChecks = context.checkSequence
        if (shouldMarkUnresolved(completedChecks)) {
          await deps.gateways.reconciliation.resolve({
            tenantId,
            caseId,
            outcome: 'UNRESOLVED',
            evidence: {
              claim_token: context.claimToken,
              reason_code: 'POLL_MAX_CHECKS_EXCEEDED',
            },
          })
        } else {
          const nextSequence = completedChecks + 1
          const nextDelaySeconds = delayBeforeCheckSeconds(nextSequence)
          await deps.gateways.reconciliation.recordPendingCheck({
            tenantId,
            caseId,
            claimToken: context.claimToken,
            nextDelaySeconds,
            checkSequence: nextSequence,
          })
        }
        break
      }
    }
  }
}
