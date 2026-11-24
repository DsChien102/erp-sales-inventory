import { assert, assertEquals } from 'jsr:@std/assert@1'
import { FakeModelClient } from './model/fake_model_client.ts'
import type { ModelResult } from './model/model_client.ts'
import { MESSAGES } from './messages.ts'
import { answerQuestion, MAX_TOOL_CALLS } from './orchestrator.ts'
import { RpcError, type Tool, type ToolContext, type ToolOutcome } from './tools/tool.ts'
import type { TableBlock } from './types.ts'

const usage = { inputTokens: 10, outputTokens: 2 }
const ctx: ToolContext = {
  tenantId: 't',
  actorId: 'a',
  today: '2026-11-16',
  rpc: () => Promise.reject(new Error('rpc không được gọi trực tiếp')),
}

const BLOCK: TableBlock = { loai: 'bang', tieu_de: 'T', cot: [], dong: [] }

function tool(name: string, run: () => Promise<ToolOutcome>): Tool {
  return {
    declaration: { name, description: name, parameters: { type: 'object' } },
    run,
  }
}
const dataTool = (name = 'cong_cu_a') =>
  tool(
    name,
    () => Promise.resolve({ kind: 'data', forModel: { so: 5 }, block: BLOCK }),
  )

const calls = (...names: string[]): ModelResult => ({
  kind: 'tool_calls',
  calls: names.map((name) => ({ name, args: { x: 1 } })),
  raw: {
    role: 'model',
    parts: names.map((name) => ({
      functionCall: { name, args: { x: 1 } },
      thoughtSignature: 'sig',
    })),
  },
  usage,
})
const text = (t: string): ModelResult => ({
  kind: 'text',
  text: t,
  raw: { role: 'model', parts: [{ text: t }] },
  usage,
})

const ask = (
  model: FakeModelClient,
  tools: Tool[],
  extra: { history?: { role: 'user' | 'assistant'; text: string }[] } = {},
) =>
  answerQuestion({
    question: 'Hỏi',
    history: extra.history ?? [],
    system: 'SYS',
    model,
    tools,
    ctx,
  })

Deno.test('one_tool_then_text', async () => {
  const model = new FakeModelClient([calls('cong_cu_a'), text('Xong rồi.')])
  const r = await ask(model, [dataTool()])
  assertEquals(r.status, 'ok')
  assertEquals(r.answer, 'Xong rồi.')
  assertEquals(r.blocks, [BLOCK])
  assertEquals(r.toolCalls, [{ name: 'cong_cu_a', args: { x: 1 }, ok: true }])
  assertEquals(r.usage, { inputTokens: 20, outputTokens: 4 })
})

Deno.test('permission_denied_stops', async () => {
  const denied = tool(
    'lai_gop',
    () => Promise.reject(new RpcError('PERMISSION_DENIED', 'no')),
  )
  const model = new FakeModelClient([calls('lai_gop'), text('KHÔNG ĐƯỢC GỌI')])
  const r = await ask(model, [denied])
  assertEquals(r.status, 'khong_quyen')
  assertEquals(r.answer, MESSAGES.khong_quyen)
  assertEquals(r.blocks, [])
  assertEquals(model.requests.length, 1)
})

Deno.test('other RpcError is reported to model as khong_doc_duoc_du_lieu', async () => {
  const broken = tool(
    'cong_cu_a',
    () => Promise.reject(new RpcError('UNKNOWN', 'boom')),
  )
  const model = new FakeModelClient([
    calls('cong_cu_a'),
    text('Mình chưa đọc được dữ liệu.'),
  ])
  const r = await ask(model, [broken])
  const second = model.requests[1].turns.at(-1)
  assertEquals(second, {
    role: 'tool_results',
    results: [{
      name: 'cong_cu_a',
      response: { loi: 'khong_doc_duoc_du_lieu' },
    }],
  })
  assertEquals(r.toolCalls[0].ok, false)
  assertEquals(r.status, 'chua_ho_tro')
})

Deno.test('unsupported_out_of_scope', async () => {
  const u = tool(
    'bao_khong_ho_tro',
    () => Promise.resolve({ kind: 'unsupported', status: 'ngoai_pham_vi' }),
  )
  const model = new FakeModelClient([
    calls('bao_khong_ho_tro'),
    text('KHÔNG ĐƯỢC GỌI'),
  ])
  const r = await ask(model, [u])
  assertEquals(r.status, 'ngoai_pham_vi')
  assertEquals(r.answer, MESSAGES.ngoai_pham_vi)
  assertEquals(model.requests.length, 1)
})

Deno.test('unsupported tu_choi / chua_ho_tro dùng câu cố định tương ứng', async () => {
  for (const status of ['tu_choi', 'chua_ho_tro'] as const) {
    const u = tool(
      'bao_khong_ho_tro',
      () => Promise.resolve({ kind: 'unsupported', status }),
    )
    const r = await ask(new FakeModelClient([calls('bao_khong_ho_tro')]), [u])
    assertEquals([r.status, r.answer], [status, MESSAGES[status]])
  }
})

Deno.test('chitchat_without_numbers', async () => {
  const r = await ask(new FakeModelClient([text('Chào bạn!')]), [dataTool()])
  assertEquals(r.status, 'tro_chuyen')
  assertEquals(r.answer, 'Chào bạn!')
})

