import { assert, assertEquals, assertInstanceOf, assertRejects } from 'jsr:@std/assert@1'
import { GeminiClient } from './gemini_client.ts'
import { ModelBusyError, ModelError, type ToolDeclaration } from './model_client.ts'

type Captured = {
  url: string
  headers: Headers
  body: Record<string, unknown>
}

function fakeFetch(
  respond: () => Response,
  captured: Captured[] = [],
): { fetch: typeof fetch; captured: Captured[] } {
  const f = (
    input: string | URL | Request,
    init?: RequestInit,
  ): Promise<Response> => {
    captured.push({
      url: String(input),
      headers: new Headers(init?.headers),
      body: JSON.parse(String(init?.body ?? '{}')),
    })
    return Promise.resolve(respond())
  }
  return { fetch: f as typeof fetch, captured }
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  })

const textReply = (text: string) => ({
  candidates: [{
    content: { role: 'model', parts: [{ text }] },
    finishReason: 'STOP',
  }],
  usageMetadata: { promptTokenCount: 11, candidatesTokenCount: 5 },
})

const TOOL: ToolDeclaration = {
  name: 'thong_ke_ban_hang',
  description: 'Thống kê bán hàng',
  parameters: { type: 'object', properties: { ky: { type: 'string' } } },
}

function client(f: typeof fetch) {
  return new GeminiClient({ apiKey: 'KEY', model: 'gemini-test', fetch: f })
}

Deno.test('sends_system_tools_and_key', async () => {
  const { fetch: f, captured } = fakeFetch(() => json(textReply('xin chào')))
  const r = await client(f).generate({
    system: 'SYS',
    turns: [{ role: 'user', text: 'Chào' }],
    tools: [TOOL],
  })
  assertEquals(r.kind, 'text')
  const c = captured[0]
  assert(c.url.includes('/models/gemini-test:generateContent'))
  assertEquals(c.headers.get('x-goog-api-key'), 'KEY')
  assertEquals(
    (c.body.systemInstruction as { parts: { text: string }[] }).parts[0].text,
    'SYS',
  )
  assertEquals(c.body.tools, [{ functionDeclarations: [TOOL] }])
  assertEquals(c.body.contents, [{ role: 'user', parts: [{ text: 'Chào' }] }])
  assertEquals(
    (c.body.generationConfig as { temperature: number }).temperature,
    0.2,
  )
})

Deno.test('omits_tools_when_empty', async () => {
  const { fetch: f, captured } = fakeFetch(() => json(textReply('ok')))
  await client(f).generate({
    system: 's',
    turns: [{ role: 'user', text: 'a' }],
    tools: [],
  })
  assertEquals('tools' in captured[0].body, false)
})

Deno.test('parses_function_calls', async () => {
  const content = {
    role: 'model',
    parts: [
      { functionCall: { name: 'a', args: { x: 1 } } },
      { functionCall: { name: 'b', args: {} } },
    ],
  }
  const { fetch: f } = fakeFetch(() =>
    json({
      candidates: [{ content }],
      usageMetadata: { promptTokenCount: 3, candidatesTokenCount: 2 },
    })
  )
  const r = await client(f).generate({
    system: 's',
    turns: [{ role: 'user', text: 'a' }],
    tools: [TOOL],
  })
  assertEquals(r.kind, 'tool_calls')
  if (r.kind !== 'tool_calls') throw new Error('unreachable')
  assertEquals(r.calls, [{ name: 'a', args: { x: 1 } }, {
    name: 'b',
    args: {},
  }])
  assertEquals(r.raw, content)
  assertEquals(r.usage, { inputTokens: 3, outputTokens: 2 })
})

Deno.test('replays_model_raw_verbatim', async () => {
  const raw = {
    role: 'model',
    parts: [{ functionCall: { name: 'a', args: {} }, thoughtSignature: 'abc' }],
  }
  const { fetch: f, captured } = fakeFetch(() => json(textReply('xong')))
  await client(f).generate({
    system: 's',
    turns: [
      { role: 'user', text: 'hỏi' },
      { role: 'model', raw },
      {
        role: 'tool_results',
        results: [{ name: 'a', response: { ok: true } }],
      },
    ],
    tools: [TOOL],
  })
  const contents = captured[0].body.contents as unknown[]
  assertEquals(contents[1], raw)
})

Deno.test('maps_tool_results_to_function_response', async () => {
  const { fetch: f, captured } = fakeFetch(() => json(textReply('xong')))
  await client(f).generate({
    system: 's',
    turns: [
      {
        role: 'tool_results',
        results: [{ name: 'a', response: { tong: 5 } }, {
          name: 'b',
          response: [1, 2],
        }],
      },
    ],
    tools: [],
  })
  assertEquals((captured[0].body.contents as unknown[])[0], {
    role: 'user',
    parts: [
      { functionResponse: { name: 'a', response: { tong: 5 } } },
      { functionResponse: { name: 'b', response: { ket_qua: [1, 2] } } },
    ],
  })
})

Deno.test('429_is_busy', async () => {
  const { fetch: f } = fakeFetch(() => json({ error: { status: 'RESOURCE_EXHAUSTED' } }, 429))
  const err = await assertRejects(() =>
    client(f).generate({
      system: 's',
      turns: [{ role: 'user', text: 'a' }],
      tools: [],
    })
  )
  assertInstanceOf(err, ModelBusyError)
})

Deno.test('resource_exhausted_status_is_busy', async () => {
  const { fetch: f } = fakeFetch(() => json({ error: { status: 'RESOURCE_EXHAUSTED' } }, 400))
  const err = await assertRejects(() =>
    client(f).generate({
      system: 's',
      turns: [{ role: 'user', text: 'a' }],
      tools: [],
    })
  )
  assertInstanceOf(err, ModelBusyError)
})

Deno.test('500_is_model_error', async () => {
  const { fetch: f } = fakeFetch(() => json({ error: { message: 'boom' } }, 500))
  const err = await assertRejects(() =>
    client(f).generate({
      system: 's',
      turns: [{ role: 'user', text: 'a' }],
      tools: [],
    })
  )
  assertInstanceOf(err, ModelError)
  assert(!(err instanceof ModelBusyError))
})

Deno.test('safety_is_model_error', async () => {
  const { fetch: f } = fakeFetch(() => json({ candidates: [{ finishReason: 'SAFETY' }] }))
  const err = await assertRejects(() =>
    client(f).generate({
      system: 's',
      turns: [{ role: 'user', text: 'a' }],
      tools: [],
    })
  )
  assertInstanceOf(err, ModelError)
})

Deno.test('no_candidate_is_model_error', async () => {
  const { fetch: f } = fakeFetch(() => json({ candidates: [] }))
  await assertRejects(
    () =>
      client(f).generate({
        system: 's',
        turns: [{ role: 'user', text: 'a' }],
        tools: [],
      }),
    ModelError,
  )
})

Deno.test('usage_defaults_zero', async () => {
  const { fetch: f } = fakeFetch(() =>
    json({
      candidates: [{
        content: { role: 'model', parts: [{ text: 'a' }, { text: 'b' }] },
      }],
    })
  )
  const r = await client(f).generate({
    system: 's',
    turns: [{ role: 'user', text: 'a' }],
    tools: [],
  })
  assertEquals(r.usage, { inputTokens: 0, outputTokens: 0 })
  assertEquals(r.kind === 'text' ? r.text : null, 'ab')
})
