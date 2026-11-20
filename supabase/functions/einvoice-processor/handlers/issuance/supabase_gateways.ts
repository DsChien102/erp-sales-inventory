import type { SupabaseClient } from 'npm:@supabase/supabase-js@2'
import type {
  IssuanceGateways,
  IssuanceResultGateway,
  LeaseAcquireOutcome,
  PreviewResultStore,
  PublishPreparationAction,
  PublishSeriesLeaseGateway,
  ReconciliationGateway,
  ReconciliationPollContext,
} from './gateways.ts'
import type { IssuanceResultEvidence } from './outcomes.ts'

const DEFAULT_LEASE_SECONDS = 300

function asList(data: unknown): Array<Record<string, unknown>> {
  if (Array.isArray(data)) return data as Array<Record<string, unknown>>
  if (typeof data === 'object' && data !== null) return [data as Record<string, unknown>]
  return []
}

class SupabasePreviewResultStore implements PreviewResultStore {
  constructor(private readonly client: SupabaseClient) {}

  async store(input: {
    tenantId: string
    salesOrderId: string
    requestId: string
    status: 'READY' | 'FAILED'
    viewerRef?: string
    failureCode?: string
    failureMessage?: string | null
    failureSource?: 'PROVIDER' | 'INTERNAL'
  }): Promise<void> {
    const { error } = await this.client.schema('einvoice').rpc('store_preview_result', {
      p_tenant_id: input.tenantId,
      p_sales_order_id: input.salesOrderId,
      p_request_id: input.requestId,
      p_status: input.status,
      p_viewer_ref: input.viewerRef ?? null,
      p_failure_code: input.failureCode ?? null,
      p_failure_message: input.failureMessage ?? null,
      p_failure_source: input.failureSource ?? null,
    })
    if (error) {
      throw new Error(`store_preview_result: ${error.message}`)
    }
  }
}

class SupabasePublishSeriesLeaseGateway implements PublishSeriesLeaseGateway {
  constructor(private readonly client: SupabaseClient) {}

  async tryAcquire(tenantId: string, attemptId: string, ownerToken: string): Promise<LeaseAcquireOutcome> {
    const { data, error } = await this.client.schema('einvoice').rpc('acquire_publish_series_lease', {
      p_tenant_id: tenantId,
      p_attempt_id: attemptId,
      p_owner_token: ownerToken,
      p_lease_seconds: DEFAULT_LEASE_SECONDS,
    })
    if (error) {
      throw new Error(`acquire_publish_series_lease: ${error.message}`)
    }
    const rows = asList(data)
    if (rows.length === 0) {
      throw new Error('acquire_publish_series_lease returned no rows')
    }
    const row = rows[0]
    const acquired = row['acquired'] === true
    if (!acquired) {
      const rawRetry = row['retry_after_seconds']
      const retryAfterSeconds = typeof rawRetry === 'number' ? rawRetry : Number(rawRetry)
      if (Number.isNaN(retryAfterSeconds) || retryAfterSeconds == null) {
        throw new Error('acquire_publish_series_lease missing retry_after_seconds')
      }
      return { kind: 'busy', retryAfterSeconds }
    }

    const providerConnectionId = row['provider_connection_id']?.toString()
    const invoiceSeries = row['invoice_series']?.toString()
    const rawVersion = row['lease_version']
    const leaseVersion = typeof rawVersion === 'number' ? rawVersion : Number(rawVersion)
    const leasedUntil = row['leased_until']

    if (!providerConnectionId || !invoiceSeries || Number.isNaN(leaseVersion) || !leasedUntil) {
      throw new Error('acquire_publish_series_lease missing fenced lease metadata')
    }

    return {
      kind: 'acquired',
      providerConnectionId,
      invoiceSeries,
      leaseVersion,
    }
  }

  async release(i: {
    tenantId: string
    providerConnectionId: string
    invoiceSeries: string
    ownerToken: string
    leaseVersion: number
  }): Promise<void> {
    const { error } = await this.client.schema('einvoice').rpc('release_publish_series_lease', {
      p_tenant_id: i.tenantId,
      p_provider_connection_id: i.providerConnectionId,
      p_invoice_series: i.invoiceSeries,
      p_owner_token: i.ownerToken,
      p_lease_version: i.leaseVersion,
    })
    if (error) {
      throw new Error(`release_publish_series_lease: ${error.message}`)
    }
  }
}

class SupabaseIssuanceResultGateway implements IssuanceResultGateway {
  constructor(private readonly client: SupabaseClient) {}

