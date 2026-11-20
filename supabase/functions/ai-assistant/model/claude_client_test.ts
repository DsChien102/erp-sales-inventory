import { assert, assertEquals, assertRejects } from 'jsr:@std/assert@1'
import { ClaudeClient } from './claude_client.ts'
import { ModelBusyError, ModelError, type ModelTurn } from './model_client.ts'

const tools = [{ name: 'tim_kiem', description: 'd', parameters: { type: 'object', properties: {} } }]

function msg(content: unknown[], stop_reason = 'end_turn') {
  return {
    id: 'msg_1',
    type: 'message',
    role: 'assistant',
    model: 'claude-haiku-5-5',
    content,
    stop_reason,
    stop_sequence: null,
    usage: { input_tokens: 10, output_tokens: 5, cache_read_input_tokens: 3, cache_creation_input_tokens: 2 },
  }
}

function fakeFetch(responses: { status?: number; body: unknown }[]) {
  const bodies: Record<string, unknown>[] = []
  let i = 0
  const f = ((_u: unknown, init?: RequestInit) => {
    bodies.push(JSON.parse(String(init?.body)))
    const r = responses[Math.min(i++, responses.length - 1)]
    return Promise.resolve(
      new Response(JSON.stringify(r.body), {
        status: r.status ?? 200,
        headers: { 'content-type': 'application/json', 'retry-after-ms': '1' },
      }),
    )
  }) as typeof fetch
  return { f, bodies }
}

function client(responses: { status?: number; body: unknown }[]) {
  const { f, bodies } = fakeFetch(responses)
  return { c: new ClaudeClient({ apiKey: 'k', model: 'claude-haiku-5-5', effort: 'low', fetch: f }), bodies }
}

const gen = (c: ClaudeClient, turns: ModelTurn[], signal?: AbortSignal) =>
  c.generate({ system: 'SYS', turns, tools, signal })

Deno.test('claude_request_shape', async () => {
  const { c, bodies } = client([{ body: msg([{ type: 'text', text: 'Chào' }]) }])
  await gen(c, [{ role: 'user', text: 'a' }])
  const b = bodies[0]
  assertEquals(b.model, 'claude-haiku-5-5')
  assertEquals(b.output_config, { effort: 'low' })
  assertEquals(b.cache_control, { type: 'ephemeral' })
  assertEquals((b.tools as { input_schema: unknown }[])[0].input_schema, tools[0].parameters)
  assertEquals(b.system, 'SYS')
  assert(!('temperature' in b) && !('thinking' in b))
})

Deno.test('claude_text_answer', async () => {
  const { c } = client([{ body: msg([{ type: 'text', text: 'Chào' }]) }])
  const r = await gen(c, [{ role: 'user', text: 'a' }])
  assertEquals(r.kind, 'text')
  assertEquals(r.kind === 'text' && r.text, 'Chào')
  assertEquals(r.usage, { inputTokens: 15, outputTokens: 5 })
})

Deno.test('claude_text_and_tool_use_is_tool_calls', async () => {
  const content = [
    { type: 'text', text: 'Để mình xem' },
    { type: 'tool_use', id: 't1', name: 'tim_kiem', input: { tu_khoa: 'a' } },
  ]
  const { c } = client([{ body: msg(content, 'tool_use') }])
  const r = await gen(c, [{ role: 'user', text: 'a' }])
  assertEquals(r.kind, 'tool_calls')
  if (r.kind === 'tool_calls') {
    assertEquals(r.calls, [{ name: 'tim_kiem', args: { tu_khoa: 'a' } }])
    assertEquals(r.raw, content)
  }
})

Deno.test('claude_tool_results_match_ids', async () => {
  const raw = [
    { type: 'thinking', thinking: '', signature: 's' },
    { type: 'tool_use', id: 't1', name: 'tim_kiem', input: {} },
    { type: 'tool_use', id: 't2', name: 'tim_kiem', input: { x: 1 } },
  ]
  const { c, bodies } = client([{ body: msg([{ type: 'text', text: 'ok' }]) }])
  await gen(c, [
    { role: 'user', text: 'a' },
    { role: 'model', raw },
    {
      role: 'tool_results',
      results: [{ name: 'tim_kiem', response: { a: 1 } }, { name: 'tim_kiem', response: { b: 2 } }],
    },
  ])
  const m = bodies[0].messages as { role: string; content: unknown }[]
  assertEquals(m[1], { role: 'assistant', content: raw })
  assertEquals(m[2], {
    role: 'user',
    content: [
      { type: 'tool_result', tool_use_id: 't1', content: '{"a":1}' },
      { type: 'tool_result', tool_use_id: 't2', content: '{"b":2}' },
    ],
  })
})

Deno.test('claude_maps_model_text', async () => {
  const { c, bodies } = client([{ body: msg([{ type: 'text', text: 'x' }]) }])
  await gen(c, [{ role: 'user', text: 'a' }, { role: 'model_text', text: 'b' }, { role: 'user', text: 'c' }])
  assertEquals((bodies[0].messages as unknown[])[1], { role: 'assistant', content: 'b' })
})

Deno.test('claude_refusal_is_model_error', async () => {
  const t: ModelTurn[] = [{ role: 'user', text: 'a' }]
  await assertRejects(
    () => gen(client([{ body: msg([], 'refusal') }]).c, t),
    ModelError,
  )
  await assertRejects(
    () => gen(client([{ body: msg([{ type: 'text', text: 'cụt' }], 'max_tokens') }]).c, t),
    ModelError,
  )
})

Deno.test('claude_429_529_busy', async () => {
  const t: ModelTurn[] = [{ role: 'user', text: 'a' }]
  const err = (type: string) => ({ type: 'error', error: { type, message: 'm' } })
  await assertRejects(
    () => gen(client([{ status: 429, body: err('rate_limit_error') }]).c, t),
    ModelBusyError,
  )
  await assertRejects(
    () => gen(client([{ status: 529, body: err('overloaded_error') }]).c, t),
    ModelBusyError,
  )
  await assertRejects(
    () => gen(client([{ status: 400, body: err('invalid_request_error') }]).c, t),
    ModelError,
  )
})

Deno.test('claude_user_abort_rethrown', async () => {
  const ac = new AbortController()
  ac.abort()
  const e = await assertRejects(() => gen(client([{ body: msg([]) }]).c, [{ role: 'user', text: 'a' }], ac.signal))
  assert(!(e instanceof ModelError) && !(e instanceof ModelBusyError))
})

Deno.test('claude_history_normalized', async () => {
  const { c, bodies } = client([{ body: msg([{ type: 'text', text: 'ok' }]) }])
  await gen(c, [
    { role: 'model_text', text: 'x' },
    { role: 'user', text: 'a' },
    { role: 'user', text: 'b' },
    { role: 'model_text', text: '  ' },
    { role: 'model_text', text: 'c' },
    { role: 'user', text: 'q' },
  ])
  assertEquals(bodies[0].messages, [
    { role: 'user', content: 'a\n\nb' },
    { role: 'assistant', content: 'c' },
    { role: 'user', content: 'q' },
  ])
})

Deno.test('claude_error_type_in_message', async () => {
  const { c } = client([{
    status: 400,
    body: { type: 'error', error: { type: 'invalid_request_error', message: 'credit balance too low' } },
  }])
  const e = await assertRejects(() => gen(c, [{ role: 'user', text: 'a' }]), ModelError)
  assert(e.message.includes('400'))
  assert(e.message.includes('invalid_request_error'))
})
