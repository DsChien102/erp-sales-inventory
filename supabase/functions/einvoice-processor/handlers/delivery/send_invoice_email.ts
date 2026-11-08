import type { CommandContext, CommandHandler } from '../../queue/types.ts'
import { parseDeliveryPayload } from './delivery_payload.ts'
import type { DeliveryDeps } from './gateways.ts'
import type { DeliveryResultEvidence, DeliveryResultKind } from './outcomes.ts'
import { providerCallReference } from './provider_call_reference.ts'
import { recordDeliveryResult } from './record_delivery_result.ts'

export function createSendInvoiceEmailHandler(deps: DeliveryDeps): CommandHandler {
  return async function handle(ctx: CommandContext): Promise<void> {
    const { tenantId, deliveryId, retryCount } = parseDeliveryPayload(
      ctx.command.payload,
      ctx.tenantId,
    )

    const attemptContext = await deps.gateway.loadAttemptContext(
      tenantId,
      deliveryId,
      retryCount,
    )
    if (!attemptContext) {
      return
    }

    const requestReference = await providerCallReference(
      ctx.command.commandId,
      ctx.attemptNumber,
    )

    const prepare = await deps.gateway.prepareProviderCall(
      tenantId,
      deliveryId,
      retryCount,
      requestReference,
    )

    if (prepare.action === 'SKIP') {
      return
    }

    if (prepare.action === 'RECORD_UNKNOWN') {
      await recordDeliveryResult(deps.gateway, {
        tenantId,
        deliveryId,
        retryCount,
        expectedDeliveryVersion: prepare.deliveryVersion,
        evidence: {
          kind: 'UNDETERMINED',
          safeCode: 'DISPATCH_STATE_UNCERTAIN',
          failureSource: 'INTERNAL',
        },
      })
      return
    }

    if (prepare.action === 'CALL_PROVIDER') {
      let evidence: DeliveryResultEvidence
      try {
        const outcome = await deps.provider.sendEmail(prepare.providerContext)
        if (outcome.kind === 'succeeded') {
          evidence = {
            kind: 'SUCCESS',
            providerReference: outcome.providerReference,
            failureSource: null,
          }
        } else {
          const kind: DeliveryResultKind = outcome.kind === 'definiteFailure'
            ? 'DEFINITE_FAILURE'
            : outcome.kind === 'retryableFailure'
            ? 'RETRYABLE_FAILURE'
            : 'UNDETERMINED'
          evidence = {
            kind,
            safeCode: outcome.safeErrorCode,
            failureSource: 'PROVIDER',
          }
        }
      } catch (_e) {
        evidence = {
          kind: 'UNDETERMINED',
          safeCode: 'PROVIDER_TRANSPORT_FAILURE',
          failureSource: 'INTERNAL',
        }
      }

      await recordDeliveryResult(deps.gateway, {
        tenantId,
        deliveryId,
        retryCount,
        expectedDeliveryVersion: prepare.deliveryVersion,
        evidence,
      })
    }
  }
}
