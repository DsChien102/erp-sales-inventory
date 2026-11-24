import type { SupabaseClient } from 'npm:@supabase/supabase-js@2'
import type {
  AutomationGateway,
  AutoIssuanceStartRequest,
  AutoIssuanceReevaluationRequest,
  AutoIssuanceResult,
  AutoDeliveryStartRequest,
  AutoDeliveryResult,
} from './gateways.ts'

function asList(data: unknown): Array<Record<string, unknown>> {
  if (Array.isArray(data)) return data as Array<Record<string, unknown>>
  if (typeof data === 'object' && data !== null) return [data as Record<string, unknown>]
  return []
}

class SupabaseAutomationGateway implements AutomationGateway {
  constructor(private readonly client: SupabaseClient) {}

  async startAutoIssuance(r: AutoIssuanceStartRequest): Promise<AutoIssuanceResult> {
    const { data, error } = await this.client.schema('einvoice').rpc(
      'start_auto_issuance',
      {
        p_tenant_id: r.tenantId,
        p_sales_order_id: r.salesOrderId,
        p_trigger_key: r.triggerKey,
        p_idempotency_key: r.idempotencyKey,
      },
    )
    if (error) {
      throw new Error(`start_auto_issuance: ${error.message}`)
    }
    const rows = asList(data)
    if (rows.length === 0) {
      throw new Error('start_auto_issuance returned no rows')
    }
    const row = rows[0]
    const started = row['started'] === true
    const skipped = (row['skipped'] as boolean | undefined) ?? !started
    return {
      started,
      skipped,
      processId: String(row['process_id'] ?? ''),
      attemptId: row['attempt_id'] != null ? String(row['attempt_id']) : null,
      status: String(row['status'] ?? ''),
      reason: row['reason'] != null ? String(row['reason']) : null,
    }
  }

  async reevaluateAutoIssuance(r: AutoIssuanceReevaluationRequest): Promise<AutoIssuanceResult> {
    const { data, error } = await this.client.schema('einvoice').rpc(
      'reevaluate_auto_issuance',
      {
        p_tenant_id: r.tenantId,
        p_process_id: r.processId,
        p_source_event_id: r.sourceEventId,
      },
    )
    if (error) {
      throw new Error(`reevaluate_auto_issuance: ${error.message}`)
    }
    const rows = asList(data)
    if (rows.length === 0) {
      throw new Error('reevaluate_auto_issuance returned no rows')
    }
    const row = rows[0]
    const started = row['started'] === true
    const skipped = (row['skipped'] as boolean | undefined) ?? !started
    return {
      started,
      skipped,
      processId: String(row['process_id'] ?? ''),
      attemptId: row['attempt_id'] != null ? String(row['attempt_id']) : null,
      status: String(row['status'] ?? ''),
      reason: row['reason'] != null ? String(row['reason']) : null,
    }
  }

  async startAutoDelivery(r: AutoDeliveryStartRequest): Promise<AutoDeliveryResult> {
    const { data, error } = await this.client.schema('einvoice').rpc(
      'start_auto_delivery',
      {
        p_tenant_id: r.tenantId,
        p_electronic_invoice_id: r.electronicInvoiceId,
        p_trigger_id: r.triggerId,
        p_idempotency_key: r.idempotencyKey,
      },
    )
    if (error) {
      throw new Error(`start_auto_delivery: ${error.message}`)
    }
    const rows = asList(data)
    if (rows.length === 0) {
      throw new Error('start_auto_delivery returned no rows')
    }
    const row = rows[0]
    const rawDisp = String(row['disposition'] ?? '')
    if (rawDisp !== 'started' && rawDisp !== 'skipped') {
      throw new Error(`Unknown auto delivery disposition: ${rawDisp}`)
    }
    return {
      disposition: rawDisp,
      deliveryId: row['delivery_id'] != null ? String(row['delivery_id']) : null,
      skipReason: rawDisp === 'skipped' && row['skip_reason'] != null ? String(row['skip_reason']) : null,
    }
  }
}

export function createSupabaseAutomationGateway(
  client: SupabaseClient,
): AutomationGateway {
  return new SupabaseAutomationGateway(client)
}

