import { forecastTool } from './forecast.ts'
import { grossProfitTool } from './gross_profit.ts'
import { queryTool } from './query.ts'
import { salesStatsTool } from './sales_stats.ts'
import { searchTool } from './search.ts'
import { stockMovementTool, stockOverviewTool } from './stock.ts'
import type { Tool } from './tool.ts'
import { unsupportedTool } from './unsupported.ts'

export function buildTools(): Tool[] {
  return [
    salesStatsTool,
    stockOverviewTool,
    stockMovementTool,
    forecastTool,
    grossProfitTool,
    searchTool,
    queryTool,
    unsupportedTool,
  ]
}

export function findTool(tools: Tool[], name: string): Tool | undefined {
  return tools.find((t) => t.declaration.name === name)
}
