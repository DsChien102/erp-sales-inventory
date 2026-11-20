import { createClient } from 'npm:@supabase/supabase-js@2'
import {
  authCreateErrorOutcome,
  dbErrorOutcome,
  type ErrorOutcome,
  parseSignupRequest,
} from './logic.ts'

// Tạo tài khoản đã xác minh email và nhận lời mời trong một lần.
// Mã lời mời 8 ký tự được gửi tới đúng email được mời nên đã chứng minh chủ email.
//
// Hai khoá, hai việc:
// - service_role: chỉ cho auth.admin.createUser / deleteUser (tạo user đã xác minh).
// - anon: gọi iam.inspect_invitation_token / iam.accept_invitation — hai RPC này chỉ
//   cấp EXECUTE cho anon, authenticated (không cấp cho service_role).

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: CORS_HEADERS })
  }
  if (req.method !== 'POST') {
    return fail(405, 'METHOD_NOT_ALLOWED')
  }

  let body: unknown
  try {
    body = await req.json()
  } catch {
    return fail(400, 'VALIDATION_ERROR')
  }
  const parsed = parseSignupRequest(body)
  if (!parsed.ok) {
    return fail(400, 'VALIDATION_ERROR')
  }
  const input = parsed.value

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  if (supabaseUrl.length === 0 || anonKey.length === 0 || serviceRoleKey.length === 0) {
    return fail(500, 'SYSTEM_ERROR')
  }

  const clientOptions = { auth: { persistSession: false, autoRefreshToken: false } }
  const publicClient = createClient(supabaseUrl, anonKey, clientOptions)
  const adminClient = createClient(supabaseUrl, serviceRoleKey, clientOptions)

  // 1. Kiểm mã lời mời; email lấy từ lời mời, người gọi không chọn được.
  const inspected = await publicClient
    .schema('iam')
    .rpc('inspect_invitation_token', { p_token: input.token })
  if (inspected.error) {
    return failWith(dbErrorOutcome(inspected.error.message))
  }
  const inspection = firstObject(inspected.data)
  const inviteeEmail = typeof inspection?.invitee_email === 'string'
    ? inspection.invitee_email.trim().toLowerCase()
    : ''
  if (inviteeEmail.length === 0) {
    return fail(500, 'SYSTEM_ERROR')
  }
  if (inspection?.account_exists === true) {
    return fail(409, 'ACCOUNT_EXISTS')
  }

  // 2. Tạo user đã xác minh; trigger _on_auth_user_confirmed tự tạo hồ sơ.
  const created = await adminClient.auth.admin.createUser({
    email: inviteeEmail,
    password: input.password,
    email_confirm: true,
    user_metadata: {
      first_name: input.givenName,
      last_name: input.familyName,
      ...(input.phone === null ? {} : { phone: input.phone }),
    },
  })
  const userId = created.data?.user?.id
  if (created.error || !userId) {
    return failWith(authCreateErrorOutcome(created.error))
  }

  // 3. Nhận lời mời. Lỗi → xoá user vừa tạo để người dùng thử lại từ đầu.
  const accepted = await publicClient.schema('iam').rpc('accept_invitation', {
    p_token: input.token,
    p_idempotency_key: input.idempotencyKey,
  })
  if (accepted.error) {
    const outcome = dbErrorOutcome(accepted.error.message)
    const removed = await adminClient.auth.admin.deleteUser(userId)
    return failWith(outcome, removed.error ? 'rolled_back_failed' : 'rolled_back')
  }

  log('ok', null)
  return json({ membership: firstObject(accepted.data) ?? {} }, 200)
})

function firstObject(data: unknown): Record<string, unknown> | null {
  const row = Array.isArray(data) ? data[0] : data
  return typeof row === 'object' && row !== null ? row as Record<string, unknown> : null
}

function fail(status: number, code: string): Response {
  log('error', code)
  return json({ code }, status)
}

function failWith(outcome: ErrorOutcome, result = 'error'): Response {
  log(result, outcome.code)
  return json({ code: outcome.code }, outcome.status)
}

// Một dòng JSON mỗi lần gọi. Không ghi mật khẩu, mã lời mời hay email.
function log(result: string, code: string | null): void {
  console.log(JSON.stringify({ fn: 'invitation-signup', result, code }))
}

function json(payload: unknown, status: number): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  })
}
