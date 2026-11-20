import type { SupabaseClient } from 'npm:@supabase/supabase-js@2'
import type {
  DocumentContext,
  IssuedInvoiceGateway,
  ObservationContext,
  OfficialViewContext,
} from './gateways.ts'
import type {
  DocumentStatus,
  DocumentType,
  FailureSource,
} from './outcomes.ts'

function asList(data: unknown): Array<Record<string, unknown>> {
  if (Array.isArray(data)) return data as Array<Record<string, unknown>>
  if (typeof data === 'object' && data !== null) return [data as Record<string, unknown>]
  return []
}

function mapDocumentStatus(raw: string): DocumentStatus {
  switch (raw.toUpperCase()) {
    case 'PENDING':
      return 'PENDING'
    case 'AVAILABLE':
      return 'AVAILABLE'
    case 'FAILED':
      return 'FAILED'
    case 'CHECK_REQUIRED':
      return 'CHECK_REQUIRED'
    default:
      throw new Error(`Unknown invoice document status: ${raw}`)
  }
}

function mapDocumentType(raw: string): DocumentType {
  switch (raw.toUpperCase()) {
    case 'PDF':
      return 'PDF'
    case 'XML':
      return 'XML'
    default:
      throw new Error(`Unknown invoice document type: ${raw}`)
  }
}

class SupabaseIssuedInvoiceGateway implements IssuedInvoiceGateway {
  constructor(private readonly client: SupabaseClient) {}

  async loadOfficialViewContext(
    tenantId: string,
    electronicInvoiceId: string,
    requestId: string,
  ): Promise<OfficialViewContext | null> {
    const { data, error } = await this.client.schema('einvoice').rpc(
      'load_official_view_operation_context',
      {
        p_tenant_id: tenantId,
        p_electronic_invoice_id: electronicInvoiceId,
        p_request_id: requestId,
      },
    )
    if (error) {
      throw new Error(`load_official_view_operation_context: ${error.message}`)
    }
    const rows = asList(data)
    if (rows.length === 0) return null
    const row = rows[0]
    return {
      tenantId: String(row.tenant_id),
      electronicInvoiceId: String(row.electronic_invoice_id),
      requestId: String(row.request_id),
      status: mapDocumentStatus(String(row.status)),
      providerConnectionId: String(row.provider_connection_id),
      providerInvoiceReference: String(row.provider_invoice_reference),
      invoiceSeries: String(row.invoice_series),
    }
  }

  async loadDocumentContext(
    tenantId: string,
    electronicInvoiceId: string,
    documentType: DocumentType,
    requestId: string,
  ): Promise<DocumentContext | null> {
    const { data, error } = await this.client.schema('einvoice').rpc(
      'load_invoice_document_operation_context',
      {
        p_tenant_id: tenantId,
        p_electronic_invoice_id: electronicInvoiceId,
        p_document_type: documentType,
        p_request_id: requestId,
      },
    )
    if (error) {
      throw new Error(`load_invoice_document_operation_context: ${error.message}`)
    }
    const rows = asList(data)
    if (rows.length === 0) return null
    const row = rows[0]
    return {
      tenantId: String(row.tenant_id),
      electronicInvoiceId: String(row.electronic_invoice_id),
      documentType: mapDocumentType(String(row.document_type)),
      requestId: String(row.request_id),
      status: mapDocumentStatus(String(row.status)),
      providerConnectionId: String(row.provider_connection_id),
      providerInvoiceReference: String(row.provider_invoice_reference),
      invoiceSeries: String(row.invoice_series),
    }
  }

  async loadObservationContext(
    tenantId: string,
    commandId: string,
  ): Promise<ObservationContext | null> {
    const { data, error } = await this.client.schema('einvoice').rpc(
      'load_provider_observation_context',
      {
        p_tenant_id: tenantId,
        p_command_id: commandId,
      },
    )
    if (error) {
      throw new Error(`load_provider_observation_context: ${error.message}`)
    }
    const rows = asList(data)
    if (rows.length === 0) return null
    const row = rows[0]
    return {
      commandId: String(row.command_id),
      tenantId: String(row.tenant_id),
      electronicInvoiceId: String(row.electronic_invoice_id),
      providerConnectionId: String(row.provider_connection_id),
      providerInvoiceReference: String(row.provider_invoice_reference),
      invoiceSeries: String(row.invoice_series),
      triggerId: String(row.trigger_id),
      correlationId: String(row.correlation_id),
    }
  }

