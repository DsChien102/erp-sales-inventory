import { MESSAGES } from './messages.ts'
import type { ModelClient, ModelTurn, Usage } from './model/model_client.ts'
import { findTool } from './tools/registry.ts'
import { RpcError, type Tool, type ToolContext } from './tools/tool.ts'
import type { Status, TableBlock, Turn } from './types.ts'

export const MAX_TOOL_CALLS = 3

export type OrchestratorResult = {
  status: Status
  answer: string
  blocks: TableBlock[]
  toolCalls: { name: string; args: Record<string, unknown>; ok: boolean }[]
  usage: Usage
}

export async function answerQuestion(i: {
  question: string
  history: Turn[]
  system: string
  model: ModelClient
  tools: Tool[]
  ctx: ToolContext
  signal?: AbortSignal
}): Promise<OrchestratorResult> {
  const turns: ModelTurn[] = i.history.map((t): ModelTurn =>
    t.role === 'user'
      ? { role: 'user', text: t.text }
      : { role: 'model', raw: { role: 'model', parts: [{ text: t.text }] } }
  )
  turns.push({ role: 'user', text: i.question })

  const declarations = i.tools.map((t) => t.declaration)
  const blocks: TableBlock[] = []
  const toolCalls: OrchestratorResult['toolCalls'] = []
  const usage: Usage = { inputTokens: 0, outputTokens: 0 }
  let dataCount = 0

  const finish = (
    status: Status,
    answer: string,
    withBlocks = true,
  ): OrchestratorResult => ({
    status,
    answer,
    blocks: withBlocks ? blocks : [],
    toolCalls,
    usage,
  })

  while (true) {
    const result = await i.model.generate({
      system: i.system,
      turns,
      tools: declarations,
      signal: i.signal,
    })
    usage.inputTokens += result.usage.inputTokens
    usage.outputTokens += result.usage.outputTokens

    if (result.kind === 'text') {
      const answer = result.text.trim()
      if (answer === '') return finish('loi', MESSAGES.loi)
      if (dataCount > 0) return finish('ok', answer)
      // Không có số liệu nào từ công cụ: câu trả lời có chữ số là bịa số ⇒ chặn.
      if (/\d/.test(answer)) {
        return finish('chua_ho_tro', MESSAGES.chua_ho_tro, false)
      }
      return finish(
        toolCalls.length === 0 ? 'tro_chuyen' : 'chua_ho_tro',
        answer,
        false,
      )
    }

    turns.push({ role: 'model', raw: result.raw })
    const results: { name: string; response: unknown }[] = []

    for (const call of result.calls) {
      if (toolCalls.length >= MAX_TOOL_CALLS) {
        return dataCount > 0 ? finish('ok', MESSAGES.qua_phuc_tap) : finish('chua_ho_tro', MESSAGES.chua_ho_tro, false)
      }

      const tool = findTool(i.tools, call.name)
      if (!tool) {
        toolCalls.push({ name: call.name, args: call.args, ok: false })
        results.push({
          name: call.name,
          response: { loi: 'khong_co_cong_cu' },
        })
        continue
      }

      try {
        const outcome = await tool.run(call.args, i.ctx)
        if (outcome.kind === 'unsupported') {
          toolCalls.push({ name: call.name, args: call.args, ok: true })
          return finish(outcome.status, MESSAGES[outcome.status], false)
        }
        if (outcome.kind === 'bad_args') {
          toolCalls.push({ name: call.name, args: call.args, ok: false })
          results.push({
            name: call.name,
            response: { loi: 'tham_so_sai', chi_tiet: outcome.chi_tiet },
          })
          continue
        }
        toolCalls.push({ name: call.name, args: call.args, ok: true })
        dataCount++
        if (outcome.block) blocks.push(outcome.block)
        results.push({ name: call.name, response: outcome.forModel })
      } catch (e) {
        toolCalls.push({ name: call.name, args: call.args, ok: false })
        if (e instanceof RpcError) {
          if (e.code === 'PERMISSION_DENIED') {
            return finish('khong_quyen', MESSAGES.khong_quyen, false)
          }
          results.push({
            name: call.name,
            response: { loi: 'khong_doc_duoc_du_lieu' },
          })
          continue
        }
        throw e
      }
    }

    turns.push({ role: 'tool_results', results })
  }
}
