import { MESSAGES } from './messages.ts'
import { type ModelConfig, modelConfigFromEnv } from './model/config.ts'
import { ModelBusyError, type ModelClient, ModelError } from './model/model_client.ts'
import { answerQuestion } from './orchestrator.ts'
import { todayInVietnam } from './period.ts'
import { buildSystemPrompt } from './prompt.ts'
import { jsonResponse, preflightResponse } from './http.ts'
import { parseAssistantRequest } from './request.ts'
import { buildTools } from './tools/registry.ts'
import { type RpcCaller, rpcErrorFromPostgrest } from './tools/tool.ts'
import type { AssistantReply, Status } from './types.ts'

type RpcResult = { data: unknown; error: { message?: string } | null }

/** Phần của SupabaseClient mà handler dùng — để test bằng đối tượng giả. */
export type SupabaseLike = {
  auth: {
    getUser(jwt?: string): Promise<
      { data: { user: { id: string } | null }; error: unknown }
    >
  }
  schema(
    name: string,
  ): { rpc(fn: string, args: Record<string, unknown>): PromiseLike<RpcResult> }
}

export type HandlerDeps = {
  now: () => Date
  getEnv: (key: string) => string | undefined
  makeClient: (authorization: string) => SupabaseLike
  makeModel: (cfg: ModelConfig) => ModelClient
  timeoutMs?: number
}

const DEFAULT_TIMEOUT_MS = 30_000

class TimeoutError extends Error {}

function reply(
  status: Status,
  answer: string,
  extra: Partial<Pick<AssistantReply, 'khoi' | 'luot_con_lai' | 'cong_cu'>> = {},
): Response {
  const body: AssistantReply = {
    trang_thai: status,
    cau_tra_loi: answer,
    khoi: extra.khoi ?? [],
    luot_con_lai: extra.luot_con_lai ?? null,
    cong_cu: extra.cong_cu ?? [],
  }
  return jsonResponse(body)
}

function rpcCaller(client: SupabaseLike): RpcCaller {
  return async (schema, fn, args) => {
    const { data, error } = await client.schema(schema).rpc(fn, args)
    if (error) throw rpcErrorFromPostgrest(error)
    return data
  }
}

export async function handleRequest(
  req: Request,
  deps: HandlerDeps,
): Promise<Response> {
  const preflight = preflightResponse(req.method)
  if (preflight) return preflight
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'method_not_allowed' }, 405)
  }

  const authorization = req.headers.get('Authorization')
  if (!authorization) return jsonResponse({ error: 'unauthorized' }, 401)

  let body: unknown
  try {
    body = await req.json()
  } catch {
    return jsonResponse({ error: 'VALIDATION_ERROR' }, 400)
  }
  const parsed = parseAssistantRequest(body)
  if (!parsed.ok) return jsonResponse({ error: 'VALIDATION_ERROR' }, 400)
  const { tenantId, question, history } = parsed.value

  // Mọi RPC chạy bằng JWT người hỏi.
  const client = deps.makeClient(authorization)
  const { data: userData, error: userError } = await client.auth.getUser(
    authorization.replace(/^Bearer\s+/i, '').trim(),
  )
  const actorId = userData?.user?.id
  if (userError || !actorId) {
    return jsonResponse({ error: 'unauthorized' }, 401)
  }

  // 1. Đếm lượt + ghi nhật ký
  const started = await client.schema('ai').rpc('start_question', {
    p_tenant_id: tenantId,
    p_question: question,
  })
  if (started.error) {
    const err = rpcErrorFromPostgrest(started.error)
    if (err.code === 'QUOTA_EXCEEDED') {
      return reply('het_luot', MESSAGES.het_luot, { luot_con_lai: 0 })
    }
    if (err.code === 'PERMISSION_DENIED') {
      return reply('khong_quyen', MESSAGES.khong_quyen)
    }
    console.error('ai.start_question failed', err.code)
    return reply('loi', MESSAGES.loi)
  }
  const info = (started.data ?? {}) as {
    log_id?: string
    remaining?: number
    is_owner?: boolean
    tenant_name?: string
  }
  const remaining = typeof info.remaining === 'number' ? info.remaining : null
  const startedAt = Date.now()

  let status: Status = 'loi'
  let answer: string = MESSAGES.loi
  let blocks: AssistantReply['khoi'] = []
  let toolCalls: {
    name: string
    args: Record<string, unknown>
    ok: boolean
  }[] = []
  let usage = { inputTokens: 0, outputTokens: 0 }

  const cfg = modelConfigFromEnv(deps.getEnv)
  if (!cfg) {
    console.error('ANTHROPIC_API_KEY chưa được cấu hình')
  } else {
    console.log('ai-trace model', cfg.model, cfg.effort)
    const controller = new AbortController()
    let timer: ReturnType<typeof setTimeout> | undefined
    try {
      const today = todayInVietnam(deps.now())
      const result = await Promise.race([
        answerQuestion({
          question,
          history,
          system: buildSystemPrompt({
            today,
            isOwner: info.is_owner === true,
            tenantName: info.tenant_name ?? '',
          }),
          model: deps.makeModel(cfg),
          tools: buildTools(),
          ctx: { tenantId, actorId, today, rpc: rpcCaller(client) },
          signal: controller.signal,
        }),
        new Promise<never>((_, reject) => {
          timer = setTimeout(() => {
            controller.abort()
            reject(new TimeoutError('timeout'))
          }, deps.timeoutMs ?? DEFAULT_TIMEOUT_MS)
        }),
      ])
      status = result.status
      answer = result.answer
      blocks = result.blocks
      toolCalls = result.toolCalls
      usage = result.usage
    } catch (e) {
      if (e instanceof ModelBusyError) {
        status = 'ban'
        answer = MESSAGES.ban
        console.error('ai-assistant Claude bận:', e.message)
      } else if (
        e instanceof TimeoutError ||
        (e instanceof Error && e.name === 'AbortError')
      ) {
        status = 'loi'
        answer = MESSAGES.cham
      } else {
        status = 'loi'
        answer = MESSAGES.loi
        // ModelError chỉ chứa mã HTTP / lý do ngắn, không chứa câu hỏi hay khoá.
        console.error(
          'ai-assistant lỗi',
          e instanceof ModelError ? e.message : e instanceof Error ? e.name : 'unknown',
        )
      }
    } finally {
      if (timer !== undefined) clearTimeout(timer)
    }
  }

  // 2. Cập nhật nhật ký — lỗi ghi nhật ký không làm hỏng câu trả lời.
  try {
    if (info.log_id) {
      const finished = await client.schema('ai').rpc('finish_question', {
        p_log_id: info.log_id,
        p_status: status,
        p_tool_calls: toolCalls,
        p_input_tokens: usage.inputTokens,
        p_output_tokens: usage.outputTokens,
        p_latency_ms: Date.now() - startedAt,
      })
      if (finished.error) console.error('ai.finish_question failed')
    }
  } catch {
    console.error('ai.finish_question threw')
  }

  return reply(status, answer, {
    khoi: blocks,
    luot_con_lai: remaining,
    cong_cu: toolCalls.map((c) => c.name),
  })
}
