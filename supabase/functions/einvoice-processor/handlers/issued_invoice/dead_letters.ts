import type { DeadLetterHandler } from '../../queue/types.ts'
import type { IssuedInvoiceGateway } from './gateways.ts'
import type { DocumentType } from './outcomes.ts'

export function createIssuedInvoiceDeadLetters(
  gateway: IssuedInvoiceGateway,
): Record<string, DeadLetterHandler> {
  return {
    'einvoice.fetch_official_view': async ({ tenantId, command, error }) => {
      const payload = command.payload
      const electronicInvoiceId = String(
        payload.electronic_invoice_id ?? '',
      ).trim()
      const requestId = String(payload.request_id ?? '').trim()
      if (!electronicInvoiceId || !requestId) {
        return
      }

      const context = await gateway.loadOfficialViewContext(
        tenantId,
        electronicInvoiceId,
        requestId,
      )
      if (!context || context.status !== 'PENDING') {
        return
      }

      await gateway.recordOfficialViewResult({
        tenantId,
        electronicInvoiceId: context.electronicInvoiceId,
        requestId: context.requestId,
        status: 'CHECK_REQUIRED',
        failureCode: 'PROVIDER_RESULT_UNDETERMINED',
        failureMessage: String(error),
        failureSource: 'INTERNAL',
      })
    },

    'einvoice.download_invoice_document': async ({
      tenantId,
      command,
      error,
    }) => {
      const payload = command.payload
      const electronicInvoiceId = String(
        payload.electronic_invoice_id ?? '',
      ).trim()
      const requestId = String(payload.request_id ?? '').trim()
      const rawType = String(payload.document_type ?? '').trim().toUpperCase()
      if (
        !electronicInvoiceId ||
        !requestId ||
        (rawType !== 'PDF' && rawType !== 'XML')
      ) {
        return
      }
      const documentType = rawType as DocumentType

      const context = await gateway.loadDocumentContext(
        tenantId,
        electronicInvoiceId,
        documentType,
        requestId,
      )
      if (!context || context.status !== 'PENDING') {
        return
      }

      await gateway.recordDocumentResult({
        tenantId,
        electronicInvoiceId: context.electronicInvoiceId,
        documentType: context.documentType,
        requestId: context.requestId,
        status: 'CHECK_REQUIRED',
        failureCode: 'PROVIDER_RESULT_UNDETERMINED',
        failureMessage: String(error),
        failureSource: 'INTERNAL',
      })
    },
  }
}

