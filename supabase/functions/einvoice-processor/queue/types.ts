export interface ClaimedCommand {
  commandId: string
  commandType: string
  payload: Record<string, unknown>
  sourceEventId: string | null
  enqueuedAt: string
  claimToken: string
  retryCount: number
}
export type Disposition = 'RETRY' | 'DEAD_LETTER'
export interface QueueRpc {
  listTenantsWithDueCommands(limit: number): Promise<string[]>
  seedDueReconciliationCommands(tenantId: string, limit: number): Promise<number>
  claimBatch(tenantId: string, limit: number): Promise<ClaimedCommand[]>
  complete(tenantId: string, commandId: string, claimToken: string): Promise<void>
  fail(tenantId: string, commandId: string, claimToken: string, error: string): Promise<void>
  retryOrDeadLetter(tenantId: string, commandId: string, claimToken: string, error: string): Promise<Disposition>
  reschedule(tenantId: string, commandId: string, claimToken: string, delaySeconds: number): Promise<void>
}
export interface CommandContext {
  tenantId: string
  command: ClaimedCommand
  attemptNumber: number
}
export type CommandHandler = (ctx: CommandContext) => Promise<void>
export type DeadLetterHandler = (
  ctx: { tenantId: string; command: ClaimedCommand; error: unknown },
) => Promise<void>
export interface RunSummary {
  tenants: number
  processed: number
  rescheduled: number
  failed: number
  errors: number
}
