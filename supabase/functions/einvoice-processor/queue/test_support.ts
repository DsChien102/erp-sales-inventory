import type { ClaimedCommand, Disposition, QueueRpc } from './types.ts'

export type Call = [string, ...unknown[]]

export class FakeQueueRpc implements QueueRpc {
  calls: Call[] = []
  batches: ClaimedCommand[][] = []
  tenantsToList: string[] = []
  disposition: Disposition = 'RETRY'
  seedError: Record<string, Error> = {}
  claimEveryTime: (() => ClaimedCommand[]) | null = null
  onComplete: () => void = () => {}

  listTenantsWithDueCommands(limit: number) {
    this.calls.push(['list', limit])
    return Promise.resolve(this.tenantsToList)
  }
  seedDueReconciliationCommands(t: string, limit: number) {
    this.calls.push(['seed', t, limit])
    if (this.seedError[t]) return Promise.reject(this.seedError[t])
    return Promise.resolve(0)
  }
  claimBatch(t: string, limit: number) {
    this.calls.push(['claim', t, limit])
    if (this.claimEveryTime) return Promise.resolve(this.claimEveryTime())
    return Promise.resolve(this.batches.shift() ?? [])
  }
  complete(t: string, id: string, _tok: string) {
    this.calls.push(['complete', t, id])
    this.onComplete()
    return Promise.resolve()
  }
  fail(t: string, id: string, _tok: string, error: string) {
    this.calls.push(['fail', t, id, error])
    return Promise.resolve()
  }
  retryOrDeadLetter(t: string, id: string, _tok: string, error: string) {
    this.calls.push(['retryOrDeadLetter', t, id, error])
    return Promise.resolve(this.disposition)
  }
  reschedule(t: string, id: string, _tok: string, delay: number) {
    this.calls.push(['reschedule', t, id, delay])
    return Promise.resolve()
  }
  names() {
    return this.calls.map((c) => c[0])
  }
  count(name: string) {
    return this.calls.filter((c) => c[0] === name).length
  }
}

let seq = 0
export function cmd(commandType: string, retryCount = 0): ClaimedCommand {
  seq++
  return {
    commandId: `c${seq}`,
    commandType,
    payload: {},
    sourceEventId: null,
    enqueuedAt: '2026-11-08T00:00:00Z',
    claimToken: `tok${seq}`,
    retryCount,
  }
}

