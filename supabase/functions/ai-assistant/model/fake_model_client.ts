import type { ModelClient, ModelResult, ModelTurn, ToolDeclaration } from './model_client.ts'

export class FakeModelClient implements ModelClient {
  readonly requests: {
    system: string
    turns: ModelTurn[]
    tools: ToolDeclaration[]
  }[] = []
  #script: (ModelResult | Error)[]

  constructor(script: (ModelResult | Error)[]) {
    this.#script = [...script]
  }

  generate(
    r: { system: string; turns: ModelTurn[]; tools: ToolDeclaration[] },
  ): Promise<ModelResult> {
    // chụp bản sao: orchestrator có thể đẩy thêm turn vào mảng sau này
    this.requests.push({
      system: r.system,
      turns: structuredClone(r.turns),
      tools: r.tools,
    })
    const next = this.#script.shift()
    if (next === undefined) {
      return Promise.reject(new Error('FakeModelClient: hết kịch bản'))
    }
    if (next instanceof Error) return Promise.reject(next)
    return Promise.resolve(next)
  }
}
