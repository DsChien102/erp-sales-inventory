import type { ColumnKind, OpenTarget, TableBlock } from '../types.ts'
import { UUID_RE } from './tool.ts'

const MAX_COLUMNS = 8

const LABELS: Record<string, string> = {
  ma_don: 'Mã đơn',
  ngay_ban: 'Ngày bán',
  gio_ban: 'Giờ bán',
  ngay: 'Ngày',
  trang_thai: 'Trạng thái',
  ten_khach: 'Khách',
  ten_nhan_vien: 'Nhân viên',
  so_dong: 'Số dòng',
  tong_tien_vnd: 'Tổng tiền',
  da_thu_vnd: 'Đã thu',
  con_no_vnd: 'Còn nợ',
  han_thanh_toan: 'Hạn thanh toán',
  ngay_huy: 'Ngày huỷ',
  ten_san_pham: 'Sản phẩm',
  ma_san_pham: 'Mã sản phẩm',
  so_luong: 'Số lượng',
  doanh_thu_vnd: 'Doanh thu',
  gia_von_vnd: 'Giá vốn',
  loai_dong: 'Loại',
  loai: 'Loại',
  don_vi: 'Đơn vị',
  ton_vat_ly: 'Tồn vật lý',
  ton_kha_dung: 'Tồn khả dụng',
  nguong_canh_bao: 'Ngưỡng cảnh báo',
  muc_ton_muc_tieu: 'Mức tồn mục tiêu',
  so_luong_thay_doi: 'Thay đổi',
  ngay_tao: 'Ngày tạo',
  ma_vach: 'Mã vạch',
}

const DATE_RE = /^\d{4}-\d{2}-\d{2}/

// Giá trị mã trong view ⇒ chữ hiển thị (cột trang_thai, loai_dong).
const VALUE_LABELS: Record<string, Record<string, string>> = {
  trang_thai: {
    hoan_tat: 'Hoàn tất',
    da_huy: 'Đã huỷ',
    active: 'Đang kinh doanh',
    inactive: 'Ngừng',
  },
  loai_dong: { ban: 'Bán', doi: 'Đổi', tra: 'Trả', huy: 'Huỷ' },
}

function label(key: string): string {
  const known = LABELS[key]
  if (known) return known
  const text = key.replace(/_vnd$/, '').replace(/_/g, ' ').trim()
  return text === '' ? key : text.charAt(0).toUpperCase() + text.slice(1)
}

function kindOf(key: string, values: unknown[]): ColumnKind {
  if (key.endsWith('_vnd')) return 'tien'
  const present = values.filter((v) => v !== null && v !== undefined)
  if (
    key.startsWith('ngay_') ||
    (present.length > 0 && present.every((v) => typeof v === 'string' && DATE_RE.test(v)))
  ) return 'ngay'
  if (present.length > 0 && present.every((v) => typeof v === 'number')) return 'so'
  return 'chu'
}

function cell(kind: ColumnKind, v: unknown): string | number | null {
  if (v === null || v === undefined) return kind === 'tien' || kind === 'so' ? null : ''
  if (kind === 'tien' || kind === 'so') {
    const n = Number(v)
    return Number.isFinite(n) ? n : null
  }
  if (typeof v === 'string') return v
  if (typeof v === 'boolean') return v ? 'Có' : 'Không'
  return typeof v === 'number' ? String(v) : JSON.stringify(v)
}

function openTarget(row: Record<string, unknown>): OpenTarget | undefined {
  const uuid = (v: unknown): v is string => typeof v === 'string' && UUID_RE.test(v)
  if (uuid(row.san_pham_id)) return { loai: 'san_pham', id: row.san_pham_id }
  if (uuid(row.don_id)) return { loai: 'don_ban', id: row.don_id }
  if (uuid(row.khach_id)) return { loai: 'khach_hang', id: row.khach_id }
  return undefined
}

/** Bảng hiển thị từ kết quả `ai.run_query`; không có bảng khi rỗng hoặc chỉ một con số. */
export function buildQueryBlock(
  r: { cot: string[]; dong: Record<string, unknown>[] },
  title: string,
): TableBlock | undefined {
  if (r.dong.length === 0) return undefined
  const visible = r.cot.filter((k) => !/_id$/.test(k)).slice(0, MAX_COLUMNS)
  if (visible.length === 0) return undefined
  if (r.dong.length === 1 && visible.length === 1) return undefined

  const cot = visible.map((k) => ({
    khoa: k,
    ten: label(k),
    kieu: kindOf(k, r.dong.map((row) => row[k])),
  }))

  return {
    loai: 'bang',
    tieu_de: title,
    cot,
    dong: r.dong.map((row) => {
      const o: Record<string, string | number | null> = {}
      for (const c of cot) {
        const v = cell(c.kieu, row[c.khoa])
        o[c.khoa] = typeof v === 'string' ? VALUE_LABELS[c.khoa]?.[v] ?? v : v
      }
      const mo = openTarget(row)
      return mo ? { o, mo } : { o }
    }),
  }
}
