import type { TableBlock } from '../types.ts'
import { redactPersonal } from './redact.ts'
import { asArray, clampInt, isRecord, PERIOD_PROPERTIES, periodFromArgs, pickEnum, type Tool, UUID_RE } from './tool.ts'

const LOC = ['tat_ca', 'sap_het', 'het_hang', 'can_han'] as const

/** bỏ dấu tiếng Việt, hạ chữ thường — để so khớp từ khoá */
export function fold(s: string): string {
  return s.normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/đ/g, 'd').replace(
    /Đ/g,
    'D',
  ).toLowerCase()
}

function num(v: unknown): number | null {
  if (v === null || v === undefined || v === '') return null
  const n = Number(v)
  return Number.isFinite(n) ? n : null
}

export const stockOverviewTool: Tool = {
  declaration: {
    name: 'tinh_hinh_ton_kho',
    description:
      'Xem tồn kho hiện tại: tất cả, hàng sắp hết (dưới ngưỡng cảnh báo), hàng đã hết, hoặc hàng cận / quá hạn sử dụng; có thể lọc theo từ khoá tên hoặc mã. Dùng cho "hàng nào sắp hết", "còn bao nhiêu [sản phẩm]".',
    parameters: {
      type: 'object',
      properties: {
        loc: {
          type: 'string',
          enum: [...LOC],
          description: 'Bộ lọc. Bỏ trống = tat_ca.',
        },
        tu_khoa: {
          type: 'string',
          description: 'Từ khoá tên hoặc mã sản phẩm',
        },
        gioi_han: {
          type: 'integer',
          description: 'Số dòng tối đa (1-20, mặc định 10)',
        },
      },
    },
  },

  async run(args, ctx) {
    const loc = pickEnum(args.loc, LOC, 'loc', 'tat_ca')
    if (!loc.ok) return { kind: 'bad_args', chi_tiet: loc.chi_tiet }
    const limit = clampInt(args.gioi_han, 1, 20, 10)
    const keyword = typeof args.tu_khoa === 'string' ? fold(args.tu_khoa.trim()) : ''

    const res = await ctx.rpc('inventory', 'list_stock_overview', {
      p_tenant_id: ctx.tenantId,
    })
    const products = asArray(isRecord(res) ? res.products : null)

    let matched = products.filter((p) => {
      const available = num(p.available) ?? 0
      const threshold = num(p.reorder_threshold)
      switch (loc.value) {
        case 'sap_het':
          return threshold !== null && available > 0 && available <= threshold
        case 'het_hang':
          return available <= 0
        case 'can_han':
          return p.has_near_expiry === true || p.has_expired === true
        default:
          return true
      }
    })
    if (keyword) {
      matched = matched.filter((p) =>
        fold(String(p.name ?? '')).includes(keyword) ||
        fold(String(p.code ?? '')).includes(keyword)
      )
    }
    matched.sort((a, b) =>
      loc.value === 'sap_het' || loc.value === 'het_hang'
        ? (num(a.available) ?? 0) - (num(b.available) ?? 0)
        : String(a.name ?? '').localeCompare(String(b.name ?? ''), 'vi')
    )
    const shown = matched.slice(0, limit)

    const dong = shown.map((p) => ({
      ten: p.name,
      ma: p.code,
      ton: num(p.available) ?? 0,
      dvt: p.base_uom,
      ...(num(p.reorder_threshold) !== null ? { nguong: num(p.reorder_threshold) } : {}),
      ...(p.has_expired === true ? { qua_han: true } : {}),
      ...(p.has_near_expiry === true ? { can_han: true } : {}),
    }))

    const block: TableBlock = {
      loai: 'bang',
      tieu_de: 'Tồn kho',
      cot: [
        { khoa: 'san_pham', ten: 'Sản phẩm', kieu: 'chu' },
        { khoa: 'ton', ten: 'Tồn', kieu: 'so' },
        { khoa: 'dvt', ten: 'ĐVT', kieu: 'chu' },
      ],
      dong: shown.map((p) => ({
        o: {
          san_pham: String(p.name ?? ''),
          ton: num(p.available) ?? 0,
          dvt: String(p.base_uom ?? ''),
        },
        ...(typeof p.product_id === 'string' ? { mo: { loai: 'san_pham' as const, id: p.product_id } } : {}),
      })),
    }

    return {
      kind: 'data',
      forModel: redactPersonal({ so_mat_hang: matched.length, dong }),
      block,
    }
  },
}

export const stockMovementTool: Tool = {
  declaration: {
    name: 'bien_dong_kho',
    description:
      'Xem nhập, xuất, tồn đầu và tồn cuối của MỘT sản phẩm trong một kỳ (thẻ kho). Cần san_pham_id: nếu chưa có, gọi tim_kiem (loai = san_pham) trước.',
    parameters: {
      type: 'object',
      properties: {
        san_pham_id: {
          type: 'string',
          description: 'uuid sản phẩm, lấy từ tim_kiem',
        },
        ...PERIOD_PROPERTIES,
      },
      required: ['san_pham_id'],
    },
  },

  async run(args, ctx) {
    const id = args.san_pham_id
    if (typeof id !== 'string' || !UUID_RE.test(id)) {
      return {
        kind: 'bad_args',
        chi_tiet: 'san_pham_id phải là uuid; hãy gọi tim_kiem (loai = san_pham) trước để lấy id',
      }
    }
    const period = periodFromArgs(args, ctx)
    if (!period.ok) return { kind: 'bad_args', chi_tiet: period.chi_tiet }

    const res = await ctx.rpc('inventory', 'get_stock_card', {
      p_tenant_id: ctx.tenantId,
      p_product_id: id,
      p_from: period.range.from,
      p_to: period.range.to,
    })
    const card = isRecord(res) ? res : {}
    const summary = isRecord(card.summary) ? card.summary : {}
    const product = isRecord(card.product) ? card.product : {}
    const rows = asArray(card.rows)

    const forModel = {
      san_pham: product.name ?? null,
      dvt: product.uom ?? null,
      ky: period.range,
      ton_dau: summary.opening_qty ?? null,
      tong_nhap: summary.in_qty ?? null,
      tong_xuat: summary.out_qty ?? null,
      ton_cuoi: summary.closing_qty ?? null,
      so_dong: rows.length,
    }

    const recent = rows.slice(-20)
    const block: TableBlock = {
      loai: 'bang',
      tieu_de: `Biến động kho${typeof product.name === 'string' ? ` — ${product.name}` : ''}`,
      cot: [
        { khoa: 'ngay', ten: 'Ngày', kieu: 'ngay' },
        { khoa: 'loai', ten: 'Loại', kieu: 'chu' },
        { khoa: 'so_luong', ten: 'Số lượng', kieu: 'so' },
        { khoa: 'ton_sau', ten: 'Tồn sau', kieu: 'so' },
      ],
      dong: recent.map((r) => ({
        o: {
          ngay: String(r.business_date ?? ''),
          loai: String(r.movement_kind ?? ''),
          so_luong: num(r.quantity_delta),
          ton_sau: num(r.balance_after),
        },
      })),
    }

    return { kind: 'data', forModel: redactPersonal(forModel), block }
  },
}
