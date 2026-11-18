import { assertEquals } from 'jsr:@std/assert@1'
import { type HandlerDeps, handleRequest, type SupabaseLike } from './handler.ts'
import { MESSAGES } from './messages.ts'
import { FakeModelClient } from './model/fake_model_client.ts'
import { ModelBusyError, type ModelClient, ModelError, type ModelResult } from './model/model_client.ts'

const T = '11111111-1111-4111-8111-111111111111'
const usage = { inputTokens: 5, outputTokens: 1 }
const text = (t: string): ModelResult => ({
  kind: 'text',
  text: t,
  raw: { role: 'model', parts: [{ text: t }] },
  usage,
})
const toolCall = (
  name: string,
  args: Record<string, unknown> = {},
): ModelResult => ({
  kind: 'tool_calls',
  calls: [{ name, args }],
  raw: { role: 'model', parts: [] },
  usage,
})

type RpcLog = { schema: string; fn: string; args: Record<string, unknown> }

function fakeClient(opts: {
  user?: { id: string } | null
  rpc: (
    schema: string,
    fn: string,
    args: Record<string, unknown>,
  ) => { data?: unknown; error?: { message: string } | null } | Error
  log?: RpcLog[]
  tokens?: (string | undefined)[]
}): SupabaseLike {
  return {
    auth: {
      getUser: (jwt?: string) => {
        opts.tokens?.push(jwt)
        return Promise.resolve({
          data: { user: opts.user === undefined ? { id: 'u1' } : opts.user },
          error: null,
        })
      },
    },
    schema: (schema) => ({
      rpc: (fn, args) => {
        opts.log?.push({ schema, fn, args })
        const r = opts.rpc(schema, fn, args)
        if (r instanceof Error) return Promise.reject(r)
        return Promise.resolve({
          data: r.data ?? null,
          error: r.error ?? null,
        })
      },
    }),
  }
}

const START_OK = {
  data: {
    log_id: 'log-1',
    remaining: 42,
    is_owner: true,
    tenant_name: 'Cửa hàng Mai',
  },
}
const rpcErr = (code: string) => ({
  error: { message: JSON.stringify({ code, message: 'x' }) },
})

function deps(
  client: SupabaseLike,
  model: ModelClient,
  env: Record<string, string> = { ANTHROPIC_API_KEY: 'k' },
  timeoutMs?: number,
): HandlerDeps {
  return {
    now: () => new Date('2026-11-16T03:00:00Z'),
    getEnv: (k) => env[k],
    makeClient: () => client,
    makeModel: () => model,
    timeoutMs,
  }
}

const post = (
  body: unknown,
  headers: Record<string, string> = { Authorization: 'Bearer jwt' },
) =>
  new Request('http://x/ai-assistant', {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
  })
const good = { tenant_id: T, question: 'Hôm nay bán được bao nhiêu?' }

Deno.test('luồng thành công: ok + bảng + lượt còn lại + nhật ký', async () => {
  const log: RpcLog[] = []
  const client = fakeClient({
    log,
    rpc: (_s, fn) =>
      fn === 'start_question'
        ? START_OK
        : fn === 'get_sales_stats'
        ? { data: { total: 1000, rows: [] } }
        : { data: null },
  })
  const model = new FakeModelClient([
    toolCall('thong_ke_ban_hang', { chi_so: 'doanh_thu' }),
    text('Hôm nay bán 1.000đ.'),
  ])
  const res = await handleRequest(post(good), deps(client, model))
  const body = await res.json()
  assertEquals(res.status, 200)
  assertEquals(body.trang_thai, 'ok')
  assertEquals(body.luot_con_lai, 42)
  assertEquals(body.cong_cu, ['thong_ke_ban_hang'])
  const stats = log.find((l) => l.fn === 'get_sales_stats')!
  assertEquals(stats.args.p_tenant_id, T)
  assertEquals(stats.args.p_from, '2026-11-16')
  const fin = log.find((l) => l.fn === 'finish_question')!
  assertEquals(fin.args.p_status, 'ok')
  assertEquals(fin.args.p_log_id, 'log-1')
  assertEquals(fin.args.p_input_tokens, 10)
  // system prompt có tên cửa hàng + vai trò
  assertEquals(model.requests[0].system.includes('Cửa hàng Mai'), true)
})

