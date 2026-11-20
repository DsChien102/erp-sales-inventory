import type { IssuedInvoiceProvider } from './issued_invoice_provider.ts'
import type {
  DocumentContext,
  IssuedInvoiceGateway,
  ObservationContext,
  OfficialViewContext,
} from './gateways.ts'
import type {
  DocumentOutcome,
  DocumentType,
  ObservationOutcome,
  OfficialViewOutcome,
  ProviderContext,
} from './outcomes.ts'

export class FakeIssuedInvoiceGateway implements IssuedInvoiceGateway {
  officialViewContext: OfficialViewContext | null = null
  documentContext: DocumentContext | null = null
  observationContext: ObservationContext | null = null

  officialViewResults: Array<
    Parameters<IssuedInvoiceGateway['recordOfficialViewResult']>[0]
  > = []
  documentResults: Array<
    Parameters<IssuedInvoiceGateway['recordDocumentResult']>[0]
  > = []
  observationRecords: Array<
    Parameters<IssuedInvoiceGateway['recordProviderObservation']>[0]
  > = []

  loadOfficialViewCalls: Array<
    { tenantId: string; electronicInvoiceId: string; requestId: string }
  > = []
  loadDocumentCalls: Array<
    {
      tenantId: string
      electronicInvoiceId: string
      documentType: DocumentType
      requestId: string
    }
  > = []
  loadObservationCalls: Array<{ tenantId: string; commandId: string }> = []

  loadOfficialViewContext(
    tenantId: string,
    electronicInvoiceId: string,
    requestId: string,
  ): Promise<OfficialViewContext | null> {
    this.loadOfficialViewCalls.push({ tenantId, electronicInvoiceId, requestId })
    return Promise.resolve(this.officialViewContext)
  }

  loadDocumentContext(
    tenantId: string,
    electronicInvoiceId: string,
    documentType: DocumentType,
    requestId: string,
  ): Promise<DocumentContext | null> {
    this.loadDocumentCalls.push({
      tenantId,
      electronicInvoiceId,
      documentType,
      requestId,
    })
    return Promise.resolve(this.documentContext)
  }

  loadObservationContext(
    tenantId: string,
    commandId: string,
  ): Promise<ObservationContext | null> {
    this.loadObservationCalls.push({ tenantId, commandId })
    return Promise.resolve(this.observationContext)
  }

  recordOfficialViewResult(
    r: Parameters<IssuedInvoiceGateway['recordOfficialViewResult']>[0],
  ): Promise<void> {
    this.officialViewResults.push(r)
    return Promise.resolve()
  }

  recordDocumentResult(
    r: Parameters<IssuedInvoiceGateway['recordDocumentResult']>[0],
  ): Promise<void> {
    this.documentResults.push(r)
    return Promise.resolve()
  }

  recordProviderObservation(
    r: Parameters<IssuedInvoiceGateway['recordProviderObservation']>[0],
  ): Promise<void> {
    this.observationRecords.push(r)
    return Promise.resolve()
  }
}

export class FakeIssuedInvoiceProvider implements IssuedInvoiceProvider {
  officialOutcome?: OfficialViewOutcome
  officialError?: Error
  documentOutcome?: DocumentOutcome
  documentError?: Error
  observationOutcome?: ObservationOutcome
  observationError?: Error

  fetchOfficialViewCalls = 0
  downloadDocumentCalls = 0
  observeCalls = 0

  fetchOfficialView(_ctx: ProviderContext): Promise<OfficialViewOutcome> {
    this.fetchOfficialViewCalls++
    if (this.officialError) return Promise.reject(this.officialError)
    if (this.officialOutcome) return Promise.resolve(this.officialOutcome)
    return Promise.resolve({
      kind: 'success',
      viewerUrl: 'https://viewer.example/invoice',
      expiresAt: new Date(Date.now() + 300000),
      providerReference: 'tx-1',
    })
  }

  downloadDocument(
    _ctx: ProviderContext,
    _documentType: DocumentType,
  ): Promise<DocumentOutcome> {
    this.downloadDocumentCalls++
    if (this.documentError) return Promise.reject(this.documentError)
    if (this.documentOutcome) return Promise.resolve(this.documentOutcome)
    return Promise.resolve({
      kind: 'success',
      bytes: new TextEncoder().encode('%PDF-1.4 test'),
      providerReference: 'tx-1',
    })
  }

  observe(_ctx: ProviderContext): Promise<ObservationOutcome> {
    this.observeCalls++
    if (this.observationError) return Promise.reject(this.observationError)
    if (this.observationOutcome) return Promise.resolve(this.observationOutcome)
    return Promise.resolve({
      kind: 'found',
      providerStateCode: 'PS_1_ES_1',
      safeDescription: 'PUBLISHED',
      observedAt: new Date(),
      detailsSnapshot: {},
      providerReference: 'tx-1',
    })
  }
}

