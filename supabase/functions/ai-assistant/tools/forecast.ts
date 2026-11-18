import type { TableBlock } from '../types.ts'
import { redactPersonal } from './redact.ts'
import { asArray, isRecord, type Tool, UUID_RE } from './tool.ts'

function num(v: unknown): number | null {
  if (v === null || v === undefined || v === '') return null
  const n = Number(v)
  return Number.isFinite(n) ? n : null
}

export const forecastTool: Tool = {
  declaration: {
    name: 'du_bao_ban_hang',
    description:
      'Dự báo nhập hàng từ tốc độ bán 8 tuần gần nhất: mỗi sản phẩm còn bán được mấy ngày và nên nhập bao nhiêu. CHỈ dùng khi hỏi "nên nhập gì / nhập bao nhiêu", "còn bán được mấy ngày". Hỏi danh sách tồn thuần ("hàng nào sắp hết", "còn bao nhiêu") thì dùng tinh_hinh_ton_kho. Kết quả dự báo đã có sẵn cột tồn, nên KHÔNG gọi thêm tinh_hinh_ton_kho cho cùng một câu hỏi. Mọi con số lấy nguyên từ kết quả. Hàng chưa đặt ngưỡng chỉ có số ngày còn bán, không có lượng nên nhập (nói là chưa đặt ngưỡng, không tự bịa).',
    parameters: {
      type: 'object',
      properties: {
        san_pham_id: {
          type: 'string',
          description: 'uuid sản phẩm (tuỳ chọn), lấy từ tim_kiem; có thì chỉ dự báo sản phẩm đó',
        },
        chi_hang_can_nhap: {
          type: 'boolean',
          description: 'true (mặc định) = chỉ hàng đã chạm ngưỡng cần nhập; false = mọi sản phẩm',
        },
      },
    },
  },

  async run(args, ctx) {
    const id = args.san_pham_id
    if (id !== undefined && id !== null && (typeof id !== 'string' || !UUID_RE.test(id))) {
      return {
        kind: 'bad_args',
        chi_tiet: 'san_pham_id phải là uuid; hãy gọi tim_kiem (loai = san_pham) trước để lấy id',
      }
    }
    const rpcArgs: Record<string, unknown> = { p_tenant_id: ctx.tenantId }
    if (typeof id === 'string') {
      rpcArgs.p_product_id = id
    } else {
      rpcArgs.p_product_id = null
      rpcArgs.p_only_need_reorder = args.chi_hang_can_nhap === false ? false : true
    }
    rpcArgs.p_limit = 20

    const res = await ctx.rpc('inventory', 'get_purchase_forecast', rpcArgs)
    const root = isRecord(res) ? res : {}
    const rows = asArray(root.rows)

    const dong = rows.map((r) => {
      const threshold = num(r.reorder_threshold)
      const target = num(r.target_level)
      return {
        ten: r.name,
        ma: r.code,
        ton: num(r.available) ?? 0,
        dvt: r.uom,
        ban_moi_ngay: num(r.daily_rate) ?? 0,
        con_ban_ngay: num(r.days_left),
        nen_nhap: num(r.suggest_qty),
        ...(threshold !== null ? { nguong: threshold } : { chua_dat_nguong: true as const }),
        ...(target !== null ? { muc_ton_muc_tieu: target } : {}),
      }
    })
    const forModel = redactPersonal({
      so_hang_can_nhap: num(root.need_reorder_count) ?? 0,
      dong,
    })

    if (rows.length === 0) return { kind: 'data', forModel }

    const block: TableBlock = {
      loai: 'bang',
      tieu_de: 'Dự báo nhập hàng',
      cot: [
        { khoa: 'san_pham', ten: 'Sản phẩm', kieu: 'chu' },
        { khoa: 'ton', ten: 'Tồn', kieu: 'so' },
        { khoa: 'ban_moi_ngay', ten: 'Bán/ngày', kieu: 'so' },
        { khoa: 'con_ban_ngay', ten: 'Còn bán (ngày)', kieu: 'so' },
        { khoa: 'nen_nhap', ten: 'Nên nhập', kieu: 'so' },
      ],
      dong: rows.map((r) => ({
        o: {
          san_pham: String(r.name ?? ''),
          ton: num(r.available) ?? 0,
          ban_moi_ngay: num(r.daily_rate) ?? 0,
          con_ban_ngay: num(r.days_left),
          nen_nhap: num(r.suggest_qty),
        },
        ...(typeof r.product_id === 'string' ? { mo: { loai: 'san_pham' as const, id: r.product_id } } : {}),
      })),
    }
    return { kind: 'data', forModel, block }
  },
}
