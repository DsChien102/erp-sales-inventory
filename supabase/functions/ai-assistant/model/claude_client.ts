import Anthropic from 'npm:@anthropic-ai/sdk@1.8.0'
import type { ModelConfig } from './config.ts'
import {
  ModelBusyError,
  type ModelClient,
  ModelError,
  type ModelResult,
  type ModelTurn,
  type ToolDeclaration,
} from './model_client.ts'

type Block = { type: string; [k: string]: unknown }

const MAX_TOKENS = 8000
const ATTEMPT_TIMEOUT_MS = 12_000

type Message = { role: 'user' | 'assistant'; content: unknown }

/**
 * Thêm một lượt chữ (câu hỏi / câu trả lời cũ trong history). App bỏ bong bóng lỗi và cắt
 * lịch sử nên có thể có: chữ rỗng, câu trả lời đứng trước câu hỏi đầu tiên, hai lượt cùng vai
 * liền nhau — Claude không nhận các dạng đó, nên bỏ / gộp ở đây.
 */
function pushText(out: Message[], role: 'user' | 'assistant', text: string) {
  const t = text.trim()
  if (t === '') return
  if (out.length === 0 && role === 'assistant') return
  const last = out.at(-1)
  if (last && last.role === role && typeof last.content === 'string') {
    last.content = `${last.content}\n\n${t}`
    return
  }
  out.push({ role, content: t })
}

/** Đổi các lượt của orchestrator sang messages của Claude. */
function toMessages(turns: ModelTurn[]): Message[] {
  const out: Message[] = []
  let lastToolUseIds: string[] = []
  for (const t of turns) {
    switch (t.role) {
      case 'user':
        pushText(out, 'user', t.text)
        break
      case 'model_text':
        pushText(out, 'assistant', t.text)
        break
      case 'model': {
        const content = t.raw as Block[]
        lastToolUseIds = content.filter((b) => b.type === 'tool_use').map((b) => b.id as string)
        // nguyên văn (kể cả khối thinking)
        out.push({ role: 'assistant', content })
        break
      }
      case 'tool_results':
        out.push({
          role: 'user',
          content: t.results.map((r, i) => ({
            type: 'tool_result',
            tool_use_id: lastToolUseIds[i],
            content: JSON.stringify(r.response),
          })),
        })
        break
    }
  }
  return out
}

export class ClaudeClient implements ModelClient {
  readonly #cfg: ModelConfig
  readonly #client: Anthropic

  constructor(o: ModelConfig & { fetch?: typeof fetch }) {
    this.#cfg = { apiKey: o.apiKey, model: o.model, effort: o.effort }
    this.#client = new Anthropic({ apiKey: o.apiKey, maxRetries: 1, fetch: o.fetch })
  }

  async generate(r: {
    system: string
    turns: ModelTurn[]
    tools: ToolDeclaration[]
    signal?: AbortSignal
  }): Promise<ModelResult> {
    // Không gửi temperature / top_p / top_k / thinking (Haiku 5.5 mặc định suy nghĩ thích ứng).
    const body = {
      model: this.#cfg.model,
      max_tokens: MAX_TOKENS,
      system: r.system,
      tools: r.tools.map((d) => ({ name: d.name, description: d.description, input_schema: d.parameters })),
      messages: toMessages(r.turns),
      output_config: { effort: this.#cfg.effort },
      cache_control: { type: 'ephemeral' },
    }

    let response: Anthropic.Message
    try {
      // deno-lint-ignore no-explicit-any
      response = await this.#client.messages.create(body as any, {
        signal: r.signal,
        timeout: ATTEMPT_TIMEOUT_MS,
      }) as Anthropic.Message
    } catch (e) {
      // Hết 30 giây tổng ⇒ ném nguyên lỗi huỷ (handler hiện "chậm").
      if (e instanceof Anthropic.APIUserAbortError) throw e
      if (
        e instanceof Anthropic.RateLimitError ||
        e instanceof Anthropic.APIConnectionTimeoutError ||
        (e instanceof Anthropic.APIError && e.status === 529)
      ) {
        throw new ModelBusyError(`Claude bận (${e instanceof Anthropic.APIError && e.status ? e.status : 'timeout'})`)
      }
      if (e instanceof Anthropic.APIError) {
        // Kèm loại lỗi của API (vd. billing_error, invalid_request_error) để log phân biệt được.
        const type = (e as { type?: unknown }).type
        throw new ModelError(`Claude HTTP ${e.status ?? e.name}${typeof type === 'string' ? ` ${type}` : ''}`)
      }
      throw e
    }

    if (response.stop_reason === 'refusal') throw new ModelError('Claude từ chối (refusal)')

    const content = response.content as unknown as Block[]
    const u = response.usage as unknown as Record<string, number | null | undefined>
    const usage = {
      inputTokens: Number(u.input_tokens ?? 0) + Number(u.cache_read_input_tokens ?? 0) +
        Number(u.cache_creation_input_tokens ?? 0),
      outputTokens: Number(u.output_tokens ?? 0),
    }

    const uses = content.filter((b) => b.type === 'tool_use')
    if (uses.length > 0) {
      return {
        kind: 'tool_calls',
        calls: uses.map((b) => ({ name: b.name as string, args: (b.input ?? {}) as Record<string, unknown> })),
        raw: response.content,
        usage,
      }
    }
    if (response.stop_reason === 'max_tokens') throw new ModelError('Claude cắt vì max_tokens')
    const text = content.filter((b) => b.type === 'text').map((b) => String(b.text ?? '')).join('')
    return { kind: 'text', text, raw: response.content, usage }
  }
}
