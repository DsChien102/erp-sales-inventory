import type { ToolDeclaration } from '../model/model_client.ts'
import { type Range, resolvePeriod } from '../period.ts'
import type { TableBlock } from '../types.ts'

export class RpcError extends Error {
  constructor(readonly code: string, message: string) {
    super(message)
  }
}

export type RpcCaller = (
  schema: string,
  fn: string,
  args: Record<string, unknown>,
) => Promise<unknown>

export type ToolContext = {
  tenantId: string
  actorId: string
  today: string
  rpc: RpcCaller
}

export type ToolOutcome =
  | { kind: 'data'; forModel: unknown; block?: TableBlock }
  | { kind: 'bad_args'; chi_tiet: string } // gửi lại model { loi: 'tham_so_sai', chi_tiet }
  | {
    kind: 'unsupported'
    status: 'ngoai_pham_vi' | 'chua_ho_tro' | 'tu_choi'
  }

export interface Tool {
  declaration: ToolDeclaration
  /** Tải dữ liệu cần cho mô tả công cụ (vd. danh mục view). Không được ném lỗi. */
  prepare?(ctx: ToolContext): Promise<void>
  run(args: Record<string, unknown>, ctx: ToolContext): Promise<ToolOutcome>
}
// RpcError 'PERMISSION_DENIED' được ném tiếp (orchestrator bắt), không gói thành ToolOutcome.

/** Đọc `code` từ JSON trong message lỗi PostgREST; không đọc được ⇒ 'UNKNOWN'. */
export function rpcErrorFromPostgrest(
  error: { message?: string } | null | undefined,
): RpcError {
  const message = error?.message ?? ''
  try {
    const parsed = JSON.parse(message)
    if (parsed && typeof parsed.code === 'string') {
      return new RpcError(
        parsed.code,
        typeof parsed.message === 'string' ? parsed.message : message,
      )
    }
  } catch {
    // không phải JSON
  }
  // RPC cũ ném thẳng mã dạng chữ (vd. 'PERMISSION_DENIED')
  if (
    /^PERMISSION_DENIED/.test(message)
  ) {
    return new RpcError('PERMISSION_DENIED', message)
  }
  return new RpcError('UNKNOWN', message)
}

export const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

export function pickEnum<T extends string>(
  value: unknown,
  allowed: readonly T[],
  name: string,
  fallback?: T,
): { ok: true; value: T } | { ok: false; chi_tiet: string } {
  if (value === undefined || value === null) {
    if (fallback !== undefined) return { ok: true, value: fallback }
    return {
      ok: false,
      chi_tiet: `thiếu ${name}; chọn một trong: ${allowed.join(', ')}`,
    }
  }
  if (
    typeof value === 'string' && (allowed as readonly string[]).includes(value)
  ) {
    return { ok: true, value: value as T }
  }
  return {
    ok: false,
    chi_tiet: `${name} không hợp lệ: ${String(value)}; chọn một trong: ${allowed.join(', ')}`,
  }
}

export function clampInt(
  value: unknown,
  min: number,
  max: number,
  fallback: number,
): number {
  const n = typeof value === 'number' ? value : Number(value)
  if (value === undefined || value === null || !Number.isFinite(n)) {
    return fallback
  }
  return Math.min(max, Math.max(min, Math.trunc(n)))
}

export function periodFromArgs(
  args: Record<string, unknown>,
  ctx: ToolContext,
): { ok: true; range: Range; ky: string } | { ok: false; chi_tiet: string } {
  const r = resolvePeriod({
    ky: args.ky,
    tu_ngay: args.tu_ngay,
    den_ngay: args.den_ngay,
  }, ctx.today)
  if (!r.ok) return r
  return {
    ok: true,
    range: r.range,
    ky: typeof args.ky === 'string' ? args.ky : 'hom_nay',
  }
}

/** JSON Schema cho tham số thời gian dùng chung. */
export const PERIOD_PROPERTIES = {
  ky: {
    type: 'string',
    enum: [
      'hom_nay',
      'hom_qua',
      'tuan_nay',
      'tuan_truoc',
      'thang_nay',
      'thang_truoc',
      'tuy_chon',
    ],
    description: 'Kỳ thời gian. Bỏ trống = hom_nay. Dùng tuy_chon kèm tu_ngay, den_ngay cho khoảng khác.',
  },
  tu_ngay: { type: 'string', description: 'YYYY-MM-DD, chỉ khi ky = tuy_chon' },
  den_ngay: {
    type: 'string',
    description: 'YYYY-MM-DD, chỉ khi ky = tuy_chon',
  },
} as const

export function isRecord(v: unknown): v is Record<string, unknown> {
  return v !== null && typeof v === 'object' && !Array.isArray(v)
}

export function asArray(v: unknown): Record<string, unknown>[] {
  return Array.isArray(v) ? v.filter(isRecord) : []
}
