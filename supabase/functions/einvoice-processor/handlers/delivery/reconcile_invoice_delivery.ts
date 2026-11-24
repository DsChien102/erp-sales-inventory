import type { CommandContext, CommandHandler } from '../../queue/types.ts'
import { parseReconciliationPayload } from './delivery_payload.ts'
import type { DeliveryDeps } from './gateways.ts'

export function createReconcileInvoiceDeliveryHandler(
  deps: DeliveryDeps,
): CommandHandler {
  return async function handle(ctx: CommandContext): Promise<void> {
    const { reconciliationCaseId, checkSequence } = parseReconciliationPayload(
      ctx.command.payload,
    )
    if (!reconciliationCaseId) {
      throw new Error(
        'reconcile_invoice_delivery payload missing reconciliation_case_id',
      )
    }

    const context = await deps.gateway.loadReconciliationContext(
      ctx.tenantId,
      reconciliationCaseId,
      checkSequence,
    )
    if (!context) {
      return
    }

    if (!context.supportsDeliveryResultObservation) {
      await deps.gateway.recordReconciliationCheck({
        tenantId: ctx.tenantId,
        reconciliationCaseId,
        expectedCaseVersion: context.caseVersion,
        checkSequence,
        kind: 'UNSUPPORTED',
        safeCode: 'DELIVERY_RESULT_OBSERVATION_UNSUPPORTED',
      })
      return
    }

    const outcome = await deps.observation.observe({
      tenantId: ctx.tenantId,
      reconciliationCaseId,
      deliveryId: context.deliveryId,
      providerConnectionId: context.providerConnectionId,
      providerDeliveryReference: context.providerDeliveryReference,
    })

    if (outcome.kind === 'succeeded') {
      await deps.gateway.recordReconciliationCheck({
        tenantId: ctx.tenantId,
        reconciliationCaseId,
        expectedCaseVersion: context.caseVersion,
        checkSequence,
        kind: 'SUCCESS',
        providerReference: outcome.providerReference,
      })
    } else if (outcome.kind === 'definiteFailure') {
      await deps.gateway.recordReconciliationCheck({
        tenantId: ctx.tenantId,
        reconciliationCaseId,
        expectedCaseVersion: context.caseVersion,
        checkSequence,
        kind: 'DEFINITE_FAILURE',
        safeCode: outcome.safeCode,
      })
    } else if (outcome.kind === 'undetermined') {
      await deps.gateway.recordReconciliationCheck({
        tenantId: ctx.tenantId,
        reconciliationCaseId,
        expectedCaseVersion: context.caseVersion,
        checkSequence,
        kind: 'UNDETERMINED',
        safeCode: outcome.safeCode,
      })
    } else {
      await deps.gateway.recordReconciliationCheck({
        tenantId: ctx.tenantId,
        reconciliationCaseId,
        expectedCaseVersion: context.caseVersion,
        checkSequence,
        kind: 'UNSUPPORTED',
        safeCode: 'DELIVERY_RESULT_OBSERVATION_UNSUPPORTED',
      })
    }
  }
}
