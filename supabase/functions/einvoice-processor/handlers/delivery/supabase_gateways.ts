import type { SupabaseClient } from 'npm:@supabase/supabase-js@2'
import type {
  DeliveryAttemptContext,
  DeliveryGateway,
  DeliveryResultRecord,
  PrepareResult,
  ReconciliationCheckRecord,
  ReconciliationContext,
} from './gateways.ts'

function asList(data: unknown): Array<Record<string, unknown>> {
  if (Array.isArray(data)) return data as Array<Record<string, unknown>>
  if (typeof data === 'object' && data !== null) return [data as Record<string, unknown>]
  return []
}

function requiredString(row: Record<string, unknown>, key: string): string {
  const value = row[key]
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new Error(`RPC row missing required field: ${key}`)
  }
  return value
}

function requiredBool(row: Record<string, unknown>, key: string): boolean {
  const value = row[key]
  if (typeof value !== 'boolean') {
    throw new Error(`RPC row missing required bool field: ${key}`)
  }
  return value
}

function requiredInt(row: Record<string, unknown>, key: string): number {
  const value = row[key]
  if (typeof value === 'number' && Number.isInteger(value)) {
    return value
  }
  if (typeof value === 'string' && /^-?\d+$/.test(value.trim())) {
    const parsed = parseInt(value.trim(), 10)
    if (!Number.isNaN(parsed)) {
      return parsed
    }
  }
  throw new Error(`RPC row missing required int field: ${key}`)
}

class SupabaseDeliveryGateway implements DeliveryGateway {
  constructor(private readonly client: SupabaseClient) {}

  async loadAttemptContext(
    tenantId: string,
    deliveryId: string,
    retryCount: number,
  ): Promise<DeliveryAttemptContext | null> {
    const { data, error } = await this.client.schema('einvoice').rpc(
      'load_delivery_attempt_context',
      {
        p_tenant_id: tenantId,
        p_delivery_id: deliveryId,
        p_retry_count: retryCount,
      },
    )
    if (error) {
      throw new Error(`load_delivery_attempt_context: ${error.message}`)
    }

    const rows = asList(data)
    if (rows.length === 0) {
      return null
    }

    const row = rows[0]
    return {
      tenantId: requiredString(row, 'tenant_id'),
      deliveryId: requiredString(row, 'delivery_id'),
      retryCount: requiredInt(row, 'retry_count'),
      deliveryVersion: requiredInt(row, 'delivery_version'),
      providerConnectionId: requiredString(row, 'provider_connection_id'),
      providerTransactionId: requiredString(row, 'provider_transaction_id'),
      invoiceSeries: requiredString(row, 'invoice_series'),
      recipientEmail: requiredString(row, 'recipient_email'),
      recipientName: row.recipient_name !== null && row.recipient_name !== undefined
        ? String(row.recipient_name)
        : null,
    }
  }

  async prepareProviderCall(
    tenantId: string,
    deliveryId: string,
    retryCount: number,
    requestReference: string,
  ): Promise<PrepareResult> {
    const { data, error } = await this.client.schema('einvoice').rpc(
      'prepare_delivery_provider_call',
      {
        p_tenant_id: tenantId,
        p_delivery_id: deliveryId,
        p_retry_count: retryCount,
        p_request_reference: requestReference,
      },
    )
    if (error) {
      throw new Error(`prepare_delivery_provider_call: ${error.message}`)
    }

    const rows = asList(data)
    if (rows.length === 0) {
      throw new Error('prepare_delivery_provider_call returned no rows')
    }

    const row = rows[0]
    const action = requiredString(row, 'action')

    switch (action) {
      case 'CALL_PROVIDER':
        return {
          action: 'CALL_PROVIDER',
          deliveryVersion: requiredInt(row, 'delivery_version'),
          providerContext: {
            tenantId,
            providerConnectionId: requiredString(row, 'provider_connection_id'),
            providerTransactionId: requiredString(row, 'provider_transaction_id'),
            invoiceSeries: requiredString(row, 'invoice_series'),
            recipientEmail: requiredString(row, 'recipient_email'),
            recipientName: row.recipient_name !== null && row.recipient_name !== undefined
              ? String(row.recipient_name)
              : null,
          },
        }
      case 'SKIP':
        return { action: 'SKIP' }
      case 'RECORD_UNKNOWN':
        return {
          action: 'RECORD_UNKNOWN',
          deliveryVersion: requiredInt(row, 'delivery_version'),
        }
      default:
        throw new Error(`Unknown prepare delivery action: ${action}`)
    }
  }