  async preparePublish(i: {
    tenantId: string
    attemptId: string
    idempotencyKey: string
    payloadHash: string
    canonicalInvoice: Record<string, unknown>
  }): Promise<PublishPreparationAction> {
    const { data, error } = await this.client.schema('einvoice').rpc('prepare_issuance_publish', {
      p_tenant_id: i.tenantId,
      p_attempt_id: i.attemptId,
      p_idempotency_key: i.idempotencyKey,
      p_payload_hash: i.payloadHash,
      p_canonical_payload: i.canonicalInvoice,
    })
    if (error) {
      throw new Error(`prepare_issuance_publish: ${error.message}`)
    }
    const rows = asList(data)
    if (rows.length === 0) {
      throw new Error('prepare_issuance_publish returned no rows')
    }
    const action = rows[0]['action']
    if (typeof action !== 'string' || action.length === 0) {
      throw new Error('prepare_issuance_publish returned missing action')
    }
    return action as PublishPreparationAction
  }

  async markProviderCallStarted(tenantId: string, attemptId: string): Promise<void> {
    const { error } = await this.client.schema('einvoice').rpc('mark_issuance_provider_call_started', {
      p_tenant_id: tenantId,
      p_attempt_id: attemptId,
    })
    if (error) {
      throw new Error(`mark_issuance_provider_call_started: ${error.message}`)
    }
  }

  async recordSuccess(
    tenantId: string,
    attemptId: string,
    e: Extract<IssuanceResultEvidence, { kind: 'success' }>,
  ): Promise<void> {
    const { data, error } = await this.client.schema('einvoice').rpc('record_issuance_success', {
      p_tenant_id: tenantId,
      p_attempt_id: attemptId,
      p_idempotency_key: e.idempotencyKey,
      p_payload_hash: e.payloadHash,
      p_provider_reference: e.providerReference,
      p_invoice_number: e.invoiceNumber,
      p_invoice_series: e.invoiceSeries,
      p_issued_at: e.issuedAt.toISOString(),
    })
    if (error) {
      throw new Error(`record_issuance_success: ${error.message}`)
    }
    const rows = asList(data)
    if (rows.length === 0) {
      throw new Error('record_issuance_success returned no rows')
    }
  }

  async recordDefiniteFailure(
    tenantId: string,
    attemptId: string,
    e: Extract<IssuanceResultEvidence, { kind: 'definiteFailure' }>,
  ): Promise<void> {
    const { data, error } = await this.client.schema('einvoice').rpc('record_issuance_failure', {
      p_tenant_id: tenantId,
      p_attempt_id: attemptId,
      p_idempotency_key: e.idempotencyKey,
      p_payload_hash: e.payloadHash,
      p_provider_code: e.providerCode,
      p_provider_message: e.providerMessage,
    })
    if (error) {
      throw new Error(`record_issuance_failure: ${error.message}`)
    }
    const rows = asList(data)
    if (rows.length === 0) {
      throw new Error('record_issuance_failure returned no rows')
    }
  }

  async recordUndetermined(
    tenantId: string,
    attemptId: string,
    e: Extract<IssuanceResultEvidence, { kind: 'undetermined' }>,
  ): Promise<void> {
    const { data, error } = await this.client.schema('einvoice').rpc('record_issuance_undetermined', {
      p_tenant_id: tenantId,
      p_attempt_id: attemptId,
      p_idempotency_key: e.idempotencyKey,
      p_payload_hash: e.payloadHash,
      p_reason_code: e.reasonCode,
    })
    if (error) {
      throw new Error(`record_issuance_undetermined: ${error.message}`)
    }
    const rows = asList(data)
    if (rows.length === 0) {
      throw new Error('record_issuance_undetermined returned no rows')
    }
  }

  async recordRetryableProviderRejection(i: {
    tenantId: string
    attemptId: string
    sourceCommandId: string
    evidence: Extract<IssuanceResultEvidence, { kind: 'retryableProviderRejection' }>
    retryAfterSeconds: number
  }): Promise<void> {
    const { data, error } = await this.client.schema('einvoice').rpc(
      'record_retryable_provider_publish_rejection',
      {
        p_tenant_id: i.tenantId,
        p_attempt_id: i.attemptId,
        p_source_command_id: i.sourceCommandId,
        p_idempotency_key: i.evidence.idempotencyKey,
        p_payload_hash: i.evidence.payloadHash,
        p_provider_code: i.evidence.providerCode,
        p_provider_message: i.evidence.providerMessage,
        p_retry_after_seconds: i.retryAfterSeconds,
      },
    )
    if (error) {
      throw new Error(`record_retryable_provider_publish_rejection: ${error.message}`)
    }
    const rows = asList(data)
    if (rows.length === 0) {
      throw new Error('record_retryable_provider_publish_rejection returned no rows')
    }
  }

