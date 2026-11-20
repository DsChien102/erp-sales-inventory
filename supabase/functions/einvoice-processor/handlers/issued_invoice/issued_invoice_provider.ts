import {
  MeInvoiceDownloadDataType,
  MeInvoiceInvoiceQuery,
  MeInvoiceStatusInputType,
} from '../../misa/mod.ts'
import type { TenantMisaClientFactory } from '../misa_client_factory.ts'
import { classifyDocument } from './document_classifier.ts'
import { classifyObservation } from './observation_classifier.ts'
import { classifyOfficialView } from './official_view_classifier.ts'
import type {
  DocumentOutcome,
  DocumentType,
  ObservationOutcome,
  OfficialViewOutcome,
  ProviderContext,
} from './outcomes.ts'

export interface IssuedInvoiceProvider {
  fetchOfficialView(ctx: ProviderContext): Promise<OfficialViewOutcome>
  downloadDocument(
    ctx: ProviderContext,
    documentType: DocumentType,
  ): Promise<DocumentOutcome>
  observe(ctx: ProviderContext): Promise<ObservationOutcome>
}

function clipDetail(detail: string): string {
  return detail.length <= 400 ? detail : `${detail.substring(0, 400)}…`
}

export function createIssuedInvoiceProvider(deps: {
  clients: TenantMisaClientFactory
  now?: () => Date
  log?: (event: string, data: Record<string, unknown>) => void
}): IssuedInvoiceProvider {
  const now = deps.now ?? (() => new Date())

  function logFailure(
    operation: string,
    ctx: ProviderContext,
    query: MeInvoiceInvoiceQuery,
    detail: string,
  ) {
    deps.log?.('misa_resource_failed', {
      operation,
      invoiceSeries: ctx.invoiceSeries,
      invoiceWithCode: query.invoiceWithCode,
      invoiceCalcu: query.invoiceCalcu,
      providerReference: ctx.providerInvoiceReference,
      detail: clipDetail(detail),
    })
  }

  return {
    async fetchOfficialView(ctx: ProviderContext): Promise<OfficialViewOutcome> {
      const query = MeInvoiceInvoiceQuery.tryFromInvSeries(ctx.invoiceSeries)
      if (query === null) {
        return {
          kind: 'checkRequired',
          safeErrorCode: 'INVOICE_SERIES_INVALID',
          providerReference: null,
        }
      }

      const tenantClient = await deps.clients.getForTenant(ctx.tenantId)
      if (tenantClient === null) {
        return {
          kind: 'checkRequired',
          safeErrorCode: 'PROVIDER_AUTH_FAILED',
          providerReference: null,
        }
      }

      const companyTaxCode = tenantClient.taxCode?.trim()
      if (!companyTaxCode) {
        return {
          kind: 'checkRequired',
          safeErrorCode: 'PROVIDER_TAX_CODE_MISSING',
          providerReference: null,
        }
      }

      const result = await tenantClient.client.previewPublished({
        transactionIds: [ctx.providerInvoiceReference],
        companyTaxCode,
        query,
      })

      if (!result.isSuccess) {
        logFailure('publishview', ctx, query, result.error ?? 'unknown_error')
      }

      return classifyOfficialView({
        result,
        providerInvoiceReference: ctx.providerInvoiceReference,
        now: now(),
      })
    },

    async downloadDocument(
      ctx: ProviderContext,
      documentType: DocumentType,
    ): Promise<DocumentOutcome> {
      const query = MeInvoiceInvoiceQuery.tryFromInvSeries(ctx.invoiceSeries)
      if (query === null) {
        return {
          kind: 'checkRequired',
          safeErrorCode: 'INVOICE_SERIES_INVALID',
          providerReference: null,
        }
      }

      const tenantClient = await deps.clients.getForTenant(ctx.tenantId)
      if (tenantClient === null) {
        return {
          kind: 'checkRequired',
          safeErrorCode: 'PROVIDER_AUTH_FAILED',
          providerReference: null,
        }
      }

      const downloadDataType = documentType === 'PDF'
        ? MeInvoiceDownloadDataType.pdf
        : MeInvoiceDownloadDataType.xml

      const result = await tenantClient.client.download({
        transactionIds: [ctx.providerInvoiceReference],
        query,
        downloadDataType,
      })

      const opName = `download(${documentType.toLowerCase()})`
      if (!result.isSuccess) {
        logFailure(opName, ctx, query, result.error ?? 'unknown_error')
      } else {
        const first = result.data?.[0]
        if (!first || !first.bytes || first.bytes.length === 0) {
          const count = result.data?.length ?? 0
          const diag = first?.diagnostics ?? ''
          logFailure(
            opName,
            ctx,
            query,
            `items=${count} without document bytes item={${diag}}`,
          )
        }
      }

      return classifyDocument({
        result,
        documentType,
        providerInvoiceReference: ctx.providerInvoiceReference,
      })
    },

    async observe(ctx: ProviderContext): Promise<ObservationOutcome> {
      const query = MeInvoiceInvoiceQuery.tryFromInvSeries(ctx.invoiceSeries)
      if (query === null) {
        return {
          kind: 'ambiguous',
          safeErrorCode: 'INVOICE_SERIES_INVALID',
        }
      }

      const tenantClient = await deps.clients.getForTenant(ctx.tenantId)
      if (tenantClient === null) {
        return {
          kind: 'ambiguous',
          safeErrorCode: 'PROVIDER_AUTH_FAILED',
        }
      }

      const result = await tenantClient.client.getStatus({
        ids: [ctx.providerInvoiceReference],
        inputType: MeInvoiceStatusInputType.transactionId,
        query,
      })

      return classifyObservation({
        result,
        providerInvoiceReference: ctx.providerInvoiceReference,
        now: now(),
      })
    },
  }
}