  async recordResult(r: DeliveryResultRecord): Promise<void> {
    const { data, error } = await this.client.schema('einvoice').rpc(
      'record_delivery_result',
      {
        p_tenant_id: r.tenantId,
        p_delivery_id: r.deliveryId,
        p_retry_count: r.retryCount,
        p_expected_version: r.expectedDeliveryVersion,
        p_outcome_kind: r.evidence.kind,
        p_provider_reference: r.evidence.providerReference ?? null,
        p_safe_code: r.evidence.safeCode ?? null,
        p_failure_source: r.evidence.failureSource ?? null,
      },
    )
    if (error) {
      throw new Error(`record_delivery_result: ${error.message}`)
    }
    const rows = asList(data)
    if (rows.length === 0) {
      throw new Error('record_delivery_result returned no rows')
    }
  }

  async recordCommandDeadLetter(
    tenantId: string,
    deliveryId: string,
    retryCount: number,
    safeFailureCode: string,
  ): Promise<void> {
    const { error } = await this.client.schema('einvoice').rpc(
      'record_delivery_command_dead_letter',
      {
        p_tenant_id: tenantId,
        p_delivery_id: deliveryId,
        p_retry_count: retryCount,
        p_safe_failure_code: safeFailureCode,
      },
    )
    if (error) {
      throw new Error(`record_delivery_command_dead_letter: ${error.message}`)
    }
  }

  async loadReconciliationContext(
    tenantId: string,
    reconciliationCaseId: string,
    checkSequence: number,
  ): Promise<ReconciliationContext | null> {
    const { data, error } = await this.client.schema('einvoice').rpc(
      'load_delivery_reconciliation_context',
      {
        p_tenant_id: tenantId,
        p_reconciliation_case_id: reconciliationCaseId,
        p_check_sequence: checkSequence,
      },
    )
    if (error) {
      throw new Error(`load_delivery_reconciliation_context: ${error.message}`)
    }

    const rows = asList(data)
    if (rows.length === 0) {
      return null
    }

    const row = rows[0]
    return {
      tenantId: requiredString(row, 'tenant_id'),
      reconciliationCaseId: requiredString(row, 'reconciliation_case_id'),
      deliveryId: requiredString(row, 'delivery_id'),
      providerConnectionId: requiredString(row, 'provider_connection_id'),
      supportsDeliveryResultObservation: requiredBool(
        row,
        'supports_delivery_result_observation',
      ),
      checkSequence: requiredInt(row, 'check_sequence'),
      caseVersion: requiredInt(row, 'case_version'),
      providerDeliveryReference: row.provider_delivery_reference !== null &&
          row.provider_delivery_reference !== undefined
        ? String(row.provider_delivery_reference)
        : null,
    }
  }

  async recordReconciliationCheck(r: ReconciliationCheckRecord): Promise<void> {
    const { data, error } = await this.client.schema('einvoice').rpc(
      'record_delivery_reconciliation_check',
      {
        p_tenant_id: r.tenantId,
        p_reconciliation_case_id: r.reconciliationCaseId,
        p_expected_case_version: r.expectedCaseVersion,
        p_check_sequence: r.checkSequence,
        p_observation_kind: r.kind,
        p_provider_reference: r.providerReference ?? null,
        p_safe_code: r.safeCode ?? null,
      },
    )
    if (error) {
      throw new Error(`record_delivery_reconciliation_check: ${error.message}`)
    }
    const rows = asList(data)
    if (rows.length === 0) {
      throw new Error('record_delivery_reconciliation_check returned no rows')
    }
  }
}

export function createSupabaseDeliveryGateway(
  client: SupabaseClient,
): DeliveryGateway {
  return new SupabaseDeliveryGateway(client)
}
