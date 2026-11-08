import { assertEquals } from 'jsr:@std/assert@1'
import { PublishSeriesLeaseBusyError } from './errors.ts'
import { runInvocation, type ProcessorDeps } from './processor.ts'
import type { ClaimedCommand, CommandHandler, Disposition, QueueRpc } from './types.ts'

type Call = [string, ...unknown[]]

class FakeQueueRpc implements QueueRpc {
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
function cmd(commandType: string, retryCount = 0): ClaimedCommand {
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

const SYNC = 'einvoice.sync_capabilities'
const ok: CommandHandler = () => Promise.resolve()
const boom: CommandHandler = () => Promise.reject(new Error('boom'))

function setup(handlers: Record<string, CommandHandler>, extra: Partial<ProcessorDeps> = {}) {
  const rpc = new FakeQueueRpc()
  const logs: [string, Record<string, unknown>][] = []
  const deadLetterCalls: unknown[] = []
  const deps: ProcessorDeps = {
    rpc,
    handlers,
    deadLetters: Object.fromEntries(
      ['einvoice.fetch_official_view', 'einvoice.download_invoice_document', 'einvoice.publish_invoice'].map((
        k,
      ) => [k, (ctx: unknown) => {
        deadLetterCalls.push(ctx)
        return Promise.resolve()
      }]),
    ),
    log: (e, d) => logs.push([e, d]),
    ...extra,
  }
  return { rpc, deps, logs, deadLetterCalls }
}

Deno.test('complete after handler succeeds', async () => {
  const { rpc, deps } = setup({ [SYNC]: ok })
  rpc.batches = [[cmd(SYNC)]]
  const s = await runInvocation(deps, 't1')
  assertEquals(rpc.calls.map((c) => c[0]), ['seed', 'claim', 'complete', 'claim'])
  assertEquals(rpc.calls[0], ['seed', 't1', 5])
  assertEquals(rpc.calls[1], ['claim', 't1', 5])
  assertEquals(s, { tenants: 1, processed: 1, rescheduled: 0, failed: 0, errors: 0 })
})

Deno.test('handler receives attemptNumber = retryCount + 1', async () => {
  let attempt = -1
  const { rpc, deps } = setup({ [SYNC]: (ctx) => { attempt = ctx.attemptNumber; return Promise.resolve() } })
  rpc.batches = [[cmd(SYNC, 2)]]
  await runInvocation(deps, 't1')
  assertEquals(attempt, 3)
})

Deno.test('unknown command type is rescheduled 300s without consuming an attempt', async () => {
  const { rpc, deps, logs } = setup({ [SYNC]: ok })
  const c = cmd('einvoice.publish_invoice')
  rpc.batches = [[c]]
  const s = await runInvocation(deps, 't1')
  assertEquals(rpc.calls.find((x) => x[0] === 'reschedule'), ['reschedule', 't1', c.commandId, 300])
  assertEquals(rpc.count('retryOrDeadLetter'), 0)
  assertEquals(rpc.count('fail'), 0)
  assertEquals(logs.some(([e]) => e === 'unknown_command_type'), true)
  assertEquals(s.rescheduled, 1)
})

Deno.test('lease busy reschedules by retryAfter', async () => {
  const { rpc, deps } = setup({ [SYNC]: () => Promise.reject(new PublishSeriesLeaseBusyError(42)) })
  const c = cmd(SYNC)
  rpc.batches = [[c]]
  await runInvocation(deps, 't1')
  assertEquals(rpc.calls.find((x) => x[0] === 'reschedule'), ['reschedule', 't1', c.commandId, 42])
})

Deno.test('typed attempt limit fails and dead-letters on last attempt', async () => {
  const type = 'einvoice.fetch_official_view'
  const { rpc, deps, deadLetterCalls } = setup({ [type]: boom })
  const c = cmd(type, 1)
  rpc.batches = [[c]]
  const s = await runInvocation(deps, 't1')
  assertEquals(rpc.calls.find((x) => x[0] === 'fail'), ['fail', 't1', c.commandId, 'Error: boom'])
  assertEquals(deadLetterCalls.length, 1)
  assertEquals((deadLetterCalls[0] as { error: Error }).error.message, 'boom')
  assertEquals(rpc.count('retryOrDeadLetter'), 0)
  assertEquals(s.failed, 1)
})

Deno.test('typed attempt limit below max uses retryOrDeadLetter', async () => {
  const type = 'einvoice.download_invoice_document'
  const { rpc, deps } = setup({ [type]: boom })
  rpc.batches = [[cmd(type, 0)]]
  await runInvocation(deps, 't1')
  assertEquals(rpc.count('retryOrDeadLetter'), 1)
  assertEquals(rpc.count('fail'), 0)
})

Deno.test('generic failure retries', async () => {
  const { rpc, deps, deadLetterCalls } = setup({ 'einvoice.publish_invoice': boom })
  rpc.disposition = 'RETRY'
  rpc.batches = [[cmd('einvoice.publish_invoice')]]
  const s = await runInvocation(deps, 't1')
  assertEquals(deadLetterCalls.length, 0)
  assertEquals(s.rescheduled, 1)
})

Deno.test('generic failure dead-letters', async () => {
  const { rpc, deps, deadLetterCalls } = setup({ 'einvoice.publish_invoice': boom })
  rpc.disposition = 'DEAD_LETTER'
  rpc.batches = [[cmd('einvoice.publish_invoice')]]
  const s = await runInvocation(deps, 't1')
  assertEquals(deadLetterCalls.length, 1)
  assertEquals(s.failed, 1)
})

Deno.test('dead-letter handler error does not escape', async () => {
  const { rpc, deps, logs } = setup({ 'einvoice.publish_invoice': boom })
  deps.deadLetters = { 'einvoice.publish_invoice': () => Promise.reject(new Error('dl')) }
  rpc.disposition = 'DEAD_LETTER'
  rpc.batches = [[cmd('einvoice.publish_invoice')]]
  const s = await runInvocation(deps, 't1')
  assertEquals(s.failed, 1)
  assertEquals(logs.some(([e]) => e === 'dead_letter_error'), true)
})

Deno.test('stops at MAX_COMMANDS and hands back claimed rows', async () => {
  const { rpc, deps } = setup({ [SYNC]: ok })
  rpc.claimEveryTime = () => Array.from({ length: 5 }, () => cmd(SYNC))
  const s = await runInvocation(deps, 't1')
  assertEquals(rpc.count('complete'), 20)
  assertEquals(rpc.count('claim'), 4)
  assertEquals(s.processed, 20)
})

Deno.test('time budget hands back remaining claimed rows', async () => {
  let t = 0
  const { rpc, deps } = setup({ [SYNC]: ok }, { now: () => t })
  rpc.onComplete = () => {
    t += 91_000
  }
  rpc.batches = [[cmd(SYNC), cmd(SYNC), cmd(SYNC)]]
  const s = await runInvocation(deps, 't1')
  assertEquals(rpc.count('complete'), 1)
  assertEquals(rpc.calls.filter((c) => c[0] === 'reschedule' && c[3] === 1).length, 2)
  assertEquals(rpc.count('claim'), 1)
  assertEquals(s.rescheduled, 2)
})

Deno.test('tenant error does not block next tenant', async () => {
  const { rpc, deps, logs } = setup({ [SYNC]: ok })
  rpc.tenantsToList = ['t1', 't2']
  rpc.seedError['t1'] = new Error('db down')
  const s = await runInvocation(deps, null)
  assertEquals(rpc.calls.some((c) => c[0] === 'claim' && c[1] === 't2'), true)
  assertEquals(s.errors, 1)
  assertEquals(s.tenants, 2)
  assertEquals(logs.find(([e]) => e === 'tenant_error')?.[1], { tenantId: 't1', error: 'Error: db down' })
})

Deno.test('explicit tenant skips discovery', async () => {
  const { rpc, deps } = setup({ [SYNC]: ok })
  await runInvocation(deps, 't1')
  assertEquals(rpc.count('list'), 0)
})

Deno.test('discovery uses MAX_TENANTS', async () => {
  const { rpc, deps } = setup({ [SYNC]: ok })
  await runInvocation(deps, null)
  assertEquals(rpc.calls[0], ['list', 20])
})
