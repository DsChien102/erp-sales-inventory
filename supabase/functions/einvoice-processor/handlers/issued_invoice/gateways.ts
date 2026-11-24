import type { createDocumentStorage } from './document_storage.ts'
import type { IssuedInvoiceProvider } from './issued_invoice_provider.ts'
import type {
  DocumentStatus,
  DocumentType,
  FailureSource,
} from './outcomes.ts'

export interface OfficialViewContext {
  tenantId: string
  electronicInvoiceId: string
  requestId: string
  status: DocumentStatus
  providerConnectionId: string
  providerInvoiceReference: string
  invoiceSeries: string
}

export interface DocumentContext extends OfficialViewContext {
  documentType: DocumentType
}

export interface ObservationContext {
  commandId: string
  tenantId: string
  electronicInvoiceId: string
  providerConnectionId: string
  providerInvoiceReference: string
  invoiceSeries: string
  triggerId: string
  correlationId: string
}

export interface IssuedInvoiceGateway {
  loadOfficialViewContext(
    tenantId: string,
    electronicInvoiceId: string,
    requestId: string,
  ): Promise<OfficialViewContext | null>

  loadDocumentContext(
    tenantId: string,
    electronicInvoiceId: string,
    documentType: DocumentType,
    requestId: string,
  ): Promise<DocumentContext | null>

  loadObservationContext(
    tenantId: string,
    commandId: string,
  ): Promise<ObservationContext | null>

  recordOfficialViewResult(r: {
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
  }): Promise<void>

  recordDocumentResult(r: {
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
  }): Promise<void>

  recordProviderObservation(r: {
    tenantId: string
    electronicInvoiceId: string
    providerStateCode: string
    safeDescription?: string | null
    providerReference?: string | null
    observedAt: Date
    deduplicationKey: string
    detailsSnapshot: Record<string, unknown>
    correlationId: string
  }): Promise<void>
}

export interface IssuedInvoiceDeps {
  provider: IssuedInvoiceProvider
  gateway: IssuedInvoiceGateway
  storage: ReturnType<typeof createDocumentStorage>
}