Deno.test('QUOTA_EXCEEDED ⇒ het_luot, không gọi model', async () => {
  const model = new FakeModelClient([])
  const client = fakeClient({ rpc: () => rpcErr('QUOTA_EXCEEDED') })
  const body = await (await handleRequest(post(good), deps(client, model)))
    .json()
  assertEquals([body.trang_thai, body.cau_tra_loi, body.luot_con_lai], [
    'het_luot',
    MESSAGES.het_luot,
    0,
  ])
  assertEquals(model.requests.length, 0)
})

Deno.test('start_question PERMISSION_DENIED ⇒ khong_quyen', async () => {
  const client = fakeClient({ rpc: () => rpcErr('PERMISSION_DENIED') })
  const body = await (await handleRequest(
    post(good),
    deps(client, new FakeModelClient([])),
  )).json()
  assertEquals(body.trang_thai, 'khong_quyen')
})

Deno.test('Claude 429 ⇒ ban + câu cố định, nhật ký ghi ban', async () => {
  const log: RpcLog[] = []
  const client = fakeClient({
    log,
    rpc: (_s, fn) => (fn === 'start_question' ? START_OK : { data: null }),
  })
  const body = await (await handleRequest(
    post(good),
    deps(client, new FakeModelClient([new ModelBusyError('429')])),
  )).json()
  assertEquals([body.trang_thai, body.cau_tra_loi], ['ban', MESSAGES.ban])
  assertEquals(
    log.find((l) => l.fn === 'finish_question')!.args.p_status,
    'ban',
  )
})

Deno.test('model chậm quá thời hạn ⇒ loi + MESSAGES.cham', async () => {
  const slow: ModelClient = {
    generate: ({ signal }) =>
      new Promise((_, reject) =>
        signal?.addEventListener(
          'abort',
          () => reject(new DOMException('aborted', 'AbortError')),
        )
      ),
  }
  const client = fakeClient({
    rpc: (_s, fn) => (fn === 'start_question' ? START_OK : { data: null }),
  })
  const body = await (await handleRequest(
    post(good),
    deps(client, slow, { ANTHROPIC_API_KEY: 'k' }, 20),
  )).json()
  assertEquals([body.trang_thai, body.cau_tra_loi], ['loi', MESSAGES.cham])
})

Deno.test('lỗi khác ⇒ loi + MESSAGES.loi', async () => {
  const client = fakeClient({
    rpc: (_s, fn) => (fn === 'start_question' ? START_OK : { data: null }),
  })
  const body = await (await handleRequest(
    post(good),
    deps(client, new FakeModelClient([new Error('boom')])),
  )).json()
  assertEquals([body.trang_thai, body.cau_tra_loi], ['loi', MESSAGES.loi])
})

Deno.test('missing_anthropic_key_loi: thiếu ANTHROPIC_API_KEY ⇒ loi, không gọi model, không 500', async () => {
  const client = fakeClient({
    rpc: (_s, fn) => (fn === 'start_question' ? START_OK : { data: null }),
  })
  let made = 0
  const d = { ...deps(client, new FakeModelClient([]), {}), makeModel: () => (made++, new FakeModelClient([])) }
  const res = await handleRequest(post(good), d)
  assertEquals(res.status, 200)
  assertEquals((await res.json()).trang_thai, 'loi')
  assertEquals(made, 0)
})

Deno.test('lỗi ghi nhật ký không làm hỏng câu trả lời', async () => {
  const client = fakeClient({
    rpc: (
      _s,
      fn,
    ) => (fn === 'start_question' ? START_OK : fn === 'finish_question' ? new Error('db down') : { data: null }),
  })
  const body = await (await handleRequest(
    post(good),
    deps(client, new FakeModelClient([text('Chào bạn!')])),
  )).json()
  assertEquals([body.trang_thai, body.cau_tra_loi], [
    'tro_chuyen',
    'Chào bạn!',
  ])
})

Deno.test('PERMISSION_DENIED từ công cụ ⇒ khong_quyen, không lộ số', async () => {
  const client = fakeClient({
    rpc: (
      _s,
      fn,
    ) => (fn === 'start_question'
      ? START_OK
      : fn === 'get_gross_profit_report'
      ? rpcErr('PERMISSION_DENIED')
      : { data: null }),
  })
  const model = new FakeModelClient([
    toolCall('lai_gop', { ky: 'thang_nay' }),
    text('KHÔNG ĐƯỢC GỌI'),
  ])
  const body = await (await handleRequest(post(good), deps(client, model)))
    .json()
  assertEquals([body.trang_thai, body.cau_tra_loi, body.khoi], [
    'khong_quyen',
    MESSAGES.khong_quyen,
    [],
  ])
})

