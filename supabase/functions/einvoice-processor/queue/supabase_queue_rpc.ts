import type { SupabaseClient } from 'npm:@supabase/supabase-js@2'
import type { ClaimedCommand, Disposition, QueueRpc } from './types.ts'

type Row = Record<string, unknown>

/** QueueRpc backed by the `einvoice` schema RPCs (service_role client). */
export class SupabaseQueueRpc implements QueueRpc {
  constructor(private readonly client: SupabaseClient) {}

  async #call(name: string, args: Record<string, unknown>): Promise<unknown> {
    const { data, error } = await this.client.schema('einvoice').rpc(name, args)
    if (error) throw new Error(`${name}: ${error.message}`)
    return data
  }

  async listTenantsWithDueCommands(limit: number): Promise<string[]> {
    const data = (await this.#call('list_tenants_with_due_commands', { p_limit: limit })) as Row[] | null
    return (data ?? []).map((r) => String(r.tenant_id))
  }

  async seedDueReconciliationCommands(tenantId: string, limit: number): Promise<number> {
    const data = await this.#call('seed_due_issuance_reconciliation_commands', {
      p_tenant_id: tenantId,
      p_limit: limit,
    })
    return typeof data === 'number' ? data : 0
  }

  async claimBatch(tenantId: string, limit: number): Promise<ClaimedCommand[]> {
    const data = (await this.#call('claim_internal_commands_batch', {
      p_tenant_id: tenantId,
      p_limit: limit,
    })) as Row[] | null
    return (data ?? []).map((r) => ({
      commandId: String(r.command_id),
      commandType: String(r.command_type),
      payload: (r.payload && typeof r.payload === 'object' ? r.payload : {}) as Record<string, unknown>,
      sourceEventId: r.source_event_id == null ? null : String(r.source_event_id),
      enqueuedAt: String(r.enqueued_at),
      claimToken: String(r.claim_token),
      retryCount: Number(r.retry_count ?? 0),
    }))
  }

  async complete(tenantId: string, commandId: string, claimToken: string): Promise<void> {
    await this.#call('complete_internal_command', {
      p_tenant_id: tenantId,
      p_command_id: commandId,
      p_claim_token: claimToken,
    })
  }

  async fail(tenantId: string, commandId: string, claimToken: string, error: string): Promise<void> {
    await this.#call('fail_internal_command', {
      p_tenant_id: tenantId,
      p_command_id: commandId,
      p_claim_token: claimToken,
      p_error: error,
    })
  }

  async retryOrDeadLetter(
    tenantId: string,
    commandId: string,
    claimToken: string,
    error: string,
  ): Promise<Disposition> {
    const data = (await this.#call('retry_or_dead_letter_internal_command', {
      p_tenant_id: tenantId,
      p_command_id: commandId,
      p_claim_token: claimToken,
      p_error: error,
    })) as Row[] | Row | null
    const row = Array.isArray(data) ? data[0] : data
    const disposition = row?.disposition
    if (disposition !== 'RETRY' && disposition !== 'DEAD_LETTER') {
      throw new Error(`retry_or_dead_letter_internal_command: unexpected disposition ${String(disposition)}`)
    }
    return disposition
  }

  async reschedule(tenantId: string, commandId: string, claimToken: string, delaySeconds: number): Promise<void> {
    await this.#call('reschedule_internal_command', {
      p_tenant_id: tenantId,
      p_command_id: commandId,
      p_claim_token: claimToken,
      p_delay_seconds: delaySeconds,
    })
  }
}
