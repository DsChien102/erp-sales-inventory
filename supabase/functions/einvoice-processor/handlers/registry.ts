import type { CommandHandler, DeadLetterHandler } from '../queue/types.ts'
import { createSyncCapabilitiesHandler, SYNC_CAPABILITIES, type SyncCapabilitiesDeps } from './sync_capabilities.ts'

/** 7-E2 adds the 8 remaining handlers here. */
export function buildHandlers(deps: SyncCapabilitiesDeps): Record<string, CommandHandler> {
  return { [SYNC_CAPABILITIES]: createSyncCapabilitiesHandler(deps) }
}

/** 7-E2 adds the 5 dead-letter handlers here. */
export const DEAD_LETTER_HANDLERS: Readonly<Record<string, DeadLetterHandler>> = {}
