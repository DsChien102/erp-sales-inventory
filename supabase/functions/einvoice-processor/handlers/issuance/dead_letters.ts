import type { DeadLetterHandler } from '../../queue/types.ts'
import { CanonicalInvoiceIntegrityError } from './errors.ts'
import type { IssuanceGateways } from './gateways.ts'

export function createIssuanceDeadLetters(
  gateways: IssuanceGateways,
): Record<string, DeadLetterHandler> {
  return {
    'einvoice.preview_invoice': async ({ tenantId, command, error }) => {
      const salesOrderId = command.payload['sales_order_id']
      const previewRequestId = command.payload['preview_request_id']
      if (
        typeof salesOrderId !== 'string' ||
        salesOrderId.trim().length === 0 ||
        typeof previewRequestId !== 'string' ||
        previewRequestId.trim().length === 0
      ) {
        return
      }

      await gateways.preview.store({
        tenantId,
        salesOrderId,
        requestId: previewRequestId,
        status: 'FAILED',
        failureCode: 'PROVIDER_UNAVAILABLE',
        failureMessage: String(error),
        failureSource: 'INTERNAL',
      })
    },

    'einvoice.publish_invoice': async ({ tenantId, command, error }) => {
      if (error instanceof CanonicalInvoiceIntegrityError) {
        await gateways.results.recordCommandIntegrityFailure(
          tenantId,
          error.attemptId,
          error.reasonCode,
        )
        return
      }

      const attemptId = command.payload['attempt_id']
      if (typeof attemptId !== 'string' || attemptId.trim().length === 0) {
        throw new Error('PublishInvoiceCommand payload missing attempt_id')
      }

      await gateways.results.recordPublishCommandDeadLetter(
        tenantId,
        attemptId,
        String(error),
      )
    },
  }
}

