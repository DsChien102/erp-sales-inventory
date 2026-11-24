// Hàm thuần của Edge Function `invitation-signup`: kiểm đầu vào và ánh xạ lỗi.
// Giữ riêng khỏi index.ts để test bằng Deno mà không cần Supabase.

export const TOKEN_LENGTH = 8
export const PASSWORD_MIN_LENGTH = 8

export type SignupInput = {
  token: string
  password: string
  givenName: string
  familyName: string
  phone: string | null
  idempotencyKey: string
}

export type ParseResult =
  | { ok: true; value: SignupInput }
  | { ok: false }

export type ErrorOutcome = { status: number; code: string }

/** Cùng luật với `PasswordPolicy` của app: ≥ 8 ký tự, có 1 số, có 1 ký tự không phải chữ/số. */
export function isPasswordValid(password: string): boolean {
  return password.length >= PASSWORD_MIN_LENGTH &&
    /\d/.test(password) &&
    /[^A-Za-z0-9]/.test(password)
}

export function normalizeToken(token: string): string {
  return token.trim().toUpperCase()
}

function text(value: unknown): string {
  return typeof value === 'string' ? value.trim() : ''
}

export function parseSignupRequest(body: unknown): ParseResult {
  if (typeof body !== 'object' || body === null || Array.isArray(body)) {
    return { ok: false }
  }
  const raw = body as Record<string, unknown>

  const token = normalizeToken(text(raw.token))
  const password = typeof raw.password === 'string' ? raw.password : ''
  const givenName = text(raw.given_name)
  const familyName = text(raw.family_name)
  const phone = text(raw.phone)
  const idempotencyKey = text(raw.idempotency_key)

  if (token.length !== TOKEN_LENGTH) return { ok: false }
  if (givenName.length === 0 || familyName.length === 0) return { ok: false }
  if (!isPasswordValid(password)) return { ok: false }
  if (idempotencyKey.length === 0) return { ok: false }

  return {
    ok: true,
    value: {
      token,
      password,
      givenName,
      familyName,
      phone: phone.length === 0 ? null : phone,
      idempotencyKey,
    },
  }
}

const DB_CODE_PATTERN = /^[A-Z][A-Z0-9_]{2,}/

/**
 * Lấy mã nghiệp vụ từ `error.message` của RPC (`raise exception 'INVITATION_EXPIRED'`),
 * cùng cách app đọc. Không khớp → `SYSTEM_ERROR`.
 */
export function extractDbErrorCode(message: string | null | undefined): string {
  const match = DB_CODE_PATTERN.exec((message ?? '').trim())
  return match ? match[0] : 'SYSTEM_ERROR'
}

/** Mã lỗi DB → phản hồi HTTP. Mã không rõ là lỗi hệ thống (500), còn lại là lỗi người dùng (400). */
export function dbErrorOutcome(message: string | null | undefined): ErrorOutcome {
  const code = extractDbErrorCode(message)
  return { status: code === 'SYSTEM_ERROR' ? 500 : 400, code }
}

const ACCOUNT_EXISTS_CODES = new Set(['email_exists', 'user_already_exists'])

/**
 * Lỗi `auth.admin.createUser` → phản hồi HTTP. Chỉ dựa vào `code` của Auth:
 * status 422 dùng chung cho nhiều lỗi (kể cả `weak_password`) nên không đủ phân biệt.
 */
export function authCreateErrorOutcome(
  error: { code?: string | null } | null | undefined,
): ErrorOutcome {
  const code = (error?.code ?? '').toLowerCase()
  if (ACCOUNT_EXISTS_CODES.has(code)) return { status: 409, code: 'ACCOUNT_EXISTS' }
  if (code === 'weak_password') return { status: 400, code: 'WEAK_PASSWORD' }
  return { status: 500, code: 'SYSTEM_ERROR' }
}
