import type { RpcCaller, ToolContext } from './tool.ts'

export type RpcCall = {
  schema: string
  fn: string
  args: Record<string, unknown>
}

/** RpcCaller giả: trả theo `schema.fn`, ghi lại lời gọi. Giá trị là Error thì ném. */
export function fakeRpc(
  responses: Record<string, unknown>,
): { rpc: RpcCaller; calls: RpcCall[] } {
  const calls: RpcCall[] = []
  const rpc: RpcCaller = (schema, fn, args) => {
    calls.push({ schema, fn, args })
    const key = `${schema}.${fn}`
    if (!(key in responses)) {
      return Promise.reject(new Error(`fakeRpc: chưa có kịch bản cho ${key}`))
    }
    const r = responses[key]
    return r instanceof Error ? Promise.reject(r) : Promise.resolve(r)
  }
  return { rpc, calls }
}

export function makeCtx(rpc: RpcCaller, today = '2026-11-16'): ToolContext {
  return { tenantId: 'tenant-1', actorId: 'actor-1', today, rpc }
}