Deno.test('400 khi body sai; 401 khi thiếu JWT hoặc không có user; 405; OPTIONS 204', async () => {
  const client = fakeClient({ rpc: () => START_OK })
  const d = deps(client, new FakeModelClient([]))
  assertEquals(
    (await handleRequest(post({ tenant_id: 'x', question: 'a' }), d)).status,
    400,
  )
  assertEquals((await handleRequest(post(good, {}), d)).status, 401)
  assertEquals(
    (await handleRequest(
      post(good),
      deps(
        fakeClient({
          user: null,
          rpc: () => START_OK,
        }),
        new FakeModelClient([]),
      ),
    )).status,
    401,
  )
  assertEquals(
    (await handleRequest(new Request('http://x', { method: 'GET' }), d)).status,
    405,
  )
  assertEquals(
    (await handleRequest(new Request('http://x', { method: 'OPTIONS' }), d))
      .status,
    204,
  )
  const notJson = new Request('http://x', {
    method: 'POST',
    headers: { Authorization: 'Bearer j' },
    body: 'không phải json',
  })
  assertEquals((await handleRequest(notJson, d)).status, 400)
})

Deno.test('getUser nhận token đã bỏ tiền tố Bearer', async () => {
  const tokens: (string | undefined)[] = []
  const client = fakeClient({ tokens, rpc: (_s, fn) => (fn === 'start_question' ? START_OK : { data: null }) })
  await handleRequest(
    post(good, { Authorization: 'Bearer abc.def.ghi' }),
    deps(client, new FakeModelClient([text('Chào bạn!')])),
  )
  assertEquals(tokens, ['abc.def.ghi'])
})

Deno.test('claude_config_passed: mặc định haiku/low; CLAUDE_MODEL, CLAUDE_EFFORT ghi đè', async () => {
  const seen: { model: string; effort: string }[] = []
  const client = fakeClient({ rpc: (_s, fn) => (fn === 'start_question' ? START_OK : { data: null }) })
  const make = (env: Record<string, string>) => ({
    ...deps(client, new FakeModelClient([text('Chào bạn!')]), env),
    makeModel: (cfg: { model: string; effort: string }) => {
      seen.push({ model: cfg.model, effort: cfg.effort })
      return new FakeModelClient([text('Chào bạn!')])
    },
  })
  await handleRequest(post(good), make({ ANTHROPIC_API_KEY: 'k' }))
  await handleRequest(
    post(good),
    make({ ANTHROPIC_API_KEY: 'k', CLAUDE_MODEL: 'model-khac', CLAUDE_EFFORT: 'medium' }),
  )
  assertEquals(seen, [{ model: 'claude-haiku-5-5', effort: 'low' }, { model: 'model-khac', effort: 'medium' }])
})

Deno.test('log lỗi model ghi message (mã HTTP) nhưng không lộ câu hỏi hay khoá', async () => {
  const logged: string[] = []
  const original = console.error
  console.error = (...args: unknown[]) => logged.push(args.map(String).join(' '))
  try {
    const secret = 'CÂU-HỎI-RIÊNG-TƯ'
    const q = { tenant_id: T, question: secret }
    const client = fakeClient({ rpc: (_s, fn) => (fn === 'start_question' ? START_OK : { data: null }) })
    await handleRequest(
      post(q),
      deps(client, new FakeModelClient([new ModelError('Claude HTTP 404')]), { ANTHROPIC_API_KEY: 'KHOÁ-BÍ-MẬT' }),
    )
    await handleRequest(
      post(q),
      deps(client, new FakeModelClient([new ModelBusyError('Claude bận (429)')]), {
        ANTHROPIC_API_KEY: 'KHOÁ-BÍ-MẬT',
      }),
    )
  } finally {
    console.error = original
  }
  const all = logged.join('\n')
  assertEquals(all.includes('Claude HTTP 404'), true)
  assertEquals(all.includes('429'), true)
  assertEquals(all.includes('CÂU-HỎI-RIÊNG-TƯ'), false)
  assertEquals(all.includes('KHOÁ-BÍ-MẬT'), false)
})

Deno.test('preflight cho phép header x-vet45-app mà app gắn vào mọi request', async () => {
  const res = await handleRequest(
    new Request('http://x', { method: 'OPTIONS' }),
    deps(fakeClient({ rpc: () => rpcErr('X') }), new FakeModelClient([])),
  )
  const allowed = (res.headers.get('Access-Control-Allow-Headers') ?? '').split(',').map((h) => h.trim())
  for (const h of ['authorization', 'apikey', 'content-type', 'x-client-info', 'x-vet45-app']) {
    assertEquals(allowed.includes(h), true, h)
  }
})
