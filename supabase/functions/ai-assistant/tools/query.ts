import { redactPersonal } from './redact.ts'
import { buildQueryBlock } from './query_table.ts'
import { asArray, isRecord, RpcError, type Tool, type ToolContext } from './tool.ts'

export type CatalogView = {
  view: string
  mo_ta: string
  cot: { ten: string; kieu: string; mo_ta: string }[]
}

const FIXED_DESCRIPTION = `Truy vấn số liệu cửa hàng bằng MỘT câu SQL SELECT (PostgreSQL) trên các view ai_read bên dưới, tối đa 50 dòng. CHỈ dùng khi không công cụ chuyên dụng nào khớp (liệt kê đơn, khách chưa mua, sản phẩm chưa bán, so sánh, kết hợp nhiều view…). (không dùng cho doanh thu / lãi gộp / dự báo thông thường — dùng công cụ chuyên dụng).
Quy tắc SQL: chỉ SELECT hoặc WITH…SELECT, một câu, không dấu ";" ở giữa, không chú thích (--, /* */), không ngoặc kép định danh; chỉ gọi hàm thông dụng (sum, count, avg, min, max, round, coalesce, date_trunc, to_char, extract, lower, upper, row_number, generate_series, …).
Tiền: cột *_vnd (đồng). Ngày: cột ngay_* (giờ Việt Nam); lọc kỳ bằng ngày, ví dụ ngay_ban >= current_date - 7. LUÔN chọn kèm cột khoá để người dùng bấm dòng mở màn: liệt kê đơn ⇒ thêm don_id; liệt kê sản phẩm ⇒ thêm san_pham_id; liệt kê khách ⇒ thêm khach_id (app tự ẩn các cột *_id khỏi bảng).
Doanh thu = sum(doanh_thu_vnd) của ban_hang_thuan (đã có dấu: trả / huỷ là số âm). Số đơn = đếm don_id của don_ban với trang_thai = 'hoan_tat'.
Khi join, đặt alias khác nhau cho các cột trùng tên (as ...). Câu SQL lỗi sẽ trả về chi tiết lỗi: sửa lại câu và gọi lại.`

function describeCatalog(views: CatalogView[]): string {
  return views.map((v) => {
    const cols = v.cot.map((c) => `  ${c.ten} (${c.kieu}): ${c.mo_ta}`).join('\n')
    return `${v.view} — ${v.mo_ta}\n${cols}`
  }).join('\n\n')
}

function parseCatalog(raw: unknown): CatalogView[] {
  return asArray(raw).map((v) => ({
    view: String(v.view ?? ''),
    mo_ta: String(v.mo_ta ?? ''),
    cot: asArray(v.cot).map((c) => ({
      ten: String(c.ten ?? ''),
      kieu: String(c.kieu ?? ''),
      mo_ta: String(c.mo_ta ?? ''),
    })),
  })).filter((v) => v.view !== '')
}

export function buildQueryTool(
  loadCatalog: (ctx: ToolContext) => Promise<CatalogView[]>,
): Tool {
  let loaded = false
  const declaration = {
    name: 'truy_van',
    description: FIXED_DESCRIPTION,
    parameters: {
      type: 'object',
      properties: {
        sql: {
          type: 'string',
          description: 'Một câu SELECT trên view ai_read, tối đa 50 dòng kết quả.',
        },
        tieu_de: {
          type: 'string',
          description: 'Tiêu đề ngắn cho bảng kết quả, ví dụ "Đơn hôm qua".',
        },
      },
      required: ['sql'],
    },
  }

  return {
    declaration,

    // Tải danh mục view một lần mỗi instance; lỗi thì giữ mô tả cố định, không làm hỏng công cụ khác.
    async prepare(ctx) {
      if (loaded) return
      try {
        const views = await loadCatalog(ctx)
        if (views.length > 0) {
          declaration.description = `${FIXED_DESCRIPTION}\n\nCác view:\n${describeCatalog(views)}`
          loaded = true
        }
      } catch {
        // giữ mô tả cố định; lần hỏi sau thử lại
      }
    },

    async run(args, ctx) {
      const sql = args.sql
      if (typeof sql !== 'string' || sql.trim() === '') {
        return { kind: 'bad_args', chi_tiet: 'thiếu sql (một câu SELECT trên view ai_read)' }
      }
      const title = typeof args.tieu_de === 'string' && args.tieu_de.trim() !== ''
        ? args.tieu_de.trim().slice(0, 80)
        : 'Kết quả'

      let res: unknown
      try {
        res = await ctx.rpc('ai', 'run_query', { p_tenant_id: ctx.tenantId, p_sql: sql })
      } catch (e) {
        if (e instanceof RpcError && e.code === 'CONTEXT_INVALID') {
          return { kind: 'bad_args', chi_tiet: e.message }
        }
        throw e
      }

      const r = isRecord(res) ? res : {}
      const cot = Array.isArray(r.cot) ? r.cot.map((c) => String(c)) : []
      const dong = asArray(r.dong)
      const biCat = r.bi_cat === true

      return {
        kind: 'data',
        forModel: redactPersonal({
          cot,
          dong,
          bi_cat: biCat,
          ...(biCat ? { ghi_chu: 'Kết quả bị cắt ở 50 dòng đầu.' } : {}),
        }),
        block: buildQueryBlock({ cot, dong }, title),
      }
    },
  }
}

export const queryTool: Tool = buildQueryTool(async (ctx) =>
  parseCatalog(await ctx.rpc('ai', 'get_catalog', {}))
)
