import type { CommandHandler, DeadLetterHandler } from '../queue/types.ts'
import { createIssuanceDeadLetters } from './issuance/dead_letters.ts'
import type { IssuanceGateways } from './issuance/gateways.ts'
import type { IssuanceProvider } from './issuance/issuance_provider.ts'
import { createPollIssuanceStatusHandler } from './issuance/poll_issuance_status.ts'
import { createPreviewInvoiceHandler } from './issuance/preview_invoice.ts'
import { createPublishInvoiceHandler } from './issuance/publish_invoice.ts'
import { createSyncCapabilitiesHandler, SYNC_CAPABILITIES, type SyncCapabilitiesDeps } from './sync_capabilities.ts'

export type HandlerDeps = SyncCapabilitiesDeps & {
  issuance: {
    provider: IssuanceProvider
    gateways: IssuanceGateways
  }
}

export function buildHandlers(deps: HandlerDeps): Record<string, CommandHandler> {
  return {
    [SYNC_CAPABILITIES]: createSyncCapabilitiesHandler(deps),
    'einvoice.preview_invoice': createPreviewInvoiceHandler(deps.issuance),
    'einvoice.publish_invoice': createPublishInvoiceHandler(deps.issuance),
    'einvoice.poll_issuance_status': createPollIssuanceStatusHandler(deps.issuance),
  }
}

export function buildDeadLetters(deps: HandlerDeps): Record<string, DeadLetterHandler> {
  return createIssuanceDeadLetters(deps.issuance.gateways)
}
