import type { CommandContext, CommandHandler } from '../../queue/types.ts'
import { ProviderCallAmbiguousError } from './errors.ts'
import type { IssuedInvoiceDeps } from './gateways.ts'
import type { DocumentOutcome, DocumentType } from './outcomes.ts'

export function createDownloadInvoiceDocumentHandler(
  deps: IssuedInvoiceDeps,
): CommandHandler {
  return async (ctx: CommandContext): Promise<void> => {
    const payload = ctx.command.payload
    const tenantId = typeof payload.tenant_id === 'string' && payload.tenant_id.trim() !== ''
      ? payload.tenant_id
      : ctx.tenantId
    const electronicInvoiceId = String(payload.electronic_invoice_id ?? '').trim()
    const requestId = String(payload.request_id ?? '').trim()

    if (!electronicInvoiceId) {
      throw new Error(
        'download_invoice_document payload missing electronic_invoice_id',
      )
    }
    if (!requestId) {
      throw new Error('download_invoice_document payload missing request_id')
    }

    const rawType = String(payload.document_type ?? '').trim().toUpperCase()
    if (rawType !== 'PDF' && rawType !== 'XML') {
      throw new Error(`Unknown document type: ${payload.document_type}`)
    }
    const documentType = rawType as DocumentType

    const context = await deps.gateway.loadDocumentContext(
      tenantId,
      electronicInvoiceId,
      documentType,
      requestId,
    )
    if (!context || context.status !== 'PENDING') {
      return
    }

    let outcome: DocumentOutcome
    try {
      outcome = await deps.provider.downloadDocument(
        {
          tenantId: context.tenantId,
          providerConnectionId: context.providerConnectionId,
          electronicInvoiceId: context.electronicInvoiceId,
          providerInvoiceReference: context.providerInvoiceReference,
          invoiceSeries: context.invoiceSeries,
          operationId: context.requestId,
          documentType: context.documentType,
        },
        context.documentType,
      )
    } catch (error) {
      if (error instanceof ProviderCallAmbiguousError) {
        throw new Error(error.safeErrorCode)
      }
      throw error
    }

    switch (outcome.kind) {
      case 'success': {
        const stored = await deps.storage.store({
          tenantId,
          electronicInvoiceId: context.electronicInvoiceId,
          documentType: context.documentType,
          documentVersion: 1,
          bytes: outcome.bytes,
        })
        await deps.gateway.recordDocumentResult({
          tenantId,
          electronicInvoiceId: context.electronicInvoiceId,
          documentType: context.documentType,
          requestId: context.requestId,
          status: 'AVAILABLE',
          storageReference: stored.storageReference,
          checksum: stored.checksum,
        })
        break
      }
      case 'checkRequired':
        await deps.gateway.recordDocumentResult({
          tenantId,
          electronicInvoiceId: context.electronicInvoiceId,
          documentType: context.documentType,
          requestId: context.requestId,
          status: 'CHECK_REQUIRED',
          failureCode: outcome.safeErrorCode,
          failureSource: 'PROVIDER',
        })
        break
      case 'definiteFailure':
        await deps.gateway.recordDocumentResult({
          tenantId,
          electronicInvoiceId: context.electronicInvoiceId,
          documentType: context.documentType,
          requestId: context.requestId,
          status: 'FAILED',
          failureCode: outcome.failureCode,
          failureMessage: outcome.failureMessage,
          failureSource: 'PROVIDER',
        })
        break
      case 'ambiguous':
        throw new Error(outcome.safeErrorCode)
    }
  }
}

