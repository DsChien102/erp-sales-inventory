const PERSONAL_KEY = /phone|email|address|tax|cccd|identity/i

/** Bỏ đệ quy mọi khoá chứa thông tin cá nhân trước khi gửi cho Gemini (AI-0 mục 11). */
export function redactPersonal(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(redactPersonal)
  if (value !== null && typeof value === 'object') {
    const out: Record<string, unknown> = {}
    for (const [k, v] of Object.entries(value as Record<string, unknown>)) {
      if (PERSONAL_KEY.test(k)) continue
      out[k] = redactPersonal(v)
    }
    return out
  }
  return value
}
