export type ToolDeclaration = {
  name: string
  description: string
  parameters: Record<string, unknown> // JSON Schema (OpenAPI subset)
}

export type ToolCall = { name: string; args: Record<string, unknown> }

export type ModelTurn =
  | { role: 'user'; text: string }
  | { role: 'model_text'; text: string } // lượt trả lời cũ trong history (chỉ chữ)
  | { role: 'model'; raw: unknown } // nguyên văn content model trả (giữ thinking/tool_use)
  | { role: 'tool_results'; results: { name: string; response: unknown }[] }

export type Usage = { inputTokens: number; outputTokens: number }

export type ModelResult =
  | { kind: 'text'; text: string; raw: unknown; usage: Usage }
  | { kind: 'tool_calls'; calls: ToolCall[]; raw: unknown; usage: Usage }

export interface ModelClient {
  generate(r: {
    system: string
    turns: ModelTurn[]
    tools: ToolDeclaration[]
    signal?: AbortSignal
  }): Promise<ModelResult>
}

/** 429 / hết hạn mức */
export class ModelBusyError extends Error {}
/** mọi lỗi khác */
export class ModelError extends Error {}