  async recordCommandIntegrityFailure(tenantId: string, attemptId: string, reasonCode: string): Promise<void> {
    const { data, error } = await this.client.schema('einvoice').rpc(
      'record_issuance_command_integrity_failure',
      {
        p_tenant_id: tenantId,
        p_attempt_id: attemptId,
        p_reason_code: reasonCode,
      },
    )
    if (error) {
      throw new Error(`record_issuance_command_integrity_failure: ${error.message}`)
    }
    const rows = asList(data)
    if (rows.length === 0) {
      throw new Error('record_issuance_command_integrity_failure returned no rows')
    }
  }

  async recordPublishCommandDeadLetter(tenantId: string, attemptId: string, reasonCode: string): Promise<void> {
    const { data, error } = await this.client.schema('einvoice').rpc('record_publish_command_dead_letter', {
      p_tenant_id: tenantId,
      p_attempt_id: attemptId,
      p_reason_code: reasonCode,
    })
    if (error) {
      throw new Error(`record_publish_command_dead_letter: ${error.message}`)
    }
    const rows = asList(data)
    if (rows.length === 0) {
      throw new Error('record_publish_command_dead_letter returned no rows')
    }
  }
}

class SupabaseReconciliationGateway implements ReconciliationGateway {
  constructor(private readonly client: SupabaseClient) {}

  async claim(tenantId: string, caseId: string, workerId: string): Promise<ReconciliationPollContext | null> {
    const { data, error } = await this.client.schema('einvoice').rpc('claim_issuance_reconciliation_case', {
      p_tenant_id: tenantId,
      p_case_id: caseId,
      p_worker_id: workerId,
    })
    if (error) {
      throw new Error(`claim_issuance_reconciliation_case: ${error.message}`)
    }
    const rows = asList(data)
    if (rows.length === 0) {
      return null
    }
    const row = rows[0]
    return {
      caseId: String(row['case_id']),
      attemptId: String(row['attempt_id']),
      claimToken: String(row['claim_token']),
      idempotencyKey: String(row['idempotency_key']),
      payloadHash: String(row['payload_hash']),
      invoiceSeries: String(row['invoice_series']),
      providerReference: row['provider_reference'] != null ? String(row['provider_reference']) : null,
      reconciliationReasonCode: row['reconciliation_reason_code'] != null
        ? String(row['reconciliation_reason_code'])
        : null,
      checkSequence: typeof row['check_sequence'] === 'number'
        ? row['check_sequence']
        : Number(row['check_sequence']),
      maxChecks: typeof row['max_checks'] === 'number' ? row['max_checks'] : 5,
    }
  }

  async recordPendingCheck(i: {
    tenantId: string
    caseId: string
    claimToken: string
    nextDelaySeconds: number
    checkSequence: number
  }): Promise<void> {
    const { error } = await this.client.schema('einvoice').rpc('record_reconciliation_pending', {
      p_tenant_id: i.tenantId,
      p_case_id: i.caseId,
      p_claim_token: i.claimToken,
      p_next_delay_seconds: i.nextDelaySeconds,
      p_check_sequence: i.checkSequence,
    })
    if (error) {
      throw new Error(`record_reconciliation_pending: ${error.message}`)
    }
  }

  async resolve(i: {
    tenantId: string
    caseId: string
    outcome: 'SUCCESS' | 'FAILURE' | 'PUBLISH_RETRY_SCHEDULED' | 'UNRESOLVED'
    evidence?: Record<string, unknown>
  }): Promise<void> {
    const { data, error } = await this.client.schema('einvoice').rpc('resolve_reconciliation_case', {
      p_tenant_id: i.tenantId,
      p_case_id: i.caseId,
      p_outcome: i.outcome,
      ...(i.evidence ? { p_evidence: i.evidence } : {}),
    })
    if (error) {
      throw new Error(`resolve_reconciliation_case: ${error.message}`)
    }
    const rows = asList(data)
    if (rows.length === 0) {
      throw new Error('resolve_reconciliation_case returned no rows')
    }
  }
}

export function createSupabaseIssuanceGateways(client: SupabaseClient): IssuanceGateways {
  return {
    preview: new SupabasePreviewResultStore(client),
    lease: new SupabasePublishSeriesLeaseGateway(client),
    results: new SupabaseIssuanceResultGateway(client),
    reconciliation: new SupabaseReconciliationGateway(client),
  }
}

