import { assert, assertEquals, assertRejects } from 'jsr:@std/assert@1'
import { forecastTool } from './forecast.ts'
import { fakeRpc, makeCtx } from './test_util.ts'
import { RpcError } from './tool.ts'

const ID = '11111111-1111-4111-8111-111111111111'

const ROWS = {
  need_reorder_count: 3,
  rows: [
    {
      product_id: ID,
      name: 'Sữa tươi hộp 1L',
      code: 'DEMO-1',
      uom: 'hộp',
      available: 40,
      reorder_threshold: 60,
      target_level: 240,
      qty_8w: 670,
      daily_rate: 12,
      days_left: 3.3,
      suggest_qty: 200,
    },
    {
      product_id: '22222222-2222-4222-8222-222222222222',
      name: 'Cà phê gói',
      code: 'DEMO-12',
      uom: 'gói',
      available: 90,
      reorder_threshold: null,
      target_level: null,
      qty_8w: 0,
      daily_rate: 0,
      days_left: null,
      suggest_qty: null,
    },
  ],
}

async function run(args: Record<string, unknown>, res: unknown = ROWS) {
  const { rpc, calls } = fakeRpc({ 'inventory.get_purchase_forecast': res })
  const out = await forecastTool.run(args, makeCtx(rpc))
  return { out, calls }
}

Deno.test('forecast_calls_rpc_with_defaults', async () => {
  const { calls } = await run({})
  assertEquals(calls.length, 1)
  assertEquals(calls[0].schema, 'inventory')
  assertEquals(calls[0].fn, 'get_purchase_forecast')
  assertEquals(calls[0].args, {
    p_tenant_id: 'tenant-1',
    p_product_id: null,
    p_only_need_reorder: true,
    p_limit: 20,
  })
})

Deno.test('forecast_single_product', async () => {
  const { calls } = await run({ san_pham_id: ID, chi_hang_can_nhap: false })
  assertEquals(calls[0].args, { p_tenant_id: 'tenant-1', p_product_id: ID, p_limit: 20 })

  const bad = await run({ san_pham_id: 'Sữa' })
  assertEquals(bad.out.kind, 'bad_args')
  assertEquals(bad.calls.length, 0)
})

Deno.test('forecast_maps_rows_and_block', async () => {
  const { out } = await run({})
  if (out.kind !== 'data') throw new Error('expected data')
  const fm = out.forModel as { so_hang_can_nhap: number; dong: Record<string, unknown>[] }
  assertEquals(fm.so_hang_can_nhap, 3)
  assertEquals(fm.dong[0], {
    ten: 'Sữa tươi hộp 1L',
    ma: 'DEMO-1',
    ton: 40,
    dvt: 'hộp',
    ban_moi_ngay: 12,
    con_ban_ngay: 3.3,
    nen_nhap: 200,
    nguong: 60,
    muc_ton_muc_tieu: 240,
  })
  const b = out.block!
  assertEquals(b.tieu_de, 'Dự báo nhập hàng')
  assertEquals(b.cot.map((c) => c.khoa), ['san_pham', 'ton', 'ban_moi_ngay', 'con_ban_ngay', 'nen_nhap'])
  assertEquals(b.cot.map((c) => c.ten), ['Sản phẩm', 'Tồn', 'Bán/ngày', 'Còn bán (ngày)', 'Nên nhập'])
  assertEquals(b.cot.map((c) => c.kieu), ['chu', 'so', 'so', 'so', 'so'])
  assertEquals(b.dong[0].mo, { loai: 'san_pham', id: ID })
  assertEquals(b.dong[0].o.nen_nhap, 200)
})

Deno.test('forecast_null_days', async () => {
  const { out } = await run({})
  if (out.kind !== 'data') throw new Error('expected data')
  const fm = out.forModel as { dong: Record<string, unknown>[] }
  assertEquals(fm.dong[1].con_ban_ngay, null)
  assertEquals(out.block!.dong[1].o.con_ban_ngay, null)
})

Deno.test('forecast_no_policy_flag', async () => {
  const { out } = await run({})
  if (out.kind !== 'data') throw new Error('expected data')
  const row = (out.forModel as { dong: Record<string, unknown>[] }).dong[1]
  assertEquals(row.chua_dat_nguong, true)
  assertEquals(row.nen_nhap, null)
  assert(!('nguong' in row))
})

Deno.test('forecast_empty_no_block', async () => {
  const { out } = await run({}, { need_reorder_count: 0, rows: [] })
  if (out.kind !== 'data') throw new Error('expected data')
  assertEquals((out.forModel as { dong: unknown[] }).dong, [])
  assertEquals(out.block, undefined)
})

Deno.test('forecast_permission_denied_rethrown', async () => {
  const { rpc } = fakeRpc({ 'inventory.get_purchase_forecast': new RpcError('PERMISSION_DENIED', 'x') })
  await assertRejects(() => forecastTool.run({}, makeCtx(rpc)), RpcError)
})