Deno.test('chitchat_with_numbers_blocked', async () => {
  const r = await ask(new FakeModelClient([text('Hôm nay bán 2.000.000đ')]), [
    dataTool(),
  ])
  assertEquals(r.status, 'chua_ho_tro')
  assertEquals(r.answer, MESSAGES.chua_ho_tro)
})

Deno.test('six_calls_capped_at_five', async () => {
  let runs = 0
  const t = tool('cong_cu_a', () => {
    runs++
    return Promise.resolve({ kind: 'data', forModel: {}, block: BLOCK })
  })
  const model = new FakeModelClient([
    calls('cong_cu_a', 'cong_cu_a', 'cong_cu_a', 'cong_cu_a', 'cong_cu_a', 'cong_cu_a'),
  ])
  const r = await ask(model, [t])
  assertEquals(MAX_TOOL_CALLS, 5)
  assertEquals(runs, 5)
  assertEquals(r.status, 'ok')
  assertEquals(r.answer, MESSAGES.qua_phuc_tap)
  assertEquals(r.blocks.length, 5)
})

Deno.test('cap across loops without any data ⇒ chua_ho_tro', async () => {
  const bad = tool(
    'cong_cu_a',
    () => Promise.resolve({ kind: 'bad_args', chi_tiet: 'sai' }),
  )
  const model = new FakeModelClient([
    calls('cong_cu_a', 'cong_cu_a'),
    calls('cong_cu_a', 'cong_cu_a'),
    calls('cong_cu_a', 'cong_cu_a'),
  ])
  const r = await ask(model, [bad])
  assertEquals(r.status, 'chua_ho_tro')
  assertEquals(r.toolCalls.length, 5)
})

Deno.test('bad_args_sent_back', async () => {
  let n = 0
  const t = tool(
    'cong_cu_a',
    () =>
      Promise.resolve(
        ++n === 1 ? { kind: 'bad_args', chi_tiet: 'chi_so lạ' } : { kind: 'data', forModel: {}, block: BLOCK },
      ),
  )
  const model = new FakeModelClient([
    calls('cong_cu_a'),
    calls('cong_cu_a'),
    text('Đây.'),
  ])
  const r = await ask(model, [t])
  assertEquals(model.requests[1].turns.at(-1), {
    role: 'tool_results',
    results: [{
      name: 'cong_cu_a',
      response: { loi: 'tham_so_sai', chi_tiet: 'chi_so lạ' },
    }],
  })
  assertEquals(r.status, 'ok')
  assertEquals(r.toolCalls.map((c) => c.ok), [false, true])
})

Deno.test('unknown_tool', async () => {
  const model = new FakeModelClient([
    calls('khong_ton_tai'),
    text('Mình chưa hỗ trợ câu này.'),
  ])
  const r = await ask(model, [dataTool()])
  assertEquals(model.requests[1].turns.at(-1), {
    role: 'tool_results',
    results: [{ name: 'khong_ton_tai', response: { loi: 'khong_co_cong_cu' } }],
  })
  assertEquals(r.toolCalls[0].ok, false)
})

Deno.test('history_assistant_is_text_turn', async () => {
  const model = new FakeModelClient([text('ok')])
  await ask(model, [dataTool()], {
    history: [{ role: 'user', text: 'Câu 1' }, {
      role: 'assistant',
      text: 'Trả lời 1',
    }],
  })
  assertEquals(model.requests[0].turns, [
    { role: 'user', text: 'Câu 1' },
    { role: 'model_text', text: 'Trả lời 1' },
    { role: 'user', text: 'Hỏi' },
  ])
  assertEquals(model.requests[0].system, 'SYS')
  assertEquals(model.requests[0].tools.map((t) => t.name), ['cong_cu_a'])
})

Deno.test('model_raw_kept', async () => {
  const first = calls('cong_cu_a')
  const model = new FakeModelClient([first, text('Xong.')])
  await ask(model, [dataTool()])
  const turns = model.requests[1].turns
  assertEquals(turns[1], {
    role: 'model',
    raw: (first as { raw: unknown }).raw,
  })
  assertEquals(turns[2].role, 'tool_results')
})

Deno.test('empty answer ⇒ loi', async () => {
  const r = await ask(new FakeModelClient([text('   ')]), [dataTool()])
  assertEquals(r.status, 'loi')
  assertEquals(r.answer, MESSAGES.loi)
})

Deno.test('lỗi model không bị bắt ở orchestrator', async () => {
  let thrown = false
  try {
    await ask(new FakeModelClient([new Error('boom')]), [dataTool()])
  } catch {
    thrown = true
  }
  assert(thrown)
})

Deno.test('chitchat_mentions_c45_not_blocked', async () => {
  const greet = 'Xin chào! Mình là Hỏi Mosaic Retail, giúp bạn xem số liệu cửa hàng.'
  const r = await ask(new FakeModelClient([text(greet)]), [dataTool()])
  assertEquals(r.status, 'tro_chuyen')
  assertEquals(r.answer, greet)
  // vẫn chặn khi có số thật
  const r2 = await ask(new FakeModelClient([text('Hỏi Mosaic Retail: hôm nay bán 2.000.000đ')]), [dataTool()])
  assertEquals(r2.status, 'chua_ho_tro')
})
