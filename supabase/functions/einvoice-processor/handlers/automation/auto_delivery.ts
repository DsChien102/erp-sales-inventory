import type { CommandContext, CommandHandler } from '../../queue/types.ts'
import type {
  AutomationDeps,
  AutomationGateway,
  AutoDeliveryResult,
  AutoDeliveryStartRequest,
} from './gateways.ts'
import { autoDeliveryIdempotencyKey } from './idempotency_keys.ts'
import { parseStartAutoDeliveryPayload } from './payloads.ts'

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i

export async function startAutoDelivery(
  g: AutomationGateway,
  r: AutoDeliveryStartRequest,
): Promise<AutoDeliveryResult> {
  if (r.tenantId.trim().length === 0) {
    throw new Error('tenantId is required')
  }
  if (r.electronicInvoiceId.trim().length === 0) {
    throw new Error('electronicInvoiceId is required')
  }
  if (r.triggerId.trim().length === 0) {
    throw new Error('triggerId is required')
  }
  if (!UUID_REGEX.test(r.idempotencyKey)) {
    throw new Error('idempotencyKey must be a canonical UUID')
  }
  return await g.startAutoDelivery(r)
}

export function createStartAutoDeliveryHandler(
  deps: AutomationDeps,
): CommandHandler {
  return async (ctx: CommandContext) => {
    const payload = parseStartAutoDeliveryPayload(
      ctx.command.payload,
      ctx.tenantId,
    )
    const idempotencyKey = await autoDeliveryIdempotencyKey({
      tenantId: payload.tenantId,
      electronicInvoiceId: payload.electronicInvoiceId,
    })
    await startAutoDelivery(deps.gateway, {
      tenantId: payload.tenantId,
      electronicInvoiceId: payload.electronicInvoiceId,
      triggerId: ctx.command.commandId,
      idempotencyKey,
    })
  }
}

