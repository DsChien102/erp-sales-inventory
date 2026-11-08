import type { DeadLetterHandler } from '../../queue/types.ts'
import {
  parseDeliveryPayload,
  parseReconciliationPayload,
} from './delivery_payload.ts'
import type { DeliveryGateway } from './gateways.ts'

export function createDeliveryDeadLetters(
  gateway: DeliveryGateway,
): Record<string, DeadLetterHandler> {
  return {
    'einvoice.send_invoice_email': async ({ tenantId, command }) => {
      const payload = parseDeliveryPayload(command.payload, tenantId)
      await gateway.recordCommandDeadLetter(
        tenantId,
        payload.deliveryId,
        payload.retryCount,
        'WORKER_EXHAUSTED_BEFORE_DISPATCH',
      )
    },
    'einvoice.reconcile_invoice_delivery': async ({ tenantId, command }) => {
      const { reconciliationCaseId, checkSequence } = parseReconciliationPayload(
        command.payload,
      )
      if (!reconciliationCaseId) {
        return
      }
      const context = await gateway.loadReconciliationContext(
        tenantId,
        reconciliationCaseId,
        checkSequence,
      )
      if (!context) {
        return
      }
      await gateway.recordReconciliationCheck({
        tenantId,
        reconciliationCaseId,
        expectedCaseVersion: context.caseVersion,
        checkSequence,
        kind: 'UNSUPPORTED',
        safeCode: 'DELIVERY_RECONCILIATION_WORKER_EXHAUSTED',
      })
    },
  }
}
