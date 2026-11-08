import type { CommandHandler, DeadLetterHandler } from '../queue/types.ts'
import { createIssuanceDeadLetters } from './issuance/dead_letters.ts'
import type { IssuanceGateways } from './issuance/gateways.ts'
import type { IssuanceProvider } from './issuance/issuance_provider.ts'
import { createPollIssuanceStatusHandler } from './issuance/poll_issuance_status.ts'
import { createPreviewInvoiceHandler } from './issuance/preview_invoice.ts'
import { createPublishInvoiceHandler } from './issuance/publish_invoice.ts'
import { createIssuedInvoiceDeadLetters } from './issued_invoice/dead_letters.ts'
import { createDownloadInvoiceDocumentHandler } from './issued_invoice/download_invoice_document.ts'
import { createFetchOfficialViewHandler } from './issued_invoice/fetch_official_view.ts'
import type { IssuedInvoiceDeps } from './issued_invoice/gateways.ts'
import { createPollProviderObservationHandler } from './issued_invoice/poll_provider_observation.ts'
import {
  createSyncCapabilitiesHandler,
  SYNC_CAPABILITIES,
  type SyncCapabilitiesDeps,
} from './sync_capabilities.ts'

export type HandlerDeps = SyncCapabilitiesDeps & {
  issuance: {
    provider: IssuanceProvider
    gateways: IssuanceGateways
  }
  issuedInvoice: IssuedInvoiceDeps
}

export function buildHandlers(
  deps: HandlerDeps,
): Record<string, CommandHandler> {
  return {
    [SYNC_CAPABILITIES]: createSyncCapabilitiesHandler(deps),
    'einvoice.preview_invoice': createPreviewInvoiceHandler(deps.issuance),
    'einvoice.publish_invoice': createPublishInvoiceHandler(deps.issuance),
    'einvoice.poll_issuance_status': createPollIssuanceStatusHandler(
      deps.issuance,
    ),
    'einvoice.fetch_official_view': createFetchOfficialViewHandler(
      deps.issuedInvoice,
    ),
    'einvoice.download_invoice_document': createDownloadInvoiceDocumentHandler(
      deps.issuedInvoice,
    ),
    'einvoice.poll_provider_observation': createPollProviderObservationHandler(
      deps.issuedInvoice,
    ),
  }
}

export function buildDeadLetters(
  deps: HandlerDeps,
): Record<string, DeadLetterHandler> {
  return {
    ...createIssuanceDeadLetters(deps.issuance.gateways),
    ...createIssuedInvoiceDeadLetters(deps.issuedInvoice.gateway),
  }
}
