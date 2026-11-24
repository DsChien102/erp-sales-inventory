import type { TableBlock } from '../types.ts'
import { redactPersonal } from './redact.ts'
import { asArray, clampInt, isRecord, PERIOD_PROPERTIES, periodFromArgs, pickEnum, type Tool } from './tool.ts'

const CHE_DO = { san_pham: 'PRODUCT', don: 'ORDER' } as const

function num(v: unknown): number | null {
  const n = Number(v)
  return v === null || v === undefined || !Number.isFinite(n) ? null : n
}

export const grossProfitTool: Tool = {
  declaration: {
    name: 'lai_gop',
    description:
      'Báo cáo lãi gộp (doanh thu thuần trừ giá vốn) theo sản phẩm hoặc theo đơn. Chỉ chủ cửa hàng xem được. Dùng cho "lãi gộp tháng này", "mặt hàng nào lãi nhiều nhất".',
    parameters: {
      type: 'object',
      properties: {
        ...PERIOD_PROPERTIES,
        che_do: {
          type: 'string',
          enum: Object.keys(CHE_DO),
          description: 'san_pham (mặc định) hoặc don',
        },
        top_n: {
          type: 'integer',
          description: 'Số dòng tối đa (1-20, mặc định 10)',
        },
      },
    },
  },

  async run(args, ctx) {
    const mode = pickEnum(
      args.che_do,
      Object.keys(CHE_DO) as (keyof typeof CHE_DO)[],
      'che_do',
      'san_pham',
    )
    if (!mode.ok) return { kind: 'bad_args', chi_tiet: mode.chi_tiet }
    const period = periodFromArgs(args, ctx)
    if (!period.ok) return { kind: 'bad_args', chi_tiet: period.chi_tiet }
    const topN = clampInt(args.top_n, 1, 20, 10)

    // PERMISSION_DENIED từ RPC được ném tiếp (orchestrator bắt)
    const res = await ctx.rpc('inventory', 'get_gross_profit_report', {
      p_tenant_id: ctx.tenantId,
      p_from: period.range.from,
      p_to: period.range.to,
      p_mode: CHE_DO[mode.value],
    })
    const report = isRecord(res) ? res : {}
    const totals = isRecord(report.totals) ? report.totals : {}
    const all = asArray(report.rows)
    const top = [...all]
      .sort((a, b) => (num(b.gross_profit_vnd) ?? 0) - (num(a.gross_profit_vnd) ?? 0))
      .slice(0, topN)

    const isProduct = mode.value === 'san_pham'
    const dong = top.map((r) => ({
      nhan: isProduct ? r.name : r.order_code,
      doanh_thu_thuan: isProduct ? r.net_revenue_vnd : r.revenue_vnd,
      lai_gop: r.gross_profit_vnd,
      ty_le_pct: r.margin_pct ?? null,
    }))

    const block: TableBlock = {
      loai: 'bang',
      tieu_de: 'Lãi gộp',
      cot: [
        { khoa: 'nhan', ten: isProduct ? 'Sản phẩm' : 'Đơn', kieu: 'chu' },
        {
          khoa: 'doanh_thu',
          ten: isProduct ? 'Doanh thu thuần' : 'Doanh thu',
          kieu: 'tien',
        },
        { khoa: 'lai_gop', ten: 'Lãi gộp', kieu: 'tien' },
        { khoa: 'ty_le', ten: '%', kieu: 'phan_tram' },
      ],
      dong: top.map((r) => ({
        o: {
          nhan: String((isProduct ? r.name : r.order_code) ?? ''),
          doanh_thu: num(isProduct ? r.net_revenue_vnd : r.revenue_vnd),
          lai_gop: num(r.gross_profit_vnd),
          ty_le: num(r.margin_pct),
        },
        ...(isProduct && typeof r.product_id === 'string'
          ? { mo: { loai: 'san_pham' as const, id: r.product_id } }
          : !isProduct && typeof r.order_id === 'string'
          ? { mo: { loai: 'don_ban' as const, id: r.order_id } }
          : {}),
      })),
    }

    return {
      kind: 'data',
      forModel: redactPersonal({ ky: period.range, tong: totals, dong }),
      block,
    }
  },
}
