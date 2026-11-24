import type { CommandContext, CommandHandler } from '../../queue/types.ts'
import type {
  AutomationDeps,
  AutomationGateway,
  AutoIssuanceReevaluationRequest,
  AutoIssuanceResult,
  AutoIssuanceStartRequest,
} from './gateways.ts'
import {
  SALES_ORDER_FINALIZED_EVENT_TYPE,
  autoIssuanceIdempotencyKey,
  autoIssuanceTriggerKey,
} from './idempotency_keys.ts'
import {
  parseReevaluateAutoIssuancePayload,
  parseStartAutoIssuancePayload,
} from './payloads.ts'

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i

export async function startAutoIssuance(
  g: AutomationGateway,
  r: AutoIssuanceStartRequest,
): Promise<AutoIssuanceResult> {
  if (r.tenantId.trim().length === 0) {
    throw new Error('tenantId is required')
  }
  if (r.salesOrderId.trim().length === 0) {
    throw new Error('salesOrderId is required')
  }
  if (r.triggerKey.trim().length === 0) {
    throw new Error('triggerKey is required')
  }
  if (!UUID_REGEX.test(r.idempotencyKey)) {
    throw new Error('idempotencyKey must be a canonical UUID')
  }
  return await g.startAutoIssuance(r)
}

export async function reevaluateAutoIssuance(
  g: AutomationGateway,
  r: AutoIssuanceReevaluationRequest,
): Promise<AutoIssuanceResult> {
  if (r.tenantId.trim().length === 0) {
    throw new Error('tenantId is required')
  }
  if (r.processId.trim().length === 0) {
    throw new Error('processId is required')
  }
  if (r.sourceEventId.trim().length === 0) {
    throw new Error('sourceEventId is required')
  }
  return await g.reevaluateAutoIssuance(r)
}

export function createStartAutoIssuanceHandler(
  deps: AutomationDeps,
): CommandHandler {
  return async (ctx: CommandContext) => {
    const payload = parseStartAutoIssuancePayload(
      ctx.command.payload,
      ctx.tenantId,
    )
    const triggerKey = autoIssuanceTriggerKey({
      eventType: SALES_ORDER_FINALIZED_EVENT_TYPE,
      eventId: ctx.command.commandId,
      salesOrderId: payload.salesOrderId,
      sourceVersion: payload.sourceVersion,
    })
    const idempotencyKey = await autoIssuanceIdempotencyKey({
      tenantId: payload.tenantId,
      salesOrderId: payload.salesOrderId,
      sourceVersion: payload.sourceVersion,
    })
    await startAutoIssuance(deps.gateway, {
      tenantId: payload.tenantId,
      salesOrderId: payload.salesOrderId,
      triggerKey,
      idempotencyKey,
    })
  }
}

export function createReevaluateAutoIssuanceHandler(
  deps: AutomationDeps,
): CommandHandler {
  return async (ctx: CommandContext) => {
    const payload = parseReevaluateAutoIssuancePayload(
      ctx.command.payload,
      ctx.tenantId,
    )
    await reevaluateAutoIssuance(deps.gateway, {
      tenantId: payload.tenantId,
      processId: payload.processId,
      sourceEventId: payload.sourceEventId,
    })
  }
}

