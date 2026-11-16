import type { TableBlock } from '../types.ts'
import { redactPersonal } from './redact.ts'
import { asArray, clampInt, isRecord, pickEnum, type Tool } from './tool.ts'

const LOAI = ['san_pham', 'khach_hang', 'don_ban'] as const

function num(v: unknown): number | null {
  const n = Number(v)
  return v === null || v === undefined || !Number.isFinite(n) ? null : n
}

export const searchTool: Tool = {
  declaration: {
    name: 'tim_kiem',
    description:
      'Tìm sản phẩm, khách hàng hoặc đơn bán theo từ khoá (tên, mã). Dùng để lấy id trước khi gọi công cụ khác, hoặc trả lời "tìm khách tên Lan", "đơn HD0012 của ai".',
    parameters: {
      type: 'object',
      properties: {
        loai: { type: 'string', enum: [...LOAI], description: 'Loại cần tìm' },
        tu_khoa: {
          type: 'string',
          description: 'Tên, mã sản phẩm / khách / đơn',
        },
        gioi_han: {
          type: 'integer',
          description: 'Số kết quả tối đa (1-5, mặc định 5)',
        },
      },
      required: ['loai', 'tu_khoa'],
    },
  },

  async run(args, ctx) {
    const loai = pickEnum(args.loai, LOAI, 'loai')
    if (!loai.ok) return { kind: 'bad_args', chi_tiet: loai.chi_tiet }
    const keyword = typeof args.tu_khoa === 'string' ? args.tu_khoa.trim() : ''
    if (!keyword) return { kind: 'bad_args', chi_tiet: 'thiếu tu_khoa' }
    const limit = clampInt(args.gioi_han, 1, 5, 5)

    if (loai.value === 'san_pham') {
      const res = await ctx.rpc('catalog', 'search_products', {
        p_tenant_id: ctx.tenantId,
        p_keyword: keyword,
        p_limit: limit,
      })
      const rows = asArray(res).slice(0, limit)
      const items = rows.map((r) => ({
        id: r.product_id,
        ten: r.name,
        ma: r.sku ?? '',
        ton: num(r.stock_qty),
        dvt: r.base_unit_name ?? '',
      }))
      const block: TableBlock = {
        loai: 'bang',
        tieu_de: 'Sản phẩm tìm thấy',
        cot: [
          { khoa: 'ten', ten: 'Sản phẩm', kieu: 'chu' },
          { khoa: 'ma', ten: 'Mã', kieu: 'chu' },
          { khoa: 'ton', ten: 'Tồn', kieu: 'so' },
        ],
        dong: items.map((i) => ({
          o: { ten: String(i.ten ?? ''), ma: String(i.ma), ton: i.ton },
          ...(typeof i.id === 'string' ? { mo: { loai: 'san_pham' as const, id: i.id } } : {}),
        })),
      }
      return {
        kind: 'data',
        forModel: redactPersonal({ ket_qua: items }),
        block,
      }
    }

    if (loai.value === 'khach_hang') {
      const res = await ctx.rpc('partner', 'search_partners', {
        p_tenant_id: ctx.tenantId,
        p_query: keyword,
        p_role: 'customer',
        p_limit: limit,
      })
      // RPC trả bảng 1 dòng { items, page, limit, total }
      const first = Array.isArray(res) ? res[0] : res
      const list = asArray(isRecord(first) ? first.items : null).slice(
        0,
        limit,
      )
      const items = list.map((r) => ({
        id: r.partner_id ?? r.id,
        ten: r.display_name ?? r.name,
      }))
      const block: TableBlock = {
        loai: 'bang',
        tieu_de: 'Khách hàng tìm thấy',
        cot: [{ khoa: 'ten', ten: 'Khách hàng', kieu: 'chu' }],
        dong: items.map((i) => ({
          o: { ten: String(i.ten ?? '') },
          ...(typeof i.id === 'string' ? { mo: { loai: 'khach_hang' as const, id: i.id } } : {}),
        })),
      }
      return {
        kind: 'data',
        forModel: redactPersonal({ ket_qua: items }),
        block,
      }
    }

    const res = await ctx.rpc('sales', 'search_sales_orders', {
      query_id: crypto.randomUUID(),
      tenant_id: ctx.tenantId,
      actor_id: ctx.actorId,
      search_text: keyword,
      page_size: limit,
    })
    const orders = asArray(isRecord(res) ? res.items : null).slice(0, limit)
    const items = orders.map((o) => {
      const customer = isRecord(o.customer) ? o.customer : {}
      const total = isRecord(o.total) ? o.total : {}
      return {
        id: o.salesOrderId,
        ma: o.orderNumber,
        khach: customer.displayName ?? null,
        tong_tien: num(total.amountMinor),
        ngay: typeof o.committedAt === 'string' ? o.committedAt.slice(0, 10) : null,
      }
    })
    const block: TableBlock = {
      loai: 'bang',
      tieu_de: 'Đơn bán tìm thấy',
      cot: [
        { khoa: 'ma', ten: 'Mã đơn', kieu: 'chu' },
        { khoa: 'khach', ten: 'Khách', kieu: 'chu' },
        { khoa: 'tong_tien', ten: 'Tổng tiền', kieu: 'tien' },
        { khoa: 'ngay', ten: 'Ngày', kieu: 'ngay' },
      ],
      dong: items.map((i) => ({
        o: {
          ma: String(i.ma ?? ''),
          khach: i.khach === null ? 'Khách lẻ' : String(i.khach),
          tong_tien: i.tong_tien,
          ngay: i.ngay,
        },
        ...(typeof i.id === 'string' ? { mo: { loai: 'don_ban' as const, id: i.id } } : {}),
      })),
    }
    return {
      kind: 'data',
      forModel: redactPersonal({ ket_qua: items }),
      block,
    }
  },
}
