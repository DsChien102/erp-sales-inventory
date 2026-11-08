import { maxAttemptsFor } from './attempt_policy.ts'
import { PublishSeriesLeaseBusyError } from './errors.ts'
import type {
  ClaimedCommand,
  CommandHandler,
  DeadLetterHandler,
  QueueRpc,
  RunSummary,
} from './types.ts'

// Edge Function (free plan) is cut at 150s; one MISA call waits at most 60s.
export const MAX_TENANTS = 20
export const CLAIM_BATCH = 5
export const SEED_LIMIT = 5
export const MAX_COMMANDS = 20
export const TIME_BUDGET_MS = 90_000
export const UNKNOWN_TYPE_DELAY_SECONDS = 300

export interface ProcessorDeps {
  rpc: QueueRpc
  handlers: Readonly<Record<string, CommandHandler>>
  deadLetters: Readonly<Record<string, DeadLetterHandler>>
  /** Milliseconds, defaults to Date.now. */
  now?: () => number
  log?: (event: string, data: Record<string, unknown>) => void
}

const defaultLog = (event: string, data: Record<string, unknown>) =>
  console.log(JSON.stringify({ event, ...data }))

export async function runInvocation(deps: ProcessorDeps, tenantId: string | null): Promise<RunSummary> {
  const { rpc, handlers, deadLetters } = deps
  const now = deps.now ?? Date.now
  const log = deps.log ?? defaultLog
  const start = now()
  const summary: RunSummary = { tenants: 0, processed: 0, rescheduled: 0, failed: 0, errors: 0 }

  const limitReached = () =>
    summary.processed + summary.rescheduled + summary.failed >= MAX_COMMANDS ||
    now() - start >= TIME_BUDGET_MS

  const runDeadLetter = async (t: string, row: ClaimedCommand, error: unknown) => {
    const dl = Object.hasOwn(deadLetters, row.commandType) ? deadLetters[row.commandType] : undefined
    if (!dl) return
    try {
      await dl({ tenantId: t, command: row, error })
    } catch (e) {
      log('dead_letter_error', { tenantId: t, commandId: row.commandId, commandType: row.commandType, error: String(e) })
    }
  }

  const handleRow = async (t: string, row: ClaimedCommand) => {
    if (limitReached()) {
      await rpc.reschedule(t, row.commandId, row.claimToken, 1)
      summary.rescheduled++
      return
    }
    const handler = Object.hasOwn(handlers, row.commandType) ? handlers[row.commandType] : undefined
    if (!handler) {
      await rpc.reschedule(t, row.commandId, row.claimToken, UNKNOWN_TYPE_DELAY_SECONDS)
      log('unknown_command_type', { tenantId: t, commandId: row.commandId, commandType: row.commandType })
      summary.rescheduled++
      return
    }
    const attemptNumber = row.retryCount + 1
    try {
      await handler({ tenantId: t, command: row, attemptNumber })
    } catch (e) {
      if (e instanceof PublishSeriesLeaseBusyError) {
        await rpc.reschedule(t, row.commandId, row.claimToken, e.retryAfterSeconds)
        summary.rescheduled++
        return
      }
      const max = maxAttemptsFor(row.commandType)
      if (max !== undefined && attemptNumber >= max) {
        await rpc.fail(t, row.commandId, row.claimToken, String(e))
        await runDeadLetter(t, row, e)
        summary.failed++
        return
      }
      const disposition = await rpc.retryOrDeadLetter(t, row.commandId, row.claimToken, String(e))
      if (disposition === 'DEAD_LETTER') {
        await runDeadLetter(t, row, e)
        summary.failed++
      } else {
        summary.rescheduled++
      }
      return
    }
    await rpc.complete(t, row.commandId, row.claimToken)
    summary.processed++
  }

  const tenants = tenantId ? [tenantId] : await rpc.listTenantsWithDueCommands(MAX_TENANTS)
  summary.tenants = tenants.length

  for (const t of tenants) {
    try {
      await rpc.seedDueReconciliationCommands(t, SEED_LIMIT)
      while (!limitReached()) {
        const rows = await rpc.claimBatch(t, CLAIM_BATCH)
        if (rows.length === 0) break
        for (const row of rows) await handleRow(t, row)
      }
    } catch (e) {
      log('tenant_error', { tenantId: t, error: String(e) })
      summary.errors++
    }
  }
  return summary
}
