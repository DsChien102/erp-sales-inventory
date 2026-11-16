import type { Turn } from './types.ts'

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

export const MAX_QUESTION_CHARS = 500
export const MAX_HISTORY_TURNS = 6
export const MAX_HISTORY_TEXT = 2000

/**
 * Chỉ nhận lịch sử dạng chữ thuần ({role: 'user' | 'assistant', text}), bỏ mọi khoá khác —
 * app không được nhét functionCall / functionResponse hay lượt "model" giả vào Gemini.
 */
export function parseAssistantRequest(
  body: unknown,
):
  | { ok: true; value: { tenantId: string; question: string; history: Turn[] } }
  | { ok: false } {
  if (body === null || typeof body !== 'object' || Array.isArray(body)) {
    return { ok: false }
  }
  const b = body as Record<string, unknown>

  if (typeof b.tenant_id !== 'string' || !UUID_RE.test(b.tenant_id)) {
    return { ok: false }
  }
  if (typeof b.question !== 'string') return { ok: false }
  const question = b.question.trim()
  if (question.length < 1 || question.length > MAX_QUESTION_CHARS) {
    return { ok: false }
  }

  const history: Turn[] = []
  if (Array.isArray(b.history)) {
    for (const item of b.history) {
      if (item === null || typeof item !== 'object' || Array.isArray(item)) {
        continue
      }
      const t = item as Record<string, unknown>
      if (t.role !== 'user' && t.role !== 'assistant') continue
      if (typeof t.text !== 'string') continue
      history.push({ role: t.role, text: t.text.slice(0, MAX_HISTORY_TEXT) })
    }
  }

  return {
    ok: true,
    value: {
      tenantId: b.tenant_id,
      question,
      history: history.slice(-MAX_HISTORY_TURNS),
    },
  }
}
