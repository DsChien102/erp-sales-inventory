export type Ky =
  | 'hom_nay'
  | 'hom_qua'
  | 'tuan_nay'
  | 'tuan_truoc'
  | 'thang_nay'
  | 'thang_truoc'
  | 'tuy_chon'

export type Range = { from: string; to: string } // 'YYYY-MM-DD'

export const MAX_RANGE_DAYS = 366

const KY_VALUES: readonly string[] = [
  'hom_nay',
  'hom_qua',
  'tuan_nay',
  'tuan_truoc',
  'thang_nay',
  'thang_truoc',
  'tuy_chon',
]

const DAY_MS = 86_400_000

function toMs(date: string): number {
  const [y, m, d] = date.split('-').map(Number)
  return Date.UTC(y, m - 1, d)
}

function fromMs(ms: number): string {
  return new Date(ms).toISOString().slice(0, 10)
}

function addDays(date: string, days: number): string {
  return fromMs(toMs(date) + days * DAY_MS)
}

function diffDays(from: string, to: string): number {
  return Math.round((toMs(to) - toMs(from)) / DAY_MS)
}

function isValidDate(value: unknown): value is string {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    return false
  }
  return fromMs(toMs(value)) === value
}

function monthStart(date: string): string {
  return date.slice(0, 8) + '01'
}

function monthEnd(date: string): string {
  const [y, m] = date.split('-').map(Number)
  return fromMs(Date.UTC(y, m, 0)) // ngày 0 của tháng sau = ngày cuối tháng này
}

function addMonths(date: string, months: number): string {
  const [y, m] = date.split('-').map(Number)
  return fromMs(Date.UTC(y, m - 1 + months, 1))
}

function mondayOf(date: string): string {
  const weekday = new Date(toMs(date)).getUTCDay() // 0 = Chủ nhật
  return addDays(date, -((weekday + 6) % 7))
}

export function todayInVietnam(now: Date): string {
  return fromMs(now.getTime() + 7 * 3_600_000)
}

export function resolvePeriod(
  input: { ky?: unknown; tu_ngay?: unknown; den_ngay?: unknown },
  today: string,
): { ok: true; range: Range } | { ok: false; chi_tiet: string } {
  const ky = input.ky === undefined || input.ky === null ? 'hom_nay' : input.ky
  if (typeof ky !== 'string' || !KY_VALUES.includes(ky)) {
    return { ok: false, chi_tiet: `ky không hợp lệ: ${String(ky)}` }
  }

  switch (ky as Ky) {
    case 'hom_nay':
      return { ok: true, range: { from: today, to: today } }
    case 'hom_qua': {
      const d = addDays(today, -1)
      return { ok: true, range: { from: d, to: d } }
    }
    case 'tuan_nay':
      return { ok: true, range: { from: mondayOf(today), to: today } }
    case 'tuan_truoc': {
      const monday = mondayOf(today)
      return {
        ok: true,
        range: { from: addDays(monday, -7), to: addDays(monday, -1) },
      }
    }
    case 'thang_nay':
      return { ok: true, range: { from: monthStart(today), to: today } }
    case 'thang_truoc': {
      const start = addMonths(monthStart(today), -1)
      return { ok: true, range: { from: start, to: monthEnd(start) } }
    }
    case 'tuy_chon': {
      const { tu_ngay, den_ngay } = input
      if (!isValidDate(tu_ngay) || !isValidDate(den_ngay)) {
        return {
          ok: false,
          chi_tiet: 'ky tuy_chon cần tu_ngay và den_ngay dạng YYYY-MM-DD hợp lệ',
        }
      }
      if (tu_ngay > den_ngay) {
        return {
          ok: false,
          chi_tiet: 'tu_ngay phải nhỏ hơn hoặc bằng den_ngay',
        }
      }
      if (diffDays(tu_ngay, den_ngay) + 1 > MAX_RANGE_DAYS) {
        return {
          ok: false,
          chi_tiet: `khoảng ngày tối đa ${MAX_RANGE_DAYS} ngày`,
        }
      }
      return { ok: true, range: { from: tu_ngay, to: den_ngay } }
    }
  }
}

export function previousPeriod(ky: Ky, range: Range): Range {
  if (ky === 'thang_nay') {
    const prevStart = addMonths(monthStart(range.from), -1)
    const length = diffDays(range.from, range.to) + 1
    const prevEnd = addDays(prevStart, length - 1)
    const last = monthEnd(prevStart)
    return { from: prevStart, to: prevEnd > last ? last : prevEnd }
  }
  if (ky === 'thang_truoc') {
    const prevStart = addMonths(monthStart(range.from), -1)
    return { from: prevStart, to: monthEnd(prevStart) }
  }
  const length = diffDays(range.from, range.to) + 1
  return { from: addDays(range.from, -length), to: addDays(range.from, -1) }
}
