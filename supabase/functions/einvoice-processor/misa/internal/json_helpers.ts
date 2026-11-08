/** Shared JSON read/write helpers for MISA wire payloads (port of json_helpers.dart). */
type Json = Record<string, unknown>

function isPlainObject(v: unknown): v is Json {
  return typeof v === 'object' && v !== null && !Array.isArray(v)
}

function dartToString(value: unknown): string {
  return typeof value === 'string' ? value : String(value)
}

export const MeInvoiceJsonHelpers = {
  asMap(raw: unknown): Json | null {
    if (isPlainObject(raw)) return raw
    if (typeof raw === 'string') {
      try {
        const decoded = JSON.parse(raw)
        if (isPlainObject(decoded)) return decoded
      } catch {
        return null
      }
    }
    return null
  },

  asList(raw: unknown): unknown[] {
    if (raw === null || raw === undefined) return []
    if (Array.isArray(raw)) return raw
    if (typeof raw === 'string') {
      try {
        const decoded = JSON.parse(raw)
        if (Array.isArray(decoded)) return decoded
        if (isPlainObject(decoded)) return [decoded]
      } catch {
        return []
      }
    }
    if (isPlainObject(raw)) return [raw]
    return []
  },

  readBool(json: Json, key: string): boolean | null {
    const value = json[key]
    if (typeof value === 'boolean') return value
    if (typeof value === 'string') {
      const lower = value.toLowerCase()
      if (lower === 'true') return true
      if (lower === 'false') return false
    }
    return null
  },

  readInt(json: Json, key: string): number | null {
    const value = json[key]
    if (typeof value === 'number') return Number.isFinite(value) ? Math.trunc(value) : null
    if (typeof value === 'string') {
      return /^[+-]?\d+$/.test(value.trim()) ? parseInt(value.trim(), 10) : null
    }
    return null
  },

  readDouble(json: Json, key: string): number | null {
    const value = json[key]
    if (typeof value === 'number') return value
    if (typeof value === 'string') {
      const t = value.trim()
      if (t === '') return null
      const n = Number(t)
      return Number.isNaN(n) ? null : n
    }
    return null
  },

  readString(json: Json, key: string): string | null {
    const value = json[key]
    if (value === null || value === undefined) return null
    const text = dartToString(value)
    return text === '' ? null : text
  },

  readDateTime(json: Json, key: string): Date | null {
    const text = MeInvoiceJsonHelpers.readString(json, key)
    if (text === null) return null
    const d = new Date(text)
    return Number.isNaN(d.getTime()) ? null : d
  },

  /** MISA date-only fields (`InvDate`, `OrgInvDate`) use yyyy-MM-dd. */
  formatDateOnly(value: Date | null | undefined): string | null {
    if (!value) return null
    const y = String(value.getUTCFullYear()).padStart(4, '0')
    const m = String(value.getUTCMonth() + 1).padStart(2, '0')
    const d = String(value.getUTCDate()).padStart(2, '0')
    return `${y}-${m}-${d}`
  },

  writeIfPresent(target: Json, key: string, value: unknown): void {
    if (value !== null && value !== undefined) target[key] = value
  },

  writeStringIfPresent(target: Json, key: string, value: string | null | undefined): void {
    if (value !== null && value !== undefined) target[key] = value
  },

  readSuccess(json: Json): boolean | null {
    const value = json['Success'] ?? json['success']
    return typeof value === 'boolean' ? value : null
  },

  readErrorCode(json: Json): string | null {
    const code = json['ErrorCode'] ?? json['errorCode']
    if (code === null || code === undefined) return null
    const text = dartToString(code)
    return text === '' ? null : text
  },
}
