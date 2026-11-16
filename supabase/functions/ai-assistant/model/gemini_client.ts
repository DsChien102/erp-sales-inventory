import {
  ModelBusyError,
  type ModelClient,
  ModelError,
  type ModelResult,
  type ModelTurn,
  type ToolDeclaration,
} from './model_client.ts'

type GeminiResponse = {
  error?: { status?: string }
  candidates?: { content?: { parts?: Part[] }; finishReason?: string }[]
  usageMetadata?: { promptTokenCount?: number; candidatesTokenCount?: number }
}

const BASE_URL = 'https://generativelanguage.googleapis.com/v1beta/models'

type Part = {
  text?: string
  functionCall?: { name: string; args?: Record<string, unknown> }
  [k: string]: unknown
}

function toContents(turns: ModelTurn[]): unknown[] {
  return turns.map((t) => {
    switch (t.role) {
      case 'user':
        return { role: 'user', parts: [{ text: t.text }] }
      case 'model':
        // nguyên văn: giữ thoughtSignature trong part functionCall
        return t.raw
      case 'tool_results':
        return {
          role: 'user',
          parts: t.results.map((r) => ({
            functionResponse: {
              name: r.name,
              // Gemini yêu cầu response là đối tượng
              response: r.response !== null && typeof r.response === 'object' &&
                  !Array.isArray(r.response)
                ? r.response
                : { ket_qua: r.response },
            },
          })),
        }
    }
  })
}

export class GeminiClient implements ModelClient {
  readonly #apiKey: string
  readonly #model: string
  readonly #fetch: typeof fetch

  constructor(o: { apiKey: string; model: string; fetch?: typeof fetch }) {
    this.#apiKey = o.apiKey
    this.#model = o.model
    this.#fetch = o.fetch ?? fetch
  }

  async generate(r: {
    system: string
    turns: ModelTurn[]
    tools: ToolDeclaration[]
    signal?: AbortSignal
  }): Promise<ModelResult> {
    const body: Record<string, unknown> = {
      systemInstruction: { parts: [{ text: r.system }] },
      contents: toContents(r.turns),
      generationConfig: { temperature: 0.2 },
    }
    if (r.tools.length > 0) body.tools = [{ functionDeclarations: r.tools }]

    const res = await this.#fetch(
      `${BASE_URL}/${this.#model}:generateContent`,
      {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          'x-goog-api-key': this.#apiKey,
        },
        body: JSON.stringify(body),
        signal: r.signal,
      },
    )

    let data: GeminiResponse | null = null
    try {
      data = await res.json()
    } catch {
      // thân không phải JSON
    }

    if (res.status === 429 || data?.error?.status === 'RESOURCE_EXHAUSTED') {
      throw new ModelBusyError('Gemini hết hạn mức (429)')
    }
    if (!res.ok) {
      throw new ModelError(`Gemini HTTP ${res.status}`)
    }

    const candidate = data?.candidates?.[0]
    if (!candidate) throw new ModelError('Gemini không trả candidate')
    if (candidate.finishReason === 'SAFETY') {
      throw new ModelError('Gemini chặn vì SAFETY')
    }
    const content = candidate.content
    if (!content) throw new ModelError('Gemini không trả content')

    const usage = {
      inputTokens: Number(data?.usageMetadata?.promptTokenCount ?? 0),
      outputTokens: Number(data?.usageMetadata?.candidatesTokenCount ?? 0),
    }

    const parts: Part[] = Array.isArray(content.parts) ? content.parts : []
    const calls = parts
      .filter((p) => p.functionCall)
      .map((p) => ({
        name: p.functionCall!.name,
        args: p.functionCall!.args ?? {},
      }))

    if (calls.length > 0) {
      return { kind: 'tool_calls', calls, raw: content, usage }
    }

    const text = parts.map((p) => (typeof p.text === 'string' ? p.text : ''))
      .join('')
    return { kind: 'text', text, raw: content, usage }
  }
}