  async recordOfficialViewResult(r: {
    tenantId: string
    electronicInvoiceId: string
    requestId: string
    status: DocumentStatus
    viewerUrl?: string
    viewerToken?: string
    expiresAt?: Date
    failureCode?: string
    failureMessage?: string | null
    failureSource?: FailureSource
  }): Promise<void> {
    const params: Record<string, unknown> = {
      p_tenant_id: r.tenantId,
      p_electronic_invoice_id: r.electronicInvoiceId,
      p_request_id: r.requestId,
      p_status: r.status,
      p_failure_source: r.failureSource ?? null,
    }
    if (r.viewerUrl !== undefined && r.viewerUrl !== null) {
      params.p_viewer_url = r.viewerUrl
    }
    if (r.viewerToken !== undefined && r.viewerToken !== null) {
      params.p_viewer_token = r.viewerToken
    }
    if (r.expiresAt !== undefined && r.expiresAt !== null) {
      params.p_expires_at = r.expiresAt.toISOString()
    }
    if (r.failureCode !== undefined && r.failureCode !== null) {
      params.p_failure_code = r.failureCode
    }
    if (r.failureMessage !== undefined && r.failureMessage !== null) {
      params.p_failure_message = r.failureMessage
    }

    const { error } = await this.client.schema('einvoice').rpc(
      'record_official_invoice_view_result',
      params,
    )
    if (error) {
      throw new Error(`record_official_invoice_view_result: ${error.message}`)
    }
  }

  async recordDocumentResult(r: {
    tenantId: string
    electronicInvoiceId: string
    documentType: DocumentType
    requestId: string
    status: DocumentStatus
    storageReference?: string
    checksum?: string
    failureCode?: string
    failureMessage?: string | null
    failureSource?: FailureSource
  }): Promise<void> {
    const params: Record<string, unknown> = {
      p_tenant_id: r.tenantId,
      p_electronic_invoice_id: r.electronicInvoiceId,
      p_document_type: r.documentType,
      p_request_id: r.requestId,
      p_status: r.status,
      p_failure_source: r.failureSource ?? null,
    }
    if (r.storageReference !== undefined && r.storageReference !== null) {
      params.p_storage_reference = r.storageReference
    }
    if (r.checksum !== undefined && r.checksum !== null) {
      params.p_checksum = r.checksum
    }
    if (r.failureCode !== undefined && r.failureCode !== null) {
      params.p_failure_code = r.failureCode
    }
    if (r.failureMessage !== undefined && r.failureMessage !== null) {
      params.p_failure_message = r.failureMessage
    }

    const { error } = await this.client.schema('einvoice').rpc(
      'record_invoice_document_result',
      params,
    )
    if (error) {
      throw new Error(`record_invoice_document_result: ${error.message}`)
    }
  }

  async recordProviderObservation(r: {
    tenantId: string
    electronicInvoiceId: string
    providerStateCode: string
    safeDescription?: string | null
    providerReference?: string | null
    observedAt: Date
    deduplicationKey: string
    detailsSnapshot: Record<string, unknown>
    correlationId: string
  }): Promise<void> {
    const { error } = await this.client.schema('einvoice').rpc(
      'record_provider_observation',
      {
        p_tenant_id: r.tenantId,
        p_electronic_invoice_id: r.electronicInvoiceId,
        p_provider_state_code: r.providerStateCode,
        p_provider_state_description: r.safeDescription ?? null,
        p_provider_reference: r.providerReference ?? null,
        p_observed_at: r.observedAt.toISOString(),
        p_deduplication_key: r.deduplicationKey,
        p_details_snapshot: r.detailsSnapshot,
        p_correlation_id: r.correlationId,
      },
    )
    if (error) {
      throw new Error(`record_provider_observation: ${error.message}`)
    }
  }
}

export function createSupabaseIssuedInvoiceGateway(
  client: SupabaseClient,
): IssuedInvoiceGateway {
  return new SupabaseIssuedInvoiceGateway(client)
}

