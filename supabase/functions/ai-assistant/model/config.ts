export type Effort = 'low' | 'medium' | 'high'
export type ModelConfig = { apiKey: string; model: string; effort: Effort }

export const DEFAULT_CLAUDE_MODEL = 'claude-haiku-5-5'

/** null ⇒ thiếu ANTHROPIC_API_KEY (handler log lỗi cấu hình, trạng thái loi). */
export function modelConfigFromEnv(
  getEnv: (k: string) => string | undefined,
): ModelConfig | null {
  const apiKey = getEnv('ANTHROPIC_API_KEY')
  if (!apiKey) return null
  const e = getEnv('CLAUDE_EFFORT')
  const effort: Effort = e === 'medium' || e === 'high' ? e : 'low'
  return { apiKey, model: getEnv('CLAUDE_MODEL') || DEFAULT_CLAUDE_MODEL, effort }
}
