import { grossProfitTool } from './gross_profit.ts'
import { salesStatsTool } from './sales_stats.ts'
import { searchTool } from './search.ts'
import { stockMovementTool, stockOverviewTool } from './stock.ts'
import type { Tool } from './tool.ts'
import { unsupportedTool } from './unsupported.ts'

// AI-3 thêm du_bao_ban_hang vào đây.
export function buildTools(): Tool[] {
  return [
    salesStatsTool,
    stockOverviewTool,
    stockMovementTool,
    grossProfitTool,
    searchTool,
    unsupportedTool,
  ]
}

export function findTool(tools: Tool[], name: string): Tool | undefined {
  return tools.find((t) => t.declaration.name === name)
}
