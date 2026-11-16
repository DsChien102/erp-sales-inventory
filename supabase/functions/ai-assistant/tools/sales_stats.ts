import { type Ky, previousPeriod } from '../period.ts'
import type { ColumnKind, OpenTarget, TableBlock } from '../types.ts'
import { redactPersonal } from './redact.ts'
import { asArray, clampInt, isRecord, PERIOD_PROPERTIES, periodFromArgs, pickEnum, type Tool } from './tool.ts'

const CHI_SO = {
  doanh_thu: { metric: 'revenue', ten: 'Doanh thu', kieu: 'tien' },
  so_don: { metric: 'order_count', ten: 'Số đơn', kieu: 'so' },
  so_luong_ban: { metric: 'quantity', ten: 'Số lượng bán', kieu: 'so' },
  gia_tri_tb_don: {
    metric: 'avg_order_value',
    ten: 'Giá trị TB mỗi đơn',
    kieu: 'tien',
  },
} as const satisfies Record<
  string,
  { metric: string; ten: string; kieu: ColumnKind }
>

const NHOM = {
  khong: 'none',
  ngay: 'day',
  tuan: 'week',
  thang: 'month',
  san_pham: 'product',
  khach_hang: 'customer',
  nhan_vien: 'seller',
} as const

type ChiSo = keyof typeof CHI_SO
type Nhom = keyof typeof NHOM

const NHOM_NHAN: Record<Exclude<Nhom, 'khong'>, string> = {
  ngay: 'ngày',
  tuan: 'tuần',
  thang: 'tháng',
  san_pham: 'sản phẩm',
  khach_hang: 'khách hàng',
  nhan_vien: 'nhân viên',
}

export const salesStatsTool: Tool = {
  declaration: {
    name: 'thong_ke_ban_hang',
    description:
      'Thống kê bán hàng của cửa hàng: doanh thu, số đơn, số lượng bán, giá trị trung bình mỗi đơn; có thể nhóm theo ngày/tuần/tháng/sản phẩm/khách/nhân viên và so với kỳ trước. Dùng cho câu hỏi "bán được bao nhiêu", "bán chạy nhất", "khách nào mua nhiều".',
    parameters: {
      type: 'object',
      properties: {
        chi_so: {
          type: 'string',
          enum: Object.keys(CHI_SO),
          description: 'Chỉ số cần xem',
        },
        nhom_theo: {
          type: 'string',
          enum: Object.keys(NHOM),
          description: 'Cách nhóm kết quả. Bỏ trống = khong (chỉ lấy tổng).',
        },
        ...PERIOD_PROPERTIES,
        so_sanh_ky_truoc: {
          type: 'boolean',
          description: 'true = lấy thêm tổng của kỳ liền trước để so sánh',
        },
        top_n: {
          type: 'integer',
          description: 'Số dòng tối đa (1-20, mặc định 10) khi nhóm theo sản phẩm/khách/nhân viên',
        },
      },
      required: ['chi_so'],
    },
  },

  async run(args, ctx) {
    const chiSo = pickEnum(
      args.chi_so,
      Object.keys(CHI_SO) as ChiSo[],
      'chi_so',
    )
    if (!chiSo.ok) return { kind: 'bad_args', chi_tiet: chiSo.chi_tiet }
    const nhom = pickEnum(
      args.nhom_theo,
      Object.keys(NHOM) as Nhom[],
      'nhom_theo',
      'khong',
    )
    if (!nhom.ok) return { kind: 'bad_args', chi_tiet: nhom.chi_tiet }
    const period = periodFromArgs(args, ctx)
    if (!period.ok) return { kind: 'bad_args', chi_tiet: period.chi_tiet }
    const topN = clampInt(args.top_n, 1, 20, 10)
    const meta = CHI_SO[chiSo.value]

    const res = await ctx.rpc('sales', 'get_sales_stats', {
      p_tenant_id: ctx.tenantId,
      p_metric: meta.metric,
      p_group_by: NHOM[nhom.value],
      p_from: period.range.from,
      p_to: period.range.to,
      p_top_n: topN,
    })
    const data = isRecord(res) ? res : {}
    const rows = asArray(data.rows)

    const forModel: Record<string, unknown> = {
      chi_so: chiSo.value,
      ky: period.range,
      tong: data.total ?? null,
      dong: rows.map((r) => ({ nhan: r.label, gia_tri: r.value })),
    }

    if (args.so_sanh_ky_truoc === true) {
      const prev = previousPeriod(period.ky as Ky, period.range)
      const prevRes = await ctx.rpc('sales', 'get_sales_stats', {
        p_tenant_id: ctx.tenantId,
        p_metric: meta.metric,
        p_group_by: 'none',
        p_from: prev.from,
        p_to: prev.to,
        p_top_n: topN,
      })
      forModel.ky_truoc = {
        ...prev,
        tong: isRecord(prevRes) ? prevRes.total ?? null : null,
      }
    }

    let block: TableBlock | undefined
    if (nhom.value !== 'khong') {
      const target: OpenTarget['loai'] | null = nhom.value === 'san_pham'
        ? 'san_pham'
        : nhom.value === 'khach_hang'
        ? 'khach_hang'
        : null
      block = {
        loai: 'bang',
        tieu_de: `${meta.ten} theo ${NHOM_NHAN[nhom.value]}`,
        cot: [
          { khoa: 'nhom', ten: 'Nhóm', kieu: 'chu' },
          { khoa: 'gia_tri', ten: meta.ten, kieu: meta.kieu },
        ],
        dong: rows.map((r) => {
          const line: TableBlock['dong'][number] = {
            o: {
              nhom: String(r.label ?? r.key ?? ''),
              gia_tri: (r.value as number | null) ?? null,
            },
          }
          if (target && r.key !== 'walk_in' && typeof r.key === 'string') {
            line.mo = { loai: target, id: r.key }
          }
          return line
        }),
      }
    }

    return { kind: 'data', forModel: redactPersonal(forModel), block }
  },
}
